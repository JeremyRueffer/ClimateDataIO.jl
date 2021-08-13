# ghg_read.jl
#
#   Load a GHG file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.6.2
# 18.11.2014
# Last Edit: 13.08.2021

"# ghg_read(source::String,verbose::Bool,filetype::String)

`time,data = ghg_read(source)` Load a single GHG file\n
* **source**::String = Single GHG file or a directory of GHG files

---

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default
* filetype::String = Data file type to load, \"primary\" is default and loads the primary high frequency file. \"biomet\" would load the BIOMET file if it is present.
* errorlog::String = Log each loading error, \"\" is default
* select::Vector{Symbol} (optional) = List of column names to be loaded, names not included will not be loaded. [] is default\n\n"
function ghg_read(source::String;verbose::Bool=false,filetype::String="primary",errorlog::String="",select::Vector{Symbol}=Symbol[])
	####################
	##  SELECT Check  ##
	####################
	if !isempty(select)
		if filetype == "primary"
			select = [setdiff([:Date,:Time]);select] # Date and Time must be included
		elseif filetype == "biomet"
			select = [setdiff([:DATE,:TIME]);select] # Date and Time must be included
		end
	end
	
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
	list = []
	try
		list = zipList(source) # List the files in the GHG file
	catch
		@warn("Failed to read " * source)
		if !isempty(errorlog)
			try
				fid3 = open(errorlog,"a+")
				write(fid3,filetype * ", failed to read: " * source * "\r\n")
				close(fid3)
			catch
				@warn("Writing problem \"failed to read\"")
			end
		end
		return Array{DateTime}(undef,0), DataFrame(), ""
	end
	iData = 0
	hf = false # High frequency?
	for i=1:1:length(list)
		if length(list[i]) >= 31
			if occursin(rootnamereg,list[i][1:26])
				if filetype == "primary" && length(list[i]) == 31
					iData = i
					hf = true
				elseif filetype == "biomet" && list[i][end-10:end] == "biomet.data"
					iData = i
					hf = false
				end
			end
		end
	end
	
	#############
	##  Unzip  ##
	#############
	verbose ? println("\t   Unzipping") : nothing
	temp_dir = tempdir() # Temporary directory for unzipped files
	if iData > 0
		if Sys.iswindows()
			if filetype == "biomet"
				subfile = splitext(basename(source))[1] * "-biomet.data"
			else
				subfile = splitext(basename(source))[1] * ".data"
			end
			
			#read(`$exe7z x $source -y -o$temp_dir $subfile`); # Temp
			zipExtractFile(source,temp_dir,subfile)
		elseif Sys.islinux()
			if filetype == "primary"
				ext = ".data"
			else
				ext = "-biomet.data"
			end
			try
				run(pipeline(`unzip -p $[source] $[splitext(splitdir(source)[2])[1]]$[ext]`,joinpath(temp_dir,splitext(splitdir(source)[2])[1] * ext)))
			catch
				@warn("Failed to unzip " * source)
				if !isempty(errorlog)
					try
						fid3 = open(errorlog,"a+")
						write(fid3,filetype * ", failed to unzip: " * source * "\r\n")
						close(fid3)
					catch
						@warn("Writing problem \"failed to unzip\"")
					end
				end
				ghg_cleanup(list,temp_dir)
				return Array{DateTime}(undef,0), DataFrame(), ""
			end
		end
	else
		@warn("No Biomet file found: " * source)
		ghg_cleanup(list,temp_dir)
		return Array{DateTime}(undef,0), DataFrame(), ""
	end
	
	#################
	##  Load Data  ##
	#################
	verbose ? println("\t   Loading " * joinpath(temp_dir,list[iData])) : nothing
	t = Array{DateTime}(undef,0)
	D = DataFrame()
	cols = Array{Any}(undef,0,0)
	fid = open(joinpath(temp_dir,list[iData]),"r")
	if iData != 0
		# Prepare header
		if filetype == "primary"
			header_line = 9
		else
			header_line = 7
		end
		for j=1:1:header_line - 2
			readline(fid)
		end
		if eof(fid)
			# Erroneous Biomet file, it has no column names or data
			@warn("No data: " * joinpath(temp_dir,list[iData]))
			if !isempty(errorlog)
				try
					fid3 = open(errorlog,"a+")
					write(fid3,filetype * ", no data: " * source * "\r\n")
					close(fid3)
				catch
					@warn("Writing problem \"no data\"")
				end
			end
			close(fid)
			ghg_cleanup(list,temp_dir)
			return Array{DateTime}(undef,0), DataFrame(), ""
		end
		l_columns = readline(fid)
		cols = split(l_columns,'\t') # Split column line into column names
		new_names = Array{String}(undef,length(cols))
		temp_name = ""
		for i=1:1:length(cols)
			temp_name = replace(cols[i]," " => "_")
			temp_name = replace(replace(temp_name,"(" => ""),")" => "")
			temp_name = replace(replace(temp_name,"%" => ""),"^" => "")
			temp_name = replace(temp_name,"_-" => "")
			temp_name = replace(temp_name,"/" => "_per_")
			new_names[i] = temp_name
		end
		
		# Prepare column types
		col_types = fill!(Array{DataType}(undef,length(cols)),Float64)
		if hf
			stringCols = ["DATAH","Date","Time"]
		else
			stringCols = ["DATAH","DATE","TIME"]
		end
		intCols = ["Seconds","Nanoseconds","Diagnostic Value","Diagnostic Value 2","CHK"]
		col_types[cols .∈ (stringCols,)] .= String
		col_types[cols .∈ (intCols,)] .= Int
		
		# Load Data
		if isempty(select)
			D = CSV.read(joinpath(temp_dir,list[iData]),DataFrame,types = col_types,header = new_names,delim = '\t',datarow = header_line) # # ZipFile.jl temporary fix
		else
			D = CSV.read(joinpath(temp_dir,list[iData]),DataFrame,types = col_types,header = new_names,delim = '\t',datarow = header_line,select = select)
		end
		
		# Convert Diagnostic_Value Column
		if "Diagnostic_Value" ∈ names(D)
			D.Diagnostic_Value = LI7200Diagnostic.(D.Diagnostic_Value)
		end
		
		# Convert Time
		t = Array{DateTime}(undef,size(D,1)) # Preallocate
		if hf
			for j=1:1:length(t)
				# Normal Data
				t[j] = DateTime.(D.Date[j] * " " * D.Time[j],dfmt)
			end
		else
			for j=1:1:length(t)
				# Biomet
				t[j] = DateTime.(D.DATE[j] * " " * D.TIME[j],dfmt)
			end
		end
	end
	close(fid)
	#if Sys.iswindows()
	#	# Garbage collection ensures the temporary file is closed so that it can be deleted.
	#	# Windows does not seem to close it in time whereas Linux does
	#	GC.gc()
	#end
	
	##########################################################
	##  Delete Temporary Files (until ZipFile.jl is fixed)  ##
	##########################################################
	ghg_cleanup(list,temp_dir)
	
	##############
	##  Output  ##
	##############
	return t,D,cols
end

function ghg_cleanup(list::Array{String,1},temp_dir::String)
	junk = ""
	for i = 1:1:length(list)
		junk = joinpath(temp_dir,list[i])
		if isfile(junk)
			rm(junk)
		end
	end
end
