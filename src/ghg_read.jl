# ghg_read.jl
#
#   Load a GHG file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.1.0
# 18.11.2014
# Last Edit: 20.08.2019

"# ghg_read(source::String,verbose::Bool,filetype::String)

`time,data = ghg_read(source)` Load a single GHG file\n
* **source**::String = Single GHG file or a directory of GHG files

---

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default
* filetype::String = Data file type to load, \"primary\" is default and loads the primary high frequency file. \"biomet\" would load the BIOMET file if it is present.
* errorlog::String = Log each loading error, \"\" is default\n\n"
function ghg_read(source::String;verbose::Bool=false,filetype::String="primary",errorlog::String="")
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
	try
		list = ZipFile.Reader(source) # List the files in the GHG file
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
	for i=1:1:length(list.files)
		if length(list.files[i].name) >= 31
			if occursin(rootnamereg,list.files[i].name[1:26])
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
	
	#########################################
	##  Unzip  (Until ZipFile.jl is fixed) ##
	#########################################
	verbose ? println("\t   Unzipping") : nothing
	temp_dir = tempdir() # Temporary directory for unzipped files
	if Sys.iswindows()
		list = ZipFile.Reader(source) # List the files in the GHG file
		open(joinpath(temp_dir,list.files[iData].name),"w") do io
			write(io,read(list.files[iData]))
		end
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
			return Array{DateTime}(undef,0), DataFrame(), ""
		end
	end
	
	###########################
	##  High Frequency Data  ##
	###########################
	t = Array{DateTime}(undef,0)
	D = DataFrame()
	cols = Array{Any}(undef,0,0)
	fid = open(joinpath(temp_dir,list.files[iData].name),"r") # ZipFile.jl temporary fix
	if iData != 0
		if filetype == "primary"
			header_line = 9
		else
			header_line = 7
		end
		for j=1:1:header_line - 2
			readline(fid) # ZipFile.jl temporary fix
			#readline(list.files[iData])
		end
		if eof(fid)
			# Erroneous Biomet file, it has no column names or data
			@warn("No data: " * joinpath(temp_dir,list.files[iData].name))
			if !isempty(errorlog)
				try
					fid3 = open(errorlog,"a+")
					write(fid3,filetype * ", no data: " * source * "\r\n")
					close(fid3)
				catch
					@warn("Writing problem \"no data\"")
				end
			end
			return Array{DateTime}(undef,0), DataFrame(), ""
		end
		l_columns = readline(fid) # ZipFile.jl temporary fix
		#l_columns = readline(list.files[iData])
		cols = permutedims(readdlm(IOBuffer("\"" * replace(l_columns,"\t" => "\",\"") * "\""),','),[2,1])
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
		
		# Load Data
		col_types = fill!(Array{DataType}(undef,length(cols)),Float64)
		if filetype == "primary"
			col_types[1:8] = [String;Int32;Int32;Int32;Int32;Int32;String;String]
			col_types[end] = Int32
		else
			col_types[1:3] = [String;String;String]
			col_types[end] = Int32
		end
		# datarow = 1, the position within the file is just at the start of the data already because of the header loading
		D = CSV.read(joinpath(temp_dir,list.files[iData].name),types = col_types,header = new_names,delim = '\t',datarow = header_line) # # ZipFile.jl temporary fix
		#D = CSV.read(list.files[iData],types = col_types,header = new_names,delim = '\t',datarow = 1)
		
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
	if Sys.iswindows()
		# Garbage collection ensures the temporary file is closed so that it can be deleted.
		# Windows does not seem to close it in time whereas Linux does
		GC.gc()
	end
	
	##########################################################
	##  Delete Temporary Files (until ZipFile.jl is fixed)  ##
	##########################################################
	junk = ""
	for i = 1:1:length(list.files)
		junk = joinpath(temp_dir,list.files[i].name)
		if isfile(junk)
			rm(junk)
		end
	end
	
	##############
	##  Output  ##
	##############
	return t,D,cols
end
