# ghg_read.jl
#
#   Load a GHG file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.2
# 18.11.2014
# Last Edit: 29.03.2018

"# ghg_read(source::String,minimumdate::DateTime,maximumdate::DateTime;recur_depth::Int,verbose::Bool,average::Bool)

`time,data = ghg_read(source)` Load a single GHG file\n
* **source**::String = Single GHG file or a directory of GHG files

---

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default\n\n"
function ghg_read(source::String;verbose::Bool=false)
	##################
	##  Initialize  ##
	##################
	epoch = DateTime(1970,1,1,1) # Licor epoch
	D = DataFrame()
	t = DateTime[]
	
	#################
	##  Load Data  ##
	#################
	# Load Header
	list = ZipFile.Reader(source) # List the files in the GHG file
	(name,ext) = splitext(basename(source))
	verbose ? println("\t   Loading " * name * ".data") : nothing
	header_line = 9
	for j=1:1:header_line - 2
		readline(list.files[1])
	end
	cols = permutedims(readcsv(IOBuffer("\"" * replace(readline(list.files[1]),"\t","\",\"") * "\"")),[2,1])
	new_names = Array{String}(length(cols))
	temp_name = ""
	for i=1:1:length(cols)
		temp_name = replace(cols[i]," ","_")
		temp_name = replace(replace(temp_name,"(",""),")","")
		temp_name = replace(replace(temp_name,"%",""),"^","")
		temp_name = replace(temp_name,"_-","")
		temp_name = replace(temp_name,"/","_per_")
		new_names[i] = temp_name
	end
	
	# Load Data
	col_types = fill!(Array{DataType}(length(cols)),Float64)
	col_types[1:8] = [String;Int;Int;Int;Int;Int;String;String]
	# datarow = 1, the position within the file is just at the start of the data already because of the header loading
	D = CSV.read(list.files[1],types = col_types,header = new_names,delim = '\t',datarow = 1)
	
	# Convert Time
	t = epoch + map(Dates.Second,Array(D[:Seconds])) + map(Dates.Millisecond,Array(D[:Nanoseconds])./1e6)
	
	return t,D,cols
end
