# LI7200Diagnostic.jl
#
#	Parse LI-7200 diagnostic values
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
#
# Julia 1.6.2
# 17.12.2020
# Last Edit: 13.08.2021

"""# LI7200Diagnostic

Parse the LI-7200 diagnostic values

---

### Example

```jldoctest
julia> x = LI7200Diagnostic(8190)
LI-7200 Diagnistic Values (8190)
		AGC (dirtiness): 87.5% - Optics need cleaning
		Sync OK
		PLL OK - Optical wheel rotating correctly
		Detector Temperature OK
		Chopper OK - Wheel temperature OK
		Pressure OK - Differential pressure sensor OK
		Voltages OK - Internal reference voltages OK
		Tinlet OK - Inlet temperature OK
		Toutlet OK - Outlet temperature OK
		Head detected
```

```jldoctest
julia> x.value
8190
```

```jldoctest
julia> x.TinletOK
true
```

---

`diag = LI7200Diagnostic(x);`\n
* **x**::Int or Float64 = Unparsed diagnostic value
* **diag**::LI7200Diagnostic = Parsed diagnostic value

---

## Fields
* **value**::Int
* **AGC**::Int
* **SyncError**::Bool
* **PLL_OK**::Bool
* **DetectorOK**::Bool
* **ChopperWheelOK**::Bool
* **PressureOK**::Bool
* **VoltageOK**::Bool
* **TinletOK**::Bool
* **ToutletOK**::Bool
* **HeadDetected**::Bool
* **AGC**::Int
"""
struct LI7200Diagnostic
	"Original diagnostic value"
	value::Int
	"AGC - Automatic Gain Control (dirtiness)"
	AGC::Int
	"Sync Error"
	SyncError::Bool
	"Optical wheel rotation"
	PLL_OK::Bool
	"Detector Temperature"
	DetectorOK::Bool
	"Chopper wheel"
	ChopperWheelOK::Bool
	"Differential pressure sensor"
	PressureOK::Bool
	"Internal reference voltage"
	VoltageOK::Bool
	"Inlet Temperature"
	TinletOK::Bool
	"Outlet Temperature"
	ToutletOK::Bool
	"Sensor Head Detection"
	HeadDetected::Bool
	
	function LI7200Diagnostic(val::Float64)
		LI7200Diagnostic(Int(val))
	end
	
	function LI7200Diagnostic(val::Int)
		value = val
		
		AGC = Int(UInt16(val & 2^(0) > 0) << 0 | UInt16(val & 2^(1) > 0) << 1 | UInt16(val & 2^(2) > 0) << 2 | UInt16(val & 2^(3) > 0) << 3)
		SyncError = val & 2^(4) > 0
		PLL_OK = val & 2^(5) > 0
		DetectorOK = val & 2^(6) > 0
		ChopperWheelOK = val & 2^(7) > 0
		PressureOK = val & 2^(8) > 0
		VoltageOK = val & 2^(9) > 0
		TinletOK = val & 2^(10) > 0
		ToutletOK = val & 2^(11) > 0
		HeadDetected = val & 2^(12) > 0
		
		new(value ,AGC, SyncError, PLL_OK, DetectorOK, ChopperWheelOK, PressureOK, VoltageOK, TinletOK, ToutletOK, HeadDetected)
	end # End of constructor
end # End of type

function Base.show(io::IO,::MIME"text/plain", diag::LI7200Diagnostic)
	# AGC and Errors only
	print(string(diag.value),
		" - AGC(" * string(diag.AGC) * "): ",diag.AGC < 14 ? @sprintf("%2.0f",diag.AGC * 6.25) * "%" : RED_FG(@sprintf("%2.0f",diag.AGC * 6.25) * "% - Optics need cleaning"))
	diag.SyncError ? nothing : print(", Sync: ",RED_FG("Error"))
	diag.PLL_OK ? nothing : print(", PLL: ",RED_FG("Error"))
	diag.DetectorOK ? nothing : print(", Detector: ",RED_FG("Error"))
	diag.ChopperWheelOK ? nothing : print(", Chopper: ",RED_FG("Error"))
	diag.PressureOK ? nothing : print(", Pressure: ",RED_FG("Error"))
	diag.VoltageOK ? nothing : print(", Voltage: ",RED_FG("Error"))
	diag.TinletOK ? nothing : print(", Tinlet: ",RED_FG("Error"))
	diag.ToutletOK ? nothing : print(", Toutlet: ",RED_FG("Error"))
	diag.HeadDetected ? nothing : print(", Head: ",RED_FG("Absent"))
	
	# Full Report Version
	#=println(string(diag.value),
		" - AGC: ",diag.AGC < 14 ? @sprintf("%2.0f",diag.AGC * 6.25) * "%" : RED_FG(@sprintf("%2.0f",diag.AGC * 6.25) * "% - Optics need cleaning"),
		", Sync: ",diag.SyncError ? GREEN_FG("+") : RED_FG("Error"),
		", PLL: ",diag.PLL_OK ? GREEN_FG("+") : RED_FG("Error"),
		", Detector: ",diag.DetectorOK ? GREEN_FG("+") : RED_FG("Error"),
		", Chopper: ",diag.ChopperWheelOK ? GREEN_FG("+") : RED_FG("Error"),
		", Pressure: ",diag.PressureOK ? GREEN_FG("+") : RED_FG("Error"),
		", Volt: ",diag.VoltageOK ? GREEN_FG("+") : RED_FG("Error"),
		", Tin:",diag.TinletOK ? GREEN_FG("+") : RED_FG("Error"),
		", Tout: ",diag.ToutletOK ? GREEN_FG("+") : RED_FG("Error"),
		", Head: ",diag.HeadDetected ? GREEN_FG("Present") : RED_FG("Absent"))=#
end
