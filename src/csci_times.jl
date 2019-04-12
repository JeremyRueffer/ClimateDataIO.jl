# csci_times.jl
#
#	Parse CampbellScientific timestamps
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# Created: 04.11.2013
# Last Edit: 11.04.2019

"""# csci_times

Retrieve the minimum and maximum dates from the listed files

---

`minimum_dates, maximum_dates = csci_times{T<:String}(F::Array{T,1};headerlines::Int=4)
* **F**::Array{String,1} = Array of files to retrieve dates from
* **headerlines**::Int (optional) = Number of header lines, 4 is default
"""
function csci_times(F::Array{T,1};headerlines::Int=4) where T <: String
	# Get the first and last dates of each file
	mintimes = fill!(Array{DateTime}(undef,length(F)),DateTime(0))
	maxtimes = fill!(Array{DateTime}(undef,length(F)),DateTime(0))
	
	df = Dates.DateFormat("\"yyyy-mm-dd HH:MM:SS\"") # Date format
	
	datastart_pos = 1
	for i=1:1:length(F)
		# Find Minimum Time
		fsize = stat(F[i]).size
		fid = open(F[i],"r")
		for j=1:1:headerlines
			readline(fid)
		end
		datastart_pos = position(fid) # Find start of data
		if ~eof(fid)
			l = readline(fid)[1:21]
			mintimes[i] = DateTime(l,df)
		end
		
		# Find Maximum Time
		l = ""
		endpos = 1
		f = false
		while !f
			seek(fid,fsize-endpos)
			l = readline(fid)
			if !isempty(l)
				if length(l) > 21
					if l[6] == '-' && l[9] == '-' && l[12] == ' '
						f = true # Found the last line
					end
				end
			end
			endpos += 1
		end
		close(fid)
		maxtimes[i] = DateTime(l[1:21],df)
	end
	
	return mintimes, maxtimes
end
