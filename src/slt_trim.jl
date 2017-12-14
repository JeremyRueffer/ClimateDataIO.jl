# slt_trim.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.1
# 09.12.2016
# Last Edit: 06.12.2017

"""# slt_trim

Remove columns from SLT files, source files must not have all equal numbers of columns

`slt_trim(source,destination,mindate,maxdate,maxanalogcols)`\n
* **source**::String = Source directory, `\"K:\\Data\"`
* **destination**::String = Destination directory, `\"K:\\Data\"`
* **mindate**::DateTime = Start of period to process
* **maxdate**::DateTime = End of period to process
* **maxanalogcols**::Int = Maximum number of columns that should remain"""
function slt_trim(f1::String,f2::String,mindate::DateTime,maxdate::DateTime,maxanalogcols::Int)
	# f1::String # Source Directory
	# f2::String # Destination Directory
	# mindate::DateTime
	# maxdate::DateTime
	# maxanalogcols::Int # Maximum number of analog columns
	
	# Check Inputs
	if !isdir(f1)
		error("First input must be a directory")
	end
	if !isdir(f2)
		error("Second input must be a directory")
	end
	
	# List and sort files
	(files,folders) = dirlist(f1,regex=r"\w\d{8}\.")
	
	# Parse File Dates
	fdates = Array{DateTime}(length(files))
	i = 0
	for i=1:1:length(files)
		try
			yearstr = parse(files[i][end-14:end-11])
			daystr = parse(files[i][end-10:end-8])
			hourstr = parse(files[i][end-7:end-6])
			minutestr = parse(files[i][end-5:end-4])
			fdates[i] = DateTime(yearstr) + Dates.Day(daystr) - Dates.Day(1) + Dates.Hour(hourstr) + Dates.Minute(minutestr)
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
	f = [ismatch(r"\.cfg$",i) for i in files]
	cfgfiles = files[f]
	cfgdates = fdates[f]
	
	# Remove files beyond the given time bounds
	f = find(mindate .<= fdates)
	fdates = fdates[f]
	files = files[f]
	f = find(maxdate .> fdates)
	fdates = fdates[f]
	files = files[f]
	
	# Display Info
	println("Adjusting SLT Analog Columns")
	println("   Source:      " * f1)
	println("   Destination: " * f2)
	println("   Number of files: " * string(length(files)))
	
	# Sort Files by Type
	f = [ismatch(r"\.slt$",i) for i in files]
	sltfiles = files[f]
	sltdates = fdates[f]
	f = [ismatch(r"\.csr$",i) for i in files]
	csrfiles = files[f]
	csrdates = fdates[f]
	f = [ismatch(r"\.csu$",i) for i in files]
	csufiles = files[f]
	csudates = fdates[f]
	f = [ismatch(r"\.flx$",i) for i in files]
	flxfiles = files[f]
	flxdates = fdates[f]
	f = [ismatch(r"\.log$",i) for i in files]
	logfiles = files[f]
	logdates = fdates[f]
	f = [ismatch(r"\.csv$",i) for i in files]
	csvfiles = files[f]
	csvdates = fdates[f]
	
	# Load the CFG info
	configs = slt_config(cfgfiles)
	begin
		temp = configs[end,:]
		temp[:Time] = DateTime(9999) # Setup a fake final row with a time well beyond any real file name
		configs = [configs;temp]
	end
	
	# Load the SLT header data
	println("\nLoading SLT Header Data")
	sltinfo = DataFrame()
	offset = 1 # File processing list offset
	while offset < length(sltfiles)
		f = find(configs[:Time] .<= sltdates[offset])[end] # Find latest config
		config1 = configs[f,:] # Current config and lower bound on file list
		config2 = configs[f+1,:] # Upper bound on file list
		
		f = find(config1[:Time] .<= sltdates .< config2[:Time])
		tempfiles = sltfiles[f]
		analog_count = config1[:Analog_Count][1] # Length?
		sample_frequency = parse(config1[:Frequency][1])
		for i=1:1:length(tempfiles)
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
		temp = splitdir(sltinfo[:FileName][i])[2]
		new_filename = joinpath(f2,temp)
		
		# Column Difference
		colldiff = length(sltinfo[:Channels][i]) - maxanalogcols
		if colldiff <= 0
			println("   ## " * temp * " ##   - Too few columns, skipped")
			continue
		end
		println("   " * temp * ", " * string(colldiff) * " columns removed")
		
		fid = open(new_filename,"w+") # Open New File
		# Write the header
		write(fid,Int8(2(maxanalogcols + 4))) # Bytes per record = Number of columns x 2
		write(fid,Int8(sltinfo[:EddyMeas_Version][i]))
		write(fid,Int8(Dates.value(Dates.Day(sltinfo[:T0][i]))))
		write(fid,Int8(Dates.value(Dates.Month(sltinfo[:T0][i]))))
		yr1 = Int8(floor(Float64(Dates.value(Dates.Year(sltinfo[:T0][i])))/100))
		yr2 = Int8(Int(Dates.value(Dates.Year(sltinfo[:T0][i]))) - 100*floor(Float64(Dates.value(Dates.Year(sltinfo[:T0][i])))/100))
		write(fid,yr1)
		write(fid,yr2)
		write(fid,Int8(Dates.value(Dates.Hour(sltinfo[:T0][i]))))
		write(fid,Int8(Dates.value(Dates.Minute(sltinfo[:T0][i]))))
		
		# Write Channels and Bit Masks
		for j=1:1:sltinfo[:Analog_Count][i] - colldiff
			write(fid,Int8(sltinfo[:Bit_Mask][i][j])) # Bit Mask
			write(fid,Int8(sltinfo[:Channels][i][j])) # Channel
		end
		
		# Read and Write Data
		fid0 = open(sltinfo[:FileName][i]) # Open Original File
		seek(fid0,sltinfo[:Start_Pos][i]) # Move file position to data
		early_end = false
		for j=1:1:sltinfo[:Line_Count][i]
			for k=1:1:4 + length(sltinfo[:Channels][i]) - colldiff
				if eof(fid0)
					early_end = true
				else
					temp_data = read(fid0,Int16,1)
					
					# Only save columns within column limit
					write(fid,temp_data)
				end
			end
			for k = 1:1:colldiff
				if eof(fid0)
					early_end = true
				else
					temp_data = read(fid0,Int16,1)
				end
			end
		end
		if early_end
			println("    Early End of File: " * string(sltinfo[:Line_Count][i]) * " lines") # Temp
		end
		close(fid0) # Close Original File
		close(fid) # Close New File
	end
	
	# Process CFG Files
	println("\nModifying CFG Files")
	for i=cfgfiles
		println("   " * splitdir(i)[2])
		fid1 = open(i,"r")
		fid2 = open(joinpath(f2,splitdir(i)[2]),"w+")
		
		for j=1:1:6 + maxanalogcols
			write(fid2,[readline(fid1,chomp=false)])
		end
		
		for j=1:1:6 - maxanalogcols
			readline(fid1) # Skip line
			write(fid2,"Analog " * string(j+maxanalogcols) * ", 0 , 5000 , mV , 0 , D\n")
		end
		
		for j=1:1:9
			write(fid2,[readline(fid1,chomp=false)])
		end
		
		close(fid1)
		close(fid2)
	end
	
	# Process CSR Files
	println("\nCopying CSR Files")
	for i=csrfiles
		println("   " * splitdir(i)[2])
		cp(i,joinpath(f2,splitdir(i)[2]))
	end
	
	# Process CSU Files
	println("\nCopying CSU Files")
	for i=csufiles
		println("   " * splitdir(i)[2])
		cp(i,joinpath(f2,splitdir(i)[2]))
	end
	
	# Process CSV Files
	println("\nCopying CSV Files")
	for i=csvfiles
		println("   " * splitdir(i)[2])
		cp(i,joinpath(f2,splitdir(i)[2]))
	end
	
	# Process LOG Files
	println("\nCopying LOG Files")
	for i=logfiles
		println("   " * splitdir(i)[2])
		cp(i,joinpath(f2,splitdir(i)[2]))
	end
	
	# Process FLX Files
	println("\nCopying FLX Files")
	for i=flxfiles
		println("   " * splitdir(i)[2])
		cp(i,joinpath(f2,splitdir(i)[2]))
	end
end # slt_trim(f1::String,f2::String,mindate::DateTime,maxdate::DateTime,maxanalogcols::Int)
