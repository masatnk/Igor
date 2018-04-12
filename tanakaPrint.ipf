#pragma rtGlobals=1		// Use modern global access method.


menu "tanakaPrint"
	"printAvg"
	"printPercentile"
	"printVar"
	"printY"
	"printYRange"
	"printdCmPPD20"
	"printdCmPPD200"
	"printdCm1500"
	"printZeroCrossWidth"
	"printPeaks"
	"printDuration"
	"printSpont"
	"printHalfDecay"
	"saveWaves"
	"printPearsonR"
end



function printAvg ([wave1, sttime, entime, step, dur])
	String wave1
	Variable sttime, entime, step, dur
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "*";
		sttime=-inf; entime=inf; step=0; dur=0
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt step, "increment (ms) (0 for avg of RANGE)"
		Prompt dur, "duration (ms) (unless increment is 0, specify range)"
		DoPrompt  "printAvg", wave1, sttime, entime, step, dur
		if (V_Flag)	// User canceled
			return -1
		endif
		print "printAvg(wave1=\"" + wave1 + "\",sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ",  step=" + num2str(step) + ", dur=" + num2str(dur) + ")"
	endif
	
	step /= 1000			// [sec]
	
	variable currentX
	string lista, a_wave
	lista = WaveList(wave1,";","")
	variable windex=0
	a_wave = StringFromList(windex, lista)
	string savename = "printavg_result"
	make /O /N=0 $savename
	wave savew = $savename
	variable nsavew
	Do
		if(entime<sttime)
				abort
		endif
		wave aw = $a_wave
		currentX = sttime
		if (step == 0)
			wavestats /Q/R=(sttime, entime) $a_wave
			print " * avg of ", a_wave, " (", sttime, " - ", entime, ") is = ", V_avg
			nsavew = numpnts(savew)
			insertpoints  nsavew, 1,  savew
			savew[nsavew + 1] = V_avg
		else
			Do
				wavestats /Q/R=(currentX, currentX+dur) $a_wave
				print " * avg of ", a_wave, " (", currentX, " - ", currentX+dur, ") is = ", V_avg
				nsavew = numpnts(savew)
				insertpoints  nsavew, 1,  savew
				savew[nsavew + 1] = V_avg
				currentX += step
			while(currentX+dur <= entime && currentX+dur <= pnt2x(aw, numpnts(aw)-1))
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	while(strlen(a_wave)!= 0)
	Beep
End



function printPercentile ([wave1, percentile, stt, ent, suffix, step, kill, printToCmd])
	String wave1, suffix
	Variable stt, ent, step, kill, percentile, printToCmd
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "*"; suffix="hist_"
		stt=-inf; ent=inf; step=0; kill=1; percentile=0.5; printToCmd = 1;
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt percentile,"PERCENTILE (if 0.5; median)"
		Prompt stt,"RANGE from (sec, if 0; leftx)"
		Prompt ent,"to (sec, if 0; rightx)"
		Prompt suffix, "SUFFIX for the destination wave"
		Prompt step, "Bin for Histogram (if 0: sdev/30)"
		Prompt kill, "kill waves? 0/1(No/Yes)"
		Prompt printToCmd, "Print? 0/1(No/Yes)"
		DoPrompt  "printPercentile", wave1, percentile, stt, ent, suffix, step, kill, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "printPercentile(wave1=\"" + wave1 + "\",percentile=" + num2str(percentile) + ", stt=" + num2str(stt) + ", ent=" + num2str(ent) + ", step=" + num2str(step) + ",suffix=\"" + suffix + "\", kill=" + num2str(kill) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	string lista , a_wave, destwave, awave, cumwave, cmd
	variable windex=0,  sttime, entime
	lista = WaveList(wave1,";","")
	a_wave = StringFromList(windex, lista)
	Do
		if(stt==-inf)
			sttime = leftx($a_wave)
		else
			sttime = stt
		endif
		if(ent==inf)
			entime = rightx($a_wave)
		else
			entime = ent
		endif
		if(entime<=sttime)
				abort
		endif
		destwave = suffix + a_wave
		Duplicate /R=(sttime,entime)/O $a_wave $destwave
		if (step == 0)
			wavestats /Q /R=(sttime, entime) $a_wave
			step = V_sdev / 30
		else
			wavestats /Q /R=(sttime, entime) $a_wave
		endif
		K17 = V_avg // average
		histogram /B={(V_min-10*step), step, (V_max-V_min)/step + 21} /R=(sttime, entime) $a_wave, $destwave
//		smooth /B=5, 2, $destwave
		//sprintf cmd, "cumulatePlot(\"%s\", 0, 0, 0, 0, 1, \"%s\", 0, 0)", destwave, destwave
		//print cmd
		//Execute /Q cmd
		
		cumulatePlot(wave1=destwave, step=0, sttime=-inf, entime=inf, integration=0, flagNorm=1, destname=destwave, dpn=0, printToCmd=0)
		cumwave = "Cum0_" + destwave
		K19 = pnt2x( $cumwave, binarySearch($cumwave, percentile) ) // percentile
		if (printToCmd)
			print " * * * * ", percentile, " of ", a_wave, " ( ", sttime, " to ", entime, " )  . . . ", pnt2x( $cumwave, binarySearch($cumwave, percentile) )
			print " * * * * V_sdev = ", V_sdev, "; step = ", step
		endif
		waveStats /Q $destwave
		K18 = V_maxloc // mode
		if (printToCmd)
			print " * * * * mode : ", K18
			print " * * * * avg : ", K17
		endif
		if (kill)
			killwaves $destwave
			killwaves $cumwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End

macro printVar(wave1, sttime, entime)
	String wave1
	Variable sttime=0, entime=0
	Prompt wave1, "Wave name"//, popup wavelist ("*",";","")
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	Silent 1

	string lista , a_wave
	variable windex=0, length, V_var, avgAvg=0, avgVar=0, avgCV=0, avgSD=0, nind = 0
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		length =  deltax($a_wave)*(numpnts($a_wave)-1)
		if(sttime==0 && entime==0)
			entime = length
		endif
		if(entime<sttime)
				abort
		endif
		wavestats /Q/R=(sttime, entime) $a_wave
			V_var = V_sdev*V_sdev
			print " ", a_wave, " (", sttime, "to", entime, ") : avg ... ", V_avg, "; SD ... ", V_sdev, "; CV ... ", V_sdev/V_avg
			if(windex == 0)
				avgAvg = V_avg
				avgVar = V_var
				avgSD = V_sdev
				avgCV = V_sdev/V_avg
			else
				if (V_avg != 0)
					avgAvg = avgAvg*(windex-nind)/(windex+1-nind) + V_avg/(windex-nind+1)
					avgVar = avgVar*(windex-nind)/(windex+1-nind) + V_var/(windex-nind+1)
					avgSD = avgSD*(windex-nind)/(windex+1-nind) + V_sdev/(windex-nind+1)
					avgCV = avgCV*(windex-nind)/(windex+1-nind) + (V_sdev/V_avg)/(windex-nind+1)
				else
					nind += 1
				endif
			endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	print " * avgAvg ... ", avgAvg, "; avgVar ... ", avgVar, "; avgSD ... ", avgSD, "; avgCV ... ", avgCV

end


macro printY (wave1, step, sttime, entime)
	String wave1
	Variable step=0, sttime=0, entime=0, dpn=1
	Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
	Prompt step, "increment (ms)"
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	Silent 1
	
	step /= 1000			// [sec]
	
	variable currentX
	string lista, a_wave
	lista = WaveList(wave1,";","")
	variable windex=0
	a_wave = StringFromList(windex, lista)
	Do
		if(entime<sttime)
				abort
		endif
		currentX = sttime
		if (step == 0)
			print " * Y of ", a_wave, " (", currentX, ") is ... ", $a_wave[x2pnt($a_wave,currentX)]
		else
			Do
				print " * Y of ", a_wave, " (", currentX, ") is ... ", $a_wave[x2pnt($a_wave,currentX)]
				currentX += step
			while(currentX <= pnt2x($a_wave, numpnts($a_wave)-1))
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	while(strlen(a_wave)!= 0)
	Beep
End


macro printYRange(target, target2, flag, t_start, t_end)
variable flag=0, t_start, t_end
string target, target2, list
prompt flag, "enter / from the list (0/1)"
prompt target, "0 : enter the wave to analyse"
prompt target2, "1 : from the list", popup, WaveList("*",";","")
prompt t_start, "from (ms)"
prompt t_end, "to (ms)"

if (flag)
	list = WaveList(target2, ";", "")
else
	list = WaveList(target,";","")
endif
	variable i = 0
	string awave
	awave = StringFromList (i, list)
	if (t_end == 0)
		t_end = deltax($awave)*(numpnts($awave)-1)
	endif
	do
		waveStats /Q /R=(t_start, t_end) $awave
		print "    * ", awave, "(", t_start, "-", t_end, ")"
		print " . . . range : ", V_min, "(", V_minloc, ") - ", V_max, "(", V_maxloc, ") average : ", V_avg
		print " . . . amplitude : ", (V_max - V_min) / 2, ", cycle/2 : ", (V_minloc - V_maxloc)
		i += 1
		awave = StringFromList (i, list)
	while (waveexists($awave))
end

macro  printdCmPPD20()
printAvg("W*5",1.4,1.45,0,0)
printAvg("W*5",1.82,1.87,0,0)
printAvg("W*5",2.24,2.29,0,0)
endmacro

macro  printdCmPPD200()
printAvg("W*5",1.4,1.45,0,0)
printAvg("W*5",2.2,2.25,0,0)
printAvg("W*5",3.1,3.15,0,0)
endmacro

macro  printdCm1500()
printAvg("W*5",1.4,1.45,0,0)
printAvg("W*5",5,5.05,0,0)
endmacro

macro printZeroCrossWidth(wave1, crossVal, width, widthMin)
	variable crossVal=0, width = 5, widthMin = 0.05
	string wave1 = "AvgAuto"
	Prompt wave1, "Wave name"//, popup wavelist ("*",";","")
	Prompt crossVal, "crossing value(y)"
	Prompt width, "width"
	Prompt widthMin, "width min"

	string lista, a_wave
	variable windex=0
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		do
			findlevels /Q /M=(widthMin) /R=(-width/2, width/2) $a_wave, crossVal
			width = width - 0.1
		while (numpnts(W_FindLevels) > 2)
		if (exists("W_Findlevels"))
			width = W_FindLevels[1] - W_FindLevels[0]
			print ". . . width : " + num2str(width) + " ( "  + num2str(W_FindLevels[0]) + " and " + num2str(W_FindLevels[1]) + " ) crossing Value = " + num2str(crossVal)
		else
			print ". . . coudn't find crossing point"
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	while(strlen(a_wave)!= 0)

endmacro

function printPeaks ([wave1, thresholdType, threshold, polarity, sttime, entime, thresholdSttime, thresholdEntime, baselinetype, dpn])
	String wave1
	Variable sttime, entime, thresholdSttime, thresholdEntime, thresholdType, threshold, baselinetype, polarity, dpn
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		sttime=-inf; entime=inf; thresholdSttime=-inf; thresholdEntime=inf; thresholdType=0; threshold=0; baselinetype = 1; polarity=0; dpn=0;
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt thresholdType,"type 0/1/2/3(max/x/SD*x/IQR*x)"
		Prompt threshold,"thres (x)" // IQR*0.7413
		Prompt polarity, "polarty (0/1: -/+)"
		Prompt sttime,"RANGE from (sec, if 0; leftx)"
		Prompt entime,"to (sec, if 0; rightx)"
		Prompt thresholdSttime,"thresRANGE(mode)"
		Prompt thresholdEntime,"to (sec, if 0; rightx)"
		Prompt baselinetype, "0/1(Avg/mode)"
		Prompt dpn, "figure 0/1(none/display)"
		DoPrompt  "printPeaks", wave1, thresholdType, threshold, polarity, sttime, entime, thresholdSttime, thresholdEntime, baselinetype, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "printPeaks(wave1=\"" + wave1 + "\", thresholdType=" + num2str(thresholdType) + ", threshold=" + num2str(threshold) + ", polarity=" + num2str(polarity) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", thresholdSttime=" + num2str(thresholdSttime) + ", thresholdEntime=" + num2str(thresholdEntime) + ", baselinetype=" + num2str(baselinetype) + ", dpn=" + num2str(dpn) + ")"
	endif

	string lista , a_wave, destwave, awave, cumwave, peakwave, name_findlevels, peakxwave, ampwave
	name_findlevels = "W_FindLevels"
		lista = WaveList(wave1,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
	variable hitNum=0, peakValue=0, peakLoc=0, i=0, tRise=0, tDecay=0, tThresStart=0, tThresEnd=0, thres=0, rest=0
	variable avgPeak=0, avgAmp = 0, avgTRise=0, avgTDecay=0, Q1=0, Q3=0, IQR = 0, avgHitNum=0, nonNum=0, baseline
	variable stt, ent, thstt, thent
	Do
		if (sttime == -inf)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if (entime == inf)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		if (thresholdSttime == -inf)
			thstt = leftx($a_wave)
		else
			thstt = thresholdSttime
		endif
		if (thresholdEntime == inf)
			thent = rightx($a_wave)
		else
			thent = thresholdEntime
		endif
		if(ent<=stt || thent<=thstt)
				abort
		endif
		destwave = a_wave
		if (dpn)
			display $destwave
		endif
		thres = threshold

		if (thresholdType == 0)		// threshold = max, resting = mode
			wavestats /Q /R=(stt, ent) $destwave
			if (polarity == 0)
				peakValue = V_min
				peakLoc = V_minloc
			else
				peakValue = V_max
				peakLoc = V_maxloc
			endif
			printPercentile (wave1=a_wave, percentile=0.5, stt=thstt, ent=thent, suffix="per", step=0, kill=1, printToCmd=0)
				avgPeak = avgPeak + peakValue
			if (baselinetype == 0) // avg
				baseline = K17
			endif
			if (baselinetype == 1) // mode
				baseline = K18
			endif
				avgAmp = avgAmp + peakValue - baseline
				if (dpn)
					SetDrawEnv xcoord= bottom
					SetDrawEnv ycoord= left
					drawLine peakLoc, peakValue, peakLoc, baseline
					setAxis bottom, stt, ent
				endif
				if (dpn == 1)
					print " . . . Peak of", a_wave, " = ", peakValue, " ( ", peakLoc, " sec ) "
					print " . . . . . amplitude = ", peakValue - baseline, " [peak - baseline] )"
					print " . . . . . baseline = ", baseline
				endif
		else
			if (thresholdType == 2)		// threshold = x*SD, resting = avg
				wavestats /Q /R=(stt, ent) $destwave
				if (polarity == 0)
					peakValue = V_min
					peakLoc = V_minloc
				else
					peakValue = V_max
					peakLoc = V_maxloc
				endif
				wavestats /Q /R=(thstt, thent) $destwave
				if (polarity)
					thres = V_sdev * threshold + V_avg
				else
					thres = - V_sdev * threshold + V_avg
				endif
				rest = V_avg
				avgPeak = avgPeak + peakValue
				avgAmp = avgAmp + peakValue - rest
				if (dpn == 1)
					print " . . . Peak of", a_wave, " = ", peakValue, " ( ", peakLoc, " sec ) "
					print " . . . . . amplitude = ", peakValue - rest, " [peak - avg] )"
					print " . . . . . Avg = ", rest
				endif
			endif
			if (thresholdType == 3)		// threshold = x*IQR, resting = mode
				printPercentile (wave1=a_wave, percentile=0.75, stt=thstt, ent=thent, suffix="per", step=0, kill=1, printToCmd=0)
					Q3 = K19
				printPercentile (wave1=a_wave, percentile=0.25, stt=thstt, ent=thent, suffix="per", step=0, kill=1, printToCmd=0)
					Q1 = K19
				if (polarity)
					IQR = Q3-Q1
				else
					IQR = Q1-Q3
				endif
				rest = K18
				thres = rest + IQR * threshold
			endif
			if (polarity)
				findlevels /EDGE=1 /Q /R=(stt, ent) $destwave, thres
			else
				findlevels /EDGE=2 /Q /R=(stt, ent) $destwave, thres
			endif
			wave levels = $name_findlevels
			hitNum=0
			peakValue=0
			tRise = 0
			tDecay = 0
			tThresStart = 0
			tThresEnd = 0
			nonNum = 0
			peakwave = "pk" + a_wave
			ampwave = "amp" + a_wave
			peakxwave = "pkx" + a_wave
			Make /O /N=(V_LevelsFound) $peakwave
			Make /O /N=(V_LevelsFound) $ampwave
			Make /O /N=(V_LevelsFound) $peakxwave
			wave pkwave = $peakwave
			wave amwave = $ampwave
			wave pkxwave = $peakxwave
			pkwave = 0
			amwave = 0
			pkxwave = 0
			i = V_LevelsFound-2
			DO
				tThresStart = levels[i]
				tThresEnd = levels[i+1]
				wavestats /Q /R=[x2pnt($destwave, tThresStart), x2pnt($destwave, tThresEnd)-1] $destwave
//				wavestats /Q /R=(tThresStart, tThresEnd) $destwave
				if (polarity)
					
					if(V_max > thres)
						hitNum = hitNum + 1
						pkwave[i] = V_max
						amwave[i] = V_max - rest
						pkxwave[i] = V_maxloc
						peakValue = peakValue + V_max
						tRise = tRise + V_maxloc - tThresStart
						tDecay = tDecay + tThresEnd - V_maxloc
						if (dpn)
							SetDrawEnv xcoord= bottom
							SetDrawEnv ycoord= left
							drawLine V_maxloc, V_max, V_maxloc, thres
							setAxis bottom, stt, ent
						endif
					else
						deletepoints i, 1, pkwave
						deletepoints i, 1, amwave
						deletepoints i, 1, pkxwave
					endif
				else
					if(V_min < thres)
						hitNum = hitNum + 1
						pkwave[i] = V_min
						amwave[i] = V_min - rest
						pkxwave[i] = V_minloc
						peakValue = peakValue + V_min
						tRise = tRise + V_minloc - tThresStart
						tDecay = tDecay + tThresEnd - V_minloc
						if (dpn)
							SetDrawEnv xcoord= bottom
							SetDrawEnv ycoord= left
							drawLine V_minloc, V_min,V_minloc, thres
							setAxis bottom, stt, ent
						endif
					else
						deletepoints i, 1, pkwave
						deletepoints i, 1, amwave
						deletepoints i, 1, pkxwave
					endif
				endif
				i-=1
			while(i>=0)

			// last
			wavestats /Q /R=(levels(V_LevelsFound-1), entime)  $destwave
			if (polarity)
				if(V_max > thres && V_maxloc != entime)
					hitNum = hitNum + 1
					pkwave[numpnts(pkwave)-1] = V_max
					amwave[numpnts(amwave)-1] = V_max - rest
					pkxwave[numpnts(pkxwave)-1] = V_maxloc
					peakValue = peakValue + V_max
					tRise = tRise + V_maxloc - tThresStart
					tDecay = tDecay + tThresEnd - V_maxloc
					if (dpn)
						SetDrawEnv xcoord= bottom
						SetDrawEnv ycoord= left
						drawLine V_maxloc, V_max, V_maxloc, thres
						setAxis bottom, stt, ent
					endif
				else
					deletepoints numpnts(pkwave)-1, 1, pkwave
					deletepoints numpnts(amwave)-1, 1, amwave
					deletepoints numpnts(pkxwave)-1, 1, pkxwave
				endif
			else
				if(V_min < thres && V_minloc != entime)
					hitNum = hitNum + 1
					pkwave[numpnts(pkwave)-1] = V_min
					amwave[numpnts(amwave)-1] = V_min - rest
					pkxwave[numpnts(pkxwave)-1] = V_minloc
					peakValue = peakValue + V_min
					tRise = tRise + V_minloc - tThresStart
					tDecay = tDecay + tThresEnd - V_minloc
					if (dpn)
						SetDrawEnv xcoord= bottom
						SetDrawEnv ycoord= left
						drawLine V_minloc, V_min,V_minloc, thres
						setAxis bottom, stt, ent
					endif
				else
					deletepoints numpnts(pkwave)-1, 1, pkwave
					deletepoints numpnts(amwave)-1, 1, amwave
					deletepoints numpnts(pkxwave)-1, 1, pkxwave
				endif
			endif

			if (hitNum != 0)
				peakValue = peakValue / hitNum
				tRise = tRise / hitNum
				tDecay = tDecay / hitNum
				nonNum += 1
			endif
			printPercentile (wave1=destwave, percentile=0.5, stt=thstt, ent=thent, suffix="per", step=0, kill=1, printToCmd=0)
				avgPeak = avgPeak + peakValue - K18
				avgTRise = avgTRise + tRise
				avgTDecay = avgTDecay + tDecay
				avgHitNum = avgHitNum + hitNum
					//print " peakValue = ", peakValue, " ( N=", hitNum, "; threshold = ", thres, " )"
					//print " mode = ", K18
					//print " * Peak of", a_wave, " = ", peakValue - K18, " (avgPeak - mode)"
					//print " * tRise = ", tRise , " ; tDecay = ", tDecay
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	if (thresholdType == 0)
		if (windex - nonNum != 0)
			avgPeak = avgPeak / (windex - nonNum)
			avgAmp = avgAmp / (windex - nonNum)
				//print " * avgPeak = ", avgPeak, "; avgAmp = ", avgAmp
				//print " * * * * END * * * * * * * * * * * * * * *"
		endif
	else
		if (windex - nonNum != 0)
			avgPeak = avgPeak / (windex - nonNum)
			avgTRise = avgTRise / (windex - nonNum)
			avgTDecay = avgTDecay / (windex - nonNum)
			avgHitNum = avgHitNum / (windex - nonNum)
			if (thresholdType != 0)
				//print " * * * * avgPeak = ", avgPeak, " ; avgTRise = ", avgTRise, " ; avgTDecay = ", avgTDecay, " ; avgN = ", avgHitNum
				//print " * * * * END * * * * * * * * * * * * * * *"
			endif
		endif
	endif
End

macro printDuration (wave1, polarity, sttime, entime, type, thresPrompt, thresholdSttime, thresholdEntime, printToCmd, dpn)
	String wave1
	Variable sttime=0.2, entime=0.4, polarity=0, type=3, thresPrompt=0, thresholdSttime=0, thresholdEntime=0.2, printToCmd = 1, dpn=1
	Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
	Prompt polarity, "polarty (0/1: -/+)"
	Prompt sttime,"from (sec, if 0; leftx)"
	Prompt entime,"to (sec, if 0; rightx)"
	Prompt type, "type0-5(dif/x/SD*x/IQR*x/FWHM/matu)"
	Prompt thresPrompt, "threshold (x)"
	Prompt thresholdSttime,"thresRANGE from (sec, if 0; leftx)"
	Prompt thresholdEntime,"to (sec, if 0; rightx)"
	Prompt printToCmd, "Print? 0/1(No/Yes)"
	Prompt dpn, "Graph? 0/1/2 (No/Yes/append)"
	Silent 1

	if(sttime==0 && entime==0)
		sttime = leftx($a_wave)
		entime = rightx($a_wave)
	endif
	if(thresholdSttime==0 && thresholdEntime==0)
		thresholdSttime = leftx($a_wave)
		thresholdEntime = rightx($a_wave)
	endif
	if(entime<=sttime || thresholdEntime<=thresholdSttime)
			abort
	endif

	string lista , a_wave, destwave, awave
		lista = WaveList(wave1,";","")
		variable windex=0
		variable Q1=0, Q3=0, IQR=0
		a_wave = StringFromList(windex, lista)
	variable duration=0, onset=0, offset=0, i=0, lastSignal = 0, lastFlag = 0, resting=0, threshold=0
	variable Avg_dur=0, Avg_onset=0, Avg_offset=0, Avg_thres=0, Avg_rest=0, Avg_peak=0
	variable red =40000, green=0, blue=0
	Do
		if (type == 5)
			destwave = "s5_150" + a_wave
			Duplicate /O $a_wave $destwave
			smooth /B=5 150, $destwave
			display $a_wave
			ModifyGraph rgb($a_wave)=(0,0,0)			
		else
			destwave = a_wave
		endif
		if (dpn == 1)
			display $destwave
			ModifyGraph rgb($destwave)=(10000,10000,10000)
		endif
		if (dpn == 2)
			append $destwave
			ModifyGraph rgb($destwave)=(abs(enoise(65535)),abs(enoise(65535)),abs(enoise(65535)))
			if (type == 5)
				ModifyGraph rgb($destwave)=(30000,30000,30000)
			endif
		endif

		duration = 0
		resting = 0
		onset=0
		offset=0
		threshold = 0
		if (type == 2 || type == 5)
			wavestats /Q /R=(thresholdSttime, thresholdEntime) $destwave
			resting = V_avg
			if (polarity)
				threshold = V_sdev * thresPrompt + resting
			else
				threshold = - V_sdev * thresPrompt + resting
			endif
		endif
		if (type == 3)
			printPercentile (wave1=destwave, percentile=0.75, stt=thresholdSttime, ent=thresholdEntime, suffix="per", step=0, kill=1, printToCmd=0)
				Q3 = K19
			printPercentile (wave1=destwave, percentile=0.25, stt=thresholdSttime, ent=thresholdEntime, suffix="per", step=0, kill=1, printToCmd=0)
				Q1 = K19
			if (polarity)
				IQR = Q3-Q1
			else
				IQR = Q1-Q3
			endif
			resting = K18
			threshold = resting + IQR * thresPrompt
		endif
		if (type == 4)
			wavestats /Q /R=(sttime, entime) $destwave
			if (polarity)
				Avg_peak = V_max
			else
				Avg_peak = V_min
			endif			
			wavestats /Q /R=(thresholdSttime, thresholdEntime) $destwave
			resting = V_avg
			threshold = (Avg_peak + resting)/2
		endif

		findlevels /Q /R=(sttime, entime) $destwave, threshold
		i=0
		lastSignal = numpnts(W_FindLevels)-1
		print " . . . ", lastSignal, " crossing"
		lastFlag = 0
		do
			if (mod(i, 2) == 1 && lastFlag == 0) // signal decaying phase
				if(W_FindLevels[i+1] - W_FindLevels[i] > 0.03) // abort if no signal more than 30 ms
					lastSignal = i
					lastFlag = 1
				endif
			endif
			i += 1
		while(i < (numpnts(W_FindLevels)-1))
		offset = W_FindLevels[lastSignal]
		onset = W_FindLevels[0]
		duration = offset - onset
		if (printToCmd)
			print " . . . ", destwave
			print "           duration = ", duration, " ( ", onset , " - ", offset, " ) "
			print "           resting = ", resting, " , threshold = ", threshold
		endif
		if (dpn==1 || dpn==2)
			SetDrawEnv xcoord= bottom, ycoord= left
			SetDrawEnv linefgc=(red,green,blue)
			drawLine onset, threshold, offset, threshold
			setAxis bottom, sttime, entime
		endif
		Avg_dur += duration
		Avg_onset += onset
		Avg_offset += offset
		Avg_thres += threshold
		Avg_rest += resting
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	Avg_dur /= windex
	Avg_onset /= windex
	Avg_offset /= windex
	Avg_thres /= windex
	Avg_rest /= windex
	if (printToCmd)
		print " * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
		print " * avgDuration = ", Avg_dur, " ( ", Avg_onset , " - ", Avg_offset, " ) "
		print " *    threshold = ", Avg_thres
		print " *    resting = ", Avg_rest
		print " * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
	endif
End


macro printSpont (wave1, destname, offsetMethod, smoothNum)
	String wave1="*4", destname
	variable offsetMethod=0, smoothNum=1
	Prompt wave1, "spont wave name"
	prompt destname, "SUFFIX of destination wavename"
	Prompt offsetMethod, "offset method (0/1 : mode/median)"
	Prompt smoothNum, "Box smooth(20times) width (points)"
	Silent 1

	string lista , a_wave, destwave, awave
		lista = WaveList(wave1,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
	Do
		if(numpnts($a_wave) == 300000)
			destwave = "C_" + a_wave + "_" + num2str(windex) + "_1"
			duplicate /O /R=(0,6) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_" + a_wave + "_" +  num2str(windex) + "_2"
			duplicate /O /R=(6,12) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_" + a_wave + "_" +  num2str(windex) + "_3"
			duplicate /O /R=(12,18) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_" + a_wave + "_" +  num2str(windex) + "_4"
			duplicate /O /R=(18,24) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			destwave = "C_" + a_wave + "_" +  num2str(windex) + "_5"
			duplicate /O /R=(24,30) $a_wave $destwave
			setScale x, 0, 6, "s", $destwave
			wave1 = "C_*"
		else
			destwave = "C_" + a_wave + num2str(windex)
			duplicate /O $a_wave $destwave
			wave1 = "C_*"
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	variable mode, median, offsetVal, spontArea, spontAreaAvg, spontMax, spontMin, spontSdevAvg, SpontRmsAvg
	lista = WaveList(wave1,";","")
	windex=0
	a_wave = StringFromList(windex, lista)
	Do
		destwave = "offset_" + a_wave
		Duplicate /O $a_wave, $destwave
		smoothWave(destwave, "", 0, 0, 2, 0, smoothNum, 20, 2, 1)
		printPercentile (wave1=destwave, percentile=0.5, stt=0, ent=0, suffix="spont", step=0, kill=1, printToCmd=0)
			mode = K18
			median = K19
			if (offsetMethod)
				offsetVal = mode
			else
				offsetVal = median
			endif
			$destwave = $destwave - offsetVal
			wavestats /Q $destwave
			spontArea = area($destwave, -inf, inf)
				print "    * ", a_wave, " offseted by ", offsetVal, " spontArea : ", spontArea
			spontMax = max(spontMax, V_max)
			spontMin = min(spontMin, V_min)
			spontAreaAvg += spontArea
			spontSdevAvg += V_sdev
			spontRmsAvg += V_rms
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	spontAreaAvg /= windex
	spontSdevAvg /= windex
	spontRmsAvg /= windex
	
	print "* AreaAvg : ", spontAreaAvg, " ; SdevAvg : ", spontSdevAvg, " ; RMSavg : ", spontRmsAvg, " ( N=", windex, ")"
	print "          max : ", spontMax, " ; min : ", spontMin
	
endmacro



macro printHalfDecay (wave1, sttime, entime, polarity, suffix, step, kill, printToCmd)
	String wave1, suffix
	Variable sttime=3, entime=3.5, kill=0, printToCmd = 1, polarity=0, step = 100
	Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
	Prompt sttime,"Decay from (sec, if 0; leftx)"
	Prompt entime,"to (sec, if 0; rightx)"
	Prompt suffix, "SUFFIX for the destination wave"
	Prompt step, "Bin for Smoothing (if 0: 100)"
	Prompt polarity, "polarty (0/1: -/+)"
	Prompt kill, "kill waves? 0/1(No/Yes)"
	Prompt printToCmd, "Print? 0/1(No/Yes)"
	Silent 1

	string lista , a_wave, destwave, awave
		lista = WaveList(wave1,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
	if (step ==0)
		step = 100
	endif
	if (sttime > entime)
		abort
	endif
	variable mode=0, stVal=0, halfVal = 0, i
	Do
		destwave = "Smooth" + suffix + num2str(windex)
			Duplicate /O $a_wave $destwave
			smooth /B=10 step, $destwave
			wavestats /Q /R=(sttime - 0.001, sttime + 0.001) $destwave
				stVal = V_avg
			printPercentile (wave1=destwave, percentile=0.5, stt=0, ent=0, suffix=suffix, step=0, kill=1, printToCmd=0)
				halfVal = (stVal - K18) / 2 + K18
				findlevels /Q /R=(sttime, entime) $destwave, halfVal
		i = 0
		do
			if (printToCmd)
				print "[", i , "] : ", num2str(W_FindLevels[i] - sttime) , " ; ( ", stVal, " - ", K18, " : halfVal = ", halfVal, " )"
			endif
			i+=1
		while(i<(numpnts(W_FindLevels)-1))
		if (kill)
			killwaves $destwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End

macro saveWaves (wave1, type, terminator, filename,  printToCmd)
	String wave1, filename
	variable type=0, terminator=1, printToCmd=1
	Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
	Prompt type, "type 0/1/2 : tab/general/igor txt"
	Prompt terminator, "OS 0/1/2 : Mac/Win/UNIX"
	Prompt filename, "file name (if \"\", wave1.txt)"
	Prompt printToCmd, "Print? 0/1(No/Yes)"
	Silent 1
	
	String termStr
	if (terminator ==0)
		termStr = "\r"
	else
		if (terminator ==1)
			termStr = "\r\n"
		else
			if (terminator ==2)
				termStr = "\n"
			endif
		endif
	endif
	
	string lista , a_wave, destfile
		lista = WaveList(wave1,";","")
		variable windex=0
		a_wave = StringFromList(windex, lista)
	Do
		if (stringmatch(filename, ""))
			destfile = a_wave + ".txt"
		else
			destfile = filename + "_" + windex + ".txt"
		endif
		if (type == 0)
			Save /J /P=home /B /M=termStr a_wave as destfile
		else
			if(type == 1)
				Save /J /P=home /G /M=termStr a_wave as destfile
			else
				if (type==2)
					Save /J /P=home /T /M=termStr a_wave as destfile
				endif
			endif
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
endmacro



function printPearsonR ([wave1, wave2, type, stt, ent])
	String wave1, wave2
	Variable type, stt, ent
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1="*"; wave2="*"
		type=0; stt=-inf; ent=inf;
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt wave2, "Wave2 name"//, popup wavelist ("*",";","")
		Prompt type, "type 0/1/2(all-all/all-other/one-one)"
		Prompt stt,"RANGE from (sec)"
		Prompt ent,"to (sec)"
		DoPrompt  "printPearsonR", wave1, wave2, type, stt, ent
		if (V_Flag)	// User canceled
			return -1
		endif
		print "printPearsonR(wave1=\"" + wave1 + "\",wave2=\"" + wave2 + "\",type=" + num2str(type) + ",stt=" + num2str(stt) + ",ent=" + num2str(ent) + ")"
	endif	

	variable length, width
	variable aindex=0, bindex=0, sttime, entime, CorrEach, CorrAll, nindex
	CorrAll=0

	string lista , listb , a_wave , b_wave, tmp_a, tmp_b
	tmp_a = "tmpPearsonRa"
	tmp_b = "tmpPearsonRb"

	lista = WaveList(wave1,";","")
	listb = WaveList(wave2,";","")

	nindex = 1
	if (type <= 1) // all-to-all
		aindex=0
		a_wave = StringFromList(aindex, lista)
		Do
			bindex = aindex
			b_wave = StringFromList(bindex, listb)
			Do
				if ((type == 1) && stringmatch(a_wave, b_wave))
					bindex += 1
					b_wave = StringFromList(bindex, listb)
					if (strlen(b_wave)!=0)
						continue
					else
						break
					endif
				endif
				if(stt==-inf)
					sttime = min(leftx($a_wave), (leftx($b_wave)))
				else
					sttime = stt
				endif
				if(ent==inf)
					entime = max(rightx($a_wave), (rightx($b_wave)))
				else
					entime = ent
				endif
				if(entime<=sttime)
					abort
				endif
				Duplicate /R=(sttime,entime) /O $a_wave, $tmp_a
				Duplicate /R=(sttime,entime) /O $b_wave, $tmp_b
				wave tmpa = $tmp_a
				wave tmpb = $tmp_b
				CorrEach = StatsCorrelation(tmpa, tmpb)
				print " [", nindex, "] Pearson R of ", a_wave, " and ", b_wave, " : (", sttime, "to", entime, ") is ", CorrEach
				if (numtype(CorrEach) != 2)
					CorrAll += CorrEach
					nindex += 1
				endif
				bindex += 1
				b_wave = StringFromList(bindex, listb)
			While(strlen(b_wave)!=0)
			aindex += 1
			a_wave = StringFromList(aindex, lista)
		While(strlen(a_wave)!=0)
		nindex -= 1
		killwaves $tmp_a
		killwaves $tmp_b
		CorrAll /= nindex
		print " Avg of Pearson R of ", nindex, " pairs : ", CorrAll
	else
		aindex = 0
		a_wave = StringFromList(aindex, lista)
		b_wave = StringFromList(aindex, listb)
		nindex = 1
		Do
			if(stt==-inf)
				sttime = min(leftx($a_wave), (leftx($b_wave)))
			else
				sttime = stt
			endif
			if(ent==inf)
				entime = max(rightx($a_wave), (rightx($b_wave)))
			else
				entime = ent
			endif
			if(entime<=sttime)
				abort
			endif
			Duplicate /R=(sttime,entime) /O $a_wave, $tmp_a
			Duplicate /R=(sttime,entime) /O $b_wave, $tmp_b
			wave tmpa = $tmp_a
			wave tmpb = $tmp_b
			CorrEach = StatsCorrelation(tmpa, tmpb)
			print " [", nindex, "] Pearson R of ", a_wave, " and ", b_wave, " : (", sttime, "to", entime, ") is ", CorrEach
			if (numtype(CorrEach) != 2)
				CorrAll += CorrEach
				nindex += 1
			endif
			aindex += 1
			a_wave = StringFromList(aindex, lista)
			b_wave = StringFromList(aindex, listb)
		While(strlen(a_wave)!=0 && strlen(b_wave)!= 0)
		nindex -= 1
		killwaves $tmp_a
		killwaves $tmp_b
		CorrAll /= nindex
		print " Avg of Pearson R of ", nindex, " pairs : ", CorrAll
	endif
End
