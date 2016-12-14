# aerodyne_parsetime.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 13.12.2016
# Last Edit: 13.12.2016

"""# aerodyne_parsetime

Parse the STR and STC file name timestamps into DateTime and sort

`time,Files = aerodyne_parsetime(F)`\n
* **time**::DateTime = Sorted timestamps
* **Files**::Array{String} = Temporally sorted file list
* **F**::Array{String} = List of files to parse and sort
"""
function aerodyne_parsetime{T<:String}(F::Array{T,1})
	## Parse the names of files into a readable time ##
	t = Array(DateTime,Int64(length(F))) # Preallocate time column
	for i = 1:1:length(F)
		t[i] = DateTime("20" * F[i][end-16:end-4],"yyyymmdd_HHMMSS")
	end
	I = sortperm(t) # Sort index (by time)
	t = t[I] # Sort time by time
	F = F[I] # Sort the files by time
	
	return t,F
end # End of aerodyne_parsetime(F::Array{String,1})
