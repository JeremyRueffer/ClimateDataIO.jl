# ghg_load.jl
#
#   Load GHG files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.1.0
# 18.11.2014
# Last Edit: 30.07.2019

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
* filetype::String = Data file type to load, \"primary\" is default and loads the primary high frequency file. \"biomet\" would load the BIOMET file if it is present.\n\n"
function ghg_load(source::String,mindate::DateTime=DateTime(0),maxdate::DateTime=DateTime(9999);filetype::String="primary",recur::Int=1,verbose::Bool=true,average::Bool=true)
	##############
	##  Checks  ##
	##############
	if isfile(source)
		return ghg_read(source,verbose=verbose)
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
	
	###################
	## Load the Data ##
	###################
	if verbose
		println("GHG Source: " * source)
		println("Load " * string(length(files)) * " GHG files")
	end
	for i=1:1:length(files)
		if verbose
			println("\t" * string(i) * ": " * files[i])
		end
		(t_temp,D_temp,cols) = ghg_read(files[i],verbose=verbose,filetype=filetype)
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
				temp = typeof(D_temp[j][1])
				if temp <: Integer
					temp = typeof(1.0)
				end
				type_list[j] = temp
			end
			D_mean_temp = DataFrame(type_list,names(D_temp),length(f)-1)
			D_std_temp = DataFrame(type_list,names(D_temp),length(f)-1)
			D_min_temp = DataFrame(type_list,names(D_temp),length(f)-1)
			D_max_temp = DataFrame(type_list,names(D_temp),length(f)-1)
			
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
				dTfiles = median(Dates.value.(diff(times)))
				
				# Estimate the number of lines based on the first file
				est = Int64(floor((1 + buffer)*((max - min)/Millisecond(dT) + dTfiles/dT)))
				println("Estimated Line Count: " * string(est))
				
				# Preallocate the final array
				t = Array{DateTime}(undef,est)
				Dinfo = describe(D_temp)
				D = DataFrame(Dinfo.eltype,Dinfo.variable,est)
				
				# Add the initial dataset
				lD = size(D_temp,1) # Length of first dataframe
				t[1:lD] = t_temp
				D[1:lD,:] = D_temp
				
				# Initialize array indexer
				pos = lD + 1 # Position to start writing the current dataset
			else
				lD = length(t_temp) # Length of the dataframe to be added
				t[pos:pos+lD-1] = t_temp
				D[pos:pos+lD-1,:] = D_temp
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
