#pragma rtGlobals=3		// Use modern global access method and strict wave access.
# Place this file in WaveMetrics/Igor Pro 6 User Files/Igor Procedures/
# You can also place a link to this file in the above location
#
Menu "Macros"
	"Load Oberlin Macros", /Q, LoadOC_Macros()
End

Function LoadOC_Macros()
//Make Sure Polarization reduction was loaded
	PolarizationLoader()
	Execute/P/Q/Z "INSERTINCLUDE \"OC_Macros\""
	Execute/P/Q/Z "COMPILEPROCEDURES "// Note the space before final quote
	Execute/P ("OC_Macros()")
End
