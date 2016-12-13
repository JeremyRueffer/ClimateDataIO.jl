using ClimateDataIO
using Base.Test

# SLTLOAD: Check a known set of data
src = splitdir(@__FILE__)[1]
mindate = DateTime(2016,11,23,14,4)
maxdate = DateTime(2016,11,23,18)
Data = ClimateDataIO.sltload(src,mindate,maxdate)

@test size(Data) == (141377,13) || "Output size incorrect, should be (141377,13)"

@test Data[:Time][1] == DateTime(2016,11,23,14,4) || "First timestamp should be 2016-11-23T14:04:00"

@test Data[:Time][end] == DateTime(2016,11,23,17,59,59,900) || "Last timestamp should be 2016-11-23T17:59:59.9"

# SLTREAD: Load one known file
src = splitdir(@__FILE__)[1]
src = joinpath(src,"W20163281000.slt")
analog_inputs = 6 # Number of analog inputs
sample_frequency = 10 # Hz
Time,Data = sltread(src,analog_inputs,sample_frequency)

@test size(Data) == (18003,10) || "Output size incorrect, should be (18003,10)"

@test Time[1] == DateTime(2016,11,23,10) || "First timestamp should be 2016-11-23T10:00:00"

@test Time[end] == DateTime(2016,11,23,10,30,00,200) || "Last timestamp should be 2016-11-23T10:30:00.2"
