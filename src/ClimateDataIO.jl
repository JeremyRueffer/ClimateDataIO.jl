# ClimateDataIO.jl
#
#   Module for loading typical data file formats found in soil and atmospheric
#	sciences
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.9.3
# 09.12.2016
# Last Edit: 20.09.2023

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

`LI7200Diagnostic`: Parse LI-7200 diagnostic values

---

#### Requirements
* CSV
* Crayons.Box
* DataFrames
* Dates
* DelimitedFiles
* Printf
* Statistics
* StatsBase
* Test"""
module ClimateDataIO

using Crayons.Box
using CSV
using DataFrames
using Dates
using DelimitedFiles
using Printf
using Statistics
using StatsBase
using Test

import Base.show

export AerodyneStatus,
    csci_textload,
    csci_textread,
    csci_times,
    ghg_load,
    ghg_pack,
    ghg_read,
    LI7200Diagnostic,
    licor_split,
    lgr_load,
    lgr_read,
    show,
    slt_config,
    slt_header,
    slt_load,
    slt_read,
    slt_timeshift,
    slt_write,
    slt_trim,
    stc_load,
    str_load

dir = splitdir(@__FILE__)[1]
include(joinpath(dir, "aerodyne_parsetime.jl"))
include(joinpath(dir, "AerodyneStatus.jl"))
include(joinpath(dir, "csci_textload.jl"))
include(joinpath(dir, "csci_textread.jl"))
include(joinpath(dir, "csci_times.jl"))
include(joinpath(dir, "dirlist.jl"))
include(joinpath(dir, "findnewton.jl"))
include(joinpath(dir, "ghg_load.jl"))
include(joinpath(dir, "ghg_pack.jl"))
include(joinpath(dir, "ghg_read.jl"))
include(joinpath(dir, "lgr_load.jl"))
include(joinpath(dir, "lgr_read.jl"))
include(joinpath(dir, "LI7200Diagnostic.jl"))
include(joinpath(dir, "licor_split.jl"))
include(joinpath(dir, "str_load.jl"))
include(joinpath(dir, "stc_load.jl"))
include(joinpath(dir, "slt_read.jl"))
include(joinpath(dir, "slt_load.jl"))
include(joinpath(dir, "slt_header.jl"))
include(joinpath(dir, "slt_config.jl"))
include(joinpath(dir, "slt_configload.jl"))
include(joinpath(dir, "slt_timeshift.jl"))
include(joinpath(dir, "slt_write.jl"))
include(joinpath(dir, "slt_trim.jl"))
include(joinpath(dir, "ziptextfiles.jl"))

# Define 7zip location constant
if Sys.iswindows() & (VERSION >= VersionNumber("1.9"))
	const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "libexec", "julia", "7z.exe")
elseif Sys.iswindows() & (VersionNumber("1.9") > VERSION >= VersionNumber("1.3.0"))
    const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "libexec", "7z.exe")
elseif Sys.iswindows() & (VERSION < VersionNumber("1.3.0"))
    const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "7z.exe")
elseif Sys.isunix() & (VERSION >= VersionNumber("1.9"))
    const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "libexec", "julia", "7z")
elseif Sys.isunix() & (VersionNumber("1.9") > VERSION >= VersionNumber("1.3.0"))
    const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "libexec", "7z")
elseif Sys.isunix() & (VERSION < VersionNumber("1.3.0"))
    const exe7z = joinpath(splitdir(Sys.BINDIR)[1], "7z")
end
end # End of module
