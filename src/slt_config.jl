# slt_config.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 09.12.2016
# Last Edit: 19.12.2016

"""# slt_config

Load configuration data from .CFG files or a directory of files.

`slt_config(filefolder)`\n
* **filefolder**::String = File, list of files, or folder with CFG files"""
function slt_config(filefolder::String)
	if isdir(filefolder)
		(filefolder,folder) = dirlist(filefolder,regex=r"\.cfg$")
	else
		filefolder = [filefolder]
	end
	
	return slt_configload(filefolder)
end # slt_config(filefolder::String)

function slt_config{T<:String}(files::Array{T,1})
	return slt_configload(files)
end # slt_config{T<:String}(files::Array{T,1})
