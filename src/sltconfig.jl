# sltconfig.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 09.12.2016
# Last Edit: 09.12.2016

"""# sltconfig

Load configuration data from .CFG files or a directory of files.

`sltconfig(filefolder)`\n
* **filefolder**::String = File, list of files, or folder with CFG files"""
function sltconfig(filefolder::String)
	if isdir(filefolder)
		(filefolder,folder) = dirlist(filefolder,regex=r"\.cfg$")
	else
		filefolder = [filefolder]
	end
	
	return sltconfig_load(filefolder)
end # sltconfig(filefolder::String)

function sltconfig{T<:String}(files::Array{T,1})
	return sltconfig_load(files)
end # sltconfig{T<:String}(files::Array{T,1})
