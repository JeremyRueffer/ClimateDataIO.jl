# slt_configload.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.1
# 09.12.2016
# Last Edit: 12.12.2017

"""# slt_configload

Load a list of .CFG files

`slt_configload{T<:String}(files::Array{T,1})`\n
* **files**::Array{String,1} = Array of CFG file names"""
function slt_configload{T<:String}(files::Array{T,1})::DataFrame
	# DataFrame Setup
	col_names = [:Time,:FileName,:Sonic,:Analyzer,:Sonic_Alignment,:Frequency,
		:Average_Time,:Station_Height,:Measurement_Height,:Vegetation_Height,
		:Inductance_CO2,:Inductance_H2O,:Coordinate_Rotation,:Webb_Correction,
		:Linear_Detrend,:Analog_Inputs,:Analog_Names,:Analog_Lower,:Analog_Upper,
		:Analog_Units,:Analog_Delay,:Slope,:Analog_Count]
	col_types = [DateTime,
		String,
		String,
		String,
		Float64,
		String,
		Float64,
		String,
 		String,
 		String,
 		String,
 		String,
 		String,
 		Bool,
 		Bool,
 		Array{Int,1},
 		Array{String,1},
 		Array{Int,1},
 		Array{Int,1},
 		Array{String,1},
 		Array{Int,1},
 		Array{Float64,1},
 		Int]
	configs = DataFrame(col_types,col_names,length(files))
	
	# Fill Fields with Single Values
	for i=1:1:length(files)
		# Initialiye empty arrays
		configs[:Analog_Inputs][i] = Array{Int,1}(0)
		configs[:Analog_Names][i] = Array{String,1}(0)
		configs[:Analog_Lower][i] = Array{Int,1}(0)
		configs[:Analog_Upper][i] = Array{Int,1}(0)
		configs[:Analog_Units][i] = Array{String,1}(0)
		configs[:Analog_Delay][i] = Array{Int,1}(0)
		configs[:Slope][i] = Array{Float64,1}(0)
		
		configs[:FileName][i] = files[i]
		time = DateTime(parse(files[i][end-14:end-11])) + Dates.Day(parse(files[i][end-10:end-8])) - Dates.Day(1) + Dates.Hour(parse(files[i][end-7:end-6])) + Dates.Minute(parse(files[i][end-5:end-4]))
		configs[:Time][i] = time
		
		# Load Config File
		analog = Array{String,1}(6)
		fid = open(files[i],"r")
		try
			readline(fid)
			configs[:Sonic][i] = readline(fid)[8:end]
			configs[:Analyzer][i] = readline(fid)[11:end]
			configs[:Sonic_Alignment][i] = parse(readline(fid)[18:end-4])
			configs[:Frequency][i] = readline(fid)[19:end-3]
			configs[:Average_Time][i] = parse(readline(fid)[15:end-4])
			analog[1] = readline(fid)
			analog[2] = readline(fid)
			analog[3] = readline(fid)
			analog[4] = readline(fid)
			analog[5] = readline(fid)
			analog[6] = readline(fid)
			configs[:Station_Height][i] = readline(fid)[17:end-2]
			readline(fid)
			configs[:Measurement_Height][i] = readline(fid)[21:end-2]
			configs[:Vegetation_Height][i] = readline(fid)[20:end-2]
			configs[:Inductance_CO2][i] = readline(fid)[21:end-1]
			configs[:Inductance_H2O][i] = readline(fid)[21:end-1]
			configs[:Coordinate_Rotation][i] = readline(fid)[22:end]
			configs[:Webb_Correction][i] = readline(fid)[18:end] == "yes"
			configs[:Linear_Detrend][i] = readline(fid)[20:end] == "yes"
		catch e
			println("Problem loading configuration: " * files[1])
			println(e)
		end
		close(fid)
		
		# Parse Analog Inputs
		for j=1:1:length(analog)
			if analog[j][end] == 'E'
				f = readcsv(IOBuffer(analog[j]))
				
				configs[:Analog_Inputs][i] = [configs[:Analog_Inputs][i];j]
				configs[:Analog_Names][i] = [configs[:Analog_Names][i];String(strip(f[1]))]
				configs[:Analog_Lower][i] = [configs[:Analog_Lower][i];f[2]]
				configs[:Analog_Units][i] = [configs[:Analog_Units][i];String(strip(f[4]))]
				configs[:Analog_Upper][i] = [configs[:Analog_Upper][i];f[3]]
				configs[:Analog_Delay][i] = [configs[:Analog_Delay][i];f[5]]
				configs[:Slope][i] = [configs[:Slope][i];(f[3] - f[2])/5000]
			end
		end
		configs[:Analog_Count][i] = length(configs[:Analog_Names][])
	end
	
	# Sort Config Files
	I = sortperm(configs[:Time])
	configs = configs[I,:]
	
	return configs
end # slt_configload{T<:String}(files::Array{T,1})
