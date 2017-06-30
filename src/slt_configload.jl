# slt_configload.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6
# 09.12.2016
# Last Edit: 19.05.2017

"""# slt_configload

Load a list of .CFG files

`slt_configload{T<:String}(files::Array{T,1})`\n
* **files**::Array{String,1} = Array of CFG file names"""
function slt_configload{T<:String}(files::Array{T,1})
	# Convert File Name Dates
	configs = DataFrame()
	for i=1:1:length(files)
		time = DateTime(parse(files[i][end-14:end-11])) + Dates.Day(parse(files[i][end-10:end-8])) - Dates.Day(1) + Dates.Hour(parse(files[i][end-7:end-6])) + Dates.Minute(parse(files[i][end-5:end-4]))
		
		# Load Config File
		config = DataFrame(Time = time, FileName = files[i])
		analog = []
		fid = open(files[i],"r")
		try
			readline(fid)
			config[:Sonic] = readline(fid)[8:end]
			config[:Analyzer] = readline(fid)[11:end]
			config[:Sonic_Alignment] = parse(readline(fid)[18:end-4])
			config[:Frequency] = readline(fid)[19:end-3]
			config[:Average_Time] = parse(readline(fid)[15:end-4])
			analog = [readline(fid)]
			analog = [analog;readline(fid)]
			analog = [analog;readline(fid)]
			analog = [analog;readline(fid)]
			analog = [analog;readline(fid)]
			analog = [analog;readline(fid)]
			config[:Station_Height] = readline(fid)[17:end-2]
			readline(fid)
			config[:Measurement_Height] = readline(fid)[21:end-2]
			config[:Vegetation_Height] = readline(fid)[20:end-2]
			config[:Inductance_CO2] = readline(fid)[21:end-1]
			config[:Inductance_H2O] = readline(fid)[21:end-1]
			config[:Coordinate_Rotation] = readline(fid)[22:end]
			config[:Webb_Correction] = readline(fid)[18:end] == "yes"
			config[:Linear_Detrend] = readline(fid)[20:end] == "yes"
		catch e
			println("Problem loading configuration: " * files[1])
			println(e)
		end
		close(fid)
		
		# Parse Analog Inputs
		#config = DataFrame(Analog_Inputs = [],Analog_Names = [],Analog_Lower = [],Analog_Upper = [],Analog_Units = [],Analog_Delay = [],Slope = [])
		config[:Analog_Inputs] = collect(Array[[]])
		config[:Analog_Names] = collect(Array[[]])
		config[:Analog_Lower] = collect(Array[[]])
		config[:Analog_Upper] = collect(Array[[]])
		config[:Analog_Units] = collect(Array[[]])
		config[:Analog_Delay] = collect(Array[[]])
		config[:Slope] = collect(Array[[]])
		for i=1:1:length(analog)
			if analog[i][end] == 'E'
				f = readcsv(IOBuffer(analog[i]))
				config[:Analog_Inputs] = Array[[config[:Analog_Inputs][1];i]]
				config[:Analog_Names] = Array[[config[:Analog_Names][1];strip(f[1])]]
				config[:Analog_Lower] = Array[[config[:Analog_Lower][1];f[2]]]
				config[:Analog_Upper] = Array[[config[:Analog_Upper][1];f[3]]]
				config[:Analog_Units] = Array[[config[:Analog_Units][1];strip(f[4])]]
				config[:Analog_Delay] = Array[[config[:Analog_Delay][1];f[5]]]
				config[:Slope] = Array[[config[:Slope][1];(f[3] - f[2])/5000]]
			end
		end
		config[:Analog_Count] = length(config[:Analog_Names][1])
		
		configs = [configs;config]
	end
	
	# Sort Config Files
	I = sortperm(configs[:Time])
	configs = configs[I,:]
	
	return configs
end # slt_configload{T<:String}(files::Array{T,1})
