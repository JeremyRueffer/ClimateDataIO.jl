# ghg_pack.jl
#
#   Pack .data and .metadata files which weren't packed into GHG files
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.7.0
# 09.11.2018
# Last Edit: 07.01.2022

"""# ghg_pack.jl

Pack all files that belong in GHG files into a new GHG file. Files are zipped to the same directory given. If a corresponding GHG file already exists it will do nothing.

---

### Example

`ghg_pack(\"K:\\\\Data\\\\GHG_Files\")`

---

`ghg_pack(source)` # Zips files into GHG files in the same directory\n
* **source**::String = Source directory to search

---

`ghg_pack(source,destination)` # Zips files into GHG files in another directory\n
* **source**::String = Source directory to search
* **destination**::String = Destination for GHG files

---

`ghg_pack(source,destination,moveDest)` # Zips files into GHG files in the another directory and move the source files\n
* **source**::String = Source directory to search
* **destination**::String = Destination for GHG files
* **moveDestination**::String = Destination for sources files after they are zipped
"""
function ghg_pack(src::String, dest::String = ""; moveDest = "")
    # Directory checks
    isdir(src) ? nothing : error(src * " does not exist.")
    if dest == ""
        dest = src
    end
    isdir(dest) ? nothing : error(dest * " does not exist.")
    if !isempty(moveDest)
        isdir(moveDest) ? nothing : error(moveDest * " does not exist.")
    end

    # Constants
    #regStr = r"\d{4}-\d{2}-\d{2}T\d{6}_AIU-\d{4}\.data"
    regStr = r"\d{4}-\d{2}-\d{2}T\d{6}_AIU-\d{4}(-biomet)?\.data"

    # List Files
    files, temp = dirlist(src, regex = regStr)
    files = unique(baseFileName.(files)) # Remove file extensions and "-biomet"

    # Zip Each Set
    if Threads.nthreads() > 1
        println("Starting " * string(Threads.nthreads()) * " simultaneous threads for " * string(length(files)) * " files")
    end
    Threads.@threads for i in files
        d, file = splitdir(i) # directory and file names
        ghg = joinpath(dest, file * ".ghg")

        # Check for existing GHG file
        if isfile(ghg)
            # This GHG file already exists, skip to the next one
            continue
        end

        # Create a new GHG archive
        println("\t" * ghg)
        zlist = [joinpath(d, file * ".data"),
            joinpath(d, file * "-biomet.data"),
            joinpath(d, file * ".metadata"),
            joinpath(d, file * "-biomet.metadata")] # List of files to zip
        ziptextfiles(ghg, zlist[isfile.(zlist)]) # Add all existing files to a GHG file

        # Move Zipped source files
        if !isempty(moveDest)
            for i in zlist[isfile.(zlist)]
                mv(i, joinpath(moveDest, basename(i)))
            end
        end
    end
end

function baseFileName(file::String)
    if length(basename(file)) == 38
        return file[1:end-12] # Remove "-biomet.data"
    else
        return file[1:end-5] # Remove ".data"
    end
end