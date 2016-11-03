#pragma rtGlobals=3		// Use modern global access method and strict wave access.
# Place this file in WaveMetrics/Igor Pro 6 User Files/User Procedures/OC_SANS_MACROS/


//================================ACTUAL FUNCTIONS
Function MultXCalc()
	Variable Phi_Initial=0
	Variable Phi_step=15
	Variable Phi_max=180
	String Condition_info="[FIELD]_[TEMP]_[Q]"		
	Prompt Phi_initial,"Initial Phi Value (Float)"
	Prompt Phi_step,"Step Size for Phi (Float)"
	Prompt Phi_max,"Maximum Phi (Float)"
	Prompt Condition_info, "Condition variables  - _B[Phi] will be added automatically"

	
	DoPrompt "Enter Below values, Current Values are Defaults",Condition_info,Phi_initial,Phi_step,Phi_max 
		if(V_Flag)
		Abort "You Cancelled - Ouch, I have feelings you know...."
	endif
	
	PickPath()
	PathInfo catPathName
	string A_Data=Condition_info+"_A90"
	print A_Data
	Execute "A_LoadOneDDataWithName(\""+S_Path+A_Data+"\",0)"
	
	variable i=0
	do
		Variable Phi=Phi_Initial+Phi_step*i
		string B_Data=Condition_info+"_B"+num2str(Phi)
		Execute "A_LoadOneDDataWithName(\""+S_Path+B_Data+"\",0)"
		//DO CALC============================================
		MultiplyDataSets(B_Data,B_Data,1,"temp")
		variable factor = sin(Phi*pi/180)^4
		print factor
		print "B_Data: "+B_Data
		DivideDataSets("temp",A_Data,4*factor,"X2_"+Condition_info+"_"+num2str(Phi))
		fReWrite1DData_noPrompt("X2_"+Condition_info+"_"+num2str(Phi),"tab","CRLF")
		killData("temp")
		i+=1
	while(Phi<Phi_Max)
End

Function killData(DF)
//taken from A_PlotManager_Kill in file Common/Packages/PlotManager/PlotManager_v40.ipf
	String DF
	String savDF=GetDataFolder(1)
	ControlInfo popup0
	SetDataFolder DF
	KillVariables/A			//removes the dependent variables
	SetDataFolder savDF
	//now kill the data folder
	KillDataFolder/Z $DF
	ControlUpdate popup0		//refresh the popup, very important if last item removed
End

Function MultSectAvg()

//USER VARIABLE SELECTION
	Variable Phi_initial=0
	Variable Phi_step=15
	Variable Dphi=-1
	Variable Phi_max=180
	String side="both"
	String prefix="[FIELD]_[TEMP]_[Q]_[TYPE]"
		
	Prompt Phi_initial,"Initial Phi Value (Float)"
	Prompt Phi_step,"Step Size for Phi (Float)"
	Prompt Dphi,"Delta Phi Default is Phi_step/2 (Float) "
	Prompt Phi_max,"Maximum Phi (Float)"
	Prompt side,"Sides?",popup,"both;right;left"
	Prompt prefix,"Output File Prefix  (string) - KEEP THE QUOTES"
	DoPrompt "Enter Below values, Current Values are Defaults",prefix,Phi_initial,Phi_step,Dphi,Phi_max,side //Keep Prefix First as this is what will be modified every time so its nice for user this way
	if(V_Flag)
		Abort "You Cancelled - Ouch, I have feelings you know....This is so annoying Ian -- Hillary"
	endif
	//END USER VARIABLE SELCTION
	
	if(Dphi==-1) // set Dphi if user did not pick a value
		Dphi=Phi_step/2
	endif

	// need next two lines or wont work
	SVAR type=root:myGlobals:gDataDisplayType
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	String path=MultAvgSetUp() //get path and do some other set up
	Variable i=0
	do
		Variable Phi=Phi_Initial+Phi_step*i
		String temp="AVTYPE=Sector;PHI="+num2str(Phi)+";DPHI="+num2str(Dphi)+";WIDTH=0;SIDE="+side+";QCENTER=0;QDELTA=0;"
		String/G root:myGlobals:Protocols:gAvgInfoStr=temp
		//setup a "fake protocol" wave, sice I have no idea of the current state of the data
		Make/O/T/N=8 root:myGlobals:Protocols:fakeProtocol
		Wave/T fakeProtocol = $"root:myGlobals:Protocols:fakeProtocol"
		String junk="Unknown file from Average_Panel"
		fakeProtocol[0] = junk
		fakeProtocol[1] = junk
		fakeProtocol[2] = junk
		fakeProtocol[3] = junk
		fakeProtocol[4] = junk
		fakeProtocol[5] = junk
		fakeProtocol[6] = junk
		fakeProtocol[7] = temp
		//set the global
		String/G root:myGlobals:Protocols:gProtoStr = "fakeProtocol"	
		
		CircularAverageTo1D(type)	
		if (useXMLOutput == 1)
					WriteXMLWaves_W_Protocol(type,path+prefix+num2str(Phi),0)
				else
					WriteWaves_W_Protocol(type,path+prefix+num2str(Phi),0)		//"" is an empty path, 1 will force a dialog
		endif
	i+=1
	while(phi<Phi_max)
	//Print out info
	print "=========DONE========================"
	print "select next line and hit enter to run again"
	print "MultSectAvg()"
	print ""//for new line
	
	print "Values used:"
	print "Phi_initial: "+num2str(Phi_initial)
	print "Phi_step: "+num2str(Phi_step)
	print "DPhi: "+num2str(DPhi)
	print "Phi_max: " + num2str(Phi_max)
	print "prefix: "+prefix
	print ""//for new line
	print "Saved in: "+path
End

Function MultAnnulAvg()
	
	
//USER VARIABLE SELECTION
	//create variables with default values
	Variable Q_initial=.005
	Variable Q_step=.01
	Variable Q_max=.11
	Variable pixels=10
	String prefix="[FIELD]_[TEMP]_[DATE]"
	//prompt user to change values
	Prompt Q_initial,"First Q Value (Float)"
	Prompt Q_step,"Increment in QCenter  (Float)"
	Prompt Q_max,"Maximum Q Center Value (Float)"
	Prompt pixels,"QDelta (Pixels) (Integer)"
	Prompt prefix,"Output File Prefix  (string) - KEEP THE QUOTES"
	DoPrompt "Enter Below values, Current Values are Defaults",prefix,Q_initial,Q_step,Q_max,pixels //Keep Prefix First as this is what will be modified every time so its nice for user this way
	if(V_Flag)
			Abort "You Cancelled - Ouch, I have feelings you know...."
	endif
//END USER VARIABLE SELCTION
	
	// need next two lines or wont work
	SVAR type=root:myGlobals:gDataDisplayType
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write

	String path=MultAvgSetUp()//set path and do some other set up

	Variable i=0 //variable for loop
	do  //Loop over Q values taking an annular average at each step
		Variable QCENTER = Q_initial + Q_step*(i)
		//build the string that the averaging routine is looking for	
		String temp="AVTYPE=Annular;PHI=0;DPHI=0;WIDTH=0;SIDE=both;QCENTER="+num2str(QCENTER)+";QDELTA="+num2str(pixels)+";"
		String/G root:myGlobals:Protocols:gAvgInfoStr=temp //set global variable

		//setup a "fake protocol" wave, sice I have no idea of the current state of the data
		Make/O/T/N=8 root:myGlobals:Protocols:fakeProtocol
		Wave/T fakeProtocol = $"root:myGlobals:Protocols:fakeProtocol"
		String junk="Unknown file from Average_Panel"
		fakeProtocol[0] = junk
		fakeProtocol[1] = junk
		fakeProtocol[2] = junk
		fakeProtocol[3] = junk
		fakeProtocol[4] = junk
		fakeProtocol[5] = junk
		fakeProtocol[6] = junk
		fakeProtocol[7] = temp
		//set the global
		String/G root:myGlobals:Protocols:gProtoStr = "fakeProtocol"	
		AnnularAverageTo1D(type)	//do avg
		WritePhiave_W_Protocol(type,path+prefix+"_AN_"+num2str(1000*QCENTER),0)// save average -"" is an empty path, 1 will force a dialog - 0 Saves to path.
	i+=1
	while(QCENTER<Q_max)
	//Print out info
	print "=========DONE========================"
	print "select next line and hit enter to run again"
	print "MultAnnulAvg()"
	print ""//for new line
	print "Values used:"
	print "Q_initial: "+num2str(Q_initial)
	print "Q_step: "+num2str(Q_step)
	print "Q_max: "+num2str(Q_max)
	print "Q Delta (pixels): " + num2str(pixels)
	print "prefix: "+prefix
	print ""//for new line
	print "Saved in: "+path
	
	
End

//Utility Functions for things that are repeated in different Mult Avg Functions
Function/S MultAvgSetUp()
	//Things from main average panel that are important to setting up the average
	//SAVE PATH IS CHOSEN IN THIS FUNCTION
	//returns the path chosen by the user
	SVAR type=root:myGlobals:gDataDisplayType
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	//Check for logscale data in "type" folder
	String dest = "root:Packages:NIST:"+type
	NVAR isLogScale = $(dest + ":gIsLogScale")
	Variable wasLogScale=isLogScale
	if(isLogScale)
		ConvertFolderToLinearScale(type)
	Endif
	//set data folder back to root (redundant)
	SetDataFolder root:

	
	//CHOOSE SAVING FOLDER
	PickPath()
	PathInfo catPathName

	return S_Path //return path chosen by user
End

//============================NICE MENU==========================================================

Function AnnularButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			MultAnnulAvg()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function SectorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			MultSectAvg()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CalcAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			calcAll()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function OC_Macros_DoneButton(ctrlName) : ButtonControl
	
	String ctrlName
	Abort "UNIMPLEMENTED"
	// This is not implemented because once you close it you aren't able to reopen it for some reason.
//	DoWindow/K OC_Macros
//	SetDataFolder root:
End


Window OC_Macros() : Panel
//Issues:
//If multiple panels are opened then teh kill window button will only kill the first panel

	PauseUpdate; Silent 1		// building window...
	Variable GoldRat=1.618 //golden ratio - overdesign forever
	Variable YLength = 200 // base all other lengths of this and golden ratio
	
	//Making Frame
	Variable X1 = 1200 //top left corner X
	Variable Y1 = 10  //top left corner Y
	NewPanel /W=(X1,Y1,GoldRat*YLength+X1,YLength+Y1) as "Oberlin SANS Macros"
	ModifyPanel frameStyle=2 //dope indented walls
	ModifyPanel fixedSize=1 //I DECIDE THE SIZE - NOT THE USER grrrr
	variable rgbFactor =65535/255 //cbRGB is some weird rgb system
	ModifyPanel cbRGB=(176*rgbFactor,196*rgbFactor,222*rgbFactor) //color name is lightsteelblue in case you were wondering
	
	Variable ButtonHeight=YLength/(GoldRat*GoldRat)
	Variable ButtonLength=YLength/GoldRat
	
	//button insets
	Variable YInset=6
	Variable XInset=10
	
	Variable YButtonGap=YLength-2*YInset-2*ButtonHeight
	Variable XButtonGap=YLength*GoldRat-2*ButtonLength-2*XInset
	Variable LowerButtonY =  YLength-YInset-ButtonHeight
	Variable RightButtonX = XInset+ButtonHeight*GoldRat+XButtonGap
//make buttons
	Button AnnulAvgBtn,pos={XInset,YInset},size={ButtonLength,ButtonHeight},proc= AnnularButtonProc,title="Multiple Annular Avg"
	Button SectAvgBtn,pos={RightButtonX,YInset},size={ButtonLength,ButtonHeight},proc= SectorButtonProc,title="Multiple Sector Avg"
	Button MultBCalc,pos={XInset,LowerButtonY},size={ButtonLength,ButtonHeight},proc=CalcAllButtonProc,title="Calc Components"
	Button Done,pos={RightButtonX,LowerButtonY},size={ButtonLength,ButtonHeight/GoldRat},proc=OC_Macros_DoneButton,title="Close Panel"
EndMacro

//Added By Ian Hunt-Isaak ihuntisa@oberlin (through may 2017) Permanent: ianhuntisaak@gmail.com
//Last Modified Sept 26 2015
// MultAnnulAvg() Performs Annular Averages at multiple Q values on the result of a workfile math operation. 
// MultSectAvg() Performs Sector Averages at multiple Phi values on the result of a workfile math operation. 



#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function calcAll()
	PickPath()
	PathInfo catPathName
	String path = S_Path
	String prefix = extractPrefix(path)
	print path
	print prefix
	calcN(path,prefix)
	calcZ(path,prefix)
	calcX1(path,prefix)
	calcX2(path,prefix,90)
	calcY(path,prefix)
	calcYZ(path,prefix)
end


Function calcN(path, prefix)
	String path //C:Users:Magnetic:Hillary:TestFolder
	String prefix //HF_10_HQ
	String pathPre = path+prefix
	print pathPre
	
	ASC_Math(pathPre+"_DD.asc",pathPre+"_UU.asc","+")
	
	String outName = "N_"+prefix
	secAvg(0,10,"both", path, outName)
end

Function calcZ(path, prefix)
	String path 
	String prefix 
	String pathPre = path+prefix
	ASC_Math(pathPre+"_UD.asc",pathPre+"_DU.asc","+")
	
	String outName = "Z_"+prefix
	secAvg(90,10,"both", path, outName)
end

Function calcX1(path, prefix)
	String path
	String prefix 
	String pathPre = path+prefix

	ASC_Math(pathPre+"_DD.asc",pathPre+"_UU.asc","+")

	secAvg(90,10,"both",path, prefix+"_A90")
	secAvg(0,10,"both",  path, prefix+"_A0")

	loadFile(path,prefix+"_A90")
	loadFile(path,prefix+"_A0")

	String outName="X1_"+prefix
	SubtractDataSets(prefix+"_A90",prefix+"_A0", 1, outName)
	fReWrite1DData_noPrompt(outName,"tab","CRLF")
end

Function calcX2(path, prefix, phi)
	String path
	String prefix
	Variable phi
	
	String pathPre=path+prefix
	String A_Data=prefix+"_A90"
	String B_Data=prefix+"_B"+num2str(phi)
	
	ASC_Math(pathPre+"_DD.asc",pathPre+"_UU.asc","+")
	secAvg(90,10,"both",path, A_Data)
	ASC_Math(pathPre+"_DD.asc",pathPre+"_UU.asc","-")
	secAvg(phi,10,"both",  path, B_Data)
	loadFile(path,A_Data)
	loadFile(path,B_Data)
	
	MultiplyDataSets(B_Data,B_Data,1,"temp")
	variable factor = sin(phi*pi/180)^4
	

	
	String outName = "X2_"+prefix
	if(phi==90)
		// For consistency wih old work
		DivideDataSets("temp",A_Data,4*factor,outName)
		fReWrite1DData_noPrompt(outName,"tab","CRLF")
	else
		DivideDataSets("temp",A_Data,4*factor,outName+"_"+num2str(phi))
		fReWrite1DData_noPrompt(outName+"_"+num2str(phi),"tab","CRLF")
	endif
end
	
Function calcYZ(path, prefix)
	String path 
	String prefix 
	String pathPre = path+prefix
	
	ASC_Math(pathPre+"_UD.asc",pathPre+"_DU.asc","+")
	
	String outName = "YZ_"+prefix
	secAvg(0,10,"both", path, outName)
end

Function calcY(path, prefix)
	String path
	String prefix 
	String pathPre = path+prefix
	
	ASC_Math(pathPre+"_UD.asc",pathPre+"_DU.asc","+")
	secAvg(0,10,"both",path, prefix+"_C0")
	secAvg(90,10,"both",  path, prefix+"_C90")
	
	loadFile(path,prefix+"_C0")
	loadFile(path,prefix+"_C90")
	
	String outName="Y_"+prefix
	SubtractDataSets(prefix+"_C0",prefix+"_C90", 1, outName)
	fReWrite1DData_noPrompt(outName,"tab","CRLF")
End

//+++++++++++++++++Utility Functions++++++++++++++++++++++++++++++



Function/S extractPrefix(input)
	//Extracts just the prefix from a path to condition
	//Assumes path is of the form:
	//					"C:Users:Ian : HF_10 : HF_10_HQ:"
	// extractPrefix ("C:Users:Ian: HF_10 : HF_10_HQ:")
	// should return "HF_10_HQ"

	String input
	String prefix = ""
	Variable len = strlen(input)
	Variable pos = strSearch(input,":",len-2,1) //strSearch(str, findThisStr, start[, options]), 1 is search backwards
	if(strsearch(input[pos+1,len-2],"_",0)==-1)
		//If guess string contains no underscores assume we're in a new polarizations
		// i.e. ...:MF_200_HQ:p9:
		Variable pos2 = strSearch(input,":",pos-1,1)
		String condInfo = input[pos2+1,pos-1]
		Variable firstUnder = strSearch(condInfo,"_",0)
		prefix = condInfo[0,firstUnder] + input[pos+1,len-2]+condInfo[firstUnder,strlen(condInfo)]
	else
		prefix = input[pos+1,len-2]
	endif

	prompt prefix,"Prefix"
	
	DoPrompt "If nothing entered will guess based on path",prefix
	if(V_Flag)
		Abort "You Cancelled - Ouch, I have feelings you know...."
	endif
	
	return prefix
end

Function loadFile(location,filestr)
	String filestr,location
 	String path=location+filestr
	Execute "A_LoadOneDDataWithName(\""+path+"\","+num2str(0)+")"
End
//---------------------------------
Function ASC_Math(path1,path2,oper)
	//Function allows calling without multiplying data with constants
	String path1,path2,oper
	ASC_Math_consts(path1,path2,oper,1,1)
End

Function ASC_Math_consts(path1,path2,oper,const1,const2)
	// WorkMath panel needs to be open in order for there to be the proper data folders
	// Performs arithmetic on ASC files.
	String path1
	String path2
	String oper
	Variable const1, const2
	String str1,str2,dest = "Result"
	String pathStr,workMathStr="WorkMath:"
	if( DataFolderExists(workMathStr) )
		// good workmath file is up
	else
		Execute "Init_WorkMath()"
	endif
	//set #1
	Load_NamedASC_File(path1,workMathStr+"File_1")
	
	NVAR pixelsX = root:myGlobals:gNPixelsX		//OK, location is correct
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	WAVE/Z data1=$("root:Packages:NIST:"+workMathStr+"File_1:linear_data")
	WAVE/Z err1=$("root:Packages:NIST:"+workMathStr+"File_1:linear_data_error")
	
	//Load set #2
	Load_NamedASC_File(path2,workMathStr+"File_2")
	WAVE/Z data2=$("root:Packages:NIST:"+workMathStr+"File_2:linear_data")
	WAVE/Z err2=$("root:Packages:NIST:"+workMathStr+"File_2:linear_data_error")
	
	//copy contents of str1 folder to dest and create the wave ref (it will exist)
	CopyWorkContents(workMathStr+"File_1",workMathStr+dest)
	WAVE/Z destData=$("root:Packages:NIST:"+workMathStr+dest+":linear_data")
	WAVE/Z destData_log=$("root:Packages:NIST:"+workMathStr+dest+":data")
	WAVE/Z destErr=$("root:Packages:NIST:"+workMathStr+dest+":linear_data_error")
	
	strswitch(oper)	
		case "*":		//multiplication
			destData = const1*data1 * const2*data2
			destErr = const1^2*const2^2*(err1^2*data2^2 + err2^2*data1^2)
			destErr = sqrt(destErr)
			break	
		case "-":		//subtraction
			destData = const1*data1 - const2*data2
			destErr = const1^2*err1^2 + const2^2*err2^2
			destErr = sqrt(destErr)
			break
		case "/":		//division
			destData = (const1*data1) / (const2*data2)
			destErr = const1^2/const2^2*(err1^2/data2^2 + err2^2*data1^2/data2^4)
			destErr = sqrt(destErr)
			break
		case "+":		//addition
			destData = const1*data1 + const2*data2
			destErr = const1^2*err1^2 + const2^2*err2^2
			destErr = sqrt(destErr)
			break			
	endswitch

	destData_log = log(destData)		//for display
	//show the result
	WorkMath_Display_PopMenuProc("",0,"Result")
End

//------------------------------------------
Function secAvg(Phi, Dphi, side,path,prefix)

	//If no input for saving - default is to save
	Variable Phi,Dphi
	String side, prefix, path
	secAvg_saveOption(Phi,Dphi,side,path,prefix,1)
End

Function secAvg_saveOption(Phi,Dphi,side,path,prefix,doSave)
	// for taking a sector average of whatever is up in the workfile math panel
	// Will fail if there is no result of a workfile math function up
	Variable Phi 
	Variable Dphi
	String side 
	String prefix
	String path
	Variable doSave //1 for save - anything else for not save
	
	// need next two lines or wont work
	SVAR type=root:myGlobals:gDataDisplayType
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	String dest = "root:Packages:NIST:"+type
	NVAR isLogScale = $(dest + ":gIsLogScale")
	Variable wasLogScale=isLogScale
	if(isLogScale)
		ConvertFolderToLinearScale(type)
	Endif
	//set data folder back to root (redundant)
	SetDataFolder root:

	String temp="AVTYPE=Sector;PHI="+num2str(Phi)+";DPHI="+num2str(Dphi)+";WIDTH=0;SIDE="+side+";QCENTER=0;QDELTA=0;"
	String/G root:myGlobals:Protocols:gAvgInfoStr=temp
	//setup a "fake protocol" wave, sice I have no idea of the current state of the data
	Make/O/T/N=8 root:myGlobals:Protocols:fakeProtocol
	Wave/T fakeProtocol = $"root:myGlobals:Protocols:fakeProtocol"
	String junk="Unknown file from Average_Panel"
	fakeProtocol[0] = junk
	fakeProtocol[1] = junk
	fakeProtocol[2] = junk
	fakeProtocol[3] = junk
	fakeProtocol[4] = junk
	fakeProtocol[5] = junk
	fakeProtocol[6] = junk
	fakeProtocol[7] = temp
	//set the global
	String/G root:myGlobals:Protocols:gProtoStr = "fakeProtocol"	
		
	CircularAverageTo1D(type)	
	if(doSave==1)
		WriteWaves_W_Protocol(type,path+prefix,0)	
	endif
End
