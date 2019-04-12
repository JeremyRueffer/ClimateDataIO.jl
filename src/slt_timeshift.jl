# slt_timeshift.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 11.04.2019

# TODOs:
#	- Re-write the SLT header only instead of re-writing the entire file

"""# slt_timeshift

Shift the initial timestamp of a range of SLT and other associated files

`slt_timeshift(f1,f2,mindate,maxdate,dt)`\n
* **f1**::String = Source directory
* **f2**::String = Destination directory
* **mindate**::DateTime = Minimum of the time range to shift
* **maxdate**::DateTime = Maximum of the time range to shift
* **dt**::Period = Amount of time shift to apply"""
function slt_timeshift(f1::String,f2::String,mindate::DateTime,maxdate::DateTime,dt::Period)
	# Constants
	nl = "\r\n"
	
	# Check Inputs
	!isdir(f1) ? error("First input must be a directory") : nothing
	!isdir(f2) ? error("Second input must be a directory") : nothing
	
	# List and sort files
	(files,folders) = dirlist(f1,regex=r"\w\d{8}\.")
	
	# Parse File Dates
	fdates = Array{DateTime}(undef,length(files))
	i = 0
	for i=1:1:length(files)
		try
			yearstr = Meta.parse(files[i][end-14:end-11])
			daystr = Meta.parse(files[i][end-10:end-8])
			hourstr = Meta.parse(files[i][end-7:end-6])
			minutestr = Meta.parse(files[i][end-5:end-4])
			fdates[i] = DateTime(yearstr) + Day(daystr) - Day(1) + Hour(hourstr) + Minute(minutestr)
		catch
			println(files[i])
			error("Failed to parse the header of " * files[i])
		end
	end
	
	# Sort the Files By Date
	f = sortperm(fdates)
	fdates = fdates[f]
	files = files[f]
	
	# Save Config files before dates are filtered
	f = [occursin(r"\.cfg$",i) for i in files]
	cfgfiles = files[f]
	cfgdates = fdates[f]
	
	# Remove files beyond the given time bounds
	f = findall(mindate .<= fdates)
	fdates = fdates[f]
	files = files[f]
	f = findall(maxdate .> fdates)
	fdates = fdates[f]
	files = files[f]
	
	# Display Info
	println("Adjusting EddyMeas Files' Times")
	println("   Source:      " * f1)
	println("   Destination: " * f2)
	println("   Number of files: " * string(length(files)))
	println("   Time Shift: " * string(dt))
	
	# Sort Files by Type
	f = [occursin(r"\.slt$",i) for i in files]
	sltfiles = files[f]
	sltdates = fdates[f]
	f = [occursin(r"\.csr$",i) for i in files]
	csrfiles = files[f]
	csrdates = fdates[f]
	f = [occursin(r"\.csu$",i) for i in files]
	csufiles = files[f]
	csudates = fdates[f]
	f = [occursin(r"\.flx$",i) for i in files]
	flxfiles = files[f]
	flxdates = fdates[f]
	f = [occursin(r"\.log$",i) for i in files]
	logfiles = files[f]
	logdates = fdates[f]
	f = [occursin(r"\.csv$",i) for i in files]
	csvfiles = files[f]
	csvdates = fdates[f]
	
	# Load the CFG info
	configs = slt_config(cfgfiles)
	configs = [configs;deepcopy(configs[1])] # Setup a fake final row with a time well beyond any real file name
	configs[end]["Time"] = DateTime(9999)
	
	# Process the CFG Files
	println("\nProcessing CFG Files")
	for i=1:1:size(configs,1) - 1
		new_time = get(configs[i],"Time",DateTime(0)) + dt
		println("   " * get(configs[i],"FileName","")[end-15:end])
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		#temp = string(Int(Year(new_time))) *
		#	@sprintf("%03u",1 + Int(Day(DateTime(Year(new_time),Month(new_time),Day(new_time)) - DateTime(Year(new_time))))) *
		#	@sprintf("%02u",Int(Hour(new_time))) *
		#	@sprintf("%02u",Int(Minute(new_time)))
		
		#temp = string(Int(Year(new_time))) *
		#	@sprintf("%03u",Int(Day(new_time - DateTime(Year(new_time))) + Day(1))) *
		#	@sprintf("%02u",Int(Hour(new_time))) *
		#	@sprintf("%02u",Int(Minute(new_time)))
		new_filename = joinpath(f2,string(get(configs[i],"FileName","")[end-15]) * temp * ".cfg")
		
		# Correct the Data
		#configs[:Time][i] = configs[:Time][i] + dt
		configs[i]["Time"] = get(configs[i],"Time",DateTime(0)) + dt
		
		# Write the Data
		fid = open(new_filename,"w+")
		try
			write(fid,"[Settings for EddyMeas]" * nl)
			#write(fid,"Sonic: " * configs[:Sonic][i] * nl)
			write(fid,"Sonic: " * get(configs[i],"Sonic","") * nl)
			#write(fid,"Analyzer: " * configs[:Analyzer][i] * nl)
			write(fid,"Analyzer: " * get(configs[i],"Analyzer","") * nl)
			#write(fid,"Sonic alignment: " * string(configs[:Sonic_Alignment][i]) * " deg" * nl)
			write(fid,"Sonic alignment: " * string(get(configs[i],"Sonic_Alignment",0)) * " deg" * nl)
			#write(fid,"Sample frequency: " * configs[:Frequency][i] * " hz" * nl)
			write(fid,"Sample frequency: " * get(configs[i],"Frequency","0") * " hz" * nl)
			#write(fid,"Average time: " * string(configs[:Average_Time][i]) * " min" * nl)
			write(fid,"Average time: " * string(get(configs[i],"Average_Time",0)) * " min" * nl)
			for j=1:1:6
				#f = findall((in)(j),configs[:Analog_Inputs][i])
				f = findall((in)(j),get(configs[i],"Analog_Inputs",[0]))
				if !isempty(f)
					f = f[1]
					#write(fid,configs[:Analog_Names][i][f] * ", " * string(configs[:Analog_Lower][i][f]) * " , " * string(configs[:Analog_Upper][i][f]) * " , " * configs[:Analog_Units][i][f] * " , " * string(configs[:Analog_Delay][i][f]) * " , E" * nl)
					write(fid,get(configs[i],"Analog_Names",[""])[f] * ", " * string(get(configs[i],"Analog_Lower",[0])[f]) * " , " * string(get(configs[i],"Analog_Upper",[0])[f]) * " , " * get(configs[i],"Analog_Units",[""])[f] * " , " * string(get(configs[i],"Analog_Delay",[0])[f]) * " , E" * nl)
				else
					write(fid,"Analog " * string(j) * ", 0, 5000 , mV , 0 , D" * nl)
				end
			end
			#write(fid,"Station height: " * configs[:Station_Height][i] * " m" * nl)
			write(fid,"Station height: " * get(configs[i],"Station_Height","0") * " m" * nl)
			write(fid,"[Settings for EddyFlux]" * nl)
			#write(fid,"Measurement height: " * configs[:Measurement_Height][i] * " m" * nl)
			write(fid,"Measurement height: " * get(configs[i],"Measurement_Height","0") * " m" * nl)
			#write(fid,"Vegetation height: " * configs[:Vegetation_Height][i] * " m" * nl)
			write(fid,"Vegetation height: " * get(configs[i],"Vegetation_Height","0") * " m" * nl)
			#write(fid,"Inductance for CO2: " * configs[:Inductance_CO2][i] * " " * nl)
			write(fid,"Inductance for CO2: " * get(configs[i],"Inductance_CO2","0") * " " * nl)
			#write(fid,"Inductance for H2O: " * configs[:Inductance_H2O][i] * " " * nl)
			write(fid,"Inductance for H2O: " * get(configs[i],"Inductance_H2O","0") * " " * nl)
			#write(fid,"Coordinate rotation: " * configs[:Coordinate_Rotation][i] * nl)
			write(fid,"Coordinate rotation: " * get(configs[i],"Coordinate_Rotation","") * nl)
			#write(fid,"Webb correction: " * (configs[:Webb_Correction][i] ? "yes" : "no") * nl)
			write(fid,"Webb correction: " * (get(configs[i],"Webb_Correction",false) ? "yes" : "no") * nl)
			#write(fid,"Linear detrending: " * (configs[:Linear_Detrend][i] ? "yes" : "no") * nl)
			write(fid,"Linear detrending: " * (get(configs[i],"Linear_Detrend",false) ? "yes" : "no") * nl)
		catch
			close(fid)
			error("Error saving config settings")
		end
		close(fid)
	end
	
	# Process the FLX Files
	println("\nProcessing FLX Files")
	dfmt = Dates.DateFormat("dd.mm.yyyy HH:MM")
	for i=1:1:length(flxfiles)
		println("   " * flxfiles[i][end-15:end])
		new_time = flxdates[i] + dt
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(flxfiles[i][end-15]) * temp * ".flx")
		
		fid0 = open(flxfiles[i],"r")
		fid = open(new_filename,"w+")
		write(fid,readline(fid0))
		while eof(fid0) == false
			l = readline(fid0)
			temp_time = DateTime(l[1:16],dfmt) + dt
			l = Dates.format(temp_time,dfmt) * l[17:end] * nl
			write(fid,l)
		end
		close(fid)
		close(fid0)
	end
	
	# Process the LOG Files
	println("\nProcessing Log Files")
	dfmt = DateFormat("dd.mm.yyyy  HH:MM:SS")
	for i=1:1:length(logfiles)
		println("   " * logfiles[i][end-15:end])
		new_time = logdates[i] + dt
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(logfiles[i][end-15]) * temp * ".log")
		
		fid0 = open(logfiles[i],"r")
		fid = open(new_filename,"w+")
		while eof(fid0) == false
			l = readline(fid0)
			temp_time = DateTime(l[1:20],dfmt) + dt
			l = Dates.format(temp_time,dfmt) * l[21:end] * nl
			write(fid,l)
		end
		close(fid)
		close(fid0)
	end
	
	# Process the CSR Files
	println("\nProcessing CSR Files")
	dfmt = DateFormat("dd.mm.yyyy HH:MM")
	for i=1:1:length(csrfiles)
		println("   " * csrfiles[i][end-15:end])
		new_time = csrdates[i] + dt
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(csrfiles[i][end-15]) * temp * ".csr")
		
		fid0 = open(csrfiles[i],"r")
		fid = open(new_filename,"w+")
		write(fid,readline(fid0))
		while eof(fid0) == false
			l = readline(fid0)
			temp_time = DateTime(l[1:16],dfmt) + dt
			l = Dates.format(temp_time,dfmt) * l[17:end] * nl
			write(fid,l)
		end
		close(fid)
		close(fid0)
	end
	
	# Process the CSU Files
	println("\nProcessing CSU Files")
	for i=1:1:length(csufiles)
		println("   " * csufiles[i][end-15:end])
		new_time = csudates[i] + dt
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(csufiles[i][end-15]) * temp * ".csu")
		
		fid0 = open(csufiles[i],"r")
		fid = open(new_filename,"w+")
		write(fid,readline(fid0))
		while eof(fid0) == false
			l = readline(fid0)
			temp_time = DateTime(l[1:16],dfmt) + dt
			l = Dates.format(temp_time,dfmt) * l[17:end] * nl
			write(fid,l)
		end
		close(fid)
		close(fid0)
	end
	
	# Process the CSV Files
	println("\nProcessing CSV Files")
	for i=1:1:length(csvfiles)
		println("   " * csvfiles[i][end-15:end])
		new_time = csvdates[i] + dt
		
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(csvfiles[i][end-15]) * temp * ".csv")
		
		fid0 = open(csvfiles[i],"r")
		fid = open(new_filename,"w+")
		write(fid,readline(fid0))
		while eof(fid0) == false
			l = readline(fid0)
			temp_time = DateTime(l[1:16],dfmt) + dt
			l = Dates.format(temp_time,dfmt) * l[17:end] * nl
			write(fid,l)
		end
		close(fid)
		close(fid0)
	end
	
	# Load the SLT header data
	println("\nLoading SLT Header Data")
	sltinfo = DataFrame()
	offset = 1 # File processing list offset
	sltdates = sltdates .+ dt # Shift the SLT file dates so they match the shifted CFG dates
	while offset < length(sltfiles)
		f = findall(get.(configs,"Time",DateTime(0)) .<= sltdates[offset])[end] # Find latest config
		config1 = configs[f,:] # Current config and lower bound on file list
		config2 = configs[f+1,:] # Upper bound on file list
		
		f = findall(get.(config1,"Time",DateTime(0)) .<= sltdates .< get.(config2,"Time",DateTime(0)))
		tempfiles = sltfiles[f]
		analog_count = get(config1[1],"Analog_Count",0) # Length?
		sample_frequency = Meta.parse(get(config1[1],"Frequency","0"))
		for i=1:1:length(tempfiles)
			#println(tempfiles[i]) # Temp
			#println(analog_count) # Temp
			#println(sample_frequency) # Temp
			temp = slt_header(tempfiles[i],analog_count,sample_frequency)
			temp[:Analog_Count] = analog_count
			temp[:Sample_Frequency] = sample_frequency
			if isempty(sltinfo)
				sltinfo = temp
			else
				sltinfo = [sltinfo;temp]
			end
			offset += 1
		end
	end
	
	# Process the SLT Files
	println("\nProcessing SLT Files")
	for i = 1:1:size(sltinfo,1)
		new_time = sltinfo[:T0][i] + dt
		println("   " * sltinfo[:FileName][i][end-15:end])
		doy = @sprintf("%03u",Dates.dayofyear(new_time))
		temp = Dates.format(new_time,"yyyy" * doy * "HHMM")
		new_filename = joinpath(f2,string(sltinfo[:FileName][i][end-15]) * temp * ".slt")
		
		fid = open(new_filename,"w+") # Open New File
		# Write the header
		write(fid,Int8(sltinfo[:BytesPerRecord][i]))
		write(fid,Int8(sltinfo[:EddyMeas_Version][i]))
		write(fid,Int8(Day(new_time).value))
		write(fid,Int8(Month(new_time).value))
		yr1 = Int8(floor(Int(Year(new_time).value)/100))
		yr2 = Int8(Int(Year(new_time).value) - 100*floor(Int(Year(new_time).value)/100))
		write(fid,yr1)
		write(fid,yr2)
		write(fid,Int8(Hour(new_time).value))
		write(fid,Int8(Minute(new_time).value))
		
		# Write Channels and Bit Masks
		for j=1:1:sltinfo[:Analog_Count][i]
			write(fid,Int8(sltinfo[:Bit_Mask][i][j])) # Bit Mask
			write(fid,Int8(sltinfo[:Channels][i][j])) # Channel
		end
		
		# Read and Write Data
		fid0 = open(sltinfo[:FileName][i]) # Open Original File
		seek(fid0,sltinfo[:Start_Pos][i]) # Move file position to data
		early_end = false
		for j=1:1:sltinfo[:Line_Count][i]*(4 + length(sltinfo[:Channels][i]))
			if eof(fid0)
				early_end = true
			else
				#temp_data = read(fid0,Int16,1)
				temp_data = read!(fid0,Array{Int16}(undef,1))
				write(fid,temp_data)
			end
		end
		early_end ? println("    Early End of File: " * string(sltinfo[:Line_Count][i]) * " lines") : nothing # Temp
		close(fid0) # Close Original File
		close(fid) # Close New File
	end
end # slt_timeshift(f1::String,f2::String,mindate::DateTime,maxdate::DateTime,dt::Period)
