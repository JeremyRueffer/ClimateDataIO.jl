# ghg_load.jl
#
#   Load GHG files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.6.0
# 18.11.2014
# Last Edit: 28.04.2021

# General TODOs
#	- Limit the output to the actual min and max dates (currently not trimmed)

"# ghg_load(source::String,minimumdate::DateTime,maximumdate::DateTime;filetype::String,recur_depth::Int,verbose::Bool,average::Bool)

`time,data = ghg_load(source,minimumdate)` Load all data including and after the given date\n
* **minimumdate**::DateTime = Starting date to load data from

`time,data = ghg_load(source,minimumdate,maximumdate)` Load all data including and after the given date\n
* **maximumdate**::DateTime = Load data before this date

`time,davg,dstd,dmin,dmax = ghg_load(source,average=true)` Return the averaged values\n
* **davg**::Array{Float64}(1) = Half hour average of the data
* **dstd**::Array{Float64}(1) = Half hour standard deviations of the data
* **dmin**::Array{Float64}(1) = Minimum values from each half hour
* **dmax**::Array{Float64}(1) = Maximum values from each half hour


---

#### Keywords:\n
* recur::Int = Subdirectory recursion depth. 1 is the root directory.
* verbose::Bool = Display information as the function runs, TRUE is default
* average::Bool = Half hour average the data starting at the first data point, TRUE is default
* filetype::String = Data file type to load, \"primary\" is default and loads the primary high frequency file. \"biomet\" would load the BIOMET file if it is present.
* errorlog::String = Log each loading error, \"\" is default\n\n"
function ghg_load(source::String,mindate::DateTime=DateTime(0),maxdate::DateTime=DateTime(9999);filetype::String="primary",recur::Int=1,verbose::Bool=true,average::Bool=true,errorlog::String="",multithread::Bool=false,nThreads::Int=Threads.nthreads())
	##############
	##  Checks  ##
	##############
	if isfile(source)
		return ghg_read(source,verbose=verbose,filetype=filetype,errorlog=errorlog)
	end
	
	!isdir(source) ? error("Date Ranges can only be used when a directory is given as an input") : nothing
	maxdate <= mindate ? error("Maximum date must be greater than the minimum date") : nothing
	
	##################
	##  List Files  ##
	##################
	(files,folder) = dirlist(source,regex=r"\.ghg$",recur=recur)
	
	###################################
	##  Convert File Times and Sort  ##
	###################################
	times = Array{DateTime}(undef,length(files))
	df = Dates.DateFormat("yyyy-mm-ddTHHMMSS")
	for i=1:1:length(files)
		temp = basename(files[i])
		times[i] = DateTime(temp[1:17],df)
	end
	f = sortperm(times)
	times = times[f]
	files = files[f]
	
	######################################
	##  Remove Files Out of Time Range  ##
	######################################
	f = findall(mindate .<= times .< maxdate)
	times = times[f]
	files = files[f]
	
	###################################
	##  Initialize Output Variables  ##
	###################################
	D = DataFrame()
	t = DateTime[]
	t_mean = DateTime[]
	D_mean = Float64[]
	D_std = Float64[]
	D_min = Float64[]
	D_max = Float64[]
	cols = String[]
	pos = 1
	
	#######################
	##  Multi-threading  ##
	#######################
	current_thread = [1] # Which thread gets to write at this moment. It is an array so it will be passed by reference and every thread will read the same value.
	multithread ? nThreads = nThreads : nThreads = 1
	nThreads > Threads.nthreads() ? nThreads = Threads.nthreads() : nothing # Ensure the thread count isn't higher than the number set in JULIA_NUM_THREADS
	
	###################
	## Load the Data ##
	###################
	if verbose
		println("GHG Source: " * source)
		println("Load " * string(length(files)) * " GHG files")
	end
	for i=1:nThreads:length(files)
		if nThreads == 1
			if verbose
				println("\t" * string(i) * ": " * files[i])
			end
			
			# Single-threaded load
			(t_temp,D_temp,cols) = ghg_read(files[i],verbose=verbose,filetype=filetype,errorlog=errorlog)
		else
			# Multi-threaded load
			current_thread[1] = 1 # Reset the thread tracker
			max_count = nThreads
			t_temp = [Array{DateTime}(undef,0)] # Preallocate empty DateTime array so new values can be appended, encasing it in an array so it ca be passed by reference
			D_temp = [DataFrame()] # Preallocate empty dataframes so new ones can be appended, encasing it in an array so it ca be passed by reference
			if i + max_count - 1 > length(files)
				max_count = length(files) - i + 1
			end
			
			if verbose
				for k=i:1:i+max_count-1
					println("\t" * string(k) * ": " * files[k])
				end
			end
			Threads.@threads for j=1:1:max_count
				cols = multithreadLoad(t_temp,D_temp,current_thread,files[i:i+max_count-1],false,filetype,errorlog)
			end
			
			# Remove encasing arrays
			t_temp = t_temp[1]
			D_temp = D_temp[1]
		end
		if isempty(t_temp) && isempty(D_temp) && isempty(cols)
			# Likely a corrupt file, skip to the next
			continue
		end
		if Sys.iswindows()
			# Garbage collection ensures the temporary file is closed so that it can be deleted.
			# Windows does not seem to close it in time whereas Linux does
			GC.gc()
		end
		
		if average
			########################
			##  Average the Data  ##
			########################
			verbose ? println("\t   Averaging Data") : nothing
			target = collect((minimum(t_temp) - Dates.Millisecond(minimum(t_temp))):Dates.Minute(30):maximum(t_temp))
			f = [findnewton(t_temp,target);(length(t_temp) + 1)]
			
			# Preallocate DataFrames
			type_list = Array{DataType}(undef,size(D_temp)[2])
			for j=1:1:size(D_temp)[2]
				temp = typeof(D_temp[!,j][1])
				if temp <: Integer
					temp = typeof(1.0)
				end
				type_list[j] = temp
			end
			D_mean_temp = DataFrame([Array{i}(undef,length(f)-1) for i in type_list],
					names(D_temp))
			D_std_temp = DataFrame([Array{i}(undef,length(f)-1) for i in type_list],
					names(D_temp))
			D_min_temp = DataFrame([Array{i}(undef,length(f)-1) for i in type_list],
					names(D_temp))
			D_max_temp = DataFrame([Array{i}(undef,length(f)-1) for i in type_list],
					names(D_temp))
			
			for j=1:1:length(f)-1
				for k=1:1:length(type_list)
					if type_list[k] == String
						tempStr = unique(D_temp[f[j]:f[j+1]-1,k])
						if length(tempStr) != 1
							tempStr = ["Mixed"]
						end
						D_mean_temp[j,k] = tempStr[1]
						D_std_temp[j,k] = tempStr[1]
						D_min_temp[j,k] = tempStr[1]
						D_max_temp[j,k] = tempStr[1]
					else
						D_mean_temp[j,k] = mean(convert(Array,D_temp[f[j]:f[j+1]-1,k]))
						D_std_temp[j,k] = std(convert(Array,D_temp[f[j]:f[j+1]-1,k]))
						D_min_temp[j,k] = minimum(convert(Array,D_temp[f[j]:f[j+1]-1,k]))
						D_max_temp[j,k] = maximum(convert(Array,D_temp[f[j]:f[j+1]-1,k]))
					end
				end
				
				if isempty(D_mean)
					t_mean = t_temp[f[j]]
				else
					t_mean = [t_mean;t_temp[f[j]]]
				end
			end
			
			if isempty(D_mean)
				D_mean = D_mean_temp
				D_std = D_std_temp
				D_min = D_min_temp
				D_max = D_max_temp
			else
				D_mean = [D_mean;D_mean_temp]
				D_std = [D_std;D_std_temp]
				D_min = [D_min;D_min_temp]
				D_max = [D_max;D_max_temp]
			end
		else
			##################
			##  No Average  ##
			##################
			# Constants
			buffer = 0.02 # 2%, extra pre-allocation space for unforseen file irregularities
			if isempty(D)
				# Determine time range of files to be loaded
				pos = 1 # Writing start position
				min = minimum(times)
				max = maximum(times)
				dT = median(Dates.value.(diff(t_temp)))
				if length(times) > 1
					# Case: Multiple Files
					dTfiles = median(Dates.value.(diff(times)))
					
					# Estimate the number of lines based on the first file
					est = Int64(floor((1 + buffer)*((max - min)/Millisecond(dT) + dTfiles/dT)))
				else
					# Case: Single File
					est = length(t_temp)
				end
				
				# Preallocate the final array
				t = Array{DateTime}(undef,est)
				Dinfo = describe(D_temp)
				D = DataFrame([Array{i}(undef,est) for i in Dinfo.eltype],Dinfo.variable)
				
				# Add the initial dataset
				lD = size(D_temp,1) # Length of first dataframe
				t[1:lD] = t_temp
				D[1:lD,:] .= D_temp
				
				# Initialize array indexer
				pos = lD + 1 # Position to start writing the current dataset
			else
				lD = length(t_temp) # Length of the dataframe to be added
				t[pos:pos+lD-1] = t_temp
				D[pos:pos+lD-1,:] .= D_temp
				pos = pos + lD
			end
		end
		verbose ? println("") : nothing
	end
	
	##############
	##  Output  ##
	##############
	verbose ? println("GHG Load Complete") : nothing
	if average
		return t_mean, D_mean, D_std, D_min, D_max
	else
		return t[1:pos-1], D[1:pos-1,:]
	end
end

function multithreadLoad(timeOut::Array{Array{DateTime,1},1},dataOut::Array{DataFrame,1},current_thread::Array{Int,1},files::Array{String,1},verbose::Bool,filetype::String,errorlog::String)
	# Constants
	thread_start = now()
	dt = Minute(1) # Time to timeout
	
	# Load the data
	time, data, cols = ghg_read(files[Threads.threadid()],verbose=verbose,filetype=filetype,errorlog=errorlog)
	
	# Once the data is loaded, wait until it's this thread's turn to append the data
	while current_thread[1] != Threads.threadid() || now() - thread_start >= dt
		if now() - thread_start >= dt
			error("Timeout")
		else
			sleep(1.0)
		end
	end
	
	# Append the data and increment current thread value
	if !isempty(time)
		# TODO: Check that the columns match, needed?
		
		timeOut[1] = [timeOut[1];time] # Append time data
		dataOut[1] = [dataOut[1];data] # Append data
		current_thread[1] = current_thread[1] + 1 # Update which thread is allowed to write
	end
	
	return cols # Needed?
end