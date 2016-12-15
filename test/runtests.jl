using ClimateDataIO
using Base.Test

# SLTLOAD: Check a known set of data
println("\n====  SLTLOAD  ====")
src = splitdir(@__FILE__)[1]
mindate = DateTime(2016,11,23,14,4)
maxdate = DateTime(2016,11,23,18)
Data = ClimateDataIO.sltload(src,mindate,maxdate,verbose=true)

@test size(Data) == (141377,13) || "SLTLOAD: Output size incorrect, should be (141377,13)"

@test Data[:Time][1] == DateTime(2016,11,23,14,4) || "SLTLOAD: First timestamp should be 2016-11-23T14:04:00"

@test Data[:Time][end] == DateTime(2016,11,23,17,59,59,900) || "SLTLOAD: Last timestamp should be 2016-11-23T17:59:59.9"



# SLTREAD: Load one known file
println("\n====  SLTREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"W20163281000.slt")
analog_inputs = 6 # Number of analog inputs
sample_frequency = 10 # Hz
Time,Data = ClimateDataIO.sltread(src,analog_inputs,sample_frequency)

@test size(Data) == (18003,10) || "SLTREAD: Output size incorrect, should be (18003,10)"

@test Time[1] == DateTime(2016,11,23,10) || "SLTREAD: First timestamp should be 2016-11-23T10:00:00"

@test Time[end] == DateTime(2016,11,23,10,30,00,200) || "SLTREAD: Last timestamp should be 2016-11-23T10:30:00.2"



# AERODYNE_LOAD: Load one file
println("\n====  AERODYNE_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"161210_000000.str")
Time,Data = ClimateDataIO.aerodyne_load(src,verbose=true)

@test Time[1] == DateTime(2016,12,10,0,0,0,622) || "AERODYNE_LOAD: First timestamp should be 2016-12-10T00:00:00.622"

@test Time[end] == DateTime(2016,12,10,0,59,59,922) || "AERODYNE_LOAD: Last timestamp should be 2016-12-10T00:59:59.922"

@test size(Data) == (35159,2) || "AERODYNE_LOAD: Output size incorrect, should be (35159,2)"



# AERODYNE_LOAD: Load all file
println("\n====  AERODYNE_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
TimeStr,DataStr,TimeStc,DataStc = ClimateDataIO.aerodyne_load(src,verbose=true)

@test TimeStr[1] == DateTime(2016,12,10,0,0,0,622) || "AERODYNE_LOAD: TimeStr first timestamp should be 2016-12-10T00:00:00.622"

@test TimeStr[end] == DateTime(2016,12,10,3,59,59,917) || "AERODYNE_LOAD: TimeStr last timestamp should be 2016-12-10T03:59:59.917"

@test size(DataStr) == (140641,2) || "AERODYNE_LOAD: DataStr output size incorrect, should be (140641,2)"

@test TimeStc[1] == DateTime(2016,12,10,0,0,2,622) || "AERODYNE_LOAD: TimeStc first timestamp should be 2016-12-10T00:00:02.622"

@test TimeStc[end] == DateTime(2016,12,10,3,59,59,117) || "AERODYNE_LOAD: TimeStc last timestamp should be 2016-12-10T03:59:59.117"

@test size(DataStc) == (14391,26) || "AERODYNE_LOAD: DataStc output size incorrect, should be (14391,26)"



# CSCI_TEXTREAD: Load one file
println("\n====  CSCI_TEXTREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"CampbellScientific_HC2S3.dat")
Data = ClimateDataIO.csci_textread(src,verbose=true)

@test Data[:Timestamp][1] == DateTime(2016,12,1,0,0,0) || "CSCI_TEXTREAD: Data[:Timestamp] first timestamp should be 2016-12-01T00:00:00"

@test Data[:Timestamp][end] == DateTime(2016,12,4,23,59,30) || "CSCI_TEXTREAD: Data[:Timestamp] last timestamp should be 2016-12-04T23:59:30"

@test size(Data) == (11520,10) || "CSCI_TEXTREAD: Data output size incorrect, should be (11520,10)"



# GHGREAD: Load one file
println("\n====  GHGREAD Tests  ====")
src = splitdir(@__FILE__)[1]
src = joinpath(src,"2016-12-11T203000_AIU-1359.ghg")
Time,Data = ClimateDataIO.ghgread(src,verbose=true)

@test Time[1] == DateTime(2016,12,11,20,30,0) || "GHGREAD: Time[1] first timestamp should be 2016-12-11T20:30:00"

@test Time[end] == DateTime(2016,12,11,20,59,59,950) || "GHGREAD: Time[end] last timestamp should be 2016-12-04T20:59:59.95"

@test size(Data) == (36000,48) || "GHGREAD: Data output size incorrect, should be (36000,48)"



# GHGLOAD: Load one file
println("\n====  GHGLOAD Tests  ====")
src = splitdir(@__FILE__)[1]
Time,Data = ClimateDataIO.ghgload(src,verbose=true,average=false)

@test Time[1] == DateTime(2016,12,11,20,0,0) || "GHGLOAD: Time[1] first timestamp should be 2016-12-11T20:00:00"

@test Time[end] == DateTime(2016,12,11,21,59,59,950) || "GHGLOAD: Time[end] last timestamp should be 2016-12-04T21:59:59.95"

@test size(Data) == (144000,48) || "GHGLOAD: Data output size incorrect, should be (144000,48)"



# GHGLOAD: Load one file
println("\n====  LGR_LOAD Tests  ====")
src = splitdir(@__FILE__)[1]
Time,Data, Cols = ClimateDataIO.lgr_load(src)

@test Time[1] == DateTime(2015,1,30,15,13,47,994) || "LGR_LOAD: Time[1] first timestamp should be 2015-01-30T15:13:47.994"

@test Time[end] == DateTime(2015,1,31,15,13,55,727) || "LGR_LOAD: Time[end] last timestamp should be 2015-01-31T15:13:55.727"

@test size(Data) == (78272,23) || "LGR_LOAD: Data output size incorrect, should be (78272,23)"



println("All Tests Complete Successfully")
