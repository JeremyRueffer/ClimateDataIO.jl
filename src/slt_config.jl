# slt_config.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 25.07.2018

"""# slt_config

Load configuration data from .CFG files or a directory of files.

`slt_config(filefolder)`\n
* **filefolder**::String = File, list of files, or folder with CFG files"""
function slt_config(filefolder::String)::Array{Dict,1}
	outputfiles = [""]
	if isdir(filefolder)
		(outputfiles,folder) = dirlist(filefolder,regex=r"\.cfg$")
	else
		outputfiles = [filefolder]
	end
	
	return slt_configload(outputfiles)
end # slt_config(filefolder::String)::Dict

function slt_config(files::Array{T,1})::Array{Dict,1} where T <: String
	return slt_configload(files)
end # slt_config(files::Array{T,1})::Dict where T <: String
