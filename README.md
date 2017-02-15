# ClimateDataIO

[![Build Status](https://travis-ci.org/JeremyRueffer/ClimateDataIO.jl.svg?branch=master)](https://travis-ci.org/JeremyRueffer/ClimateDataIO.jl)
[![Coverage Status](https://coveralls.io/repos/github/JeremyRueffer/ClimateDataIO.jl/badge.svg?branch=master)](https://coveralls.io/github/JeremyRueffer/ClimateDataIO.jl?branch=master)
[![codecov.io](http://codecov.io/github/JeremyRueffer/ClimateDataIO.jl/coverage.svg?branch=master)](http://codecov.io/github/JeremyRueffer/ClimateDataIO.jl?branch=master)

The purpose of ClimateDataIO is not purely to load individual files but to do other basic tasks involving the data. A LOAD function will work on multiple files and can load files based on a time span. In all cases the timestamps are also generated (SLT files only) or parsed. A few functions exist to correct problems with the data (SLTTRIM, SLTTIMESHIFT, SLTWRITE, LICOR_SPLIT).

This is a work in progress. The functions are fully functional but their names will probably change as things are standardized. Once that is complete this package will then be registered so it can be imported with `Pkg.add("ClimateDataIO")`. After it has been registered, basic reading components will be added to [FileIO](https://github.com/JuliaIO/FileIO.jl) whenever reasonably possible.

Until the 1.0.0 release anyone that wishes to use this will have to install this package by typing `Pkg.clone("git://github.com/JeremyRueffer/ClimateDataIO.jl.git")` into the Julia REPL. Updates are done by typing `Pkg.checkout("ClimateDataIO")`.

## Aerodyne

Both STR and STC files are simple column-separated ASCII text files. STC files have two header lines whereas the STR have only one.

### STR Header
```
12/10/2016 00:00:00 0.004 3564172800.000 23:00:00 SPEC:NH3
```

### STC Header
```
12/10/2016 00:00:00 0.004 3564172800.000 23:00:00 SPEC:NH3
time, Range_F 1_L 1, Zero_F 1, Range_F 2_L 1, Zero_F 2, Praw, Traw, AD2, Tref, AD6, AD7, StatusW, ValveW, VICI_W, USBByte, NI6024Byte, SPEFile, T Laser 1, V Laser 1, LW Laser 1,  dT1,  X1,  pos1,  ConvergenceWord,  ChillerT,  CV1_Volts
```

The timestamps are seconds from January 1, 1904.


```julia
epoch = DateTime(1904)
Traw = 3564187199.917300
T = epoch + Dates.Second(floor(Traw)) + Dates.Millisecond(floor(1000(Traw - floor(Traw))))
```

## Campbell Scientific

DAT files are simple comma-separated ASCII text files with four header lines.

### TOA5 Header
```
"TOA5","CR1000 - IP","CR1000","E2948","CR1000.Std.22","CPU:LoggerCode.CR1","35271","Rotronics_HC2S3"
"TIMESTAMP","RECORD","AirTemp_HC2S3_S01","RelHum_HC2S3_S01","AirTemp_HC2S3_S02","RelHum_HC2S3_S02","AirTemp_HC2S3_S03","RelHum_HC2S3_S03","AirTemp_HC2S3_S04","RelHum_HC2S3_S04"
"TS","RN","Deg C","%","Deg C","%","Deg C","%","Deg C","%"
"","","Smp","Smp","Smp","Smp","Smp","Smp","Smp","Smp"
```
The first line contains format (TOA5), logger, and logger code information. The remaining three lines relate to each column. The second line is the list of column names followed by the column units, and finally how they were collected. "Smp" means sample and "Avg" means average.

Timestamps are full text dates and times.

```julia
Traw = "2016-12-01 00:00:00"
fmt = Dates.DateFormat("yyyy-mm-dd HH:MM:SS")
T = DateTime(Traw,fmt)
```

## EddyMeas

SLT files are binary but all other related files are ASCII text. All other files contain metadata and processed data from the SLT files. For more information see page 15 of the [EddySoft](https://www.bgc-jena.mpg.de/Freiland/index.php/Sofware/Software) manual.

| File | Purpose |
| ---- | ------- |
| SLT | Data |
| CFG | Instrument settings |
| LOG | Log information |
| FLX | ? |
| CSU | ? |
| CSR | ? |
| CSV | ? |

Timestamps for SLT data are generated based on the initial timestamp found in the file header and the sample frequency assuming consistent timing, `To + n*(1/F) - (1/F)` where `To` is the initial time, `F` is the sample frequency (Hz), and `n` is the sample number.

## Licor

GHG files are ZIP archives of ASCII text files, normally one tab-separated DATA file and one METADATA settings file. Each DATA file has eight header lines, the last of which is a list of column names.

### DATA Header
```
Model:	LI-7200 Enclosed CO2/H2O Analyzer
SN:	72H-0616
Instrument:	AIU-1359
File Type:	2
Software Version:	8.0.0
Timestamp:	22:00:00
Timezone:	Europe/Berlin
DATAH	Seconds	Nanoseconds	Sequence Number	Diagnostic Value	Diagnostic Value 2	Date	Time	CO2 Absorptance	H2O Absorptance	CO2 (mmol/m^3)	CO2 (mg/m^3)	H2O (mmol/m^3)	H2O (g/m^3)	Block Temperature (C)	Total Pressure (kPa)	Box Pressure (kPa)	Head Pressure (kPa)	Aux 1 - U (m/s)	Aux 2 - V (m/s)	Aux 3 - W (m/s)	Aux 4 - SOS (m/s)	Cooler Voltage (V)	Vin SmartFlux (V)	CO2 (umol/mol)	CO2 dry(umol/mol)	H2O (mmol/mol)	H2O dry(mmol/mol)	Dew Point (C)	Cell Temperature (C)	Temperature In (C)	Temperature Out (C)	Average Signal Strength	CO2 Signal Strength	H2O Signal Strength	Delta Signal Strength	Flow Rate (slpm)	Flow Rate (lpm)	Flow Pressure (kPa)	Flow Power (V)	Flow Drive (%)	H2O Sample	H2O Reference	CO2 Sample	CO2 Reference	HIT Power (W)	Vin HIT (V)	CHK
```

DATA files have two options for a timestamp. The second and third columns are seconds and nanoseconds. Adding both to the January 1, 1970 01:00 epoch will return the correct date and time.

```julia
epoch = DateTime(1970,1,1,1)
s = 1481490002 # Seconds
ns = 550000000 # Nanoseconds
T = epoch + Dates.Second(s) + Dates.Millisecond(ns/1e6)
# 2016-12-11T22:00:02.05
```

The second option are columns seven and eight, date and time.

```julia
datestring = "2016-12-11"
timestring = "22:00:02:500"
fmt = Dates.DateFormat("yyyy-mm-ddHH:MM:SS:sss")
T = DateTime(datestring * timestring,fmt)
# 2016-12-11T22:00:02.5
```

## Los Gatos Research

The TXT files generated by the LGR instruments are simple fixed-width comma-separated ASCII text files with two header lines.

### Header
```
VC:904M BD:May 23 2013 SN:LGR-13-0171
                     Time,      [CH4]_ppm,   [CH4]_ppm_sd,      [H2O]_ppm,   [H2O]_ppm_sd,      [CO2]_ppm,   [CO2]_ppm_sd,     [CH4]d_ppm,  [CH4]d_ppm_sd,     [CO2]d_ppm,  [CO2]d_ppm_sd,      GasP_torr,   GasP_torr_sd,         GasT_C,      GasT_C_sd,         AmbT_C,      AmbT_C_sd,         RD0_us,      RD0_us_sd,         RD1_us,      RD1_us_sd,       Fit_Flag,            MIU
```

Timestamps are full text dates and times.

```julia
Traw = "30/01/2015 15:13:47.994"
fmt = Dates.DateFormat("dd/mm/yyyy HH:MM:SS.sss")
T = DateTime(Traw,fmt)
```
