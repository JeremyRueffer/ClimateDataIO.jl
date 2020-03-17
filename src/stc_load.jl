# stc_load.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.3.1
# 16.12.2016
# Last Edit: 17.03.2020

"""# stc_load

Load data from Aerodyne STC files generated by TDLWintel

---

### Examples

`time,data = stc_load(\"K:\\\\Data\\\\140113_135354.stc\")`\n
`time,data = stc_load([\"K:\\\\Data\\\\140113_135354.stc\",\"K:\\\\Data\\\\140114_000000.stc\"])`\n
`time,data = stc_load(\"K:\\\\Data\\\\\")` # Load all STC files in the given directory and subdirectories\n
`time,data = stc_load(\"K:\\\\Data\\\\\",verbose=true,cols=[\"Traw\",\"X1\"])` # Load only Traw and X1 from all files in the given directory and display information as it is processed\n
`time,data = stc_load(\"K:\\\\Data\\\\\",DateTime(2014,6,27,11,58,0))` # Load files starting at the given timestamp\n
`time,data = stc_load(\"K:\\\\Data\\\\\",DateTime(2014,6,27,11,58,0),DateTime(2014,7,4,12,0,0))` # Load files between the given timestamps\n

---

`time, D = stc_load(F)`\n
* **time**::Array{DateTime,1} = Parsed time values from the STC file
* **D**::DataFrame = Data from the STC file
* **F**::Array{String,1} = Array of STC files to load

`time, D = stc_load(F;verbose=false,cols=[])`\n
* **time**::Array{DateTime,1} =
* **F**::String = File name and location
* **verbose**::Bool (optional) = Display what is happening, FALSE is default
* **cols**::Array{String,1} or Array{Symbol,1} (optional) = List of columns to return, [] is default

`time, D = stc_load(F,mindate;verbose=false,cols=[])`\n
`time, D = stc_load(F,mindate,maxdate;verbose=false,cols=[])`\n
* **mindate**::DateTime = Load files including and after this date and time
* **maxdate**::DateTime = Load files up to this date and time
"""
function stc_load(Dr::String,mindate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)
	## Load STC files in the given directory (Dr) including and beyond the given date ##
	return stc_load(Dr,mindate,DateTime(9999,1,1,0,0,0);verbose=verbose,cols=cols,recur=recur)
end # End of stc_load(Dr::String,mindate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)

function stc_load(Dr::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)
	## Load STC files in the given directory (Dr) between the given dates ##
	
	# Check for Directory
	if isdir(Dr) == false
		error("First input should be a directory")
	end
	
	# List Files
	verbose ? println("Listing Files") : nothing
	(Fstc,folders) = dirlist(Dr,regex=r"\d{6}_\d{6}\.stc$",recur=recur) # List STC files
	
	# Parse Times
	(Tstc,Fstc) = aerodyne_parsetime(Fstc)
	
	# Sort Info
	f = sortperm(Tstc)
	Tstc = Tstc[f]
	Fstc = Fstc[f]
	
	# Remove Files Out of Range
	begin
		# STC Files
		f = findall(mindate .<= Tstc .< maxdate)
		Tstc = Tstc[f]
		Fstc = Fstc[f]
	end
	
	# Load Data
	verbose ? println("Loading:") : nothing
	(Tstc,Dstc) = stc_load(Fstc,verbose=verbose,cols=cols)
	
	# Remove Time Values Out of Range
	begin
		# Ensure all rows are defined in SPEFile
		if in(true,[isequal(:SPEFile,i) for i in names(Dstc)]) # See if :SPEFile exists first
			f = ismissing.(Dstc.SPEFile)
			Dstc.SPEFile[f] .= ""
		end
		
		f = findall(mindate .<= Tstc .< maxdate)
		Tstc = Tstc[f]
		Dstc = Dstc[f,:]
	end
	
	return Tstc,Dstc
end # End of stc_load(Dr::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false,cols::Array{String,1}=String[],recur::Int=9999)

function stc_load(F::Array{T,1};verbose::Bool=false,cols::Array{String,1}=String[]) where T <: String
	## Load a list of file names ##
	
	# Sort files by dates
	(Ftime,F) = aerodyne_parsetime(F)
	
	# Load and concatinate data
	(t,D) = stc_load(F[1],verbose=verbose,cols=cols) # Initial load
	for i=2:1:length(F)
		(tempT,tempD) = stc_load(F[i],verbose=verbose,cols=cols)
		t = [t;tempT]
		D = [D;tempD]
	end
	
	return t,D
end # End stc_load(F::Array{T,1};verbose::Bool=false,cols::Array{String,1}=String[]) where T <: String

function stc_load(F::String;verbose::Bool=false,cols::Array{String,1}=String[])
	ext = splitext(F)[2][2:end] # Save the extension
	
	verbose ? println("  " * F) : nothing
	
	## Check for a proper file
	if isdir(F) == true
		return stc_load(F,DateTime(0,1,1,0,0,0),DateTime(9999,1,1,0,0,0),verbose=verbose,cols=cols)
	elseif isempty(ext) == true
		error("No file extension")
	elseif ext != "stc"
		error("Extension is not STC. Returning nothing...")
		return
	end
	
	#################
	##  Load Data  ##
	#################
	## Load Header Information
	fid = open(F,"r")
	h1 = readline(fid)
	h2 = readline(fid)
	
	h3 = permutedims(readdlm(IOBuffer("\"" * replace(h2[1:end],"," => "\",\"") * "\""),','),[2,1])
	h = Array{String}(undef,length(h3))
	for i=1:1:length(h3)
		h[i] = strip(String(h3[i])) # Remove leading and trailing whitespace
		h[i] = replace(h[i]," " => "_") # Replace remaining whitespace with _
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
	coltypes = Any[Float64 for i=1:length(h)]
	for i=1:1:length(h)
		if h[i] == "SPEFile"
			coltypes[i] = Union{Missing,String}
		end
		
		if h[i] == "StatusW"
			coltypes[i] = Int
		end
	end
	
	## Todo: Replace column names with reasonable names
	
	## Load data
	D = DataFrame()
	try
		D = CSV.read(F;delim=",",types=coltypes,header=h,datarow=3,missingstring="-")
	catch
		println("Cannot load " * F)
		error("ERROR loading file")
	end
	
	#########################
	##  Parse Time Format  ##
	#########################
	time = Array{DateTime}(undef,length(D.time)) # Preallocate time column
	secs = Dates.Second # Initialize so it doesn't have to do it every time in the loop
	millisecs = Dates.Millisecond # Initialize so it doesn't have to do it every time in the loop
	for i=1:1:length(D.time)
		secs = Dates.Second(floor(D.time[i]))
		millisecs = Dates.Millisecond(floor(1000(D.time[i] - floor(D.time[i]))))
		time[i] = DateTime(1904,1,1,0,0,0) + secs + millisecs
	end
	
	##################################
	##  Keep only selected columns  ##
	##################################
	if !isempty(cols)
		# Check cols' type
		if typeof(cols) != Array{Symbol,1} && typeof(cols) != Symbol
			temp = Array{Symbol}(undef,length(cols))
			for i=1:1:length(cols)
				temp[i] = Symbol(cols[i]) # Convert all the values to symbols
			end
			cols = temp
		end
		
		# Make sure each entry exists
		fields = names(D)
		cols_bool = fill!(Array{Bool}(undef,length(cols)),false) # Preallocate false
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
			time = Array{DateTime}(undef,0)
		else
			D = D[:,cols]
		end
	end
	
	return time,D
end # End of stc_load(F::String;verbose::Bool=false,cols::Array{String,1}=String[])
