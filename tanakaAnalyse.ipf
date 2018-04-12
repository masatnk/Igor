#pragma rtGlobals=1		// Use modern global access method.


menu  "tanakaAnalyse"
	submenu "Electrophysiology"
		"PnSubtraction"
		"IVSubtraction"
		"spontAnalysis"
		"rampAnalysis"
		"PSCcharge"
		"extractAP"
		"extractMinis"
		"calcISI"
		"analyzeSpikes"
		"analyzeBurst"
	end
	submenu "Receptive Field"
		"drawSpikeRF"
		"drawEPSPpeakRF"
		"drawSpikeRFspot"
		"drawEPSPRFspot"
	end
	submenu "Feedback Inhibition"
		"makeTemplates"
		"anaReciprocal"
		"makeDistanceMatrix"
		"calcInh_population"
		"calcInh_single"
		"calcBlockInh_population"
		"calcInhWithAllBNconditions"
		"calcInhWithSquareStims"
		"calcInhPatternedStim"
		"calcInhVibSquare"
	end
	submenu "Statistics"
		"templateMatching"
		"calcEntropy"
		"calcProb"
		"transToProb"
	end
end

/////////////////////////////////////////// Receptive Field ///////////////////////////////////////////////////

function drawSpikeRF([folderprefix, waves, thres, dur, durOffset, px])
	String folderprefix, waves
	Variable thres, dur, durOffset, px
	if (dur == 0)		// if (row == null) : so there was no input
		folderprefix="FB"; waves="GHGC*1";
		thres=-20e-3; dur=1; durOffset=1; px=10;
		Prompt folderprefix, "folder prefix(prefix_D*_**)"
		Prompt waves, "spike wave name"
		Prompt thres, "spike threshold"
		Prompt dur, "spike count window"
		Prompt durOffset, "spike count from"
		Prompt px, "px per bar"
		DoPrompt  "drawSpikeRF", folderprefix, waves, thres, dur, durOffset, px
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*drawSpikeRF(folderprefix=\"" + folderprefix + "\", waves=\"" + waves + "\", thres=" + num2str(thres) + ", dur=" + num2str(dur)+ ", durOffset=" + num2str(durOffset) + ", px=" + num2str(px) + ")"
	endif
	
	string lista, a_wave, targetname, targetFolder, RFprefix, RFname, fDindexStr, fPindexStr
	variable findex, fDindex, fDangle, fPindex, windex, pxOffset, pxLength, i 
	variable fDnum, fPnum, sttime, entime
	RFprefix ="SpikeRF"
	fDnum = 8
	fPnum = 11
	pxOffset = 0
	pxLength = 110

	setDataFolder root:
	findex = 0
	Do
		if (findex == 0)
			fDindex = 1
			fDindexStr = "1"
		elseif (findex == 1)
			fDindex = 2
			fDindexStr = "2"
		elseif (findex == 2)
			fDindex = 3
			fDindexStr = "3"
		elseif (findex == 3)
			fDindex = 4
			fDindexStr = "4"
		elseif (findex == 4)
			fDindex = 6
			fDindexStr = "6"
		elseif (findex == 5)
			fDindex = 7
			fDindexStr = "7"
		elseif (findex == 6)
			fDindex = 8
			fDindexStr = "8"
		elseif (findex == 7)
			fDindex = 9
			fDindexStr = "9"
		endif

		fPindex = 0
		Do
			if (fPindex == 0)
				fPindexStr = "01"
			elseif (fPindex == 1)
				fPindexStr = "02"
			elseif (fPindex == 2)
				fPindexStr = "03"
			elseif (fPindex == 3)
				fPindexStr = "04"
			elseif (fPindex == 4)
				fPindexStr = "05"
			elseif (fPindex == 5)
				fPindexStr = "06"
			elseif (fPindex == 6)
				fPindexStr = "07"
			elseif (fPindex == 7)
				fPindexStr = "08"
			elseif (fPindex == 8)
				fPindexStr = "09"
			elseif (fPindex == 9)
				fPindexStr = "10"
			elseif (fPindex == 10)
				fPindexStr = "11"
			endif
			sttime = durOffset + fPindex*0.1
			entime = sttime + dur
			targetFolder = "root:" + folderprefix + "_D" + fDindexStr + "_p" + fPindexStr
			if (DataFolderExists(targetFolder))
				setDataFolder root:
				RFname = RFprefix + fDindexStr
				wave RF = $RFname
				if (!waveExists(RF))
					Make /O /N=(pxLength, pxLength) $RFname
					wave RF = $RFname
					RF = 0
				endif
				setDataFolder $targetFolder
				windex = 0
				lista = WaveList(waves,";","")
				a_wave = StringFromList(windex, lista)
				Do
					wave a = $a_wave
					if (waveExists(a) == 0)
						print "not exist such a wave at " + targetFolder
						abort
					endif
					findlevels /Q/R=(sttime, entime)  a, thres
					RF[fPindex*px+pxOffset-5, (fPindex+1)*px+pxOffset-1-5] += (V_LevelsFound / 2)
					windex += 1
					a_wave = StringFromList(windex, lista)
				While(strlen(a_wave)!=0)
				RF[fPindex*px+pxOffset-5, (fPindex+1)*px+pxOffset-1-5] /= windex
			endif
			fPindex +=1
		While ( fPindex < fPnum)
		findex +=1
	While (findex < fDnum)

	pxLength = 156
	variable pxEnd = 0
	setDataFolder root:
	RFname = "RFspike"
	Make /O /N=(pxLength, pxLength) $RFname
	wave RF = $RFname
	lista = WaveList(RFprefix+"*",";","")
	windex = 0
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave at " + targetFolder
			abort
		endif
		if (str2num(a_wave[7]) == 1)
			fDangle = 135
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[7]) == 2)
			fDangle = 90
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[7]) == 3)
			fDangle = 45
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[7]) == 4)
			fDangle = 180
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[7]) == 6)
			fDangle = 0
			pxOffset =23
			pxEnd  = 132
		elseif (str2num(a_wave[7]) == 7)
			fDangle = 225
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[7]) == 8)
			fDangle = 270
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[7]) == 9)
			fDangle = 315
			pxOffset = 0
			pxEnd  = 155
		endif
		imageRotate /A=(fDangle) a
		wave rotated = $("M_RotatedImage")
		RF[pxOffset,pxEnd][pxOffset,pxEnd] += rotated[p-pxOffset][q-pxOffset]
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	RF /= windex
end



function drawEPSPpeakRF([folderprefix, waves, coef, restdur, dur, durOffset, px])
	String folderprefix, waves
	Variable coef, restdur, dur, durOffset, px
	if (dur == 0)		// if (row == null) : so there was no input
		folderprefix="FB"; waves="GHGC*1";
		coef=50; dur=1; durOffset=1; restdur=1; px=10;
		Prompt folderprefix, "folder prefix(prefix_D*_**)"
		Prompt waves, "EPSP wave name"
		Prompt coef, "Box smooth coef"
		Prompt restdur, "EPSP rest window"
		Prompt dur, "EPSP peak window"
		Prompt durOffset, "EPSP from"
		Prompt px, "px per bar"
		DoPrompt  "drawEPSPpeakRF", folderprefix, waves, coef, restdur, dur, durOffset, px
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*drawEPSPpeakRF(folderprefix=\"" + folderprefix + "\", waves=\"" + waves + "\", coef=" + num2str(coef) + ", restdur=" + num2str(restdur) +  ", dur=" + num2str(dur) +  ", durOffset=" + num2str(durOffset) + ", px=" + num2str(px) + ")"
	endif
	
	string lista, a_wave, targetname, targetFolder, RFprefix, RFname, fDindexStr, fPindexStr
	variable findex, fDindex, fDangle, fPindex, windex, pxOffset, pxLength
	variable fDnum, fPnum, sttime, entime, reststtime, restentime, restVm, peakVm
	RFprefix ="EPSPpeakRF"
	fDnum = 8
	fPnum = 11
	pxOffset = 0
	pxLength = 110

	setDataFolder root:
	findex = 0
	Do
		if (findex == 0)
			fDindex = 1
			fDindexStr = "1"
		elseif (findex == 1)
			fDindex = 2
			fDindexStr = "2"
		elseif (findex == 2)
			fDindex = 3
			fDindexStr = "3"
		elseif (findex == 3)
			fDindex = 4
			fDindexStr = "4"
		elseif (findex == 4)
			fDindex = 6
			fDindexStr = "6"
		elseif (findex == 5)
			fDindex = 7
			fDindexStr = "7"
		elseif (findex == 6)
			fDindex = 8
			fDindexStr = "8"
		elseif (findex == 7)
			fDindex = 9
			fDindexStr = "9"
		endif

		fPindex = 0
		Do
			if (fPindex == 0)
				fPindexStr = "01"
			elseif (fPindex == 1)
				fPindexStr = "02"
			elseif (fPindex == 2)
				fPindexStr = "03"
			elseif (fPindex == 3)
				fPindexStr = "04"
			elseif (fPindex == 4)
				fPindexStr = "05"
			elseif (fPindex == 5)
				fPindexStr = "06"
			elseif (fPindex == 6)
				fPindexStr = "07"
			elseif (fPindex == 7)
				fPindexStr = "08"
			elseif (fPindex == 8)
				fPindexStr = "09"
			elseif (fPindex == 9)
				fPindexStr = "10"
			elseif (fPindex == 10)
				fPindexStr = "11"
			endif
			sttime = durOffset + fPindex*0.1
			entime = sttime + dur
			restentime = sttime
			reststtime = restentime - restdur
			targetFolder = "root:" + folderprefix + "_D" + fDindexStr + "_p" + fPindexStr
			if (DataFolderExists(targetFolder))
				setDataFolder root:
				RFname = RFprefix + fDindexStr
				wave RF = $RFname
				if (!waveExists(RF))
					Make /O /N=(pxLength, pxLength) $RFname
					wave RF = $RFname
					RF = 0
				endif
				setDataFolder $targetFolder
				windex = 0
				lista = WaveList(waves,";","")
				a_wave = StringFromList(windex, lista)
				wave a = $a_wave
				Do
					if (waveExists(a) == 0)
						print "not exist such a wave at " + targetFolder
						abort
					endif
					string cmd = "smoothWave(\"" + a_wave +  "\",\"s\",0,0,2,0," + num2str(coef) + "," + num2str(coef) + ",2,0)"
					Execute cmd
					wave a = $("s"+a_wave)
					wavestats /Q /R=(reststtime, restentime) a
					restVm = V_avg
					wavestats /Q /R=(sttime, entime) a
					peakVm = V_max
					RF[fPindex*px+pxOffset-5, (fPindex+1)*px+pxOffset-1-5] += peakVm - restVm
					windex += 1
					a_wave = StringFromList(windex, lista)
				While(strlen(a_wave)!=0)
				RF[fPindex*px+pxOffset-5, (fPindex+1)*px+pxOffset-1-5] /= windex
			endif
			fPindex +=1
		While ( fPindex < fPnum)
		findex +=1
	While (findex < fDnum)

	pxLength = 156
	variable pxEnd = 0
	setDataFolder root:
	RFname = "RF_EPSPpeak"
	Make /O /N=(pxLength, pxLength) $RFname
	wave RF = $RFname
	lista = WaveList(RFprefix+"*",";","")
	windex = 0
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave at " + targetFolder
			abort
		endif
		if (str2num(a_wave[10]) == 1)
			fDangle = 135
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[10]) == 2)
			fDangle = 90
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[10]) == 3)
			fDangle = 45
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[10]) == 4)
			fDangle = 180
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[10]) == 6)
			fDangle = 0
			pxOffset =23
			pxEnd  = 132
		elseif (str2num(a_wave[10]) == 7)
			fDangle = 225
			pxOffset = 0
			pxEnd  = 155
		elseif (str2num(a_wave[10]) == 8)
			fDangle = 270
			pxOffset = 23
			pxEnd  = 132
		elseif (str2num(a_wave[10]) == 9)
			fDangle = 315
			pxOffset = 0
			pxEnd  = 155
		endif
		imageRotate /A=(fDangle) a
		wave rotated = $("M_RotatedImage")
		RF[pxOffset,pxEnd][pxOffset,pxEnd] += rotated[p-pxOffset][q-pxOffset]
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	RF /= windex
end



function drawSpikeRFspot([folderprefix, waves, thres, dur, durOffset, px])
	String folderprefix, waves
	Variable thres, dur, durOffset, px
	if (dur == 0)		// if (row == null) : so there was no input
		folderprefix="Sp"; waves="GHGC*1";
		thres=-20e-3; dur=1; durOffset=1; px=10;
		Prompt folderprefix, "folder prefix(prefix_D*_**)"
		Prompt waves, "spike wave name"
		Prompt thres, "spike threshold"
		Prompt dur, "spike count window"
		Prompt durOffset, "spike count from"
		Prompt px, "px per 100um"
		DoPrompt  "drawSpikeRFspot", folderprefix, waves, thres, dur, durOffset, px
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*drawSpikeRFspot(folderprefix=\"" + folderprefix + "\", waves=\"" + waves + "\", thres=" + num2str(thres) + ", dur=" + num2str(dur) + ", durOffset=" + num2str(durOffset) + ", px=" + num2str(px) + ")"
	endif
	
	string lista, a_wave, targetname, targetFolder, RFprefix, RFname, RFdifname, fDindexStr
	variable findex, fDindex, fDangle, windex, pxOffset, pxLength
	variable fDnum, sttime, entime
	RFprefix ="SpikeRFspot"
	fDnum = 11
	pxOffset = 0
	pxLength = 11*px
	durOffset = 1

	setDataFolder root:
	RFname = RFprefix
	Make /O /N=(fDnum) $RFname
	wave RF = $RFname
	RF = 0
	findex = 0
	Do
		if (findex == 0)
			fDindex = 1
			fDindexStr = "100"
		elseif (findex == 1)
			fDindex = 2
			fDindexStr = "200"
		elseif (findex == 2)
			fDindex = 3
			fDindexStr = "300"
		elseif (findex == 3)
			fDindex = 4
			fDindexStr = "400"
		elseif (findex == 4)
			fDindex = 5
			fDindexStr = "500"
		elseif (findex == 5)
			fDindex = 6
			fDindexStr = "600"
		elseif (findex == 6)
			fDindex = 7
			fDindexStr = "700"
		elseif (findex == 7)
			fDindex = 8
			fDindexStr = "800"
		elseif (findex == 8)
			fDindex = 9
			fDindexStr = "900"
		elseif (findex == 9)
			fDindex = 10
			fDindexStr = "1000"
		elseif (findex == 10)
			fDindex = 11
			fDindexStr = "1100"
		endif

			sttime = durOffset
			entime = sttime + dur
			targetFolder = "root:" + folderprefix + fDindexStr
			if (DataFolderExists(targetFolder))
				setDataFolder $targetFolder
				windex = 0
				lista = WaveList(waves,";","")
				a_wave = StringFromList(windex, lista)
				Do
					wave a = $a_wave
					if (waveExists(a) == 0)
						print "not exist such a wave at " + targetFolder
						abort
					endif
					findlevels /Q/R=(sttime, entime)  a, thres
					RF[findex] += (V_LevelsFound / 2)
					windex += 1
					a_wave = StringFromList(windex, lista)
				While(strlen(a_wave)!=0)
				RF[findex] /= windex
			else
				RF[findex] = NaN
			endif
		findex +=1
	While (findex < fDnum)

	setDataFolder root:
	RFname = RFprefix
	RFdifname = RFprefix + "_Dif"
	variable nextindex = 0, lastindex = 0, flagFirst=1
	Make /O /N=(fDnum) $RFdifname
	wave RF = $RFname
	wave RFdif = $RFdifname
	findex=0
	Do
		if (flagFirst)
			nextindex = findex
			if (numtype(RF[nextindex]) == 2)
				Do
					nextindex += 1
				While (numtype(RF[nextindex]) == 2 && nextindex < fDnum)
			endif
			if (numtype(RF[nextindex]) == 2)
				break
			else
				RFdif[nextindex] = RF[nextindex] 
				findex = nextindex
				lastindex = nextindex
			endif
			flagFirst = 0
		else
			nextindex = findex
			if (numtype(RF[nextindex]) == 2)
				Do
					nextindex += 1
				While (numtype(RF[nextindex]) == 2 && nextindex < fDnum)
			endif
			if (numtype(RF[nextindex]) == 2)
				break
			else
				RFdif[nextindex] = (RF[nextindex] - RF[lastindex]) / ((nextindex+1)^2 - (lastindex+1)^2)
				findex = nextindex
				lastindex = nextindex				
			endif
		endif
		findex +=1
	While(findex < fDnum)
	
	pxLength = 156
	variable center = pxLength/2 - 0.5
	RFname = "RFspike_spot"
	Make /O /N=(pxLength, pxLength) $RFname
	wave RF = $RFname
	variable rindex, cindex, radius, d
	findex = fDnum
	Do
		if (numtype(RFdif[findex]) != 2)
			radius = (findex + 1) * px / 2
			rindex=0
			Do
				cindex = 0
				Do
					d = sqrt((rindex - center)^2 + (cindex - center)^2)
					if (d <= radius)
						RF[rindex][cindex] = RFdif[findex]
					endif
					cindex += 1
				While (cindex < pxLength)
				rindex += 1
			While(rindex < pxLength)
		endif
		findex -= 1
	While(findex >= 0)
end



function drawEPSPRFspot([folderprefix, waves, coef, restdur, dur, durOffset, px])
	String folderprefix, waves
	Variable coef, restdur, dur, durOffset, px
	if (dur == 0)		// if (row == null) : so there was no input
		folderprefix="Sp"; waves="GHGC*1";
		coef=50; dur=1; durOffset=1; restdur=1; px=10;
		Prompt folderprefix, "folder prefix(prefix_D*_**)"
		Prompt waves, "EPSP wave name"
		Prompt coef, "Box smooth coef"
		Prompt restdur, "EPSP rest window"
		Prompt dur, "EPSP peak window"
		Prompt durOffset, "EPSP from"
		Prompt px, "px per 100um"
		DoPrompt  "drawEPSPRFspot", folderprefix, waves, coef, restdur, dur, durOffset, px
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*drawEPSPRFspot(folderprefix=\"" + folderprefix + "\", waves=\"" + waves + "\", coef=" + num2str(coef) + ", restdur=" + num2str(restdur) +  ", dur=" + num2str(dur) +  ", durOffset=" + num2str(durOffset) + ", px=" + num2str(px) + ")"
	endif
	
	string lista, a_wave, targetname, targetFolder, RFprefix, RFname, RFdifname, fDindexStr
	variable findex, fDindex, fDangle, windex, pxOffset, pxLength, reststtime, restentime
	variable fDnum, sttime, entime, restVm, peakVm
	RFprefix ="EPSP_RFspot"
	fDnum = 11
	pxOffset = 0
	pxLength = 11*px
	durOffset = 1

	setDataFolder root:
	RFname = RFprefix
	Make /O /N=(fDnum) $RFname
	wave RF = $RFname
	RF = 0
	findex = 0
	Do
		if (findex == 0)
			fDindex = 1
			fDindexStr = "100"
		elseif (findex == 1)
			fDindex = 2
			fDindexStr = "200"
		elseif (findex == 2)
			fDindex = 3
			fDindexStr = "300"
		elseif (findex == 3)
			fDindex = 4
			fDindexStr = "400"
		elseif (findex == 4)
			fDindex = 5
			fDindexStr = "500"
		elseif (findex == 5)
			fDindex = 6
			fDindexStr = "600"
		elseif (findex == 6)
			fDindex = 7
			fDindexStr = "700"
		elseif (findex == 7)
			fDindex = 8
			fDindexStr = "800"
		elseif (findex == 8)
			fDindex = 9
			fDindexStr = "900"
		elseif (findex == 9)
			fDindex = 10
			fDindexStr = "1000"
		elseif (findex == 10)
			fDindex = 11
			fDindexStr = "1100"
		endif

			sttime = durOffset
			entime = sttime + dur
			restentime = sttime
			reststtime = restentime - restdur
			targetFolder = "root:" + folderprefix + fDindexStr
			if (DataFolderExists(targetFolder))
				setDataFolder $targetFolder
				windex = 0
				lista = WaveList(waves,";","")
				a_wave = StringFromList(windex, lista)
				Do
					wave a = $a_wave
					if (waveExists(a) == 0)
						print "not exist such a wave at " + targetFolder
						abort
					endif
					string cmd = "smoothWave(\"" + a_wave +  "\",\"s\",0,0,2,0," + num2str(coef) + "," + num2str(coef) + ",2,0)"
					Execute cmd
					wave a = $("s"+a_wave)
					wavestats /Q /R=(reststtime, restentime) a
					restVm = V_avg
					wavestats /Q /R=(sttime, entime) a
					peakVm = V_max

					RF[findex] += peakVm - restVm
					windex += 1
					a_wave = StringFromList(windex, lista)
				While(strlen(a_wave)!=0)
				RF[findex] /= windex
			else
				RF[findex] = NaN
			endif
		findex +=1
	While (findex < fDnum)

	setDataFolder root:
	RFname = RFprefix
	RFdifname = RFprefix + "_Dif"
	variable nextindex = 0, lastindex = 0, flagFirst=1
	Make /O /N=(fDnum) $RFdifname
	wave RF = $RFname
	wave RFdif = $RFdifname
	findex=0
	Do
		if (flagFirst)
			nextindex = findex
			if (numtype(RF[nextindex]) == 2)
				Do
					nextindex += 1
				While (numtype(RF[nextindex]) == 2 && nextindex < fDnum)
			endif
			if (numtype(RF[nextindex]) == 2)
				break
			else
				RFdif[nextindex] = RF[nextindex] 
				findex = nextindex
				lastindex = nextindex
			endif
			flagFirst = 0
		else
			nextindex = findex
			if (numtype(RF[nextindex]) == 2)
				Do
					nextindex += 1
				While (numtype(RF[nextindex]) == 2 && nextindex < fDnum)
			endif
			if (numtype(RF[nextindex]) == 2)
				break
			else
				RFdif[nextindex] = (RF[nextindex] - RF[lastindex]) / ((nextindex+1)^2 - (lastindex+1)^2)
				findex = nextindex
				lastindex = nextindex				
			endif
		endif
		findex +=1
	While(findex < fDnum)
	
	pxLength = 156
	variable center = pxLength/2 - 0.5
	RFname = "RF_EPSP_spot"
	Make /O /N=(pxLength, pxLength) $RFname
	wave RF = $RFname
	variable rindex, cindex, radius, d
	findex = fDnum
	Do
		if (numtype(RFdif[findex]) != 2)
			radius = (findex + 1) * px / 2
			rindex=0
			Do
				cindex = 0
				Do
					d = sqrt((rindex - center)^2 + (cindex - center)^2)
					if (d <= radius)
						RF[rindex][cindex] = RFdif[findex]
					endif
					cindex += 1
				While (cindex < pxLength)
				rindex += 1
			While(rindex < pxLength)
		endif
		findex -= 1
	While(findex >= 0)
end

/////////////////////////////////////////// Electrophysiology ///////////////////////////////////////////////////

macro PnSubtraction (wave1, wave2, sttime, entime, destname, dpn, printToCmd)
	String wave1="B*_2", wave2="leak*", destname="Pn_"
	Variable sttime=0.1, entime=0.6, dpn=3, printToCmd = 0
	Prompt wave1, "waveRaw name"
	Prompt wave2, "waveLeak name"
	Prompt sttime, "RANGE from"
	Prompt entime, "to"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Prompt printToCmd, "Print? 0/1 (No/Yes)"
	
	string list1, list2, a_wave, b_wave, destwave, awave, bwave
		list1 = WaveList(wave1,";","")
		list2 = WaveList(wave2,";","")
		variable windex=0
		a_wave = StringFromList(windex, list1)
		b_wave = StringFromList(windex, list2)
	Do
		destwave = destname + a_wave
		Duplicate /O /R=(sttime,entime) $a_wave $destwave
		
		setScale /P x (leftx($a_wave)), (deltax($a_wave)), "s", $destwave
		$destwave = $destwave - $b_wave
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif

		windex+=1
		a_wave = StringFromList(windex, list1)
		b_wave = StringFromList(windex, list2)
	While(strlen(a_wave)!=0 && strlen(b_wave)!=0)
endmacro

macro IVSubtraction (waveIV, waveTemp, tempAmp, IVfrom, IVdV, IVnum, sttime, entime, strest, enrest)
	String waveIV="00*Im*", waveTemp="Avg*"
	Variable tempAmp=-20, IVfrom=-30, IVdV=10, IVnum=11,  sttime=0, entime=0.8, strest=0, enrest=0.1
	Prompt waveIV, "wave IV"
	Prompt waveTemp, "wave Temp (1 wave)"
	Prompt tempAmp, "Temp Amp (mV)"
	Prompt IVfrom, "IV from (mV)"
	Prompt IVdV, "IV dV (mV)"
	Prompt IVnum, "IV trace num"
	Prompt sttime, "RANGE from"
	Prompt entime, "to"
	Prompt strest, "resting from"
	Prompt enrest, "to"
	
	string listIV, listTemp, IV_wave, temp_wave, destwave, awave, bwave, leakname, leakwave, destname
	destname = "IVPn_"
	leakname = "leak"
		listIV = WaveList(waveIV,";","")
		listTemp = WaveList(waveTemp,";","")
	variable windex, ratio, nindex, dpn
	windex = 0
		IV_wave = StringFromList(windex, listIV)
		temp_wave = StringFromList(windex, listTemp)
	dpn = 3
	nindex = 0
	Do
		ratio =  (IVdV * nindex + IVfrom) / tempAmp
		leakwave = leakname + num2str(nindex)
		multiplyWave(temp_wave, leakwave, dpn, ratio, 0 ,0,-inf,inf,strest,enrest)
			//  eliminating the resting current (subtract its average)
		nindex += 1
	While(nindex < IVnum)
	
	leakwave = leakname + "*"
	PnSubtraction(waveIV,leakwave,sttime,entime,"Pn_",3,0)
endmacro


macro makeTemplates (wave1, waveTemp, destname, normMethod, sttime, entime, RestSttime, RestEntime, dpn, printToCmd)
	String wave1="Pn*", waveTemp="Avg*", destname="Temp_"
	Variable dpn=3, printToCmd = 1, sttime=0.101, entime=0.103, normMethod=1, RestSttime=0.05, RestEntime=0.1
	Prompt wave1, "waveRaw name"
	Prompt waveTemp, "waveTempRaw name"
	Prompt destname, "destination name"
	Prompt normMethod, "normMethod 0/1/2 (Avg/Min/Max)"
	Prompt sttime, "Range from"
	Prompt entime, "to"
	Prompt RestSttime, "Resting Range from"
	Prompt RestEntime, "to"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Prompt printToCmd, "Print? 0/1 (No/Yes)"
	
	string list1, list2, listTemp, a_wave, b_wave,  destwave, awave, bwave
		list1 = WaveList(wave1,";","")
		listTemp = WaveList(waveTemp,";","")
		variable windex=0
		a_wave = StringFromList(windex, list1)
		waveTemp = StringFromList(windex, listTemp)
	Do
		subtract(a_wave,"sub",NaN,0,RestSttime,RestEntime,0,3)
		windex+=1
		a_wave = StringFromList(windex, list1)
	While(strlen(a_wave)!=0)
		list2 = WaveList("sub*",";","")
		windex=0
		b_wave = StringFromList(windex, list2)
		variable num
	Do
		destwave = destname + b_wave
		Duplicate /O $waveTemp $destwave
		wavestats /Q /R=(sttime, entime) $b_wave
		if (normMethod == 0)
			num = V_avg
		endif
		if (normMethod == 1)
			num = V_min
		endif
		if (normMethod == 2)
			num = V_max
		endif
		wavestats /Q /R=(sttime, entime) $destwave
		if (normMethod == 0)
			num = num / V_avg
		endif
		if (normMethod == 1)
			num = num / V_min
		endif
		if (normMethod == 2)
			num = num / V_max
		endif
		multiplyWave(destwave, "", 3, num, 2, 0, -inf, inf, RestSttime, RestEntime)
//multiplyWave (wave1, wavedest, dpn, num, offset, val, sttime, entime, avgsttime, avgentime)

		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif

		if(printToCmd)
			print "* ", destwave, " multiplied by ", num
		endif
		windex+=1
		b_wave = StringFromList(windex, list2)
	While(strlen(b_wave)!=0)

endmacro

macro spontAnalysis (wave1, cross, wave2)
	string wave1="*4", wave2=""
	variable cross=0
	prompt wave1, "wave1Name"
	prompt cross, "crosscorrelogram? (1/0 : y/n)"
	prompt wave2, "wave2Name"

	Display as "Auto"
	string lista , a_wave, destwave, awave
		lista = WaveList(wave1,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
	Do
		if(numpnts($a_wave) == 300000)
			destwave = "C_GLC_" + a_wave + num2str(windex) + "_1"
			duplicate /O /R=(0,6) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_GLC_" + a_wave + num2str(windex) + "_2"
			duplicate /O /R=(6,12) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_GLC_" + a_wave + num2str(windex) + "_3"
			duplicate /O /R=(12,18) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_GLC_" + a_wave + num2str(windex) + "_4"
			duplicate /O /R=(18,24) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_GLC_" + a_wave + num2str(windex) + "_5"
			duplicate /O /R=(24,30) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			wave1 = "C_GLC*"
		else
			destwave = "C_GLC_" + a_wave + num2str(windex)
			duplicate /O $a_wave $destwave
			wave1 = "C_GLC*"
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	displayCrosscorrelo(wave1=(wave1),wave2=(wave1),winrange=5000,step=10,sttime=0,entime=0,destname="Auto",dpn=2)
	averageWaves("Correlo*Auto",-5,5,"Auto",2)
		lista = WaveList("Correlo*Auto",";","")
		windex=0
		a_wave = StringFromList(windex, lista)
	Do
		ModifyGraph rgb($a_wave)=(56576,56576,56576);DelayUpdate
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
		if (cross)
			Display as "Cross"
				lista = WaveList(wave2,";","")
				windex=0
				a_wave = StringFromList(windex, lista)
				Do
					if(numpnts($a_wave) == 300000)
						destwave = "C_Mb_" + a_wave + num2str(windex) + "_1"
						duplicate /O /R=(0,6) $a_wave $destwave
						setScale x, 0, 6, "s", $destwave
						destwave = "C_Mb_" + a_wave + num2str(windex) + "_2"
						duplicate /O /R=(6,12) $a_wave $destwave
						setScale x, 0, 6, "s", $destwave
						destwave = "C_Mb_" + a_wave + num2str(windex) + "_3"
						duplicate /O /R=(12,18) $a_wave $destwave
						setScale x, 0, 6, "s", $destwave
						destwave = "C_Mb_" + a_wave + num2str(windex) + "_4"
						duplicate /O /R=(18,24) $a_wave $destwave
						setScale x, 0, 6, "s", $destwave
						destwave = "C_Mb_" + a_wave + num2str(windex) + "_5"
						duplicate /O /R=(24,30) $a_wave $destwave
						setScale x, 0, 6, "s", $destwave
						wave2 = "C_Mb_*"
					else
						destwave = "C_Mb_" + a_wave + num2str(windex)
						duplicate /O $a_wave $destwave
						wave2 = "C_Mb_*"
					endif
					windex+=1
					a_wave = StringFromList(windex, lista)
				While(strlen(a_wave)!=0)
			displayCrosscorrelo(wave1,wave2,5000,10,0,0,"Cross",2)
			averageWaves("Correlo*Cross",-5,5,"Cross",2)
			lista = WaveList("Correlo*Cross",";","")
				windex=0
				a_wave = StringFromList(windex, lista)
			Do
				ModifyGraph rgb($a_wave)=(56576,56576,56576);DelayUpdate
				windex+=1
				a_wave = StringFromList(windex, lista)
			While(strlen(a_wave)!=0)
			Display as "AutoMb"
				displayCrosscorrelo(wave2,wave2,5000,10,0,0,"AutoMb",2)
				averageWaves("Correlo*AutoMb",-5,5,"AutoMb",2)
				lista = WaveList("Correlo*AutoMb",";","")
				windex=0
				a_wave = StringFromList(windex, lista)
			Do
				ModifyGraph rgb($a_wave)=(56576,56576,56576);DelayUpdate
				windex+=1
				a_wave = StringFromList(windex, lista)
			While(strlen(a_wave)!=0)
		endif

	print "avgAuto : "
		printZeroCrossWidth("AvgAuto",0,5,0.05)
	if (cross)
		print "avgAutoMb : "
			printZeroCrossWidth("AvgAutoMb",0,5,0.05)
		print "avgCross : "
			printZeroCrossWidth("AvgCross",0,5,0.05)
	endif

	printPeak(wave1,0,0,0,0,"printPeak",100,0,1,1)
endmacro

macro rampAnalysis (wave1, wave2, destname)
	String wave1="B*7_1_4", wave2="B*9_1_4", destname="Igaba_"
	Prompt wave1, "wave1 name"
	Prompt wave2, "wave2 name"
	Prompt destname, "destname (wave1 minus wave2)"

	sum2Waves(wave1,wave2,destname,0,0,0,1,1)
	duplicate /O /R=(0.11, 0.17) Igaba_0, Igaba
	curvefit line  Igaba /D
	String text = "y = " + num2str(W_coef[0] * 1e12) + " + " + num2str(W_coef[1] * 1e12) + "x"
	display Igaba, fit_Igaba
	ModifyGraph rgb(Igaba)=(13056,13056,13056)
	TextBox/C/N=text0/F=0/M/H={0,3,10}/A=MC text
	print "* * * * * * * results * * * * * * *"
	print "* * * y(x=0) = ", W_coef[0], " A"
	print "* * * slope = ", W_coef[1], " S"
endmacro

macro anaReciprocal (wave1, wave2, destname)
	String wave1="AvgPn", wave2="AvgIca", destname="Pn_"
	Prompt wave1, "waveRaw name"
	Prompt wave2, "waveIca name"
	Prompt destname, "destination name"
	
	String subWave1 = "sub" + wave1
	makeTemplates(wave1,wave2,"Temp_",1,0.1,0.2,0,0.1,3,1)
		// make templates normalized for MIN between 0 - 2ms
	sum2Waves(subWave1,"Temp*","sumTemp_",0,-inf,inf,3,0)
		cumulatePlot("sumTemp*",0,0.1,0.3,1,0,"Std",3,1)
	print " * * Averaged Cumulative * * * * * * *"
		averageWave("sumTemp*",0,0,"sumTemp",3)
			cumulatePlot("AvgsumTemp",0,0.1,0.3,1,0,"AvgStd",3,1)
	print " * * Pn peak (Ica) * * * * * * *"
		printPeaks(wave1,0,0,0,0.09,0.11,0,0.1,1,1)
	print " * * Pn peak (IPSC) * * * * * * *"
		printPeaks("AvgsumTemp",0,0,1,0.1,0.3,0,0.1,1,1)
endmacro


macro PSCcharge (wave1, type, sttimeMode, entimeMode, sttimePeriod, entimePeriod, destname, line)
	String wave1="Avg*", destname="GloPost", type = "namual"
	variable line=0
	variable sttimeMode=0.45, entimeMode=0.5
	variable sttimePeriod=0.5, entimePeriod=0.7
	Prompt wave1, "waveRaw name"
	Prompt type, "baseline type", popup "avg;mode;"
	Prompt sttimeMode, "baseline from (s)"
	Prompt entimeMode, "to (s)"
	Prompt sttimePeriod, "period from (s)"
	Prompt entimePeriod, "to (s)"
	Prompt destname, "destination name"
	Prompt line, "0/1/2 (NO/left/right)"

	variable baseline

	printPercentile (wave1=wave1, percentile=0.5, stt=sttimeMode, ent=entimeMode, suffix=destname, step=0, kill=0, printToCmd=1)
	if (stringmatch(type, "mode"))
		baseline = K18
	endif
	if  (stringmatch(type, "avg"))
		baseline = K17
		print baseline
	endif
		
	if (line != 0)
		if (line == 2)
			SetDrawEnv ycoord= right;DelayUpdate
		else
			SetDrawEnv ycoord= left;DelayUpdate
		endif
		SetDrawEnv xcoord= bottom;DelayUpdate
		DrawLine sttimeMode, baseline, entimePeriod, baseline
	endif
		
	subtract(wave1,"sub", baseline, 1, sttimePeriod, entimePeriod,1,3)
	subtract(wave1,"r_sub", baseline, 1, sttimeMode, entimeMode,1,3)
		
	String subwave, rwave
		subwave = "sub" + wave1
		rwave = "r_sub" + wave1
	cumulatePlot(subwave,0,0,0,1,0,destname,3, 1)
	variable PSCcharge = K10
	string r_destname = destname + "_r"
	cumulatePlot(rwave,0,0,0,1,0,r_destname,3, 1)
	variable r_PSCcharge = K10
	print " * * * * * * * * * * * * * * * * * * * * * * * *"
	print " * PSCcharge : ", PSCcharge
	print " * baseline (", type ,"): ", baseline
	print " * ( - resting charge : ", r_PSCcharge, ")"
	print " *  = ", (PSCcharge - r_PSCcharge/(entimeMode - sttimeMode)*(entimePeriod - sttimePeriod))
	print " * * * * * * * * * * * * * * * * * * * * * * * *"	
	
endmacro


function extractAP([waves, type, sttime, entime, pol, thres, tempmatch, corrthres, dupst, dupen])
	String waves
	Variable type, sttime, entime, pol, thres, tempmatch, corrthres, dupst, dupen
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*_Vm*";
		type=2; sttime=-inf; entime=inf; pol=1; thres=15; tempmatch=0; corrthres=0.7; dupst=0; dupen=0
		Prompt waves, "wave name"
		Prompt type, "type 1,2,3 (val,dV/dt, x*SD)"
		Prompt sttime, "from (s)"
		Prompt entime, "to (s)"
		Prompt pol, "polarity 0/1 (neg/pos)"
		Prompt thres, "threshold (mV,V/s, x)"
		Prompt tempmatch, "Try template match? 1/0"
		Prompt corrthres, "correlation thres to accept as temp"
		Prompt dupst, "template sttime (say, -0.5ms)"
		Prompt dupen, "template entime  (say, 1ms)"
		DoPrompt  "extractAP", waves, type, sttime, entime, pol, thres, tempmatch, corrthres, dupst, dupen
		if (V_Flag)	// User canceled
			return -1
		endif
		print "extractAP(waves=\"" + waves + "\", type=" + num2str(type) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", pol=" + num2str(pol) + ", thres=" + num2str(thres) + ", tempmatch=" + num2str(tempmatch) + ", corrthres=" + num2str(corrthres) + ", dupst=" + num2str(dupst) + ", dupen=" + num2str(dupen) + ")"
	endif
	dupst /= 1000
	dupen /= 1000
	string lista, awave, diffwave, foundXwave, foundVwave, nAPwave, foundPXwave, foundPwave, targetname
	string listt, cwave, twave, graphname, gtext, foundClass, targetwave, classtext, tempwave, tempwaves
	string tempnumwave, unclasswave, raster
	variable foundN, findex, sampDur, flagNotAP, unclass_index, stt, ent, thresSD
	variable windex, normVal, tindex, rval, len_a, len_t
	sampDur = 4.53515e-05
	
	tempnumwave = "template_sampleN"
	diffwave = "differentiated"
	tempwaves = "tempwave*"
	if (type == 2)
		thres = thres * 1000
	elseif ( type == 3)	
		thresSD = thres
	endif
	windex=0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
	Do
		print windex, awave
		foundXwave = "AP_X_" + awave
		foundVwave = "AP_V_" + awave
		foundPXwave = "AP_PeakX_" + awave
		foundPwave = "AP_Peak_" + awave
		if (tempmatch == 1)
			foundClass = "AP_classified" + awave
		endif
		nAPwave = "AP_n_" + awave
		if (!waveExists($nAPwave))
			Make /O /N=0 $nAPwave
		endif
		if (type == 1)
			if (pol == 1)
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $awave, thres
			else
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $awave, thres
			endif
		elseif (type == 2)
				Duplicate /O $awave, $diffwave
				differentiate $diffwave
				Make /N=0 /O $foundXwave
			if (pol == 1)
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $diffwave, thres
			else
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $diffwave, thres
			endif
		elseif (type == 3)
			wavestats /Q $awave
			if (pol == 1)
				thres = V_avg + thresSD * V_sdev 
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $awave, thres
			else
				thres = V_avg - thresSD * V_sdev 
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $awave, thres
			endif
		endif
		foundN = V_levelsFound
		InsertPoints numpnts($nAPwave), 1, $nAPwave
		wave nAP = $nAPwave
		nAP[windex] = foundN
		if (foundN == 0)
			print "No spike found."
			windex+=1
			awave = StringFromList(windex, lista)
			if(waveExists($awave))
				continue
			else
				break
			endif
		endif
		if (V_flag == 2)
			Killwaves $foundXwave
		else
			Duplicate /O $foundXwave, $foundVwave
			Duplicate /O $foundXwave, $foundPXwave
			Duplicate /O $foundXwave, $foundPwave
			Duplicate /O $foundXwave, $foundClass
			wave Xwave = $foundXwave
			wave Vm = $foundVwave
			wave wPX = $foundPXwave
			wave wP = $foundPwave
			wave wClass = $foundClass
			unclass_index = 0
			wClass = -1
			wave a = $awave
			Vm[] = a(Xwave[p])
			findex = 0
			Do
				flagNotAP = 0 
				stt = Xwave[findex]
				ent = Xwave[findex]+0.001
				if (type == 2)
					if (pol == 1)
						findLevel /EDGE=2 /Q /R=(stt, ent) $diffwave, thres
					else
						findLevel /EDGE=1 /Q /R=(stt, ent) $diffwave, thres
					endif
				else
					if (pol == 1)
						findLevel /EDGE=2 /Q /R=(stt, ent) $awave, thres
					else
						findLevel /EDGE=1 /Q /R=(stt, ent) $awave, thres
					endif
				endif
				if (V_flag)
					ent = stt + 0.001
				else
					ent = V_LevelX
				endif
				wavestats /Q /R=(stt, ent) $awave
				if (pol == 1)
					wP[findex] = V_max
					wPX[findex] = V_maxloc
				else
					wP[findex] = V_min
					wPX[findex] = V_minloc
				endif
				if (tempmatch == 1 && dupst < 0 && dupen > 0)
					targetname = "APw_" + awave + "_" +  num2str(findex)
					Duplicate /O /R=(wPX[findex]+dupst, wPX[findex]+dupen) $awave, $targetname
					SetScale/P x 0,sampDur,"s", $targetname
					graphname = "tempmatch"
					if (waveexists($tempnumwave))
						wave tNw = $tempnumwave
					endif
					cwave = "col_" + targetname
					classtext = ""
					Duplicate /O $targetname, $cwave
					listt = WaveList(tempwaves,";","")
					len_t = ItemsInList(listt)
					tindex = 0
					twave = StringFromList(tindex, listt)
					if (!waveexists($tempnumwave))
						Display /N=$graphname $targetname
						modifyGraph rgb=(40000,40000,40000)
						DoWindow /F $graphname
						rval= Prompt_templateMatching(graphname, 0)
						if (rval == -1)		// Graph name error
							print "Graph name error."
							abort
						elseif (rval == 1)	// Ignore
							classtext = "user ignored " + targetname
							DoWindow /K $graphname
							unclasswave = "unclass_" + targetname + num2str(unclass_index)
							Rename $targetname, $unclasswave
							unclass_index += 1
							flagNotAP = 1
						elseif (rval == 2)	// Create
							tempwave = "tempwave_" + num2str(len_t)
							Duplicate /O $targetname, $tempwave
							wClass[windex] = len_t
							Insertpoints len_t, 1, tNw
							DoWindow /K $graphname
							Make /N=1 $tempnumwave
							wave tNw = $tempnumwave
							tNw[len_t] = 1
							len_t += 1
							classtext = "user made " + targetname + " as a template wave " + tempwave
						elseif (rval == 3)	// Kill
							DoWindow /K $graphname
							classtext = "user killed " + targetname
							Killwaves $targetname
							flagNotAP = 1
						elseif (rval == 4)	// Cancel
							print "user canceled."
							abort
						endif
					else
						Do 
							WaveStats /Q $twave
							normVal = V_rms * sqrt(V_npnts)
							WaveStats /Q $cwave
							normVal = normVal * V_rms * sqrt(V_npnts)
							Correlate $twave, $cwave
							wave tw = $twave
							wave cw = $cwave
							wave aw = $targetname
							cw /= normVal
							wavestats /Q $cwave
							if (corrthres <= V_max)
								tNw[tindex] += 1
								if (type != 1)
									tw = ( tw * (tNw[tindex] - 1) + aw ) / tNw[tindex]
								endif
								wClass[windex] = tindex
								classtext = "classified " + targetname + " as a template wave " + twave + " (corrthres: " + num2str(corrthres) + " <= corr: " +  num2str(V_max) + " )"
							else
								Display /N=$graphname $twave 
								AppendtoGraph $targetname
								modifyGraph rgb($targetname)=(20000,20000,20000)
								DoWindow /F $graphname
								gtext = "correlation : " + num2str(V_max) + " < thers ( " + num2str(corrthres) + " )"
								DrawText /W=$graphname 0.1, 0.8, gtext
								rval= Prompt_templateMatching(graphname, 1)
								if (rval == -1)		// Graph name error
									print "Graph name error."
									abort
								elseif (rval == 0)	// Match
									tNw[tindex] += 1
									if (type != 2)
										tw = ( tw * (tNw[tindex] - 1) + aw ) / tNw[tindex]
									endif
									wClass[windex] = tindex
									DoWindow /K $graphname
									classtext = "user classified " + targetname + " as a template wave " + twave
									break
								elseif (rval == 1)	// Non-Match
									classtext = "user ignored " + targetname
									DoWindow /K $graphname
									unclasswave = "unclass_" + targetname + num2str(unclass_index)
									Rename $targetname, $unclasswave
									flagNotAP = 1
								elseif (rval == 2)	// Create
									tempwave = "tempwave_" + num2str(len_t)
									Duplicate /O $targetname, $tempwave
									wClass[windex] = len_t
									Insertpoints len_t, 1, tNw
									tNw[len_t] = 1
									len_t += 1
									DoWindow /K $graphname
									classtext = "user made " + targetname + " as a template wave " + tempwave
									break
								elseif (rval == 3)	// Kill
									DoWindow /K $graphname
									classtext = "user killed " + targetname
									Killwaves $targetname
									flagNotAP = 1
									break
								elseif (rval == 4)	// Cancel
									print "user canceled."
									abort
								endif
							endif
							tindex += 1
							twave = StringFromList(tindex, listt)
						While (strlen(twave)!=0)
					endif
					print "\t\t", findex, " : ", classtext
					Killwaves $cwave
//					windex+=1
					targetname = StringFromList(windex, lista)
					if (flagNotAP)
						Deletepoints findex, 1, $foundXwave
						Deletepoints findex, 1, $foundVwave
						Deletepoints findex, 1, $foundPXwave
						Deletepoints findex, 1, $foundPwave
						Deletepoints findex, 1, $foundClass
						findex -= 1
					endif
				endif
				findex += 1
			While(findex < numpnts($foundXwave))
			nAP[windex] = findex
			if (waveexists($foundXwave))
				if (numpnts($foundXwave) > 0)
					raster = "raster_" + awave
					Duplicate /O $awave, $raster
					wave rasterwave = $raster
					rasterwave = 0
					foundN = numpnts(Xwave)
					findex = 0
					Do
						rasterwave[x2pnt(rasterwave, Xwave[findex])] = +1
						findex += 1
					While (findex < foundN)
				endif
			endif
		endif
		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
	Killwaves $diffwave
End



function calcISI([waves, type, st, en, pol, thres])
	String waves
	Variable type, st, en, pol, thres
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "spike*";
		type=1; st=-inf; en=inf; pol=1; thres=1; 
		Prompt waves, "wave name"
		Prompt type, "type 1,2 (val,dV/dt)"
		Prompt st, "from (s)"
		Prompt en, "to (s)"
		Prompt pol, "polarity 0/1 (neg/pos)"
		Prompt thres, "threshold (mV,V/s)"
		DoPrompt  "calcISI", waves, type, st, en, pol, thres
		if (V_Flag)	// User canceled
			return -1
		endif
		print "calcISI(waves=\"" + waves + "\", type=" + num2str(type) + ", st=" + num2str(st) + ", en=" + num2str(en) + ", pol=" + num2str(pol) + ", thres=" + num2str(thres) + ")"
	endif

	string regExp = "spike*A-([0-9]+)*";
	string lista, awave, diffwave, foundXwave, nAPwave, ISIwave
	variable foundN, windex, sttime, entime
	
	if (type == 2)
		thres = thres * 1000
	endif
	windex=0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
	Do
		if (st == -inf)
			sttime = leftx($awave)
		else
			sttime = st
		endif
		if (en == inf)
			entime = rightx($awave)
		else
			entime = en
		endif
		if (sttime >= entime)
			abort
		endif
		print windex, awave
		foundXwave = "AP_X_" + awave
		nAPwave = "AP_n_" + awave
		ISIwave = "ISI_" + awave
		if (!waveexists($nAPwave))
			Make /O /N=0 $nAPwave
		endif
		if (type == 1)
			if (pol == 1)
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $awave, thres
			else
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $awave, thres
			endif
		elseif (type == 2)
				Duplicate /O $awave, $diffwave
				differentiate $diffwave
				Make /N=0 /O $foundXwave
			if (pol == 1)
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $diffwave, thres
			else
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $diffwave, thres
			endif
		endif
		foundN = V_levelsFound
		InsertPoints numpnts($nAPwave), 1, $nAPwave
		wave nAP = $nAPwave
		nAP[windex] = foundN
		if (!waveExists($ISIwave))
			Make /O /N=(foundN-1) $ISIwave
		endif
		wave ISIw = $ISIwave
		wave fXw = $foundXwave
		ISIw[] = fXw[p+1] - fXw[p]
		windex += 1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
end
	

function extractMinis([waves, type, sttime, entime, pol, thres, winwidth, winstep, restdur, decaydur])
	String waves
	Variable type, sttime, entime, pol, thres, winwidth, winstep, restdur, decaydur
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "0*_Im*";
		type=2; sttime=-inf; entime=inf; pol=0; thres=2; winwidth=1; winstep=0.5; restdur=0.02; decaydur=0.05
		Prompt waves, "wave name"
		Prompt type, "type 1,2 (avg+SD,dIdt)"
		Prompt sttime, "from (s)"
		Prompt entime, "to (s)"
		Prompt pol, "polarity 0/1 (neg/pos)"
		Prompt thres, "thres (t*SD, t(pA/ms))"
		Prompt winwidth, "window width (s)"
		Prompt winstep, "window step (s)"
		Prompt restdur, "Duration for Irest (s)"
		Prompt decaydur, "Duration for decay (s)"
		DoPrompt  "extractMinis", waves, type, sttime, entime, pol, thres, winwidth, winstep, restdur, decaydur
		if (V_Flag)	// User canceled
			return -1
		endif
		print "extractMinis(waves=\"" + waves + "\", type=" + num2str(type) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", pol=" + num2str(pol) + ", thres=" + num2str(thres) + ", winwidth=" + num2str(winwidth) + ", winstep=" + num2str(winstep) + ", restdur=" + num2str(restdur) + ", decaydur=" + num2str(decaydur) + ")"
	endif

	string lista, awave, foundXwave, swave, diffwave, twave, destname, wavefitcoef, minisNwave
	string graphMinis, gtext, waveMinisAmp, waveMinisRiseT, waveMinisDecayT, waveStX, waveEnX
		diffwave = "differentiated"
		graphMinis = "Minis"
		wavefitcoef = "W_coef"
	variable Irest, Irest_restdur, Ithres, peakMinis, peakMinisX, ampMinis, amp10, amp90, amp10X, amp90X, riseT, decayT
	variable windex, stwin, enwin, mindex, dindex, flagDone, i
	variable stNotFound, enNotFound, stRest, enRest, lenFound, crossX, rval
		lista = WaveList(waves,";","")
		windex = 0
		awave = StringFromList(windex, lista)
	Do
		print "*********** ", awave, " **************"
		smoothWave(wave1=awave, destname="s_", sttime=-inf, entime=inf, smoothMethod=2, endEffect=0, width=10, repetition=20, sgOrder=2, printToCmd=0)
		if (sttime >= entime)
			print "sttime >= entime, so finish the program"
			abort
		else
			if (sttime == -inf)
				sttime = leftx($awave)
			endif
			if (entime == inf)
				entime = rightx($awave)
			endif
		endif
			waveMinisAmp = "miniA_" + awave
			waveMinisRiseT = "miniRT_" + awave
			waveMinisDecayT = "miniDT_" + awave
			minisNwave = "miniN_" + awave
			waveStX = "miniSt_" + awave
			waveEnX = "miniEn_" + awave
			Make /O /N=0 $waveMinisAmp
			Make /O /N=0 $waveMinisRiseT
			Make /O /N=0 $waveMinisDecayT
			Make /O /N=0 $waveStX
			Make /O /N=0 $waveEnX
			Make /O /N=3 $minisNwave		// detect, events, minis
			wave wmAmp = $waveMinisAmp
			wave wmRiseT = $waveMinisRiseT
			wave wmDecayT = $waveMinisDecayT
			wave wmStX = $waveStX
			wave wmEnX = $waveEnX
			wave wmN = $minisNwave
			wmN = 0
		foundXwave = "X_" + awave
		swave = "s_" + awave
		if (type == 2)
			Make /N=0 /O $foundXwave
			Duplicate /O $swave, $diffwave
			differentiate $diffwave
			if (pol == 1)
				Ithres = thres * 1000
				findLevels /D=$foundXwave /EDGE=1 /Q /R=(sttime, entime) $diffwave, Ithres
			else
				Ithres = - thres * 1000
				findLevels /D=$foundXwave /EDGE=2 /Q /R=(sttime, entime) $diffwave, Ithres
			endif
			lenFound = numpnts($foundXwave)
			wave foundX = $foundXwave
			mindex = 0
			if (V_flag != 2)
				Do
					crossX = foundX[mindex]
					print "asfasdfa"
					stwin = foundX[mindex] - 0.1
					enwin = foundX[mindex] + 0.5
						print crossX
						Wavestats /Q /R=(crossX - restdur, crossX) $swave
						Irest = V_avg
						if (pol==1)
							findLevel /EDGE=1 /Q /R=(crossX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=2 /Q /R=(crossX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
						else
							findLevel /EDGE=2 /Q /R=(crossX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=1 /Q /R=(crossX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
						endif
						if (stNotFound)
							stRest = crossX - restdur
						endif
						if (enNotFound)
							enRest = crossX + decaydur
						endif
						print "**", stRest, enRest, "data"
						if (pol==1)
							Wavestats /Q /R=(crossX, enRest) $swave
							peakMinis = V_max
							ampMinis = peakMinis - Irest
							peakMinisX = V_maxloc
							findLevel /EDGE=1 /Q /R=(peakMinisX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=2 /Q /R=(peakMinisX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
							amp10 = ampMinis * 0.1 + Irest
							findLevel /EDGE=1 /Q /R=(stRest, peakMinisX) $swave, amp10
							amp10X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp10%"
							endif
							amp90 = ampMinis * 0.9 + Irest
							findLevel /EDGE=1 /Q /R=(stRest, peakMinisX) $swave, amp90
							amp90X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp90%"
							endif
						else
							Wavestats /Q /R=(crossX, enRest) $swave
							peakMinis = V_min
							ampMinis = Irest - peakMinis
							peakMinisX = V_minloc
							findLevel /EDGE=2 /Q /R=(peakMinisX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=1 /Q /R=(peakMinisX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
							amp10 = - ampMinis * 0.1 + Irest
							findLevel /EDGE=2 /Q /R=(stRest, peakMinisX) $swave, amp10
							amp10X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp10%"
							endif
							amp90 = - ampMinis * 0.9 + Irest
							findLevel /EDGE=2 /Q /R=(stRest, peakMinisX) $swave, amp90
							amp90X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp90%"
							endif
						endif
						print peakMinisX
						print "**", stRest, enRest, "data"

						if (stNotFound)
							stRest = crossX - restdur
						endif
						if (enNotFound)
							enRest = crossX + decaydur
						endif
						riseT = (amp90X - amp10X)*1000
						flagDone = 0
						print "Done", flagDone, "Rest", stRest, enRest
						if (flagDone == 0)
							Display /N=$graphMinis /W=(100,100,800,500) $swave 
							modifyGraph rgb=(40000,40000,40000)
							DoWindow /F $graphMinis
							SetAxis bottom stwin, enwin
							SetDrawEnv ycoord= left, xcoord=prel, linebgc=(0,0,0)
							DrawLine 0, Irest, 1, Irest
							SetDrawEnv ycoord= prel, xcoord=bottom, linebgc=(60000,0,0)
							DrawLine crossX, 0,  crossX, 1
							SetDrawEnv ycoord= left, xcoord=prel, linebgc=(10000,10000,20000)
							DrawLine 0, Ithres, 1, Ithres
							gtext = "amp : " + num2str(ampMinis) + ";  "
							gtext += "riseT : " + num2str(riseT) + ";  "
							SetDrawEnv ycoord= left, xcoord=bottom, linebgc=(0,0,0)
							DrawLine peakMinisX, Irest, peakMinisX, peakMinis
							CurveFit  /Q exp_XOffset, $swave(peakMinisX, enRest) /D 
							wave wfitcoef = $wavefitcoef
							decayT = wfitcoef[2] * 1000
							gtext += "decayTau : " + num2str(decayT)
							DrawText /W=$graphMinis 0.1, 0.8, gtext
							ShowInfo
							Cursor /A=1 /C=(65535, 40000, 0) /H=0 /L=0 /S=1 /W=$graphMinis A $swave stRest
							Cursor /A=1 /C=(65535, 40000, 0) /H=0 /L=0 /S=1 /W=$graphMinis B $swave enRest
							InsertPoints numpnts($waveStX), 1, $waveStX
							InsertPoints numpnts($waveEnX), 1, $waveEnX
							wmStX[wmN[0]] = stRest	
							wmEnX[wmN[0]] = enRest	
							wmN[0] += 1		// detect
							rval= UserCursorAdjust(graphMinis)
							if (rval == -1)		// Graph name error
								print "Graph name error."
								abort
							elseif (rval == 3)	// User canceled
								print "user canceled."
								abort
							elseif (rval == 2)	// User ignored
							else				// synaptic event
								wmN[1] += 1
								if (rval != 1)	// synaptic event and will be used for minis analysis
									wmN[2] += 1
									destname = "m_" + num2str(dindex) + "_" + awave
//									Duplicate /O /R=(xcsr(A),xcsr(B)) $awave, $destname
									Duplicate /O /R=(crossX-restdur, crossX+decaydur) $awave, $destname 
									destname = "sm_" + num2str(dindex) + "_" + awave
//									Duplicate /O /R=(xcsr(A),xcsr(B)) $swave, $destname
									Duplicate /O /R=(crossX-restdur, crossX+decaydur) $swave, $destname 
									InsertPoints numpnts(wmAmp), 1, wmAmp
									InsertPoints numpnts($waveMinisRiseT), 1, $waveMinisRiseT
									InsertPoints numpnts($waveMinisDecayT), 1, $waveMinisDecayT
									wmAmp[dindex] = ampMinis
									wmRiseT[dindex] = riseT
									wmDecayT[dindex] = decayT		// tau (ms)
									dindex += 1
								endif
							endif
							print "\t\t detect: ", wmN[0], " ; events: ", wmN[1], " ; minis analysis: ", wmN[2]
							DoWindow /K $graphMinis
						endif
						mindex += 1
					While (mindex < lenFound)
			endif
		elseif (type == 1)
			dindex = 0
			stwin=sttime
			Do
				enwin = stwin +winwidth
				wavestats /Q /R=(stwin, enwin) $swave
				if (pol == 1)
					Ithres = V_avg + thres * V_sdev
				else
					Ithres = V_avg -  thres * V_sdev
				endif
				twave = swave
				Make /N=0 /O $foundXwave
				if (pol == 1)
					findLevels /D=$foundXwave /EDGE=1 /Q /R=(stwin, enwin) $twave, Ithres
				else
					findLevels /D=$foundXwave /EDGE=2 /Q /R=(stwin, enwin) $twave, Ithres
				endif
				lenFound = numpnts($foundXwave)
				wave foundX = $foundXwave
				mindex = 0
				if (V_flag != 2)
					Do
						crossX = foundX[mindex]
						print crossX
						Wavestats /Q /R=(crossX - restdur, crossX) $swave
						Irest = V_avg
						if (pol==1)
							findLevel /EDGE=1 /Q /R=(crossX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=2 /Q /R=(crossX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
						else
							findLevel /EDGE=2 /Q /R=(crossX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=1 /Q /R=(crossX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
						endif
						if (stNotFound)
							stRest = crossX - restdur
						endif
						if (enNotFound)
							enRest = crossX + decaydur
						endif
						print "**", stRest, enRest, "data"
						if (pol==1)
							Wavestats /Q /R=(crossX, enRest) $swave
							peakMinis = V_max
							ampMinis = peakMinis - Irest
							peakMinisX = V_maxloc
							findLevel /EDGE=1 /Q /R=(peakMinisX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=2 /Q /R=(peakMinisX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
							amp10 = ampMinis * 0.1 + Irest
							findLevel /EDGE=1 /Q /R=(stRest, peakMinisX) $swave, amp10
							amp10X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp10%"
							endif
							amp90 = ampMinis * 0.9 + Irest
							findLevel /EDGE=1 /Q /R=(stRest, peakMinisX) $swave, amp90
							amp90X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp90%"
							endif
						else
							Wavestats /Q /R=(crossX, enRest) $swave
							peakMinis = V_min
							ampMinis = Irest - peakMinis
							peakMinisX = V_minloc
							findLevel /EDGE=2 /Q /R=(peakMinisX, stwin) $swave, Irest
							stRest = V_LevelX
							stNotFound = V_flag
							findLevel /EDGE=1 /Q /R=(peakMinisX, enwin) $swave, Irest
							enRest = V_LevelX
							enNotFound = V_flag
							amp10 = - ampMinis * 0.1 + Irest
							findLevel /EDGE=2 /Q /R=(stRest, peakMinisX) $swave, amp10
							amp10X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp10%"
							endif
							amp90 = - ampMinis * 0.9 + Irest
							findLevel /EDGE=2 /Q /R=(stRest, peakMinisX) $swave, amp90
							amp90X = V_LevelX
							if (V_flag)
								print "************* cannot find the crossX of amp90%"
							endif
						endif
						print peakMinisX
						print "**", stRest, enRest, "data"

						if (stNotFound)
							stRest = crossX - restdur
						endif
						if (enNotFound)
							enRest = crossX + decaydur
						endif
						riseT = (amp90X - amp10X)*1000
						flagDone = 0
							For (i=0; i<numpnts(wmStX); i+=1)
								if (stRest < wmEnX[i] && enRest > wmStX[i])
									flagDone = 1
									break
								endif
							endfor
						print "Done", flagDone, "Rest", stRest, enRest, "data", wmStX[i], wmEnX[i]
						if (flagDone == 0)
							Display /N=$graphMinis $swave 
							modifyGraph rgb=(40000,40000,40000)
							DoWindow /F $graphMinis
							SetAxis bottom stwin, enwin
							SetDrawEnv ycoord= left, xcoord=prel, linebgc=(0,0,0)
							DrawLine 0, Irest, 1, Irest
							SetDrawEnv ycoord= prel, xcoord=bottom, linebgc=(60000,0,0)
							DrawLine crossX, 0,  crossX, 1
							SetDrawEnv ycoord= left, xcoord=prel, linebgc=(10000,10000,20000)
							DrawLine 0, Ithres, 1, Ithres
							gtext = "amp : " + num2str(ampMinis) + ";  "
							gtext += "riseT : " + num2str(riseT) + ";  "
							SetDrawEnv ycoord= left, xcoord=bottom, linebgc=(0,0,0)
							DrawLine peakMinisX, Irest, peakMinisX, peakMinis
							CurveFit  /Q exp_XOffset, $swave(peakMinisX, enRest) /D 
							wave wfitcoef = $wavefitcoef
							decayT = wfitcoef[2] * 1000
							gtext += "decayTau : " + num2str(decayT)
							DrawText /W=$graphMinis 0.1, 0.8, gtext
							ShowInfo
							Cursor /A=1 /C=(65535, 40000, 0) /H=0 /L=0 /S=1 /W=$graphMinis A $swave stRest
							Cursor /A=1 /C=(65535, 40000, 0) /H=0 /L=0 /S=1 /W=$graphMinis B $swave enRest
							InsertPoints numpnts($waveStX), 1, $waveStX
							InsertPoints numpnts($waveEnX), 1, $waveEnX
							wmStX[wmN[0]] = stRest	
							wmEnX[wmN[0]] = enRest	
							wmN[0] += 1		// detect
							rval= UserCursorAdjust(graphMinis)
							if (rval == -1)		// Graph name error
								print "Graph name error."
								abort
							elseif (rval == 3)	// User canceled
								print "user canceled."
								abort
							elseif (rval == 2)	// User ignored
							else				// synaptic event
								wmN[1] += 1
								if (rval != 1)	// synaptic event and will be used for minis analysis
										wmN[2] += 1
									destname = "m_" + num2str(dindex) + "_" + awave
//									Duplicate /O /R=(xcsr(A),xcsr(B)) $awave, $destname
									Duplicate /O /R=(crossX-restdur, crossX+decaydur) $awave, $destname 
									destname = "sm_" + num2str(dindex) + "_" + awave
//									Duplicate /O /R=(xcsr(A),xcsr(B)) $swave, $destname
									Duplicate /O /R=(crossX-restdur, crossX+decaydur) $swave, $destname 
									InsertPoints numpnts(wmAmp), 1, wmAmp
									InsertPoints numpnts($waveMinisRiseT), 1, $waveMinisRiseT
									InsertPoints numpnts($waveMinisDecayT), 1, $waveMinisDecayT
									wmAmp[dindex] = ampMinis
									wmRiseT[dindex] = riseT
									wmDecayT[dindex] = decayT		// tau (ms)
									dindex += 1
								endif
							endif
							print "\t\t detect: ", wmN[0], " ; events: ", wmN[1], " ; minis analysis: ", wmN[2]
							DoWindow /K $graphMinis
						endif
						mindex += 1
					While (mindex < lenFound)
				else
					print "V_flag == 2"
				endif
				stwin += winstep
			While (stwin + winwidth < entime)
		endif
		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
	print "*************************"
	print "******** Done *********"
End

Function UserCursorAdjust(graphName)
	String graphName
	DoWindow /F $graphName // Bring graph to front
	if (V_Flag == 0) // Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewDataFolder/O root:tmp_PauseforCursorDF
	Variable/G root:tmp_PauseforCursorDF:canceled= 0
	NewPanel/K=2 /W=(139,300,582,500) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor // Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName // Put panel near the graph
	DrawText 21,20,"Adjust the cursors and then"
	DrawText 21,40,"Click Continue."
	Button button0,pos={80,58},size={300,20},title="Synaptic event so add this to minis template"
	Button button0,proc=UserCursorAdjust_ContButtonProc
	Button button1,pos={80,80},size={300,20}
	Button button1,proc=UserCursorAdjust_FreqBProc,title="Synaptic event but does not add this"
	Button button2,pos={80,102},size={300,20}
	Button button2,proc=UserCursorAdjust_IgnoreBProc,title="Ignore"
	Button button3,pos={80,124},size={300,20}
	Button button3,proc=UserCursorAdjust_CancelBProc,title="Cancel"

	PauseForUser tmp_PauseforCursor,$graphName
	NVAR gCaneled = root:tmp_PauseforCursorDF:canceled
	Variable canceled = gCaneled // Copy from global to local	
	// before global is killed
	KillDataFolder root:tmp_PauseforCursorDF
	return canceled
End

Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function UserCursorAdjust_FreqBProc(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:canceled= 1
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function UserCursorAdjust_IgnoreBProc(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:canceled= 2
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function UserCursorAdjust_CancelBProc(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:canceled= 3
	DoWindow/K tmp_PauseforCursor // Kill self
End


Function Demo()
	DoWindow Graph0
	if (V_Flag==0)
		ShowInfo
	endif
	Variable rval= UserCursorAdjust("Graph0")
	if (rval == -1) // Graph name error?
		return -1;
	endif
	if (rval == 1) // User canceled?
		DoAlert 0,"Canceled"
		return -1;
	endif
	CurveFit gauss,jack[pcsr(A),pcsr(B)] /D
End








function makeDistanceMatrix([row, col, side])
	Variable row, col, side
	if (row == 0)		// if (row == null) : so there was no input
		row = 40; col=40; side=25;
		Prompt row, "row num"
		Prompt col, "col num"
		Prompt side, "side (size)"
		DoPrompt  "makeDistanceMatrix", row, col, side
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* makeDistanceMatrix(row=" + num2str(row) + ", col=" + num2str(col) + ", side=" + num2str(side) + ")"
	endif

	variable rowindex, colindex, rowDindex, colDindex, distance
	string namewave
	rowindex=0
	Do
		colindex=0
		Do
			namewave = "DMatrix" + num2str(side) + "_" + num2str(rowindex) + "_" + num2str(colindex)
			Make /O /N=(row, col) /D $namewave
			wave M = $namewave
			rowDindex=0
			Do
				colDindex=0
				Do
					distance = sqrt(abs(rowindex - rowDindex)^2 + abs(colindex - colDindex)^2) * side
//					M[rowDindex][colDindex] = distance
					M[rowDindex][colDindex] = exp(-distance/200)
					colDindex += 1
				While(colDindex < col)
				rowDindex += 1
			While(rowDindex < row)	
			colindex += 1
		While(colindex < col)
		rowindex += 1
	While(rowindex < row)
end


function calcInhibition_old([suffix, signal, lateral])
	String suffix
	Variable signal, lateral
	if (numType(strlen(suffix)) == 2)		// if (wave == null) : so there was no input
		suffix = "I_F_GaussSD10";
		signal=0; lateral=0;
		Prompt suffix, "noise wave suffix (:noise:)"
		Prompt signal, "signal 0/1 (:signal:S10*)"
		Prompt lateral, "low thres lateral 0/1"
		DoPrompt  "calcInhibition_old", suffix, signal, lateral
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcInhibition_old(suffix=\"" + suffix + "\", signal=" + num2str(signal) + ", lateral=" + num2str(lateral) + ")"
	endif

	variable row=25, col=25
	variable strow=16, stcol=16
	string waves = suffix + "*"
	string noiseFoldername = ":noise"

	string lista, a_wave, destwave, mIPSPrecname, mIPSPlatname
	mIPSPrecname = ":mIPSP:mIPSPrec"
		wave mIPSPrec = $mIPSPrecname
	mIPSPlatname = ":mIPSP:mIPSPlat"
		wave mIPSPlat = $mIPSPlatname
	string volname, outname, outname_lat, recname, latname, cellname, signalname, signalsuffix
		signalsuffix = ":signal:S10"
	variable windex=0, tindex=0, rowindex=0, colindex=0, conindex=0, length=0, inhlength=0, conlength=0, ratio=0, vlast=-0.05, vnow=-0.05, ECl=-0.07, coef_cl=1
	setDataFolder noiseFoldername
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		length = numpnts($a_wave)
	setDataFolder ::
		conlength = numpnts(mIPSPrec)
		inhlength = length + conlength - 1
	print "     starts making waves ... "
	Do
		wave a = $(noiseFoldername + ":" + a_wave)
		volname = "V_" + a_wave
		outname = "O_" + a_wave
		recname = "R_" + a_wave
		latname = "L_" + a_wave
		Duplicate /O $a_wave $volname
		Duplicate /O $a_wave $outname
		Duplicate /O $a_wave $recname
			Redimension /N=(inhlength) $recname
		Duplicate /O $a_wave $latname
			Redimension /N=(inhlength) $latname
		wave v = $volname
		wave out = $outname
		wave rec = $recname
		wave lat = $latname
		v = 0
		out = 0
		rec = 0
		lat = 0
		if (lateral == 1)
			outname_lat = "OL_" + a_wave
			Duplicate /O $a_wave $outname_lat
			wave out_lat = $outname_lat
			out_lat = 0
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	print "     finished making waves."
	
	print "     starts calculation ( 0 -", num2str(length-1), ") ... "
	variable rowIindex=0, colIindex=0
	tindex = 0
	Do 
		print "       [", num2str(tindex), "]", time()
		rowindex = strow
		Do
			colindex = stcol
			Do
				a_wave = noiseFoldername + ":" + suffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
				cellname = ":Matrix:DMatrix25_" + num2str(rowindex) + "_" + num2str(colindex)
				volname = "V_" + a_wave
				outname = "O_" + a_wave
				recname = "R_" + a_wave
				latname = "L_" + a_wave
				wave a = $a_wave
				wave cell = $cellname
				wave v = $volname
				wave out = $outname
				wave rec = $recname
				wave lat = $latname
				if (tindex == 0)
					vlast = -0.05
				else
					vlast = v[tindex-1]
				endif
				coef_cl = (vlast - Ecl)/(-0.05 - Ecl)
				rec[tindex] = rec[tindex]*coef_cl
				lat[tindex] = lat[tindex]*coef_cl
				if (signal == 1)
					signalname = signalsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave sig = $signalname
					vnow = a[tindex] + sig[tindex] + rec[tindex] + lat[tindex]
					vnow = vlast + (vnow - vlast) * (1-exp(-1))
				else
					vnow = a[tindex] + rec[tindex] + lat[tindex]
					vnow = vlast + (vnow - vlast) * (1-exp(-1))
				endif
				v[tindex] = vnow
				
				//////////////////////// write transform function (a = a_wave)
				//		out = (a+0.1)^15/((a+0.1)^15+(-.035+0.1)^15)
				//////////////////////////////////////////////////
				out[tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.035+0.1)^20)
				if (lateral == 1)
					outname_lat = "OL_" + a_wave
					wave out_lat = $outname_lat
					//////////////////////// write transform function (a = a_wave)
					//		out_lat = (a+0.1)^25/((a+0.1)^25+(-.045+0.1)^15)
					//////////////////////////////////////////////////
					out_lat[tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.045+0.1)^20)
				endif

				rowIindex = strow
				Do
					colIindex = stcol
					Do
						ratio = cell[rowIindex][colIindex]
//						print "cell ", num2str(rowindex), num2str(colindex), "[",  num2str(rowIindex),  num2str(colIindex), "] = ",  num2str(ratio)
						latname = "L_" + suffix + "_" + num2str(rowIindex) + "_" + num2str(colIindex)
						wave lat = $latname
						recname = "R_" + suffix + "_" + num2str(rowIindex) + "_" + num2str(colIindex)
						wave rec = $recname
						conindex = 0
						if ((rowindex == rowIindex) && (colindex == colIindex))
							if (lateral == 1)
								Do
									rec[tindex + conindex] += out[tindex] * mIPSPrec[conindex] * ratio
									lat[tindex + conindex] += out_lat[tindex] * mIPSPlat[conindex] * ratio
									conindex += 1
								While(conindex < conlength)
							else
								Do
									rec[tindex + conindex] += out[tindex] * mIPSPrec[conindex] * ratio
									lat[tindex + conindex] += out[tindex] * mIPSPlat[conindex] * ratio
									conindex += 1
								While(conindex < conlength)
							endif
						else
							if (lateral == 1)
								Do
									lat[tindex + conindex] += out_lat[tindex] * mIPSPlat[conindex] * ratio
									conindex += 1
								While(conindex < conlength)
							else
								Do
									lat[tindex + conindex] += out[tindex] * mIPSPlat[conindex] * ratio
									conindex += 1
								While(conindex < conlength)
							endif
						endif
						colIindex += 1
					While(colIindex < col)
					rowIindex += 1
				While(rowIindex < row)
				colindex += 1
			While(colindex < col)
			rowindex += 1
		While(rowindex < row)
		tindex += 1
	While(tindex < length)
	print "     finished calculation. "
End



function calcInh_population([suffix, signal, noiseFoldername, lateral, GJ, tau])
	String suffix, noiseFoldername
	Variable signal, lateral, tau, GJ
	if (numType(strlen(suffix)) == 2)		// if (wave == null) : so there was no input
		suffix = "I_F_GaussSD10"; noiseFoldername = ":noise";
		signal=1; lateral=1; GJ=0; tau=5;
		Prompt suffix, "noise wave suffix (:noise:)"
		Prompt signal, "signal 0/1 (:signal:S10*)"
		Prompt noiseFoldername, "noise folder"
		Prompt lateral, "low thres lateral 0/1"
		Prompt GJ, "gap junction 0/1"
		Prompt tau, "tau (pnts)"
		DoPrompt  "calcInh_population", suffix, signal, noiseFoldername, lateral, GJ, tau
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcInh_population(suffix=\"" + suffix + "\", signal=" + num2str(signal) + ", noiseFoldername=\"" + noiseFoldername + "\", lateral=" + num2str(lateral) + ", GJ=" + num2str(GJ) + ", tau=" + num2str(tau) + ")"
	endif

	variable row=40, col=40
	variable strow=0, stcol=0
	variable enrow=40, encol=40
	string waves = suffix + "*"
////////////////////////////////////////////////////////// Voltage-Clamp
	variable VC = 0, VCrow=20, VCcol=20
////////////////////////////////////////////////////////// Voltage-Clamp

	string lista, a_wave, destwave, mIPSPrecname, mIPSPlatname
	mIPSPrecname = ":mIPSP:mIPSPrec"
		wave mIPSPrec = $mIPSPrecname
	mIPSPlatname = ":mIPSP:mIPSPlat"
		wave mIPSPlat = $mIPSPlatname
	string volname, outname, outname_lat, recname, latname, cellname, signalname, signalsuffix
	string dimname
		signalsuffix = ":signal:S10"
	variable windex=0, tindex=0, rowindex=0, colindex=0, length=0, inhlength=0, conlength=0, tlast=0
	variable coef=0, vlast=-0.05, vlast2=-0.05, vnow=-0.05, Ecl=-0.07, coef_cl=1, taucoef=1-exp(-1/tau)
	variable tauGJ = 10, ratioGJ = 5, vleft=0, vright=0, vabove=0, vbelow=0, vspace=0, tauGJcoef=1-exp(-1/tauGJ)
	variable taucoef1 = (exp(1/tauGJ) - exp(1/tau) - exp(1/tauGJ-1/tau) + exp(-1/tau) - exp(-1/tauGJ) + exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef2 = (exp(1/tauGJ - 1/tau) - exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef3 = (exp(-1/tauGJ) - exp(-1/tau)) / (exp(1/tauGJ) - exp(1/tau))
////////////////////////////////////////////////////////// saturation
	variable thresSaturated =  -0.030, flagSaturated = 0
////////////////////////////////////////////////////////// IPSP at Vrest
	setDataFolder noiseFoldername
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		length = numpnts($a_wave)
		conlength = numpnts(mIPSPrec)
		inhlength = length + conlength - 1
	setDataFolder ::

	print "     starts making waves ... "	
		volname = "V_" +  suffix
		outname = "O_" +  suffix
		recname = "R_" +  suffix
		latname = "L_" + suffix
		make /O /N=(row, col, length) $volname 
		make /O /N=(row, col, length) $outname 
		make /O /N=(row, col, inhlength) $recname 
		make /O /N=(row, col, inhlength) $latname 
		wave v = $volname
		wave out = $outname
		wave rec = $recname
		wave lat = $latname

		dimname = "D_" + suffix
		make /O /N=(conlength) $dimname 
		wave dim = $dimname
		dim = 0

		v = 0
		out = 0
		rec = 0
		lat = 0
		if (lateral == 1)
			outname_lat = "OL_" + suffix
			make /O /N=(row, col, inhlength) $outname_lat 
			wave out_lat = $outname_lat
			out_lat = 0
		endif
	print "     finished making waves."
	
	print "     starts calculation ( 0 -", num2str(length-1), ") ... "
	tindex = 0
	Do 
		print "       [", num2str(tindex), "]", time()
		rowindex = strow
		Do
			colindex = stcol
			Do
				a_wave = noiseFoldername + ":" + suffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave a = $a_wave
				cellname = ":Matrix:DMatrix25_" + num2str(rowindex) + "_" + num2str(colindex)
					wave cell = $cellname
				if (tindex == 0)
					vlast = -0.05
					vlast2 = -0.05
				elseif (tindex == 1)
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = -0.05
				else
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = v[rowindex][colindex][tindex-2]
				endif
				if (GJ)
					if (rowindex == strow)
						vleft = vlast
					else
						vleft = v[rowindex-1][colindex][tindex-1]
					endif
					if (rowindex == enrow-1)
						vright = vlast
					else
						vright = v[rowindex+1][colindex][tindex-1]
					endif
					if (colindex == stcol)
						vabove = vlast
					else
						vabove = v[rowindex][colindex-1][tindex-1]
					endif
					if (colindex == encol - 1)
						vbelow = vlast
					else
						vbelow = v[rowindex][colindex+1][tindex-1]
					endif
//					vspace = (vleft + vright + vabove + vbelow) * tauGJcoef * ratioGJ
					vspace = ((vleft + vright + vabove + vbelow)/4 - vlast) * ratioGJ
				endif
////////////////////////////////////////////////////////// saturation
				if (lat[rowindex][colindex][tindex] < thresSaturated)
					lat[rowindex][colindex][tindex] =  thresSaturated
					flagSaturated = 1
				endif
////////////////////////////////////////////////////////// saturation
				coef_cl = (vlast - Ecl)/(-0.05 - Ecl)
				rec[rowindex][colindex][tindex] = rec[rowindex][colindex][tindex]*coef_cl
				lat[rowindex][colindex][tindex] = lat[rowindex][colindex][tindex]*coef_cl
/////////////////////////////////// Voltage clamp ///////////////////////////
//				if (VC == 1 && ((colindex == VCcol && rowindex == VCrow) || (colindex == 20 && rowindex == 19)) )
//					if (signal == 1)
//						signalname = signalsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
//						wave sig = $signalname
//						vnow = a[tindex] + sig[tindex]
//					else
//						vnow = a[tindex]
//					endif
//				else
///////////////////////////////////////////////////////////////////////////
					if (signal == 1)
						signalname = signalsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
						wave sig = $signalname
						vnow = a[tindex] + sig[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
//						vnow = a[tindex] + sig[tindex]
					else
						vnow = a[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
//						vnow = a[tindex]
					endif
					if (tindex == 1)
						vnow = vlast + (vnow - vlast) * taucoef + (vspace) * tauGJcoef
					elseif (tindex > 1)
						vnow = ((vnow + vspace) * taucoef1) + (vlast * taucoef2) + (vlast2 * taucoef3)
//						vnow = vlast + (vnow - vlast) * taucoef + vspace
					endif
//				endif
				v[rowindex][colindex][tindex] = vnow
				//////////////////////// write transform function (a = a_wave)
				//		out = (a+0.1)^20/((a+0.1)^20+(-.035+0.1)^20)
				//////////////////////////////////////////////////
				if (lateral == 2)
					out[rowindex][colindex][tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.044+0.1)^20)
				else
					out[rowindex][colindex][tindex] = (vnow+0.1)^13/((vnow+0.1)^13+(-.035+0.1)^13)
				endif
				if (lateral == 1)
					//////////////////////// write transform function (a = a_wave)
					//		out_lat = (a+0.1)^20/((a+0.1)^20+(-.045+0.1)^20)
					//////////////////////////////////////////////////
//					out_lat[rowindex][colindex][tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.044+0.1)^20)
					out_lat[rowindex][colindex][tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.044+0.1)^20)
				endif

				tlast = tindex + length - 1
					rec[rowindex][colindex][tindex,tlast] += out[rowindex][colindex][tindex] * mIPSPrec[r-tindex]
				if (lateral == 1)
					if (tindex < conlength)
						Redimension /N=(tindex+1) dim
					endif
					dim[] = out_lat[rowindex][colindex][tindex-p] * mIPSPlat[p+1]
					coef = sum(dim)
					lat[][][tindex+1] += coef * cell[p][q]

// 2(6s)
//					dim[][] = out_lat[rowindex][colindex][tindex] * cell[p][q]
//					lat[][][tindex,tlast] += mIPSPlat[r-tindex] * dim[p][q]

// 1(10s)			lat[][][tindex,tlast] += out_lat[rowindex][colindex][tindex] * mIPSPlat[r-tindex] * cell[p][q]
				else
//					lat[][][tindex,tlast] += out[rowindex][colindex][tindex] * mIPSPlat[r-tindex] * cell[p][q]
					if (tindex < conlength)
						Redimension /N=(tindex+1) dim
					endif
					dim[] = out[rowindex][colindex][tindex-p] * mIPSPlat[p+1]
					coef = sum(dim)
					lat[][][tindex+1] += coef * cell[p][q]
				endif
				colindex += 1
			While(colindex < encol)
			rowindex += 1
		While(rowindex < enrow)
		if (flagSaturated)
			print "* lateral saturated (< ", num2str(thresSaturated) , " ) "
			flagSaturated = 0
		endif
		tindex += 1
	While(tindex < length)
	print "     finished calculation. "
End


function calcInh_single([suffix, signal, noiseFoldername, lateral, GJ, tau])
	String suffix, noiseFoldername
	Variable signal, lateral, GJ, tau
	if (numType(strlen(suffix)) == 2)		// if (wave == null) : so there was no input
		suffix = "I_F_GaussSD10"; noiseFoldername = ":noise";
		signal=1; lateral=0; GJ=0; tau=5;
		Prompt suffix, "noise wave suffix (:noise:)"
		Prompt signal, "signal 0/1 (:signal:S10*)"
		Prompt noiseFoldername, "noise folder"
		Prompt lateral, "low thres lateral 0/1"
		Prompt GJ, "gap junction 0/1"
		Prompt tau, "tau (pnt)"
		DoPrompt  "calcInh_single", suffix, signal, noiseFoldername, lateral, GJ, tau
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcInh_single(suffix=\"" + suffix + "\", signal=" + num2str(signal) + ", noiseFoldername=\"" + noiseFoldername + "\", lateral=" + num2str(lateral) + ", GJ=" + num2str(GJ) + ", tau=" + num2str(tau)  + ")"
	endif

	variable row=40, col=40
	variable strow=0, stcol=0
	variable enrow=40, encol=40
	string waves = suffix + "*"

	string lista, a_wave, destwave, mIPSPrecname_single
	mIPSPrecname_single = ":mIPSP:mIPSPrec"
		wave mIPSPrec_single = $mIPSPrecname_single
	string alpha_single = ":mIPSP:mIPSPalpha"
		wave alpha = $alpha_single
	string volname, outname, recname, latname, cellname, signalname, signalsuffix
	string dimname
		signalsuffix = ":signal:S10"
	variable windex=0, tindex=0, rowindex=0, colindex=0, length=0, inhlength=0, conlength=0, tlast=0
	variable coef=0, discoef=0, IPSPrange, vlast=-0.05, vlast2=-0.05, vnow=-0.05, Ecl=-0.07, coef_cl=1, taucoef=1-exp(-1/tau)
	variable tauGJ = 10, ratioGJ = 5, vleft=0, vright=0, vabove=0, vbelow=0, vspace=0, tauGJcoef=1-exp(-1/tauGJ)
	variable taucoef1 = (exp(1/tauGJ) - exp(1/tau) - exp(1/tauGJ-1/tau) + exp(-1/tau) - exp(-1/tauGJ) + exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef2 = (exp(1/tauGJ - 1/tau) - exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef3 = (exp(-1/tauGJ) - exp(-1/tau)) / (exp(1/tauGJ) - exp(1/tau))
////////////////////////////////////////////////////////// saturation
	variable thresSaturated =  -0.030, flagSaturated = 0
////////////////////////////////////////////////////////// IPSP at ECl
	setDataFolder noiseFoldername
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		length = numpnts($a_wave)
		conlength = numpnts(mIPSPrec_single)
		inhlength = length + conlength - 1
	setDataFolder ::

	print "     starts making waves ... "	
		volname = "V_" +  suffix
		outname = "O_" +  suffix
		recname = "R_" +  suffix
		latname = "L_" + suffix
		make /O /N=(row, col, length) $volname 
		make /O /N=(row, col, length) $outname 
		make /O /N=(row, col, inhlength) $recname 
		make /O /N=(row, col, inhlength) $latname 
		wave v = $volname
		wave out = $outname
		wave rec = $recname
		wave lat = $latname

		dimname = "D_" + suffix
		make /O /N=(conlength) $dimname 
		wave dim = $dimname
		dim=0

		v = 0
		out = 0
		rec = 0
		lat = 0
	print "     finished making waves."
	
	print "     starts calculation ( 0 -", num2str(length-1), ") ... "
	tindex = 0
	Do 
		print "       [", num2str(tindex), "]", time()
		rowindex = strow
		Do
			colindex = stcol
			Do
				a_wave = noiseFoldername + ":" + suffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave a = $a_wave
				cellname = ":DMatrix:DMatrix25_" + num2str(rowindex) + "_" + num2str(colindex)
					wave cell = $cellname
				if (tindex == 0)
					vlast = -0.05
					vlast2 = -0.05
				elseif (tindex == 1)
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = -0.05
				else
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = v[rowindex][colindex][tindex-2]
				endif

				if (GJ)
					if (rowindex == strow)
						vleft = vlast
					else
						vleft = v[rowindex-1][colindex][tindex-1]
					endif
					if (rowindex == enrow-1)
						vright = vlast
					else
						vright = v[rowindex+1][colindex][tindex-1]
					endif
					if (colindex == stcol)
						vabove = vlast
					else
						vabove = v[rowindex][colindex-1][tindex-1]
					endif
					if (colindex == encol - 1)
						vbelow = vlast
					else
						vbelow = v[rowindex][colindex+1][tindex-1]
					endif
//					vspace = (vleft + vright + vabove + vbelow) * tauGJcoef * ratioGJ
					vspace = ((vleft + vright + vabove + vbelow)/4 - vlast) * ratioGJ
				endif
////////////////////////////////////////////////////////// saturation
				if (lat[rowindex][colindex][tindex] < thresSaturated)
					lat[rowindex][colindex][tindex] =  thresSaturated
					flagSaturated = 1
				endif
////////////////////////////////////////////////////////// saturation
				coef_cl = (vlast - ECl)/(-0.05 - ECl)
				rec[rowindex][colindex][tindex] = rec[rowindex][colindex][tindex]*coef_cl
				lat[rowindex][colindex][tindex] = lat[rowindex][colindex][tindex]*coef_cl
				if (signal == 1)
					signalname = signalsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave sig = $signalname
					vnow = a[tindex] + sig[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
				else
					vnow = a[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
				endif
				if (tindex == 1)
					vnow = vlast + (vnow - vlast) * taucoef + (vspace) * tauGJcoef
				elseif (tindex > 1)
					vnow = ((vnow + vspace) * taucoef1) + (vlast * taucoef2) + (vlast2 * taucoef3)
//					vnow = vlast + (vnow - vlast) * taucoef + vspace
				endif
				v[rowindex][colindex][tindex] = vnow

				if (lateral == 1)
					//////////////////////// write transform function (a = a_wave)
					//		out = (a+0.1)^20/((a+0.1)^20+(-.045+0.1)^20)
					//////////////////////////////////////////////////
					out[rowindex][colindex][tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.044+0.1)^20)
				else
					//////////////////////// write transform function (a = a_wave)
					//		out = (a+0.1)^20/((a+0.1)^20+(-.035+0.1)^20)
					//////////////////////////////////////////////////
					out[rowindex][colindex][tindex] = (vnow+0.1)^13/((vnow+0.1)^13+(-.035+0.1)^13)
				endif

				tlast = tindex + length - 1
					rec[rowindex][colindex][tindex,tlast] += out[rowindex][colindex][tindex] * mIPSPrec_single[r-tindex]

				if (tindex < conlength)
					Redimension /N=(tindex+1) dim
				endif
				dim[] = out[rowindex][colindex][tindex-p] * mIPSPrec_single[p+1]
				coef = sum(dim)
				dim=0
				dim[] = out[rowindex][colindex][tindex-p] * alpha[p+1]
				discoef = sum(dim)
				dim=0
				IPSPrange = 0.01/discoef
				lat[][][tindex+1] += coef * (cell[p][q])^(IPSPrange)
				lat[rowindex][colindex][tindex+1] -= coef * (cell[rowindex][colindex])^(IPSPrange)

				colindex += 1
			While(colindex < encol)
			rowindex += 1
		While(rowindex < enrow)
		if (flagSaturated)
			print "* lateral saturated (< ", num2str(thresSaturated) , " ) "
			flagSaturated = 0
		endif
		tindex += 1
	While(tindex < length)
	print "     finished calculation. "
End

function calcBlockInh_population([suffix, signal, noiseFoldername, lateral, inhrec, inhlat, GJ, tau])
	String suffix, noiseFoldername
	Variable signal, lateral, inhrec, inhlat, GJ, tau
	if (numType(strlen(suffix)) == 2)		// if (wave == null) : so there was no input
		suffix = "I_F_GaussSD10"; noiseFoldername = ":noise";
		signal=1; lateral=1; GJ=0; tau=5;
		Prompt suffix, "noise wave suffix (:noise:)"
		Prompt signal, "signal 0/1 (:signal:S10*)"
		Prompt noiseFoldername, "noise folder"
		Prompt lateral, "low threshold lateral 0/1"
		Prompt inhrec, "calc reciprocal 0/1"
		Prompt inhlat, "calc lateral 0/1"
		Prompt GJ, "gap junction 0/1"
		Prompt tau, "tau (pnts)"
		DoPrompt  "calcBlockInh_population", suffix, signal, noiseFoldername, lateral, inhrec, inhlat, GJ, tau
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcBlockInh_population(suffix=\"" + suffix + "\", signal=" + num2str(signal) + ", noiseFoldername=\"" + noiseFoldername + "\", lateral=" + num2str(lateral) + ", inhrec=" + num2str(inhrec) + ", inhlat=" + num2str(inhlat) + ", GJ=" + num2str(GJ) + ", tau=" + num2str(tau) + ")"
	endif

	variable row=40, col=40
	variable strow=0, stcol=0
	variable enrow=40, encol=40
	string waves = suffix + "*"

	string lista, a_wave, destwave, mIPSPrecname, mIPSPlatname
	mIPSPrecname = ":mIPSP:mIPSPrec"
		wave mIPSPrec = $mIPSPrecname
	mIPSPlatname = ":mIPSP:mIPSPlat"
		wave mIPSPlat = $mIPSPlatname
	string volname, outname, outname_lat, recname, latname, cellname, signalname, signalsuffix
	string dimname
		signalsuffix = ":signal:S10"
	variable windex=0, tindex=0, rowindex=0, colindex=0, length=0, inhlength=0, conlength=0, tlast=0
	variable coef=0, vlast=-0.05, vlast2=-0.05, vnow=-0.05, Ecl=-0.07, coef_cl=1, taucoef=1-exp(-1/tau)
	variable tauGJ = 10, ratioGJ = 5, vleft=0, vright=0, vabove=0, vbelow=0, vspace=0, tauGJcoef=1-exp(-1/tauGJ)
	variable taucoef1 = (exp(1/tauGJ) - exp(1/tau) - exp(1/tauGJ-1/tau) + exp(-1/tau) - exp(-1/tauGJ) + exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef2 = (exp(1/tauGJ - 1/tau) - exp(1/tau - 1/tauGJ)) / (exp(1/tauGJ) - exp(1/tau))
	variable taucoef3 = (exp(-1/tauGJ) - exp(-1/tau)) / (exp(1/tauGJ) - exp(1/tau))
////////////////////////////////////////////////////////// saturation
	variable thresSaturated =  -0.030, flagSaturated = 0
////////////////////////////////////////////////////////// IPSP at ECl
	setDataFolder noiseFoldername
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		length = numpnts($a_wave)
		conlength = numpnts(mIPSPrec)
		inhlength = length + conlength - 1
	setDataFolder ::

	print "     starts making waves ... "	
		volname = "V_" +  suffix
		outname = "O_" +  suffix
		recname = "R_" +  suffix
		latname = "L_" + suffix
		make /O /N=(row, col, length) $volname 
		make /O /N=(row, col, length) $outname 
		make /O /N=(row, col, inhlength) $recname 
		make /O /N=(row, col, inhlength) $latname 
		wave v = $volname
		wave out = $outname
		wave rec = $recname
		wave lat = $latname

		dimname = "D_" + suffix
		make /O /N=(conlength) $dimname 
		wave dim = $dimname
		dim=0

		v = 0
		out = 0
		rec = 0
		lat = 0
		if (lateral == 1)
			outname_lat = "OL_" + suffix
			make /O /N=(row, col, inhlength) $outname_lat 
			wave out_lat = $outname_lat
			out_lat = 0
		endif
	print "     finished making waves."
	
	print "     starts calculation ( 0 -", num2str(length-1), ") ... "
	tindex = 0
	Do 
		print "       [", num2str(tindex), "]", time()
		rowindex = strow
		Do
			colindex = stcol
			Do
				a_wave = noiseFoldername + ":" + suffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave a = $a_wave
				cellname = ":Matrix:DMatrix25_" + num2str(rowindex) + "_" + num2str(colindex)
					wave cell = $cellname
				if (tindex == 0)
					vlast = -0.05
					vlast2 = -0.05
				elseif (tindex == 1)
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = -0.05
				else
					vlast = v[rowindex][colindex][tindex-1]
					vlast2 = v[rowindex][colindex][tindex-2]
				endif
				if (GJ)
					if (rowindex == strow)
						vleft = vlast
					else
						vleft = v[rowindex-1][colindex][tindex-1]
					endif
					if (rowindex == enrow-1)
						vright = vlast
					else
						vright = v[rowindex+1][colindex][tindex-1]
					endif
					if (colindex == stcol)
						vabove = vlast
					else
						vabove = v[rowindex][colindex-1][tindex-1]
					endif
					if (colindex == encol - 1)
						vbelow = vlast
					else
						vbelow = v[rowindex][colindex+1][tindex-1]
					endif
//					vspace = (vleft + vright + vabove + vbelow) * tauGJcoef * ratioGJ
					vspace = ((vleft + vright + vabove + vbelow)/4 - vlast) * ratioGJ
				endif
////////////////////////////////////////////////////////// saturation
				if (lat[rowindex][colindex][tindex] < thresSaturated)
					lat[rowindex][colindex][tindex] =  thresSaturated
					flagSaturated = 1
				endif
////////////////////////////////////////////////////////// saturation
				coef_cl = (vlast - Ecl)/(-0.05 - Ecl)
				if (inhrec)
					rec[rowindex][colindex][tindex] = rec[rowindex][colindex][tindex]*coef_cl
				endif
				if (inhlat)
					lat[rowindex][colindex][tindex] = lat[rowindex][colindex][tindex]*coef_cl
				endif
				if (signal == 1)
					signalname = signalsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
					wave sig = $signalname
					if (inhrec)
						if (inhlat)
							vnow = a[tindex] + sig[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
						else
							vnow = a[tindex] + sig[tindex] + rec[rowindex][colindex][tindex]
						endif
					else
						if (inhlat)
							vnow = a[tindex] + sig[tindex] + lat[rowindex][colindex][tindex]
						else
							vnow = a[tindex] + sig[tindex]
						endif
					endif	
				else
					if (inhrec)
						if (inhlat)
							vnow = a[tindex] + rec[rowindex][colindex][tindex] + lat[rowindex][colindex][tindex]
						else
							vnow = a[tindex] + rec[rowindex][colindex][tindex]
						endif
					else
						if (inhlat)
							vnow = a[tindex] + lat[rowindex][colindex][tindex]
						else
							vnow = a[tindex]
						endif
					endif
				endif
				if (tindex == 1)
					vnow = vlast + (vnow - vlast) * taucoef + (vspace) * tauGJcoef
				elseif (tindex > 1)
					vnow = ((vnow + vspace) * taucoef1) + (vlast * taucoef2) + (vlast2 * taucoef3)
//					vnow = vlast + (vnow - vlast) * taucoef + vspace
				endif
				v[rowindex][colindex][tindex] = vnow
				//////////////////////// write transform function (a = a_wave)
				//		out = (a+0.1)^20/((a+0.1)^20+(-.035+0.1)^20)
				//////////////////////////////////////////////////
				if (inhrec || inhlat)
					out[rowindex][colindex][tindex] = (vnow+0.1)^13/((vnow+0.1)^13+(-.035+0.1)^13)
				endif
				if (inhlat)
					//////////////////////// write transform function (a = a_wave)
					//		out_lat = (a+0.1)^20/((a+0.1)^20+(-.045+0.1)^20)
					//////////////////////////////////////////////////
					if (lateral == 1)
						out_lat[rowindex][colindex][tindex] = (vnow+0.1)^20/((vnow+0.1)^20+(-.044+0.1)^20)
					endif
				endif

				tlast = tindex + length - 1
				if (inhrec)
					rec[rowindex][colindex][tindex,tlast] += out[rowindex][colindex][tindex] * mIPSPrec[r-tindex]
				endif
				if (inhlat)
					if (lateral == 1)
						if (tindex < conlength)
							Redimension /N=(tindex+1) dim
						endif
						dim[] = out_lat[rowindex][colindex][tindex-p] * mIPSPlat[p+1]
						coef = sum(dim)
						lat[][][tindex+1] += coef * cell[p][q]
					else
						if (tindex < conlength)
							Redimension /N=(tindex+1) dim
						endif
						dim[] = out[rowindex][colindex][tindex-p] * mIPSPlat[p+1]
						coef = sum(dim)
						lat[][][tindex+1] += coef * cell[p][q]
					endif
				endif
				colindex += 1
			While(colindex < encol)
			rowindex += 1
		While(rowindex < enrow)
		if (flagSaturated)
			print "* lateral saturated (< ", num2str(thresSaturated) , " ) "
			flagSaturated = 0
		endif
		tindex += 1
	While(tindex < length)
	print "     finished calculation. "
End


macro calcInhWithAllBNconditions(stV, enV, stP, enP, stI, enI, makeBN, GJflag)
	variable makeBN=0
	variable stP, enP=3, stV, enV=4, stI, enI=7, GJflag=0
	prompt stV, "V from (5/10/20/50/100)"
	prompt enV, "to 0-4"
	prompt stP, "1/P from (50/10/2/1.25)"
	prompt enP, "to 0-3"
	prompt stI, "I from (no/pL/pH/sH/oL/oR/sL/pLL)"
	prompt enI, "to 0-7"
	prompt makeBN, "make BN at first? 0/1"
	prompt GJflag, "gap junction? 0/1"

	string targetFolder, signalname, iFolder, lista, a_wave
	string signalPrefix = "S10_", pstr, ROIname="ROIstim", ROIbgname="bg", ROIwavename, ROIbgwavename
	variable pindex, aindex, nindex, iindex, windex, stZ, enZ
	variable pnum, aV, amV

	aindex=stV
	Do
		if(aindex==0)
			aV = 0.005
		endif
		if(aindex==1)
			aV = 0.010
		endif
		if(aindex==2)
			aV = 0.020
		endif
		if(aindex==3)
			aV = 0.050
		endif
		if(aindex==4)
			aV = 0.100
		endif
//		if(aindex==5)
//			aV = 0.08
//		endif
		amV = aV*1000

		pindex=stP
		Do
			if(pindex==0)
				pnum=50	
				pstr = "50"
			endif
			if(pindex==1)
				pnum=10
				pstr = "10"
			endif
			if(pindex==2)
				pnum=2
				pstr = "2"
			endif
			if(pindex==3)
				pnum=1.25
				pstr = "1_25"
			endif
			if (makeBN)
				setDataFolder :signal
					nindex = 0
					Do
						signalname = signalPrefix + num2str(nindex)
						makeBinominalNoise(pnum,1,0,aV,1,200,1,40,signalname,3)
						nindex+=1
					while(nindex<40)
					vectorTo3D(waves="S10", type=0,row=40, col=40, imaginary=0, namewave="Matrix_S")
					Matrix_S = round(ceil(Matrix_S)-1)
					nindex=0
					Do
						make /O /b /u /N=(40, 40) $(ROIname + num2str(nindex))
						ROIwavename = ROIname + num2str(nindex)
						$(ROIwavename) = 1
						$(ROIwavename)[10,29][10,29] = Matrix_S[p][q][nindex*200]
						Matrix_S += 1
						Matrix_S -= 1
						makeROISurround(waves=ROIwavename, namewave=ROIbgname, stX=10, enX=29, stY=10, enY=29)
						ROIbgwavename = ROIbgname + ROIwavename
						targetFolder = "root:Gauss:smoothed:ROI:p" + pstr + "_" + num2str(amV) + "mV"
						newDataFolder /O $targetFolder
						moveWave $(ROIwavename), $(targetFolder+":")
						moveWave $(ROIbgwavename), $(targetFolder+":")
						nindex+=1
					While(nindex<5)
					moveWave Matrix_S, $(targetFolder+":")
				setDataFolder ::
			endif
			
			iindex = stI
			Do
				if (iindex == 0)
	calcBlockInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=0, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "noInhibition"
				endif
				if (iindex == 1)
	calcInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "population_low"
				endif
				if (iindex == 2)
	calcInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "population_high"
				endif
				if (iindex == 3)
	calcInh_single(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "single_high"
				endif
				if (iindex == 4)
	calcBlockInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, inhrec=0, inhlat=1, GJ=GJflag, tau=5)
	iFolder = "onlyLateral"
				endif
				if (iindex == 5)
	calcBlockInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=1, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "onlyReciprocal"
				endif
				if (iindex == 6)
	calcInh_single(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "single_low"
				endif
				if (iindex == 7)
	calcInh_population(suffix="I_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=2, GJ=GJflag, tau=5)
	iFolder = "population_lowlow"
				endif 

				imageStats3D(waves="V_I*", namewave="V", type=0, ROI="ROIimage", stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				transformWave(waves="V_I*", destname="Re", dpn=3)
				imageStats3D(waves="Re_V_I*", namewave="Re", type=0, ROI="ROIimage", stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				nindex=0
				Do
					targetFolder = "p" + pstr + "_" + num2str(amV) + "mV:"
					ROIwavename = "ROIstim" + num2str(nindex)
					ROIbgwavename = "bgROIstim" + num2str(nindex)
					stZ = nindex*200
					enZ = (nindex+1)*200-1
					imageStats3D(waves="V_I*", namewave="V", type=1, ROI=(targetFolder + ROIwavename), stX=10, enX=29, stY=10, enY=29, stZ=stZ, enZ=enZ)
					imageStats3D(waves="V_I*", namewave="V", type=1, ROI=(targetFolder + ROIbgwavename), stX=10, enX=29, stY=10, enY=29, stZ=stZ, enZ=enZ)
					sum2Waves(("V_avg_"+ROIwavename),("V_avg_"+ROIbgwavename),("V_dif_Stim"+num2str(nindex)),0,0,0,3,0)
					multiply2Waves(waves=("V_dif_Stim"+num2str(nindex)+"*"), wave2=("V_sd_"+ROIbgwavename), destname=("V_snr" + num2str(nindex)), mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
					imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=(targetFolder+ROIwavename), stX=10, enX=29, stY=10, enY=29, stZ=stZ, enZ=enZ)
					imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=(targetFolder+ROIbgwavename), stX=10, enX=29, stY=10, enY=29, stZ=stZ, enZ=enZ)
					sum2Waves(("Re_avg_"+ROIwavename),("Re_avg_"+ROIbgwavename),("Re_dif_Stim"+num2str(nindex)),0,0,0,3,0)
					multiply2Waves(waves=("Re_dif_Stim"+num2str(nindex)+"*"), wave2=("Re_sd_"+ROIbgwavename), destname=("Re_snr" + num2str(nindex)), mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
					nindex+=1
				While(nindex<5)

				targetFolder = "root:Gauss:smoothed:" + iFolder + ":BNp" + pstr + "_" + num2str(amV) + "mV"
				newDataFolder /O $targetFolder
				lista = wavelist("*", ";", "")
				windex=0
				a_wave = StringFromList(windex, lista)
				do
					moveWave $a_wave, $(targetFolder+":")
					windex+=1
					a_wave = StringFromList(windex, lista)
				while(strlen(a_wave)!=0)

				print "finished I", num2str(pnum), num2str(amV), "mV", iFolder
				saveexperiment
				print "*saved p", num2str(pnum), num2str(amV), "mV", iFolder
				iindex+=1
			While(iindex <= enI)
		stI = 0
		makeBN = 1
		pindex+=1
		While(pindex <= enP)
	stP=0
	aindex+=1
	While(aindex <= enV)


endmacro


macro calcInhWithSquareStims(stV, enV, stW, enW, stI, enI, makeStim, GJflag)
	variable makeStim=0
	variable stW, enW=4, stV, enV=4, stI, enI=7, GJflag=1
	prompt stV, "V from (5/10/20/50/100)"
	prompt enV, "to 0-4"
	prompt stW, "width from (400/100/25/50/25)"
	prompt enW, "to 0-4"
	prompt stI, "I from (no/pL/pH/sH/oL/oR/sL/pLL)"
	prompt enI, "to 0-7"
	prompt makeStim, "make stim at first? 0/1"
	prompt GJflag, "gap junction? 0/1"

	string targetFolder, signalname, iFolder, lista, a_wave
	string ROIstim, ROIedge, ROIsur, widthstr, rewavename
	variable widthindex, aindex, iindex, windex
	variable width, aV, amV
	variable rowfrom, rowto, colfrom, colto
	
	aindex=stV
	Do
		if(aindex==0)
			aV = 0.005
		endif
		if(aindex==1)
			aV = 0.010
		endif
		if(aindex==2)
			aV = 0.020
		endif
		if(aindex==3)
			aV = 0.050
		endif
		if(aindex==4)
			aV = 0.100
		endif
//		if(aindex==5)
//			aV = 0.08
//		endif
		amV = aV*1000

		widthindex=stW
		Do
			if(widthindex==0)
				width=400	
				widthstr = "400"
				rowfrom = 12
				rowto = 27
				colfrom = 12
				colto = 27
			endif
			if(widthindex==1)
				width=100
				widthstr = "100"
				rowfrom = 18
				rowto = 21
				colfrom = 18
				colto = 21
//				width=200
//				widthstr = "200"
//				rowfrom = 16
//				rowto = 23
//				colfrom = 16
//				colto = 23
			endif
			if(widthindex==2)
				width=25
				widthstr = "25"
				rowfrom = 20
				rowto = 20
				colfrom = 20
				colto = 20
//				width=100
//				widthstr = "100"
//				rowfrom = 18
//				rowto = 21
//				colfrom = 18
//				colto = 21
			endif
			if(widthindex==3)
				width=50
				widthstr = "50"
				rowfrom = 19
				rowto = 20
				colfrom = 19
				colto = 20
			endif
			if(widthindex==4)
				width=25
				widthstr = "25"
				rowfrom = 20
				rowto = 20
				colfrom = 20
				colto = 20
			endif
			ROIstim = "ROI" + num2str(width) + "umStim"
			ROIedge = "ROI" + num2str(width) + "umEdge"
			ROIsur = "ROI" + num2str(width) + "umSurround"

			if (makeStim)
				setDataFolder :signal
					assignValues(waves="*", destname="", type=0, value=0, sttime=-inf, entime=inf, dpn=3)
					assignSignals(strow=rowfrom, enrow=rowto, stcol=colfrom, encol=colto, sttime=250, entime=749, val=aV)
				setDataFolder ::
			endif
			
			iindex = stI
			Do
				if (iindex == 0)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=0, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "noInhibition"
				endif
				if (iindex == 1)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "population_low"
				endif
				if (iindex == 2)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "population_high"
				endif
				if (iindex == 3)
	calcInh_single(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "single_high"
				endif
				if (iindex == 4)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, inhrec=0, inhlat=1, GJ=GJflag, tau=5)
	iFolder = "onlyLateral"
				endif
				if (iindex == 5)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=1, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "onlyReciprocal"
				endif
				if (iindex == 6)
	calcInh_single(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "single_low"
				endif
				if (iindex == 7)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=2, GJ=GJflag, tau=5)
	iFolder = "population_lowlow"
				endif 
				imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIstim, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIedge, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIsur, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				transformWave(waves="V_I*", destname="Re", dpn=3)
				imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIstim, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIedge, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIsur, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				sum2Waves(("Re_avg_ROI" + widthstr + "umStim"),("Re_avg_ROI" + widthstr + "umSurround"),("Re_dif_" + widthstr + "umStim"),0,0,0,3,0)
				sum2Waves(("Re_avg_ROI" + widthstr + "umEdge"),("Re_avg_ROI" + widthstr + "umSurround"),("Re_dif_" + widthstr + "umEdge"),0,0,0,3,0)
				multiply2Waves(waves=("Re_dif_" + widthstr + "umStim*"), wave2=("Re_sd_ROI" + widthstr + "umSurround"), destname="Re_snr_", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
				multiply2Waves(waves=("Re_dif_" + widthstr + "umEdge*"), wave2=("Re_sd_ROI" + widthstr + "umSurround"), destname="Re_snr_", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)				
				targetFolder = "root:Gauss:smoothed:" + iFolder + ":d" + widthstr + "um" + num2str(amV) + "mV"
				newDataFolder /O $targetFolder
				lista = wavelist("*", ";", "")
				windex=0
				a_wave = StringFromList(windex, lista)
				do
					moveWave $a_wave, $(targetFolder+":")
					windex+=1
					a_wave = StringFromList(windex, lista)
				while(strlen(a_wave)!=0)

				print "finished ", widthstr, "um",  num2str(amV), "mV", iFolder
				saveexperiment
				print "*saved ", widthstr, "um",  num2str(amV), "mV", iFolder
				iindex+=1
			While(iindex <= enI)
//		stI = 0
		makeStim = 1
		widthindex+=1
		While(widthindex <= enW)
	stW=0
	aindex+=1
	While(aindex <= enV)

endmacro



macro calcInhPatternedStim(stI, enI, calcSNR, GJflag)
	variable stI, enI=7, calcSNR=0, GJflag=1
	prompt stI, "I from (no/pL/pH/sH/oL/oR/sL/pLL)"
	prompt enI, "to 0-7"
	prompt calcSNR, "calc SNR? 0/1"
	prompt GJflag, "gap junction? 0/1"

	string targetFolder, signalname, iFolder, lista, a_wave
	string ROIstim, ROIedge, ROIsur, rewavename
	variable iindex, windex
	variable rowfrom, rowto, colfrom, colto

	ROIstim = "ROIpatternStim"
//	ROIedge = "ROIpatternEdge"
	ROIsur = "ROIpatternSurround"
	iindex = stI
	Do
		if (iindex == 0)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=0, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "noInhibition"
		endif
		if (iindex == 1)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "population_low"
		endif
		if (iindex == 2)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "population_high"
		endif
		if (iindex == 3)
	calcInh_single(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, GJ=GJflag, tau=5)
	iFolder = "single_high"
		endif
		if (iindex == 4)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, inhrec=0, inhlat=1, GJ=GJflag, tau=5)
	iFolder = "onlyLateral"
		endif
		if (iindex == 5)
	calcBlockInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=0, inhrec=1, inhlat=0, GJ=GJflag, tau=5)
	iFolder = "onlyReciprocal"
		endif
		if (iindex == 6)
	calcInh_single(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=1, GJ=GJflag, tau=5)
	iFolder = "single_low"
		endif
		if (iindex == 7)
	calcInh_population(suffix="I_b_F_GaussSD10", signal=1, noiseFoldername=":noise", lateral=2, GJ=GJflag, tau=5)
	iFolder = "population_lowlow"
		endif 
		if (calcSNR)
			imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIstim, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
//			imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIedge, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
			imageStats3D(waves="V_I*", namewave="V", type=1, ROI=ROIsur, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
		endif
		transformWave(waves="V_I*", destname="Re", dpn=3)
		if (calcSNR)
			imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIstim, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
//			imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIedge, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
			imageStats3D(waves="Re_V_I*", namewave="Re", type=1, ROI=ROIsur, stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
			sum2Waves(wave1="Re_avg_ROI*Stim", wave2="Re_avg_ROI*Surround", destname="Re_dif_Stim",sumMethod=0,sttime=0,entime=0,dpn=3,printToCmd=0)
//			sum2Waves(("Re_avg_ROI*Edge"),("Re_avg_ROI*Surround"),("Re_dif_*Edge"),0,0,0,3,0)
			multiply2Waves(waves=("Re_dif_*Stim*"), wave2=("Re_sd_ROI*Surround"), destname="Re_snr_", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
//			multiply2Waves(waves=("Re_dif_*Edge*"), wave2=("Re_sd_ROI*Surround"), destname="Re_snr_", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)				
		endif
		targetFolder = "root:Gauss:smoothed:" + iFolder + ":pattern"
		newDataFolder /O $targetFolder
		lista = wavelist("*", ";", "")
		windex=0
		a_wave = StringFromList(windex, lista)
		do
			moveWave $a_wave, $(targetFolder+":")
			windex+=1
			a_wave = StringFromList(windex, lista)
		while(strlen(a_wave)!=0)

		print "finished ", iFolder
		saveexperiment
		print "*saved ", iFolder
		iindex+=1
	While(iindex <= enI)

endmacro


macro calcInhVibSquare(stW, enW, stV, enV, stI, enI, makeStim, GJflag)
	variable makeStim=0
	variable stW, enW=4, stV, enV=3, stI, enI=7, GJflag=1
	prompt stW, "width from (400/200/100/50/25)"
	prompt enW, "to 0-4"
	prompt stV, "V from (5/10/20/50)"
	prompt enV, "to 0-3"
	prompt stI, "I from (no/pL/pH/sH/oL/oR/sL/pLL)"
	prompt enI, "to 0-7"
	prompt makeStim, "make stim at first? 0/1"
	prompt GJflag, "gap junction? 0/1"

	string targetFolder, signalname, iFolder, lista, a_wave
	string ROIstim, ROIedge, ROIsur, widthstr, rewavename, stimname
	variable widthindex, aindex, iindex, windex, vFlag=1
	variable width, aV, amV
	variable rowfrom, rowto, colfrom, colto
	
	widthindex=stW
	Do
		if(widthindex==0)
			width=400	
			widthstr = "400"
			rowfrom = 12
			rowto = 27
			colfrom = 12
			colto = 27
		endif
		if(widthindex==1)
			width=200
			widthstr = "200"
			rowfrom = 16
			rowto = 23
			colfrom = 16
			colto = 23
		endif
		if(widthindex==2)
			width=100
			widthstr = "100"
			rowfrom = 18
			rowto = 21
			colfrom = 18
			colto = 21
		endif
		if(widthindex==3)
			width=50
			widthstr = "50"
			rowfrom = 19
			rowto = 20
			colfrom = 19
			colto = 20
		endif
		if(widthindex==4)
			width=25
			widthstr = "25"
			rowfrom = 20
			rowto = 20
			colfrom = 20
			colto = 20
		endif
		aindex=stV
		Do
			if(aindex==0)
				aV = 0.005
			endif
			if(aindex==1)
				aV = 0.010
			endif
			if(aindex==2)
				aV = 0.020
			endif
			if(aindex==3)
				aV = 0.050
			endif
//			if(aindex==4)
//				aV = 0.100
//			endif
//			if(aindex==5)
//				aV = 0.08
//			endif
			amV = aV*1000

			ROIstim = "ROI" + num2str(width) + "umStim"
			ROIedge = "ROI" + num2str(width) + "umEdge"
			ROIsur = "ROI" + num2str(width) + "umSurround"

			if (makeStim)
				NewPath pic, "C:\Users\MasashiTanaka\Documents\Data_ana\MATSUMOTO\patternedStim"
				stimname = "square" + widthstr + "um.bmp"
				imageload /O /T=bmp /P=pic stimname
				Redimension/N=(-1,-1) $stimname
				makeVibratingImages(waves="square*bmp", namewave="vib_", makeGauss=1, direction=2,  freq=10, SD=1, num=500)
				targetFolder = "root:Gauss:smoothed:patternStim:d" + widthstr + "um"
				newDataFolder /O $targetFolder
				lista = wavelist("*", ";", "")
				windex=0
				a_wave = StringFromList(windex, lista)
				do
					moveWave $a_wave, $(targetFolder+":")
					windex+=1
					a_wave = StringFromList(windex, lista)
				while(strlen(a_wave)!=0)
				makeStim=0
			endif
			if (vFlag)
				targetFolder = "root:Gauss:smoothed:patternStim:d" + widthstr + "um"
				setDataFolder $targetFolder
				ROItoVector(waves="vib*", namewave="S10", length=1000, onset=250, step=1, val=aV)
				vectorTo3D(waves="S10", type=0,row=40, col=40, imaginary=0, namewave="Matrix_S")
				targetFolder = "root:Gauss:smoothed:signal"
				if(dataFolderExists(targetFolder))
					killDataFolder $targetFolder
				endif
				newDataFolder $targetFolder
				lista = wavelist("S10*", ";", "")
				windex=0
				a_wave = StringFromList(windex, lista)
				do
					moveWave $a_wave, $(targetFolder+":")
					windex+=1
					a_wave = StringFromList(windex, lista)
				while(strlen(a_wave)!=0)
				moveWave Matrix_S $(targetFolder+":")
				setDataFolder root:Gauss:smoothed:
				vFlag = 0
			endif
			
			iindex = stI
			Do
				if (iindex == 0)
	calcInhPatternedStim(0, 0, 0, GJflag)
	iFolder = "noInhibition"
				endif
				if (iindex == 1)
	calcInhPatternedStim(1, 1, 0, GJflag)
	iFolder = "population_low"
				endif
				if (iindex == 2)
	calcInhPatternedStim(2, 2, 0, GJflag)
	iFolder = "population_high"
				endif
				if (iindex == 3)
	calcInhPatternedStim(3, 3, 0, GJflag)
	iFolder = "single_high"
				endif
				if (iindex == 4)
	calcInhPatternedStim(4, 4, 0, GJflag)
	iFolder = "onlyLateral"
				endif
				if (iindex == 5)
	calcInhPatternedStim(5, 5, 0, GJflag)
	iFolder = "onlyReciprocal"
				endif
				if (iindex == 6)
	calcInhPatternedStim(6, 6, 0, GJflag)
	iFolder = "single_low"
				endif
				if (iindex == 7)
	calcInhPatternedStim(7, 7, 0, GJflag)
	iFolder = "population_lowlow"
				endif
				slide3DImagesWithWaves(waves="Re*", namewave="s", xwave="I_F_Gauss_x_0", ywave="I_F_Gauss_y_0",  offset=250, num=500, sFolder=("patternStim:d" + widthstr + "um"))
				imageStats3D(waves="sRe*", namewave="Re", type=1, ROI=("ROI" + widthstr + "umStim"), stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="sRe*", namewave="Re", type=1, ROI=("ROI" + widthstr + "umEdge"), stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				imageStats3D(waves="sRe*", namewave="Re", type=1, ROI=("ROI" + widthstr + "umSurround"), stX=10, enX=29, stY=10, enY=29, stZ=-inf, enZ=inf)
				sum2Waves("Re_avg*Stim","Re_avg*Surround","Re_dif_",0,0,0,3,3)
				sum2Waves("Re_avg*Edge","Re_avg*Surround","Re_dif_edge",0,0,0,3,3)
				multiply2Waves(waves="Re_dif_0", wave2="Re_sd*Surround", destname="Re_snr", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
				multiply2Waves(waves="Re_dif_edge0", wave2="Re_sd*Surround", destname="Re_snr", mulMethod=0, sttime=-inf, entime=inf, dpn=3, printToCmd=0)
				targetFolder = "root:Gauss:smoothed:" + iFolder + ":d" + widthstr + "um" + num2str(amV) + "mV"
				newDataFolder /O $targetFolder
				lista = wavelist("*", ";", "")
				windex=0
				a_wave = StringFromList(windex, lista)
				do
					moveWave $a_wave, $(targetFolder+":")
					windex+=1
					a_wave = StringFromList(windex, lista)
				while(strlen(a_wave)!=0)

				print "finished ", widthstr, "um",  num2str(amV), "mV", iFolder
				saveexperiment
				print "*saved ", widthstr, "um",  num2str(amV), "mV", iFolder
				iindex+=1
			While(iindex <= enI)
		stW=0
		vFlag=1
		aindex+=1
		While(aindex <= enV)
	stI = 0
	makeStim = 1
	widthindex+=1
	While(widthindex <= enW)

endmacro


function calcEntropy([waves, destname, sttime, entime])
	String waves, destname
	Variable sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "nPattern*ratio"; destname = "ent";
		sttime = -inf; entime = inf;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. default \"ent\""
		Prompt sttime, "Range from"
		Prompt entime, "to"
		DoPrompt  "calcEntropy", waves, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcEntropy(waves=\"" + waves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	if (stringmatch(destname, ""))
		destname = "ent"
	endif

	string lista, a_wave, destwave, tmpwave
	variable windex=0, sumtmp, nindex=0, lend
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (sttime > entime)
			print "error: sttime > entime"
			abort
		endif
		tmpwave = "p_" + a_wave
		destwave = destname + "_" + a_wave
		Duplicate /O /R=(sttime,entime) $a_wave $tmpwave
		Duplicate /O $tmpwave $destwave
		wave tmp = $tmpwave
		wave d = $destwave
		sumtmp = sum(tmp)
		tmp = tmp/sumtmp
		d = -tmp * log(tmp) / log(2)
		lend = numpnts(d)
		nindex = 0
		Do
			if (numtype(d[nindex]) == 2)
				d[nindex] = 0
			endif
			nindex += 1
		While(nindex < lend)
		print "entropy: ", sum(d)
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End



function calcProb([waves, hwaves, destname, sttime, entime])
	String waves, hwaves, destname
	Variable sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "ent*spike*"; destname = "p"; hwaves="Sum_histo";
		sttime = 0; entime = 0.5;
		Prompt waves, "Wave names"
		Prompt hwaves, "histogram names"
		Prompt destname, "SUFFIX. default \"p\""
		Prompt sttime, "Range from"
		Prompt entime, "to"
		DoPrompt  "calcProb", waves, hwaves, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* calcProb(waves=\"" + waves + "\", hwaves=\"" + hwaves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	if (stringmatch(destname, ""))
		destname = "p"
	endif
	
		wave h = $hwaves
	string lista, listh, a_wave, destwave, h_wave
	variable windex=0, sumtmp, nindex=0, lend
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		destwave = destname + "_" + a_wave
		Make /N=100 /O $destwave
		wave d = $destwave
		lend = numpnts(d)
	Do
		wave a = $a_wave
		if (sttime > entime)
			print "error: sttime > entime"
			abort
		endif

		d[windex] = sum(a) * h[windex] / sum(h)
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	print sum(d)
End



function transToProb([waves, hwaves, destname, sttime, entime])
	String waves, hwaves, destname
	Variable sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "hoOs*spike1*"; destname = "p"; hwaves="Sum_histo";
		sttime = -inf; entime = inf;
		Prompt waves, "Wave names"
		Prompt hwaves, "histogram names"
		Prompt destname, "SUFFIX. default \"p\""
		Prompt sttime, "Range from"
		Prompt entime, "to"
		DoPrompt  "transToProb", waves, hwaves, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* transToProb(waves=\"" + waves + "\", hwaves=\"" + hwaves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	if (stringmatch(destname, ""))
		destname = "p"
	endif
	
	wave h = $hwaves
	string lista, listh, a_wave, destwave, h_wave
	variable windex=0, sumtmp, nindex=0, maxh, lena, numa
	maxh = sum(h)
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (sttime > entime)
			print "error: sttime > entime"
			abort
		endif
		destwave = destname + "_" + a_wave
		Duplicate /R=(sttime, entime) /O a, $destwave
		wave d = $destwave
		lena = numpnts(d)
		d = h[d[p]] / maxh
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	numa = windex

	//// make matrix waves
	vectorTo3D(waves="p_hoOs*", type=1,row=1, col=numa, imaginary=0, namewave="matrix_p")
	wave mp = $("matrix_p")
	Make/N=(lena,numa)/D /O matrix_p_raster
	Make/N=(lena,numa)/D /O matrix_i_raster
	matrix_p_raster = mp[r][q][p]
	matrix_i_raster = -log(matrix_p_raster[p][q][r])/log(2)

End


//// Igor demo functions /////


function templateMatching([waves, type, tempwave, tempnumwave, thres])
	String waves, tempwave, tempnumwave
	Variable type, thres
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "0*_Im*"; tempwave = "tempwave*"; tempnumwave = "template_sampleN"
		type=2; thres=2;
		Prompt waves, "wave name"
		Prompt type, "type 1/2 (add/not add to temp)"
		Prompt tempwave, "template wave name"
		Prompt tempnumwave, "tempN wave name"
		Prompt thres, "thres (t*SD, t(pA/ms))"
		DoPrompt  "templateMatching", waves, type, tempwave, tempnumwave, thres
		if (V_Flag)	// User canceled
			return -1
		endif
		print "templateMatching(waves=\"" + waves + "\", type=" + num2str(type) + ", tempwave=\"" + tempwave + "\", tempnumwave=\"" + tempnumwave + "\", thres=" + num2str(thres) + ")"
	endif

	string lista, listt, awave, cwave, twave, graphname, gtext, classwave, targetwave, classtext
	graphname = "tempmatch"
	if (waveexists($tempnumwave))
		wave tNw = $tempnumwave
	endif
	variable windex, normVal, tindex, rval, len_a, len_t
		lista = WaveList(waves,";","")
		len_a = ItemsInList(lista)
		classwave = "tempmatch_classified"
		Make /N=(len_a) /O $classwave
		wave clw = $classwave
		clw = -1
		windex = 0
		awave = StringFromList(windex, lista)
	Do
		cwave = "col_" + awave
		classtext = ""
		Duplicate /O $awave, $cwave
		listt = WaveList(tempwave,";","")
		len_t = ItemsInList(listt)
		tindex = 0
		twave = StringFromList(tindex, listt)
		if (!waveexists($tempnumwave))
			Display /N=$graphname $awave 
			modifyGraph rgb=(40000,40000,40000)
			DoWindow /F $graphname
			rval= Prompt_templateMatching(graphname, 0)
			if (rval == -1)		// Graph name error
				print "Graph name error."
				abort
			elseif (rval == 1)	// Ignore
				classtext = "user ignored " + awave
				DoWindow /K $graphname
			elseif (rval == 2)	// Create
				targetwave = "tempwave_" + num2str(len_t)
				Duplicate /O $awave, $targetwave
				clw[windex] = len_t
				Insertpoints len_t, 1, tNw
				DoWindow /K $graphname
				Make /N=1 $tempnumwave
				wave tNw = $tempnumwave
				tNw[len_t] = 1
				len_t += 1
				classtext = "user made " + awave + " as a template wave " + targetwave
			elseif (rval == 3)	// Kill
				Killwaves $awave
				Deletepoints windex, 1, clw
				DoWindow /K $graphname
				classtext = "user killed " + awave
			elseif (rval == 4)	// Cancel
				print "user canceled."
				abort
			endif
		else
			Do 
				WaveStats /Q $twave
				normVal = V_rms * sqrt(V_npnts)
				WaveStats /Q $cwave
				normVal = normVal * V_rms * sqrt(V_npnts)
				Correlate $twave, $cwave
				wave tw = $twave
				wave cw = $cwave
				wave aw = $awave
				cw /= normVal
				wavestats /Q $cwave
				if (thres <= V_max)
					tNw[tindex] += 1
					if (type == 1)
						tw = ( tw / tNw[tindex] * (tNw[tindex] - 1) ) + ( aw / tNw[tindex] ) 
					endif
					clw[windex] = tindex
					classtext = "classified " + awave + " as a template wave " + twave + " (thres: " + num2str(thres) + " <= corr: " +  num2str(V_max) + " )"
				else
					Display /N=$graphname $twave 
					AppendtoGraph $awave
					modifyGraph rgb($awave)=(20000,20000,20000)
					DoWindow /F $graphname
					gtext = "correlation : " + num2str(V_max) + " < thers ( " + num2str(thres) + " )"
					DrawText /W=$graphname 0.1, 0.8, gtext
					rval= Prompt_templateMatching(graphname, 1)
					if (rval == -1)		// Graph name error
						print "Graph name error."
						abort
					elseif (rval == 0)	// Match
						tNw[tindex] += 1
						if (type == 1)
							tw = ( tw / tNw[tindex] * (tNw[tindex] - 1) ) + ( aw / tNw[tindex] ) 
						endif
						clw[windex] = tindex
						DoWindow /K $graphname
						classtext = "user classified " + awave + " as a template wave " + twave
						break
					elseif (rval == 1)	// Non-Match
						classtext = "user ignored " + awave
						DoWindow /K $graphname
					elseif (rval == 2)	// Create
						targetwave = "tempwave_" + num2str(len_t)
						Duplicate /O $awave, $targetwave
						clw[windex] = len_t
						Insertpoints len_t, 1, tNw
						tNw[len_t] = 1
						len_t += 1
						DoWindow /K $graphname
						classtext = "user made " + awave + " as a template wave " + targetwave
						break
					elseif (rval == 3)	// Kill
						DoWindow /K $graphname
						Killwaves $awave
						Deletepoints windex, 1, clw
						classtext = "user killed " + awave
						break
					elseif (rval == 4)	// Cancel
						print "user canceled."
						abort
					endif
				endif
				tindex += 1
				twave = StringFromList(tindex, listt)
			While (strlen(twave)!=0)
		endif
		print "\t\t", windex, " : ", classtext
		Killwaves $cwave
		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
End


Function prompt_TemplateMatching(graphName, existTemp)
	String graphName
	variable existTemp
	DoWindow /F $graphName // Bring graph to front
	if (V_Flag == 0) // Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewDataFolder/O root:tmp_PauseforCursorDF
	Variable/G root:tmp_PauseforCursorDF:selected= -1
	NewPanel/K=2 /W=(139,300,582,500) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor // Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName // Put panel near the graph
	DrawText 21,20,"Adjust the cursors and then"
	DrawText 21,40,"Click Continue."
	if (existTemp)
		Button button0,pos={80,58},size={300,20},title= "Match"
		Button button0,proc= procTempMatch_Match
		Button button1,pos={80,80},size={300,20},title="Non-match"
		Button button1,proc= procTempMatch_NonMatch
	else
		Button button1,pos={80,80},size={300,20},title="Ignore"
		Button button1,proc= procTempMatch_NonMatch
	endif
	Button button2,pos={80,102},size={300,20},title= "Create a new template for this wave(black)"
	Button button2,proc= procTempMatch_Create
	Button button3,pos={80,124},size={300,20},title="Kill this wave(black)"
	Button button3,proc= procTempMatch_Kill
	Button button4,pos={80,146},size={300,20},title="Cancel"
	Button button4,proc= procTempMatch_Cancel

	PauseForUser tmp_PauseforCursor,$graphName
	NVAR gSelected =root:tmp_PauseforCursorDF:selected
	Variable lSelected = gSelected // Copy from global to local	
	// before global is killed
	KillDataFolder root:tmp_PauseforCursorDF
	return lSelected
End

Function procTempMatch_Match(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:selected= 0
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function procTempMatch_NonMatch(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:selected= 1
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function procTempMatch_Create(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:selected= 2
	DoWindow/K tmp_PauseforCursor // Kill self
End


Function procTempMatch_Kill(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:selected= 3
	DoWindow/K tmp_PauseforCursor // Kill self
End

Function procTempMatch_Cancel(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:selected= 4
	DoWindow/K tmp_PauseforCursor // Kill self
End

function analyzeSpikes([waves])
	String waves
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*_Vm*";
		Prompt waves, "wave name"
		DoPrompt  "analyzeWaves", waves
		if (V_Flag)	// User canceled
			return -1
		endif
		print "analyzeSpikes(waves=\"" + waves + "\")"
	endif

	string lista, awave, diffwave, filterwave, foundXwave, foundVwave, nAPwave, foundPXwave, foundPwave, targetname, regExpr, idstr
	variable foundN, findex, idnum, lowpass_cut, lowpass_start, lowpass_num, highpass_cut, highpass_start, highpass_num
	lowpass_start = 0.1	// 22.05 kHz * 0.1 = 2.205 kHz
	lowpass_cut = 0.3		// 22.05 kHz * 0.3 = 6.615 kHz
	lowpass_num = 101	// larger number gives better stop-band rejection 
	highpass_cut = 0.02	// 22.05 kHz * 0.02 = 441 Hz 
	highpass_start = 0.06	// 22.05 kHz * 0.06 = 1323 Hz
	highpass_num = 101	// larger number gives better stop-band rejection 
	variable windex=0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
	Do
		regExpr=".*_([0-9]+)"
		SplitString/E=(regExpr) awave, idnum
		idstr = num2str(idnum)
		filterwave = "fil_" + idstr
		diffwave = "dif_" + idstr

		foundXwave = "AP_X_" + awave
		foundVwave = "AP_V_" + awave
		foundPXwave = "AP_PeakX_" + awave
		foundPwave = "AP_Peak_" + awave
		nAPwave = "AP_n_" + awave[0,3]
		
		Duplicate /O $awave, $filterwave
		FilterFIR /HI={highpass_cut,highpass_start,highpass_num} /LO={lowpass_cut,lowpass_start,lowpass_num} $filterwave
		Duplicate /O $awave, $diffwave
		Differentiate $diffwave

		

		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
	extractAP(waves="110_fil", type=1, sttime=-inf, entime=inf, pol=0, thres=-15, dupst=-0.0005, dupen=0.001)
End



function analyzeBurst([waves, thres, sttime, entime])
	String waves
	Variable thres, sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "oOs*spike1*";
		thres = 200; sttime=0; entime=0.5;
		Prompt waves, "wave name (in time [s])"
		Prompt thres, "threshold [Hz] >="
		Prompt sttime, "range from [s]"
		Prompt entime, "to [s]"
		DoPrompt  "analyzeBurst", waves, thres, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "analyzeBurst(waves=\"" + waves + "\", thres=" + num2str(thres) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	string lista, awave,timewave, diffwave, xonwave, xoffwave, durwave, targetname, idstr, regstr
	variable foundN, findex, difflen, ii, thresT, flagBstSt, Nbst, idnum
	
	thresT = 1/thres

	variable windex=0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
	Do
		if (sttime > entime)
			print "error: sttime > entime"
			abort
		endif
		regstr = ".*_([0-9]+)"
		SplitString /E=(regstr) awave, idstr
		
		timewave = "t" + awave
		diffwave = "d_t" + awave
		xonwave = "Bst_X_" + idstr
		xoffwave = "Bst_Xoff_" + idstr
		durwave = "Bst_dur_" + idstr
		
		Make /O /N=0 $xonwave
		Make /O /N=0 $xoffwave
		Make /O /N=0 $durwave
		wave xon = $xonwave
		wave xoff = $xoffwave
		wave durw = $durwave
		DuplicateWave(wave1=awave, destname="t", sttime=-inf, entime=inf, sty=sttime, eny=entime, num=0, dpn=3, printToCmd=0)
		stepdifWave(waves=timewave, destname="d")
		wave wtime = $timewave
		wave wdiff = $diffwave
		difflen = numpnts(wdiff)
		Nbst = -1
		flagBstSt = 0
		for (ii=0; ii<difflen; ii+=1)
			if (wdiff[ii] <= thresT)
				if (flagBstSt == 0)
					Nbst += 1
					insertpoints Nbst, 1, xon
					insertpoints Nbst, 1, xoff
					insertpoints Nbst, 1, durw
					xon[Nbst] = wtime[ii]
					durw[Nbst] = wdiff[ii]
					xoff[Nbst] = wtime[ii+1]
					flagBstSt = 1
				else
					durw[Nbst] += wdiff[ii]
					xoff[Nbst] = wtime[ii+1]
				endif
			else
				flagBstSt = 0				
			endif
		endfor

		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
End
