# aerodyne_load.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 13.12.2016
# Last Edit: 13.12.2016

"""# aerodyne_load

Load data from STR and/or STC files generated by TDLWintel

---

### Examples

`time,data = aerodyne_load(\"K:\\\\Data\\\\140113_135354.str\")`\n
`time,data = aerodyne_load([\"K:\\\\Data\\\\140113_135354.str\",\"K:\\\\Data\\\\140114_000000.str\"])`\n
`timeSTR,dataSTR,timeSTC,dataSTC = aerodyne_load(\"K:\\\\Data\\\\\")` # Load all STR and STC files in the given directory and subdirectories\n
`timeSTR,dataSTR,timeSTC,dataSTC = aerodyne_load(\"K:\\\\Data\\\\\",verbose=true,cols=[\"Traw\",\"X1\"])` # Load only Traw and X1 from all files in the given directory and display information as it is processed\n
`timeSTR,dataSTR,timeSTC,dataSTC = aerodyne_load(\"K:\\\\Data\\\\\",DateTime(2014,6,27,11,58,0))` # Load files starting at the given timestamp\n
`timeSTR,dataSTR,timeSTC,dataSTC = aerodyne_load(\"K:\\\\Data\\\\\",DateTime(2014,6,27,11,58,0),DateTime(2014,7,4,12,0,0))` # Load files between the given timestamps\n

---

`time, D = aerodyne_load(F)`\n
* **time**::Array{DateTime,1} = Parsed time values from the STR or STC file
* **D**::DataFrame = Data from the STR or STC file
* **F**::Array{String,1} = Array of STR or STC files to load

`timeStr, DStr, timeStc, DStc = aerodyne_load(F;verbose=false,cols=[])`\n
* **timeStr**::Array{DateTime,1} =
* **F**::String = File name and location
* **verbose**::Bool (optional) = Display what is happening, FALSE is default
* **cols**::Array{String,1} or Array{Symbol,1} (optional) = List of columns to return, [] is default

`time, D = aerodyne_load(F,mindate;verbose=false,cols=[])`\n
`time, D = aerodyne_load(F,mindate,maxdate;verbose=false,cols=[])`\n
* **mindate**::DateTime = Load files including and after this date and time
* **maxdate**::DateTime = Load files up to this date and time
"""
function aerodyne_load(Dr::String,mindate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)
	## Load STR and STC files in the given directory (Dr) including and beyond the given date ##
	return aerodyne_load(Dr,mindate,DateTime(9999,1,1,0,0,0);verbose=verbose,cols=cols,recur=recur)
end # End of aerodyne_load(Dr::String,mindate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)

function aerodyne_load(Dr::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)
	## Load STR and STC files in the given directory (Dr) between the given dates ##
	
	# Check for Directory
	if isdir(Dr) == false
		error("First input should be a directory")
	end
	
	# List Files
	if verbose
		println("Listing Files")
	end
	(Fstr,folders) = dirlist(Dr,regex=r"\d{6}_\d{6}\.str$",recur=recur) # List STR files
	(Fstc,folders) = dirlist(Dr,regex=r"\d{6}_\d{6}\.stc$",recur=recur) # List STC files
	
	# Parse Times
	(Tstr,Fstr) = aerodyne_parsetime(Fstr)
	(Tstc,Fstc) = aerodyne_parsetime(Fstc)
	
	# Sort Info
	f = sortperm(Tstr)
	Tstr = Tstr[f]
	Fstr = Fstr[f]
	f = sortperm(Tstc)
	Tstc = Tstc[f]
	Fstc = Fstc[f]
	
	# Remove Files Out of Range
	begin
		# STR Files
		f = findin(Tstr .== mindate,true)
		if isempty(f)
			f = findin(Tstr .< mindate,true)
			if isempty(f)
				f = 1
			else
				f = f[end]
			end
		else
			f = f[1]
		end
		Tstr = Tstr[f:end]
		Fstr = Fstr[f:end]
		f = Tstr .< maxdate
		Tstr = Tstr[f]
		Fstr = Fstr[f]
		
		# STC Files
		f = findin(Tstc .== mindate,true)
		if isempty(f)
			f = findin(Tstc .< mindate,true)
			if isempty(f)
				f = 1
			else
				f = f[end]
			end
		else
			f = f[1]
		end
		Tstc = Tstc[f:end]
		Fstc = Fstc[f:end]
		f = Tstc .< maxdate
		Tstc = Tstc[f]
		Fstc = Fstc[f]
	end
	
	# Load Data
	if verbose
		println("Loading:")
	end
	(Tstr,Dstr) = aerodyne_load(Fstr,verbose=verbose,cols=cols)
	(Tstc,Dstc) = aerodyne_load(Fstc,verbose=verbose,cols=cols)
	
	# Remove Time Values Out of Range
	begin
		f = Tstr .>= mindate
		Tstr = Tstr[f]
		Dstr = Dstr[f,:]
		f = Tstr .<= maxdate
		Tstr = Tstr[f]
		Dstr = Dstr[f,:]
		
		# Ensure all rows are defined in SPEFile
		if in(true,[isequal(:SPEFile,i) for i in names(Dstc)]) # See if :SPEFile exists first
			f = isna(Dstc[:SPEFile])
			Dstc[:SPEFile][f] = ""
		end
		
		f = Tstc .>= mindate
		Tstc = Tstc[f]
		Dstc = Dstc[f,:]
		f = Tstc .<= maxdate
		Tstc = Tstc[f]
		Dstc = Dstc[f,:]
	end
	
	return Tstr,Dstr,Tstc,Dstc
end # End of aerodyne_load(Dr::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)

function aerodyne_load{T<:String}(F::Array{T,1};verbose::Bool=false,cols::Array{String,1}=String[])
	## Load a list of file names ##
	
	# Sort files by dates
	(Ftime,F) = aerodyne_parsetime(F)
	
	# Load and concatinate data
	(t,D) = aerodyne_load(F[1],verbose=verbose,cols=cols) # Initial load
	for i=2:1:length(F)
		(tempT,tempD) = aerodyne_load(F[i],verbose=verbose,cols=cols)
		t = [t;tempT]
		D = [D;tempD]
	end
	
	return t,D
end # End aerodyne_load{T<:String}(F::Array{T,1};verbose::Bool=false,cols::Array{String,1}=String[])

function aerodyne_load(F::String;verbose::Bool=false,cols::Array{String,1}=String[])
	ext = F[rsearch(F,'.') + 1:end] # Save the extension
	
	if verbose
		println("  " * F)
	end
	
	## Check for a proper file
	if isempty(ext) == true
		error("No file extension")
	elseif isdir(F) == true
		return aerodyne_load(F,DateTime(0,1,1,0,0,0))
	elseif ext != "str" && ext != "stc"
		error("Extension is not either STR or STC. Returning nothing...")
		return
	end
	
	#################
	##  Load Data  ##
	#################
	## Load Header Information
	fid = open(F,"r")
	h1 = readline(fid)
	h = collect(Array[[]])
	if ext == "stc"
		h2 = readline(fid)
		
		h = permutedims(readcsv(IOBuffer("\"" * replace(h2[1:end-1],",","\",\"") * "\"")),[2,1]) # "
		h = [ascii("$i") for i in h]
		for i=1:1:length(h)
			h[i] = strip(h[i]) # Remove leading and trailing whitespace
			h[i] = replace(h[i]," ","_") # Replace remaining whitespace with _
		end
	elseif ext == "str"
		h1 = h1[rsearch(h1,"SPEC:")[end]+1:end-2] # Remove everything including and before the SPEC:
		h = permutedims(readcsv(IOBuffer("\"" * replace(h1,",","\",\"") * "\"")),[2,1]) # "
		h = [ascii("$i") for i in h]
		for i=1:1:length(h)
			h[i] = strip(h[i]) # Remove leading and trailing whitespace
			h[i] = replace(h[i]," ","_") # Replace remaining whitespace with _
		end
		h = ["time";h]
	end
	close(fid)
	
	## Check for duplicate column names and adjust them
	unames = unique(h) # unique column names
	for i in unames
		check = 0
		for j = 1:length(h)
			if i == h[j]
				check += 1
				
				if check > 1
					h[j] = h[j] * "-" * string(check)
				end
			end
		end
	end
	
	## List column types
	coltypes = repmat([Float64],length(h))
	for i=1:1:length(h)
		if h[i] == "SPEFile"
			coltypes[i] = String
		end
		
		if h[i] == "StatusW"
			coltypes[i] = Int64
		end
	end
	
	## Todo: Replace column names with reasonable names
	
	## Load data
	D = []
	if ext == "stc"
		try
			D = DataFrames.readtable(F,eltypes = coltypes,separator = ',',header = false,skipstart = 2*2)
		catch
			println("Cannot load " * F)
			error("ERROR loading file")
		end
	elseif ext == "str"
		try
			D = DataFrames.readtable(F,eltypes = coltypes,separator = ' ',header = false,skipstart = 2*1)
		catch
			println("Cannot load " * F)
			error("ERROR loading files")
		end
	end
	
	## Rename the dataframe columns with the correct names
	for i=1:1:length(h)
		rename!(D,Symbol("x" * string(i)),Symbol(h[i]))
	end
	
	#########################
	##  Parse Time Format  ##
	#########################
	time = Array(DateTime,length(D[:time])) # Preallocate time column
	secs = Dates.Second # Initialize so it doesn't have to do it every time in the loop
	millisecs = Dates.Millisecond # Initialize so it doesn't have to do it every time in the loop
	for i=1:1:length(D[:time])
		secs = Dates.Second(floor(D[:time][i]))
		millisecs = Dates.Millisecond(floor(1000(D[:time][i] - floor(D[:time][i]))))
		time[i] = DateTime(1904,1,1,0,0,0) + secs + millisecs
	end
	
	##################################
	##  Keep only selected columns  ##
	##################################
	if !isempty(cols)
		# Check cols' type
		if typeof(cols) != Array{Symbol,1} && typeof(cols) != Symbol
			temp = Array(Symbol,length(cols))
			for i=1:1:length(cols)
				temp[i] = Symbol(cols[i]) # Convert all the values to symbols
			end
			cols = temp
		end
		
		# Make sure each entry exists
		fields = names(D)
		cols_bool = fill!(Array(Bool,length(cols)),false) # Preallocate false
		for i=1:1:length(cols)
			for j=1:1:length(fields)
				if fields[j] == cols[i]
					cols_bool[i] = true
				end
			end
		end
		cols = cols[cols_bool]
		
		# Remove Unwanted column
		if isempty(cols)
			D = DataFrame()
			time = Array(DateTime,0)
		else
			D = D[cols]
		end
	end
	
	return time,D
end # End of aerodyne_load(F::String;verbose::Bool=false,cols::Array{String,1}=String[])
