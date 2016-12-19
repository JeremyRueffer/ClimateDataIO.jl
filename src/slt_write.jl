# slt_write.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Runior Research Group Nitrosphere
# Julia 0.5.0
# 09.12.2016
# Last Edit. 19.12.2016

"""# slt_write

Write data to an SLT file

`slt_write(F,t0,ch,bm,D)`\n
* **filename**::DirectIndexString = Root of file name, \"K:\\Data\\D\". Script will finish it. ::DirectIndexString
* **t0**::DateTime = Initial time.
* **ch**::Array{Int8} = Channels (which analog inputs are active)
* **bm**::Array{Int8} = Bit Masks (which analog inputs are high resolution)
* **D**::Array{Int16} = data

\n\n
Important notes:\n
* Data input must have u,v,w,c and the analog voltages that are active. The data must be as it is written by EddyMeas. u,v,w are multiplied by 100 before the data is saved. c is multiplied by 50. High resolution data is also modified. See the EddySoft PDF on page 15 (actual page 23) for more information on parsing."""
function slt_write(F::String,t0::DateTime,ch::Array{Int8},bm::Array{Int8},D::Array{Int16})
	F = joinpath(F,string(Int64(Dates.Year(t0))) * @sprintf("%03u",Int64(floor(Float64(t0 - DateTime(Dates.Year(t0)))/1000/60/60/24))) * @sprintf("%02u",Int64(Dates.Hour(t0))) * @sprintf("%02u",Int64(Dates.Minute(t0))) * ".slt")
	
	# Time Conversion
	day0 = Int8(Dates.Day(t0))
	month0 = Int8(Dates.Month(t0))
	yr1 = Int8(Int64(Dates.Year(t0))/100)
	yr2 = Int8(Int64(Dates.Year(t0)) - 100*floor(Int64(Dates.Year(t0))/100))
	hour0 = Int8(Dates.Hour(t0))
	minute0 = Int8(Dates.Minute(t0))
	
	# Write the Header
	fid = open(F,"w+") # Open New File
	write(fid,Int8(2*size(D,2))) # Bytes per record = Number of columns x 2
	write(fid,eddy_ver)
	write(fid,day0)
	write(fid,month0)
	write(fid,yr1)
	write(fid,yr2)
	write(fid,hour0)
	write(fid,minute0)
	
	# Write Channels and Bit Masks
	for i=1:1:length(ch)
		write(fid,bm[i]) # Bit Mask
		write(fid,ch[i]) # Channel
	end
	
	# Read and Write Data
	for i=1:1:size(D,1)
		write(fid,D[i,1])
		write(fid,D[i,2])
		write(fid,D[i,3])
		write(fid,D[i,4])
		for j=1:1:length(ch)
			temp = D[i,4 + j]
			if bm[j] & 2^(1-1) > 0 # If the first bit is high
				# If the bit mask is high, use the following formula to convert the mV value to binary
				temp = 10temp - 25000
			end
			write(fid,temp)
		end
	end
	close(fid) # Close New File
end # slt_write(F::String,t0::DateTime,ch::Array{Int8},bm::Array{Int8},D::Array{Int16})
