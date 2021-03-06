# slt_read.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 18.04.2019

"""# slt_read

Load a single SLT file

`slt_read(F,a_inputs,sample_rate)`\n
* **F**::String = File name, including path
* **a_inputs**::Int = Number of analog channels in the SLT file
* **sample_rate**::Int or String = Sampling rate of the sonic"""
function slt_read(F::String,AnalogIn::Int,freq::String)
	return slt_read(F,AnallogIn,parse(freq))
end # slt_read(F::String,AnalogIn::Int,freq::String)

function slt_read(F::String,a_inputs::Int,sample_rate::Int)
	# Arrays to output
	t = [] # Time
	d = [] # Data
	
	# Parsing information for SLT files can be found in the EddySoft PDF on page 15 (actual page 23).
	
	fid = open(F,"r")
	try
		# Header
		bpr = Int(read!(fid,Array{Int8}(undef,1))[1]) # Bytes Per Record
		eddymeasver = read!(fid,Array{Int8}(undef,1))
		dom = Int(read!(fid,Array{Int8}(undef,1))[1]) # Day of Month
		m = Int(read!(fid,Array{Int8}(undef,1))[1]) # Month number
		yr = 100*Int(read!(fid,Array{Int8}(undef,1))[1]) + Int(read!(fid,Array{Int8}(undef,1))[1]) # Year
		h = Int(read!(fid,Array{Int8}(undef,1))[1]) # Hour
		minut = Int(read!(fid,Array{Int8}(undef,1))[1]) # Minute
		t0 = DateTime(yr,m,dom,h,minut,0) # Initial file time
		
		fs = stat(F).size # File size in bytes
		l = (fs - 8 - 2*a_inputs)/(8 + 2*a_inputs) # Number of rows of data, trusting the user inputs
		if l - floor(l) != 0
			warn(F * " either has a different column count than " * string(a_input + 4) * " or was terminated early.")
		end
		l = Int(floor(l))
		
		# Bit Masks and Channels
		bm = read!(fid,Array{Int8}(undef,2*a_inputs))
		ch = bm[2:2:end] # Channels
		bm = bm[1:2:end] # Bit masks
		
		## Preallocate Output Array
		t_offset = fill!(Array{Dates.Millisecond}(undef,floor(l)),Dates.Millisecond(1000/sample_rate)) # dt between every sample
		t_offset[1] = Dates.Millisecond(0) # Correction, the first sample shouldn't have an offset
		t_offset = cumsum(t_offset) # Time offset from the start for every sample
		t = DateTime(yr,m,dom,h,minut,0) + t_offset # Time
		d = NaN.*Array{Float64}(undef,(Int(l),4 + a_inputs)) # Data Array
		
		for i=1:1:l
			d[i,1] = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # u
			d[i,2] = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # v
			d[i,3] = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # w
			d[i,4] = Float64(read!(fid,Array{Int16}(undef,1))[1])/50 # c, # Speed of Sound
			
			for j=1:1:a_inputs
				V = Float64(read!(fid,Array{Int16}(undef,1))[1]) # V1
				if bm[j] & 2^(1-1) > 0 # If the first bit is high
					# If the bit mask is high, use the following formula to convert the binary value to mV
					V = (V[1] + 25000)/10 # Binary to mV
				end
				d[i,j+4] = V
			end
		end
	catch
		println("Error loading file: " * F)
	end
	close(fid)
	
	return t,d
end # End of slt_read(F::String,a_inputs::Int,sample_rate::Int)
