# lgr_read.jl
#
#   Load Los Gatos Research (LGR) Methane data
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 07.11.2014
# Last Edit: 18.04.2019

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
	
	df = Dates.DateFormat("dd/mm/yyyy HH:MM:SS.sss") # Date format
	
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
	while !isempty(l)
		l = readline(fid)
		l_count += 1
	end
	footerlines = 1
	while !eof(fid)
		readline(fid)
		footerlines += 1
	end
	
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
	D = CSV.read(source,
		datarow=3,
		dateformat=Dates.DateFormat("  dd/mm/yyyy HH:MM:SS.sss"),
		delim=',',
		header=col_names,
		footerskip=footerlines, # PGP signed
		types=col_types)
	
	return D
end
