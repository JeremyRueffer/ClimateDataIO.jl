# ghg_read.jl
#
#   Load a GHG file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.3
# 18.11.2014
# Last Edit: 19.06.2018

"# ghg_read(source::String,verbose::Bool,filetype::String)

`time,data = ghg_read(source)` Load a single GHG file\n
* **source**::String = Single GHG file or a directory of GHG files

---

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default
* filetype::String = Data file type to load, \"primary\" is default and loads the primary high frequency file. \"biomet\" would load the BIOMET file if it is present.\n\n"
function ghg_read(source::String;verbose::Bool=false,filetype::String="primary")
	##################
	##  Initialize  ##
	##################
	epoch = DateTime(1970,1,1,1) # Licor epoch
	D = DataFrame()
	t = DateTime[]
	dfmt = Dates.DateFormat("yyyy-mm-dd HH:MM:SS:sss")
	rootnamereg = r"\d{4}\-\d{2}\-\d{2}T\d{6}_AIU\-\d{4}" # Regular expression for the basic file name
	
	#################
	##  Load Data  ##
	#################
	# Load Header
	list = ZipFile.Reader(source) # List the files in the GHG file
	iData = 0
	hf = false # High frequency?
	for i=1:1:length(list.files)
		if length(list.files[i].name) >= 31
			if ismatch(rootnamereg,list.files[i].name[1:26])
				if filetype == "primary" && length(list.files[i].name) == 31
					iData = i
					hf = true
				elseif filetype == "biomet" && list.files[i].name[end-10:end] == "biomet.data"
					iData = i
					hf = false
				end
			end
		end
	end
	(name,ext) = splitext(basename(source))
	verbose ? println("\t   Loading " * name * ".data") : nothing
	
	###########################
	##  High Frequency Data  ##
	###########################
	t = Array{DateTime}(0)
	D = DataFrame()
	cols = Array{Any}(0,0)
	if iData != 0
		if filetype == "primary"
			header_line = 9
		else
			header_line = 7
		end
		for j=1:1:header_line - 2
			readline(list.files[iData])
		end
		l_columns = readline(list.files[iData])
		cols = permutedims(readcsv(IOBuffer("\"" * replace(l_columns,"\t","\",\"") * "\"")),[2,1])
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
		if filetype == "primary"
			col_types[1:8] = [String;Int;Int;Int;Int;Int;String;String]
			col_types[end] = Int
		else
			col_types[1:3] = [String;String;String]
			col_types[end] = Int
		end
		# datarow = 1, the position within the file is just at the start of the data already because of the header loading
		D = CSV.read(list.files[iData],types = col_types,header = new_names,delim = '\t',datarow = 1)
		
		# Convert Time
		#t = epoch + map(Dates.Second,Array(D[:Seconds])) + map(Dates.Millisecond,floor.(Array(D[:Nanoseconds])./1e6))
		t = Array{DateTime}(size(D,1)) # Preallocate
		if hf
			for j=1:1:length(t)
				# Normal Data
				t[j] = DateTime.(D[:Date][j] * " " * D[:Time][j],dfmt)
			end
		else
			for j=1:1:length(t)
				# Biomet
				t[j] = DateTime.(D[:DATE][j] * " " * D[:TIME][j],dfmt)
			end
		end
	end
	
	##############
	##  Output  ##
	##############
	return t,D,cols
end
