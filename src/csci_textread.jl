# csci_textread.jl
#
#	Load a Campbell Scientific TOA5 file
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# Created: 04.11.2013
# Last Edit: 11.04.2019

"""# csci_textread

Load a TOA5 data file generated by Campbell Scientific dataloggers

---

### Examples

`t, d = csci_textread(\"K:\\\\Data\\\\AirTemp.dat\")` Load the data from a file into \"t\", a DateTime array, and \"d\", a floating point array.

`t, d, logger_Str, columns_Str, units_Str, type_Str = csci_textload(\"K:\\\\Data\\\\AirTemp.dat\",headerout = true)` # Output the header lines in addition to the data

---

`t, d = csci_textread(F::String;headerlines::Int=4,headeroutput::Bool=false,verbose::Bool=true,strlist::Array{String,1}=String[],intlist::Array{String,1}=String[],timelist::Array{String,1}=String[])`\n
* **data**::DataFrame = Loaded data, including a fully parsed time column
* **F**::String or Array{String,1} = File or an array of files to load
* **headerlines**::Int (optional) = Number of header lines, 4 is default
* **headeroutput**::Bool (optional) = Add four header lines to output, FALSE is default
* **verbose**::Bool (optional) = Display information about what is happening when set to TRUE, TRUE is default
* **strlist**::Array{String} (optional) = List of column names that should be strings, [] is default
* **intlist**::Array{String} (optional) = List of column names that should be integers, [] is default
* **timelist**::Array{String} (optional) = List of column names that should be DateTime values, [] is default
"""
function csci_textread(F::String;headerlines::Int=4,headeroutput::Bool=false,verbose::Bool=true,strlist::Array{String,1}=String[],intlist::Array{String,1}=String[],timelist::Array{String,1}=String[])
	# F = file name and location
	# kwargs = KeyWord Arguments
	#	hout::Bool = Include four additional header lines in outputs
	#	headerlines::Int = Number of header lines
	
	headerlines += 1
	df = Dates.DateFormat("yyyy-mm-dd HH:MM:SS.ss") # Date format
	
	## Update Conversion Lists
	strlist = ["OSVersion";"ProgName";"CompileResults";"CardStatus";"IPInfo";"pppDialResponse";"DataTableName\\(\\d\\)";"PortConfig\\(\\d\\)";"IPAddressEth";"IPMaskEth";"IPGateway";"pppIPAddr";"pppUsername";"pppPassword";"pppDial";"Messages";strlist]
	intlist = ["RECORD";"TCPPort";intlist]
	timelist = ["TIMESTAMP";"StartTime";"LastSystemScan";timelist]
	
	## Load Header Data
	fid = open(F,"r")
	loggerStr = readline(fid)
	colsStr = readline(fid)
	unitsStr = readline(fid)
	processingStr = readline(fid)
	close(fid)
	
	logger = readdlm(IOBuffer(loggerStr),',')
	cols_temp = readdlm(IOBuffer(colsStr),',')
	units = readdlm(IOBuffer(unitsStr),',')
	processing_temp = readdlm(IOBuffer(processingStr),',')
	
	cols = Array{String}(undef,length(cols_temp))
	processing = Array{String}(undef,length(cols_temp))
	for i=1:length(cols)
		cols[i] = cols_temp[i]
		processing[i] = processing_temp[i]
	end
	
	## Prepare Type List
	types = Any[Float64 for i=1:length(processing)]
	for i=1:1:length(types)
		for j=1:1:length(strlist)
			if occursin(Regex(strlist[j]),cols[i])
				types[i] = Union{Missing,String}
			end
		end
	end
	for i=1:1:length(types)
		for j=1:1:length(intlist)
			if occursin(Regex(intlist[j]),cols[i])
				types[i] = Int
			end
		end
	end
	t_index = Int[]
	for i=1:1:length(types)
		for j=1:1:length(timelist)
			if occursin(Regex(timelist[j]),cols[i])
				types[i] = DateTime
				t_index = [t_index;i]
			end
		end
	end
	
	cols[1] = "Timestamp"
	cols[2] = "Record"
	
	## Load Data
	D = CSV.read(F;types = types,header=cols,delim = ',',datarow = headerlines,dateformat = df)
	#D = readtable(F,eltypes = types,separator = ',',header = false,skipstart = headerlines)
	
	if headeroutput
		return D,loggerStr,colsStr,unitsStr,processingStr
	else
		return D
	end
end # csci_textread(F::String;headerlines=4,headeroutput=false,verbose=true,strlist=[],intlist=[],timelist=[])
