#pragma rtGlobals=1		// Use modern global access method.
Menu "tanakaGraph"
	"hideAxis"
	"appearAxis"
	"hideUnits"
	"fontSize"
	"drawPulse"
	"drawHBar"
	"drawVBar"
	"TachibanaTexts"
	"makeCategoryPlot"
	"addCategoryPlot"
	"adjustCategoryPlot"
	"addErrorBar"
	"setTracesOffset"
	"setTracesColor"
End

macro hideAxis()
	String a_axis, a_list
	variable windex=0

	a_list = AxisList("")
	a_axis = StringFromList(windex, a_list)
	Do
		ModifyGraph axThick($a_axis)=0
		ModifyGraph noLabel($a_axis)=2
		windex+=1
		a_axis = StringFromList(windex, a_list)
	While(strlen(a_axis)!=0)
end

macro appearAxis()
	String a_axis, a_list
	variable windex=0

	a_list = AxisList("")
	a_axis = StringFromList(windex, a_list)
	Do
		ModifyGraph axThick($a_axis)=1
		ModifyGraph noLabel($a_axis)=0
		ModifyGraph axRGB=(0,0,0),tlblRGB=(0,0,0),alblRGB=(0,0,0)
		windex+=1
		a_axis = StringFromList(windex, a_list)
	While(strlen(a_axis)!=0)
end

macro hideUnits()
	String a_axis, a_list
	variable windex=0

	a_list = AxisList("")
	a_axis = StringFromList(windex, a_list)
	Do
		Label $a_axis "\\u#2"
		windex+=1
		a_axis = StringFromList(windex, a_list)
	While(strlen(a_axis)!=0)
end

macro TachibanaTexts()
	appearAxis()
	fontSize(18)
	hideUnits()
	Label bottom "\\u#2Time"
	SetDrawEnv fsize= 18;DelayUpdate
	DrawText 0,0,"ms"
	DrawText 0.1,0.1,"pA"
	DrawText 0.2,0.2,"pA"
	DrawText 0.3,0.3,"-70 mV"
	DrawText 0.4,0.4,"-10 mV"
	SetDrawEnv textrot= 90;DelayUpdate
	DrawText 0.5,0.5,"Vh = -90 mV"
	DrawText 0.6,0.6,"Current"
end

macro fontSize(size)
	String a_axis, a_list
	variable windex=0, size=18
	prompt size, "font size"

	a_list = AxisList("")
	a_axis = StringFromList(windex, a_list)
	Do
		ModifyGraph fSize($a_axis)=size
		SetDrawEnv fsize=size
		windex+=1
		a_axis = StringFromList(windex, a_list)
	While(strlen(a_axis)!=0)
end

macro drawPulse(sttime, onset, offset, entime, fromY, toY, polarity)
	variable sttime=-0.1, onset=0, offset=0.2, entime=0.6, fromY=0.06, toY=0.12, polarity=1
	prompt sttime, "start time"
	prompt onset, "onset"
	prompt offset, "offset"
	prompt entime, "end time"
	prompt fromY, "Y from (rel)"
	prompt toY, "Y to (rel)"
	prompt polarity, "polarity 0/1: neg/pos"

	if (polarity ==0)
		variable temp
		temp = toY
		toY = fromY
		fromY = temp
	endif

	variable stX, enX, stY, enY
	stX = sttime; enX = onset; stY = toY; enY = toY
		SetDrawEnv xcoord= bottom,linethick= 2.00
		DrawLine stX, stY, enX, enY
	stX = onset; enX = onset; stY = toY; enY = fromY
		SetDrawEnv xcoord= bottom,linethick= 2.00
		DrawLine stX, stY, enX, enY
	stX = onset; enX = offset; stY = fromY; enY = fromY
		SetDrawEnv xcoord= bottom,linethick= 2.00
		DrawLine stX, stY, enX, enY
	stX = offset; enX = offset; stY = fromY; enY = toY
		SetDrawEnv xcoord= bottom,linethick= 2.00
		DrawLine stX, stY, enX, enY
	stX = offset; enX = entime; stY = toY; enY = toY
		SetDrawEnv xcoord= bottom,linethick= 2.00
		DrawLine stX, stY, enX, enY

end

macro adjustCategoryPlot()
	ModifyGraph barGap(bottom)=0
	ModifyGraph toMode=-1
	ModifyGraph catGap(bottom)=0.5
end

macro makeCategoryPlot (wave1, isSE, wave2, foldername)
	string wave1="*", wave2="", foldername=""
	variable isSE=0
	prompt wave1, "Avg wave names"
	prompt isSE, "SE wave? (1/0 : y/n)"
	prompt wave2, "SE wave names"
	prompt foldername, "folder name"

	string targetFolder, labelwave
	if(stringmatch(foldername,""))
		foldername = "temp"
	endif
		targetFolder = ":" + foldername
		newDataFolder /O $targetFolder
	string lista, a_wave, listSE, SE_wave, destwave, SEwave
		lista = WaveList(wave1,";","")
		listSE = WaveList(wave2,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
		SE_wave = StringFromList(windex, listSE)
	labelwave = foldername + "xLabel"
	make /T /O $labelwave
	Do
		destwave = foldername + num2str(windex) +  "_" + a_wave
		SEwave = foldername + num2str(windex) + "_SE_" + a_wave
		make /O $destwave
			$destwave = NaN
		make /O $SEwave
			$SEwave = NaN
		wavestats /Q $a_wave
			$labelwave[windex] = destwave
			$destwave[windex] = V_avg
			if (isSE == 1)
				$SEwave[windex] = $SE_wave[0]
			else
				$SEwave[windex] = V_sdev / sqrt(V_npnts)
			endif
			if (windex == 0)
				Display $destwave vs $labelwave
			else
				AppendToGraph $destwave vs $labelwave
			endif
			ErrorBars $destwave Y,wave=($SEwave,$SEwave)
		windex+=1
		a_wave = StringFromList(windex, lista)
		SE_wave = StringFromList(windex, listSE)
	While(strlen(a_wave)!=0)
	variable wavenum = windex
		DeletePoints wavenum, 500, $labelwave
		moveWave $labelwave, $(targetFolder+":")
	windex=0
	a_wave = StringFromList(windex, lista)
	Do
		destwave = foldername + num2str(windex) +  "_" + a_wave
		SEwave = foldername + num2str(windex) + "_SE_" + a_wave
		DeletePoints wavenum, 500, $destwave
		DeletePoints wavenum, 500, $SEwave
		moveWave $destwave, $(targetFolder+":")
		moveWave $SEwave, $(targetFolder+":")	
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	ModifyGraph useNegRGB=1,usePlusRGB=1;DelayUpdate
	ModifyGraph hbFill=2,useNegPat=1;DelayUpdate
	ModifyGraph hBarNegFill=2,rgb=(0,0,0);DelayUpdate
	ModifyGraph plusRGB=(40000,40000,40000);DelayUpdate
	ModifyGraph negRGB=(40000,40000,40000)

end

macro addErrorBar(avg, SE)
	string avg="", SE=""
	prompt avg, "avgWave", popup wavelist ("*",";","")
	prompt SE, "SEWave", popup wavelist ("*",";","")
	ErrorBars $avg Y,wave=($SE,$SE)
end

macro addCategoryPlot(avg, x_label , isSE, SE)
	string avg="", SE="", x_label=""
	variable isSE = 1
	prompt avg, "avgWave"
	prompt x_label, "xLabel", popup wavelist ("*",";","")
	prompt isSE, "add SE? (0/1: no/yes)"
	prompt SE, "SEWave"

	String avg_wave, SE_wave, avg_list, SE_list
	variable windex=0
	avg_list = WaveList(avg, ";", "")
	SE_list = WaveList(SE, ";", "")
	avg_wave = StringFromList(windex, avg_list)
	if (isSE==1)
		SE_wave = StringFromList(windex, SE_list)
		Do
			AppendToGraph $avg_wave vs $x_label
			ModifyGraph useNegRGB=1,usePlusRGB=1,hbFill=2,rgb($avg_wave)=(0,0,0)
			ErrorBars $avg_wave Y,wave=($SE_wave,$SE_wave)
			windex+=1
			avg_wave = StringFromList(windex, avg_list)
			SE_wave = StringFromList(windex, SE_list)
		While(strlen(avg_wave)!=0 && strlen(SE_wave)!=0)
	else
		Do
			AppendToGraph $avg_wave vs $x_label
			ModifyGraph useNegRGB=1,usePlusRGB=1,hbFill=2,rgb($avg_wave)=(0,0,0)
			windex+=1
			avg_wave = StringFromList(windex, avg_list)
		While(strlen(avg_wave)!=0)
	endif
end



macro drawHBar(length, startX)
	variable length=1, startX=0
	prompt length, "length"
	prompt startX, "startX"
	variable stX, enX, stY, enY
	stX = startX
	enX = startX + length
	stY = 0.5
	enY = 0.5
	SetDrawEnv xcoord= bottom,linethick= 2.00
	DrawLine stX, stY, enX, enY
end


macro drawVBar(length, startY)
	variable length=300e-12, startY=-200e-12
	prompt length, "length"
	prompt startY, "startY"
	variable stX, enX, stY, enY
	stX = 0.5
	enX = 0.5
	stY = startY
	enY = startY + length
	SetDrawEnv ycoord= left,linethick= 2.00
	DrawLine stX, stY, enX, enY
end

function setTracesOffset([graphname, waves, type, Xoffset, Yval])
	String graphname, waves
	Variable type, Xoffset, Yval
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		graphname = ""; waves = "*";  
		type=0; Xoffset=0; Yval=0
		Prompt graphname, "Graph name (if \"\", top)"
		Prompt waves, "Wave or trace name"
		Prompt type, "type 0/1(set Xoffset/raster)"
		Prompt Xoffset, "X offset"
		Prompt Yval, "Y value"
		DoPrompt  "setTracesOffset", graphname, waves, type, Xoffset, Yval
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* setTracesOffset(graphname=\"" + graphname + "\", waves=\"" + waves + "\", type=" + num2str(type) + ", Xoffset=" + num2str(Xoffset) + ", Yval=" + num2str(Yval) + ")"
	endif

	string lista, a_wave, offsetStr, XoffsetDef, YoffsetDef
	variable windex=0
	variable bit=1		// bit=0: normal; 1: include contour traces; 2: omit hidden traces
	variable instance=0
	variable Yoffset
		lista = TraceNameList(graphname,";",bit)
		a_wave = StringFromList(windex, lista)
	Do
		offsetStr = StringByKey("offset(x)", TraceInfo(graphname, a_wave, instance), "=", ";", 0)
		SplitString /E="{(.*),(.*)}" offsetStr, XoffsetDef, YoffsetDef
		if (type == 0)
			ModifyGraph offset($a_wave)={Xoffset, str2num(YoffsetDef)}
		elseif (type == 1)
			ModifyGraph offset($a_wave)={str2num(XoffsetDef), Yval*windex}
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End

function setTracesColor([graphname, waves, type, stred, stgrn, stblu, enred, engrn, enblu])
	String graphname, waves
	Variable type, stred, stgrn, stblu, enred, engrn, enblu
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		graphname = ""; waves = "*";
		type=0; stred = 65535; stgrn = 0; stblu = 0;  enred = 0; engrn = 0; enblu = 65535; 
		Prompt graphname, "Graph name (if \"\", top)"
		Prompt waves, "Wave or trace name"
		Prompt type, "type 0/1/2 (gray/rainbow/value)"
		Prompt stred, "from red (0-65535)"
		Prompt stgrn, "green (0-65535)"
		Prompt stblu, "blue (0-65535)"
		Prompt enred, "to red (0-65535)"
		Prompt engrn, "green (0-65535)"
		Prompt enblu, "blue (0-65535)"
		DoPrompt  "setTracesColor", graphname, waves, type, stred, stgrn, stblu, enred, engrn, enblu
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* setTracesColor(graphname=\"" + graphname + "\", waves=\"" + waves + "\", type=" + num2str(type) + ", stred=" + num2str(stred) + ", stgrn=" + num2str(stgrn) + ", stblu=" + num2str(stblu) + ", enred=" + num2str(enred) + ", engrn=" + num2str(engrn) + ", enblu=" + num2str(enblu) + ")"
	endif

	string lista, a_wave
	variable windex=0, nTraces=0, wred, wgrn, wblu
	variable bit=1		// bit=0: normal; 1: include contour traces; 2: omit hidden traces
		lista = TraceNameList(graphname,";",bit)
		nTraces = ItemsInList(lista)
		if (nTraces < 2)
			nTraces = 2
		endif
		a_wave = StringFromList(windex, lista)
	windex = 0
	Do
		if (type == 0)
			wred = 65535 * windex / nTraces
			wgrn = wred
			wblu = wred
		elseif (type == 1)
			if (windex <= nTraces*1/3)
				wred = 65535
				wgrn = 65535 * windex / ((nTraces-1) * 1/3)
				wblu = 0
			elseif (windex <= nTraces*1/2)
				wred = 65535 - 65535 *  (windex - (nTraces-1) * 1/3) / ((nTraces-1) * 1/6)
				wgrn = 65535
				wblu = 0
			elseif (windex <= nTraces*2/3)
				wred = 0
				wgrn = 65535 - 65535 *  (windex - (nTraces-1) * 1/2) / ((nTraces-1) * 1/6)
				wblu = 65535 * (windex - (nTraces-1) * 1/2) / ((nTraces-1) * 1/6)
			elseif (windex <= nTraces*5/6)
				wred = 19456 * (windex - (nTraces-1) * 2/3) / ((nTraces-1) * 1/6)
				wgrn = 0
				wblu = 65535 - 32000 *  (windex - (nTraces-1) * 2/3) / ((nTraces-1) * 1/6)
			else
				wred = 19456 + 17264 * (windex - (nTraces-1) * 5/6) / ((nTraces-1) * 1/6)
				wgrn = 0
				wblu = 33535 + 32000 * (windex - (nTraces-1) * 5/6) / ((nTraces-1) * 1/6)
			endif
		else
			wred = stred + (enred - stred) * windex / (nTraces-1)
			wgrn = stgrn + (engrn - stgrn) * windex / (nTraces-1)
			wblu = stblu + (enblu - stblu) * windex / (nTraces-1)
		endif
		ModifyGraph rgb($a_wave)=(wred, wgrn, wblu)
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End