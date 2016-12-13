# lgr_read.jl
#
#   Load Los Gatos Research (LGR) Methane data
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 07.11.2014
# Last Edit: 12.12.2016

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
	if !isfile(source)
		error(source * " must be a file")
	end

	#############################################
	##  Prepare Settings for Loading the Data  ##
	#############################################
	# Data Line Count
	fsize = stat(source).size
	fid = open(source,"r")
	readline(fid)
	cols = readline(fid)[1:end-1]
	cols = permutedims(readcsv(IOBuffer("\"" * replace(replace(cols," ",""),",","\",\"") * "\"")),[2,1])
	startpos = position(fid)
	l = readline(fid)
	llength = length(l) # Line Length
	endpos = 1
	f = false
	while !f
		seek(fid,fsize-endpos)
		l = readline(fid)
		l = l[1:findfirst(l,',')] # Find the first comma
		if !isempty(l)
			if length(findin(l,'/')) == 2 && length(findin(l,':')) == 2
				f = true # Found the last line
			end
		end
		endpos += 1
	end
	endpos = position(fid) # Position of the end of data
	close(fid)
	l_count = Int((endpos - startpos)/llength) # Number of data lines

	# Column Types
	col_types = fill!(Array(DataType,length(cols)),Float64)
	col_types[[1;length(col_types)]] = String

	#####################
	##  Load the Data  ##
	#####################
	D = DataFrames.readtable(source,eltypes = col_types,separator = ',',header = false,skipstart = 2,nrows=l_count)

	####################
	##  Convert Time  ##
	####################
	t = Array(DateTime,size(D,1))
	for i=1:1:length(t)
		t[i] = DateTime(D[i,1],"dd/mm/yyyy HH:MM:SS.sss")
	end

	return t,D,cols
end
