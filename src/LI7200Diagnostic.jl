# LI7200Diagnostic.jl
#
#	Parse LI-7200 diagnostic values
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
#
# Julia 1.5.4
# 17.12.2020
# Last Edit: 07.01.2021

"""# LI7200Diagnostic

Parse the LI-7200 diagnostic values

---

### Example

```jldoctest
julia> x = LI7200Diagnostic(8190)
LI-7200 Diagnistic Values (8190)
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
julia> x.Value
8190
```

```jldoctest
julia> x.TinletOK
true
```

---

`diag = LI7200Diagnostic(x)`\n
* **x**::Int or Float64 = Unparsed diagnostic value
* **diag**::LI7200Diagnostic = Parsed diagnostic value

---

## Fields
* **Value**::Int
* **SyncError**::Bool
* **PLL_OK**::Bool
* **DetectorOK**::Bool
* **ChopperWheelOK**::Bool
* **PressureOK**::Bool
* **VoltageOK**::Bool
* **TinletOK**::Bool
* **ToutletOK**::Bool
* **HeadDetected**::Bool
"""
mutable struct LI7200Diagnostic
	"Original diagnostic value"
	Value::Int
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
		Value = val
		
		SyncError = val & 2^(11-1) > 0
		PLL_OK = val & 2^(10-1) > 0
		DetectorOK = val & 2^(9-1) > 0
		ChopperWheelOK = val & 2^(8-1) > 0
		PressureOK = val & 2^(7-1) > 0
		VoltageOK = val & 2^(6-1) > 0
		TinletOK = val & 2^(5-1) > 0
		ToutletOK = val & 2^(4-1) > 0
		HeadDetected = val & 2^(3-1) > 0
		
		new(Value,SyncError, PLL_OK, DetectorOK, ChopperWheelOK, PressureOK, VoltageOK, TinletOK, ToutletOK, HeadDetected)
	end # End of constructor
end # End of type

function Base.show(io::IO, diag::LI7200Diagnostic)
	println("LI-7200 Diagnistic Values (" * string(diag.Value) * ")")
	diag.SyncError ? println("\tSync OK") : println("\tSync ERROR")
	diag.PLL_OK ? println("\tPLL OK - Optical wheel rotating correctly") : println("\tPLL ERROR - Optical wheel not rotating correctly")
	diag.DetectorOK ? println("\tDetector Temperature OK")  : println("\tDetector ERROR - Temperature not near setpoint")
	diag.ChopperWheelOK ? println("\tChopper OK - Wheel temperature OK") : println("\tChopper ERROR - Wheel temperature not near setpoint")
	diag.PressureOK ? println("\tPressure OK - Differential pressure sensor OK") : println("\tPressure ERROR - Differential pressure sensor out of range")
	diag.VoltageOK ? println("\tVoltages OK - Internal reference voltages OK") : println("\tVoltage ERROR - Internal reference voltages NOT OK")
	diag.TinletOK ? println("\tTinlet OK - Inlet temperature OK") : println("\tTinlet ERROR - Open circuit")
	diag.ToutletOK ? println("\tToutlet OK - Outlet temperature OK") : println("\tToutlet ERROR - Open circuit")
	diag.HeadDetected ? println("\tHead detected") : println("\tHead NOT detected")
end