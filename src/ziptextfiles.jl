# ziptextfiles.jl
#
#   Zip a text file or list of text files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.4.0
# 08.12.2016
# Last Edit: 01.04.2020

# Reference: https://zipfilejl.readthedocs.io/en/latest/

# include("/home/jeremy/AD-Home/Code/Julia/Jeremy/ziptextfiles.jl")

"# ziptextfiles(dest::String,files)

Zip a text file or a list of text files

`ziptextfiles(destination,files)`\n
* **destination**::String = Destination directory and file name of the resulting ZIP file
* **files**::Array{String,1} or String = File or list of files\n\n

---\n

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default
\n\n"
function ziptextfiles(dest::String,files::String;verbose::Bool=false)
	ziptextfiles(dest,[files],verbose=verbose)
	
	nothing
end

function ziptextfiles(dest::String,files::Array{String,1};verbose::Bool=false)
	verbose ? println(dest) : nothing
	
	# Zip each file
	tempFile = ""
	for i=1:1:length(files)
		tempFile = files[i]
		verbose ? println("\t" * tempFile) : nothing
		
		read(`$exe7z a -tzip $dest $tempFile`,String);
	end
	
	verbose ? println("Complete") : nothing
	nothing
end

function zipExtractAll(source::String,destinationFolder::String)
	##############
	##  Checks  ##
	##############
	isfile(source) ? nothing : error("ZIP file does not exist")
	isdir(destinationFolder) ? nothing : error("Destination folder does not exist")
	
	read(`$exe7z x $source -y -o$destinationFolder`,String);
end

function zipExtractFile(source::String,destinationFolder::String,fileToExtract::String)
	##############
	##  Checks  ##
	##############
	isfile(source) ? nothing : error("ZIP file does not exist")
	isdir(destinationFolder) ? nothing : error("Destination folder does not exist")
	
	read(`$exe7z x $source -y -o$destinationFolder $fileToExtract`,String);
end

function zipList(file::String)
	isfile(file) ? nothing : error("zipList input must be a file string.") # Check
	
	# Load the raw list and parse it into lines
	listRaw = read(`$exe7z l $file`,String);
	list = readlines(IOBuffer(listRaw))
	
	# Find where the file list starts
	fileListStart = 0
	for i=1:1:length(list)
		if occursin("Date",list[i]) & occursin("Time",list[i]) & occursin("Attr",list[i]) & occursin("Size",list[i]) & occursin("Compressed",list[i]) & occursin("Name",list[i])
			fileListStart = i + 2
		end
	end
	
	# List just the file names themselves
	fileList = Array{String}(undef,length(list)- 1 - fileListStart)
	for i=1:length(fileList)
		# Isolate the file name from the whole line
		fileList[i] = list[fileListStart + i - 1][findlast(' ',list[fileListStart + i - 1])+1:end]
	end
	
	return fileList
end