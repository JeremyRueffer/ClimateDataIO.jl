# Directory listing function test
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# Created: 01.11.2013
# Last Edit: 26.06.2018

"""# dirlist(directory::ASCIIString;recur_depth::Int,regular_expression::Regex)

`(files,folders) = dirlist(\"K:\\\\Code\\\\\")` List all the files in the Code directory and all its subdirectories

`(files,folders) = dirlist([\"K:\\\\Code\\\\Matlab\\\\\",\"K:\\\\Code\\\\Julia\\\\\"])` List all the files in the K:\\Code\\Matlab\\ and K:\\Code\\Julia\\ directories and all of their subdirectories

`(files,folders) = dirlist(\"K:\\\\Code\\\\\",recur=2)` List all the files in the Code directory and one levels of directories below that.

`(files,folders) = dirlist([\"K:\\\\Code\\\\\"],recur=2)` List all the files and folders in the Code directory and one levels below that.

`(files,folders) = dirlist([\"K:\\\\Code\\\\\"],recur=2,regex=r\"\\.jl\$\")` Limit the files to those that match the regular expression `r\"\\.jl\$\"`

---

#### Keywords:\n
* recur::Int = Subdirectory recursion depth. 1 is the root directory.
* regex::Regex = Regular expression\n\n

---

\n
#### Regular Expression Examples\n
* Regular expression reference: http://www.regular-expressions.info
* `r\"(AirTemp).*\\d{8}-\\d{6}\"` Search for names with AirTemp followed by any number of characters then followed by 8 numbers, a dash, and 6 more numbers
* `r\"\\d{8}-\\d{6}\"` Search for names with eight digits followed by a dash and another six digits (12345678-654321)
* `r\"(example)\"` Search for all files with \"example\" in the name.
* `r\"\\.jl\$\"` Search for .jl at the end of the file. The . must be escaped with a \\
* `r\"(slt|cfg)\$\"` Search for files that end in slt or cfg\n\n

---

\n
#### Related Functions\n
* joinpath
* isdir
* isfile
* splitdir
* splitdrive
* basename
* dirname"""
function dirlist(directory::String;args...) #function dirlist{T <: String}(directory::Vector{T};args...)
    return dirlist([directory];args...)
end

#function dirlist{T <: String}(directories::Array{T,1};recur=typemax(Int),regex=r"")
function dirlist(directories::Array{T,1};recur::Int=typemax(Int),regex::Regex=r"") where T <: String
	###################################
	##  Regular Expression Examples  ##
	###################################
	# Regular expression reference: http://www.regular-expressions.info
	# reg = r"(AirTemp).*\d{8}-\d{6}" # Search for names with AirTemp followed by any number of characters then followed by 8 numbers, a dash, and 6 more numbers
	# r"\d{8}-\d{6}" # Search for names with eight digits followed by a dash and another six digits (12345678-654321)
	# r"(example)" # Search for all files with "example" in the name
	# r"\.jl$" # Search for .jl at the end of the file. The . must be escaped with a \
	
    # Parse Inputs
    rcr_max = Int[]
    try
		rcr_max = Int(recur)
	catch e
		error("recur must be convertable to Int")
	end
	
	# Initialize variables to be used inside the loop
	flist = Array{String}(undef,0) # File list
	dlist = Array{String}(undef,0) # Directory list
	rcr = 1
	lst = Array{String}(undef,0)
	nextdirs = Array{String}(undef,0)
	
	# Iterate through the given directory and its subdirectories
	while rcr <= rcr_max && ~isempty(directories)
		# While the maximum recursion level hasn't been reached and "directories" is not empty
		nextdirs = Array{String}(undef,0) # List of directories for the next iteration
		for i=1:1:length(directories)
			lst = Array{String}(undef,0) # Define and reset on each cycle
			try # May fail on certain folders like K:\__Papierkorb__\
				lst = readdir(directories[i]) # List contents of specified directory
			catch
				println("FAILED READING " * directories[i])
				println("Continuing...")
			end
			fbool = fill!(Array{Bool}(undef,length(lst)),false) # File boolean array, true = file, false = not
			dbool = fill!(Array{Bool}(undef,length(lst)),false) # Directory boolean array (FASTER)
			
			# Check for files and directories
			for j=1:1:length(lst)
				if isdir(joinpath(directories[i],lst[j]))
					dbool[j] = true
					lst[j] = joinpath(directories[i],lst[j]) # Make the directory a full path
				elseif isfile(joinpath(directories[i],lst[j]))
					fbool[j] = true
					lst[j] = joinpath(directories[i],lst[j]) # Make the file a full path
				end
			end
			flist = [flist;lst[fbool]] # Add the new files
			dlist = [dlist;lst[dbool]] # Add the new directories
			nextdirs = [nextdirs;lst[dbool]] # Add the directories to a list of future directories to search
		end
		directories = nextdirs
		rcr += 1 # Next level of recursion
	end
	
    if regex != r""
		# Find specific files if regular expression exists
		matches = repeat([false],length(flist)) # Preallocate a false array
		for i=1:1:length(flist)
			matches[i] = occursin(regex,flist[i])
		end
		flist = flist[matches] # Take only matching files
	end
	
    return flist,dlist # Return the results of the file and directory listing
end
