# ghg_read.jl
#
#   Load a GHG file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 18.11.2014
# Last Edit: 19.12.2016

"# ghg_read(source::String,minimumdate::DateTime,maximumdate::DateTime;recur_depth::Int,verbose::Bool,average::Bool)

`time,data = ghg_read(source)` Load a single GHG file\n
* **source**::String = Single GHG file or a directory of GHG files

---

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default\n\n"
function ghg_read(source::String;verbose::Bool=false)
	
	epoch = DateTime(1970,1,1,1) # Licor epoch
	
	##################
	##  Initialize  ##
	##################
	#epoch = DateTime(1970)
	if is_linux() || is_apple()
		temp_dir = "/tmp/"
	elseif is_windows()
		temp_dir = ENV["temp"]
	end
	D = DataFrame()
	t = DateTime[]
	
	#############
	##  Unzip  ##
	#############
	verbose ? println("\t   Unzipping") : nothing
	if is_windows()
		list = ZipFile.Reader(source) # List the files in the GHG file
		for i=1:1:length(list.files)
			if splitext(list.files[i].name)[2] == ".data"
				fid = open(joinpath(temp_dir,list.files[i].name),"w")
				write(fid,readstring(list.files[i]))
				close(fid)
			end
		end
	elseif is_linux()
		temp = []
		try
			temp = readstring(`unzip -d $temp_dir $source`)
		catch
			warn("Failed to unzip " * temp)
			return
		end
	end
	
	#################
	##  Load Data  ##
	#################
	# Load Header
	(name,ext) = splitext(basename(source))
	temp = joinpath(temp_dir,name * ".data")
	verbose ? println("\t   Loading " * joinpath(temp_dir,name * ".data")) : nothing
	header_line = 7
	fid = open(temp,"r")
	for j=1:1:header_line
		readline(fid)
	end
	cols = permutedims(readcsv(IOBuffer("\"" * replace(readline(fid)[1:end-1],"\t","\",\"") * "\"")),[2,1])
	close(fid)
	new_names = Array(Symbol,length(cols))
	temp_name = ""
	for i=1:1:length(cols)
		temp_name = replace(cols[i]," ","_")
		temp_name = replace(replace(temp_name,"(",""),")","")
		temp_name = replace(replace(temp_name,"%",""),"^","")
		temp_name = replace(temp_name,"_-","")
		temp_name = replace(temp_name,"/","_per_")
		new_names[i] = Symbol(temp_name)
	end
	
	# Load Data
	col_types = fill!(Array(DataType,length(cols)),Float64)
	col_types[1:8] = [String;Int64;Int64;Int64;Int64;Int64;String;String]
	D = DataFrames.readtable(temp,eltypes = col_types,separator = '\t',header = false,skipstart = header_line + 1)
	verbose ? println("\t   Deleting temporary files") : nothing
	rm(temp) # Remove the temporary data file
	temp = joinpath(temp_dir,name * ".metadata")
	isfile(temp) && rm(temp) # Delete the temporary metadata file if it exists
	names!(D,new_names)
	
	# Convert Time
	t = epoch + map(Dates.Second,Array(D[:Seconds])) + map(Dates.Millisecond,Array(D[:Nanoseconds])./1e6)
	
	return t,D,cols
end
