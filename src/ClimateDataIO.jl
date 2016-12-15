# ClimateDataIO.jl
#
#   Module for loading typical data file formats found in soil and atmospheric
#	sciences
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.5.0
# 09.12.2016
# Last Edit: 15.12.2016

__precompile__(true)

"""# ClimateDataIO

Tools for loading various file types common to soil, atmosphereic, and climate sciences. This includes SLT files from EddyMeas, Aerodyne QCL data, CampbellScientific TOA5 DAT files, Los Gatos Research data files, and Licor GHG files.

`aerodyne_load`: Load STR and STC files

`AerodyneStatus`: Convert the StatusW column in STC files into boolean values

`ghgload`: Load Licor GHG files

`ghgread`: Load a Licor GHG file

`sltload`: Load SLT files based on dates

`sltheader`: Load SLT header info

`sltread`: Read SLT file converting everything except mV signals

`sltconfig`: Load SLT configuration data files (CFG)

`slttimeshift`: Shift a set of SLT files' time

`sltwrite`: Write data to an SLT file

`slttrim`: Remove columns from SLT files

`csci_textload`: Load CampbellScientific text DAT files

`csci_textread`: Load a CampbellScientific text DAT files

`lgr_load`: Load  Los Gatos Research (LGR) text data files

`lgr_read`: Load a Los Gatos Research (LGR) text data file

`licor_split`: Split Licor text data files into smaller compressed GHG files

For more information see each function's help.

---

#### Requirements
* DataFrames
* ZipFiles (only for licor_split and ghgread)"""
module ClimateDataIO

	using DataFrames
	using ZipFile # Only needed for ziptextfiles.jl (licor_split.jl)
	
	export aerodyne_load,
		AerodyneStatus,
		ghgload,
		ghgread,
		sltread,
		sltload,
		sltheader,
		sltconfig,
		slttimeshift,
		sltwrite,
		slttrim,
		csci_textload,
		csci_textread,
		lgr_load,
		lgr_read,
		licor_split
	
	dir = splitdir(@__FILE__)[1]
	include(joinpath(dir,"aerodyne_load.jl"))
	include(joinpath(dir,"aerodyne_parsetime.jl"))
	include(joinpath(dir,"AerodyneStatus.jl"))
	include(joinpath(dir,"ghgload.jl"))
	include(joinpath(dir,"ghgread.jl"))
	include(joinpath(dir,"sltread.jl"))
	include(joinpath(dir,"sltload.jl"))
	include(joinpath(dir,"sltheader.jl"))
	include(joinpath(dir,"sltconfig.jl"))
	include(joinpath(dir,"sltconfig_load.jl"))
	include(joinpath(dir,"slttimeshift.jl"))
	include(joinpath(dir,"sltwrite.jl"))
	include(joinpath(dir,"slttrim.jl"))
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
