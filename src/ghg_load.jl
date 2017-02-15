# ghg_load.jl
#
#   Load GHG files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 18.11.2014
# Last Edit: 14.02.2017

# General TODOs
#	- Limit the output to the actual min and max dates (currently not trimmed)

"# ghg_load(source::String,minimumdate::DateTime,maximumdate::DateTime;recur_depth::Int,verbose::Bool,average::Bool)

`time,data = ghg_load(source,minimumdate)` Load all data including and after the given date\n
* **minimumdate**::DateTime = Starting date to load data from

`time,data = ghg_load(source,minimumdate,maximumdate)` Load all data including and after the given date\n
* **maximumdate**::DateTime = Load data before this date

`time,davg,dstd,dmin,dmax = ghg_load(source,average=true)` Return the averaged values\n
* **davg**::Array(Float64,1) = Half hour average of the data
* **dstd**::Array(Float64,1) = Half hour standard deviations of the data
* **dmin**::Array(Float64,1) = Minimum values from each half hour
* **dmax**::Array(Float64,1) = Maximum values from each half hour


---

#### Keywords:\n
* recur::Int = Subdirectory recursion depth. 1 is the root directory.
* verbose::Bool = Display information as the function runs, TRUE is default
* average::Bool = Half hour average the data starting at the first data point, TRUE is default\n\n"
function ghg_load(source::String,mindate::DateTime=DateTime(0),maxdate::DateTime=DateTime(9999);recur::Int=1,verbose::Bool=true,average::Bool=true)
	##############
	##  Checks  ##
	##############
	if isfile(source)
		return ghg_read(source,verbose=verbose)
	end
	!isdir(source) ? error("Date Ranges can only be used when a directory is given as an input") : nothing
	maxdate <= mindate ? error("Maximum date must be greater than the minimum date") : nothing
	
	#################
	##  Constants  ##
	#################
	#epoch = DateTime(1970,1,1,1)
	
	##################
	##  List Files  ##
	##################
	(files,folder) = dirlist(source,regex=r"\.ghg$",recur=recur)
	
	###################################
	##  Convert File Times and Sort  ##
	###################################
	times = Array(DateTime,length(files))
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
	f = find(mindate .<= times .< maxdate)
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
		(t_temp,D_temp,cols) = ghg_read(files[i],verbose=verbose)
		
		if average
			########################
			##  Average the Data  ##
			########################
			verbose ? println("\t   Averaging Data") : nothing
			f = [findnewton(t_temp,[minimum(t_temp) - Dates.Millisecond(minimum(t_temp)):Dates.Minute(30):maximum(t_temp);]),length(t_temp) + 1;]
			for j=1:1:length(f)-1
				temp_mean = mean(convert(Array,D_temp[f[j]:f[j+1]-1,9:end-1]),1)
				temp_std = std(convert(Array,D_temp[f[j]:f[j+1]-1,9:end-1]),1)
				temp_min = minimum(convert(Array,D_temp[f[j]:f[j+1]-1,9:end-1]),1)
				temp_max = maximum(convert(Array,D_temp[f[j]:f[j+1]-1,9:end-1]),1)
				
				if isempty(D_mean)
					t_mean = t_temp[f[j]]
					D_mean = temp_mean
					D_std = temp_std
					D_min = temp_min
					D_max = temp_max
				else
					t_mean = [t_mean;t_temp[f[j]]]
					D_mean = [D_mean;temp_mean]
					D_std = [D_std;temp_std]
					D_min = [D_min;temp_min]
					D_max = [D_max;temp_max]
				end
			end
		else
			##################
			##  No Average  ##
			##################
			if isempty(D)
				t = t_temp
				D = D_temp
			else
				t = [t;t_temp]
				D = [D;D_temp]
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
		return t, D
	end
end
