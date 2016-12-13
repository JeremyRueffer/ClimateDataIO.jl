# sltload.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 09.12.2016
# Last Edit: 09.12.2016

"""# sltload

Load a range of SLT files and convert the analog channels if conversion values are present in the corresponding CFG files

`sltload(dr,mindate,maxdate;average=false,verbose=true)`\n
* **dr**::String = SLT directory
* **mindate**::DateTime = Minimum of the time range to load
* **maxdate**::DateTime = Maximum of the time range to load
* **average**::Bool (optional) = Half hour average the data when TRUE, FALSE is default
* **verbose**::Bool (optional) = Display information of what is going on when TRUE, TRUE is default
"""
function sltload(dr::String,mindate::DateTime,maxdate::DateTime;average::Bool=false,verbose::Bool=true)
	############
	## Checks ##
	############
	if !isdir(dr)
		error("First input must be a directory.")
	end
	
	#########################
	## List and Sort Files ##
	#########################
	if verbose
		println("Listing SLT Files")
	end
	(files,folders) = dirlist(dr,regex=r"\w\d{8}\.(slt|cfg)$")
	
	# Parse File Dates
	if verbose
		println("Sorting " * string(length(files)) * " Files")
	end
	fdates = Array(DateTime,length(files))
	i = 0
	for i=1:1:length(files)
		temp = basename(files[i])
		try
			yearstr = parse(temp[2:5])
			daystr = parse(temp[6:8])
			hourstr = parse(temp[9:10])
			minutestr = parse(temp[11:12])
			fdates[i] = DateTime(yearstr) + Dates.Day(daystr) - Dates.Day(1) + Dates.Hour(hourstr) + Dates.Minute(minutestr)
			catch
				println(files[i])
				error("Failed")
			end
	end
	
	# Save Config files before dates are filtered
	f = [ismatch(r"\.cfg$",i) for i in files]
	cfgfiles = files[f]
	cfgdates = fdates[f]
	
	# Sort CFG Files by Date
	f = sortperm(cfgdates)
	cfgdates = cfgdates[f]
	cfgfiles = cfgfiles[f]
	
	# Save SLT files before dates are filtered
	f = [ismatch(r"\.slt$",i) for i in files]
	files = files[f]
	fdates = fdates[f]
	
	# Remove files beyond the given time bounds
	f = find(mindate .<= fdates .< maxdate)
	fdates = fdates[f]
	files = files[f]
	
	# Sort the Files By Date
	f = sortperm(fdates)
	fdates = fdates[f]
	files = files[f]
	
	# If no files are found return nothing
	if isempty(files)
		if average == false
			return DataFrame()
		else
			return DateTime[],[],[],[],[]
		end
	end
	
	###############################
	## Prepare CFG and SLT Info  ##
	###############################
	if verbose
		println("Loading Settings for " * string(length(files)) * " files")
	end
	
	# Remove Unnecessary Config Files
	f = find(cfgdates .<= mindate)
	if isempty(f)
		error("No corresponding configuration files found, cannot continue.")
	end
	f = f[end]
	cfgdates = cfgdates[f:end]
	cfgfiles = cfgfiles[f:end]
	
	f = find(cfgdates .< maxdate)
	cfgdates = cfgdates[f]
	cfgfiles = cfgfiles[f]
	
	# Load CFG info
	configs = sltconfig(cfgfiles)
	begin
		temp = configs[end,:]
		temp[:Time] = DateTime(9999) # Setup a fake final row with a time well beyond any real file name
		configs = [configs;temp]
	end
	
	# Check for column changes
	if length(unique(configs[:Analog_Inputs])) > 1
		error("Analog inputs are not all the same, dimension mismatch.")
	end
	
	# Load SLT Info
	sltinfo = DataFrame()
	cfg = Array(Int8,length(files)) # List of which CFG file each
	offset = 1 # File processing list offset
	while offset < length(files)
		cfgf = find(configs[:Time] .<= fdates[offset])[end] # Find latest config
		config1 = configs[cfgf,:] # Current config and lower bound on file list
		config2 = configs[cfgf+1,:] # Upper bound on file list
		
		f = find(config1[:Time] .<= fdates .< config2[:Time])
		tempfiles = files[f]
		analog_count = config1[:Analog_Count][1]
		sample_frequency = parse(config1[:Frequency][1])
		slope = config1[:Slope][1]
		for i=1:1:length(tempfiles)
			cfg[offset] = cfgf
			temp = sltheader(tempfiles[i],analog_count,sample_frequency)
			temp[:Analog_Count] = analog_count
			temp[:Sample_Frequency] = sample_frequency
			temp[:Slope] = collect(Array[slope])
			if isempty(sltinfo)
				sltinfo = temp
			else
				sltinfo = [sltinfo;temp]
			end
			offset += 1
		end
	end
	
	# Preallocate Final Arrays
	if verbose
		println("Preallocating Final Arrays (" * string(Int64(sum(sltinfo[:Line_Count]))) * "," * string(4+configs[:Analog_Count][1]) * ")")
	end
	l = Int64(sum(sltinfo[:Line_Count]))
	if 4+configs[:Analog_Count][1] == 4
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 5
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 6
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 7
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 8
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 9
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN))
	elseif 4+configs[:Analog_Count][1] == 10
		D = DataFrame(Time = fill!(Array(DateTime,l),DateTime(0)), u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN), wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN), Analog6 = fill!(Array(Float64,l),NaN))
	end
	
	# Rename DataFrame columns
	h = ["Time";"u";"v";"w";"sonic_temp";"speed_of_sound";"wind_direction";configs[:Analog_Names][1]]
	h_unique = unique(h);
	if length(h) !== length(unique(h_unique))
		for i = 1:1:length(h_unique)
			n = 1
			for j = 1:1:length(h)
				if h[j] == h_unique[i]
					if n > 1
						h[j] = h_unique[i] * "_" * string(n)
					end
					n += 1
				end
			end
		end
	end
	h = [Symbol(replace("$j"," ","")) for j in h]
	names!(D,h)
	#for i=1:1:configs[:Analog_Count][1]
	#        rename!(D,symbol("Analog" * string(i)),symbol(replace(configs[:Analog_Names][1][i]," ","")))
	#end
	
	###################
	## Load the Data ##
	###################
	if verbose
		println("Loading Data (" * string(length(files)) * " files)")
	end
	offset = 0
	u = 0.0
	v = 0.0
	for i=1:1:length(files)
		println("   " * string(i) * ": " * files[i])
		
		fid = open(files[i],"r")
		try
			seek(fid,sltinfo[:Start_Pos][i])
			
			for j=1:1:Int64(sltinfo[:Line_Count][i])
				ms = Int64(floor((j-1)*(1/sltinfo[:Sample_Frequency][i])*1000)) # milliseconds
				D[j+offset,1] = sltinfo[:T0][i] + Dates.Millisecond(ms) # Years, Months, Days, Hours, Minutes, Seconds, Milliseconds
				u = Float64(read(fid,Int16,1)[1])/100 # u
				v = Float64(read(fid,Int16,1)[1])/100 # v
				D[j+offset,2] = u
				D[j+offset,3] = v
				D[j+offset,4] = Float64(read(fid,Int16,1)[1])/100 # w
				temp = Float64(read(fid,Int16,1)[1])
				D[j+offset,5] = ((temp/50)^2)/403 - 273.16 # Tc
				D[j+offset,6] = temp/50 # c
				
				# Wind Direction
				if u == v == 0
					D[j+offset,7] = 0 # Otherwise u = v = 0 → NaN which messes up other calculations
				else
					if v < 0
						D[j+offset,7] = acosd(u/sqrt(u^2 + v^2)) - configs[:Sonic_Alignment][cfg[i]] # Wind Direction, A·B = |A||B|cos(Ø) → Ø = acos(Au/|A|) if B = [0 1 0]m/s (positive N wind)
					else
						D[j+offset,7] = 360 - acosd(u/sqrt(u^2 + v^2)) - configs[:Sonic_Alignment][cfg[i]] # Wind Direction, A·B = |A||B|cos(Ø) → Ø = acos(Au/|A|) if B = [0 1 0]m/s (positive N wind)
					end
				end
				
				for k=1:1:sltinfo[:Analog_Count][i]
					V = Float64(read(fid,Int16,1)[1]) # V1
					if sltinfo[:Bit_Mask][i][k] & 2^(1-1) > 0 # If the first bit is high
						# If the bit mask is high, use the following formula to convert the binary value to mV
						V = (V[1] + 25000)/10 # Binary to mV
					end
					b = Float64(configs[:Analog_Lower][cfg[i]][k]) # Y-intercept
					m = configs[:Slope][cfg[i]][k] # Slope
					D[j+offset,k+7] = m*V + b # Convert to a value
				end
			end
			offset += Int64(sltinfo[:Line_Count][i])
		catch e
			println("Error loading file: " * files[i])
			println(e)
		end
		close(fid)
	end
	
	####################
	##  Average Data  ##
	####################
	tmean = DateTime[]
	Dmean = DataFrame[]
	Dstd = DataFrame[]
	Dmin = DataFrame[]
	Dmax = DataFrame[]
	if average
		if verbose
			println("\tAveraging SLT Data")
		end
		
		targets = collect(minimum(D[:Time]) - Dates.Millisecond(minimum(D[:Time])):Dates.Minute(30):maximum(D[:Time]))
		actual = findnewton(D[:Time],targets)
		f = [actual;length(D[:Time]) + 1]
		
		# Preallocate
		tmean = fill!(Array(DateTime,length(f) - 1),DateTime(0))
		l = length(f) - 1
		if 4+configs[:Analog_Count][1] == 4
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 5
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 6
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 7
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 8
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 9
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN))
		elseif 4+configs[:Analog_Count][1] == 10
			Dmean = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN), Analog6 = fill!(Array(Float64,l),NaN))
			Dstd = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN), Analog6 = fill!(Array(Float64,l),NaN))
			Dmin = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN), Analog6 = fill!(Array(Float64,l),NaN))
			Dmax = DataFrame(u = fill!(Array(Float64,l),NaN), v = fill!(Array(Float64,l),NaN), w = fill!(Array(Float64,l),NaN), sonic_temp = fill!(Array(Float64,l),NaN), speed_of_sound = fill!(Array(Float64,l),NaN),wind_direction = fill!(Array(Float64,l),NaN), Analog1 = fill!(Array(Float64,l),NaN), Analog2 = fill!(Array(Float64,l),NaN), Analog3 = fill!(Array(Float64,l),NaN), Analog4 = fill!(Array(Float64,l),NaN), Analog5 = fill!(Array(Float64,l),NaN), Analog6 = fill!(Array(Float64,l),NaN))
		end
		names!(Dmean,names(D)[2:end])
		names!(Dstd,names(D)[2:end])
		names!(Dmin,names(D)[2:end])
		names!(Dmax,names(D)[2:end])
		
		# Process the Data
		temp_Dmean = []
		temp_Dstd = []
		temp_Dmin = []
		temp_Dmax = []
		for j=1:1:length(f)-1
			try
				tmean[j] = D[f[j],1]
				temp_Dmean = mean(convert(Array,D[f[j]:f[j+1]-1,2:end]),1)
				temp_Dstd = std(convert(Array,D[f[j]:f[j+1]-1,2:end]),1)
				temp_Dmin = minimum(convert(Array,D[f[j]:f[j+1]-1,2:end]),1)
				temp_Dmax = maximum(convert(Array,D[f[j]:f[j+1]-1,2:end]),1)
				
				for k=1:1:length(temp_Dmean)
					Dmean[j,k] = temp_Dmean[k]
					Dstd[j,k] = temp_Dstd[k]
					Dmin[j,k] = temp_Dmin[k]
					Dmax[j,k] = temp_Dmax[k]
				end
			catch
				println("\nsize(D) = " * string(size(D)))
				println("\tminimum(t) = " * string(minimum(t)))
				println("\tmaximum(t) = " * string(maximum(t)))
				println("\tf[j] = " * string(f[j]))
				println("\tj = " * string(j))
				println("\tlength(D[f[j]]) = " * string(length(D[f[j]])))
			end
		end
	end
	
	if verbose
		println("Complete")
	end
	if average
		return tmean, Dmean, Dstd, Dmin, Dmax
	else
		return D
	end
end # sltload(dr::String,mindate::DateTime,maxdate::DateTime)
