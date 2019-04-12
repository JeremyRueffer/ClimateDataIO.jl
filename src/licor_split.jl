# licor_split.jl
#
#   Split Li-7200 TXT files into GHG archives
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 20.05.2014
# Last Edit: 12.04.2019

"# licor_split(source::String,destination::String;verbose::Bool=false)

Split an Li-7200 text file into small files in the standard GHG format. If possible, files will start on the usual four hour marks (0000, 0400, 0800, etc.).

`licor_split(source,destination)` Split Li7200 files in the source directors\n
* **source**::String = Directory of Li-7200 text files with names similar to 2016-03-17T104500.txt
* **destination**::String = Destination directory\n\n

---\n

#### Keywords:\n
* verbose::Bool = Display information as the function runs, TRUE is default
\n\n"
function licor_split(Dr::String,Dest::String;verbose::Bool=true)
    ###################
    ##  Definitions  ##
    ###################
    # Dr = Source Directory
    # Dest = Destination Directory
	
    ####################
    ##  Parse Inputs  ##
    ####################
    # Check Directory Validity
    if ~isdir(Dr) | ~isdir(Dest)
        error("Source or destination directory does not exist")
    end
	
    (files,folders) = dirlist(Dr,regex=r"\d{4}-\d{2}-\d{2}T\d{6}\.txt$",recur=1) # List TXT files
	
    #####################
    ##  Process Files  ##
    #####################
    if isempty(files)
	    println("No Metdata files to split")
    else
    	if verbose
	    	println("=== Splitting Metdata Files ===")
	    end
    end
    time = DateTime[]
    starttime = DateTime[]
    endtime = DateTime[]
    fname = String[]
    header = Array{String}(undef,0) # Initialized header array
    sentinel = 20; # Sentinel value for header while loop
    for i=1:1:length(files)
    	if verbose
	    	println("   " * files[i])
	    end
	    s = stat(files[i]) # Get file info
		
	    fid = open(files[i],"r")
		
	    # Load Header
	    j = 1;
	    l = "Bierchen" # Needs any string at least 5 characters long
	    while l[1:5] != "DATAH" && j < sentinel
	    	l = readline(fid,keep=true)
	    	header = [header;l]
	    	j += 1
	    end
	    data_pos = position(fid) # Position of where the data starts
		
	    #Get Start Time
	    l = readline(fid,keep=true)
		ft = findall(x -> x == '\t',l)
	    starttime = DateTime(l[ft[6]+1:ft[8]-1],"yyyy-mm-dd\tHH:MM:SS:sss")
		
	    # Get End Time
	    endline = true
	    lastpos = 4 # Characters from the end of the file where the last line begins
	    while endline == true
		    seek(fid,s.size-lastpos)
		    l = readline(fid,keep=true)
		    if eof(fid) == false
			    endline = false
		    else
			    lastpos += 2
		    end
	    end
	    l = readline(fid,keep=true)
		ft = findall(x -> x == '\t',l)
	    endtime = DateTime(l[ft[6]+1:ft[8]-1],"yyyy-mm-dd\tHH:MM:SS:sss")
		
	    # Split the File
	    seek(fid,data_pos) # Move the cursor to the start of the data
	    fid2 = open(files[i]);close(fid2)
	    next_start = []
	    first_file = true
	    while eof(fid) == false
		    if isopen(fid2) == false
			    # No output stream available
			    # Open new output file from previous line
				
			    if first_file == true
				    # There is not previously loaded line, load one now
				    l = readline(fid,keep=true)
				    first_file = false
			    end
					
			    # Calculate last value of file
				ft = findall(x -> x == '\t',l)
			    temp_start = DateTime(l[ft[6]+1:ft[8]-1],"yyyy-mm-dd\tHH:MM:SS:sss")
			    HH2 = Dates.Hour[]
			    DD2 = Dates.Day(temp_start)
			    if Dates.Hour(0) <= Dates.Hour(temp_start) < Dates.Hour(4)
				    HH2 = Dates.Hour(4)
			    elseif Dates.Hour(4) <= Dates.Hour(temp_start) < Dates.Hour(8)
				    HH2 = Dates.Hour(8)
			    elseif Dates.Hour(8) <= Dates.Hour(temp_start) < Dates.Hour(12)
				    HH2 = Dates.Hour(12)
			    elseif Dates.Hour(12) <= Dates.Hour(temp_start) < Dates.Hour(16)
				    HH2 = Dates.Hour(16)
			    elseif Dates.Hour(16) <= Dates.Hour(temp_start) < Dates.Hour(20)
				    HH2 = Dates.Hour(20)
			    elseif Dates.Hour(20) <= Dates.Hour(temp_start) < Dates.Hour(24)
				    HH2 = Dates.Hour(0)
				    DD2 = DD2 + Dates.Day(1)
			    end
			    next_start = DateTime(Dates.Year(temp_start),Dates.Month(temp_start),DD2,HH2)
				
			    # Generate File Name
			    for j=1:1:length(header)
			    	if occursin(r"^Instrument:",header[j])
			    		fname = joinpath(Dest,Dates.format(temp_start,"yyyy-mm-ddTHHMMSS") * "_" * header[j][13:end-1] * ".data")
			    	end
				end
				if verbose
			    	println("\t\t- " * fname)
			    end
			    fid2 = open(fname,"w+")
				
			    # Find and replace the Timestamp header line
			    for j=1:1:length(header);
			    	if occursin(r"^Timestamp",header[j])
			    		header[j] = "Timestamp:  " * Dates.format(temp_start,"yyyy-mm-dd HH:MM:SS:sss") * "\n"
			    	end
			    end
				
			    # Iteratively write the header
			    for j=1:1:length(header)
			    	write(fid2,header[j])
			    end
				
			    write(fid2,l) # Write the line used to create the file name
		    else
			    # An output stream is available
			    l = readline(fid,keep=true) # Load in another line
				
			    # Write or Close
				ft = findall(x -> x == '\t',l)
				#println(l) # Temp
				#println(l[ft[6]+1:ft[8]-1]) # Temp
			    temp_end = DateTime(l[ft[6]+1:ft[8]-1],"yyyy-mm-dd\tHH:MM:SS:sss")
			    if temp_end >= next_start
				    # The current line is newer than the start of the next file, close the current file
				    close(fid2)
					
				    # Zipped File Name (minus extension)
				    fzip = splitext(fname)[1]
					
				    # Zip File
				    if verbose
				    	println("\t\t\tCompressing...")
				    end
				    fzip = fzip * ".ghg"
					ziptextfiles(fzip,fname) # Zip file
				    rm(fname)
			    else
				    # Still within range, write the current line
				    write(fid2,l)
			    end
		    end
	    end
		
	    close(fid2)
	    close(fid)
		
		# Zipped File Name (minus extension)
		fzip = splitext(fname)[1]
		
		# Zip the final file
		if verbose
			println("\t\t\tCompressing...")
		end
		fzip = fzip * ".ghg"
	    fzip2 = fzip * ".ghg"
		ziptextfiles(fzip,fname) # Zip file
	    rm(fname)
    end
	
    if verbose
    	println("Complete")
    end
end
