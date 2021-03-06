# lgr_load.jl
#
#   Load Los Gatos Research (LGR) Methane data
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.4.2
# 07.11.2014
# Last Edit: 17.07.2020

# - Programmatically zipped data files have a PGP signature at the end after the last line of data
# - Data files are TXT files withing a ZIP file
# - Sometimes multiple text files and a folder can be contained within a ZIP file
# - Line width is assumed to be fixed

"# lgr_load(source::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false)

`data = lgr_load(source)` Load a directory of LGR zip files\n
* **data**::DataFrame = Data
* **source**::String = Directory of LGR zip files\n\n

`data = lgr_load(source,minimumdate)` \n
* **minimumdate**::DateTime = Starting date to load data from\n\n

`data = lgr_load(source,minimumdate,maximumdate)` \n
* **maximumdate**::DateTime = Load data before this date\n\n

---\n

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default\n\n"
function lgr_load(source::String,mindate::DateTime=DateTime(0),maxdate::DateTime=DateTime(9999);verbose::Bool=false)
	# Check source
	if !isdir(source) & !isfile(source)
		error("source is not a file or directory.")
	end
	
	# Temporary Directory, Unzipping Destination
	dest = tempdir()
	
	#############################
	##  Basic Settings Output  ##
	#############################
	if verbose
		println("Loading LGR ZIP Files")
		println("  From: " * string(mindate))
		println("  To  : " * string(maxdate))
		println("  Temp Directory: " * dest)
	end
	
	##################
	##  List Files  ##
	##################
	(files,folders) = dirlist(source,regex=r"\d{2}[A-Z][a-z][a-z]\d{4}\.zip$")
	times = Array{DateTime}(undef,length(files))
	for i=1:1:length(times)
		times[i] = DateTime(files[i][end-12:end-4],"dduuuyyyy") # Convert file name to a timestamp
	end
	f = sortperm(times)
	times = times[f]
	files = files[f]
	
	# Remove files out of time range
	f = findall(mindate .<= times .< maxdate)
	times = times[f]
	files = files[f]
	verbose ? println("  ZIP File Count: " * string(length(files)) * "\n") : nothing
	
	# List and unzip contents
	D = DataFrame()
	for i=1:1:length(files)
		println("-=-==  " * files[i] * "  ==-=-") # Temp
		temp = files[i]
		zipfiles = Vector{String}()
		zipdirectories = Vector{String}()
		
		# List Zip Contents
		verbose ? println("   # " * string(i) * ": " * basename(temp)) : nothing
		zipfiles = joinpath.(dest,zipList(files[i])) # List the files in the archive
		zipExtractAll(files[i],dest)
		
		# Load Each Data File
		for j=1:1:length(zipfiles)
			tempD = lgr_read(zipfiles[j],verbose=verbose)
			isempty(D) ? D = tempD : D = [D;tempD]
		end
		
		# Delete Files and Directories
		for j=1:1:length(zipfiles)
			if isfile(zipfiles[j])
				rm(zipfiles[j])
			end
		end
		for j=1:1:length(zipdirectories)
			if isdir(zipdirectories[j])
				rm(zipdirectories[j])
			end
		end
	end
	
	verbose ? println("  Data Loading Complete") : nothing
	
	return D
end
