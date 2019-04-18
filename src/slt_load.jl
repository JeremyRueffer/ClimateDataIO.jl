# slt_load.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 18.04.2019

"""# slt_load

Load a range of SLT files and convert the analog channels if conversion values are present in the corresponding CFG files

IMPORTANT NOTE: Gill sonic anemometers have a 30° offset from North, when a Gill instrument is listed on the "Sonic:" line of a configuration file then the 30° offset will be corrected.

`slt_load(dr,mindate,maxdate;average=false,verbose=true,angle_offset=0.0)`\n
* **dr**::String = SLT directory
* **mindate**::DateTime = Minimum of the time range to load
* **maxdate**::DateTime = Maximum of the time range to load
* **average**::Bool (optional) = Half hour average the data when TRUE, FALSE is default
* **verbose**::Bool (optional) = Display information of what is going on when TRUE, TRUE is default
* **angle_offset**::Real (optional) = Angle to add to the wind direction it will be added to the "Sonic Alignment" in the configuration file, 0.0 is default
"""
function slt_load(dr::String,mindate::DateTime,maxdate::DateTime;average::Bool=false,verbose::Bool=true,angle_offset::Real=0.0)
	###############
	## Constants ##
	###############
	GillSonics = 30.0 # Gill sonics have an offset of 30° towards West from North, see page 43 of the Gill R3 manual
	
	############
	## Checks ##
	############
	if !isdir(dr)
		error("First input must be a directory.")
	end
	
	#########################
	## List and Sort Files ##
	#########################
	verbose ? println("Listing SLT Files") : nothing
	(files,folders) = dirlist(dr,regex=r"\w\d{8}\.(slt|cfg)$")
	
	# Parse File Dates
	verbose ? println("Sorting " * string(length(files)) * " Files") : nothing
	fdates = Array{DateTime}(undef,length(files))
	i = 0
	for i=1:1:length(files)
		temp = basename(files[i])
		try
			yearstr = Meta.parse(temp[2:5])
			daystr = Meta.parse(temp[6:8])
			hourstr = Meta.parse(temp[9:10])
			minutestr = Meta.parse(temp[11:12])
			fdates[i] = DateTime(yearstr) + Dates.Day(daystr) - Dates.Day(1) + Dates.Hour(hourstr) + Dates.Minute(minutestr)
			catch
				println(files[i])
				error("Failed")
			end
	end
	
	# Save Config files before dates are filtered
	f = [occursin(r"\.cfg$",i) for i in files]
	cfgfiles = files[f]
	cfgdates = fdates[f]
	
	# Sort CFG Files by Date
	f = sortperm(cfgdates)
	cfgdates = cfgdates[f]
	cfgfiles = cfgfiles[f]
	
	# Save SLT files before dates are filtered
	f = [occursin(r"\.slt$",i) for i in files]
	files = files[f]
	fdates = fdates[f]
	
	# Remove files beyond the given time bounds
	f = findall(mindate .<= fdates .< maxdate)
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
	verbose ? println("Loading Settings for " * string(length(files)) * " files") : nothing
	
	# Remove Unnecessary Config Files
	f = findall(cfgdates .<= mindate)
	if isempty(f)
		error("No corresponding configuration files found, cannot continue.")
	end
	f = f[end]
	cfgdates = cfgdates[f:end]
	cfgfiles = cfgfiles[f:end]
	
	f = findall(cfgdates .< maxdate)
	cfgdates = cfgdates[f]
	cfgfiles = cfgfiles[f]
	
	# Load CFG info
	configs = slt_config(cfgfiles)
	configs = [configs;deepcopy(configs[1])] # Setup a fake final row with a time well beyond any real file name
	configs[end]["Time"] = DateTime(9999)
	
	# Check for column changes
	if length(unique(get.(configs,"Analog_Inputs",[-9999.0.*ones(Int,6)]))) > 1
		error("Analog inputs are not all the same, dimension mismatch.")
	end
	
	# Load SLT Info
	sltinfo = DataFrame()
	cfg = Array{Int8}(undef,length(files)) # List of which CFG file each
	offset = 1 # File processing list offset
	times = get.(configs,"Time",Dates.DateTime(0))
	while offset < length(files)
		cfgf = findall(times .<= fdates[offset])[end] # Find latest config
		config1 = configs[cfgf] # Current config and lower bound on file list
		config2 = configs[cfgf+1] # Upper bound on file list
		
		f = findall(get(config1,"Time",Dates.DateTime(1)) .<= fdates .< get(config2,"Time",Dates.DateTime(1)))
		tempfiles = files[f]
		analog_count = get(config1,"Analog_Count",0)
		sample_frequency = Meta.parse(get(config1,"Frequency","0"))
		slope = get(config1,"Slope",zeros(Float64,6))
		for i=1:1:length(tempfiles)
			cfg[offset] = cfgf
			temp = slt_header(tempfiles[i],analog_count,sample_frequency)
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
	
	# Rename DataFrame columns
	h = ["Time";"u";"v";"w";"sonic_temp";"speed_of_sound";"wind_direction";get(configs[1],"Analog_Names","")]
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
	
	# Preallocate Final Arrays
	verbose ? println("Preallocating Final Arrays (" * string(Int(sum(sltinfo[:Line_Count]))) * "," * string(4+get(configs[1],"Analog_Count",0)) * ")") : nothing
	l = Int(sum(sltinfo[:Line_Count]))
	col_types = fill!(Array{DataType}(undef,length(h)),Float64)
	col_types[1] = DateTime
	D = DataFrame(col_types,Symbol[Symbol(i) for i in h],l)
	D[:,2:end] = NaN
	D[:,1] = DateTime(0)
	
	###################
	## Load the Data ##
	###################
	verbose ? println("Loading Data (" * string(length(files)) * " files)") : nothing
	instrument_offset = 0.0 # If instrument in use by its design has an offset
	offset = 0
	u = 0.0
	v = 0.0
	filefolder = ""
	for i=1:1:length(files)
		if splitdir(files[i])[1] != filefolder
			filefolder = splitdir(files[i])[1]
			println("  " * filefolder)
		end
		println("\t" * string(i) * ": " * basename(files[i]))
		
		# Instrument Angle Offset
		if occursin("Gill",get.(configs,"Sonic","")[cfg[i]])
			instrument_offset = GillSonics
		else
			instrument_offset = 0.0
		end
		
		fid = open(files[i],"r")
		try
			seek(fid,sltinfo[:Start_Pos][i])
			
			for j=1:1:Int(sltinfo[:Line_Count][i])
				ms = Int(floor((j-1)*(1/sltinfo[:Sample_Frequency][i])*1000)) # milliseconds
				D[j+offset,1] = sltinfo[:T0][i] + Dates.Millisecond(ms) # Years, Months, Days, Hours, Minutes, Seconds, Milliseconds
				u = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # u
				v = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # v
				D[j+offset,2] = u
				D[j+offset,3] = v
				D[j+offset,4] = Float64(read!(fid,Array{Int16}(undef,1))[1])/100 # w
				temp = Float64(read!(fid,Array{Int16}(undef,1))[1])
				D[j+offset,5] = ((temp/50)^2)/403 - 273.16 # Tc
				D[j+offset,6] = temp/50 # c
				
				# Wind Direction
				if u == v == 0
					D[j+offset,7] = 0 # Otherwise u = v = 0 → NaN which messes up other calculations
				else
					if v < 0
						D[j+offset,7] = acosd(u/sqrt(u^2 + v^2)) - get.(configs,"Sonic_Alignment",[0])[cfg[i]] + instrument_offset + angle_offset # Wind Direction, A·B = |A||B|cos(Θ) → Θ = acos(Au/|A|) if B = [0 1 0]m/s (positive N wind)
					else
						D[j+offset,7] = 360 - acosd(u/sqrt(u^2 + v^2)) - get.(configs,"Sonic_Alignment",[0])[cfg[i]] + instrument_offset + angle_offset # Wind Direction, A·B = |A||B|cos(Θ) → Θ = acos(Au/|A|) if B = [0 1 0]m/s (positive N wind)
					end
				end
				
				for k=1:1:sltinfo[:Analog_Count][i]
					V = Float64(read!(fid,Array{Int16}(undef,1))[1]) # V1
					if sltinfo[:Bit_Mask][i][k] & 2^(1-1) > 0 # If the first bit is high
						# If the bit mask is high, use the following formula to convert the binary value to mV
						V = (V[1] + 25000)/10 # Binary to mV
					end
					b = Float64(get.(configs,"Analog_Lower",[0])[cfg[i]][k]) # Y-intercept
					m = get.(configs,"Slope",[0])[cfg[i]][k] # Slope
					D[j+offset,k+7] = m*V + b # Convert to a value
				end
			end
			offset += Int(sltinfo[:Line_Count][i])
		catch e
			println("Error loading file: " * files[i])
			println(e)
		end
		close(fid)
	end
	
	##############################
	##  Correct Wind Direction  ##
	##############################
	f = findall(D[7] .> 360.0)
	D[f,7] = D[f,7] .- 360.0
	
	f = findall(D[7] .< 0.0)
	D[f,7] = D[f,7] .+ 360.0
	
	####################
	##  Average Data  ##
	####################
	tmean = DateTime[]
	Dmean = DataFrame[]
	Dstd = DataFrame[]
	Dmin = DataFrame[]
	Dmax = DataFrame[]
	if average
		verbose ? println("\tAveraging SLT Data") : nothing
		
		targets = collect(minimum(D[:Time]) - Dates.Millisecond(minimum(D[:Time])):Dates.Minute(30):maximum(D[:Time]))
		actual = findnewton(D[:Time],targets)
		f = [actual;length(D[:Time]) + 1]
		
		# Preallocate
		tmean = fill!(Array{DateTime}(undef,length(f) - 1),DateTime(0))
		l = length(f) - 1
		Dcols = [:u,:v,:w,:sonic_temp,:speed_of_sound,:wind_direction,:Analog1,:Analog2,:Analog3,:Analog4,:Analog5,:Analog6]
		Dtypes = [Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64]
		
		Dmean = DataFrame(Dtypes[1:6+get.(configs,"Analog_Count",[0])[1]],Dcols[1:6+get.(configs,"Analog_Count",[0])[1]],l)
		Dstd = DataFrame(Dtypes[1:6+get.(configs,"Analog_Count",[0])[1]],Dcols[1:6+get.(configs,"Analog_Count",[0])[1]],l)
		Dmin = DataFrame(Dtypes[1:6+get.(configs,"Analog_Count",[0])[1]],Dcols[1:6+get.(configs,"Analog_Count",[0])[1]],l)
		Dmax = DataFrame(Dtypes[1:6+get.(configs,"Analog_Count",[0])[1]],Dcols[1:6+get.(configs,"Analog_Count",[0])[1]],l)
		for i = length(Dcols[1:4+get.(configs,"Analog_Count",[0])[1]])
			for j = l
				Dmean[j,i] = NaN
				Dstd[j,i] = NaN
				Dmin[j,i] = NaN
				Dmax[j,i] = NaN
			end
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
				temp_Dmean = mean(convert(Matrix,D[f[j]:f[j+1]-1,2:end]),dims=1)
				temp_Dstd = std(convert(Matrix,D[f[j]:f[j+1]-1,2:end]),dims=1)
				temp_Dmin = minimum(convert(Matrix,D[f[j]:f[j+1]-1,2:end]),dims=1)
				temp_Dmax = maximum(convert(Matrix,D[f[j]:f[j+1]-1,2:end]),dims=1)
				
				for k=1:1:length(temp_Dmean)
					Dmean[j,k] = temp_Dmean[k]
					Dstd[j,k] = temp_Dstd[k]
					Dmin[j,k] = temp_Dmin[k]
					Dmax[j,k] = temp_Dmax[k]
				end
			catch e
				println(e)
				println("\n\tsize(D) = " * string(size(D)))
				println("\tnames(D) = " * string(names(D)))
				println("\tsize(Dmean) = " * string(size(Dmean)))
				println("\tsize(temp_Dmean) = " * string(size(temp_Dmean)))
				println("\tminimum(t) = " * string(minimum(D[:Time])))
				println("\tmaximum(t) = " * string(maximum(D[:Time])))
				println("\tf[j] = " * string(f[j]))
				println("\tj = " * string(j))
			end
		end
	end
	
	verbose ? println("Complete") : nothing
	if average
		return tmean, Dmean, Dstd, Dmin, Dmax
	else
		return D
	end
end # slt_load(dr::String,mindate::DateTime,maxdate::DateTime)
