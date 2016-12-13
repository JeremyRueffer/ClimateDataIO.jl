# ziptextfiles.jl
#
#   Zip a text file or list of text files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 08.12.2016
# Last Edit: 13.12.2016

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
	zid = ZipFile.Writer(dest) # Open zip file
	
	# Zip Each File
	for i=1:1:length(files)
		if isfile(files[i])
			verbose ? println("\t" * files[i]) : nothing
			fid_destination = ZipFile.addfile(zid,basename(files[i]),method=ZipFile.Deflate)
			fid_source = open(files[i],"r")
			while !eof(fid_source)
				write(fid_destination,readline(fid_source))
			end
			close(fid_source)
			close(fid_destination)
		else
			println("\t" * files[i] * " doesn't exist")
		end
	end
	
	close(zid) # Close zip file
	
	verbose ? println("Complete") : nothing
	nothing
end
