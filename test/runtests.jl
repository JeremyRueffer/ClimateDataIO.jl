using ClimateDataIO
using Base.Test

# Last Edit: 31.01.17

# SLTLOAD: Check a known set of data
println("\n====  SLTLOAD  ====")
src = splitdir(@__FILE__)[1]
mindate = DateTime(2016,11,23,14,4)
maxdate = DateTime(2016,11,23,18)
Data = ClimateDataIO.slt_load(src,mindate,maxdate,verbose=true)
@test size(Data) == (141377,13) || "SLTLOAD: Output size incorrect, should be (141377,13)"
@test Data[:Time][1] == DateTime(2016,11,23,14,4) || "SLTLOAD: First timestamp should be 2016-11-23T14:04:00"
@test Data[:Time][end] == DateTime(2016,11,23,17,59,59,900) || "SLTLOAD: Last timestamp should be 2016-11-23T17:59:59.9"



tmean, Dmean, Dstd, Dmin, Dmax = ClimateDataIO.slt_load(src,mindate,maxdate,verbose=true,average=true)
@test size(Dmean) == (8,12) || "SLTLOAD: Output size incorrect, should be (8,12)"
@test size(Dstd) == (8,12) || "SLTLOAD: Output size incorrect, should be (8,12)"
@test size(Dmin) == (8,12) || "SLTLOAD: Output size incorrect, should be (8,12)"
@test size(Dmax) == (8,12) || "SLTLOAD: Output size incorrect, should be (8,12)"
@test length(tmean) == 8 || "SLTLOAD: Output length incorrect, should be 8"
@test tmean[1] == DateTime(2016,11,23,14,4) || "SLTLOAD: First timestamp should be 2016-11-23T14:04:00"
@test tmean[end] == DateTime(2016,11,23,17,34) || "SLTLOAD: Last timestamp should be 2016-11-23T17:34:00"



src = splitdir(@__FILE__)[1]
mindate = DateTime(2016,11,23,14,4)
maxdate = DateTime(2016,11,23,18)
dest = joinpath(splitdir(@__FILE__)[1],"temporary_files")
isdir(dest) ? nothing: mkdir(dest)
maxcols = 2 # Max analog columns
ClimateDataIO.slt_trim(src,dest,mindate,maxdate,maxcols)
Data = ClimateDataIO.slt_load(dest,mindate,maxdate)
f = ["W20163281404.cfg",
	"W20163281404.csr",
	"W20163281404.csu",
	"W20163281404.csv",
	"W20163281404.flx",
	"W20163281404.log",
	"W20163281404.slt",
	"W20163281430.slt",
	"W20163281500.slt",
	"W20163281530.slt",
	"W20163281600.slt",
	"W20163281630.slt",
	"W20163281700.slt",
	"W20163281730.slt"]
for i in f
	rm(joinpath(dest,i))
end
@test size(Data) == (141377,9) || "SLTLOAD: Output size incorrect, should be (141377,9)"
@test Data[:Time][1] == DateTime(2016,11,23,14,4) || "SLTLOAD: First timestamp should be 2016-11-23T14:04:00"
@test Data[:Time][end] == DateTime(2016,11,23,17,59,59,900) || "SLTLOAD: Last timestamp should be 2016-11-23T17:59:59.9"



src = joinpath(splitdir(@__FILE__)[1],"W20163280930.slt")
header = slt_header(src,6,10)
println(typeof(header)) # Temp



# SLTREAD: Load one known file
println("\n====  SLTREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"W20163281000.slt")
analog_inputs = 6 # Number of analog inputs
sample_frequency = 10 # Hz
Time,Data = ClimateDataIO.slt_read(src,analog_inputs,sample_frequency)
@test size(Data) == (18003,10) || "SLTREAD: Output size incorrect, should be (18003,10)"
@test Time[1] == DateTime(2016,11,23,10) || "SLTREAD: First timestamp should be 2016-11-23T10:00:00"
@test Time[end] == DateTime(2016,11,23,10,30,00,200) || "SLTREAD: Last timestamp should be 2016-11-23T10:30:00.2"



# SLT_TIMESHIFT
println("\n====  SLT_TIMESHIFT Tests  ====")
src = splitdir(@__FILE__)[1]
dest = joinpath(splitdir(@__FILE__)[1],"temporary_files")
mindate = DateTime(2016,11,23,14,4)
maxdate = DateTime(2016,11,23,17)
dt = Dates.Hour(4)
slt_timeshift(src,dest,mindate,maxdate,dt)
Data = ClimateDataIO.slt_load(dest,mindate + dt,maxdate + dt,verbose=true)
f = ["W20163281804.cfg",
	"W20163281804.csr",
	"W20163281804.csu",
	"W20163281804.csv",
	"W20163281804.flx",
	"W20163281804.log",
	"W20163281804.slt",
	"W20163281830.slt",
	"W20163281900.slt",
	"W20163281930.slt",
	"W20163282000.slt",
	"W20163282030.slt"]
for i in f
	println(joinpath(dest,i))
	rm(joinpath(dest,i))
end
@test Data[:Time][1] == DateTime(2016,11,23,18,4) || "SLT_TIMESHIFT: Last timestamp should be 2016-11-23T18:04:00"
@test Data[:Time][end] == DateTime(2016,11,23,21,0,0,100) || "SLT_TIMESHIFT: Last timestamp should be 2016-11-23T21:00:00.1"



# STR_LOAD: Load one Aerodyne STR file
println("\n====  STR_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"161210_000000.str")
cols = ["NH3"]
Time,Data = ClimateDataIO.str_load(src,verbose=true,cols=cols)
@test Time[1] == DateTime(2016,12,10,0,0,0,622) || "STR_LOAD: First timestamp should be 2016-12-10T00:00:00.622"
@test Time[end] == DateTime(2016,12,10,0,59,59,922) || "STR_LOAD: Last timestamp should be 2016-12-10T00:59:59.922"
@test size(Data) == (35159,1) || "STR_LOAD: Output size incorrect, should be (35159,2)"



println("\nMultiple files")
src = splitdir(@__FILE__)[1]
Time,Data = ClimateDataIO.str_load(src,verbose=true)
@test Time[1] == DateTime(2016,12,10,0,0,0,622) || "STR_LOAD: First timestamp should be 2016-12-10T00:00:00.622"
@test Time[end] == DateTime(2016,12,10,3,59,59,917) || "STR_LOAD: Last timestamp should be 2016-12-10T03:59:59.917"
@test size(Data) == (140641,2) || "STR_LOAD: Output size incorrect, should be (140641,2)"



# STC_LOAD: Load one Aerodyne STC file
println("\n====  STC_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"161210_000000.stc")
Time,Data = ClimateDataIO.stc_load(src,verbose=true)
@test Time[1] == DateTime(2016,12,10,0,0,2,622) || "STC_LOAD: First timestamp should be 2016-12-10T00:00:02.622"
@test Time[end] == DateTime(2016,12,10,0,59,59,622) || "STC_LOAD: Last timestamp should be 2016-12-10T00:59:59.622"
@test size(Data) == (3598,26) || "STC_LOAD: Output size incorrect, should be (35159,2)"



println("\nMultiple files")
src = splitdir(@__FILE__)[1]
Time,Data = ClimateDataIO.stc_load(src,verbose=true)
@test Time[1] == DateTime(2016,12,10,0,0,2,622) || "STC_LOAD: First timestamp should be 2016-12-10T00:00:02.622"
@test Time[end] == DateTime(2016,12,10,3,59,59,117) || "STC_LOAD: Last timestamp should be 2016-12-10T03:59:59.117"
@test size(Data) == (14391,26) || "STC_LOAD: Output size incorrect, should be (14391,2)"



println("\nStatus Values")
statuses = ClimateDataIO.AerodyneStatus(Data[:StatusW])
temp = fill!(Array(Bool,14391),false)
@test temp == statuses.Valve1 || "AERODYNESTATUS: All values in statuses.Valve1 should be FALSE"
@test temp == statuses.Valve2 || "AERODYNESTATUS: All values in statuses.Valve2 should be FALSE"
@test temp == statuses.Valve3 || "AERODYNESTATUS: All values in statuses.Valve3 should be FALSE"
@test temp != statuses.Valve4 || "AERODYNESTATUS: All values in statuses.Valve4 should not all be FALSE"
@test temp == statuses.Valve5 || "AERODYNESTATUS: All values in statuses.Valve5 should be FALSE"
@test temp == statuses.Valve6 || "AERODYNESTATUS: All values in statuses.Valve6 should be FALSE"
@test temp == statuses.Valve7 || "AERODYNESTATUS: All values in statuses.Valve7 should be FALSE"
@test temp != statuses.Valve8 || "AERODYNESTATUS: All values in statuses.Valve8 should not all be FALSE"
known_names = [:AutoBG;:AutoCal;:FrequencyLock;:BinomialFilter;:AltMode;:GuessLast;:PowerNorm;:ContRefLock;:AutoSpectSave;:PressureLock;:WriteData;:RS232;:ElectronicBGSub;:Valve1;:Valve2;:Valve3;:Valve4;:Valve5;:Valve6;:Valve7;:Valve8]
@test known_names == fieldnames(statuses) || "AERODYNESTATUS: statuses field names should be as follows - \n21-element Array{Symbol,1}:\n  :AutoBG\n  :AutoCal\n  :FrequencyLock\n  :BinomialFilter\n  :AltMode\n  :GuessLast\n  :PowerNorm\n  :ContRefLock\n  :AutoSpectSave\n  :PressureLock\n  :WriteData\n  :RS232\n  :ElectronicBGSub\n  :Valve1\n  :Valve2\n  :Valve3\n  :Valve4\n  :Valve5\n  :Valve6\n  :Valve7\n  :Valve8"



src = splitdir(@__FILE__)[1]
src = joinpath(src,"161210_000000.stc")
Time,Data = ClimateDataIO.stc_load(src,verbose=true,cols = ["Praw","time"])
@test names(Data) == [:Praw,:time] || "STC_LOAD: Fields should be [:Praw,:time]"



# CSCI_TEXTREAD: Load one file
println("\n====  CSCI_TEXTREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"CampbellScientific_HC2S3_20161201-000000.dat")
Data = ClimateDataIO.csci_textread(src,verbose=true)
@test Data[:Timestamp][1] == DateTime(2016,12,1,0,0,0) || "CSCI_TEXTREAD: Data[:Timestamp] first timestamp should be 2016-12-01T00:00:00"
@test Data[:Timestamp][end] == DateTime(2016,12,4,23,59,30) || "CSCI_TEXTREAD: Data[:Timestamp] last timestamp should be 2016-12-04T23:59:30"
@test size(Data) == (11520,10) || "CSCI_TEXTREAD: Data output size incorrect, should be (11520,10)"



Data,loggerStr,colsStr,unitsStr,processingStr = ClimateDataIO.csci_textread(src,verbose=true,headeroutput=true)
@test loggerStr == "\"TOA5\",\"CR1000 - IP\",\"CR1000\",\"E2948\",\"CR1000.Std.22\",\"CPU:LoggerCode.CR1\",\"35271\",\"Rotronics_HC2S3\"\r\n" || "loggerStr should be \"TOA5\",\"CR1000 - IP\",\"CR1000\",\"E2948\",\"CR1000.Std.22\",\"CPU:LoggerCode.CR1\",\"35271\",\"Rotronics_HC2S3\"\\r\\n"
@test colsStr == "\"TIMESTAMP\",\"RECORD\",\"AirTemp_HC2S3_S01\",\"RelHum_HC2S3_S01\",\"AirTemp_HC2S3_S02\",\"RelHum_HC2S3_S02\",\"AirTemp_HC2S3_S03\",\"RelHum_HC2S3_S03\",\"AirTemp_HC2S3_S04\",\"RelHum_HC2S3_S04\"\r\n" || "colsStr should be \"TIMESTAMP\",\"RECORD\",\"AirTemp_HC2S3_S01\",\"RelHum_HC2S3_S01\",\"AirTemp_HC2S3_S02\",\"RelHum_HC2S3_S02\",\"AirTemp_HC2S3_S03\",\"RelHum_HC2S3_S03\",\"AirTemp_HC2S3_S04\",\"RelHum_HC2S3_S04\"\\r\\n"
@test unitsStr == "\"TS\",\"RN\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\"\r\n" || "unitsStr should be \"TS\",\"RN\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\"\\r\\n"
@test processingStr == "\"\",\"\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\"\r\n" || "processingStr should be \"\",\"\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\"\\r\\n"
@test Data[:Timestamp][1] == DateTime(2016,12,1,0,0,0) || "CSCI_TEXTREAD: Data[:Timestamp] first timestamp should be 2016-12-01T00:00:00"
@test Data[:Timestamp][end] == DateTime(2016,12,4,23,59,30) || "CSCI_TEXTREAD: Data[:Timestamp] last timestamp should be 2016-12-04T23:59:30"
@test size(Data) == (11520,10) || "CSCI_TEXTREAD: Data output size incorrect, should be (11520,10)"



println("\n===  CSCI_TEXTLOAD  ===")
Data, HeaderInfo, HeaderColumns, HeaderUnits, HeaderSample = ClimateDataIO.csci_textload([src],verbose=true,headerlines=4,headeroutput=true)
h1 = "\"TOA5\",\"CR1000 - IP\",\"CR1000\",\"E2948\",\"CR1000.Std.22\",\"CPU:LoggerCode.CR1\",\"35271\",\"Rotronics_HC2S3\"\r\n"
h2 = "\"TIMESTAMP\",\"RECORD\",\"AirTemp_HC2S3_S01\",\"RelHum_HC2S3_S01\",\"AirTemp_HC2S3_S02\",\"RelHum_HC2S3_S02\",\"AirTemp_HC2S3_S03\",\"RelHum_HC2S3_S03\",\"AirTemp_HC2S3_S04\",\"RelHum_HC2S3_S04\"\r\n"
h3 = "\"TS\",\"RN\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\"\r\n"
h4 = "\"\",\"\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\"\r\n"
@test Data[:Timestamp][1] == DateTime(2016,12,1,0,0,0) || "CSCI_TEXTREAD: Data[:Timestamp] first timestamp should be 2016-12-01T00:00:00"
@test Data[:Timestamp][end] == DateTime(2016,12,4,23,59,30) || "CSCI_TEXTREAD: Data[:Timestamp] last timestamp should be 2016-12-04T23:59:30"
@test size(Data) == (11520,10) || "CSCI_TEXTLOAD: Data output size incorrect, should be (11520,10)"
@test h1 == HeaderInfo || "CSCI_TEXTLOAD: HeaderInfo should be \"\"TOA5\",\"CR1000 - IP\",\"CR1000\",\"E2948\",\"CR1000.Std.22\",\"CPU:LoggerCode.CR1\",\"35271\",\"Rotronics_HC2S3\"\r\n\""
@test h2 == HeaderColumns || "CSCI_TEXTLOAD: HeaderColumns should be \"\"TIMESTAMP\",\"RECORD\",\"AirTemp_HC2S3_S01\",\"RelHum_HC2S3_S01\",\"AirTemp_HC2S3_S02\",\"RelHum_HC2S3_S02\",\"AirTemp_HC2S3_S03\",\"RelHum_HC2S3_S03\",\"AirTemp_HC2S3_S04\",\"RelHum_HC2S3_S04\"\r\n\""
@test h3 == HeaderUnits || "CSCI_TEXTLOAD: HeaderUnits should be \"\"TS\",\"RN\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\",\"Deg C\",\"%\"\r\n\""
@test h4 == HeaderSample || "CSCI_TEXTLOAD: HeaderSample should be \"\"\",\"\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\",\"Smp\"\r\n\""



src = splitdir(@__FILE__)[1]
rootname = "CampbellScientific"
Data = ClimateDataIO.csci_textload(src,rootname,DateTime(2016,12),DateTime(2017,1))
@test Data[:Timestamp][1] == DateTime(2016,12,1,0,0,0) || "CSCI_TEXTREAD: Data[:Timestamp] first timestamp should be 2016-12-01T00:00:00"
@test Data[:Timestamp][end] == DateTime(2016,12,4,23,59,30) || "CSCI_TEXTREAD: Data[:Timestamp] last timestamp should be 2016-12-04T23:59:30"
@test size(Data) == (11520,10) || "CSCI_TEXTLOAD: Data output size incorrect, should be (11520,10)"



println("\n===  CSCI_TIMES  ===")
src = joinpath(src,"CampbellScientific_HC2S3_20161201-000000.dat")
srcs = [src,src]
mintime = DateTime(2016,12,1)
maxtime = DateTime(2016,12,4,23,59,30)
mintimes, maxtimes = ClimateDataIO.csci_times(srcs,headerlines=4)
@test [mintime;mintime] == mintimes || "CSCI_TIME: Both minimum time values should be 2016-12-01T00:00:00"
@test [maxtime;maxtime] == maxtimes || "CSCI_TIME: Both maximum time values should be 2016-12-04T23:59:30"



# GHGREAD: Load one file
println("\n====  GHGREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"2016-12-11T203000_AIU-1359.ghg")
Time,Data = ClimateDataIO.ghg_read(src,verbose=true)
@test Time[1] == DateTime(2016,12,11,20,30,0) || "GHGREAD: Time[1] first timestamp should be 2016-12-11T20:30:00"
@test Time[end] == DateTime(2016,12,11,20,59,59,950) || "GHGREAD: Time[end] last timestamp should be 2016-12-04T20:59:59.95"
@test size(Data) == (36000,48) || "GHGREAD: Data output size incorrect, should be (36000,48)"



# GHGLOAD: Load one file
println("\n====  GHGLOAD Tests  ====")
src = splitdir(@__FILE__)[1]
Time,Data = ClimateDataIO.ghg_load(src,verbose=true,average=false)
@test Time[1] == DateTime(2016,12,11,20,0,0) || "GHGLOAD: Time[1] first timestamp should be 2016-12-11T20:00:00"
@test Time[end] == DateTime(2016,12,11,21,59,59,950) || "GHGLOAD: Time[end] last timestamp should be 2016-12-04T21:59:59.95"
@test size(Data) == (144000,48) || "GHGLOAD: Data output size incorrect, should be (144000,48)"



Time,Data = ClimateDataIO.ghg_load(src,verbose=true,average=true)
@test Time[1] == DateTime(2016,12,11,20,0,0) || "GHGLOAD: Time[1] first timestamp should be 2016-12-11T20:00:00"
@test Time[end] == DateTime(2016,12,11,21,30) || "GHGLOAD: Time[end] last timestamp should be 2016-12-04T21:30:00"
@test size(Data) == (4,39) || "GHGLOAD: Data output size incorrect, should be (4,39)"



# GHGLOAD: Load one file
println("\n====  LGR_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
Time,Data, Cols = ClimateDataIO.lgr_load(src,verbose=true)
@test Time[1] == DateTime(2015,1,30,15,13,47,994) || "LGR_LOAD: Time[1] first timestamp should be 2015-01-30T15:13:47.994"
@test Time[end] == DateTime(2015,1,31,15,13,55,727) || "LGR_LOAD: Time[end] last timestamp should be 2015-01-31T15:13:55.727"
@test size(Data) == (78272,23) || "LGR_LOAD: Data output size incorrect, should be (78272,23)"



# LGR_READ Error Check
err = true
try
	Time,Data,Cols = ClimateDataIO.lgr_read("blahblahblah")
	err = false
end
@test err == true || "LGR_READ: Should throw an error, invalid file given"



# LICOR_SPLIT
println("\n====  LICOR_SPLIT Tests  ====")
src = splitdir(@__FILE__)[1]
dest = joinpath(src,"temporary_files")
F1 = joinpath(src,"2016-12-11T213000_AIU-1359.ghg")
F2 = joinpath(dest,"2016-12-11T213000_AIU-1359.data")
F3 = joinpath(dest,"2016-12-11T213000.txt")
temp = readstring(`unzip -d $dest $F1`)

# Prepare File
println("\nGenerating test file...")
epoch = DateTime(1970) + Dates.Hour(1)

# Copy the old file
cp(F2,F3)

# Add Data
fid = open(F2,"r")
fid2 = open(F3,"a")
l = []
t = []
ft = findin(l,"\t")
s = []
for i=1:1:8
    # Skip Header
    l = readline(fid)
end
p = position(fid) # File position
for j=1:1:4 # 20 for another eight hours
    seek(fid,p) # Reset file position
    while !eof(fid)
        l = readline(fid)
        ft = findin(l,"\t")
        fsec = findfirst(l[6:end],'\t')+5 # Location of second column
        fmsec = findfirst(l[fsec+1:end],'\t')+fsec # Location of nanosecond column
        t = epoch + Dates.Second(parse(l[ft[1]+1:ft[2]])) + Dates.Millisecond(round(parse(Float64,l[ft[2]+1:ft[3]])/10^6))
        t = t + Dates.Second(1800*j)
        l = l[1:5] * string(parse(Int,l[ft[1]+1:ft[2]]) + 1800*j) * l[ft[2]:ft[6]] * Dates.format(t,"yyyy-mm-dd\tHH:MM:SS:sss") * l[ft[8]:end]
        write(fid2,l)
    end
end
close(fid)
close(fid2)
rm(joinpath(dest,"2016-12-11T213000_AIU-1359.data"))
rm(joinpath(dest,"2016-12-11T213000_AIU-1359.metadata"))

println("\nSplitting test file...")
ClimateDataIO.licor_split(dest,dest)
rm(joinpath(dest,"2016-12-11T213000.txt"))

println("\nLoading Split Files...")
Time,Data = ClimateDataIO.ghg_load(dest,DateTime(2016,12,11,21,30),average=false,verbose=false)
rm(joinpath(dest,"2016-12-11T213000_AIU-1359.ghg"))
#rm(joinpath(dest,"2016-12-12T000000_AIU-1359.ghg"))
#rm(joinpath(dest,"2016-12-12T040000_AIU-1359.ghg"))
@test Time[1] == DateTime(2016,12,11,21,30) || "LICOR_SPLIT: Time[1] first timestamp should be 2016-12-11T21:30:00"
@test Time[end] == DateTime(2016,12,11,23,59,59,950) || "LICOR_SPLIT: Time[end] last timestamp should be 2016-12-11T23:59:59.95"
@test size(Data) == (180000,48) || "LGR_SPLIT: Data output size incorrect, should be (180000,48)"

println("\n\nAll Tests Complete Successfully")
