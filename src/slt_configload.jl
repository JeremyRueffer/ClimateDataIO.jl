# slt_configload.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 18.04.2019

"""# slt_configload

Load a list of .CFG files

`slt_configload(files::Array{T,1}) where T <: String`\n
* **files**::Array{String,1} = Array of CFG file names"""
function slt_configload(files::Array{T,1})::Array{Dict,1} where T <: String
	# Dict Prep
	Time = DateTime(9999)			# DateTime
	FileName = ""					# String
	Sonic = ""						# String
	Analyzer = ""					# String
	Sonic_Alignment = 0.0			# Float64
	Frequency = ""					# String
	Average_Time = 0.0				# Float64
	Station_Height = ""				# String
	Measurement_Height = ""			# String
	Vegetation_Height = ""			# String
	Inductance_CO2 = ""				# String
	Inductance_H2O = ""				# String
	Coordinate_Rotation = ""		# String
	Webb_Correction = false			# Bool
	Linear_Detrend = false			# Bool
	Analog_Inputs = zeros(Int,6)	# Array{Int,1}
	Analog_Names = Array{String}(undef,6)		# Array{String,1}
	Analog_Lower = zeros(Int,6)					# Array{Int,1}
	Analog_Upper = zeros(Int,6)					# Array{Int,1}
	Analog_Units = Array{String}(undef,6)		# Array{String,1}
	Analog_Delay = zeros(Int,6)					# Array{Int,1}
	Slope = zeros(Float64,6)			# Array{Float64,1}
	Analog_Count = 0					# Int
	
	configs = Array{Dict}(undef,length(files))
	
	# Fill Fields with Single Values
	for i=1:1:length(files)
		# Initialize empty arrays
		Analog_Inputs = zeros(Int,6)
		Analog_Names = Array{String}(undef,0)
		Analog_Lower = zeros(Int,6)
		Analog_Upper = zeros(Int,6)
		Analog_Units = Array{String}(undef,0)
		Analog_Delay = zeros(Int,6)
		Slope = zeros(Float64,6)
		
		FileName = files[i]
		Time = DateTime(Meta.parse(files[i][end-14:end-11])) + Dates.Day(Meta.parse(files[i][end-10:end-8])) - Dates.Day(1) + Dates.Hour(Meta.parse(files[i][end-7:end-6])) + Dates.Minute(Meta.parse(files[i][end-5:end-4]))
		
		# Load Config File
		analog = Array{String}(undef,6)
		fid = open(files[i],"r")
		try
			readline(fid)
			Sonic = readline(fid)[8:end]
			Analyzer = readline(fid)[11:end]
			Sonic_Alignment = Meta.parse(readline(fid)[18:end-4])
			Frequency = readline(fid)[19:end-3]
			Average_Time = Meta.parse(readline(fid)[15:end-4])
			analog[1] = readline(fid)
			analog[2] = readline(fid)
			analog[3] = readline(fid)
			analog[4] = readline(fid)
			analog[5] = readline(fid)
			analog[6] = readline(fid)
			Station_Height = readline(fid)[17:end-2]
			readline(fid)
			Measurement_Height = readline(fid)[21:end-2]
			Vegetation_Height = readline(fid)[20:end-2]
			Inductance_CO2 = readline(fid)[21:end-1]
			Inductance_H2O = readline(fid)[21:end-1]
			Coordinate_Rotation = readline(fid)[22:end]
			Webb_Correction = readline(fid)[18:end] == "yes"
			Linear_Detrend = readline(fid)[20:end] == "yes"
		catch e
			println("Problem loading configuration: " * files[1])
			println(e)
		end
		close(fid)
		
		# Parse Analog Inputs
		for j=1:1:length(analog)
			if analog[j][end] == 'E'
				f = readdlm(IOBuffer(analog[j]),',')
				
				Analog_Inputs[j] = j
				Analog_Names = [Analog_Names;String(strip(f[1]))]
				Analog_Lower[j] = f[2]
				Analog_Units = [Analog_Units;String(strip(f[4]))]
				Analog_Upper[j] = f[3]
				Analog_Delay[j] = f[5]
				Slope[j] = (f[3] - f[2])/5000
			end
		end
		Analog_Count = length(Analog_Names)
		
		configs[i] = Dict("Time"=>Time,"FileName"=>FileName,"Sonic"=>Sonic,"Analyzer"=>Analyzer,"Sonic_Alignment"=>Sonic_Alignment,"Frequency"=>Frequency,"Average_Time"=>Average_Time,"Station_Height"=>Station_Height,"Measurement_Height"=>Measurement_Height,"Vegetation_Height"=>Vegetation_Height,"Inductance_CO2"=>Inductance_CO2,"Inductance_H2O"=>Inductance_H2O,"Coordinate_Rotation"=>Coordinate_Rotation,"Webb_Correction"=>Webb_Correction,"Linear_Detrend"=>Linear_Detrend,"Analog_Inputs"=>Analog_Inputs,"Analog_Names"=>Analog_Names,"Analog_Lower"=>Analog_Lower,"Analog_Upper"=>Analog_Upper,"Analog_Units"=>Analog_Units,"Analog_Delay"=>Analog_Delay,"Slope"=>Slope,"Analog_Count"=>Analog_Count)
	end
	
	# Sort Config Files
	I = sortperm(get.(configs,"Time",DateTime(9999)))
	configs = configs[I]
	return configs
end # slt_configload(files::Array{T,1}) where T <: String
