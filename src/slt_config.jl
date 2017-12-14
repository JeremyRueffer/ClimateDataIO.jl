# slt_config.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.1
# 09.12.2016
# Last Edit: 12.12.2017

"""# slt_config

Load configuration data from .CFG files or a directory of files.

`slt_config(filefolder)`\n
* **filefolder**::String = File, list of files, or folder with CFG files"""
function slt_config(filefolder::String)::DataFrame
	outputfiles = [""]
	if isdir(filefolder)
		(outputfiles,folder) = dirlist(filefolder,regex=r"\.cfg$")
	else
		outputfiles = [filefolder]
	end
	
	return slt_configload(outputfiles)
end # slt_config(filefolder::String)::DataFrame

function slt_config{T<:String}(files::Array{T,1})::DataFrame
	return slt_configload(files)
end # slt_config{T<:String}(files::Array{T,1})::DataFrame
