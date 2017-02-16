# lgr_load.jl
#
#   Load Los Gatos Research (LGR) Methane data
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 07.11.2014
# Last Edit: 16.02.2017

# - Programmatically zipped data files have a PGP signature at the end after the last line of data
# - Data files are TXT files withing a ZIP file
# - Sometimes multiple text files and a folder can be contained within a ZIP file
# - Line width is assumed to be fixed

"# lgr_load(source::String,mindate::DateTime,maxdate::DateTime;verbose::Bool=false)

`time,data,columns = lgr_load(source)` Load a directory of LGR zip files\n
* **time**::Array(DateTime,1) = Time column
* **data**::DataFrame = Data
* **columns**::Array(String,1) = List of columns
* **source**::String = Directory of LGR zip files\n\n

`time,data,columns = lgr_load(source,minimumdate)` \n
* **minimumdate**::DateTime = Starting date to load data from\n\n

`time,data,columns = lgr_load(source,minimumdate,maximumdate)` \n
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
	if is_linux()
		dest = "/tmp/"
	elseif is_apple()
		dest = ENV["TMPDIR"]
	elseif is_windows()
		dest = ENV["Temp"]
	end
	
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
	times = Array(DateTime,length(files))
	for i=1:1:length(times)
		times[i] = DateTime(files[i][end-12:end-4],"dduuuyyyy") # Convert file name to a timestamp
	end
	f = sortperm(times)
	times = times[f]
	files = files[f]
	
	# Remove files out of time range
	f = find(mindate .<= times .< maxdate)
	times = times[f]
	files = files[f]
	verbose ? println("  ZIP File Count: " * string(length(files)) * "\n") : nothing
	
	# List and unzip contents
	D = DataFrame()
	t = Array(DateTime,0)
	cols = []
	for i=1:1:length(files)
		temp = files[i]
		zipfiles = Array(String,0)
		zipdirectories = Array(String,0)
		
		# List Zip Contents
		verbose ? println("   # " * string(i) * ": " * basename(temp)) : nothing
		if is_windows()
			println("files[" * string(i))
			l = ZipFile.Reader(files[i])
			for j in l.files
				if splitext(j.name)[2] == ".txt"
					push!(zipfiles,joinpath(dest,j.name))
					
					verbose ? println("      " * zipfiles[j]) : nothing
					fid = open(joinpath(dest,j.name),"w")
					write(fid,readstring(j))
					close(fid)
				end
			end
			close(l) # Close Zip File
		else
			l = readcsv(IOBuffer(readstring(`unzip -l $temp`)))[4:end-2]
			for j=1:1:length(l)
				if splitext(l[j][31:end])[2] == ".txt"
					push!(zipfiles,joinpath(dest,l[j][findlast(l[j],' ')+1:end]))
				else
					push!(zipdirectories,joinpath(dest,l[j][findlast(l[j],' ')+1:end]))
				end
			end
			zipfiles = sort(zipfiles) # Sort the files so they will be loaded chronologically
			
			if verbose
				for j=1:1:length(zipfiles)
					println("      " * zipfiles[j])
				end
			end
			
			# Unzip
			temp2 = readstring(`unzip -d $dest $temp`)
		end
		
		# Load Each Data File
		for j=1:1:length(zipfiles)
			(tempT,tempD,cols) = lgr_read(zipfiles[j],verbose=verbose)
			t = [t;tempT]
			D = [D;tempD]
		end
		
		# Delete Files and Directories
		for j=1:1:length(zipfiles)
			rm(zipfiles[j])
		end
		for j=1:1:length(zipdirectories)
			rm(zipdirectories[j])
		end
	end
	
	verbose ? println("  Data Loading Complete") : nothing
	
	return t, D, cols
end
