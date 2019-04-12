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
# Last Edit: 26.06.2018

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
	# Data Line Count
	fsize = stat(source).size
	fid = open(source,"r")
	readline(fid)
	cols = readline(fid,chomp=false)[1:end-1]
	cols = permutedims(readdlm(IOBuffer("\"" * replace(replace(cols," ",""),",","\",\"") * "\""),','),[2,1])
	startpos = position(fid)
	l = readline(fid,chomp=false)
	llength = length(l) # Line Length
	endpos = 1
	f = false
	while !f
		seek(fid,fsize-endpos)
		l = readline(fid,chomp=false)
		l = l[1:findfirst(l,',')] # Find the first comma
		if !isempty(l)
			if length(findin(l,'/')) == 2 && length(findin(l,':')) == 2
				f = true # Found the last line
			end
		end
		endpos += 1
	end
	endpos = position(fid) # Position of the end of data
	footerlines = 0
	while !eof(fid)
		readline(fid)
		footerlines += 1
	end
	close(fid)
	l_count = Int((endpos - startpos)/llength) # Number of data lines
	
	# Column Types
	col_types = fill!(Array{DataType}(length(cols)),Float64)
	col_types[length(col_types)] = String
	col_types[1] = DateTime
	
	# Column Names
	col_names = Array{String}(length(cols))
	for i=1:length(cols)
		col_names[i] = replace(cols[i],"[","")
		col_names[i] = replace(col_names[i],"]","")
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
