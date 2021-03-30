# lgr_read.jl
#
#   Load Los Gatos Research (LGR) Methane data
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.6.0
# 07.11.2014
# Last Edit: 30.03.2021

# - Programmatically zipped data files have a PGP signature at the end after the last line of data
# - Data files are TXT files withing a ZIP file
# - Sometimes multiple text files and a folder can be contained within a ZIP file
# - Line width is assumed to be fixed

"# lgr_read(source::String;verbose::Bool=false)

`time,data,columns = lgr_read(source)` Load a single LGR TXT files\n
* **source**::String = File name and location\n\n

---\n

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default\n\n"
function lgr_read(source::String;verbose::Bool=false)
	# Check for file
	!isfile(source) ? error(source * " must be a file") : nothing
	
	dfmt = Dates.DateFormat("dd/mm/yyyy HH:MM:SS.sss") # Date format
	
	#############################################
	##  Prepare Settings for Loading the Data  ##
	#############################################
	# Header Info
	fsize = stat(source).size
	fid = open(source,"r")
	readline(fid)
	cols = readline(fid,keep=true)[1:end-1]
	cols = permutedims(readdlm(IOBuffer("\"" * replace(replace(cols," " => ""),"," => "\",\"") * "\""),','),[2,1])
	startpos = position(fid)
	
	# Determine Line Count
	l = readline(fid)
	l_count = 1
	while !isempty(l) && !eof(fid)
		l = readline(fid)
		l_count += 1
	end
	footerlines = 1
	while !eof(fid)
		readline(fid)
		footerlines += 1
	end
	close(fid)
	
	# Column Types
	col_types = fill!(Array{DataType}(undef,length(cols)),Float64)
	col_types[length(col_types)] = String
	col_types[1] = DateTime
	
	# Column Names
	col_names = Array{String}(undef,length(cols))
	for i=1:length(cols)
		col_names[i] = replace(cols[i],"[" => "")
		col_names[i] = replace(col_names[i],"]" => "")
	end
	
	#####################
	##  Load the Data  ##
	#####################
	D = DataFrame!(CSV.File(source,
		datarow=3,
		dateformat=dfmt,
		delim=',',
		header=col_names,
		#limit=l_count-1, # Read up until the PGP signature but not beyond it
		footerskip=footerlines, # PGP signed
		types=col_types))
	
	close(fid)
	if Sys.iswindows()
		# Garbage collection ensures the temporary file is closed so that it can be deleted.
		# Windows does not seem to close it in time whereas Linux does
		GC.gc()
	end
	return D
end
