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
# Last Edit: 11.08.2021

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
mutable struct LI7200Diagnostic
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

function Base.show(io::IO, diag::LI7200Diagnostic)
	println("LI-7200 Diagnistic Values (" * string(diag.value) * ")")
	diag.AGC < 14 ? println("\tAGC (dirtiness): " * string(diag.AGC * 6.25) * "%") : println("\tAGC (dirtiness): ", RED_FG(string(diag.AGC * 6.25)),RED_FG("% - Optics need cleaning"))
	diag.SyncError ? println("\tSync OK") : println("\tSync ",RED_FG("ERROR"))
	diag.PLL_OK ? println("\tPLL OK - Optical wheel rotating correctly") : println("\tPLL ",RED_FG("ERROR - Optical wheel not rotating correctly"))
	diag.DetectorOK ? println("\tDetector Temperature OK")  : println("\tDetector ",RED_FG("ERROR - Temperature not near setpoint"))
	diag.ChopperWheelOK ? println("\tChopper OK - Wheel temperature OK") : println("\tChopper ",RED_FG("ERROR - Wheel temperature not near setpoint"))
	diag.PressureOK ? println("\tPressure OK - Differential pressure sensor OK") : println("\tPressure ",RED_FG("ERROR - Differential pressure sensor out of range"))
	diag.VoltageOK ? println("\tVoltages OK - Internal reference voltages OK") : println("\tVoltage ",RED_FG("ERROR - Internal reference voltages NOT OK"))
	diag.TinletOK ? println("\tTinlet OK - Inlet temperature OK") : println("\tTinlet ",RED_FG("ERROR - Open circuit"))
	diag.ToutletOK ? println("\tToutlet OK - Outlet temperature OK") : println("\tToutlet ",RED_FG("ERROR - Open circuit"))
	diag.HeadDetected ? println("\tHead detected") : println(RED_FG("\tHead NOT detected"))
end
