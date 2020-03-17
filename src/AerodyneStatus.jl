# aerodyne_status.jl
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 1.3.1
# 13.12.2016
# Last Edit: 10.03.2020

"""# AerodyneStatus

Parse the StatusW column in an STC file into this custom type

---

### Example

`statuses = AerodyneStatus.(Dstc[:StatusW])`\n
`valve1 = getfield.(statuses,:Valve1)` # Get all 'Valve1' field values from a vector of statuses, Dstc

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
mutable struct AerodyneStatus
	AutoBG::Bool
	AutoCal::Bool
	FrequencyLock::Bool
	BinomialFilter::Bool
	AltMode::Bool
	GuessLast::Bool
	PowerNorm::Bool
	ContRefLock::Bool
	
	AutoSpectSave::Bool
	PressureLock::Bool
	#b11::Bool
	#b12::Bool
	WriteData::Bool
	RS232::Bool
	ElectronicBGSub::Bool
	#b16::Bool
	
	Valve1::Bool
	Valve2::Bool
	Valve3::Bool
	Valve4::Bool
	Valve5::Bool
	Valve6::Bool
	Valve7::Bool
	Valve8::Bool
	
	# Constructor for AerodyneStatus type
	function AerodyneStatus(val::Float64)
		AerodyneStatus(Int(val))
	end # End AerodyneStatus(val::Float64) constructor
	
	# Constructor for AerodyneStatus type
	function AerodyneStatus(val::Int)
		####################
		##  Parse Inputs  ##
		####################
		# Byte 1
		AutoBG = val & 2^(1-1) > 0
		AutoCal = val & 2^(2-1) > 0
		FrequencyLock = val & 2^(3-1) > 0
		BinomialFilter = val & 2^(4-1) > 0
		AltMode = val & 2^(5-1) > 0
		GuessLast = val & 2^(6-1) > 0
		PowerNorm = val & 2^(7-1) > 0
		ContRefLock = val & 2^(8-1) > 0
		
		# Byte 2
		AutoSpectSave = val & 2^(9-1) > 0
		PressureLock = val & 2^(10-1) > 0
		#b11 = val & 2^(11-1) > 0
		#b12 = val & 2^(12-1) > 0
		WriteData = val & 2^(13-1) > 0
		RS232 = val & 2^(14-1) > 0
		ElectronicBGSub = val & 2^(15-1) > 0
		#b16 = val & 2^(16-1) > 0
		
		# Byte 3
		Valve1 = val & 2^(17-1) > 0
		Valve2 = val & 2^(18-1) > 0
		Valve3 = val & 2^(19-1) > 0
		Valve4 = val & 2^(20-1) > 0
		Valve5 = val & 2^(21-1) > 0
		Valve6 = val & 2^(22-1) > 0
		Valve7 = val & 2^(23-1) > 0
		Valve8 = val & 2^(24-1) > 0
		
		new(AutoBG,AutoCal,FrequencyLock,BinomialFilter,AltMode,GuessLast,PowerNorm,ContRefLock,AutoSpectSave,PressureLock,WriteData,RS232,ElectronicBGSub,Valve1,Valve2,Valve3,Valve4,Valve5,Valve6,Valve7,Valve8)
	end # End of constructor
end # End of type

function Base.show(io::IO, status::AerodyneStatus)
	#println("| AutoBG | AutoCal | Frequency Lock | Binomial Filter | AltMode | Guess Last | Power Norm. | Cont. Ref. Lock | Auto Spec. Save | Press. Lock | Write Data | RS232 | Elec. BG Sub. | Valve 1 | Valve 2 | Valve 3 | Valve 4 | Valve 5 | Valve 6 | Valve 7 | Valve 8 |")
	status.Valve1 ? print("| Valve1") : nothing
	status.Valve2 ? print("| Valve2") : nothing
	status.Valve3 ? print("| Valve3") : nothing
	status.Valve4 ? print("| Valve4") : nothing
	status.Valve5 ? print("| Valve5") : nothing
	status.Valve6 ? print("| Valve6") : nothing
	status.Valve7 ? print("| Valve7") : nothing
	status.Valve8 ? print("| Valve8") : nothing
	status.WriteData ? print("| Write Data") : nothing
	status.RS232 ? print("| RS232 Output") : nothing
	status.GuessLast ? print("| Guess Last Fit") : nothing
	status.ContRefLock ? print("| Continuous Reference Lock") : nothing
	status.AutoSpectSave ? print("| Auto Spectrum Save") : nothing
	status.AutoBG ? print("| Auto Background") : nothing
	status.AutoCal ? print("| Auto Calibration") : nothing
	status.FrequencyLock ? print("| Frequency Lock") : nothing
	status.BinomialFilter ? print("| Binomial Filter") : nothing
	status.AltMode ? print("| AltMode") : nothing
	status.PowerNorm ? print("| Power Normalization") : nothing
	status.PressureLock ? print("| Pressure Lock") : nothing
	status.ElectronicBGSub ? print("| Electronic Background Subtraction") : nothing
end