# ClimateDataIO.jl
#
#   Module for loading typical data file formats found in soil and atmospheric
#	sciences
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.2.0
# 09.12.2016
# Last Edit: 21.08.2019

__precompile__(true)

"""# ClimateDataIO

Tools for loading various file types common to soil, atmospheric, and climate sciences. This includes SLT files from EddyMeas, Aerodyne QCL data, CampbellScientific TOA5 DAT files, Los Gatos Research data files, and Licor GHG files.

For more specific information see each functions' help.

---

### Aerodyne QCL Files
`AerodyneStatus`: Convert the StatusW column in STC files into boolean values

`str_load`: Load Aerodyne STR files

`stc_load`: Load Aerodyne STC files

### Campbell Scientific Text DAT Files
`csci_textload`: Load CampbellScientific text DAT files

`csci_textread`: Load a CampbellScientific text DAT files

`csci_times`: Load the minimum and maximum dates and times in the listed files

### EddyMeas SLT Files
`slt_load`: Load SLT files

`slt_header`: Load SLT header info

`slt_read`: Read SLT file converting everything except mV signals

`slt_config`: Load SLT configuration data files (CFG)

`slt_timeshift`: Shift a set of SLT files' time

`slt_write`: Write data to an SLT file

`slt_trim`: Remove columns from SLT files

### LGR Laser Data
`lgr_load`: Load  Los Gatos Research (LGR) text data files

`lgr_read`: Load a Los Gatos Research (LGR) text data file

### Licor GHG Files
`ghg_load`: Load Licor GHG files

`ghg_read`: Load a Licor GHG file

`licor_split`: Split Licor text data files into smaller compressed GHG files

---

#### Requirements
* CSV
* DataFrames
* Dates
* DelimitedFiles
* Printf
* Statistics
* StatsBase
* Test
* ZipFiles (only for licor`_`split and ghg`_`read)"""
module ClimateDataIO

	using DataFrames
	using Dates
	using Printf
	using DelimitedFiles
	using StatsBase
	using ZipFile # Used in ghg_read (and therefore ghg_load) and licor_split
	using CSV
	using Statistics
	using Test
	
	export AerodyneStatus,
		str_load,
		stc_load,
		slt_read,
		slt_load,
		slt_header,
		slt_config,
		slt_timeshift,
		slt_write,
		slt_trim,
		csci_textload,
		csci_textread,
		csci_times,
		lgr_load,
		lgr_read,
		ghg_load,
		ghg_read,
		licor_split
	
	dir = splitdir(@__FILE__)[1]
	include(joinpath(dir,"aerodyne_parsetime.jl"))
	include(joinpath(dir,"AerodyneStatus.jl"))
	include(joinpath(dir,"ghg_load.jl"))
	include(joinpath(dir,"ghg_read.jl"))
	include(joinpath(dir,"str_load.jl"))
	include(joinpath(dir,"stc_load.jl"))
	include(joinpath(dir,"slt_read.jl"))
	include(joinpath(dir,"slt_load.jl"))
	include(joinpath(dir,"slt_header.jl"))
	include(joinpath(dir,"slt_config.jl"))
	include(joinpath(dir,"slt_configload.jl"))
	include(joinpath(dir,"slt_timeshift.jl"))
	include(joinpath(dir,"slt_write.jl"))
	include(joinpath(dir,"slt_trim.jl"))
	include(joinpath(dir,"dirlist.jl"))
	include(joinpath(dir,"findnewton.jl"))
	include(joinpath(dir,"csci_textload.jl"))
	include(joinpath(dir,"csci_textread.jl"))
	include(joinpath(dir,"csci_times.jl"))
	include(joinpath(dir,"lgr_load.jl"))
	include(joinpath(dir,"lgr_read.jl"))
	include(joinpath(dir,"licor_split.jl"))
	include(joinpath(dir,"ziptextfiles.jl"))
end
