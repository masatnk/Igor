#pragma rtGlobals=1		// Use modern global access method.

menu "tanakaWaveTransform"
	submenu "change wave features"
		"renameWaves"
		"truncWavename"
		"assignValues"
		"assignValuesWithxwave"
		"replaceValues"
		"setWaveScale"
		"compressWave"
		"expandWave"
	end
	submenu "make waves"
		"makeWaves"
		"copyrandomWaves"
		"splitWave"
		"transposeWaves"
		"make1DWaveFromXYwaves"
		"makeSpectrogram"
		"makeSlidingCorrel"
		"makeGaussianNoise"
		"makeBinominalNoise"
		"makeComplexWave"
		"makeColorIndexWave"
	end
	submenu "calc on a wave"
		"subtract"
		"sumWave"
		"statWaves"
		"duplicateWave"
		"duplicateWithONOFFwave"
		"duplicateWithOffsetWave"
		"duplicateWithOffsetWaveWithText"
		"multiplyWave"
		"normWave"
		"smoothWave"
		"differentiateWave"
		"stepdifWave"
		"FFT_Wave"
		"Rect2Polar"
		"makeAPtrain"
		"cumulatePlot"
		"discretizeWave"
		"absWave"
		"rectWave"
		"transformWave"
		"filterWave"
		"modifyWave"
		"sortWave"
	end
	submenu "calc on waves"
		"concatenateWaves"
		"concatenate2Waves"
		"averageWave"
		"sum2Waves"
		"multiply2Waves"	
		"convolution"
		"histogramWaves"
	end
end


function sumWave([waves, targetname, sttime, entime, dpn])
	String waves, targetname
	Variable sttime, entime, dpn
	// there is a problem for discrete deltax wave
	if (numType(strlen(waves)) == 2)		// if (waves == null) : so there was no input
		waves="*"; targetname="target";
		sttime = -inf; entime=inf; dpn=3;
		Prompt waves, "wave name"
		Prompt targetname, "target suffix"
		Prompt sttime, "from (s)"
		Prompt entime, "to (s)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "sumWave", waves, targetname, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "sumWave(waves=\"" + waves + "\", targetname=\"" + targetname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) +  ")"
	endif
	
	string lista, awave, targetwave
	variable windex, left_t, right_t, num_target, delta_a, left_a, right_a, left_min, right_max, pindex
	windex = 0
	lista = WaveList(waves,";","")
	awave = StringFromList(windex, lista)
	delta_a = deltax($awave)
	if (sttime == -inf || entime == inf)
		Do
			wave a = $awave
			if (waveExists(a) == 0)
				print "not exist such a wave"
				abort
			endif
			if (delta_a != deltax(a))
				print "!!!!!  waves have different deltax !!!!!!"
				abort
			endif
			if (sttime == -inf)
				left_min = min(left_min, leftx(a))
			endif
			if (entime == inf)
				right_max = max(right_max, rightx(a))
			endif
			windex += 1
			awave = StringFromList(windex, lista)
		While(strlen(awave)!=0)
	endif
	if (sttime == -inf)
		sttime = left_min
	endif
	if (entime == inf)
		entime = right_max
	endif
	targetwave = "Sum_" + targetname
	num_target = abs((entime - sttime) / delta_a) + 1
	Make /O /N=(num_target) $targetwave
	setScale /P x, sttime, delta_a, $targetwave
	variable sumN
	wave t = $targetwave
	t=0
	For (pindex=0; pindex<num_target; pindex+=1)
		sumN = 0
		windex = 0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
		Do
			wave a = $awave
			if (pnt2x(t, pindex) >= leftx(a) && rightx(a) >= pnt2x(t, pindex))
				t[pindex] = t[pindex] + a[x2pnt(a, pnt2x(t, pindex))]
				sumN += 1
			endif
			windex += 1
			awave = StringFromList(windex, lista)
		While(strlen(awave)!=0)
//		t[pindex] /= sumN
	Endfor
	
end


function statWaves([waves, targetname, sttime, entime, dpn])
	String waves, targetname
	Variable sttime, entime, dpn
	// This program preserves the x-scale
	// there is a problem for discrete deltax wave
	if (numType(strlen(waves)) == 2)		// if (waves == null) : so there was no input
		waves="*"; targetname="target";
		sttime = -inf; entime=inf; dpn=3;
		Prompt waves, "wave name"
		Prompt targetname, "target suffix"
		Prompt sttime, "from (s)"
		Prompt entime, "to (s)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "statWaves", waves, targetname, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "statWaves(waves=\"" + waves + "\", targetname=\"" + targetname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) +  ")"
	endif
	
	string lista, awave, avgwave, SDwave, medwave, tmpformed, tmpformed2, CVwave, SEwave
	variable windex, left_t, right_t, delta_a, left_a, right_a, left_min, right_max, pindex, len_max, tmpindex, ya, findex, xindex
	tmpformed = "tmpforMED"
	tmpformed2 = "tmpforMED2"
	len_max = 0
	windex = 0
	lista = WaveList(waves,";","")
	awave = StringFromList(windex, lista)
	delta_a = deltax($awave)
	ya = dimsize($awave,1)
	if (sttime == -inf || entime == inf)
		/// this has to be changed so that min of leftx and max of rightx should be considered
		Do
			wave a = $awave
			if (len_max <= numpnts(a))
				len_max = dimsize(a,0)
				wave maxw = $awave
			endif
			if (waveExists(a) == 0)
				print "!!! the wave does not exist"
				abort
			endif
			if (delta_a != deltax(a))
				print "!!!  waves have different deltax "
				abort
			endif
			if (sttime == -inf)
				left_min = min(left_min, leftx(a))
			endif
			if (entime == inf)
				right_max = max(right_max, rightx(a))
			endif
			windex += 1
			awave = StringFromList(windex, lista)
		While(strlen(awave)!=0)
	endif
	if (sttime == -inf)
		sttime = left_min
	endif
	if (entime == inf)
		entime = right_max
	endif
	avgwave = "Avg_" + targetname
	medwave = "Med_" + targetname
	SDwave = "SD_" + targetname
	CVwave = "CV_" + targetname
	SEwave = "SE_" + targetname
	Duplicate /O maxw, $avgwave
	Duplicate /O maxw, $medwave
	Duplicate /O maxw, $SDwave
	Duplicate /O maxw, $CVwave
	Duplicate /O maxw, $SEwave

	variable sumN
	wave avg = $Avgwave
	wave med = $medwave
	wave SD = $SDwave
	wave CV = $CVwave
	wave SE = $SEwave
	avg=0
	med = 0
	SD=0
	CV=0
	SE=0
	For (pindex=0; pindex<len_max; pindex+=1)
		Make /O /N=(windex, ya), $tmpformed
		wave tmpw = $tmpformed
		tmpindex = 0
		sumN = 0
		windex = 0
		lista = WaveList(waves,";","")
		awave = StringFromList(windex, lista)
		Do
			wave a = $awave
			if (pnt2x(avg, pindex) >= leftx(a) && rightx(a) >= pnt2x(avg, pindex))
				if (numtype(a[x2pnt(a, pnt2x(avg, pindex))]) != 2) // NAN
					avg[pindex][] = avg[pindex][q] + a[x2pnt(a, pnt2x(avg, pindex))][q]
					tmpw[tmpindex][] = a[x2pnt(a, pnt2x(avg, pindex))][q]
					SD[pindex][] = SD[pindex][q] + a[x2pnt(a, pnt2x(avg, pindex))]*a[x2pnt(a, pnt2x(avg, pindex))][q]
					tmpindex += 1
					sumN += 1
				endif
			else
				deletepoints /M=0 inf,1, tmpw
			endif
			windex += 1
			awave = StringFromList(windex, lista)
		While(strlen(awave)!=0)
		avg[pindex][] /= sumN
		SD[pindex][] = sqrt(SD[pindex]/(sumN-1)- avg[pindex]*avg[pindex]/(sumN-1)*sumN) // unbiased
		SE[pindex][] = SD[pindex] / sqrt(sumN)
//		SD[pindex] = sqrt(SD[pindex]/(sumN)- avg[pindex]*avg[pindex])	// biased
		Make /O /N=(tmpindex), $tmpformed2
		wave tmpw2 = $tmpformed2
		For (findex=0; findex<ya; findex+=1)
			For (xindex=0; xindex<tmpindex; xindex+=1)
				tmpw2[xindex] = tmpw[xindex][findex]
			endfor
			med[pindex][findex] = statsmedian(tmpw2)
		endfor
	Endfor
	CV = SD / avg
end

function averageWave([sampleWaves, destname, sttime, entime, dpn])
	String sampleWaves, destname
	Variable sttime, entime, dpn

	if (numType(strlen(sampleWaves)) == 2)		// if (waves == null) : so there was no input
		sampleWaves="*"; destname="";
		sttime=-inf; entime=inf; dpn = 3;
		Prompt sampleWaves, "Wave name (must be x-aligned)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"

		DoPrompt  "averageWave", sampleWaves, destname, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "averageWave(sampleWaves=\"" + sampleWaves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) +  ")"
	endif

	string lista
	string a_wave
	string awave = "adhocWaveSample"
	string bwave = "adhocWaveAvg"
	lista = WaveList(sampleWaves,";","")
	string destwave = "Avg" + destname
	variable n=1, stt, ent
	a_wave = StringFromList((n-1), lista)
	print "* average of ..."
	Do
		if(sttime==-inf)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if(entime==inf)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		if(ent<=stt)
				abort
		endif
		print "       ", n, " : ",  a_wave, " (", stt, " - ", ent, ")"
		if (n>1)
			Duplicate/R=(stt,ent)/O $a_wave $awave
			Duplicate/R=(stt,ent)/O $destwave $bwave
			wave dw = $destwave
			wave aw = $awave
			wave bw = $bwave
			dw = ( bw * (n-1)/n) + ( aw * (1/(n)) )
			killwaves $awave, $bwave
		else
			Duplicate/R=(stt,ent)/O $a_wave $destwave
		endif
		n+=1
		a_wave = StringFromList((n-1), lista)
	While(strlen(a_wave)!=0)
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
End


function renameWaves([waves, namewave, useOldname, replaceoldstr, replacenewstr, useNum, num, num2])
	String waves, namewave, replaceoldstr, replacenewstr
	Variable useOldname, useNum, num, num2
	if (numType(strlen(waves)) == 2)		// if (waves == null) : so there was no input
		waves="*"; namewave=""; replaceoldstr=""; replacenewstr="";
		useOldname=1; useNum=0; num=1; num2=1;
		Prompt waves, "wave name"
		Prompt namewave, "new name prefix"
		Prompt useOldname, "name type 0/1/2 (keep/new/replace)"
		Prompt replaceoldstr, "replace old str"
		Prompt replacenewstr, "replace new str"
		Prompt useNum, "how many num index? 0-2"
		Prompt num, "num2 index length"
		Prompt num2, "num3 index length"
		DoPrompt  "renameWaves", waves, namewave, useOldname, replaceoldstr, replacenewstr, useNum, num, num2
		if (V_Flag)	// User canceled
			return -1
		endif
		print "renameWaves(waves=\"" + waves + "\", namewave=\"" + namewave + "\", useOldname=" + num2str(useOldname) + ", replaceoldstr=\"" + replaceoldstr + "\", replacenewstr=\"" + replacenewstr  + "\", useNum=" + num2str(useNum) + ",  num=" + num2str(num) + ", num2=" + num2str(num2) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, nindex, n2index

	nindex = 0
	n2index = 0
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		if (useOldname == 1)
			targetname = namewave + a_wave
		elseif (useOldname == 2)
			targetname = replacestring(replaceoldstr, a_wave, replacenewstr)
		else
			targetname = namewave
		endif
		if (useNum > 0)
			targetname += "_" +  num2str(nindex)
			if (useNum > 1)
				targetname += "_" +  num2str(n2index)
				n2index += 1
				if (n2index < num2)
					nindex -= 1
				else
					n2index = 0
				endif
			endif
			nindex += 1
		endif
		if (exists(targetname))
			killwaves $targetname
		endif
		rename a, $targetname

		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function truncWavename([waves, order, num, num2])
	String waves
	Variable order, num, num2
	if (numType(strlen(waves)) == 2)		// if (waves == null) : so there was no input
		waves="*";
		order=0; num=1; num2=1;
		Prompt waves, "wave name"
		Prompt order, "0/1 (from left/right)"
		Prompt num, "from"
		Prompt num2, "to"
		DoPrompt  "truncWavename", waves, order, num, num2
		if (V_Flag)	// User canceled
			return -1
		endif
		print "truncWavename(waves=\"" + waves + "\", order=" + num2str(order) + ", num=" + num2str(num) + ", num2=" + num2str(num2) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		if (num <= 0 && num2 > strlen(a_wave))
			print "you cannot delete all the name"
			abort
		endif
		if (order == 0)
			if (num == 0)
				targetname = a_wave[(num2+1), (strlen(a_wave)-1)]
			else
				targetname = a_wave[0, (num-1)] + a_wave[(num2+1), (strlen(a_wave)-1)]
			endif
		else
			if (num == 0)
				targetname = a_wave[0, (strlen(a_wave)-1-num2-1)]
			else
				targetname = a_wave[0, (strlen(a_wave)-1-num2)-1] + a_wave[(strlen(a_wave)-1-num+1), (strlen(a_wave)-1)]
			endif
		endif
		rename a, $targetname

		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function setWaveScale([waves, axis, mode, delta, sttime, entime, unitStr])
	String waves, unitStr
	Variable axis, mode, delta, sttime, entime
	if (numType(strlen(waves)) == 2)		// if (waves == null) : so there was no input
		waves="*"; unitStr = "s";
		mode=0; delta=5e-5; sttime=0; entime=0
		Prompt waves, "wave name"
		Prompt axis, "axis? 0-3 (x,y,z,t)"
		Prompt mode, "mode 0/1/2 (delta/end/none)"
		Prompt delta, "delta val (if mode=0)"
		Prompt sttime, "start val"
		Prompt entime, "end val (if mode=1)"
		Prompt unitStr, "unit"
		DoPrompt  "setWaveScale", waves, axis, mode, delta, sttime, entime, unitStr
		if (V_Flag)	// User canceled
			return -1
		endif
		print "setWaveScale(waves=\"" + waves + "\", axis=" + num2str(axis) + ", mode=" + num2str(mode)  + ", delta=" + num2str(delta) + ",  sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", unitStr=\"" + unitStr + "\")"
	endif
	
	string lista, a_wave
	variable windex

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif

		if (axis == 0)
			if (mode == 1)
				SetScale /I x, sttime, entime, unitStr, a
			elseif (mode == 0)
				SetScale /P x, sttime, delta, unitStr, a
			else
				SetScale x, 0, 0, unitStr, a
			endif
		elseif (axis == 1)
			if (mode == 1)
				SetScale /I y, sttime, entime, unitStr, a
			elseif (mode == 0)
				SetScale /P y, sttime, delta, unitStr, a
			else
				SetScale y, 0, 0, unitStr, a
			endif
		elseif (axis == 2)
			if (mode == 1)
				SetScale /I z, sttime, entime, unitStr, a
			elseif (mode == 0)
				SetScale /P z, sttime, delta, unitStr, a
			else
				SetScale z, 0, 0, unitStr, a
			endif
		elseif (axis == 3)
			if (mode == 1)
				SetScale /I t, sttime, entime, unitStr, a
			elseif (mode == 0)
				SetScale /P t, sttime, delta, unitStr, a
			else
				SetScale t, 0, 0, unitStr, a
			endif
		endif
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


macro mysplitWave (wave1, num, modScale)
	string wave1="B*2"
	variable num = 5, modScale=1
	prompt wave1, "wave1Name"
	prompt num, "N (split to N waves)"
	prompt modScale, "modify xScale? (to 0-step)"

	string lista , a_wave, destwave, awave
		lista = WaveList(wave1,";","")
		variable windex=0, nindex=0
		a_wave = StringFromList(windex, lista)

	variable step, sttime, entime
	Do
		step = (rightx($a_wave) - leftx($a_wave)) / num
		nindex = 0
		Do 
			destwave = "f_" + a_wave + "_" + num2str(nindex)
			sttime = nindex * step
			entime = sttime + step
			duplicate /O /R=(sttime,entime) $a_wave $destwave
			if (modScale)
				setScale x, 0, step, "s", $destwave
			endif
			nindex += 1
		While (nindex < num)
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
endmacro


function makeWaves([namewave, raw, col, depth, num])
	String namewave
	Variable raw, col, depth, num
	if (raw == 0)		// if (raw == null) : so there was no input
		namewave="S10"; raw = 600; col=0; depth=0; num=40
		Prompt namewave, "wave name"
		Prompt raw, "raw num"
		Prompt col, "col num"
		Prompt depth, "depth num"
		Prompt num, "wave num"
		DoPrompt  "makeWaves", namewave, raw, col, depth, num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* makeWaves(namewave=\"" + namewave + "\",raw=" + num2str(raw) + ", col=" + num2str(col) + ", depth=" + num2str(depth) + ", num=" + num2str(num) + ")"
	endif

	string targetwave
	variable nindex=0
	Do 
		targetwave = namewave + "_" + num2str(nindex)
		Make /O /N=(raw, col, depth) /D $targetwave
		nindex += 1
	While (nindex < num)
end


function assignValues([waves, destname, type, value, sttime, entime, dpn])
	String waves, destname, value
	Variable type, sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; value="n"
		type=0; sttime=-INF; entime=INF; dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt type,"type (0: pnt; 1: x)"
		Prompt value,"value assigned (n: #wave)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "assignValues", waves, destname, type, value, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print " assignValues(waves=\"" + waves + "\", destname=\"" + destname + "\", type=" + num2str(type) + ", value=\"" + value + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ")"
	endif

	Silent 1

	string lista, a_wave, destwave
	variable windex=0, foundN, nvalue
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)

		foundN = strsearch(value, "n", 0)
		if (foundN != -1)
			value = replacestring("n", value, "")
			if (stringmatch(value, ""))
				value = "1"
			endif
		endif

	Do
		if (type == 1)
			if (sttime != -INF)
				sttime = x2pnt($a_wave, sttime)
			endif
			if (entime != INF)
				entime = x2pnt($a_wave, entime)
			endif
		endif
		if(entime<sttime)
				abort
		endif

		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave targetWave = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave targetWave = $destwave
		endif
		if (foundN != -1)
			nvalue = str2num(value) * windex
		else
			nvalue = str2num(value)
		endif

		targetWave[sttime,entime] = nvalue
		
		if(dpn==1)
			display targetWave
		elseif(dpn==2)
			appendtograph targetWave
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End




function assignValuesWithxwave([waves, waves2, destname, type, value, sttime, entime, dpn])
	String waves, waves2, destname
	Variable type, sttime, entime, dpn, value
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; value=2000
		type=0; sttime=-INF; entime=INF; dpn=3;
		Prompt waves, "Wave name"
		Prompt waves2, "xwave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt type,"type (0: pnt; 1: x) not working"
		Prompt value,"value assigned (n: #wave)"
		Prompt sttime,"RANGE from (sec) not working"
		Prompt entime,"to (sec) not working"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None) not working"
		DoPrompt  "assignValuesWithxwave", waves, waves2, destname, type, value, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print " assignValuesWithxwave(waves=\"" + waves + "\", waves2=\"" + waves2 + "\", destname=\"" + destname + "\", type=" + num2str(type) + ", value=" + num2str(value) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ")"
	endif

	Silent 1

	string lista, a_wave, listb, b_wave, destwave
	variable windex=0, foundN, nvalue
		lista = WaveList(waves,";","")
		listb = WaveList(waves2,";","")
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)

	Do
		if(entime<sttime)
				abort
		endif
		wave wa = $a_wave
		wave wb = $b_wave

		destwave = destname + a_wave
		if (stringmatch(destname, ""))
			wave targetWave = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave targetWave = $destwave
		endif
		
		variable ii
		for(ii=0; ii<numpnts(wb); ii+=1)
			targetWave[x2pnt(wa, wb[ii])] = value
		endfor
		
		windex+=1
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
	While(strlen(a_wave)!=0)
End


function replaceValues([waves, destname, type, valueold, value, sttime, entime, dpn])
	String waves, destname
	Variable value, type, valueold, sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*";
		value=0; valueold=-inf; sttime=-INF; entime=INF; dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt type,"type 0/1/2 (equal/below/above)"
		Prompt valueold,"value old"
		Prompt value,"value assigned"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "replaceValues", waves, type, destname, valueold, value, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print " replaceValues(waves=\"" + waves + "\", destname=\"" + destname + "\", type=" + num2str(type) + ", valueold=" + num2str(valueold) + ", value=" + num2str(value) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave
	variable windex=0, npnt, indn, stpnt, enpnt, stt, ent
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)

	Do
		if (sttime == -INF)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if (entime == INF)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		stpnt = x2pnt($a_wave, stt)
		enpnt = x2pnt($a_wave, ent)
		if(enpnt<stpnt)
				abort
		endif

		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave targetWave = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave targetWave = $destwave
		endif

		indn = stpnt
		Do
			if (numtype(valueold) == 2) //NaN
				if (numtype(targetWave[indn]) == 2)
					targetWave[indn] = value
				endif
			else
				if (type == 0 && targetWave[indn] == valueold)
					targetWave[indn] = value
				elseif (type == 1 && targetWave[indn] <= valueold)
					targetWave[indn] = value
				elseif (type == 2 && targetWave[indn] >= valueold)
					targetWave[indn] = value
				endif
			endif
			indn += 1
		While (indn< enpnt)

		if(dpn==1)
			display targetWave
		elseif(dpn==2)
			appendtograph targetWave
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End



function transformWave([waves, destname, dpn])
	String waves, destname
	Variable dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*";
		dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "transformWave", waves, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* transformWave(waves=\"" + waves + "\", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave, printstr
	variable windex=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)

	Do
		wave a = $a_wave
		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave d = $a_wave
//			wave /C d = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave d = $destwave
//			wave /C d = $destwave
		endif

//////////////////////// write transform function (a = a_wave)
//		d = exp(-a/100)
//		d = 1/a[p]
//		printstr = "1/a[p]"

//		variable FR = 1.4815
//		d = -log( FR^a[p] * exp(-FR) / factorial(a[p]) )
//		printstr = "FR^a[p] * exp(-FR) / factorial(a[p])"
		
		d = log(a)/log(10)*10

//		d = 1/a[p]
//		printstr = "1/a[p]"

//		printstr = "-log(a)/log(2)"

//		d =  cmplx( real(a) *1/(1+(x/20)^4) , imag(a) *1/(1+(x/20)^4))
//		printstr = "cmplx( real(a) *1/(1+(x/20)^4) , imag(a) *1/(1+(x/20)^4))"
//////////////////////////////////////////////////
		if(dpn==1)
			display d
		elseif(dpn==2)
			appendtograph d
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	print "function: ", "output = ", printstr
End


function stepdifWave([waves, destname])
	String waves, destname
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="d"
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		DoPrompt  "stepdifWave", waves, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "stepdifWave(waves=\"" + waves + "\", destname=\"" + destname + "\")"
	endif

	string lista, a_wave, destwave, printstr
	variable windex=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave d = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave d = $destwave
		endif

		d[] = a[p+1] - a[p]
		deletepoints (x2pnt(d, rightx(d))-1), 1, d
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End

function transposeWaves([waves, destname, sttime, entime])
	String waves, destname
	variable sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="d"
		sttime = -inf; entime = inf;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt sttime, "Range from"
		Prompt entime, "to"
		DoPrompt  "transposeWaves", waves, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "transposeWaves(waves=\"" + waves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	string lista, a_wave, destwave, printstr
	variable windex, maxN, ind, numwave, stt, ent, indt
	lista = WaveList(waves,";","")
	maxN = 0
	numwave = 0
	windex = 0
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (sttime == -inf)
			stt = x2pnt(a, leftx(a))
		else
			stt = x2pnt(a, sttime)
		endif
		if (entime == inf)
			ent = x2pnt(a, rightx(a))
		else
			ent = x2pnt(a, entime)
		endif
		numwave += 1
		maxN = max(maxN, ent-stt+1)
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	if (maxN > 2000)
		print "Stopped because > 2000 waves will be created. See the ipf file."
		abort
	endif

	ind = 0
	Do
		destwave = destname + "_" + num2str(ind)
		Make /O /N=(numwave) $destwave
		wave d = $destwave
		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			wave a = $a_wave
			if (sttime == -inf)
				stt = x2pnt(a, leftx(a))
			else
				stt = x2pnt(a, sttime)
			endif
			if (entime == inf)
				ent = x2pnt(a, rightx(a))
			else
				ent = x2pnt(a, entime)
			endif
			indt = stt + ind
			if (indt < numpnts(a))
				d[windex] = a[indt]
			else
				d[windex] = NaN
			endif
			windex+=1
			a_wave = StringFromList(windex, lista)
		While(strlen(a_wave)!=0)
		ind += 1
	While (ind< maxN)
End


function make1DWaveFromXYwaves([wavey, wavex, sttime, entime, dtime, val, type, destname])
	String wavey, wavex, destname
	Variable sttime, entime, dtime, val, type
	if (numType(strlen(wavey)) == 2)		// if (wave == null) : so there was no input
		wavey = ""; wavex="*_x"; destname="tr"
		Prompt wavey, "Y wave name. if \"\", value is used"
		Prompt wavex, "X wave name"
		Prompt sttime, "destwave X from"
		Prompt entime, "destwave X to"
		Prompt dtime, "destwave deltaX"
		Prompt val, "destwave value (in case Y wave omitted)"
		Prompt type, "type 0/1 (pnt/fill)"
		Prompt destname, "PREFIX. overwrite Xwave if \"\""
		DoPrompt  "make1DWaveFromXYwaves", wavey, wavex, sttime, entime, dtime, val, type, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "make1DWaveFromXYwaves(wavey=\"" + wavey + "\", wavex=\"" + wavex + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dtime=" + num2str(dtime) + ", val=" + num2str(val) + ", type=" + num2str(type) + ", destname=\"" + destname + "\")"
	endif

	string listy, listx, x_wave, y_wave, destwave, printstr
	variable windex, ind, numwave, npnts, flagy, lenx, nindex
	npnts = floor((entime - sttime) / dtime) + 1
	windex = 0
	listx = WaveList(wavex,";","")
	if (!stringmatch(wavey, ""))
		listy = WaveList(wavey,";","")
		y_wave = StringFromList(windex, listy)
		flagy = 1
	else
		flagy = 0
	endif
	x_wave = StringFromList(windex, listx)
	Do
		wave wx = $x_wave
		lenx = numpnts(wx)
		if (flagy)
			wave wy = $y_wave
		endif
		destwave = destname + "_" + x_wave
		make /N=(npnts) /O $destwave
		SetScale/P x sttime, dtime, "", $destwave
		wave wd = $destwave
		wd = 0
		nindex = 0
		Do
			if (flagy)
				if (type == 0)
					wd[x2pnt(wd, wx[nindex])] = wy[nindex]
				else
					if (nindex == lenx)
						wd[x2pnt(wd, wx[nindex]), inf] = wy[nindex]
					else
						wd[x2pnt(wd, wx[nindex]), x2pnt(wd, wx[nindex+1])] = wy[nindex]
					endif
				endif
			else
				if (type == 0)
					wd[x2pnt(wd, wx[nindex])] = val
				else
					if (nindex == lenx)
						wd[x2pnt(wd, wx[nindex]), inf] = val
					else
						wd[x2pnt(wd, wx[nindex]), x2pnt(wd, wx[nindex+1])] = val
					endif
				endif
			endif
			nindex += 1
		While(nindex < lenx)
		windex += 1
		if (flagy)
			y_wave = StringFromList(windex, listy)
		endif
		x_wave = StringFromList(windex, listx)
	While(strlen(x_wave)!=0)
	
End

function multiplyWave ([wave1, wavedest, dpn, num, offset, val, sttime, entime, avgsttime, avgentime])
	String wave1, wavedest
	Variable dpn, num, offset, val, sttime, entime, avgsttime, avgentime
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1="Avg*"; wavedest="leak"
		num=-3; offset=0; val=0; sttime=-inf; entime=inf; avgsttime=0; avgentime=0.1; dpn=3
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt wavedest, "destwave name (\"\"to overwrite)" //, popup wavelist ("*",";","")	
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		Prompt num, "multiply by (if 0, norm with offset)"
		Prompt offset, "offset 0-3 (avg/median/mode/val)"
		Prompt val, "offset val"
		Prompt sttime, "RANGE from (s)"
		Prompt entime, "to (s)"
		Prompt avgsttime, "Resting; from (s)"
		Prompt avgentime, "to (s)"
		DoPrompt  "multiplyWave", wave1, wavedest, dpn, num, offset, val, sttime, entime, avgsttime, avgentime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "multiplyWave(wave1=\"" + wave1 + "\", wavedest=\"" + wavedest + "\", dpn=" + num2str(dpn) + ", num=" + num2str(num) + ", offset=" + num2str(offset) + ", val=" + num2str(val) + ", sttime=" + num2str(sttime)  + ",entime=" + num2str(entime)  + ", avgsttime=" + num2str(avgsttime)  + ", avgentime=" + num2str(avgentime) + ")"

	endif

	string lista , a_wave, destwave
	variable windex=0, length, offsetVal
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		destwave = wavedest + "_" + a_wave + "_" + num2str(windex)
		length = deltax($a_wave)*(numpnts($a_wave)-1) 
		
		if(sttime >= entime)
			print "sttime >= entime"
			abort
		endif
		if(avgsttime >= avgentime)
			print "avgsttime >= avgentime"
			abort
		endif

		if (offset == 0)
			wavestats /Q/R=(avgsttime, avgentime) $a_wave
			offsetVal = V_avg	// mean
		endif
		if (offset == 1)
			printPercentile (wave1=a_wave, percentile=0.5, stt=avgsttime, ent=avgentime, suffix="per", step=0, kill=1, printToCmd=0)
			offsetVal = K19	// median
		endif
		if (offset == 2)
			printPercentile (wave1=a_wave, percentile=0.5, stt=avgsttime, ent=avgentime, suffix="per", step=0, kill=1, printToCmd=0)
			offsetVal = K18	// mode
		endif
		if (offset == 3)
			offsetVal = val	// user-defined value
		endif
		if (stringmatch(wavedest, ""))
			destwave = a_wave
		else
			Duplicate/R=(sttime, entime)/O $a_wave $destwave
		endif
		
		wave dw = $destwave

		if (num == 0)
			if (offsetVal != 0)
				dw = (dw - offsetVal) / offsetVal
			else
				dw = (dw - offsetVal) * num + offsetVal
			endif
		else
			dw = (dw - offsetVal) * num + offsetVal
		endif

		if(dpn==1)
			display dw
		endif
		if(dpn==2)
			appendtograph dw
		endif
//		print " * multiply ", wave1, " with ", num, " OFFSET : ", offsetVal,  " (", sttime, "to", entime, ")"
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end macro


function cumulatePlot ([wave1, step, sttime, entime, integration, flagNorm, destname, dpn, printToCmd])
	String wave1, destname
	Variable step, sttime, entime, dpn, flagNorm, integration, printToCmd
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		step=0; sttime=-inf; entime=inf; dpn = 1; flagNorm=1; integration=1; printToCmd=1;
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt step, "bin step (scaled value)"
		Prompt sttime,"RANGE from (scaled. if 0; leftx)"
		Prompt entime,"to (scaled. if 0; rightx)"
		Prompt integration, "yValue. 0/1 (just sum/ integrate)"
		Prompt flagNorm, "normalize max to 1.0? 0/1 (No/Yes)"
		prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		Prompt printToCmd, "Print? 0/1 (No/Yes)"
		DoPrompt  "cumulatePlot",wave1, step, sttime, entime, integration, flagNorm, destname, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "cumulatePlot(wave1=\"" + wave1 + "\",step=" + num2str(step) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", integration=" + num2str(integration) + ", flagNorm=" + num2str(flagNorm) + ",destname=\"" + destname + "\", dpn=" + num2str(dpn) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	variable length
	string awave, destwave
	string lista , a_wave, info
	awave = "wave_cumulating"
	
	variable windex=0, stt, ent
	lista = WaveList(wave1,";","")
	a_wave = StringFromList(windex, lista)
	Do
		if(sttime == -inf)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if(entime == inf)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		if(ent<=stt)
				abort
		endif
		if(step < deltax($a_wave))
			step = deltax($a_wave)
		endif
		if (printToCmd)
			print " * cumulative plot of ", a_wave, " (", stt, "to", ent, ")"
		endif
		Duplicate/R=(stt,ent)/O $a_wave $awave		
		destwave = "Cum" + num2str(windex) + "_" + destname
		info = waveinfo($a_wave, 0)
		//cumulationNorm(awave, destwave, stt, ent, step, stringByKey("xunits", info), stringByKey("dunits", info), flagNorm, integration, printToCmd)
		
		Make/O/N=( (ent - stt)/step) $destwave
		wave wawave = $awave
		wave wdestwave = $destwave
		string xScale, yScale
		variable zt=0, len, tau, xtime, xtime2, maxCharge
		len = ent - stt
		xtime = stt
		xScale = stringByKey("xunits", info)
		yScale = stringByKey("dunits", info)

		for (xtime=stt; xtime<ent; xtime+=step)
			for (xtime2=xtime; xtime2<(xtime+step); xtime2+=deltax(wawave))
				zt += wawave(xtime2)
			endfor
			wdestwave[x2pnt(wawave, xtime)]=zt*step
		endfor
		setScale /P x, stt, deltax($a_wave), xScale, wdestwave
		
		//SetScale/P x stt, step, xScale, wdestwave
		WaveStats/Q wdestwave
		if (printToCmd)
			print "V_max : ", V_max, " ; V_min : ", V_min
		endif
		zt=0
			// couldnt find a function that returns the values for directed points
		maxCharge = mean(wdestwave, pnt2x(wdestwave, numpnts(wdestwave)-1), pnt2x(wdestwave, numpnts(wdestwave)-1))
		if(flagNorm)
			wdestwave /= maxCharge
			if(integration)
				if (printToCmd)
					print "maxCharge : ", maxCharge
				endif
			endif
		else
			//SetScale/I y , V_min, V_max, yScale, wdestwave
			if(integration)
				//SetScale/I y , V_min, V_max, "C", wdestwave
				if (printToCmd)
					print "maxCharge : ", maxCharge
				endif
			endif
		endif
		K10 = maxCharge
		if (printToCmd)
			print "xtime", xtime, "deltax", deltax(wawave), step
		endif
	
		killwaves $awave

		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

End

Function cumulationNorm(awave, destwave, sttime, entime, binstep, xScale, yScale, flagNorm, integration, printToCmd)
	// not used???
	string awave, destwave, xScale, yScale
	Variable sttime, entime, binstep, flagNorm, integration, printToCmd

	Make/O/N=( (entime - sttime)/binstep) $destwave
	wave wawave = $awave
	wave wdestwave = $destwave
	
	variable zt=0, len, tau, xtime, xtime2, step, maxCharge
	len = entime - sttime
	xtime = sttime

		step = binstep
		for (xtime=sttime; xtime<entime; xtime+=step)
			for (xtime2=xtime; xtime2<(xtime+step); xtime2+=deltax(wawave))
				zt += wawave(xtime2)
			endfor
			wdestwave[x2pnt(wawave, xtime)]=zt*step
		endfor
		SetScale/P x sttime, binstep, xScale, wdestwave
		WaveStats/Q wdestwave
		if (printToCmd)
			print "V_max : ", V_max, " ; V_min : ", V_min
		endif
		zt=0
			// couldnt find a function that returns the values for directed points
		maxCharge = mean(wdestwave, pnt2x(wdestwave, numpnts(wdestwave)-1), pnt2x(wdestwave, numpnts(wdestwave)-1))
		if(flagNorm)
			wdestwave /= maxCharge
			if(integration)
				if (printToCmd)
					print "maxCharge : ", maxCharge
				endif
			endif
		else
			SetScale/I y , V_min, V_max, yScale, wdestwave
			if(integration)
				SetScale/I y , V_min, V_max, "C", wdestwave
				if (printToCmd)
					print "maxCharge : ", maxCharge
				endif
			endif
		endif
		K10 = maxCharge
	if (printToCmd)
		print "xtime", xtime, "deltax", deltax(wawave), binstep
	endif
end


macro subtract(wave1, destname, type, val, inv, sttime, entime, trim, dpn)
	String wave1, destname="sub"
	Variable sttime=0, entime=0, dpn = 3, trim=1, type=3, val=0, inv=0
	Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
	prompt type, "type 0-5: val/min/max/avg/med/mode"
	prompt val, "sub val (if type==0)"
	prompt inv, "inverse sign? (0/1 NO/Inverse)"
	Prompt sttime,"RANGE for calc sub from (sec)"
	Prompt entime,"to (sec)"
	Prompt trim,"trim with the RANGE above? 0/1(No/Yes)"
	prompt destname, "NAME of the destination wave. (\"\" to overwrite wave1)"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Silent 1
	
	variable length, sub
	string awave
	string destwave
	
	string lista , a_wave, subStr
	lista = WaveList(wave1,";","")
	variable windex=0
	a_wave = StringFromList(windex, lista)
	Do
		length = deltax($a_wave)*(numpnts($a_wave)-1)
		if (sttime == -inf)
			sttime = leftx($a_wave)
		endif
		if (entime == inf)
			entime = rightx($a_wave)
		endif
		if(entime<sttime)
				abort
		endif
		if(stringMatch(destname, ""))
			destwave = a_wave
		else
			destwave = destname + a_wave
			if(trim)
				Duplicate/R=(sttime,entime)/O $a_wave $destwave
			else
				Duplicate/O $a_wave $destwave
			endif
		endif
		
		waveStats /Q /R=(sttime, entime) $a_wave
		if (type == 0) //val
			sub = val
			$destwave = $destwave - sub
		endif
		if (type < 0 || type > 5) //
			print "!!!! invalid type"
			return
		endif
		if (type == 1) //min
			sub = V_min
			$destwave = $destwave - sub
		endif
		if (type == 2) //max
			sub = V_max
			$destwave = sub - $destwave
		endif
		if (type == 3) //avg
			sub = V_avg
			$destwave = $destwave - sub
		endif
		if (type == 4) //med
			printPercentile(wave1=destwave,percentile=0.5, stt=sttime, ent=entime, step=0,suffix="hist_", kill=1, printToCmd=0)
			sub = K19
			$destwave = $destwave - sub
		endif
		if (type == 5) //mode
			printPercentile(wave1=destwave,percentile=0.5, stt=sttime, ent=entime, step=0,suffix="hist_", kill=1, printToCmd=0)
			sub = K18
			$destwave = $destwave - sub
		endif
		subStr = num2str(val)
		if(inv == 1)
			$destwave = -$destwave
		endif
		print " * subtraction of ", a_wave, " with ", sub, " (", sttime, "to", entime, ")"
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	Beep
End



macro makeGaussianNoise (avg, sigma, range, step, sampling, num, destname, dpn)
	String destname
	Variable range=7, sigma=0.1, avg=0.5, sampling=0.1, num=1, dpn = 1, step=10
	Prompt avg, "Mean (V)"
	Prompt sigma, "Sigma (V)"
	Prompt range, "range (sec)"
	Prompt step, "step (ms)"
	prompt sampling, "sampling (ms)"
	prompt num, "How many?"
	prompt destname, "SUFFIX of the destination wave"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Silent 1
	range = range
	step = step / 1000
	sampling = sampling / 1000

	string destwave
	variable pnt_range = range/sampling
	variable pnt_step = step/sampling
	variable zt=0, index, len, tau, pnt, noise	
	variable i = 0
	Do	
		destwave = "Gauss" + destname + "_" + num2str(i)
		Make/O/N=(pnt_range) $destwave
		pnt = 0
		do
			noise = gnoise(sigma) + avg
			$destwave[pnt, pnt+pnt_step-1] = noise
			pnt += pnt_step
		while ((pnt + pnt_step - 1) < pnt_range)
		SetScale/P x 0, sampling, "s", $destwave
	
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		i = i + 1
	while(i < num)
endmacro

macro makeBinominalNoise (p, sampling, rest, amp, range, step, phase, num, destname, dpn)
	String destname
	Variable p=2, sampling=16.66667, rest=0, amp=1, range=10, step=16.66667, phase=1, num=1, dpn = 1
	Prompt p, "probability (1/p; p=0-1)"
	prompt sampling, "wave sampling (ms)"
	Prompt rest, "resting"
	Prompt amp, "amplitude"
	Prompt range, "range (sec)"
	Prompt step, "pulse step (ms)"
	Prompt phase, "offset phase 0/1(no/random)"
	prompt num, "How many waves?"
	prompt destname, "PREFIX of the destination wave"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Silent 1
	range = range * 1000

	string destwave
	variable pnt_range = round(range/sampling)
//icate /O /R=(sttime, entime) $a_wave $destwave
	variable zt=0, index, len, tau, pnt, noise
	variable pnt_step = round(step/sampling)
	variable i = 0
	Do	
		destwave = destname + "_" + num2str(i)
		Make/O/N=(pnt_range) $destwave
		if (phase)
			pnt = abs(enoise(step/sampling/2) + step/sampling/2)
			if ((enoise(p/2) + p/2)<=1)
				$destwave[0,pnt-1] = amp + rest
			else
				$destwave[0,pnt-1] = rest
			endif
		else
			pnt = 0
		endif
		do
			noise = enoise(p/2) + p/2		// noise from 0 to p
			if (noise <= 1)
				$destwave[pnt, pnt+pnt_step-1] = amp + rest
			else
				$destwave[pnt, pnt+pnt_step-1] = rest
			endif
			pnt += pnt_step
		while (pnt <= pnt_range)
		SetScale/P x 0, sampling/1000, "s", $destwave
	
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		i = i + 1
	while(i < num)

endmacro


function filterWave ([waves, destname, HP_cut, HP_start, LP_start, LP_cut, HP_num, LP_num])
	String waves, destname
	Variable LP_start, LP_cut, LP_num, HP_start, HP_cut, HP_num
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*_Vm*"; destname="fil_"
		HP_cut=441;  HP_start=1323; LP_start=2205; LP_cut=6615;  HP_num=101; LP_num=101;
		Prompt waves, "wave name"
		Prompt destname, "destination prefix"
		Prompt HP_cut, "high pass cut freq (Hz)"
		Prompt HP_start, "high pass start freq (Hz)"
		Prompt LP_start, "low pass start freq (Hz)"
		Prompt LP_cut, "low pass cut freq (Hz)"
		Prompt HP_num, "high pass num (the larger, the steeper)"
		Prompt LP_num, "low pass num (the larger, the steeper)"
		DoPrompt  "filterWave", waves, destname, LP_start, LP_cut, LP_num, HP_start, HP_cut, HP_num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "filterWave(waves=\"" + waves + "\", destname=\"" + destname + "\", HP_cut=" + num2str(HP_cut) + ", HP_start=" + num2str(HP_start)  + ", LP_start=" + num2str(LP_start) + ", LP_cut=" + num2str(LP_cut) + ", HP_num=" + num2str(HP_num) + ", LP_num=" + num2str(LP_num) + ")"
	endif

	string lista, awave, destwave
	variable windex, samplefreq
	variable lowpass_start, lowpass_cut, lowpass_num, highpass_cut, highpass_start, highpass_num
		lista = WaveList(waves,";","")
		windex = 0
		awave = StringFromList(windex, lista)
	Do
		destwave = destname + awave
		samplefreq = 1/deltax($awave)
		lowpass_start = LP_start / samplefreq
		lowpass_cut = LP_cut / samplefreq
		highpass_start = HP_start / samplefreq
		highpass_cut = HP_cut / samplefreq
		Duplicate /O $awave, $destwave		
		if (LP_start == 0 || LP_cut == 0)
			FilterFIR /E=0 /HI={highpass_cut, highpass_start, HP_num} /WINF=Hanning $destwave
		elseif  (HP_start == 0 || HP_cut == 0)
			FilterFIR /E=0 /LO={lowpass_start, lowpass_cut, LP_num} /WINF=Hanning $destwave
		else
			FilterFIR /E=0 /HI={highpass_cut, highpass_start, HP_num} /LO={lowpass_start, lowpass_cut, LP_num} /WINF=Hanning $destwave
		endif
		windex+=1
		awave = StringFromList(windex, lista)
	While(strlen(awave)!=0)
End


function normWave ([wave1, wavedest, sttime, entime, normSttime, normEntime, normVal, normMethod])
	String wave1, wavedest
	Variable normVal, sttime, entime, normSttime, normEntime, normMethod
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1="B*"; wavedest="norm"
		normVal=-200e-12; sttime=-inf; entime=inf; normSttime=0.1015; normEntime=0.103; normMethod=1
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt wavedest, "destwave name (\"\"to overwrite)" //, popup wavelist ("*",";","")	
		Prompt sttime, "resting from (s)"
		Prompt entime, "to (s)"
		Prompt normSttime, "Norm Range from (s)"
		Prompt normEntime, "to (s)"
		Prompt normVal, "norm to "
		Prompt normMethod, "method 0/1/2/3 (avg/min/max/SD) " // (avg/min/max/SD)
		DoPrompt  "normWave", wave1, wavedest, sttime, entime, normSttime, normEntime, normVal, normMethod
		if (V_Flag)	// User canceled
			return -1
		endif
		print "normWave(wave1=\"" + wave1 + "\", wavedest=\"" + wavedest + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime)  + ", normSttime=" + num2str(normSttime) + ", normEntime=" + num2str(normEntime) + ", normVal=" + num2str(normVal) + ", normMethod=" + num2str(normMethod) + ")"
	endif

	string lista , a_wave, destwave
	variable windex=0, length, num, resting
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do		
		if(sttime >= entime)
			print"sttime >= entime"
			abort
		endif
		if(normSttime>=normEntime)
			print"normSttime >= normEntime"
			abort
		endif
		
		wavestats /Q /R=(sttime, entime) $a_wave
		resting = V_avg
		wavestats /Q /R=(normSttime, normEntime) $a_wave
		if (normMethod == 0)
			num = normVal / (V_avg - resting)
		endif
		if (normMethod == 1)
			num = normVal / (V_min - resting)
		endif
		if (normMethod == 2)
			num = normVal / (V_max - resting)
		endif
		if (normMethod == 3)
			num = normVal / (V_sdev - resting)
		endif

		multiplyWave(wave1=a_wave, wavedest=wavedest, dpn=3, num=num, offset=3, val=0, sttime=-inf, entime=inf, avgsttime=sttime, avgentime=entime)

			// multiplyWave (wave1, wavedest, dpn, num, offset, val, sttime, entime, avgsttime, avgentime)
			//    offset 0-3 (avg/median/mode/val)

		destwave = wavedest + "_" + a_wave + "_" + num2str(windex)
		

		if (normMethod == 0)
			print " * norm ",  num2str(num) ," : " , a_wave, " from ", V_avg, " ( avg from ", normSttime, " to ", normEntime, " )   to ", normVal,  " (", sttime, "to", entime, ")"
		endif
		if (normMethod == 1)
			print " * norm ",  num2str(num) ," : " ,  a_wave, " from ", V_min, " ( min from ", normSttime, " to ", normEntime, " )   to ", normVal,  " (", sttime, "to", entime, ")"
		endif
		if (normMethod == 2)
			print " * norm ",  num2str(num) ," : " ,  a_wave, " from ", V_max, " ( max from ", normSttime, " to ", normEntime, " )   to ", normVal,  " (", sttime, "to", entime, ")"
		endif
		if (normMethod == 3)
			print " * norm ",  num2str(num) ," : " ,  a_wave, " from ", V_sdev, " ( sdev from ", normSttime, " to ", normEntime, " )   to ", normVal,  " (", sttime, "to", entime, ")"
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end macro



function sum2Waves([wave1, wave2, destname, sumMethod, sttime, entime, dpn, printToCmd])
	String wave1, wave2, destname
	Variable sumMethod, sttime, entime, dpn, printToCmd
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1="Pn*"; wave2="Temp*"; destname="sum_";
		sttime=-inf; entime=inf; dpn=3; printToCmd=1; sumMethod=0;

		Prompt wave1, "Wave1 name"
		Prompt wave2, "Wave2 name"
		Prompt destname, "SUFFIX. overwrite wave1 if \"\""
		Prompt sumMethod, "method 0/1 ((1-2)/(1+2))"
		Prompt sttime, "range from (s)"
		Prompt entime, "to"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"		
		Prompt printToCmd, "print 0/1(no/yes)"
		DoPrompt  "sum2Waves", wave1, wave2, destname, sumMethod, sttime, entime, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* sum2Waves(wave1=\"" + wave1 + "\", wave2=\"" + wave2 + "\", destname=\"" + destname + "\", sumMethod=" + num2str(sumMethod) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	string lista, listb, a_wave, b_wave, destwave, polarity
	variable windex=0, length_a, length_b, stt, ent
		lista = WaveList(wave1,";","")
		listb = WaveList(wave2,";","")
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
	Do
		wave a = $a_wave
		wave b = $b_wave
		length_a = deltax(a)*(numpnts(a)-1)
		length_b = deltax(b)*(numpnts(b)-1)
		if(sttime==-inf)
			stt = leftx(a)
		else
			stt = sttime
		endif
		if(entime==inf)
			ent = rightx(a)
		else
			ent = entime
		endif
		if(ent<=stt)
			abort
		endif

		if (stringmatch(destname, ""))
			wave d = a
		else
			destwave = destname + num2str(windex)
			Duplicate /O /R=(stt, ent) $a_wave $destwave
			wave d = $destwave
		endif

		if (sumMethod)
			d = a + b
		else
			d = a - b
		endif
		if(dpn==1)
			display d
		endif
		if(dpn==2)
			appendtograph d
		endif

		if (printToCmd)
			if(sumMethod)
				polarity = "+"
			else
				polarity = "-"
			endif
			print " * ", destwave, " = ", a_wave, " ", polarity , " ", b_wave, " ( ", stt, " - ", ent, " ) "
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
	While(strlen(a_wave)!=0)
end macro


function multiply2Waves([waves, wave2, destname, mulMethod, sttime, entime, dpn, printToCmd])
	String waves, wave2, destname
	Variable mulMethod, sttime, entime, dpn, printToCmd
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "subVavg*"; wave2="Vsd*"; destname="Vsnr" 
		mulMethod=0; sttime=-inf; entime=inf; dpn=3; printToCmd=0;
		Prompt waves, "Wave1 name"
		Prompt wave2, "Wave2 name"
		Prompt destname, "SUFFIX. overwrite wave1 if \"\""
		Prompt mulMethod, "method 0/1 ((1/2)/(1*2))"
		Prompt sttime, "range from (s)"
		Prompt entime, "to"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"		
		Prompt printToCmd, "print 0/1(no/yes)"
		DoPrompt  "multiply2Waves", waves, wave2, destname, mulMethod, sttime, entime, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print " multiply2Waves(waves=\"" + waves + "\", wave2=\"" + wave2 + "\", destname=\"" + destname + "\", mulMethod=" + num2str(mulMethod) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	string lista, listb, a_wave, b_wave
	variable windex=0, flagKill=0, flagOverwrite=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		listb = WaveList(wave2,";","")
		b_wave = StringFromList(windex, listb)
	Do
		if (sttime >= entime)
			print "sttime >= entime"
			abort
		endif
		if (leftx(a) < sttime)
			string a_temp = "temp" + a_wave
			string b_temp = "temp" + b_wave
			Duplicate /O /R=(sttime, entime) $a_wave $a_temp
			Duplicate /O /R=(sttime, entime) $b_wave $b_temp
			wave a = $a_temp
			wave b = $b_temp
			flagKill=1
		else
			wave a = $a_wave
			wave b = $b_wave
		endif

		if (stringmatch(destname, ""))
			wave d = a
			flagOverwrite=1
		else
			string destwave = destname + a_wave
			Duplicate /O /R=(sttime, entime) $a_wave $destwave
			wave d = $destwave
		endif
		
		if (mulMethod)
			d = a * b
		else
			d = a / b
		endif
		
		if (flagKill)
			killwaves b
			if (flagOverwrite)
//				killwaves $a_wave
			else
				killwaves a
			endif
		endif

		if(dpn==1)
			display d
		elseif(dpn==2)
			appendtograph d
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
	While(strlen(a_wave)!=0 && strlen(b_wave)!=0)
End

function smoothWave ([wave1, destname, sttime, entime, smoothMethod, endEffect, width, repetition, sgOrder, printToCmd])
	String wave1, destname
	Variable sttime, entime, printToCmd, smoothMethod, width, repetition, sgOrder, endEffect
		if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1="*2"; destname= "smooth_"
		sttime=0; entime=0; printToCmd=1; smoothMethod=2; width=5; repetition=10; sgOrder=2; endEffect=0
		Prompt wave1, "Wave1 name" //, popup wavelist ("*",";","")
		Prompt destname, "destwave name" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt smoothMethod, "method1/2/3(BN/Box/Savitzky-Golay) " // 1/2/3 = Binominal/Box/Savitzky-Golay
		Prompt endEffect, "0/1/2/3(bounce/wrap/zero/fill)" // 0/1/2/3 = bounce/wrap/zero/fill
		Prompt width, "width (ODD for Box(1-101)/SG(5(7)-25) only)" //  ODD for Box(1-101)/SG(5(7)-25) only
		Prompt repetition, "width/repetition (BN/Box only)"
		Prompt sgOrder, "Order (2/4: for SG only)"
		Prompt printToCmd, "Print? 0/1 (No/Yes)"

		DoPrompt  "smoothWave", wave1, destname, sttime, entime, smoothMethod, endEffect, width, repetition, sgOrder, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "smoothWave(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", smoothMethod=" + num2str(smoothMethod) + ", endEffect=" + num2str(endEffect) + ", width=" + num2str(width) + ", repetition=" + num2str(repetition) + ", sgOrder=" + num2str(sgOrder) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	string lista, a_wave, destwave
	variable windex=0, length_a, offset = 0, stt, ent
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		//length_a = deltax($a_wave)*(numpnts($a_wave)-1)
		destwave = destname + a_wave
		if(sttime == 0 && entime == 0)
			stt = leftx($a_wave)
			ent = rightx($a_wave)
		endif
		if(sttime==-inf)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if (entime==inf)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		if(ent<=stt)
			abort
		endif
		if (!stringmatch(a_wave, destwave))
			Duplicate /O /R=(stt, ent) $a_wave $destwave
		endif
		wavestats /Q $destwave
//		offset = V_avg
		wave d = $destwave
//		d = d - offset
		if (smoothMethod==1)	// Binominal (multipass Box smooth at factor of 50 (V_doOrigBinomSmooth=0))
			smooth /E=(endEffect) repetition, d
			if (printToCmd)
				print "     ", destwave, " smoothed by Binominal of Np=", repetition, "(width=", (2*repetition-1) ,", SD=", 0.5*0.5*(2*repetition) , "; n=", (2*repetition), ", p=0.5) (endEffect=", endEffect, ")"
			endif
		endif
		if (smoothMethod==2)	// Box
			smooth /B=(repetition) /E=(endEffect) width, d
			if (printToCmd)
				print "     ", destwave, " smoothed by ", width ," points Box ", repetition, " times (endEffect=", endEffect, ")"
			endif
		endif
		if (smoothMethod==3)	// Savitzky-Golay
			smooth /S=(sgOrder) /E=(endEffect)  width, d
			if (printToCmd)
				print "     ", destwave, " smoothed by ", width, " points ", sgOrder, " nd Savitzky-Golay (endEffect=", endEffect, ")"
			endif
		endif
//		d += offset

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end macro


function absWave([waves, destname, dpn])
	String waves, destname
	Variable dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="R"
		dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "absWave", waves, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "absWave(waves=\"" + waves + "\", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave
	variable windex=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave d = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave d = $destwave
		endif		
		d = abs(a)
		if(dpn==1)
			display d
		elseif(dpn==2)
			appendtograph d
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End



function rectWave([waves, destname, pol, type, thres, dpn])
	String waves, destname
	Variable pol, type, thres, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="R"
		pol=1; type=0; thres=2; dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt pol, "polarity 0/1 (cut pos/neg)"
		Prompt type, "type 0/1 (SD/val)"
		Prompt thres, "thres N (SD*N/val=N)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "rectWave", waves, destname, pol, type, thres, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "rectWave(waves=\"" + waves + "\", destname=\"" + destname + "\", pol=" + num2str(pol) + ", type=" + num2str(type) + ", thres=" + num2str(thres) + ", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave
	variable windex=0, pindex, dsize, thresval
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave d = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave d = $destwave
		endif
		dsize = DimSize(d, 0)
		if (type==0)
			wavestats /Q d
			if (pol == 0)
				thresval = V_avg + thres*V_sdev 
				pindex=0
				Do
					if (d[pindex] > thresval)
						d[pindex] = thresval
					endif
					pindex += 1
				While(pindex<dsize)
			elseif (pol == 1)
				thresval = V_avg - thres*V_sdev
				pindex=0
				Do
					if (d[pindex] < thresval)
						d[pindex] = thresval
					endif
					pindex += 1
				While(pindex<dsize)
			endif
		elseif (type==1)
			if (pol == 0)
				pindex=0
				Do
					if (d[pindex] > thres)
						d[pindex] = thres
					endif
					pindex += 1
				While(pindex<dsize)
			elseif (pol == 1)
				pindex=0
				Do
					if (d[pindex] < thres)
						d[pindex] = thres
					endif
					pindex += 1
				While(pindex<dsize)
			endif
		endif
		
		if(dpn==1)
			display d
		elseif(dpn==2)
			appendtograph d
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End

function differentiateWave([waves, destname, dpn])
	String waves, destname
	Variable dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="R"
		dpn=3;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX. overwritten if \"\""
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "differentiateWave", waves, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "differentiateWave(waves=\"" + waves + "\", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave
	variable windex=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		destwave = destname + "_" + a_wave
		if (stringmatch(destname, ""))
			wave d = $a_wave
		else
			Duplicate /O $a_wave $destwave
			wave d = $destwave
		endif		
		differentiate d
		if(dpn==1)
			display d
		elseif(dpn==2)
			appendtograph d
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End


macro makeComplexWave (range, step, destname)
	String destname
	Variable length=7, step=0.1
	Prompt length, "length (sec)"
	Prompt step, "step (ms)"
	prompt destname, "SUFFIX of the destination wave"
	Silent 1
	
	length = length * 1000
	string destwave = "Cmplx_" + destname
	Make/C/O/N=(length) $destwave
endmacro


function makeColorIndexWave([namewave, type, xtype, minval, maxval, stColor, enColor])
	String namewave, stColor, enColor
	Variable type, xtype, minval, maxval
	if (numType(strlen(namewave)) == 2)		// if (wave == null) : so there was no input
		namewave = "BlackBlueRed"; stColor="65535;0;0"; enColor="0;0;65535";
		type=3; xtype=0; minval = 0; maxval = 1;
		Prompt namewave, "Color index name"
		Prompt type, "type 0-3/4 (Rbw/user)"
		Prompt xtype, "X type 0/1 (linear/log)"
		Prompt minval, "min value"
		Prompt maxval, "max value"
		Prompt stColor, "red;grn;blu (0-65535)"
		Prompt enColor, "red;grn;blu (0-65535)"
		DoPrompt  "makeColorIndexWave", namewave, type, xtype, minval, maxval, stColor, enColor
		if (V_Flag)	// User canceled
			return -1
		endif
		print " makeColorIndexWave(namewave=\"" + namewave + "\", type=" + num2str(type) + ", xtype=" + num2str(xtype) + ", minval=" + num2str(minval) + ", maxval=" + num2str(maxval) + ", stColor=\"" + stColor + "\", enColor=\"" + enColor + "\")"
	endif

	////////// some error is expected for log or edge of the color alternation (2015/3/11)
	variable nPnt, wred, wgrn, wblu, nindex, nDiv, nRows, xMin, xMax, nstep, nval
	variable stR,stG,stB, enR,enG,enB
	string sstR,sstG,sstB, senR,senG,senB
	string lognamewave
	nPnt = maxval - minval
	nstep = nPnt / 10000
	lognamewave = "log_" + namewave 
	Make /N=((nPnt/nstep),3) /O $namewave
	SetScale/P x 0,nstep,"", $namewave
	wave indexwave = $namewave	
		If (type == 0)
			nindex=0
			nval = nindex * nstep
			Do
				if (nval <= nPnt*1/6)
					wred = 36720 - 17264 * nval / (nPnt * 1/6)
					wgrn = 0
					wblu = 65535 - 32000 * nval / (nPnt * 1/6)
				elseif (nval <= nPnt*1/3)
					wred = 19456 - 19456 * (nval - nPnt * 1/6) / (nPnt * 1/6)
					wgrn = 0
					wblu = 33535 + 32000 *  (nval - nPnt * 1/6) / (nPnt * 1/6)
				elseif (nval <= nPnt*1/2)
					wred = 0
					wgrn = 0 + 65535 *  (nval - nPnt * 1/3) / (nPnt * 1/6)
					wblu = 65535 - 65535 * (nval - nPnt * 1/3) / (nPnt * 1/6)
				elseif (nval <= nPnt*2/3)
					wred = 65535 *  (nval - nPnt * 1/2) / (nPnt * 1/6)
					wgrn = 65535
					wblu = 0
				else
					wred = 65535
					wgrn = 65535 - 65535 * (nval - nPnt * 2/3) / (nPnt * 1/3)
					wblu = 0
				endif
				indexwave[nindex][0] = wred
				indexwave[nindex][1] = wgrn
				indexwave[nindex][2] = wblu
				nindex += 1
				nval = nindex * nstep
			While (nval < nPnt)
		elseif (type == 1)
			nindex=0
			nval = nindex * nstep
			Do
				if (nval <= nPnt*1/7)
					wred = 36720 * nval / (nPnt * 1/7)
					wgrn = 0
					wblu = 65535 * nval / (nPnt * 1/7)
				elseif (nval <= nPnt*2/7)
					wred = 36720 - 17264 * (nval - nPnt * 1/7) / (nPnt * 1/7)
					wgrn = 0
					wblu = 65535 - 32000 * (nval - nPnt * 1/7) / (nPnt * 1/7)
				elseif (nval <= nPnt*3/7)
					wred = 19456 - 19456 * (nval - nPnt * 2/7) / (nPnt * 1/7)
					wgrn = 0
					wblu = 33535 + 32000 *  (nval - nPnt * 2/7) / (nPnt * 1/7)
				elseif (nval <= nPnt*4/7)
					wred = 0
					wgrn = 0 + 65535 *  (nval - nPnt * 3/7) / (nPnt * 1/7)
					wblu = 65535 - 65535 * (nval - nPnt * 3/7) / (nPnt * 1/7)
				elseif (nval <= nPnt*5/7)
					wred = 65535 *  (nval - nPnt * 4/7) / (nPnt * 1/7)
					wgrn = 65535
					wblu = 0
				else
					wred = 65535
					wgrn = 65535 - 65535 * (nval - nPnt * 5/7) / (nPnt * 2/7)
					wblu = 0
				endif
				indexwave[nindex][0] = wred
				indexwave[nindex][1] = wgrn
				indexwave[nindex][2] = wblu
				nindex += 1
				nval = nindex * nstep
			While (nval < nPnt)
		elseif (type == 2)
			nindex=0
			nval = nindex * nstep
			Do
				nDiv = 5
				if (nval <= nPnt*1/nDiv)	// black to blue
					wred = 0
					wgrn = 0
					wblu = 65535 * nval / (nPnt * 1/nDiv)
				elseif (nval <= nPnt*2/nDiv)	// blue to green
					wred = 0
					wgrn = 65535 * (nval - nPnt * 1/nDiv) / (nPnt * 1/nDiv)
					wblu = 65535 - 65535 * (nval - nPnt * 1/nDiv) / (nPnt * 1/nDiv)
				elseif (nval <= nPnt*3/nDiv)	// green to yellow
					wred = 65535 * (nval - nPnt * 2/nDiv) / (nPnt * 1/nDiv)
					wgrn = 65535
					wblu = 0
				else					// yello to red
					wred = 65535
					wgrn = 65535 - 65535 * (nval - nPnt * 3/nDiv) / (nPnt * 2/nDiv)
					wblu = 0
				endif
				indexwave[nindex][0] = wred
				indexwave[nindex][1] = wgrn
				indexwave[nindex][2] = wblu
				nindex += 1
				nval = nindex * nstep
			While (nval < nPnt)
		elseif (type == 3)
			nindex=0
			nval = nindex * nstep
			Do
				if (nval <= nPnt*1/5)	// black to lightblue
					wred = 20000 * nval / (nPnt * 1/5)
					wgrn = 20000 * nval / (nPnt * 1/5)
					wblu = 65535 * nval / (nPnt * 1/5)
				elseif (nval <= nPnt*2/5)	// lightblue to lightgreen
					wred = 20000
					wgrn = 20000 + 45535 * (nval - nPnt * 1/5) / (nPnt * 1/5)
					wblu = 65535 - 35535 * (nval - nPnt * 1/5) / (nPnt * 1/5)
				elseif (nval <= nPnt*3/5)	// green to yellow
					wred = 20000 + 45535 * (nval - nPnt * 2/5) / (nPnt * 1/5)
					wgrn = 65535
					wblu = 30000
				else					// yellow to light red
					wred = 65535
					wgrn = 65535 - 35535 * (nval - nPnt * 3/5) / (nPnt * 2/5)
					wblu = 30000
				endif
				indexwave[nindex][0] = wred
				indexwave[nindex][1] = wgrn
				indexwave[nindex][2] = wblu
				nindex += 1
				nval = nindex * nstep
			While (nval < nPnt)
		else
			splitstring /E="([[:digit:]]+);([[:digit:]]+);([[:digit:]]+)" stColor, sstR,sstG,sstB
			splitstring /E="([[:digit:]]+);([[:digit:]]+);([[:digit:]]+)" enColor, senR,senG,senB
			stR = str2num(sstR)
			stG = str2num(sstG)
			stB = str2num(sstB)
			enR = str2num(senR)
			enG = str2num(senG)
			enB = str2num(senB)
			nindex=0
			nval = nindex * nstep
			Do
				if (nval <= nPnt*1/3)	// black to stColor
					wred = stR * nval / (nPnt * 1/3)
					wgrn = stG * nval / (nPnt * 1/3)
					wblu = stB * nval / (nPnt * 1/3)
				elseif (nval <= nPnt*2/3)	// stColor to enColor
					wred = stR + (enR - stR) * (nval - nPnt * 1/3) / (nPnt * 1/3)
					wgrn = stG + (enG - stG) * (nval - nPnt * 1/3) / (nPnt * 1/3)
					wblu = stB + (enB - stB) * (nval - nPnt * 1/3) / (nPnt * 1/3)
				else					// enColor to white
					wred = enR + (65535 - enR) * (nval - nPnt * 2/3) / (nPnt * 1/3)
					wgrn = enG + (65535 - enG) * (nval - nPnt * 2/3) / (nPnt * 1/3)
					wblu = enB + (65535 - enB) * (nval - nPnt * 2/3) / (nPnt * 1/3)
				endif
				indexwave[nindex][0] = wred
				indexwave[nindex][1] = wgrn
				indexwave[nindex][2] = wblu
				nindex += 1
				nval = nindex * nstep
			While (nval < nPnt)
		endif
		if (xtype == 1)		// log
			Make /N=((nPnt/nstep),3) /O $lognamewave	
			wave logindexwave = $lognamewave	
			nRows = nPnt
			xMin = minval
			xMax = maxval
			logindexwave[][] = floor(nRows*(log(indexwave[p][q])-log(xMin))/(log(xmax)-log(xMin)))
		endif

End

macro modifyWave (wave1, destname, sttime, entime, target, valueRe, valueIm, dpn, printToCmd)
	String wave1="", destname= "LP30_"
	Variable sttime=0, entime=0, valueRe=0, valueIm=0, printToCmd=1, target=0, dpn=1
	Prompt wave1, "wave name" //, popup wavelist ("*",";","")
	Prompt destname, "destwave name" //, popup wavelist ("*",";","")
	Prompt sttime, "Range from (s)"
	Prompt entime, "to (s)"
	Prompt target, "target 0/1 (Double/Complex) "
	Prompt valueRe, "value (real)"
	Prompt valueIm, "value (imaginary)"
	Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
	Prompt printToCmd, "Print? 0/1 (No/Yes)"

	string lista, a_wave, destwave
	destwave = destname
	variable windex=0, length_a, pnt_a, offset = 0
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	variable zt=0, index, len, tau, pnt, noise
	variable stpnt, enpnt
	Do
		length_a = deltax($a_wave)*(numpnts($a_wave)-1)
		pnt_a = (numpnts($a_wave)-1)
		if(entime==0)
			entime = length_a
		endif
		if(entime<=sttime)
			abort
		endif

		if (stringmatch(destwave, ""))
			destwave = a_wave
		else
			destwave = destname + a_wave
			Duplicate /O $a_wave $destwave
		endif

		stpnt = x2pnt($destwave, sttime)
		enpnt = x2pnt($destwave, entime)
		pnt = 0
		if (target == 0)
			$destwave[stpnt, enpnt] = valueRe
		endif
		if (target == 1)
			$destwave[stpnt, enpnt] = cmplx(valueRe, valueIm)
		endif
	
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

end macro


function discretizeWave ([wave1, destname, sttime, entime, step, type, dpn, printToCmd])
	String wave1, destname
	Variable sttime, entime, step, printToCmd, type, dpn
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "disc_"
		sttime=-inf; entime=inf; step=15; printToCmd=1; type=1; dpn=1
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "destwave(Prefix)" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt step, "step (ms) "
		Prompt type, "type 0/1/2 (avg/sum/Hz) "
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		Prompt printToCmd, "Print? 0/1 (No/Yes)"
		DoPrompt  "discretizeWave", wave1, destname, sttime, entime, step, type, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "discretizeWave(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime)  + ", step=" + num2str(step)  + ", type=" + num2str(type)  + ", dpn=" + num2str(dpn)  + ", printToCmd=" + num2str(printToCmd) + ")"
	endif
	step = step/1000

	string lista, a_wave, destwave
	destwave = destname
	if (stringmatch(destwave, ""))
		destwave = "disc_"
	endif
	variable windex=0, length_a, pnt_a, offset = 0, right_t, left_t, target
	target = 0
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	variable pnt, pntstep, pnt_dest, pnt_sttime, pnt_entime, pnt_index
	Do
		destwave = destname + a_wave
		length_a = deltax($a_wave)*(numpnts($a_wave)-1)
		pnt_a = (numpnts($a_wave)-1)
		if(entime==inf)
			right_t = rightx($a_wave)
		else
			right_t = entime
		endif
		if(sttime==-inf)
			left_t = leftx($a_wave)
		else
			left_t = sttime
		endif
		if(right_t<=left_t)
			abort
		endif
		pnt_dest = (right_t - left_t)/step
		Make /O /N=(pnt_dest) $destwave
		wave d = $destwave

		pntstep = step / deltax($a_wave)
		pnt_sttime = x2pnt($a_wave, left_t)
		pnt_entime = x2pnt($a_wave, right_t)
		pnt = pnt_sttime
		pnt_index=0
		Do
			if (type == 0)
				wavestats /Q /R=[pnt, pnt + pntstep - 1] $a_wave
				d[pnt_index] = V_Avg
			elseif (type == 1)
				d[pnt_index] = sum($a_wave, pnt2x($a_wave, pnt), pnt2x($a_wave, pnt+pntstep-1))
			elseif(type ==2)
				d[pnt_index] = sum($a_wave, pnt2x($a_wave, pnt), pnt2x($a_wave, pnt+pntstep-1))/step					
			endif
			pnt += pntstep
			pnt_index += 1
		while (pnt + pntstep - 1 < pnt_entime)
		if (pnt < pnt_entime)
			wavestats /Q /R=[pnt, pnt_entime] $destwave
//			$destwave[pnt_index] = V_Avg
		endif
		
		SetScale/P x (left_t + step/2), step, "s", $destwave

		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function duplicateWave ([wave1, destname, sttime, entime, sty, eny, type, num, dpn, printToCmd])
	String wave1, destname
	Variable sttime, entime, sty, eny, printToCmd, type, dpn, num
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "dup_"
		sttime=-inf; entime=inf; sty=0; eny=0; type=0; num=0; printToCmd=1; dpn=1
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "destwave prefix" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt sty, "Dup. only Y from"
		Prompt eny, "to (if <=Yfrom, ignore)"
		Prompt type, "type 0/1(norm/dif)"
		Prompt num, "number of copy (if <=0, ignore)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		Prompt printToCmd, "Print? 0/1 (No/Yes)"
		DoPrompt  "duplicateWave", wave1, destname, sttime, entime, sty, eny, type, num, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "DuplicateWave(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime)  + ", sty=" + num2str(sty) + ", eny=" + num2str(eny)  + ", type=" + num2str(type) + ", num=" + num2str(num)  + ", dpn=" + num2str(dpn)  + ", printToCmd=" + num2str(printToCmd) + ")"
	endif

	if(entime<=sttime)
		print entime, "<=", sttime, ", so abort"
		abort
	endif
	if (type == 1 && sty >= eny)
		print eny, "<=", sty, ", so abort"
		abort
	endif

	
	string lista, a_wave, destwave, destwave2
	variable windex=0, pnt_a, offset = 0, target=0, nindex, lend, pindex, stt, ent, allnum=0, tmpnum
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	variable pnt, pntstep, diffval

	Do
		windex +=1
		allnum += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	num = round(num)
	if (0 < num && num < allnum)
		Make /O /N=(num) tmprandnum
		tmprandnum = NaN
		nindex = 0
		Do
			tmpnum = round((enoise(0.5) + 0.5) * allnum - 0.5)
			FindValue /V=(tmpnum) tmprandnum
			if (V_value == -1)
				tmprandnum[nindex] = tmpnum
				nindex += 1
			endif
		While (nindex < num)
		sort tmprandnum, tmprandnum
	endif

	
	windex=0
	a_wave = StringFromList(windex, lista)
	Do
		if (strlen(a_wave) ==0)	/// i dont know why but this is necessary to stop the loop (after continue)
			break
		endif
		if (0 < num && num < allnum)
			FindValue /V=(windex) tmprandnum
			if (V_value == -1)
				windex += 1
				a_wave = StringFromList(windex, lista)
				continue
			endif
		endif
		destwave = destname + a_wave
		if(sttime==-inf)
			stt = leftx($a_wave)
		else
			stt = sttime
		endif
		if(entime==inf)
			ent = rightx($a_wave)
		else
			ent = entime
		endif
		if (stringmatch(a_wave, destwave))
			destwave2 = destname + a_wave + "_c"
			Duplicate /O /R=(stt, ent) $a_wave $destwave2
			Killwaves $a_wave
			Rename $destwave2, $destwave
		else
			Duplicate /O /R=(stt, ent) $a_wave $destwave
		endif
		if (type == 0)
			if (sty < eny)
				lend = numpnts($destwave)
				wave d = $destwave
				nindex = 0
				pindex = 0
				Do
					if (d[pindex] < sty || d[pindex] > eny)
						deletepoints pindex, 1, $destwave
						pindex -= 1
					endif
					pindex += 1
					nindex += 1
				While(nindex < lend)
			endif
		elseif (type ==1)
			if (sty < eny)
				lend = numpnts($destwave)
				wave d = $destwave
				nindex = 0
				pindex = 0
				Do
					diffval = d[pindex+1] - d[pindex]
					if (diffval < sty || diffval > eny || numtype(diffval) == 2)
						deletepoints pindex, 1, $destwave
						pindex -= 1
					else
						deletepoints pindex+1, 1, $destwave
					endif
					pindex += 1
					nindex += 1
				While(nindex < lend-1)
			endif
		endif
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function duplicateWithONOFFwave ([stwave, enwave, stoffset, enoffset, type, destname, wave1, wave2, wave3, wave4])
	String stwave, enwave, destname, wave1, wave2, wave3, wave4
	variable stoffset, enoffset, type
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		stwave="song_onset_*"; enwave="song_offset_*"; destname= "dup_"; wave1="*_mic"; wave2="*_t"; wave3="*_vm"; wave4="";
		stoffset = -1; enoffset = 1; type=1;
		Prompt stwave, "ON wave name" //, popup wavelist ("*",";","")
		Prompt enwave, "OFF wave name" //, popup wavelist ("*",";","")
		Prompt stoffset, "ON offset (say -1[s])"
		Prompt enoffset, "OFF offset (say 1[s])"
		Prompt destname, "destwave prefix (if \"\", overwrite)" //, popup wavelist ("*",";","")
		Prompt type, "type 0/1/2 (pnt, x, Osort(not work))"
		Prompt wave1, "wave1 name" //, popup wavelist ("*",";","")
		Prompt wave2, "wave2 name (ignore if \"\")" //, popup wavelist ("*",";","")
		Prompt wave3, "wave3 name (ignore if \"\")" //, popup wavelist ("*",";","")
		Prompt wave4, "wave4 name (ignore if \"\")" //, popup wavelist ("*",";","")
		DoPrompt  "duplicateWithONOFFwave", stwave, enwave, stoffset, enoffset, destname, wave1, wave2, wave3, wave4
		if (V_Flag)	// User canceled
			return -1
		endif
		print "DuplicateWithONOFFwave(stwave=\"" + stwave + "\", enwave=\"" + enwave + "\", stoffset=" + num2str(stoffset) + ", enoffset=" + num2str(enoffset) + ", destname=\"" + destname + "\", type=", num2str(type), ",wave1=\"" + wave1 + "\", wave2=\"" + wave2 + "\", wave3=\"" + wave3 + "\", wave4=\"" + wave4 + "\")"
	endif
	
	//  DuplicateWithONOFFwave(stwave="bout_onset_*", enwave="bout_offset_*", stoffset=0, enoffset=0, destname="d_", type= 0  ,wave1="spike*", wave2="ADC*ADC-01*", wave3="", wave4="")

	string stlist, enlist, wave1list, wave2list, wave3list, wave4list, regExpr, rectime
	string wst, wen, w1, w2, w3, w4, destwave
	variable sindex=0, windex=0, sttime, entime, dindex, len_st, flagNext, offset
	variable samplerate = 20000
	if (type == 2)
		regExpr =  "Os([0-9]+)_.*"
	else
		regExpr =  ".*_([0-9]+)"
	endif
	stlist = WaveList(stwave,";","")
	wst = StringFromList(sindex, stlist)
	enlist = WaveList(enwave,";","")
	wen = StringFromList(sindex, enlist)
	wave1list = WaveList(wave1,";","")
	wave2list = WaveList(wave2,";","")
	wave3list = WaveList(wave3,";","")
	wave4list = WaveList(wave4,";","")
	sindex = 0
	wst = StringFromList(sindex, stlist)
	wave st = $wst
	wen = StringFromList(sindex, enlist)
	Do
		print "\t", sindex, ": ", wst
		splitString /E=(regExpr) wst, rectime
		wave st = $wst
		len_st = numpnts(st)
		wave en = $wen
		dindex = 0
		if (type == 1 || type == 2)
			Do
				flagNext = 0
				if (st[dindex] > en[dindex])
					print "ERROR ::::::::::::::: ON time is after OFF time"
					abort
				else
					sttime = st[dindex]/1000 + stoffset
					entime = en[dindex]/1000 + enoffset
					if (sttime < 0)
						offset = stoffset - sttime
					else
						offset = stoffset
					endif
					windex = 0
					w1 = StringFromList(windex, wave1list)
					Do
						if (waveexists($w1))
							if (strsearch(w1, rectime, 0) == -1)
								print "\t\t", w1, " does not include ", rectime
								flagNext = 1
							else
								destwave = destname + w1 + "_" + num2str(dindex)
								Duplicate /O /R=(sttime, entime) $w1, $destwave
								Setscale /P x, offset, deltax($w1), $destwave
							endif
						endif
						windex += 1
						w1 = StringFromList(windex, wave1list)
					While(waveexists($w1))
					windex = 0
					w2 = StringFromList(windex, wave2list)
					Do
						if (waveexists($w2))
							if (strsearch(w2, rectime, 0) == -1)
								print "\t\t", w2, " does not include ", rectime
								flagNext = 1
							else
								destwave = destname + w2 + "_" + num2str(dindex)
								Duplicate /O /R=(sttime, entime) $w2, $destwave
								Setscale /P x,  offset, deltax($w2), $destwave
							endif
						endif
						windex += 1
						w2 = StringFromList(windex, wave2list)
					While(waveexists($w2))
					windex = 0
					w3 = StringFromList(windex, wave3list)
					Do
						if (waveexists($w3))
							if (strsearch(w3, rectime, 0) == -1)
								print "\t\t", w3, " does not include ", rectime
								flagNext = 1
							else
								destwave = destname + w3 + "_" + num2str(dindex)
								Duplicate /O /R=(sttime, entime) $w3, $destwave
								Setscale /P x,  offset, deltax($w3), $destwave
							endif
						endif
						windex += 1
						w3 = StringFromList(windex, wave3list)
					While(waveexists($w3))
					windex = 0
					w4 = StringFromList(windex, wave4list)
					Do
						if (waveexists($w4))
							if (strsearch(w4, rectime, 0) == -1)
								print "\t\t", w4, " does not include ", rectime
								flagNext = 1
							else
								destwave = destname + w4 + "_" + num2str(dindex)
								Duplicate /O /R=(sttime, entime) $w4, $destwave
								Setscale /P x,  offset, deltax($w4), $destwave
							endif
						endif
						windex += 1
						w4 = StringFromList(windex, wave4list)
					While(waveexists($w4))
				endif
//				print "d", dindex, sttime, entime
				dindex += 1
			While (dindex < len_st)
		else
			Do
				flagNext = 0
				if (st[dindex] > en[dindex])
					print "ERROR ::::::::::::::: ON time is after OFF time"
					abort
				else
					sttime = st[dindex] + stoffset*samplerate
					entime = en[dindex] + enoffset*samplerate		
					if (sttime < 0)
						offset = stoffset - sttime/samplerate
					else
						offset = stoffset
					endif
					windex = 0
					w1 = StringFromList(windex, wave1list)
					Do
						if (waveexists($w1))
								destwave = destname + w1 + "_" + num2str(dindex)
								Duplicate /O /R=[sttime, entime] $w1, $destwave
								Setscale /P x, offset, deltax($w1), $destwave
						endif
						windex += 1
						w1 = StringFromList(windex, wave1list)
					While (waveexists($w1))
					windex = 0
					w2 = StringFromList(windex, wave2list)
					Do
						if (waveexists($w2))
								destwave = destname + w2 + "_" + num2str(dindex)
								Duplicate /O /R=[sttime, entime] $w2, $destwave
								Setscale /P x,  offset, deltax($w2), $destwave
						endif
						windex += 1
						w2 = StringFromList(windex, wave2list)
					While (waveexists($w2))
					windex = 0
					w3 = StringFromList(windex, wave3list)
					Do
						if (waveexists($w3))
								destwave = destname + w3 + "_" + num2str(dindex)
								Duplicate /O /R=[sttime, entime] $w3, $destwave
								Setscale /P x,  offset, deltax($w3), $destwave
						endif
						windex += 1
						w3 = StringFromList(windex, wave3list)
					While (waveexists($w3))
					windex = 0
					w4 = StringFromList(windex, wave4list)
					Do
						if (waveexists($w4))
								destwave = destname + w4 + "_" + num2str(dindex)
								Duplicate /O /R=[sttime, entime] $w4, $destwave
								Setscale /P x,  offset, deltax($w4), $destwave
						endif
						windex += 1
						w4 = StringFromList(windex, wave4list)
					While (waveexists($w4))
				endif
//				print "d", dindex, sttime, entime
				dindex += 1
			While (dindex < len_st)
		endif
		sindex+=1
		wst = StringFromList(sindex, stlist)
		wave st = $wst
		wen = StringFromList(sindex, enlist)
	While(waveexists(st))
end




function duplicateWithOffsetWave ([wave1, offsetw, destname, type, textw, wavereg, textreg, correctOffset, sttime, entime])
	String wave1, offsetw, destname, textw, wavereg, textreg
	variable type, correctOffset, sttime, entime
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1 = "Os*"; offsetw="*onset"; destname= "o"; textw="*filename"; wavereg = "Os([0-9]+)_.*"; textreg = ".*_[0-9]+_([0-9]+).wav";
		type=1; sttime=-0.5; entime=1;
		Prompt wave1, "wave1 name" //, popup wavelist ("*",";","")
		Prompt offsetw, "offset wave (reg exp if type==1)" //, popup wavelist ("*",";","")
		Prompt destname, "destwave prefix (if \"\", overwrite)" //, popup wavelist ("*",";","")
		Prompt type, "type 0/1/2/3 (all-all/textw/1-1/wavename)"
		Prompt textw, "text wave (if type==1)" //, popup wavelist ("*",";","")
		Prompt wavereg, "wave1 name reg exp" //, popup wavelist ("*",";","")
		Prompt textreg, "text reg exp" //, popup wavelist ("*",";","")
		Prompt correctOffset, "correct offset? 0/1/2 (no/offset left(x)/-Y)"
		Prompt sttime, "Range from "
		Prompt entime, "to"
		DoPrompt  "duplicateWithOffsetWave", wave1, offsetw, destname, type, textw, wavereg, textreg, correctOffset, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "duplicateWithOffsetWave(wave1=\"" + wave1 + "\", offsetw=\"" + offsetw + "\", destname=\"" + destname + "\", type=" + num2str(type) +  ", textw=\"" + textw +  "\", wavereg=\"" + wavereg + "\", textreg=\"" + textreg + "\", correctOffset=" + num2str(correctOffset) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	string destwave, w1, owlist, tlist, wave1list, rectime, rectime2, owname, twname, tmpstr
	variable windex, tindex, lent, dx, tmpsttime, tmpentime

	wave1list = WaveList(wave1,";","")
	owlist = WaveList(offsetw,";","")
	owname = StringFromList(0, owlist);
	wave ow = $owname

	tindex = 0
	if (type == 0)
		lent = numpnts(ow)
		windex = 0
		w1 = StringFromList(windex, wave1list)	/// split waves
		Do
			tindex = 0
			splitString /E=(wavereg) w1, rectime2
			Do	/// duplicate the original wave (sttime-entime) with offset
				destwave = destname + w1 + "_" + num2str(tindex)
				//	destwave = destname + rectime2 + "_" + num2str(tindex)
				if (correctOffset == 2)
					Duplicate /O $w1, $destwave
					//Duplicate /O /R=(ow[tindex]+sttime, ow[tindex]+entime) $w1, $destwave
					wave dw = $destwave
					dw -= ow[tindex]
				else
						if (sttime < leftx($w1)-ow[tindex])
							tmpsttime = leftx($w1)-ow[tindex]
						else
							tmpsttime = sttime
						endif
						if (entime > rightx($w1)-ow[tindex])
							tmpentime = rightx($w1)-ow[tindex]
						else
							tmpentime = entime
						endif
					if (tmpsttime < tmpentime)
						if (correctOffset == 0)
							Duplicate /O /R=(ow[tindex]+tmpsttime, ow[tindex]+tmpentime) $w1, $destwave
						elseif (correctOffset == 1)
							Duplicate /O /R=(ow[tindex]+tmpsttime+leftx($w1), ow[tindex]+tmpentime+leftx($w1)) $w1, $destwave
						endif
						wave dw = $destwave
						dx = deltax($w1)
						SetScale/P x tmpsttime,dx,"s", dw
					endif
				endif
				tindex += 1
			While (tindex < lent)
			windex += 1
			w1 = StringFromList(windex, wave1list)
		While (waveexists($w1))
	elseif (type == 1)	//  w1 = original wave, tw = textwave, ow = offset
		tlist = WaveList(textw,";","")
		twname = StringFromList(0, tlist);	
		wave /T tw = $twname
		lent = numpnts(tw)
		Do
			splitString /E=(textreg) tw[tindex], rectime

			windex = 0
			w1 = StringFromList(windex, wave1list)
			Do
				splitString /E=(wavereg) w1, rectime2
				if (stringmatch(rectime, rectime2))	// if textwave name matches to original wave names, duplicate and sum offset
					destwave = destname + w1 + "_" + num2str(tindex)
					if (correctOffset == 2)
						Duplicate /O $w1, $destwave
						//Duplicate /O /R=(ow[tindex]+sttime, ow[tindex]+entime) $w1, $destwave
						wave dw = $destwave
						dw -= ow[tindex]
					else
						if (sttime < leftx($w1)-ow[tindex])
							tmpsttime = leftx($w1)-ow[tindex]
						else
							tmpsttime = sttime
						endif
						if (entime > rightx($w1)-ow[tindex])
							tmpentime = rightx($w1)-ow[tindex]
						else
							tmpentime = entime
						endif
						if (tmpsttime < tmpentime)
							if (correctOffset == 0)
								Duplicate /O /R=(ow[tindex]+tmpsttime, ow[tindex]+tmpentime) $w1, $destwave
							elseif (correctOffset == 1)
								Duplicate /O /R=(ow[tindex]+tmpsttime+leftx($w1), ow[tindex]+tmpentime+leftx($w1)) $w1, $destwave
							endif
							wave dw = $destwave
							dx = deltax($w1)
							SetScale/P x tmpsttime,dx,"s", dw
						endif
					endif
				endif
				windex += 1
				w1 = StringFromList(windex, wave1list)
			While (waveexists($w1))
			tindex += 1
		While (tindex < lent)
	elseif (type == 2) // one by one
		windex = 0
		w1 = StringFromList(windex, wave1list)	/// split waves
		Do
			splitString /E=(wavereg) w1, rectime2
			destwave = destname + w1 + "_" + num2str(tindex)
			if (correctOffset == 2)
				Duplicate /O $w1, $destwave
				//Duplicate /O /R=(ow[tindex]+sttime, ow[tindex]+entime) $w1, $destwave
				wave dw = $destwave
				dw -= ow[tindex]
			else
				if (sttime < leftx($w1)-ow[tindex])
					tmpsttime = leftx($w1)-ow[tindex]
				else
					tmpsttime = sttime
				endif
				if (entime > rightx($w1)-ow[tindex])
					tmpentime = rightx($w1)-ow[tindex]
				else
					tmpentime = entime
				endif
				if (tmpsttime < tmpentime)
					if (correctOffset == 0)
						Duplicate /O /R=(ow[tindex]+tmpsttime, ow[tindex]+tmpentime) $w1, $destwave
					elseif (correctOffset == 1)
						Duplicate /O /R=(ow[tindex]+tmpsttime+leftx($w1), ow[tindex]+tmpentime+leftx($w1)) $w1, $destwave
					endif
					wave dw = $destwave
					dx = deltax($w1)
					SetScale/P x tmpsttime,dx,"s", dw
				endif
			endif
			windex += 1
			w1 = StringFromList(windex, wave1list)
		While (waveexists($w1))
	else
		print "Exception"
	endif

end


function duplicateWithOffsetWaveWithText ([wave1, offsetw, destname, type, textw, wavereg, textreg, correctOffset, sttime, entime])
// use this if reg expression is used to sort the offset waves
	String wave1, offsetw, destname, textw, wavereg, textreg
	variable type, correctOffset, sttime, entime
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1 = "amp_*"; offsetw="*Ch*"; destname= "o"; textw=""; wavereg = "amp_.*([0-9]+)_.*"; textreg = "([0-9]+)Ch*";
		type=1; sttime=-0.5; entime=1;
		Prompt wave1, "wave1 name" //, popup wavelist ("*",";","")
		Prompt offsetw, "offset wave" //, popup wavelist ("*",";","")
		Prompt destname, "destwave prefix (if \"\", overwrite)" //, popup wavelist ("*",";","")
		Prompt type, "type (not used)"
		Prompt textw, "text wave (not used)" //, popup wavelist ("*",";","")
		Prompt wavereg, "wave1 name reg exp" //, popup wavelist ("*",";","")
		Prompt textreg, "offset name reg exp" //, popup wavelist ("*",";","")
		Prompt correctOffset, "correct offset? 0/1/2 (no/offset left(x)/-Y)"
		Prompt sttime, "Range from "
		Prompt entime, "to"
		DoPrompt  "duplicateWithOffsetWaveWithText", wave1, offsetw, destname, type, textw, wavereg, textreg, correctOffset, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "duplicateWithOffsetWaveWithText(wave1=\"" + wave1 + "\", offsetw=\"" + offsetw + "\", destname=\"" + destname + "\", type=" + num2str(type) +  ", textw=\"" + textw +  "\", wavereg=\"" + wavereg + "\", textreg=\"" + textreg + "\", correctOffset=" + num2str(correctOffset) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif

	string destwave, w1, owlist, tlist, wave1list, rectime, rectime2, owname, twname, tmpstr, Chname, Chnamereg
	variable windex, tindex, lent, owindex

	wave1list = WaveList(wave1,";","")
	owlist = WaveList(offsetw,";","")
	
	Chnamereg = ".*Ch([0-9]+_[0-9]+).*"

	owindex = 0
	owname = StringFromList(owindex, owlist);
	Do
		wave ow = $owname
		lent = numpnts(ow)
		
		splitString /E=(textreg) owname, rectime
		splitString /E=(Chnamereg) owname, Chname		
		windex = 0
		w1 = StringFromList(windex, wave1list)	/// split waves
		Do
			splitString /E=(wavereg) w1, rectime2
			//print num2str(owindex) + "," + num2str(windex) + ":" + rectime + "?" + rectime2
			if (stringmatch(rectime, rectime2))	// if textwave name matches to original wave names, duplicate and sum offset
				tindex = 0
				Do
					if (numtype(ow[tindex]) == 2)
						tindex += 1
					else
						destwave = destname + w1 + "_Ch" + Chname + num2str(tindex)
						if (correctOffset == 2)
							Duplicate /O $w1, $destwave
							//Duplicate /O /R=(ow[tindex]+sttime, ow[tindex]+entime) $w1, $destwave
							wave dw = $destwave
							dw -= ow[tindex]
						else
							if (sttime == -inf)
								sttime = leftx($w1)-ow[tindex]
							endif
							if (entime == inf)
								entime = rightx($w1)-ow[tindex]
							endif
							if (sttime < entime)
								if (leftx($w1) <= ow[tindex]+sttime && ow[tindex]+entime <= rightx($w1))
									if (correctOffset == 0)
										Duplicate /O /R=(ow[tindex]+sttime, ow[tindex]+entime) $w1, $destwave
									elseif (correctOffset == 1)
										Duplicate /O /R=(ow[tindex]+sttime+leftx($w1), ow[tindex]+entime+leftx($w1)) $w1, $destwave
									endif
									wave dw = $destwave
									SetScale/I x sttime,entime,"s", dw
								endif
							endif
						endif
						tindex += 1
					endif
				While (tindex < lent)
			endif
			windex += 1
			w1 = StringFromList(windex, wave1list)
		While (waveexists($w1))
		owindex += 1
		owname = StringFromList(owindex, owlist);
	While (waveexists($owname))

end



function FFT_Wave ([wave1, destname, sttime, entime, type, dpn, printToCmd])
	String wave1, destname
	Variable sttime, entime, type, printToCmd, dpn
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "FFT_"
		sttime=0; entime=0; type=0; printToCmd=1; dpn=1
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "destwave (Prefix)" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt type, "type 0/1/2 (FFT/FFTmag/IFFT)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		Prompt printToCmd, "Print? 0/1 (No/Yes)"
		DoPrompt  "FFT_Wave", wave1, destname, sttime, entime, type, dpn, printToCmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print "FFT_Wave(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime)  + ", type=" + num2str(type) + ", dpn=" + num2str(dpn) + ", printToCmd=" + num2str(printToCmd) + ")"
	endif
	string lista, a_wave, destwave, tmpwave
	string win = "Hanning"
	tmpwave = "tmpwave"
	variable windex=0, length_a, pnt_a, offset = 0
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	variable pnt, pntstep
	Do
		length_a = deltax($a_wave)*(numpnts($a_wave)-1)
		if (stringmatch(destname, ""))
			destwave = a_wave
		else
			destwave = destname + a_wave
		endif

		if(entime==0)
			entime = length_a
		endif
		if(entime<=sttime)
			abort
		endif

		Duplicate /O /R=(sttime, entime) $a_wave $destwave
		
		if (mod(numpnts($destwave), 2) == 1)
			deletepoints numpnts($destwave)-1, 1, $destwave
		endif 
		if(type ==0)
//			Hanning $destwave
			FFT $destwave
		elseif(type == 1)
			FFT /OUT=3 /DEST=$tmpwave $destwave
			wave d = $destwave
			wave t = $tmpwave
			Killwaves d
			Duplicate /O $tmpwave, $destwave
			Killwaves t			
		elseif(type == 2)
			IFFT $destwave
		endif

		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function convolution([waves, srcWave, sttime, entime, destname, dpn])
	String waves, srcWave, destname
	Variable sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; srcWave = ""
		sttime=0; entime=0; dpn=1;
		Prompt waves, "Wave name"
		Prompt srcWave, "srcWave name"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "convolution", waves, srcWave, sttime, entime, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* convolution(waves=\"" + waves + "\", srcWave=\"" + srcWave + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif

	variable method=0		// different algorithm
	
	Silent 1

	string lista, a_wave, b_wave, destwave
		lista = WaveList(waves,";","")
		destwave = "Con" + destname
	variable windex=0, length, nindex=0, conindex=0, coef=0
	a_wave = StringFromList(windex, lista)
	Do
		destwave = destwave + a_wave + num2str(windex)
		length = (numpnts($a_wave)+numpnts($srcWave)-1)
		Duplicate /O $a_wave $destwave
		if (method == 1)
			b_wave = a_wave + "copy"
			Duplicate /O $srcWave $b_wave
			wave wbWave = $b_wave
		endif
		Redimension /N=(length) $destwave
		wave wDest = $destwave
		wave waWave = $a_wave
		wave wsrcWave = $srcWave
		wDest = 0
		nindex = 0
		Do
			if (method == 0)
				conindex = 0
				Do
					wDest[nindex + conindex] += waWave[nindex] * wsrcWave[conindex]
					conindex += 1
				While(conindex < numpnts($srcWave))
			elseif (method == 1)
				if (nindex < 100)
					Redimension /N=(nindex + 1) wbWave
				endif
				wbWave[] = waWave[nindex-p] * wsrcWave[p]
				coef = sum(wbWave)
				wDest[nindex] = coef
			endif
			nindex += 1
		While(nindex < numpnts($a_wave))

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
		if(dpn==1)
			display $destwave
		endif
		if(dpn==2)
			appendtograph $destwave
		endif
End


function concatenateWaves([waves, destname, sttime, entime])
	String waves, destname
	Variable sttime, entime
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname = "cnct_"
		sttime=0; entime=0;
		Prompt waves, "Wave name"
		Prompt destname, "name of destination wave"
		Prompt sttime,"RANGE from"
		Prompt entime,"to"
		DoPrompt  "concatenateWaves", waves, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print " concatenateWaves(waves=\"" + waves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif
	
	string lista, awave
	variable windex=0, lendestwave
	lista = WaveList(waves,";","")
	Make /O /N=0, $destname
	Concatenate lista, $destname

End


function concatenate2Waves([wave1, wave2, destname, sttime, entime])
	String wave1, wave2, destname
	Variable sttime, entime
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1 = "Os*spike1"; wave2 = "Os*spike2"; destname = "cnct_"
		sttime=0; entime=0;
		Prompt wave1, "Wave1 name"
		Prompt wave2, "Wave2 name"
		Prompt destname, "suffix of destname"
		Prompt sttime,"RANGE from"
		Prompt entime,"to"
		DoPrompt  "concatenate2Waves", wave1, wave2, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print " concatenate2Waves(wave1=\"" + wave1 + "\", wave2=\"" + wave2 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif
	
	string list1, w1, list2, w2, destprefix, destwave
	variable w1index=0, lendestwave, w2index = 0
	list1 = WaveList(wave1,";","")
	list2 = WaveList(wave2,";","")
	w1 = StringFromList(w1index, list1)
	w2 = StringFromList(w2index, list2)
	Do
		destprefix = w1[0,13]
		destwave = destprefix + "_" + destname
		if (stringmatch(w2, destprefix + "*"))
			Make /O /N=0, $destwave
			Concatenate /O {$w1, $w2}, $destwave
			w1index += 1
			w2index += 1
		else
			Duplicate /O $w1, $destwave
			w1index += 1
		endif
		w1 = StringFromList(w1index, list1)
		w2 = StringFromList(w2index, list2)
	While (waveexists($w1))

End


function Rect2Polar([waves, waveImag, sttime, entime, destname, dpn])
	String waves, waveImag, destname
	Variable sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; waveImag = ""; destname="P_"
		sttime=-inf; entime=inf; dpn=1;
		Prompt waves, "Wave name (real wave)"
		Prompt waveImag, "imag wave(needless if cmplx)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "Rect2Polar", waves, waveImag, sttime, entime, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* Rect2Polar(waves=\"" + waves + "\", waveImag=\"" + waveImag + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, listb, b_wave, destwave
	variable windex=0, length=0, isCmplx=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
		isCmplx = WaveType($a_wave) & 0x01
	if (sttime >= entime)
		print "sttime > entime"
		abort
	endif
	if (!isCmplx)
		listb = WaveList(waveImag,";","")
		b_wave = StringFromList(windex, listb)
	endif
	Do
		destwave = destname + a_wave
		if (isCmplx)
			wave /C a = $a_wave
			Duplicate /O /C $a_wave $destwave
			wave /C d = $destwave
			d = r2polar(a)
		else
			wave a2 = $a_wave
			wave b = $b_wave
			length = numpnts(a2)
			Make /C /N=(length) $destwave
			wave /C d = $destwave
			d = r2polar(cmplx(a2, b))
		endif

		if(dpn==1)
			display d
		endif
		if(dpn==2)
			appendtograph d
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
		if (!isCmplx)
			b_wave = StringFromList(windex, listb)
		endif
	While(strlen(a_wave)!=0)
End


function copyrandomWaves([waves, targetname, random, prop, strow, enrow, stcol, encol, bgname, bg])
	String waves, targetname, bgname
	Variable strow, enrow, stcol, encol, prop, random, bg
	if (encol == 0)		// if (row == null) : so there was no input
		waves="I_F_GaussSD10_0_0"; targetname="I_F_GaussSD10"; bgname="Cosine30Hz2mV180"; bg=0;
		strow=16; enrow=23; stcol=16; encol=23; prop=0.5; random=1;
		Prompt waves, "copied wave"
		Prompt targetname, "target prefix(PREFIX_row_col)"
		Prompt random, "0/1(use copied/random)"
		Prompt prop, "proportion for copy (0.0-1.0)"
		Prompt strow, "row from"
		Prompt enrow, "to"
		Prompt stcol, "col from"
		Prompt encol, "to"
		Prompt bgname, "background name"
		Prompt bg, "fill background wave 0/1"
		DoPrompt  "copyrandamWaves", waves, targetname, random, prop, strow, enrow, stcol, encol, bgname, bg
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* copyrandomWaves(waves=\"" + waves + "\", targetname=\"" + targetname + "\",random=" + num2str(random)  + ", prop=" + num2str(prop) + ",strow=" + num2str(strow)  + ",enrow=" + num2str(enrow) + ",stcol=" + num2str(stcol) + ",encol=" + num2str(encol) + ", bgname=\"" + bgname + "\", bg=" + num2str(bg) + ")"
	endif

	wave copied = $waves
	if (bg)
		wave bgwave = $bgname
	endif
	string a_wave, lista, targetwave
	string tempwave="temp", ROIname = "ROIpattern", ROIbgname = "ROIbg"
	variable windex, nindex, ncopy, rowsize, colsize, size, row, col, flag, num
		lista = WaveList(targetname,";","")
		a_wave = StringFromList(windex, lista)
	windex = 0
	rowsize = enrow - strow + 1
	colsize = encol - stcol + 1
	size = rowsize * colsize
	ncopy = round(size * prop)
	if (ncopy > size)
		print "ncopy > size"
		abort
	endif
	if(!random)
		print " . . . copied = ", waves
	endif
	make /O /N=(ncopy) $tempwave
	make /O /b /u /N=(40, 40) $ROIname
	make /O /b /u /N=(40, 40) $ROIbgname
	wave temp = $tempwave
	wave ROI = $ROIname
	wave ROIbg = $ROIbgname
	ROI[][] = 1
	ROIbg[][] = 1
	ROIbg[strow,enrow][stcol,encol] = 0
	print " . . . ncopy = ", num2str(ncopy)
	nindex = 0
	Do
		flag=1
		Do
			row = rowsize
			Do
				row = abs(trunc(enoise(rowsize)))	// max = rowsize-1
			While (row == rowsize)
			col = colsize
			Do
				col = abs(trunc(enoise(rowsize)))
			While (col == colsize)
			num = row*colsize+col+1
			if (nindex!=0)
				windex = 0
				Do
					if (temp[windex] == num)
						flag = 1
						windex = nindex
					else
						flag = 0
					endif
					windex += 1
				While (windex < nindex)
			else
				flag = 0
			endif
		While(flag == 1)
		if (random && nindex ==0)
			waves = targetname + "_" + num2str(row+strow) + "_" + num2str(col+stcol)
			wave copied = $waves
			print " . . . copied = ", waves
		endif
		temp[nindex] = num
		targetwave = targetname + "_" + num2str(row+strow) + "_" + num2str(col+stcol)
		print " . . . [", num2str(nindex), "] : target = ", targetwave
		ROI[row+strow][col+stcol] = 0
		ROIbg[row+strow][col+stcol] = 1
		wave target = $targetwave
		target = copied
		nindex += 1
	While(nindex < ncopy)
	if (bg)
		row = strow
		Do
			col = stcol
			Do
				num = (row-strow)*colsize+(col-stcol)+1
				windex = 0
				flag = 1
				Do
					if (temp[windex] == num)
						flag = 1
						windex = ncopy
					else
						flag = 0
					endif 
					windex += 1
				While (windex < ncopy)
				if (flag == 0)
					targetwave = targetname + "_" + num2str(row) + "_" + num2str(col)
					wave target = $targetwave
					target = bgwave
				endif
				col += 1
			While(col <= encol)
			row += 1
		While(row <= enrow)
	endif

	killwaves temp
end


function makeAPtrain([waves, destname, type, thres, sttime, entime, dpn])
	String waves, destname
	Variable type, thres, sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="AP_"
		sttime=-inf; entime=inf; dpn=1;
		Prompt waves, "Wave name"
		Prompt destname, "SUFFIX of the destwave"
		Prompt type, "0/1: raw/dif"
		Prompt thres, "threshold"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt dpn, "Graph 1/2/3/4 (Show/Append/None)"
		DoPrompt  "makeAPtrain", waves, destname, type, thres, sttime, entime, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* makeAPTrain(waves=\"" + waves + "\", destname=\"" + destname + "\", type =" + num2str(type) + ", thres =" + num2str(thres) +  ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", dpn=" + num2str(dpn) + ")"
	endif

	string lista, a_wave, destwave, difwave
	variable windex=0, index=0, dpnflag=0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	if (sttime >= entime)
		print "sttime > entime"
		abort
	endif
	Do
		destwave = destname + a_wave
		Duplicate /O /R=(sttime, entime) $a_wave $destwave
		wave d = $destwave
		d = 0
		if (type == 1)
			difwave = "dif_" + a_wave
			Duplicate /O /R=(sttime, entime) $a_wave $difwave
			differentiate $difwave
			FindLevels /EDGE=1 /Q /R=(sttime, entime) $difwave, thres
				//edge: 1=increasing, 2=decreasing, 0=both
			print " . . . ", difwave, " : ", V_LevelsFound, " spikes"
		else
			FindLevels /EDGE=1 /Q /R=(sttime, entime) $a_wave, thres
				//edge: 1=increasing, 2=decreasing, 0=both
			print " . . . ", a_wave, " : ", V_LevelsFound, " spikes"
		endif
		wave wLevels = $("W_findLevels")
		index = 0	
		Do
			d[x2pnt(d, wLevels[index])] = 1
			index += 1
		While (index < V_LevelsFound)
		setScale /P y, 0, 1, "",  d

		if(dpn==1)
			display d
		endif
		if(dpn==2)
			appendtograph d
		endif
		if(dpn==4)
			if(!dpnflag)
				display d
				dpnflag = 1
			else
				appendtograph d
			endif
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	killwaves wLevels
End


function compressWave([waves, type, bin, width, sttime, entime, destname, dpn])
	String waves, destname
	Variable type, bin, width, sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="c_"
		sttime=-inf; entime=inf; bin=0.1; width=0; dpn=1;
		Prompt waves, "Wave name"
		Prompt type, "0/1/2: val/sum/mean"
		Prompt bin, "bin (s)"
		Prompt width, "width (s) (if 0: bin)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt destname, "SUFFIX of the destwave"
		Prompt dpn, "Graph 1/2/3/4 (Show/Append/None)"
		DoPrompt  "compressWave", waves, type, bin, width, sttime, entime, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* compressWave(waves=\"" + waves + "\", type=" + num2str(type) + ", bin=" + num2str(bin) + ", width=" + num2str(width)  +  ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif
	///////////////// running average or can be used for PSTH

	string lista, a_wave, destwave, difwave
	variable windex=0, index=0, dpnflag=0, size=0, dsttime = 0
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	if (sttime >= entime)
		print "sttime > entime"
		abort
	endif
	if (width == 0)
		width = bin
	endif
	wave wLevels = $("W_findLevels")
	Do
		destwave = destname + a_wave
		Duplicate /O /R=(sttime, entime) $a_wave $destwave
		wave a = $a_wave
		wave d = $destwave
		size = trunc(numpnts(d) * deltax(d) / bin)
		redimension /N=(size) d
		if (sttime == -inf)
			dsttime = leftx(a) + bin/2
		endif
		setScale /P x, dsttime, bin, "s",  d
		index = 0
		if (type == 0)
			Do
				d[index] = a(index*bin+bin/2+leftx(d))
				index += 1
			While (index < size)
		elseif (type == 1)
			Do
				d[index] = sum(a, index*bin+bin/2+leftx(d)-width/2, index*bin+bin/2+leftx(d)+width/2)
//				print "from", index*bin+bin/2+leftx(d)-width/2, " to ",  index*bin+bin/2+leftx(d)+width/2
				index += 1
			While (index < size)
		elseif (type == 2)
			Do
				d[index] = mean(a, index*bin+bin/2+leftx(d)-width/2, index*bin+bin/2+leftx(d)+width/2)
				index += 1
			While (index < size)
		endif

		if(dpn==1)
			display d
		endif
		if(dpn==2)
			appendtograph d
		endif
		if(dpn==4)
			if(!dpnflag)
				display d
				dpnflag = 1
			else
				appendtograph d
			endif
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End


function expandWave([waves, type, scale, width, sttime, entime, destname, dpn])
	String waves, destname
	Variable type, scale, width, sttime, entime, dpn
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname="p_"
		sttime=-inf; entime=inf; scale=2; width=0.005; dpn=1;
		Prompt waves, "Wave name"
		Prompt type, "0/1: repeat/line"
		Prompt scale, "expand scale"
		Prompt width, "width (s) (if 0: bin)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt destname, "SUFFIX of the destwave"
		Prompt dpn, "Graph 1/2/3 (Show/Append/None)"
		DoPrompt  "expandWave", waves, type, scale, width, sttime, entime, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print " expandWave(waves=\"" + waves + "\", type=" + num2str(type) + ", scale=" + num2str(scale) + ", width=" + num2str(width)  +  ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", destname=\"" + destname + "\", dpn=" + num2str(dpn) + ")"
	endif
	///////////////// running average or can be used for PSTH

	if (sttime >= entime)
		print "sttime > entime"
		abort
	endif
	if (scale <= 1)
		print "scale should be > 1"
		abort
	endif

	string lista, a_wave, destwave, difwave
	variable windex=0, index=0, dpnflag=0, size=0, dsttime = 0, pwidth, pindex, pstep
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	wave wLevels = $("W_findLevels")
	Do
		destwave = destname + a_wave
		Duplicate /O /R=(sttime, entime) $a_wave $destwave
		wave a = $a_wave
		wave d = $destwave
		size = trunc(DimSize(d,0) * scale)
		redimension /N=(size) d
		if (width < deltax(d))
			width = deltax(d)
		endif
		pwidth = trunc(width / deltax(d))
		pstep = trunc(pwidth * (scale-1))
		if ((scale - 1) * pwidth <= 1)
			if (type == 0)
				print "type was set to 1 because pwidth is too small"
			endif
			d[] = a[p/scale]
		else
	 		index = 0
			if (type == 0)
				Do
					pindex = 0
					Do
						//print pindex, index*(pstep+pwidth) + pindex, index*pwidth + pindex
						d[index*(pstep+pwidth) + pindex] = a[index*pwidth + pindex]
						pindex += 1
					While (pindex < pwidth)
					pindex = 0
					Do
//						print pindex, index*(pstep+pwidth) + pwidth + pindex, index*pwidth + pindex/(scale-1)
						d[index*(pstep+pwidth) + pwidth + pindex] = a[index*pwidth + pindex/(scale-1)]
						pindex += 1
					While (pindex < pstep)
					index += 1
				While ((index+2)*pwidth-1 < size)
				d[(index+1)*pwidth,size] = a[p-pwidth]
			elseif (type == 1)
				Do
					pindex = 0
					Do
						d[index*(pstep+pwidth) + pindex] = a[index*pwidth + pindex]
						pindex += 1
					While (pindex < pwidth)
					pindex = 0
					Do
						d[pindex] = (a[(index+1)*pwidth+1] - a[(index+1)*pwidth]) * (pindex+1) / pstep + a[(index+1)*pwidth]
						pindex += 1
					While (pindex < pstep)
					index += 1
				While ((index+2)*pwidth-1 < size)
				d[(index+1)*pwidth,size] = a[p-pwidth]
			endif

			if(dpn==1)
				display d
			endif
			if(dpn==2)
				appendtograph d
			endif
			if(dpn==4)
				if(!dpnflag)
					display d
					dpnflag = 1
				else
					appendtograph d
				endif
			endif
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
End


function makeSpectrogram ([wave1, destname, sttime, entime, width, shift, padwidth, filt, out])
	String wave1, destname
	Variable sttime, entime, width, shift, padwidth, filt, out
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "S_"
		sttime=-inf; entime=inf; width=11.61; padwidth=23.22; filt=1; shift=1
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "dest (Prefix)" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt width, "width (ms)"
		Prompt shift, "shift bin (ms)"
		Prompt padwidth, "pad width (ms)"
		Prompt filt, "win filter 0/1(none/hanning)"
		Prompt out, "save fig? 0/1"
		DoPrompt  "makeSpectrogram", wave1, destname, sttime, entime, width, shift, padwidth, filt, out
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeSpectrogram(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", width=" + num2str(width) + ", shift=" + num2str(shift) + ", padwidth=" + num2str(padwidth) + ", filt=" + num2str(filt) + ", out=" + num2str(out) + ")"
	endif
	width = width/1000
	shift = shift/1000
	padwidth = padwidth/1000
	
	string lista, a_wave, destwave, figname, pathname, adestwave, powerwave, ffwave, beatwave, beatzwave
	variable windex=0, sindex=0, last_a=0, delta_a=0, last_s=0, padpnt
	variable max_freq, min_freq, stwin, enwin, winpnt, shiftpnt, stpnt, enpnt, dpnt, ent, picwidth
	variable padCoef, df, CoefHanningEnergy, CoefHanningPower
	CoefHanningEnergy = 0.501953
	CoefHanningPower = 0.3765
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		last_a = rightx($a_wave)
		delta_a = deltax($a_wave)
		if (stringmatch(destname, ""))
			destwave = a_wave  + "_mag"
			powerwave = a_wave + "_power"
		else
			destwave = destname + a_wave + "_mag"
			powerwave = destname + a_wave + "_power"
		endif
		if(sttime == -inf)
			sttime = leftx($a_wave)
		endif
		if(entime == inf)
			ent = last_a
		else
			if (entime != ent)
				ent = last_a
			endif
		endif
		if(ent<=sttime)
			abort
		endif
		stpnt = x2pnt($a_wave, sttime)
		enpnt = x2pnt($a_wave, ent)
		max_freq = 1/delta_a
		min_freq = 1/width
		winpnt = trunc(width / delta_a)
		padpnt = trunc(padwidth / delta_a)
		padCoef = padwidth/width
		shiftpnt = trunc(shift / delta_a)
		if (mod(winpnt+1, 2) != 0)
			winpnt += 1
		endif
		if (mod(padpnt+1, 2) != 0)
			padpnt += 1
		endif
		print "width: ", width, "[s] (", (winpnt+1) , "pnts); padwidth: ", padwidth, "[s] (", (padpnt-1) , "pnts)"
		if (padCoef > 1)
			make /O /N=((enpnt - stpnt - winpnt)/shiftpnt+1, (max_freq / 2 / min_freq * padCoef + 1) ) $destwave
			duplicate /O $destwave, $powerwave
		else
			make /O /N=((enpnt - stpnt - winpnt)/shiftpnt+1, (max_freq / 2 / min_freq + 1) ) $destwave
			duplicate /O $destwave, $powerwave
		endif
		adestwave = "amp_" + destwave
		ffwave = "ff_" + destwave
		beatwave = "beat_" + destwave
		beatzwave = "beatz_" + destwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $adestwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $ffwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $beatwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $beatzwave
		wave d = $destwave
		wave ad = $adestwave
		wave pd = $powerwave
		wave ff = $ffwave
		wave beat = $beatwave
		wave beatz = $beatzwave
		d = 0
		pd = 0
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  d
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  pd
		if (padCoef > 1)
			df = min_freq/padCoef
			SetScale/P y, 0, df, "Hz",  d
			SetScale/P y, 0, df, "Hz",  pd
		else
			df = min_freq
			SetScale/P y, 0, df, "Hz",  d
			SetScale/P y, 0, df, "Hz",  pd
		endif
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  ad
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  ff
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  beat
		SetScale/P x, sttime+width/2, shiftpnt*delta_a, "s",  beatz
		sindex=0
		stwin = stpnt + sindex * shiftpnt
		enwin = stwin + winpnt
		dpnt = width/shift
		Do
			Duplicate /R=[stwin, enwin] /O $a_wave, winforspectr
			if (filt == 1)
				Hanning winforspectr
			endif
			if (padCoef > 1)
//				InsertPoints winpnt+1, winpnt-1, winforspectr // I think this is wrong way because of the output of Hanning(windorspectr)
				InsertPoints winpnt+1, (padpnt-winpnt)/2-1, winforspectr
				InsertPoints 0, (padpnt-winpnt)/2-1, winforspectr
			endif
//			FFT /OUT=3 /DEST=dest_makeSpectrum winforspectr
			FFT /OUT=3 /DEST=dest_makeSpectrum winforspectr			
//			FFT /OUT=3 /DEST=dest_makeSpectrum /WINF=Hanning winforspectr

//			pd[sindex][] = dest_makeSpectrum[q]^2 / winpnt * 2
			Duplicate /O dest_makeSpectrum, dest_makeSpectrum_power
			dest_makeSpectrum_power = dest_makeSpectrum ^2 / winpnt * 2
			if (filt == 1)
				dest_makeSpectrum_power /= CoefHanningPower
			endif
			pd[sindex][] = dest_makeSpectrum_power[q] // [V^2/Hz] this result (/wo Hanning) is pretty similar to the result of MATLAB
			pd[sindex][0] /= 2 

//			FFT /RP=[stwin, enwin] /OUT=3 /DEST=dest_makeSpectrum /WINF=Hanning $a_wave
//			d[sindex, sindex+dpnt][] += dest_makeSpectrum[q] //(old algorithm)
			dest_makeSpectrum /= winpnt / 2 // transform to single-sided spectrum
			dest_makeSpectrum[0] /= 2	// 0Hz should not be multiplied by 2
			if (filt == 1)
				dest_makeSpectrum /= CoefHanningEnergy
			endif
			d[sindex][] = dest_makeSpectrum[q] // [V]
			ad[sindex] = log(sum(dest_makeSpectrum_power, 400, 10000))/log(10) * 10 // dB (subtract baseline to calculate relative intensity)
			wavestats /Q /R=(0,1/width*100) dest_makeSpectrum
			beat[sindex] = V_maxloc
			beatz[sindex] = V_max
			Duplicate /O /R=(0,1/width*20) dest_makeSpectrum, tmpautocorrel
			//correlate /AUTO tmpautocorrel, tmpautocorrel
			FindPeak /R=(1/width,1/width*20) /M=(V_max/20) /Q tmpautocorrel
			if (V_flag)
				ff[sindex] = 0
			else
				ff[sindex] = V_PeakLoc
			endif
			sindex+=1
			stwin = stpnt + sindex * shiftpnt
			enwin = stwin + winpnt
		While (enwin < enpnt)

//		d /= (dpnt+1) //(old algorithm)
	
		if (out)
			figname = "spectrogram" + num2str(windex)
			NewImage /N=$figname d
			SetAxis /W=$figname /R left 0,15000
			ModifyImage /W=$figname $destwave ctab={0,50000,Grays,0}
			if ((ent-sttime) > 7)
				picwidth = 14
			else
				picwidth = (ent-sttime) * 2
			endif
			savePICT /O /E=-7 /B=288 /I /W=(0,0, picwidth,1.5) /P=home /N=$figname as (a_wave+".tif")
			Killwindow $figname
		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
//	killwaves dest_makeSpectrum


end


function makeSlidingCorrel ([wave1, destname, sttime, entime, width, shift, padwidth, filt, out])
	String wave1, destname
	Variable sttime, entime, width, shift, padwidth, filt, out
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "S_"
		sttime=-inf; entime=inf; width=11.61; padwidth=23.22; filt=1; shift=1
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "dest (Prefix)" //, popup wavelist ("*",";","")
		Prompt sttime, "Range from (s)"
		Prompt entime, "to (s)"
		Prompt width, "width (ms)"
		Prompt shift, "shift bin (ms)"
		Prompt padwidth, "pad width (ms)"
		Prompt filt, "win filter 0/1(none/hanning)"
		Prompt out, "save fig? 0/1"
		DoPrompt  "makeSlidingCorrel", wave1, destname, sttime, entime, width, shift, padwidth, filt, out
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeSlidingCorrel(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", width=" + num2str(width) + ", shift=" + num2str(shift) + ", padwidth=" + num2str(padwidth) + ", filt=" + num2str(filt) + ", out=" + num2str(out) + ")"
	endif
	width = width/1000
	shift = shift/1000
	padwidth = padwidth/1000
	
	string lista, a_wave, destwave, figname, pathname, adestwave, ffwave, beatwave, tmpa, tmpdestname
	variable windex=0, sindex=0, last_a=0, delta_a=0, last_s=0, padpnt
	variable max_freq, min_freq, stwin, enwin, winpnt, shiftpnt, stpnt, enpnt, dpnt, ent, picwidth
	variable padCoef, df, CoefHanningEnergy, CoefHanningPower
	tmpa = "wave_tmpa"
	CoefHanningEnergy = 0.501953
	CoefHanningPower = 0.3765
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	Do
		last_a = rightx($a_wave)
		delta_a = deltax($a_wave)
		if (stringmatch(destname, ""))
			destwave = a_wave  + "_sl"
		else
			destwave = destname + a_wave + "_sl"
		endif
		if(sttime == -inf)
			sttime = leftx($a_wave)
		endif
		if(entime == inf)
			ent = last_a
		else
			if (entime != ent)
				ent = last_a
			endif
		endif
		if(ent<=sttime)
			abort
		endif
		stpnt = x2pnt($a_wave, sttime)
		enpnt = x2pnt($a_wave, ent)
		max_freq = 1/delta_a
		min_freq = 1/width
		winpnt = trunc(width / deltax($a_wave))
		padpnt = trunc(padwidth / deltax($a_wave))
		padCoef = padwidth/width
		shiftpnt = trunc(shift / deltax($a_wave))
		if (mod(winpnt+1, 2) != 0)
			winpnt += 1
		endif
		if (mod(padpnt+1, 2) != 0)
			padpnt += 1
		endif
		print "width: ", width, "[s] (", (winpnt+1) , "pnts); padwidth: ", padwidth, "[s] (", (padpnt-1) , "pnts)"

		if (padCoef > 1)
			make /O /N=((enpnt - stpnt - winpnt)/shiftpnt+1, (width/0.001) ) $destwave
		else
			make /O /N=((enpnt - stpnt - winpnt)/shiftpnt+1, (width/0.001) ) $destwave
		endif
		ffwave = "beatz_" + destwave
		beatwave = "beat_" + destwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $ffwave
		make /O /N=((enpnt - stpnt - winpnt)/shiftpnt) $beatwave
		wave ff = $ffwave
		wave beat = $beatwave

		wave d = $destwave
		d = 0
		SetScale/P x, sttime+width/2, shift, "s",  d
		SetScale/P x, sttime+width/2, shift, "s",  ff
		SetScale/P x, sttime+width/2, shift, "s",  beat
		SetScale/P y, 0, 0.001, "s",  d
		sindex=0
		stwin = stpnt + sindex * shiftpnt
		enwin = stwin + winpnt
		dpnt = width/shift
		Do
			Duplicate /R=[stwin, enwin] /O $a_wave, $tmpa
			discretizeWave(wave1=tmpa, destname="d", sttime=-inf, entime=inf, step=1, type=0, dpn=3, printToCmd=0)
			wave wtmpa = $("d" + tmpa)
			Correlate /AUTO wtmpa, wtmpa
			discretizeWave(wave1=("d" + tmpa), destname="d", sttime=-inf, entime=inf, step=1, type=0, dpn=3, printToCmd=0)
			wave wdtmpa = $("dd" +tmpa)
			d[sindex][] = wdtmpa[q + x2pnt(wdtmpa,0)] // [V]
			wavestats /Q /R=(0.04,width) wdtmpa
			beat[sindex] = V_maxloc
			ff[sindex] = V_max
			//FindPeak /R=(0.04, shift*50) /M=(V_max/20) /Q wdtmpa
			
			sindex+=1
			stwin = stpnt + sindex * shiftpnt
			enwin = stwin + winpnt
		While (enwin < enpnt)
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
//	killwaves dest_makeSpectrum


end

function histogramWaves ([wave1, destname, sttime, entime, binst, binen, width, binstep, binfilt, type])
	String wave1, destname
	Variable sttime, entime, binst, binen, width, binstep, binfilt, type
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1=""; destname= "h_"
		sttime=-inf; entime=inf; width=20e-3; binst=-inf; binen=inf; binstep=1e-3; binfilt = 20e-3; type=0
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		Prompt destname, "dest (Prefix)" //, popup wavelist ("*",";","")
		Prompt sttime, "X range from"
		Prompt entime, "to"
		Prompt binst, "bin from (barX)"
		Prompt binen, "bin to"
		Prompt width, "bin width"
		Prompt binstep, "bin step"
		Prompt binfilt, "filter width (not working)"
		Prompt type, "0/1 (linear/log)"
		DoPrompt  "histogramWaves", wave1, destname, sttime, entime, binst, binen, width, binstep, binfilt, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "histogramWaves(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", binst=" + num2str(binst) + ", binen=" + num2str(binen) + ", width=" + num2str(width) + ", binstep=" + num2str(binstep)  + ", binfilt=" + num2str(binfilt)  + ", type=" + num2str(type)  + ")"
	endif
	
	string lista, a_wave, destwave, tmpwave, xdestwave
	variable windex=0, first_a, last_a, delta_a, stt, ent, bst, ben, Nbin, Nratio, stbin, enbin, binratio, xbin, ii

	if ((type ==1) && (binst != -inf) && (binst <= 0))
		print " stop because binst was <=0" 
		abort
	endif
	
	lista = WaveList(wave1,";","")
	a_wave = StringFromList(windex, lista)
	Do
		first_a = leftx($a_wave)
		last_a = rightx($a_wave)
		delta_a = deltax($a_wave)
		if (stringmatch(destname, ""))
			destwave = a_wave
		else
			destwave = destname + a_wave
		endif
		wave a = $a_wave
		
		if(sttime == -inf)
			stt = first_a
		else
			stt = sttime
		endif
		if(entime == inf)
			ent = last_a
		else
			ent = entime
		endif
		if(ent<stt)
			abort
		endif

		wavestats /Q /R=(stt, ent) $a_wave
		if (width <= 0)
			width = V_sdev / 30
		endif

		if (type == 0)
			if(binst == -inf)
				bst = V_min - width/2
			else
				bst = binst
			endif
			if(binen == inf)
				ben = V_max + width/2
			else
				ben = binen
			endif
			if (bst > ben)
				print "bst < ben"
				abort
			endif
			if (binstep > 0)
				Nbin = floor((ben-bst-width)/binstep + 1)
				Make /O /N=(Nbin) $destwave
				wave wdest = $destwave
				tmpwave = "tmpwave"
				Duplicate /O $a_wave, $tmpwave
				wave wtmp = $tmpwave
				for (ii=0; ii<Nbin; ii+=1)
					stbin = bst + ii * binstep
					enbin = stbin + width
					wtmp = (stbin <= a[p]) && (a[p] < enbin)
					wdest[ii] = sum(wtmp)
				endfor
				killwaves wtmp
				setscale /P x, bst, binstep, wdest
			else
				Nbin = floor((ben-bst)/width)
				Make /O /N=(Nbin) $destwave
				histogram /B={bst, width, Nbin} /R=(stt, ent) $a_wave, $destwave
			endif
		else	 /// log plot
			if (V_min <= 0)
				print " skip " + a_wave + " because min was <=0" 
				continue
			endif

			Nbin = floor((V_max-V_min)/width)
			Nratio = V_max / V_min
			binratio = Nratio ^(1/Nbin)
			if(binst == -inf)
				bst = V_min
			else
				bst = binst
			endif
			if(binen == inf)
				ben = V_max
			else
				ben = binen
			endif
			if (bst > ben)
				print "bst < ben"
				abort
			endif
			Nbin = floor((ben-bst)/width) 
			Nratio = ben / bst
			binratio = Nratio ^(1/(Nbin-1))

			Make /O /N=(Nbin) $destwave
			wave wdest = $destwave
			tmpwave = "tmpwave"
			Duplicate /O $a_wave, $tmpwave
			wave wtmp = $tmpwave
			xdestwave = "x" + destwave
			Duplicate /O $destwave, $xdestwave
			wave xdest = $xdestwave
			for (ii=0; ii<Nbin; ii+=1)
				xbin = bst * (binratio^ii)
				stbin = xbin
				enbin = xbin * binratio
				wtmp = (stbin <= a[p]) && (a[p] < enbin)
				wdest[ii] = sum(wtmp)
				xdest[ii] = xbin
			endfor
			killwaves wtmp
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


function sortWave([waves, destname, sttime, entime, type])
	String waves, destname
	Variable sttime, entime, type
	if (numType(strlen(waves)) == 2)		// if (wave == null) : so there was no input
		waves = "*"; destname = "s_"
		sttime=0; entime=0;
		Prompt waves, "Wave name"
		Prompt destname, "name of destination wave"
		Prompt sttime,"RANGE from"
		Prompt entime,"to"
		Prompt type,"0/1(des/asc)"
		DoPrompt  "sortWave", waves, destname, sttime, entime, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print " sortWave(waves=\"" + waves + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", type=" + num2str(type)+ ")"
	endif
	
	string lista, awave, destwave
	variable windex=0, lendestwave
	lista = WaveList(waves,";","")
	awave = StringFromList(windex, lista)
	Do
		if (stringmatch(destname, ""))
			wave d = $awave
		else
			destwave = destname + awave
			Duplicate /O $awave, $destwave
			wave d = $destwave
		endif
		if (type == 0)
			sort d, d
		else
			sort /R d, d
		endif
		
		windex += 1
		awave = StringFromList(windex, lista)
	While (waveexists($awave))

End
