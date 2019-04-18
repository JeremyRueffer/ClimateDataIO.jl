# slt_header.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 18.04.2019

"""# slt_header

Load an SLT header

`slt_header(f,AnalogIn,freq)`\n
* **f**::String = File name
* **AnalogIn**::Int = Number of analog signals
* **freq**::Number or String = Sample frequency"""
function slt_header(f::String,AnalogIn::Int,freq::String)
	return slt_header(f,AnalogIn,parse(Float64,freq))
end # slt_header(f::String,AnalogIn::Int,freq::String)

function slt_header(f::String,AnalogIn::Int,freq::Number)
	# Prepare Output Variables
	bpr = Int # Bytes Per Record
	eddymeasver = [] # Eddy Meas Version
	t0 = DateTime # Initial Timestamp
	ch = [] # Channels
	bm = [] # Bit Masks
	l = [] # Number of Rows of Data
	stpos = [] # Starting Position of Data
	
	fid = open(f,"r")
	try
		# Header
		bpr = Int(read!(fid,Array{Int8}(undef,1))[1]) # Bytes Per Record
		eddymeasver = read!(fid,Array{Int8}(undef,1))
		dom = Int(read!(fid,Array{Int8}(undef,1))[1]) # Day of Month
		m = Int(read!(fid,Array{Int8}(undef,1))[1]) # Month number
		yr = 100*Int(read!(fid,Array{Int8}(undef,1))[1]) + Int(read!(fid,Array{Int8}(undef,1))[1]) # Year
		h = Int(read!(fid,Array{Int8}(undef,1))[1]) # Hour
		minut = Int(read!(fid,Array{Int8}(undef,1))[1]) # Minute
		t0 = DateTime(yr,m,dom,h,minut,0) # Initial file time
		
		fs = stat(f).size # File size in bytes
		l = (fs - 8 - 2*AnalogIn)/bpr # Number of rows of data
		
		# Bit Masks and Channels
		bm = read!(fid,Array{Int8}(undef,2*AnalogIn))
		ch = bm[2:2:end] # Channels
		bm = bm[1:2:end] # Bit masks
		
		stpos = position(fid) # Position of the first data point
	catch
		println("Error loading file: " * f)
	end
	close(fid)
	
	# Format Output
	output = DataFrame(FileName = f,T0 = t0,Line_Count = l,Start_Pos = stpos,Channels = collect(Array[ch]),Bit_Mask = collect(Array[bm]),EddyMeas_Version = eddymeasver,BytesPerRecord = bpr)
	
	return output
end # slt_header(f::String,AnalogIn::Int,freq::Number)
