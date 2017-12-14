# aerodyne_status.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.6.1
# 13.12.2016
# Last Edit: 13.12.2017

"""# AerodyneStatus

Parse the StatusW column in an STC file into this custom type

---

### Example

`statuses = AerodyneStatus(Dstc[:StatusW])`\n
`statuses.Valve3` # Show statuses for valve 3

---

#### Fields (all contain boolean values)\n
* **AutoBG** - Automatic Background
* **AutoCal** - Automatic Calibration
* **FrequencyLock**
* **BinomialFilter**
* **AltMode** - Alternative Mode
* **GuessLast** - First guess is last guess from previous curve fit
* **PowerNorm** - Power Normalization
* **ContRefLock** - Continuous Reference Lock
* **AutoSpectSave** - Automatic Spectrum Save
* **PressureLock**
* **WriteData**
* **RS232** - RS232 output active/inactive
* **ElectronicBGSub** - Subtract electronic background noise
* **Valve 1** - Active/inactive
* **Valve 2** - Active/inactive
* **Valve 3** - Active/inactive
* **Valve 4** - Active/inactive
* **Valve 5** - Active/inactive
* **Valve 6** - Active/inactive
* **Valve 7** - Active/inactive
* **Valve 8** - Active/inactive
"""
type AerodyneStatus
	AutoBG::Vector{Bool}
	AutoCal::Vector{Bool}
	FrequencyLock::Vector{Bool}
	BinomialFilter::Vector{Bool}
	AltMode::Vector{Bool}
	GuessLast::Vector{Bool}
	PowerNorm::Vector{Bool}
	ContRefLock::Vector{Bool}
	
	AutoSpectSave::Vector{Bool}
	PressureLock::Vector{Bool}
	#b11::Vector{Bool}
	#b12::Vector{Bool}
	WriteData::Vector{Bool}
	RS232::Vector{Bool}
	ElectronicBGSub::Vector{Bool}
	#b16::Vector{Bool}
	
	Valve1::Vector{Bool}
	Valve2::Vector{Bool}
	Valve3::Vector{Bool}
	Valve4::Vector{Bool}
	Valve5::Vector{Bool}
	Valve6::Vector{Bool}
	Valve7::Vector{Bool}
	Valve8::Vector{Bool}
	
	# Constructor for AerodyneStatus type
	function AerodyneStatus{T<:Float64}(vals::Array{T,1})
		AerodyneStatus(Array{Int}(vals))
	end # End AerodyneStatus{T<:Float64}(vals::Array{T,1}) constructor
	
	# Constructor for AerodyneStatus type
	function AerodyneStatus(vals::Array{Int})
		l = Int(length(vals))
		
		AutoBG = Array{Bool}(l)
		AutoCal = Array{Bool}(l)
		FrequencyLock = Array{Bool}(l)
		BinomialFilter = Array{Bool}(l)
		AltMode = Array{Bool}(l)
		GuessLast = Array{Bool}(l)
		PowerNorm = Array{Bool}(l)
		ContRefLock = Array{Bool}(l)
		
		AutoSpectSave = Array{Bool}(l)
		PressureLock = Array{Bool}(l)
		#b11 = Array{Bool}(l)
		#b12 = Array{Bool}(l)
		WriteData = Array{Bool}(l)
		RS232 = Array{Bool}(l)
		ElectronicBGSub = Array{Bool}(l)
		#b16 = Array{Bool}(l)
		
		Valve1 = Array{Bool}(l)
		Valve2 = Array{Bool}(l)
		Valve3 = Array{Bool}(l)
		Valve4 = Array{Bool}(l)
		Valve5 = Array{Bool}(l)
		Valve6 = Array{Bool}(l)
		Valve7 = Array{Bool}(l)
		Valve8 = Array{Bool}(l)
		
		# Parse Inputs
		for i=1:l
			# Byte 1
			AutoBG[i] = vals[i] & 2^(1-1) > 0
			AutoCal[i] = vals[i] & 2^(2-1) > 0
			FrequencyLock[i] = vals[i] & 2^(3-1) > 0
			BinomialFilter[i] = vals[i] & 2^(4-1) > 0
			AltMode[i] = vals[i] & 2^(5-1) > 0
			GuessLast[i] = vals[i] & 2^(6-1) > 0
			PowerNorm[i] = vals[i] & 2^(7-1) > 0
			ContRefLock[i] = vals[i] & 2^(8-1) > 0
			
			# Byte 2
			AutoSpectSave[i] = vals[i] & 2^(9-1) > 0
			PressureLock[i] = vals[i] & 2^(10-1) > 0
			#b11[i] = vals[i] & 2^(11-1) > 0
			#b12[i] = vals[i] & 2^(12-1) > 0
			WriteData[i] = vals[i] & 2^(13-1) > 0
			RS232[i] = vals[i] & 2^(14-1) > 0
			ElectronicBGSub[i] = vals[i] & 2^(15-1) > 0
			#b16[i] = vals[i] & 2^(16-1) > 0
			
			# Byte 3
			Valve1[i] = vals[i] & 2^(17-1) > 0
			Valve2[i] = vals[i] & 2^(18-1) > 0
			Valve3[i] = vals[i] & 2^(19-1) > 0
			Valve4[i] = vals[i] & 2^(20-1) > 0
			Valve5[i] = vals[i] & 2^(21-1) > 0
			Valve6[i] = vals[i] & 2^(22-1) > 0
			Valve7[i] = vals[i] & 2^(23-1) > 0
			Valve8[i] = vals[i] & 2^(24-1) > 0
		end # End of conversion
		new(AutoBG,AutoCal,FrequencyLock,BinomialFilter,AltMode,GuessLast,PowerNorm,ContRefLock,AutoSpectSave,PressureLock,WriteData,RS232,ElectronicBGSub,Valve1,Valve2,Valve3,Valve4,Valve5,Valve6,Valve7,Valve8)
	end # End of constructor
end # End of type
