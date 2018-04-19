#pragma rtGlobals=1		// Use modern global access method.

menu "tanakaMusic"
	submenu "general"
		"playPartOfSound"
		"makeSineMusic"
	end
	submenu "rhythm"
		"drawRhythmDiagram" // drawing
		"makeRhythmWave" // make beat wave with sine correlation
		"makeCorrRhythmMatrix" // correlation matrix
		"analyzeRhythmMatrix"
		"analyzeBeatAndRhythm" // ?
		"analyzeCorrBetweenBeats" // correlation matrix with beat peaks
	end
	submenu "shamisen"
		"VectorFromDim"
		"tuboToTone"
		"toneToMuse"
		"toneToText"
		"textHistogram"
		"makeToneDifferenceWave"
		"extractPhrases"
		"showResponses"
		"deleteSameTones"
		"deleteGraces"
		"deleteRests"
		"killPlateauWaves"
		"killSameWaves"
	end
end

function VectorFromDim ([wave1, destname, method])
	String wave1, destname
	Variable method
	String funcname = "VectorFromDim"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "shami*"; destname = funcname + "_"; method = 0
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt destname, "dest name"
		Prompt method, "method (max/shami)"
		DoPrompt "VectorFromDim", wave1, destname,method
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", destname=\"" + destname + "\",method=" + num2str(method) +  ")" 
	endif

	string lista , a_name, targetname
	variable windex=0, nindex=0, length
		lista = WaveList(wave1,";","")
		a_name = StringFromList(windex, lista)
	Do
		wave a_wave = $a_name
		targetname = destname + a_name + "_" + num2str(windex)
		length = DimSize(a_wave, 0)
		if (method == 0)
			make /O /N=(length) $targetname
		endif
		wave destwave = $(targetname)
		nindex = 0
		Do
			if (method == 0)
				destwave[nindex] = max( max(a_wave[nindex][0], a_wave[nindex][1]), a_wave[nindex][2])
			endif
			nindex += 1
		while(nindex < length)
		windex+=1
		a_name = StringFromList(windex, lista)
	While(strlen(a_name)!=0)
end function


function tuboToTone ([wave1, wave2, destname])
	String wave1, wave2, destname
	String funcname = "tuboToTone"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "shami_tubo"; wave2 = "shami_tune"; destname = "shami_tone"
		Prompt wave1, "tubo Wave" //, popup wavelist ("*",";","")
		Prompt wave2, "tyogen Wave" //, popup wavelist ("*",";","")
		Prompt destname, "dest name"
		DoPrompt "tuboToTone", wave1, wave2, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", wave2=\"" + wave2  + "\", destname=\"" + destname + "\")" 
	endif

	string lista , a_name, targetname
	variable windex=0, nindex=0, length
		lista = WaveList(wave1,";","")
		a_name = StringFromList(windex, lista)
	variable tubo, pochi
	variable tone, ntone, maxTone=0
	make /N=3 temptones
	Do
		wave a_wave = $a_name
		if (windex == 0)
			targetname = destname
		else
			targetname = destname + "_" + num2str(windex)
		endif
		length = DimSize(a_wave, 0)
		make /O /N=(length,3) $targetname
		wave targetwave = $targetname
		wave tune = $wave2
		targetwave = NaN
		nindex = 0
		Do
			ntone = 0
			temptones = 0
			variable i
			for (i=0; i<3; i+=1)
				if (a_wave[nindex][i] != 0)
					ntone += 1
				else
					continue
				endif
				if (a_wave[nindex][i] == -1)
					temptones[i] = -1
				else
					tubo = mod(a_wave[nindex][i], 10)
					pochi = trunc(a_wave[nindex][i] / 10)
					if (tubo <= 0)
						tone = pochi * 12 - 1
					elseif (tubo <= 4)
						tone = pochi * 12 + trunc(tubo) - 1
					elseif (tubo <= 8)
						tone = pochi * 12 + trunc(tubo)
					else
						tone = pochi * 12 + trunc(tubo) + 1
					endif
					temptones[i] = tune[i] + tone
				endif
			endfor
			Sort  temptones, temptones
			targetwave[nindex][0] = temptones[0]
			targetwave[nindex][1] = temptones[1]
			targetwave[nindex][2] = temptones[2]
			if (maxTone < ntone)
				maxTone = ntone
			endif
			nindex += 1
		while(nindex < length)
		windex+=1
		a_name = StringFromList(windex, lista)
	While(strlen(a_name)!=0)
	killWaves temptones

end function


function toneToMuse ([waveTone, waveRhythm, destname])
	String waveTone, waveRhythm, destname
	String funcname = "toneToMuse"
	if (numType(strlen(waveTone)) == 2)	// if (wave1 == null) : so there was no input
		waveTone = "shami_tone"; waveRhythm = "shami_rhythm"
		Prompt waveTone, "Wave tone" //, popup wavelist ("*",";","")
		Prompt waveRhythm, "Wave rhythm"
		Prompt destname, "dest name"
		DoPrompt "toneToMuse", waveTone, waveRhythm, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(waveTone=\"" + waveTone + "\", waveRhythm=\"" + waveRhythm + "\", destname=\"" + destname + "\")" 
	endif

	string list_t, list_r, name_t, name_r
	variable windex=0, nindex=0, length_t, col_t, tone, rhythm, rhythm_mod
		list_t = WaveList(waveTone,";","")
		list_r = WaveList(waveRhythm,";","")
		name_t = StringFromList(windex, list_t)
		name_r = StringFromList(windex, list_r)
	String museLine, museTone, museRhythm, museOct, targetname
	Do
		museLine = "";	museTone = "";	museRhythm = ""; museOct = ""
		wave wave_t = $name_t
		wave wave_r = $name_r
		length_t = DimSize(wave_t, 0)
		col_t = DimSize(wave_t, 1)
		targetname = destname + "Muse_" + num2str(windex)
		make /O /T /N=(length_t) $targetname
		wave /T destwave = $targetname
		nindex = 0
		Do
			museLine = "["
			variable i, j
			if (col_t == 0)
				col_t = 1
			endif
			for (i=0; i<col_t; i+=1)
				museRhythm = ""
				tone = wave_t[nindex][i]
				rhythm = wave_r[nindex][i]		// even if wave_r is a vector, no error is called
				museOct = "o" + num2str(trunc(tone/12)+3)
				if (rhythm < 0.125)			// cannot work if == 0.01 (???)
					museRhythm = "^64"
				else
					if( mod(rhythm,0.25) == 0.125)		// 1/64
						museRhythm = "^64" + museRhythm
						rhythm -= 0.125
					endif
					if( mod(rhythm,0.5) == 0.25)		// 1/32
						museRhythm = "^32" + museRhythm
						rhythm -= 0.25
					endif
					if( mod(rhythm,1) == 0.5)			// 1/16
						museRhythm = "^16" + museRhythm
						rhythm -= 0.5
					endif
					if( mod(rhythm, 2) == 1)			// 1/8
						museRhythm = "^8" + museRhythm
						rhythm -= 1
					endif
					if( mod(rhythm, 4) == 2)			// 1/4
						museRhythm = "^4" + museRhythm
						rhythm -= 2
					endif
					if( mod(rhythm, 8) == 4)			// 1/2
						museRhythm = "^2" + museRhythm
						rhythm -= 4
					endif
					if( mod(rhythm, 8) == 0)			// 1/1
						for (j=0; j<(rhythm / 8); j+=1)
							museRhythm = "^1" + museRhythm
						endfor
					else
						print " * (ERROR) rhythm = ", rhythm
					endif
				endif
				museRhythm = museRhythm[1, strlen(museRhythm) - 1]
				for (j=0; j < trunc((tone - 100) / 12); j+=1)
					museLine = museLine + "<"
				endfor
				if ( tone < 1 )
					museTone = "_"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 0 )
					museTone = "r"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 1 )
					museTone = "m-"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 2 )
					museTone = "m"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 3 )
					museTone = "f"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 4 )
					museTone = "s-"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 5 )
					museTone = "s"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 6 )
					museTone = "l-"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 7 )
					museTone = "l"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 8 )
					museTone = "c-"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 9 )
					museTone = "c"
					museLine = museLine + museTone + museRhythm + " "
				elseif ( mod((tone - 100), 12) == 10 )
					museTone = "<d"
					museLine = museLine + museTone + museRhythm + "> "
				elseif ( mod((tone - 100), 12) == 11 )
					museTone = "<r-"
					museLine = museLine + museTone + museRhythm + "> "
				endif
				for (j=0; j < trunc((tone - 100) / 12); j+=1)
					museLine = museLine + ">"
				endfor
			endfor
			museLine = museLine + "]" + museRhythm 
			destwave[nindex] = museLine
			nindex += 1
		while(nindex < length_t)
		windex+=1
		name_t = StringFromList(windex, list_t)
		name_r = StringFromList(windex, list_r)
	While(strlen(name_t)!=0)
end function

function toneToText ([waveTone, destname])
	String waveTone, destname
	String funcname = "toneToText"
	if (numType(strlen(waveTone)) == 2)	// if (wave1 == null) : so there was no input
		waveTone = "shami_tone"
		Prompt waveTone, "Wave tone" //, popup wavelist ("*",";","")
		Prompt destname, "dest name"
		DoPrompt "toneToText", waveTone, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(waveTone=\"" + waveTone + "\", destname=\"" + destname + "\")" 
	endif

	string list_t, name_t
	variable windex=0, nindex=0, length_t, col_t, tone
		list_t = WaveList(waveTone,";","")
		name_t = StringFromList(windex, list_t)
	String textLine, textTone, targetname
	Do
		textLine = "";	textTone = ""
		wave wave_t = $name_t
		length_t = DimSize(wave_t, 0)
		col_t = DimSize(wave_t, 1)
		targetname = destname + "Text_" + num2str(windex)
		make /O /T /N=(length_t) $targetname
		wave /T destwave = $targetname
		nindex = 0
		Do
			textLine = ""
			textTone = ""
			variable i, j
			if (col_t == 0)
				col_t = 1
			endif
			for (i=0; i<col_t; i+=1)
				tone = wave_t[nindex][i]
				if ( tone < 1 )
					textTone = ""
					continue
				elseif ( mod((tone - 100), 12) == 0 )
					textTone = "ˆë‰z"
				elseif ( mod((tone - 100), 12) == 1 )
					textTone = "’f‹à"
				elseif ( mod((tone - 100), 12) == 2 )
					textTone = "•½’²"
				elseif ( mod((tone - 100), 12) == 3 )
					textTone = "Ÿâ"
				elseif ( mod((tone - 100), 12) == 4 )
					textTone = "‰º–³"
				elseif ( mod((tone - 100), 12) == 5 )
					textTone = "‘o’²"
				elseif ( mod((tone - 100), 12) == 6 )
					textTone = "éèà"
				elseif ( mod((tone - 100), 12) == 7 )
					textTone = "‰©à"
				elseif ( mod((tone - 100), 12) == 8 )
					textTone = "êa‹¾"
				elseif ( mod((tone - 100), 12) == 9 )
					textTone = "”ÕÂ"
				elseif ( mod((tone - 100), 12) == 10 )
					textTone = "_å"
				elseif ( mod((tone - 100), 12) == 11 )
					textTone = "ã–³"
				endif
				textLine = textLine + ";" +  textTone
			endfor
			textLine = textLine[1, strlen(textLine)-1] 
			destwave[nindex] = textLine
			nindex += 1
		while(nindex < length_t)
		windex+=1
		name_t = StringFromList(windex, list_t)
	While(strlen(name_t)!=0)
end function

function textHistogram ([wave1, destname])
	String wave1, destname
	String funcname = "textHistogram"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "shami_tone_text"
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt destname, "dest name"
		DoPrompt "textHistogram", wave1, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", destname=\"" + destname + "\")" 
	endif

	string lista, name_a, targetname, str, key
	string keylist = "ˆë‰z;’f‹à;•½’²;Ÿâ;‰º–³;‘o’²;éèà;‰©à;êa‹¾;”ÕÂ;_å;ã–³"
	variable windex=0, nindex=0, length_a, freq, sumfreq, nkey
	nkey = ItemsInList(keylist)
	lista = WaveList(wave1,";","")
	name_a = StringFromList(windex, lista)
	Do
		wave wave_a = $name_a
		length_a = DimSize(wave_a, 0)
		targetname = destname + "Histo_" + num2str(windex)
		make /O /T /N=(nkey) $(targetname + "_l")
		wave /T labelwave = $(targetname + "_l")
		make /O /N=(nkey) $(targetname)
		wave histowave = $targetname
		sumfreq = 0
		nindex = 0
		key = StringFromList(nindex, keylist)
		Do
			labelwave[nindex] = key
			freq = textFrequency(wave1=wave1, key=key, type=0)
			histowave[nindex] = freq
			sumfreq += freq
			nindex += 1
			key = StringFromList(nindex, keylist)
		while(strlen(key)!=0)
		Duplicate /O histowave, $(targetname + "r")
		wave ratiowave = $(targetname + "r")
		ratiowave = ratiowave / sumfreq
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
end function


function textFrequency ([wave1, key, type])
	String wave1, key
	Variable type
	String funcname = "textFrequency"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "shami_tone_text"
		type = 0
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt key, "keyword"
		Prompt type, "type 0/1 : complete/part"	// does not work
		DoPrompt "textFrequency", wave1, key, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", key=\"" + key + "\", type=" + num2str(type) + ")" 
	endif

	string lista, name_a, listStr
	variable windex=0, nindex=0, length_a, col_a, freq
		lista = WaveList(wave1,";","")
		name_a = StringFromList(windex, lista)
	Do
		wave /T wave_a = $name_a
		length_a = DimSize(wave_a, 0)
		col_a = DimSize(wave_a, 1)
		nindex = 0
		freq = 0
		Do
			variable i
			if(col_a == 0)
				col_a = 1
			endif
			for (i=0; i<col_a; i+=1)
				listStr = wave_a[nindex][i]
				if (strsearch(key, listStr, 0) == -1)
					continue
				else
					freq += 1
				endif
			endfor
			nindex += 1
		while(nindex < length_a)
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
	return freq
end function


function makeToneDifferenceWave ([wave1, wave_nRepeats])
	String wave1, wave_nRepeats
	String funcname = "makeToneDifferenceWave"
	if (numType(strlen(wave1)) == 2)
		wave1 = "phrase*"
		wave_nRepeats = "nRepeats"
		Prompt wave1, "wave name"
		Prompt wave_nRepeats, "wave nRepeats"
		DoPrompt funcname, wave1, wave_nRepeats
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", wave_nRepeats=\"" + wave_nRepeats + "\")" 
	endif

	string lista, name_a
	variable windex, rindex, cindex
	variable n_a, row_a, col_a, dif
	Duplicate /O $wave_nRepeats, toneDifferences
	lista = WaveList(wave1,";","")
	toneDifferences = 0
	windex=0
	name_a = StringFromList(windex, lista)
	n_a = ItemsInList(lista)
	Do
		if (waveExists($name_a))
			wave wave_a = $name_a
			row_a = DimSize(wave_a,0)
			col_a = DimSize(wave_a,1)
		endif
		dif = 0
		rindex = 0
		Do
			cindex = 0
			Do
				if (wave_a[rindex][cindex] != 0 && wave_a[rindex+1][cindex] != 0)
					dif = wave_a[rindex+1][cindex] - wave_a[rindex][cindex] 
				endif
				cindex += 1
			while(cindex < col_a)
			rindex += 1
		while(rindex < (row_a-1))
		toneDifferences[windex] = dif		
		windex+=1
		name_a = StringFromList(windex, lista)
	While(windex < n_a)
end function

function extractPhrases ([wave1, maxlen, sttime, entime])
	String wave1
	Variable maxlen, sttime, entime
	String funcname = "extractPhrases"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "shami_tone"
		maxlen = 50; sttime = 0; entime = 0
		Prompt wave1, "Wave name" //, popup wavelist ("*",";","")
		Prompt maxlen, "max length of phrases"
		Prompt sttime, "from "
		Prompt entime, "to"
		DoPrompt "extractPhrases", wave1, maxlen, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=\"" + wave1 + "\", maxlen=" + num2str(maxlen) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")" 
	endif

	string lista, name_a, targetFolder, targetwave
	variable windex, nindex, length_a, col_a, length_ph, last_ph_onset
	lista = WaveList(wave1,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	Do
		wave wave_a = $name_a
		if (sttime==0 && entime==0)
			sttime = DimOffset(wave_a, 0)
			entime = DimSize(wave_a, 0)
		endif
		if (sttime >= entime)
			abort
		endif
		length_a = DimSize(wave_a, 0)
		col_a = DimSize(wave_a, 1)
		length_ph = 2
		Do
			last_ph_onset = length_a - length_ph + 1
			targetFolder = "phrase" + num2str(length_ph)
			newDataFolder /O $targetFolder
			nindex = 0
			Do
				targetwave = "phrase" + num2str(length_ph) + "_" + num2str(nindex)
				Duplicate /O /R=[nindex, (nindex+length_ph-1)] wave_a, $targetwave			
				moveWave $targetwave, $(":" + targetFolder + ":")
				nindex += 1
			while(nindex < last_ph_onset)
			length_ph += 1
		while (length_ph <= maxlen)
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
end function


function showResponses ([name_rhythm, name_tubo, name_rendition, name_t, threshold, maxlen])
	String name_rhythm, name_tubo, name_rendition, name_t
	Variable threshold, maxlen
	String funcname = "showResponses"
	if (numType(strlen(name_rhythm)) == 2)	// if (wave1 == null) : so there was no input
		name_tubo = "shami_tubo"; name_rhythm = "shami_rhythm"; name_rendition = "shami_rendition"; name_t = "shami_t"
		threshold = 3; maxlen = 8
		Prompt name_rhythm, "Wave rhythm", popup wavelist ("*",";","")
		Prompt name_tubo, "Wave tubo", popup wavelist ("*",";","")
		Prompt name_rendition, "Wave rendition", popup wavelist ("*",";","")
		Prompt name_t, "Wave time", popup wavelist ("*",";","")
		Prompt threshold, "detection threshold"
		Prompt maxlen, "max length"
		DoPrompt funcname, name_rhythm, name_tubo, name_rendition, name_t, threshold, maxlen
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(name_rhythm=\"" + name_rhythm + "\", name_tubo=\"" + name_tubo + "\", name_rendition=\"" + name_rendition + "\", name_t=\"" + name_t + "\", threshold=" + num2str(threshold) + ", maxlen=" + num2str(maxlen) + ")" 
	endif

//	string lista, name_a, listStr
//	variable windex=0, nindex=0, length_a, col_a, freq
//		lista = WaveList(wave_rhythm,";","")
	//	name_a = StringFromList(windex, lista)

	string destname = name_t + "_Resp"
	Duplicate /O $name_t, $destname
	Wave wave_tubo = $name_tubo
	Wave wave_rhythm = $name_rhythm
	Wave wave_rendition = $name_rendition
	Wave wave_t = $name_t
	Wave wave_dest = $destname

	variable len, pindex, lastDur, flagDetect, stResp
	Variable nResp, nWait
	len = DimSize(wave_rhythm, 0)
	wave_dest = 0
	pindex = 0
	flagDetect = 0
	lastDur = 10
	Do
		if (wave_rhythm[pindex] >= lastDur * threshold)		// detection of responsive phrase
			if ((pindex - stResp) <= maxlen)			// took as responses
//				print "pindex:", num2str(pindex), "; stResp:", num2str(stResp), "; lastDur:", lastDur, "\tYES : d:", num2str(pindex - stResp)
				if (flagDetect == 0)		// detected for the first time
//					print "	once"
					stResp = pindex
					flagDetect = 1
				elseif (flagDetect == 1)		// detected twice
//					print "	twice"
					nWait += 1
					variable i
					wave_dest[stResp] = 2
					for (i=stResp+1; i<=pindex; i+=1)
						wave_dest[i] = 1
					endfor
					stResp = pindex
				endif
			else
//				print "pindex:", num2str(pindex), "much distance"
				stResp = pindex
				if (flagDetect == 1)
					nResp += 1
				endif
				flagDetect = 0
			endif
		endif
		if (wave_rhythm[pindex] > 0.02)	// ! (decorative OR suri)
			lastDur = wave_rhythm[pindex]
		endif
		pindex += 1
	while(pindex < len)

	print " * nResponses: ", nResp, " ( Wait: ", nWait, ")" 
end function



function deleteSameTones ([name_rhythm, name_tubo, name_t])
	String name_rhythm, name_tubo, name_t
	String funcname = "deleteSameTones"
	if (numType(strlen(name_rhythm)) == 2)	// if (wave1 == null) : so there was no input
		name_tubo = "shami_tubo"; name_rhythm = "shami_rhythm_max"; name_t = "shami_chapter"
		Prompt name_rhythm, "Wave rhythm", popup wavelist ("*",";","")
		Prompt name_tubo, "Wave tubo", popup wavelist ("*",";","")
		Prompt name_t, "other wave to be deleted", popup wavelist ("*",";","")
		DoPrompt funcname, name_rhythm, name_tubo, name_t
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(name_rhythm=\"" + name_rhythm + "\", name_tubo=\"" + name_tubo + "\", name_t=\"" + name_t + "\")" 
	endif

	string destname
	Wave wave_tubo = $name_tubo
		destname = name_tubo + "_noSameTones"
		Duplicate /O $name_tubo, $destname
		Wave wave_dest_tubo = $destname
	Wave wave_rhythm = $name_rhythm
	 	destname = name_rhythm + "_noSameTones"
		Duplicate /O $name_rhythm, $destname
		Wave wave_dest_rhythm = $destname
	Wave wave_t = $name_t
		destname = name_t + "_noSameTones"
		Duplicate /O $name_t, $destname
		Wave wave_dest_t = $destname

	variable row, col, rindex, cindex, flagSame, val = 0
	row = DimSize(wave_dest_tubo, 0)
	col = DimSize(wave_dest_tubo, 1)
	rindex = 0
	Do
		cindex = 0
		Do
			if (wave_dest_tubo[rindex][cindex] == wave_dest_tubo[rindex+1][cindex] )
				flagSame = 1
				cindex += 1
				val = wave_dest_rhythm[rindex+1]
			else
//				print rindex, " ", cindex
				flagSame = 0
				cindex += 1
				break
			endif
		while(cindex < col)
//		print "*"
		
		if(flagSame == 1)
			if (val > 0.02)
				wave_dest_rhythm[rindex] += val
			endif
			deletepoints /M=0 rindex+1, 1, wave_dest_tubo
			deletepoints /M=0 rindex+1, 1, wave_dest_rhythm
			deletepoints /M=0 rindex+1, 1, wave_dest_t
			rindex -= 1
			row -= 1
		endif
		rindex += 1
	while(rindex < (row-1))
end function


function deleteGraces ([name_rhythm, name_tubo, name_t, type])
	String name_rhythm, name_tubo, name_t
	variable type
	String funcname = "deleteGraces"
	if (numType(strlen(name_rhythm)) == 2)	// if (wave1 == null) : so there was no input
		name_tubo = "shami_tubo"; name_rhythm = "shami_rhythm_max"; name_t = "shami_chapter"
		type = 0
		Prompt name_rhythm, "Wave rhythm", popup wavelist ("*",";","")
		Prompt name_tubo, "Wave tubo", popup wavelist ("*",";","")
		Prompt name_t, "other wave to be deleted", popup wavelist ("*",";","")
		Prompt type, "0/1: all/only tuton"
		DoPrompt funcname, name_rhythm, name_tubo, name_t, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(name_rhythm=\"" + name_rhythm + "\", name_tubo=\"" + name_tubo + "\", name_t=\"" + name_t + "\", type=" + num2str(type) + ")" 
	endif

	string destname
	Wave wave_tubo = $name_tubo
		destname = name_tubo + "_noGraces"
		Duplicate /O $name_tubo, $destname
		Wave wave_dest_tubo = $destname
	Wave wave_rhythm = $name_rhythm
	 	destname = name_rhythm + "_noGraces"
		Duplicate /O $name_rhythm, $destname
		Wave wave_dest_rhythm = $destname
	Wave wave_t = $name_t
		destname = name_t + "_noGraces"
		Duplicate /O $name_t, $destname
		Wave wave_dest_t = $destname

	variable row, col, rindex, cindex, flagGrace, nGraces=0, nTuton1=0, nTuton2=0, nTuton3=0
	row = DimSize(wave_dest_tubo, 0)
	col = DimSize(wave_dest_tubo, 1)
	rindex = 0
	if (type == 0)
		Do
			cindex = 0
			Do
				if (wave_dest_rhythm[rindex][cindex] < 0.02)
					flagGrace = 1
					cindex += 1
				else
					flagGrace = 0
					cindex += 1
					break
				endif
			while(cindex < col)
		
			if(flagGrace == 1)
				deletepoints /M=0 rindex, 1, wave_dest_tubo
				deletepoints /M=0 rindex, 1, wave_dest_rhythm
				deletepoints /M=0 rindex, 1, wave_dest_t
				nGraces += 1
				rindex -= 1
				row -= 1
			endif
			rindex += 1
		while(rindex < row)
		print "nGraces :", nGraces
	else
		Do
			cindex = 0
			flagGrace = 0
			Do
				if (wave_dest_rhythm[rindex][cindex] < 0.02 && wave_dest_rhythm[rindex+1][cindex] < 0.02)
					if (wave_dest_tubo[rindex][cindex] == 2 && wave_dest_tubo[rindex+1][cindex] == 4)								
						flagGrace = 1
						print rindex
						break
					endif
				endif
				cindex += 1
			while(cindex < col)
		
			if(flagGrace == 1)
				deletepoints /M=0 rindex, 2, wave_dest_tubo
				deletepoints /M=0 rindex, 2, wave_dest_rhythm
				deletepoints /M=0 rindex, 2, wave_dest_t
				if (cindex == 0)
					nTuton1 += 1
				elseif (cindex == 1)
					nTuton2 += 1
				elseif (cindex == 2)
					nTuton3 += 1
				endif
				rindex -= 2
				row -= 2
			endif
			rindex += 1
		while(rindex < (row - 1))
		print " * tuton1 :", nTuton1, "; tuton2 :", nTuton2, "; tuton3 :", nTuton3
	endif
end function


function deleteRests ([name_rhythm, name_tubo, name_t])
	String name_rhythm, name_tubo, name_t
	String funcname = "deleteRests"
	if (numType(strlen(name_rhythm)) == 2)	// if (wave1 == null) : so there was no input
		name_tubo = "shami_tubo"; name_rhythm = "shami_rhythm_max"; name_t = "shami_chapter"
		Prompt name_rhythm, "Wave rhythm", popup wavelist ("*",";","")
		Prompt name_tubo, "Wave tubo", popup wavelist ("*",";","")
		Prompt name_t, "other wave to be deleted", popup wavelist ("*",";","")
		DoPrompt funcname, name_rhythm, name_tubo, name_t
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(name_rhythm=\"" + name_rhythm + "\", name_tubo=\"" + name_tubo + "\", name_t=\"" + name_t + "\")" 
	endif

	string destname
	Wave wave_tubo = $name_tubo
		destname = name_tubo + "_noRests"
		Duplicate /O $name_tubo, $destname
		Wave wave_dest_tubo = $destname
	Wave wave_rhythm = $name_rhythm
	 	destname = name_rhythm + "_noRests"
		Duplicate /O $name_rhythm, $destname
		Wave wave_dest_rhythm = $destname
	Wave wave_t = $name_t
		destname = name_t + "_noRests"
		Duplicate /O $name_t, $destname
		Wave wave_dest_t = $destname

	variable row, col, rindex, cindex, flagRest, nRests=0
	row = DimSize(wave_dest_tubo, 0)
	col = DimSize(wave_dest_tubo, 1)
	rindex = 0
	Do
		cindex = 0
		Do
			if (wave_dest_tubo[rindex][cindex] < 0.01)
				flagRest = 1
				cindex += 1
			else
				flagRest = 0
				cindex += 1
				break
			endif
		while(cindex < col)
		
		if(flagRest == 1)
			if (rindex != 0)
				wave_dest_rhythm[rindex-1] += wave_dest_rhythm[rindex]
			endif
			deletepoints /M=0 rindex, 1, wave_dest_tubo
			deletepoints /M=0 rindex, 1, wave_dest_rhythm
			deletepoints /M=0 rindex, 1, wave_dest_t
			nRests += 1
			rindex -= 1
			row -= 1
		endif
		rindex += 1
	while(rindex < row)
	print "nRests :", nRests
end function

function killPlateauWaves ([wave1])
	String wave1
	String funcname = "killPlateauWaves"
	if (numType(strlen(wave1)) == 2)
		wave1 = "phrase*"
		Prompt wave1, "wave name"
		DoPrompt funcname, wave1
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(wave1=" + wave1 + "\")" 
	endif

	string lista, name_a
	variable windex, rindex, cindex
	variable n_a, row_a, col_a, nPlateau=0, flagPlateau
	lista = WaveList(wave1,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	n_a = ItemsInList(lista)
	Do
		if (waveExists($name_a))
			wave wave_a = $name_a
			row_a = DimSize(wave_a,0)
			col_a = DimSize(wave_a,1)
		endif
		flagPlateau = 1
		rindex = 0
		Do
			cindex = 0
			Do
				if (wave_a[rindex][cindex] != wave_a[rindex+1][cindex])
					flagPlateau = 0
					break
				endif
				cindex += 1
			while(cindex < col_a)
			if (flagPlateau == 0)
				break
			endif
			rindex += 1
		while(rindex < (row_a - 1))
		if (flagPlateau == 1)
			print " . . plateau : ", name_a
			killWaves wave_a
			nPlateau += 1
		endif
		windex+=1
		name_a = StringFromList(windex, lista)
	While(windex < n_a)
	print "END"
end function

function killSameWaves ([selector, tolerance])
	Variable selector, tolerance
	String funcname = "killSameWaves"
	if (selector == 0)	
		selector = 1; tolerance = 1e-8
		Prompt selector, "which aspects?: 1:data/2:type ... "	// equalWaves
		Prompt tolerance, "square difference < tolerance = match"
		DoPrompt "killSameWaves", selector, tolerance
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*" + funcname + "(selector=" + num2str(selector) + ", tolerance=" + num2str(tolerance) + ")" 
	endif

	make /O /N=(0,0) onsetRepeats
		wave onset_repeats = onsetRepeats
	make /O /N=(0) nRepeats
		wave n_repeats = nRepeats

	string lista, name_a, listb, name_b
	variable windex, phindex, nindex, n_a, n_b, num_a, num_b, length_a, col_a, length_ph, n_repeat
	lista = WaveList("phrase*",";","")
	phindex = 0
	windex=0
	name_a = StringFromList(windex, lista)
	n_a = ItemsInList(lista)
	Do
		if (waveExists($name_a))
			wave wave_a = $name_a
			phindex += 1
			if (DimSize(onsetRepeats,1) == 0)
				Redimension /N=(phindex, 1) onsetRepeats
			else
				Redimension /N=(phindex, -1) onsetRepeats
			endif
			num_a = str2num(name_a[strSearch(name_a, "_", 0)+1, strlen(name_a)-1])
			onsetRepeats[phindex-1][0] = num_a
			print " . . ", name_a
		else
			windex+=1
			name_a = StringFromList(windex, lista)
			continue
		endif
		listb = WaveList("phrase*",";","")
		n_b = ItemsInList(listb)
		n_repeat = 0
		nindex=0
		name_b = StringFromList(nindex, listb)
		Do
			num_b = str2num(name_b[strSearch(name_b, "_", 0)+1, strlen(name_b)-1])
			if (num_a >= num_b)
				nindex += 1
				name_b = StringFromList(nindex, listb)
				continue
			else 
				wave wave_b = $name_b
				if(equalWaves(wave_a, wave_b, selector, tolerance) == 1)
					print " . . . . . ", name_b
					killWaves wave_b
					n_repeat += 1
					if (DimSize(onsetRepeats,1) < (n_repeat+1))
						Redimension /N=(-1, (n_repeat+1)) onsetRepeats
					endif
					onsetRepeats[phindex-1][n_repeat] = num_b
				endif
				nindex += 1
				name_b = StringFromList(nindex, listb)
			endif
		while(nindex < n_b)
		print " . . ", num2str(n_repeat)
		print "========================================"
		Redimension /N=(phindex) n_repeats
		n_repeats[phindex] = n_repeat
		windex+=1
		name_a = StringFromList(windex, lista)
	While(windex < n_a)
	print "END"
end function


function playPartOfSound ([wave1, destname, sttime, entime])
	String wave1, destname
	Variable sttime, entime
	String funcname = "playPartOfSound"
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "wave*"; destname="p_"; sttime=0; entime=0
		Prompt wave1, "Audio Wave" //, popup wavelist ("*",";","")
		Prompt destname, "prefix" //, popup wavelist ("*",";","")
		Prompt sttime, "from" //, popup wavelist ("*",";","")
		Prompt entime, "to"
		DoPrompt "playPartOfSound", wave1, destname, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print " " + funcname + "(wave1=\"" + wave1 + "\", destname=\"" + destname + "\", sttime=" + num2str(sttime)  + ", entime=" + num2str(entime) + ")" 
	endif

	string lista , a_name, targetname
	variable windex=0
		lista = WaveList(wave1,";","")
		a_name = StringFromList(windex, lista)
	Do
		wave a_wave = $a_name
		targetname = destname+a_name
		Duplicate /O /R=(sttime, entime) a_wave, $targetname
		Playsound /A $targetname
		windex+=1
		a_name = StringFromList(windex, lista)
	While(strlen(a_name)!=0)

end function

function makeSineMusic ([wave_onset, wave_offset, wave_freq, amp, trise, tdecay, freq, destname])
	String wave_onset, wave_offset, wave_freq, destname
	Variable amp, trise, tdecay, freq
	String funcname = "makeSineMusic"
	if (numType(strlen(wave_onset)) == 2)	// if (wave1 == null) : so there was no input
		wave_onset = "*onset"; wave_offset = "*offset"; wave_freq = "*freq"; destname = "sine"
		amp = 10000; trise=0.01; tdecay=0.01; freq=44100;
		Prompt wave_onset, "onset wave" //, popup wavelist ("*",";","")
		Prompt wave_offset, "offset Wave" //, popup wavelist ("*",";","")
		Prompt wave_freq, "frequency name"
		Prompt amp, "amplitude (-32768 to 32767)"
		Prompt trise, "rise time [s]"
		Prompt tdecay, "decay time [s]"
		Prompt freq, "frequency (default=44100)"
		Prompt destname, "dest name"
		DoPrompt "makeSineMusic", wave_onset, wave_offset, wave_freq, amp, trise, tdecay, freq, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print " makeSineMusic" + "(wave_onset=\"" + wave_onset + "\", wave_offset=\"" + wave_offset + "\", wave_freq=\"" + wave_freq + "\", amp=" + num2str(amp) + ", trise=" + num2str(trise) + ", tdecay=" + num2str(tdecay) + ", freq=" + num2str(freq)  + ", destname=\"" + destname + "\")" 
	endif

	string listonset, listoffset, listfreq, onset_name, offset_name, freq_name, targetname
	variable windex=0, nindex=0, length
		listonset = WaveList(wave_onset,";","")
		listoffset = WaveList(wave_offset,";","")
		listfreq = WaveList(wave_freq,";","")
		onset_name = StringFromList(windex, listonset)
		offset_name = StringFromList(windex, listoffset)
		freq_name = StringFromList(windex, listfreq)
		
	variable lenx, samplefreq
	if (freq <=0)
		samplefreq = 44100
	else
		samplefreq = freq
	endif
	
	Do
		if(strlen(onset_name)==0)
			break
		endif

		wave onset_wave = $onset_name
		wave offset_wave = $offset_name
		wave freq_wave = $freq_name
		if (windex == 0)
			targetname = destname
		else
			targetname = destname + "_" + num2str(windex)
		endif
		lenx = offset_wave[numpnts(offset_wave)-1]
					
		make /O /N=(samplefreq * lenx) $targetname
		SetScale/P x 0, 1/samplefreq,"s", $targetname
		wave twave = $targetname
		twave = 0
		
		variable ii

		for (ii=0; ii<DimSize(onset_wave,0); ii+=1)
			// phase is onset=0
			twave[x2pnt(twave,onset_wave[ii]), x2pnt(twave,offset_wave[ii])] = amp * sin((x-onset_wave[ii])*2*pi*freq_wave[ii])
		endfor
		if (trise > 0)
			for (ii=0; ii<DimSize(onset_wave,0); ii+=1)
				twave[x2pnt(twave,onset_wave[ii]), x2pnt(twave,onset_wave[ii]+trise)] = twave[x2pnt(twave,x)] * ((x-onset_wave[ii])/trise)
			endfor
		endif
		if (tdecay > 0)
			for (ii=0; ii<DimSize(onset_wave,0); ii+=1)
				twave[x2pnt(twave,offset_wave[ii]-tdecay), x2pnt(twave,offset_wave[ii])] = twave[x2pnt(twave,x)] * ((offset_wave[ii]-x)/tdecay)
			endfor
		endif
		
		windex+=1
		onset_name = StringFromList(windex, listonset)
		offset_name = StringFromList(windex, listoffset)
		freq_name = StringFromList(windex, listfreq)
	While(strlen(onset_name)!=0)

end function


function drawRhythmDiagram ([waveFF, waveBeat])
	String waveFF, waveBeat
	if (numType(strlen(waveFF)) == 2)	// if (wave1 == null) : so there was no input
		waveFF = "measure*"; waveBeat = "Ry*beat*mag";
		Prompt waveFF, "Wave measure Xonset (s)"//, popup wavelist ("*",";","")
		Prompt waveBeat, "Wave beat"//, popup wavelist ("*",";","")
		DoPrompt  "drawRhythmDiagram", waveFF, waveBeat
		if (V_Flag)	// User canceled
			return -1
		endif
		print "drawRhythmDiagram(waveFF=\"" + waveFF + "\", waveBeat=\"" + waveBeat + "\")"
	endif
	
	string lista, name_a, listb, name_b
	variable windex, rangea, rangeb, thresa, thresb, Nffcross, Nbeatcross
	string nameffcross, namebeatcross, nameffpeak, namebeatpeak, nameffpeakx, namebeatpeakx
	string nameMeasure, nameMeasurebeat, nameBeatStrength, nameBeatPhase, nameBeatT, nameBeatTempo

	Display as "Rhythm Diagram"

	lista = WaveList(waveFF,";","")
	listb = WaveList(waveBeat,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	name_b = StringFromList(windex, listb)
	Do
		wave wave_a = $name_a
		wave wave_b = $name_b
		wavestats /Q wave_a
		rangea = V_max - V_min
		thresa = V_avg + rangea * 0.01
		wavestats /Q wave_b
		rangeb = V_max - V_min
		thresb = V_avg + rangeb * 0.01
		
		//nameffcross = "cr" + name_a
		namebeatcross = "cr" + name_b
		
		//print windex, ": ", thresa, thresb, name_b
		//FindLevels /B=5 /D=$nameffcross /EDGE=1 /Q wave_a, thresa
		
		// find thethres crossed 
		FindLevels /B=5 /D=$namebeatcross /EDGE=1 /Q wave_b, thresb
		//wave waveffcross = $nameffcross
		wave wavebeatcross = $namebeatcross
		//nameffpeak = "pk" + name_a
		namebeatpeak = "pk" + name_b
		//nameffpeakx = "pkx" + name_a
		namebeatpeakx = "pkx" + name_b
		nameMeasure = "M" + name_a
		nameMeasurebeat = "MB" + name_a
		nameBeatStrength = "strn" + name_b
		nameBeatPhase = "phase" + name_b
		nameBeatT = "t" + name_b
		nameBeatTempo = "tempo" + name_b
		//Make /N=(DimSize(waveffcross,0)) /O $nameffpeak
		//Make /N=(DimSize(waveffcross,0)) /O $nameffpeakx
		Make /N=(DimSize(wave_a,0)) /O $nameMeasure
		Make /N=(DimSize(wave_a,0)) /O $nameMeasurebeat
		Make /N=(DimSize(wavebeatcross,0)) /O $namebeatpeak
		Make /N=(DimSize(wavebeatcross,0)) /O $namebeatpeakx
		Make /N=(DimSize(wavebeatcross,0)) /O $nameBeatStrength
		Make /N=(DimSize(wavebeatcross,0)) /O $nameBeatT
		
		//wave waveffpeak = $nameffpeak
		//wave waveffpeakx = $nameffpeakx
		wave waveMeasure = $nameMeasure
		wave waveMeasurebeat = $nameMeasurebeat
		wave wavebeatpeak = $namebeatpeak
		wave wavebeatpeakx = $namebeatpeakx
		wave waveBeatStrength = $nameBeatStrength
		wave waveBeatT = $nameBeatT
		// calc ff peaks
		//variable i
		//for (i=0; i<DimSize(waveffcross,0); i+=1)
		//	if (i == DimSize(waveffcross,0)-1)
		//		wavestats /R=(waveffcross[i], rightx(wave_a)) /Q wave_a
		//	else
		//		wavestats /R=(waveffcross[i], waveffcross[i+1]) /Q wave_a
		//	endif
		//	//print i, V_maxloc, waveffcross[i], waveffcross[i+1], name_a
		//	waveffpeak[i] = V_max
		//	waveffpeakx[i] = V_maxloc
		//endfor
		
		// calc beat peaks
		variable Vmeasure=inf, vindex = 0, Nbeat=0, indbeat=0
		variable i
		for (i=0; i<DimSize(wavebeatcross,0); i+=1)
			if (i == DimSize(wavebeatcross,0)-1)
				wavestats /R=(wavebeatcross[i], rightx(wave_b)) /Q wave_b
			else
				wavestats /R=(wavebeatcross[i], wavebeatcross[i+1]) /Q wave_b
			endif
			wavebeatpeak[i] = V_max
			wavebeatpeakx[i] = V_maxloc
			//print i, wavebeatpeakx[i], vindex, Nbeat
			if (vindex < DimSize(wave_a,0))
				if (wavebeatpeakx[i] < wave_a[vindex])
					Vmeasure = abs(wave_a[vindex] - wavebeatpeakx[i])
					Nbeat += 1
					//print i, Nbeat
					if (vindex > 0)
						waveBeatStrength[indbeat] = wavebeatpeak[i]
						waveBeatT[indbeat] = wavebeatpeakx[i]
						indbeat += 1
					endif
				else
					waveBeatStrength[indbeat] = wavebeatpeak[i]
					waveBeatT[indbeat] = wavebeatpeakx[i]
					indbeat += 1
					if (vindex > 0)
						if (abs(wave_a[vindex] - wavebeatpeakx[i]) < Vmeasure)
							waveMeasurebeat[vindex-1] = Nbeat+1
						else
							waveMeasurebeat[vindex-1] = Nbeat
						endif
					endif
					if (abs(wave_a[vindex] - wavebeatpeakx[i]) < Vmeasure)
						waveMeasure[vindex] = wavebeatpeakx[i]
						//print "setNow"
						Nbeat = 0
					else
						waveMeasure[vindex] = wavebeatpeakx[i-1]
						//print "setPre"
						Nbeat = 1
					endif
						//print i, Nbeat
					vindex +=	 1
					if (vindex < DimSize(wave_a,0))
						Vmeasure = abs(wave_a[vindex] - wavebeatpeakx[i])
					endif
				endif
			else
				Nbeat += 1
					//print i, Nbeat
				waveBeatStrength[indbeat] = wavebeatpeak[i]
				waveBeatT[indbeat] = wavebeatpeakx[i]
				indbeat += 1
			endif
		endfor
		deletepoints indbeat, inf, waveBeatStrength
		deletepoints indbeat, inf, waveBeatT
		waveMeasurebeat[vindex] = Nbeat+1
		Duplicate /O waveBeatT, $nameBeatPhase
		Duplicate /O waveMeasure, $nameBeatTempo		
		wave waveBeatPhase = $nameBeatPhase
		wave waveBeatTempo = $nameBeatTempo

		indbeat = 0
		variable j		
		for (i=0; i<DimSize(waveMeasure,0); i+=1)
			waveBeatPhase[indbeat] = 0
			indbeat+=1
			if (i == DimSize(waveMeasure,0)-1) // last
				waveBeatTempo[i] = (rightx(wave_b) - waveMeasure[i]) / waveMeasurebeat[i]
			else
				waveBeatTempo[i] = (waveMeasure[i+1] - waveMeasure[i]) / waveMeasurebeat[i]
			endif
			for (j=1; j<waveMeasurebeat[i]; j+=1)
				waveBeatPhase[indbeat] = (waveBeatT[indbeat] - (waveMeasure[i] + waveBeatTempo[i] * j)) / waveBeatTempo[i]
				indbeat += 1
			endfor
		endfor
				
		
		
	//// draw Diagram
	variable nSyl = 8
	string xname, yname, sxname, syname, txname, tyname, end_xname, end_yname, st_xname, st_yname, trxname, tryname, lxname, lyname
	variable nindex, length_a, last_n, wred, wgrn, wblu, nColor, nnoise, preX, preY, postX, postY, snoise, linethickness, preSyl, postSyl, ssnoise
	// for Bezier
	variable useBezier = 0
	variable txpre, typre, lxpost, lypost

		//nnoise=0.015		// 0.025	
		//snoise = 0.005	// 0.015
		ssnoise = 0.005	// 0.012
		linethickness = 0.3
	
	
		wavestats /Q waveBeatTempo
		variable normTempo = V_max
		wavestats /Q waveBeatStrength
		variable normStrength = V_max

		preX = cos(Pi/2) * 0.25 + 0.5 // + gnoise(snoise)
		preY = sin(Pi/2) * 0.25 + 0.5 // + gnoise(snoise)

		indbeat = 0
		for (i=0; i<DimSize(waveMeasure,0); i+=1)
			
			for (j=0; j<waveMeasurebeat[i]-1; j+=1)
//				if (i == 0 && j == 0)
//					preX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
	//				preY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
//					preX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 + 0.5 // + gnoise(snoise)
//					preY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 + 0.5 // + gnoise(snoise)
//				endif
				wred = (50000 - 10000 * (trunc((waveMeasurebeat[i]-1)/2)/5)) * mod(waveMeasurebeat[i] + 1, 2)
				wred  = (40000 - wred) * (1 - waveBeatStrength[indbeat]/V_max) + wred
				wgrn = 30000 * (trunc((waveMeasurebeat[i]-1)/2)/5)
				wgrn  = (40000 - wgrn) * (1 - waveBeatStrength[indbeat]/V_max) + wgrn
				wblu = (50000 - 10000 * (trunc((waveMeasurebeat[i]-1)/2)/5)) * mod(waveMeasurebeat[i], 2) 
				wblu  = (40000 - wblu) * (1 - waveBeatStrength[indbeat]/V_max) + wblu

//				postX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
//				postY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
				postX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 + 0.5 // + gnoise(snoise)
				postY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 + 0.5 // + gnoise(snoise)
					print i, j, waveMeasurebeat[i], preX-0.5, preY-0.5, postX-0.5, postY-0.5
				setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness
				if (waveMeasurebeat[i] == 1)
					txpre =  (preX+postX)/2 + cos(Pi/2+2*Pi/8*1) / 8 + gnoise(ssnoise)
					typre =  (preY+postY)/2 + sin(Pi/2+2*Pi/8*1) / 8	 + gnoise(ssnoise)
					lxpost =  (preX+postX)/2 + cos(Pi/2+2*Pi/8*2) / 8 + gnoise(ssnoise)
					lypost =  (preX+postX)/2 + sin(Pi/2+2*Pi/8*2) / 8 + gnoise(ssnoise)
					setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness, fillpat=0
					DrawBezier preX, preY, 1, 1, {preX, preY, txpre, typre,     lxpost, lypost, postX, postY}
				else
					DrawLine preX, preY, postX, postY
				endif
				preX = postX
				preY = postY

				indbeat += 1
			endfor
		endfor
		
		windex+=1
		name_a = StringFromList(windex, lista)
		name_b = StringFromList(windex, listb)
	While(strlen(name_a)!=0)
	
	
	
	
	
	
end


function drawRhythmDiagram0 ([waveFF, waveBeat])
	String waveFF, waveBeat
	if (numType(strlen(waveFF)) == 2)	// if (wave1 == null) : so there was no input
		waveFF = "measure*"; waveBeat = "Ry*beat*mag";
		Prompt waveFF, "Wave measure Xonset (s)"//, popup wavelist ("*",";","")
		Prompt waveBeat, "Wave beat"//, popup wavelist ("*",";","")
		DoPrompt  "drawRhythmDiagram0", waveFF, waveBeat
		if (V_Flag)	// User canceled
			return -1
		endif
		print "drawRhythmDiagram0(waveFF=\"" + waveFF + "\", waveBeat=\"" + waveBeat + "\")"
	endif
	
	string lista, name_a, listb, name_b
	variable windex, rangea, rangeb, thresa, thresb, Nffcross, Nbeatcross
	string nameffcross, namebeatcross, nameffpeak, namebeatpeak, nameffpeakx, namebeatpeakx
	string nameMeasure, nameMeasurebeat, nameBeatStrength, nameBeatPhase, nameBeatT, nameBeatTempo

	Display as "Rhythm Diagram0"

	lista = WaveList(waveFF,";","")
	listb = WaveList(waveBeat,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	name_b = StringFromList(windex, listb)
	Do
		wave wave_a = $name_a
		wave wave_b = $name_b
		print name_a, name_b
		wavestats /Q wave_a
		rangea = V_max - V_min
		thresa = V_avg + rangea * 0.01
		wavestats /Q wave_b
		rangeb = V_max - V_min
		thresb = V_avg + rangeb * 0.01
		
		//nameffcross = "cr" + name_a
		namebeatcross = "cr" + name_b
		
		//print windex, ": ", thresa, thresb, name_b
		//FindLevels /B=5 /D=$nameffcross /EDGE=1 /Q wave_a, thresa
		
		// find thethres crossed 
		
		//FindLevels /B=5 /D=$namebeatcross /EDGE=1 /Q wave_b, thresb
		//wave wavebeatcross = $namebeatcross
		namebeatpeak = "pk" + name_b
		namebeatpeakx = "pkx" + name_b
		nameMeasurebeat = "MB" + name_a
		nameBeatStrength = "amp" + name_b
		nameBeatPhase = "phase" + name_b
		//nameBeatT = "t" + name_b
		nameBeatTempo = "tempo" + name_b
		//Make /N=(DimSize(waveffcross,0)) /O $nameffpeak
		//Make /N=(DimSize(waveffcross,0)) /O $nameffpeakx
		//Make /N=(DimSize(wave_a,0)) /O $nameMeasure
		//Make /N=(DimSize(wave_a,0)) /O $nameMeasurebeat
		//Make /N=(DimSize(wavebeatcross,0)) /O $namebeatpeak
		//Make /N=(DimSize(wavebeatcross,0)) /O $namebeatpeakx
		//Make /N=(DimSize(wavebeatcross,0)) /O $nameBeatStrength
		//Make /N=(DimSize(wavebeatcross,0)) /O $nameBeatT
		Duplicate /O $namebeatpeakx, $nameBeatTempo
		
		//wave waveffpeak = $nameffpeak
		//wave waveffpeakx = $nameffpeakx
		wave wavebeatpeak = $namebeatpeak
		wave wavebeatpeakx = $namebeatpeakx
		wave waveBeatStrength = $nameBeatStrength
		//wave waveBeatT = $nameBeatT
		wave waveBeatPhase = $nameBeatPhase
		wave waveBeatTempo = $nameBeatTempo
		
		// Prepare waveBeatTempo
		differentiate /METH=1 /EP=1 waveBeatTempo // stepdif
		insertPoints inf, 1, waveBeatTempo
		waveBeatTempo[inf] = rightx(wave_b) - wavebeatpeakx[inf]
		
		// Prepare Meter beat
		make /N=(0) /O $nameMeasurebeat
		wave waveMeasurebeat = $nameMeasurebeat

		variable ii, jj, lastjj
		for (ii=0; ii<numpnts(wave_a); ii+=1)
			variable Nbeat=0
			for (jj=lastjj; jj<numpnts(wavebeatpeakx); jj+=1)
				if(wave_a[ii] == wavebeatpeakx[jj])
					insertpoints inf, 1, waveMeasurebeat
					waveMeasurebeat[ii] = Nbeat
					lastjj = jj
					break
				else
					Nbeat += 1
				endif
			endfor
		endfor
		insertpoints inf, 1, waveMeasurebeat
		waveMeasurebeat[ii] = Nbeat
		

	//// draw Diagram
	variable nSyl = 8
	string xname, yname, sxname, syname, txname, tyname, end_xname, end_yname, st_xname, st_yname, trxname, tryname, lxname, lyname
	variable nindex, length_a, last_n, wred, wgrn, wblu, nColor, nnoise, preX, preY, postX, postY, snoise, linethickness, preSyl, postSyl, ssnoise
	// for Bezier
	variable useBezier = 0
	variable txpre, typre, lxpost, lypost, indbeat, i, j, r, wopacity

		//nnoise=0.015		// 0.025	
		//snoise = 0.005	// 0.015
		ssnoise = 0.005	// 0.012
		linethickness = 0.3
	
		wavestats /Q waveBeatTempo
		variable normTempo = V_max
		wavestats /Q waveBeatStrength
		variable normStrength = V_max
		wavestats /Q waveMeasurebeat
		variable normTempo2 = V_max
		normTempo2 = normTempo2 * normTempo
		wavestats /Q waveBeatStrength
		variable norm_opacity = V_max

		//preX = cos(-Pi/2) * 0.25 + 0.5 // + gnoise(snoise)
		//preY = sin(-Pi/2) * 0.25 + 0.5 // + gnoise(snoise)

		preX = 0.5 // + gnoise(snoise)
		preY = 0.5 // + gnoise(snoise)
		indbeat = 0
		for (i=0; i<numpnts(waveMeasurebeat); i+=1)
			
			for (j=0; j<waveMeasurebeat[i]; j+=1)
//				if (i == 0 && j == 0)
//					preX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
	//				preY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
//					preX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 + 0.5 // + gnoise(snoise)
//					preY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*j) * 0.25 + 0.5 // + gnoise(snoise)
//				endif
				wred = (50000 - 10000 * (trunc((waveMeasurebeat[i]-1)/2)/5)) * mod(waveMeasurebeat[i] + 1, 2)
				wred  = (40000 - wred) * (1 - waveBeatStrength[indbeat]/V_max) + wred
				wgrn = 30000 * (trunc((waveMeasurebeat[i]-1)/2)/5)
				wgrn  = (40000 - wgrn) * (1 - waveBeatStrength[indbeat]/V_max) + wgrn
				wblu = (50000 - 10000 * (trunc((waveMeasurebeat[i]-1)/2)/5)) * mod(waveMeasurebeat[i], 2) 
				wblu  = (40000 - wblu) * (1 - waveBeatStrength[indbeat]/V_max) + wblu
				wopacity = 65535 * waveBeatStrength[i] / norm_opacity
				
				//r = (waveBeatTempo[i] / normTempo) / 2 / sin(Pi/waveMeasurebeat[i]) // length represents tempo
				r = (waveBeatTempo[i] * waveMeasurebeat[i] / normTempo2)  // radium represents measure
			

//				postX = cos(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
//				postY = sin(Pi/2+2*Pi/waveMeasurebeat[i]*(j+1)) * 0.25 * (waveBeatTempo[i] / normTempo) + 0.5 // + gnoise(snoise)
				postX = cos(-Pi/2+2*Pi/waveMeasurebeat[i]*(j)) * r * 0.25 + 0.5 // + gnoise(snoise)
				postY = sin(-Pi/2+2*Pi/waveMeasurebeat[i]*(j)) * r * 0.25 + 0.5 // + gnoise(snoise)
					//print i, j, waveMeasurebeat[i], preX-0.5, preY-0.5, postX-0.5, postY-0.5
				if (waveMeasurebeat[i] == 1)
					txpre =  (preX+postX)/2 + cos(Pi/2+2*Pi/8*1) / 8 + gnoise(ssnoise)
					typre =  (preY+postY)/2 + sin(Pi/2+2*Pi/8*1) / 8	 + gnoise(ssnoise)
					lxpost =  (preX+postX)/2 + cos(Pi/2+2*Pi/8*2) / 8 + gnoise(ssnoise)
					lypost =  (preX+postX)/2 + sin(Pi/2+2*Pi/8*2) / 8 + gnoise(ssnoise)
					setDrawEnv linefgc=(wred,wgrn,wblu,wopacity), linethick=linethickness, fillpat=0
					DrawBezier preX, preY, 1, 1, {preX, preY, txpre, typre,     lxpost, lypost, postX, postY}
				else
					setDrawEnv linefgc=(wred,wgrn,wblu,wopacity), linethick=linethickness
					DrawLine preX, preY, postX, postY
				endif
				preX = postX
				preY = postY

				indbeat += 1
			endfor
		endfor
		
		windex+=1
		name_a = StringFromList(windex, lista)
		name_b = StringFromList(windex, listb)
	While(strlen(name_a)!=0)
	
	
	
	
	
	
end


function makeRhythmWave ([waveFreq, waveAmp, waveRhythm, destname])
	String waveFreq, waveAmp, waveRhythm, destname
	if (numType(strlen(waveFreq)) == 2)	// if (wave1 == null) : so there was no input
		waveFreq = "ff_*"; waveRhythm="R_amp_S_s*mag"; destname="Ry_"
		Prompt waveFreq, "Wave frequency [Hz]"//, popup wavelist ("*",";","")
		Prompt waveAmp, "Wave frequency amp"
		Prompt waveRhythm, "Wave raw rhythm"
		Prompt destname, "destname prefix"
		DoPrompt  "makeRhythmWave", waveFreq, waveAmp, waveRhythm, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeRhythmWave(waveFreq=\"" + waveFreq + "\", waveAmp=\"" + waveAmp + "\", waveRhythm=\"" + waveRhythm + "\", destname=\"" + destname  + "\")"
	endif
	
	string lista, name_a, listr, name_r, destwave, listamp, name_amp
	variable windex, aindex, rect, sizea, sizer, lefta, leftr, da, dr, sizesine, xnow, fnow, predictivewin, divide
	variable flagdivide

	// * Parameters * //
	rect = 0
	divide = 8
	flagdivide = 1

	lista = WaveList(waveFreq,";","")
	listamp = WaveList(waveAmp,";","")
	listr = WaveList(waveRhythm,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	name_amp = StringFromList(windex, listamp)
	name_r = StringFromList(windex, listr)
	Do
   		print name_a, name_r
		wave wa = $name_a // Hz
		wave wamp = $name_amp // amp
		wave wr = $name_r // raw trace
		sizea = DimSize(wa, 0)
		sizer = DimSize(wr, 0)
		lefta = DimOffset(wa, 0)
		leftr = DimOffset(wr, 0)
		da = deltax(wa)
		dr = deltax(wr)
		if (leftr >= lefta)
			print "Aborted because of irregular inputs. Check the code"
			abort
		else
			// * sine wave with twice the diff of onset
			sizesine = abs(lefta - leftr)*2
			predictivewin = 0
		endif

		if (stringmatch(destname, "") == 1)
			destname = "Ry_"
		endif
		destwave = destname + name_a
		Duplicate /O wr, $destwave
		wave wd = $destwave
		wd = 0

    	aindex=0
		Do
			xnow = lefta+da*aindex
    		fnow = wa(xnow)
    		if (fnow <= 0)
				aindex += 1
    			continue
    		endif
    		
    		if (sizesine > divide/fnow && flagdivide)
	    		int ii
	    		int Ndivide = max(1, round(sizesine / (divide/fnow)))
	    		//print Ndivide
	    		//print round(sizesine)
				for (ii = 0; ii<Ndivide; ii+=1)
			    	make /N=( sizesine/Ndivide /dr) /O tmpsine
					setscale /P x, xnow - sizesine/2 + sizesine / Ndivide * ii , dr, "s", tmpsine
					tmpsine = sin((x - 1/fnow/4)  * fnow * 2*pi)
					Duplicate /O tmpsine, tmpauto
					Duplicate /R=(xnow - sizesine/2 + sizesine / Ndivide * ii,xnow - sizesine/2 + sizesine / Ndivide * (ii + 1) -dr) /O wr, tmpsnip // posthoc computation
					correlate tmpsnip, tmpauto
					wavestats /Q tmpauto

					make /N=( sizesine/Ndivide /dr)/O tmprhythm
					setscale /P x, xnow - sizesine/2 + sizesine / Ndivide * ii , dr, "s", tmprhythm
					//tmprhythm = sin((x - 1/fnow/4 - (xnow - sizesine/2 - predictivewin) + V_maxloc) * fnow * 2*pi) * wamp(xnow)
					tmprhythm = sin((x - 1/fnow/4 - (xnow - sizesine/2 - predictivewin) + V_maxloc - sizesine / Ndivide * ii) * fnow * 2*pi) * wamp(xnow) 

					//wd[x2pnt(wd, leftx(tmprhythm)), x2pnt(wd, rightx(tmprhythm))] += tmprhythm[p-x2pnt(wd, leftx(tmprhythm))]
					wd[x2pnt(wd, leftx(tmprhythm)), x2pnt(wd, rightx(tmprhythm))] += tmprhythm[p-x2pnt(wd, leftx(tmprhythm))]
					//if (aindex == 2 && ii == 9)
					//	break
					//endif
				endfor
				//if (aindex == 2)
					//print xnow
					//print xnow - sizesine/2 + sizesine / Ndivide * ii
					//print xnow - sizesine/2 + sizesine / Ndivide * (ii + 1) -dr
				//	break
				//endif
			else
    		
		    	//make /N=(1/fnow/dr+1) /O tmpsine // 1) this is faster but not accurate
				//setscale /P x, 0, dr, "s", tmpsine
				//tmpsine = sin((x-1/fnow/4) * fnow * 2*pi)
		    	make /N=( (sizesine+2*predictivewin) /dr+1) /O tmpsine
				setscale /P x, xnow - sizesine/2 - predictivewin, dr, "s", tmpsine
				tmpsine = sin((x - 1/fnow/4)  * fnow * 2*pi)
				Duplicate /O tmpsine, tmpauto	

				Duplicate /R=(xnow - sizesine/2, xnow + sizesine/2) /O wr, tmpsnip // posthoc computation
			// Duplicate /R=(xnow - sizesine/2, xnow) /O wr, tmpsnip // realtime computation (spectrogram also should be realtime in this case)
			
				if (rect == 1)
  					// cut the raw rhythm < mean-1SD
  					rectWave(waves="tmpsnip", destname="R", pol=1, type=0, thres=1, dpn=3)
					correlate /C R_tmpsnip, tmpauto
				else
					//correlate /C tmpsnip, tmpauto // 1) this is faster but not accurate
					correlate tmpsnip, tmpauto
  		  		endif
				wavestats /Q tmpauto

				make /N=( (sizesine+2*predictivewin) /dr+1) /O tmprhythm
				setscale /P x, xnow - sizesine/2 - predictivewin, dr, "s", tmprhythm
				//tmprhythm = sin((x - 1/fnow/4 - (xnow - sizesine/2 - predictivewin) + V_maxloc) * fnow * 2*pi) * wamp(xnow)
				tmprhythm = sin((x - 1/fnow/4 - (xnow - sizesine/2 - predictivewin) + V_maxloc) * fnow * 2*pi) * wamp(xnow) 

				wd[x2pnt(wd, leftx(tmprhythm)), x2pnt(wd, rightx(tmprhythm))] += tmprhythm[p-x2pnt(wd, leftx(tmprhythm))]
			endif
						
			aindex += 1
		While(aindex < sizea)
		//Killwaves tmpsine
		//Killwaves tmpauto
		//Killwaves tmpsnip
		//Killwaves tmprhythm

  		windex+=1
		name_a = StringFromList(windex, lista)
		name_r = StringFromList(windex, listr)
	While(strlen(name_a)!=0 && strlen(name_r)!=0)
end



function makeCorrRhythmMatrix ([wave1, wave2, winrange,beat_prewin, beat_postwin, beatwintype, calcrange, errwin, fwarp, destname])
	// make correlation matrix (one-by-one correlation) 
	// you can make another function with step instead of wave2
	// destname is not necessary
	
	String wave1, wave2, destname
	Variable winrange, calcrange, errwin, fwarp, beat_prewin, beat_postwin, beatwintype
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		errwin=0.1; fwarp = 0.05; winrange=0; beat_prewin = 0.4; beat_postwin = 0.6; beatwintype=0
		Prompt wave1, "raw wave name"//, popup wavelist ("*",";","")
		Prompt wave2, "peakx wave name"//, popup wavelist ("*",";","")
		Prompt winrange, "window width [ms]"
		Prompt beat_prewin, "pre win wid [ratio]"
		Prompt beat_postwin, "post win wid [ratio]"
		Prompt beatwintype, "win type 0:wwin, 1:wbeat"
		Prompt calcrange, "calc range [ms]"
		Prompt errwin,"error window size [ratio]"
		Prompt fwarp,"freq warp [ratio]"
		Prompt destname,"SUFFIX"
		DoPrompt  "makeCorrRhythmMatrix",wave1, wave2, winrange, beat_prewin, beat_postwin, beatwintype, calcrange, errwin, fwarp, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeCorrRhythmMatrix(wave1=\"" + wave1 + "\",wave2=\"" + wave2 + "\",winrange=" + num2str(winrange) + ",beat_prewin=" + num2str(beat_prewin) + ",beat_postwin=" + num2str(beat_postwin) + ",beatwintype=" + num2str(beatwintype)  + ",calcrange=" + num2str(calcrange) +  ",errwin=" + num2str(errwin) + ",fwarp=" + num2str(fwarp) + ",destname=\"" + destname + "\")"
	endif	
	/// This function seems to show a bit smaller value when the window size is large
	/// probably due to the smeared effect of the sliding window (moving average degrades the high correlation of a point)
	

	winrange /=1000		// to [sec]
	calcrange /=1000		// to [sec]
	//errwin /= 1000
	
	variable length, width
	string wave_1, wave_2, wave_3, finaldestname, maxname, metername
	string diaginame, diagjname, diagNname, diagcorrname, metermatname
	wave_1 = "tmpwave_1"
	wave_2 = "tmpwave_2"
	wave_3 = "tmpwave_3"
	variable flag_alltoall=1, aindex=0, bindex=0 
	variable ii, jj, kk, ll, xa, xb, da, db, avgb, winpnt, cwinpnt, now, lasttime, ind_1, ind_2, la, lb
	variable tmpnum, win
	variable pntcenter1, pntcenter2, pntwid_pre, pntwid_post, RMS1, Len1, RMS2, Len2, max2,tmpcorrval
	//variable flagMAD = 1, max1, max2
	
	// *** parameters
	//errwin = winrange/10 // 1/10
	variable filter_strength = 0.2 // 0.2, range = 0-1 (0: no filter, 1: [0.33,0.33,0.33])
	variable winXerr = 0.05
	variable winYerr
	variable flagwarp
	
	variable calc_cmm = 0 // cmm is obsolete // this matrix visualizes the beat number, but pretty inconsistent
	
	print fwarp

	if (fwarp > 0)
		if (fwarp >= 1)
			print "error: fwarp should not be >=1"
			return 0
		endif
		winYerr = fwarp
		flagwarp = 2 // 2 for freq warp in 2D wave
	elseif (fwarp == -1)
			print "Music mode: similarity calc for resonance"
			print "i.e., 1/2, 2/3, 3/4, 1, 4/3, 3/2, 2 "
		flagwarp = -1
		Make /N=(7) /O wavemusicalscale
		wavemusicalscale[0] = 1/2
		wavemusicalscale[1] = 2/3
		wavemusicalscale[2] = 3/4
		wavemusicalscale[3] = 1
		wavemusicalscale[4] = 4/3
		wavemusicalscale[5] = 3/2
		wavemusicalscale[6] = 2
		variable sizescale = DimSize(wavemusicalscale,0)
	else
		flagwarp = 0
	endif

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	listb = WaveList(wave2,";","")

	lasttime = datetime
	if (flag_alltoall)
	
		aindex=0
		a_wave = StringFromList(aindex, lista)
		b_wave = StringFromList(aindex, listb)
		Do
			wave wa = $a_wave
			wave wb = $b_wave
			print a_wave, b_wave
			xa = dimSize($a_wave,0)
			da = deltax($a_wave)
			la = leftx($a_wave)
			xb = dimSize($b_wave,0)
			db = deltax($b_wave)
			lb = leftx($b_wave)
			if (numtype(da) ==2 || numtype(db) ==2)
				print  "wave not found"
				break
			endif
			if (DimSize(wa, 1) == 0) // 1D
				flagwarp = 0
			endif
			
			winpnt = round(winrange/da)
			pntwid_post = round(winpnt*beat_postwin) // !!! very important parameter
			pntwid_pre = round(winpnt*beat_prewin)  // !!! very important parameter
			cwinpnt = round(calcrange/(wb[round(numpnts(wb)/2)]-wb[round(numpnts(wb)/2)-1]))

			// make waves
			finaldestname = "crm_" + b_wave + destname
				make /N=(xb, xb) /O $finaldestname
				wave wcrm = $finaldestname
				wcrm = 0


			if (calc_cmm)
				metermatname = "cmm_" + b_wave + destname
				variable wcmmaverage = 0
				if (wcmmaverage)
					make /N=(xb, xb) /O $metermatname
				else
					make /N=(xb, xb*2-1) /O $metermatname
					SetScale/P y -(xb-1),1,"", $metermatname
				endif
				wave wcmm = $metermatname
				wcmm = 0
			endif

				//if (strlen(destname) > 0)
				//	destwave = "RM" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
				//else
				//	destwave = "RM" + num2str(aindex) + "_" + num2str(bindex)
				//endif

			// calculate matrix					
				for (ii = 0; ii<=xb-2; ii+=1)
					if (winrange == 0)
						winpnt = round((wb[ii+1]-wb[ii]) /da)
						pntwid_post = round(winpnt*beat_postwin) // !!! very important parameter
						pntwid_pre = round(winpnt*beat_prewin)  // !!! very important parameter				
					endif
				
					pntcenter1 = x2pnt(wa, wb[ii])
					Duplicate /O /R=[pntcenter1-pntwid_pre, pntcenter1+pntwid_post] $a_wave, $wave_1
					wave w1 = $wave_1
					SetScale /P x 0, da, "s", w1 
					WaveStats/Q w1
					RMS1 = V_rms
					Len1 = numpnts(w1)
					//max1 = V_max

					ind_2 = 0
					for (jj = ii+1; jj<=ii+cwinpnt; jj+=1)
						if (jj>=xb)
							break
						endif
						if (DimSize($a_wave,1) > 1)
							// has to calculate for vertical change
						endif
						variable winpnt2 = winpnt
						variable dwin2 = da
						variable pntwid_post2 = round(winpnt2*beat_postwin) // !!! very important parameter
						variable pntwid_pre2 = round(winpnt2*beat_prewin)  // !!! very important parameter
						variable pntwinXerr = round(winpnt2*winXerr/2)
						variable pntwinXshift = round(winpnt2*errwin)
						pntcenter2 = x2pnt(wa, wb[jj])
						max2 = 0
						
						if (flagwarp == 0)
							// no time warping
							for (ll = -pntwinXshift; ll<=pntwinXshift; ll+=1)
								Duplicate /O /R=[pntcenter2-pntwid_pre+ll, pntcenter2+pntwid_post+ll] $a_wave, $wave_2
								wave w2 = $wave_2
								tmpcorrval = statscorrelation(w1,w2)
								if (max2 < tmpcorrval)
									max2 = tmpcorrval
								endif
								if (ll == pntwinXshift)
									break
								endif
							endfor
						elseif (flagwarp == 2) // only for 2D
							variable pntwinYerr = round((DimOffset(wa,1)+((DimSize(wa,1)-1)*DimDelta(wa,1)))*winYerr/DimDelta(wa,1))
							// freq warping
							for (kk = -pntwinYerr; kk<=pntwinYerr; kk+=1)
								// change X (expand -> shrink)
								for (ll = -pntwinXshift; ll<=pntwinXshift; ll+=1)
									// shift X
									Duplicate /O /R=[pntcenter2-pntwid_pre+ll, pntcenter2+pntwid_post+ll] $a_wave, $wave_2
									wave w2 = $wave_2

									// 1) this takes much time, so try 2)
									RatioFromNumber ((DimSize(wa,1)+kk)/DimSize(wa,1))
									Resample /UP=(V_numerator) /DOWN=(V_denominator) /DIM=1 $wave_2 // numerator+1 for larger window
									setScale /P y, DimOffset(wa,1), DimDelta(wa,1), $wave_2 // this is not perfect due to the rounded value kk
									Duplicate /O $wave_1, $wave_3
									wave w3 = $wave_3
									if (DimSize($wave_2,1) > DimSize($wave_3,1))
										Deletepoints /M=1 DimSize($wave_3,1), inf, w2
									else
										Deletepoints /M=1 DimSize($wave_2,1), inf, w3
									endif
								
									tmpcorrval = statscorrelation(w3,w2)
							
									if (max2 < tmpcorrval)
										max2 = tmpcorrval
									endif
									
									// TEST
									//if(kk==-pntwinYerr && ll ==0 )
									//	break
									//endif
									
								endfor
									// TEST
									//if(kk==-pntwinYerr)
									//	break
									//endif

							endfor
						elseif (flagwarp == -1) // only for 2D music
							// freq warping
							for (kk = 0; kk<sizescale; kk+=1)
								// change X (expand -> shrink)
								for (ll = -pntwinXshift; ll<=pntwinXshift; ll+=1)
									// shift X
									Duplicate /O /R=[pntcenter2-pntwid_pre+ll, pntcenter2+pntwid_post+ll] $a_wave, $wave_2
									wave w2 = $wave_2

									RatioFromNumber wavemusicalscale[kk]
									Resample /UP=(V_numerator) /DOWN=(V_denominator) /DIM=1 $wave_2 // numerator+1 for larger window
									setScale /P y, DimOffset(wa,1), DimDelta(wa,1), $wave_2 // this is not perfect due to the rounded value kk
									Duplicate /O $wave_1, $wave_3
									wave w3 = $wave_3
									if (DimSize($wave_2,1) > DimSize($wave_3,1))
										Deletepoints /M=1 DimSize($wave_3,1), inf, w2
									else
										Deletepoints /M=1 DimSize($wave_2,1), inf, w3
									endif
								
									tmpcorrval = statscorrelation(w3,w2)
							
									if (max2 < tmpcorrval)
										max2 = tmpcorrval
									endif
									
									// TEST
									//if(kk==-pntwinYerr && ll ==0 )
									//	break
									//endif
									
								endfor
									// TEST
									//if(kk==-pntwinYerr)
									//	break
									//endif

							endfor
						else
							// Xwarp might not be useful
							for (kk = -pntwinXerr; kk<=pntwinXerr; kk+=1)
								// change X (expand -> shrink)
								variable zoomcoef = (winpnt2+kk*2)/winpnt2
								for (ll = -pntwinXshift; ll<=pntwinXshift; ll+=1)
									// shift X
									Duplicate /O /R=[pntcenter2-pntwid_pre+kk+ll, pntcenter2+pntwid_post-kk+ll] $a_wave, $wave_2
									wave w2 = $wave_2

									// 1) this takes much time, so try 2)
									RatioFromNumber ((winpnt2+kk*2)/winpnt2)
									Resample /UP=(V_numerator) /DOWN=(V_denominator) $wave_2 // numerator+1 for larger window
									if (DimSize($wave_2,0) > DimSize($wave_1,0))
										Deletepoints inf, (DimSize($wave_2,0) - DimSize($wave_1,0)), w2
									else
										Deletepoints inf, (DimSize($wave_1,0) - DimSize($wave_2,0)), w1
									endif
								
									// 2)
									//Duplicate /O $wave_2, $wave_3
									//wave w3 = $wave_3
									//if (DimSize(w1,1) > 1)
									//	w2[][] = w3[p*zoomcoef][q]
									//else
									//	w2[] = w3[p*zoomcoef]
									//endif
									//if (zoomcoef > 1)
									//	// if shrink, remove the repetitive end
									//	Duplicate /O w1, w3
									//	deletepoints /M=0 round(dimsize(w3,0)/zoomcoef)-1, inf, w3
									//	deletepoints /M=0 round(dimsize(w2,0)/zoomcoef)-1, inf, w2
									//	tmpcorrval = statscorrelation(w2,w3)
									//else
										tmpcorrval = statscorrelation(w1,w2)
									//endif
									
									if (max2 < tmpcorrval)
										max2 = tmpcorrval
									endif
								endfor
							endfor
						endif
						
						wcrm[ii][jj] = max2
						
						if (calc_cmm)
							wcmm[ii][ind_2+1+xb-1] = max2
							ind_2 += 1
						endif
						
						// Crosscorrelation
						//pntcenter2 = x2pnt(wa, wb[jj])
						//Duplicate /O /R=[pntcenter2-pntwid_pre, pntcenter2+pntwid_post] $a_wave, $wave_2
						//wave w2 = $wave_2
						//SetScale /P x 0, da, "s", w2 
						//WaveStats/Q w2
						//RMS2 = V_rms
						//Len2 = numpnts(w2)
						//correlate w1, w2 // w2 is now crosscorrelogram
						//w2 /= (RMS1 * sqrt(Len1) * RMS2 * sqrt(Len2))	
						//wavestats /Q /R=(-errwin,errwin) w2
						//wcrm[ii][jj] = V_max
						//wcmm[ii][ind_2+1+xb-1] = V_max

						// for TEST
						//if (ii == 3 && jj == 20)
						//	print max2
						//	break
						//endif

						//wcrm[ii][jj] = statscorrelation(w1,w2) // this is too sensitive to phase difference
						
						
						

						// MAD	(won't work because amplitude changes)
						//if (flagMAD)
						//	variable MAD = 0
						//	for (kk = 0; kk< Len1; kk+=1)
						//		//MAD += abs(w1[kk]/max1 - w2[kk]/max2) / Len1 // normalization does not help
						//		MAD += abs(w1[kk] - w2[kk]) / Len1
						//	endfor
						//	wcrm[ii][jj] = MAD
						//endif
						
						//wn[ii,ii+winpnt-1][jj,jj+winpnt-1] += 1
					endfor
					// for TEST
					//if (ii == 3 && jj == 20)
					//	break
					//endif


					if (calc_cmm)
						ind_2 = 0					
						for (jj = ii-1; jj>=ii-cwinpnt; jj-=1)
							if (jj<0)
								break
							endif
							if (wcmmaverage)
								if (wcmm[ii][ind_2+1] == 0)
									wcmm[ii][ind_2+1] = wcrm[jj][ii]
								else
									wcmm[ii][ind_2+1] = (wcmm[ii][ind_2+1] + wcrm[jj][ii])/2
								endif
							else
								wcmm[ii][xb-1-(ind_2+1)] = wcrm[jj][ii]
							endif
							ind_2 += 1
						endfor
					endif

				endfor
				
				//return 0
				
				
				//wcrm = wcrm / wn
				
			//if (flagMAD)
			//	wavestats wcrm
			//	wcrm /= V_max
			//	wcrm = abs(1 - wcrm)
			//endif

			// filter the results
			make /N=(3,3) /O coefMatrix
			coefMatrix = 0
			coefMatrix[0][0] = filter_strength/(filter_strength*2+1)
			coefMatrix[1][1] = 1/(filter_strength*2+1)
			coefMatrix[2][2] = filter_strength/(filter_strength*2+1)
			MatrixConvolve coefMatrix, wcrm
			killwaves coefMatrix

					variable flagkill0 = 1
					if (flagkill0)
						killwaves tmpwave_1
						killwaves tmpwave_2
						if (flagwarp == -1 || flagwarp == 2)
							killwaves tmpwave_3
						endif
					endif
				

			aindex+=1
			a_wave = StringFromList(aindex, lista)
			b_wave = StringFromList(aindex, listb)
		While(strlen(a_wave)!=0)
		
		now = datetime
		print now-lasttime, " s "
	endif
End

function analyzeCorrBetweenBeats ([waveRaw, waveBeat, destname])
	// calculate correlation between parts of waveraw aligned to waveBeat
	// I think this function is not so useful
	// it now only detects neighboring parts, but if it can analyze larger, that might be better
	// also, this weighs the long correlation with log, which is not the best way to do it
	
	String waveRaw, waveBeat, destname
	if (numType(strlen(waveRaw)) == 2)	// if (wave1 == null) : so there was no input
		waveRaw="da_fwav0"; waveBeat = "pkxsRbeat_wav0"; destname="N_"
		Prompt waveRaw, "Wave raw"
		Prompt waveBeat, "Wave beat"//, popup wavelist ("*",";","")
		Prompt destname, "destname prefix"
		DoPrompt  "analyzeCorrBetweenBeats", waveRaw, waveBeat, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "analyzeCorrBetweenBeats(waveRaw=\"" + waveRaw + "\", waveBeat=\"" + waveBeat + "\", destname=\"" + destname  + "\")"
	endif
	
	string lista , listb , a_wave , b_wave
	lista = WaveList(waveRaw,";","")
	listb = WaveList(waveBeat,";","")

	variable aindex=0
	a_wave = StringFromList(aindex, lista)
	b_wave = StringFromList(aindex, listb)
	Do
		wave wa = $a_wave
		wave wb = $b_wave
		print a_wave, b_wave
		variable xa = dimSize($a_wave,0)
		variable da = deltax($a_wave)
		variable la = leftx($a_wave)
		variable xb = dimSize($b_wave,0)
		variable db = deltax($b_wave)
		variable lb = leftx($b_wave)
		if (numtype(da) ==2 || numtype(db) ==2)
			print  "wave not found"
			break
		endif

		String finaldestname = destname + a_wave
		String finaldestnameamp = destname + a_wave + "Amp"
		make /N=(0) /O $finaldestname
		make /N=(0) /O $finaldestnameamp
		wave wd = $finaldestname
		wave wda = $finaldestnameamp
		
		variable maxMeter = 20

		variable ii, jj, kk, ll
		variable inda = 0
		variable indnow = 0
		variable twarp = 0
		
		for (ii=3; ii<xb; ii+=1) // length of comparison
			if (ii < indnow)
				continue
			endif

			variable maxCorr = -1
			variable maxCorrX = 0
			
			for (jj=1; jj<=maxMeter; jj+=1)
				if (ii + jj*2 >= xb-1)
					break
				endif
				
				
				Duplicate /O /R=(wb[ii],wb[ii+jj]) wa, tmpwave_a0
				Duplicate /O /R=(wb[ii+jj],wb[ii+jj*2]) wa, tmpwave_a1


				Duplicate /O tmpwave_a1, tmpcorwave

				Correlate tmpwave_a0, tmpcorwave				


				wavestats /Q tmpwave_a0
				variable Normval = V_rms * sqrt(V_npnts)
				wavestats /Q tmpwave_a1
				tmpcorwave /= Normval * V_rms * sqrt(V_npnts)
				wavestats /Q tmpcorwave
				if (maxCorr < V_max * log(jj))
					print indnow, ii, "-", ii+jj, ",", ii+jj, "-", ii+jj*2, V_max
					maxCorr = V_max * log(jj)
					//maxCorr = V_max
					maxCorrX = jj
				endif
			endfor
			if (maxCorrX > 1 && maxCorr > 0.5)
			print inda, maxCorrX, maxCorr
				insertpoints inf, 2, wd
				insertpoints inf, 2, wda
				wd[inda] = maxCorrX
				wda[inda] = maxCorr
				inda += 1
				wd[inda] = maxCorrX
				wda[inda] = maxCorr
				inda += 1
				
				indnow = ii + maxCorrX*2
			endif
		endfor

		aindex+=1
		a_wave = StringFromList(aindex, lista)
		b_wave = StringFromList(aindex, listb)
	While(strlen(a_wave)!=0)
end

function analyzeRhythmMatrix ([wave1, wave2, threscorr, destname ])
	// you can make another function with step instead of wave2
	// destname is not necessary
	String wave1, wave2, destname
	variable threscorr
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1="crm_*";wave2="pkxsRbeat*";
		threscorr = 0.75;
		Prompt wave1, "wave matrix name"//, popup wavelist ("*",";","")
		Prompt wave2, "peakx wave name"//, popup wavelist ("*",";","")
		Prompt threscorr, "thres corr"
		prompt destname, "SUFFIX of the destination wave"
		DoPrompt  "analyzeRhythmMatrix",wave1, wave2, threscorr, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "analyzeRhythmMatrix(wave1=\"" + wave1 + "\",wave2=\"" + wave2 + "\", threscorr=" + num2str(threscorr) + ", destname=\"" + destname + "\")"
	endif	
	/// This function seems to show a bit smaller value when the window size is large
	/// probably due to the smeared effect of the sliding window (moving average degrades the high correlation of a point)
	

	string wave_1, wave_2, wave_3, destwave, finaldestname, maxname, metername
	string diaginame, diagjname, diagNname, diagcorrname, metermatname
	variable flag_alltoall=1, aindex=0, bindex=0 
	variable ii, jj, kk, ll, xa, xb, da, db, avgb, winpnt, cwinpnt, now, lasttime, ind_1, ind_2, la, lb
	variable tmpnum, win
	variable pntcenter1, pntcenter2, pntwid_pre, pntwid_post, RMS1, Len1, RMS2, Len2, max2,tmpcorrval
	//variable flagMAD = 1, max1, max2

	variable calc_cmm = 0 // cmm is obsolete

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	listb = WaveList(wave2,";","")

	lasttime = datetime
	
		aindex=0
		a_wave = StringFromList(aindex, lista)
		b_wave = StringFromList(aindex, listb)
		Do
			wave wcrm = $a_wave
			wave wb = $b_wave
			print a_wave, b_wave
			xa = dimSize($a_wave,0)
			da = deltax($a_wave)
			la = leftx($a_wave)
			xb = dimSize($b_wave,0)
			db = deltax($b_wave)
			lb = leftx($b_wave)
			if (numtype(da) ==2 || numtype(db) ==2)
				print  "wave not found"
				break
			endif

			if (calc_cmm)			
				metermatname = "cmm_" + b_wave
				wave wcmm = $metermatname
			endif

			diaginame = "cdi_" + b_wave
			diagjname = "cdj_" + b_wave
			diagNname = "cdN_" + b_wave
			diagcorrname = "cdc_" + b_wave
			metername = "cmt_" + b_wave			
			make /N=0 /O $diaginame
			make /N=0 /O $diagjname
			make /N=0 /O $diagNname
			make /N=0 /O $diagcorrname
			wave wcdi = $diaginame
			wave wcdj = $diagjname
			wave wcdN = $diagNname
			wave wcdc = $diagcorrname
			wcdi = 0
			wcdj = 0
			wcdN = 0
			wcdc = 0
			
			// analyze diag to extract pattern
			variable diagonalcorr
				for (ii=0; ii<=xb-1; ii+=1)
					Make /N=0 /O tmprootjj

					// search in column for val > threscorr as the root of diag
					for (jj=ii+1; jj<=xb-1; jj+=1)
						if (ii < jj)
							if (wcrm[ii][jj] > threscorr)
								InsertPoints numpnts(tmprootjj), 1, tmprootjj
								tmprootjj[numpnts(tmprootjj)-1] = jj
							endif
						endif
					endfor
					Duplicate /O tmprootjj, tmpNdiag
					Duplicate /O tmprootjj, tmpcorrdiag
					tmpNdiag = 0
					tmpcorrdiag = 0
					
					// determine the final diag 
					for (jj=0; jj<numpnts(tmprootjj); jj+=1)
						Do
							diagonalcorr = wcrm[ii+tmpNdiag[jj]][tmprootjj[jj]+tmpNdiag[jj]]
							if (diagonalcorr < threscorr)
								break
							endif
							tmpcorrdiag[jj] += diagonalcorr
							tmpNdiag[jj] += 1
						While(xb > tmprootjj[jj] + tmpNdiag[jj])
						tmpcorrdiag[jj] /= tmpNdiag[jj]
						// save diag if N > 1
						variable flagignore=1
						if (tmpNdiag[jj] > 1)
							flagignore=0
							for (kk=0; kk<numpnts(wcdi); kk+=1)
								if (ii - wcdi[kk] == tmprootjj[jj] - wcdj[kk] && wcdN[kk] > ii - wcdi[kk])
									// discard because it is in the same diag (start ii and jj are same, but shorter than existing diag)
									flagignore = 1
									break
								endif
							endfor
						endif
						if (flagignore==0)
							InsertPoints numpnts(wcdi), 1, wcdi
							InsertPoints numpnts(wcdj), 1, wcdj
							InsertPoints numpnts(wcdN), 1, wcdN
							InsertPoints numpnts(wcdc), 1, wcdc
							wcdi[numpnts(wcdi)] = ii
							wcdj[numpnts(wcdj)] = tmprootjj[jj]
							wcdN[numpnts(wcdN)] = tmpNdiag[jj]
							wcdc[numpnts(wcdc)] = tmpcorrdiag[jj]
						endif
					endfor
					// for TEST
					//if (ii == 10 && jj == 20)
					//	break
					//endif
				endfor
				killwaves tmprootjj
				killwaves tmpNdiag
				killwaves tmpcorrdiag
				
				
			// show figure
			if (1)
				NewImage /N=autoimage wcrm
				SetDrawEnv linethick = 2, linefgc = (65505,65505,65505), xcoord = top, ycoord = left
				DrawLine 0, 0, xb-1, xb-1 
				for (ii=0; ii<=numpnts(wcdi); ii+=1)
					SetDrawEnv linethick = 2, linefgc = (65505,10000,10000), xcoord = top, ycoord = left
					DrawLine wcdi[ii], wcdj[ii], wcdi[ii]+wcdN[ii]-1, wcdj[ii]+wcdN[ii]-1 
				endfor
			endif
			
			// calculate live average of correlation matrix (repeating sound or non-unique sound)
			Make /N=(xb) /O avg_rhythmmatrix
			avg_rhythmmatrix = 0
			for (ii=0; ii<xb; ii+=1)
				variable avgline = 0
				variable indlinepnt = 0
				for (jj=ii+1; jj<xb; jj+=1)
					avgline += wcrm[ii][jj]
					indlinepnt += 1
				endfor
				avg_rhythmmatrix[ii] = avgline / indlinepnt
			endfor

			// Calculate d_meter as the contrasting edge (suggesting that the rhythm pattern changed)
			// , usign the cmm matrix

			if (calc_cmm)
				Make /N=(xb) /O d_meter
				d_meter = 0
				for (ii=1; ii<xb; ii+=1)
					avgline = 0
					indlinepnt = 0
					for (jj=0; jj<xb*2-1; jj+=1)
						if (wcmm[ii][jj] != 0 && wcmm[ii-1][jj] != 0 )
							avgline += abs(wcmm[ii][jj] - wcmm[ii-1][jj])
							indlinepnt += 1
						endif
					endfor
					d_meter[ii] = avgline / indlinepnt
				endfor
			endif
			
			
			// project diag to beatx
			Make /N=0 /O tmpindstart
			Make /N=0 /O tmpindend
			Make /N=0 /O tmpcdcval
			for (ii=0; ii<numpnts(wcdi); ii+=1)
				InsertPoints numpnts(tmpindstart), 1, tmpindstart
				InsertPoints numpnts(tmpindend), 1, tmpindend
				InsertPoints numpnts(tmpcdcval), 1, tmpcdcval
				tmpindstart[numpnts(tmpindstart)] = wcdi[ii]
				tmpindend[numpnts(tmpindend)] = wcdi[ii] + wcdN[ii] - 1
				tmpcdcval[numpnts(tmpcdcval)] = wcdc[ii]
				//if (tmpindend[numpnts(tmpindend)] >= wcdj[ii])
				//	tmpindend[numpnts(tmpindend)] = wcdj[ii] + wcdN[ii] - 1
				//else
				InsertPoints numpnts(tmpindstart), 1, tmpindstart
				InsertPoints numpnts(tmpindend), 1, tmpindend
				InsertPoints numpnts(tmpcdcval), 1, tmpcdcval
				tmpindstart[numpnts(tmpindstart)] = wcdj[ii]
				tmpindend[numpnts(tmpindend)] = wcdj[ii] + wcdN[ii] - 1
				tmpcdcval[numpnts(tmpcdcval)] = wcdc[ii]
				//endif
			endfor

			// separate inner diag
			Make /N=0 /O tmpindstart_sep_inner
			Make /N=0 /O tmpindend_sep_inner
			Make /N=0 /O tmpcdcval_sep_inner
			variable flag_sep_inner=1
			if (flag_sep_inner)
				for (ii=0; ii<numpnts(wcdi); ii+=1)
					for (jj=ii+1; jj<numpnts(wcdi); jj+=1)
						// if range is the same
						if (tmpindstart[ii*2] == tmpindstart[jj*2] && tmpindend[ii*2+1] == tmpindend[jj*2+1] && (tmpindend[ii*2] != tmpindend[jj*2] || tmpindstart[ii*2+1] != tmpindstart[jj*2+1]))
							InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
							InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
							InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
							tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = min(tmpindend[ii*2], tmpindend[jj*2])+1
							tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = max(tmpindend[ii*2], tmpindend[jj*2])
							tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[ii*2]
							InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
							InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
							InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
							tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = min(tmpindstart[ii*2+1], tmpindstart[jj*2+1])
							tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = max(tmpindstart[ii*2+1], tmpindstart[jj*2+1])-1
							tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[ii*2+1]
							if (tmpindend[ii*2] >= tmpindstart[ii*2+1] || tmpindend[jj*2] >= tmpindstart[jj*2+1])
								continue
							endif
							// copy the original
							if (tmpindstart[ii*2+1] > tmpindend[ii*2])
								InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
								InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
								InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
								tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = tmpindstart[ii*2]
								tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = tmpindend[ii*2]
								tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[ii*2]
								InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
								InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
								InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
								tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = tmpindstart[ii*2+1]
								tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = tmpindend[ii*2+1]
								tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[ii*2+1]
							endif
							if (tmpindstart[jj*2+1] > tmpindend[jj*2])
								InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
								InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
								InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
								tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = tmpindstart[jj*2]
								tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = tmpindend[jj*2]
								tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[jj*2]
								InsertPoints numpnts(tmpindstart_sep_inner), 1, tmpindstart_sep_inner
								InsertPoints numpnts(tmpindend_sep_inner), 1, tmpindend_sep_inner
								InsertPoints numpnts(tmpcdcval_sep_inner), 1, tmpcdcval_sep_inner
								tmpindstart_sep_inner[numpnts(tmpindstart_sep_inner)] = tmpindstart[jj*2+1]
								tmpindend_sep_inner[numpnts(tmpindend_sep_inner)] = tmpindend[jj*2+1]
								tmpcdcval_sep_inner[numpnts(tmpcdcval_sep_inner)] = tmpcdcval[jj*2+1]
							endif
						endif
					endfor
				endfor
			endif

			// eliminate redundant inner points
			for (ii=numpnts(tmpindstart_sep_inner)-1; ii>=0; ii-=1)
				for (jj=ii-1; jj>=0; jj-=1)
					if (tmpindstart_sep_inner[ii] == tmpindstart_sep_inner[jj])
						if(tmpindend_sep_inner[ii] == tmpindend_sep_inner[jj] )
							if (tmpcdcval_sep_inner[ii] == tmpcdcval_sep_inner[jj])
								deletepoints ii, 1, tmpindstart_sep_inner
								deletepoints ii, 1, tmpindend_sep_inner
								deletepoints ii, 1, tmpcdcval_sep_inner
							endif
						endif
					endif
				endfor
			endfor
			
			// separate at the middle of diag (eliminate overlaps)
			variable flag_sep_mid=1
			if (flag_sep_mid)
				for (ii=0; ii<numpnts(wcdi); ii+=1)
					// separate at the onset of overlap
					if (tmpindstart[ii*2+1] <= tmpindend[ii*2])
						tmpindend[ii*2] = tmpindstart[ii*2+1]-1
						//InsertPoints numpnts(tmpindstart_sep_mid), 1, tmpindstart_sep_mid
						//InsertPoints numpnts(tmpindend_sep_mid), 1, tmpindend_sep_mid
						//InsertPoints numpnts(tmpcdcval_sep_mid), 1, tmpcdcval_sep_mid
						//tmpindstart_sep_mid[numpnts(tmpindstart_sep_mid)] = tmpindstart[ii*2]
						//tmpindend_sep_mid[numpnts(tmpindend_sep_mid)] = tmpindstart[ii*2+1]-1
						//tmpcdcval_sep_mid[numpnts(tmpcdcval_sep_mid)] = tmpcdcval[ii*2]
						//InsertPoints numpnts(tmpindstart_sep_mid), 1, tmpindstart_sep_mid
						//InsertPoints numpnts(tmpindend_sep_mid), 1, tmpindend_sep_mid
						//InsertPoints numpnts(tmpcdcval_sep_mid), 1, tmpcdcval_sep_mid
						//tmpindstart_sep_mid[numpnts(tmpindstart_sep_mid)] = tmpindstart[ii*2+1]
						//tmpindend_sep_mid[numpnts(tmpindend_sep_mid)] = tmpindend[ii*2+1]
						//tmpcdcval_sep_mid[numpnts(tmpcdcval_sep_mid)] = tmpcdcval[ii*2]
					endif
				endfor
			endif
			
			// estimate the meter (This measure is much better than the following, which is sensitive to small misalignment of the diag)
			Make /N=(xb) /O tmpmeter
			tmpmeter = 0
			variable coef_end = 0.5
			for (ii=0; ii<numpnts(wcdi); ii+=1)
				tmpmeter[tmpindstart[ii*2]] += tmpcdcval[ii*2] * (tmpindend[ii*2] - tmpindstart[ii*2] + 1)
				tmpmeter[tmpindend[ii*2]+1] += coef_end * (tmpcdcval[ii*2] * (tmpindend[ii*2] - tmpindstart[ii*2] + 1))
				tmpmeter[tmpindstart[ii*2+1]] += tmpcdcval[ii*2+1] * (tmpindend[ii*2+1] - tmpindstart[ii*2+1] + 1)
				if (tmpindend[ii*2+1]+1 < xb-1)
					tmpmeter[tmpindend[ii*2+1]+1] += coef_end * (tmpcdcval[ii*2+1] * (tmpindend[ii*2+1] - tmpindstart[ii*2+1] + 1))
				endif
				// all the range
				if (tmpindend[ii*2+1] - tmpindstart[ii*2] + 1 <= tmpindend[ii*2] - tmpindstart[ii*2] + tmpindend[ii*2+1] - tmpindstart[ii*2+1] + 2)
					tmpmeter[tmpindstart[ii*2]] += tmpcdcval[ii*2] * (tmpindend[ii*2+1] - tmpindstart[ii*2] + 1)
					if (tmpindend[ii*2+1]+1 < xb-1)
						tmpmeter[tmpindend[ii*2+1]+1] += coef_end * (tmpcdcval[ii*2] * (tmpindend[ii*2+1] - tmpindstart[ii*2] + 1))
					endif
				endif
			endfor
			

			// !!! To extract large peaks, but this is obviously not a good strategy...
			wavestats /Q tmpmeter
			tmpmeter = tmpmeter/V_max * tmpmeter/V_max
			//Duplicate /O tmpmater, r_meter
			//r_meter = d_meter*d_meter * tmpmeter //d_meter^2: increase contrast
			
			// smoothWave(wave1="tmpmeter", destname="s", sttime=0, entime=0, smoothMethod=2, endEffect=0, width=2, repetition=2, sgOrder=2, printToCmd=1)
			printPeaks(wave1="tmpmeter", thresholdType=2, threshold=0, polarity=1, sttime=-inf, entime=inf, thresholdSttime=-inf, thresholdEntime=inf, baselinetype=1, dpn=0) // > avg
			string pkxname = "pkxtmpmeter"
			wave spkx = $pkxname
			
			
			if (calc_cmm) // I am not sure if this is right....
				// threshold to extract only microrhythm
				variable avgmeter_thres = 0.8
				variable movingavgmeter = 0
			
				if (movingavgmeter)
					variable winsize0 = 6
					variable halfwinsize0 = round(winsize0/2)
					make /N=(xb - winsize0 -1) /O avgmeter
					SetScale/P x halfwinsize0,1,"", avgmeter
					make /N=(xb - winsize0 -1) /O avgmeteramp
					SetScale/P x halfwinsize0,1,"", avgmeteramp
					avgmeter = 0
					avgmeteramp = 0
			
					make /N=(xb*2-1) /O tmpavgmeter
					SetScale/P x -(xb-1),1,"", tmpavgmeter
					for (ii=halfwinsize0; ii<xb-1-halfwinsize0; ii+=1)
						variable Mtmpavgmeter = 0
						tmpavgmeter = 0
						for (jj=ii-halfwinsize0; jj<ii+halfwinsize0-1; jj+=1)
							tmpavgmeter[] += wcmm[jj][p]
							Mtmpavgmeter += 1
						endfor
						tmpavgmeter = tmpavgmeter/Mtmpavgmeter
						wavestats /Q /R=(-halfwinsize0,halfwinsize0) tmpavgmeter
						avgmeter[x2pnt(avgmeter,ii)] =  1/abs(V_maxloc)
						if (V_max >= avgmeter_thres)
							avgmeteramp[x2pnt(avgmeter,ii)] =  V_max
						else
						endif
					endfor
				else
					variable nspkx = numpnts(spkx) // based on the long meter
					make /N=(nspkx) /O avgmeter
					avgmeter = 0
				
					make /N=(xb*2-1) /O tmpavgmeter
					SetScale/P x -(xb-1),1,"", tmpavgmeter
					for (ii=0; ii<nspkx-1; ii+=1)
						variable Ntmpavgmeter = 0
						tmpavgmeter = 0
						for (jj=spkx[ii]; jj<spkx[ii+1]; jj+=1)
							tmpavgmeter[] += wcmm[jj][p]
							Ntmpavgmeter += 1
						endfor
						tmpavgmeter = tmpavgmeter/Ntmpavgmeter
						variable halftmp = (spkx[ii+1]-spkx[ii])/2
						wavestats /Q /R=(-halftmp,halftmp) tmpavgmeter
						if (V_max >= avgmeter_thres)
							avgmeter[ii] =  1/abs(V_maxloc)
						endif
					endfor
					Ntmpavgmeter = 0
					tmpavgmeter = 0
					for (jj=spkx[nspkx-1]; jj<xb; jj+=1)
						tmpavgmeter[] += wcmm[jj][p]
						Ntmpavgmeter += 1
					endfor
					tmpavgmeter = tmpavgmeter/Ntmpavgmeter
					halftmp = (xb-spkx[nspkx-1])/2
					wavestats /Q /R=(-halftmp,halftmp) tmpavgmeter
					if (V_max >= avgmeter_thres)
						avgmeter[nspkx-1] =  1/abs(V_maxloc)
					endif
				endif
			endif
				
				
			make /N=(numpnts(spkx)) /O $metername
			wave wmeter = $metername
			wmeter = 0
			for (ii=0; ii<numpnts(spkx); ii+=1)
				wmeter[ii] = wb[spkx[ii]]
			endfor
			//sort wmeter, wmeter
				
			variable flagkill0 = 0
			if (flagkill0)
				killwaves tmprootjj
				killwaves tmpNdiag
				killwaves tmpcorrdiag
				killwaves tmpindstart
				killwaves tmpindend
				killwaves tmpcdcval
				killwaves tmpindstart_sep_inner
				killwaves tmpindend_sep_inner
				killwaves tmpcdcval_sep_inner
				//killwaves tmpmeter
				killwaves pktmpmeter
				killwaves amptmpmeter
				//killwaves pkxtmpmeter
				//killwaves logicoverlap
			endif
		
		
		
		
		
			// !!!! following algorithm is not good (but I leave it for future ideas)
			// !!!! Look at the following if you want to enhance inner-rhythm



			if (0)
				

					// combine diag that spans the same range
					variable flagcase
					for (ii=0; ii<numpnts(wcdi); ii+=1)
						for (jj=ii+1; jj<numpnts(wcdi); jj+=1)
							flagcase=0
							if (tmpindstart[ii*2] == tmpindstart[jj*2] && tmpindend[ii*2+1] == tmpindend[jj*2+1])
								if (tmpindend[ii*2] - tmpindstart[ii*2] + tmpindend[ii*2+1] - tmpindstart[ii*2+1] > tmpindend[jj*2] - tmpindstart[jj*2] + tmpindend[jj*2+1] - tmpindstart[jj*2+1])
									// ii covers more in the range
										flagcase = 1
								elseif (tmpindend[ii*2] - tmpindstart[ii*2] + tmpindend[ii*2+1] - tmpindstart[ii*2+1] == tmpindend[jj*2] - tmpindstart[jj*2] + tmpindend[jj*2+1] - tmpindstart[jj*2+1])
									// ii and jj covers the same in the range
									if (tmpcdcval[ii*2] > tmpcdcval[jj*2])
										flagcase = 1
									else
										flagcase = 2
									endif
								else
									// jj covers more in the range
										flagcase = 2
								endif
							endif
							if (flagcase == 1)
								tmpindstart[jj*2] = tmpindstart[ii*2]
								tmpindend[jj*2] = tmpindend[ii*2]
								tmpcdcval[jj*2] = tmpcdcval[ii*2]
								tmpindstart[jj*2+1] = tmpindstart[ii*2+1]
								tmpindend[jj*2+1] = tmpindend[ii*2+1]
								tmpcdcval[jj*2+1] = tmpcdcval[ii*2+1]
							elseif (flagcase == 2)
								tmpindstart[ii*2] = tmpindstart[jj*2]
								tmpindend[ii*2] = tmpindend[jj*2]
								tmpcdcval[ii*2] = tmpcdcval[jj*2]
								tmpindstart[ii*2+1] = tmpindstart[jj*2+1]
								tmpindend[ii*2+1] = tmpindend[jj*2+1]
								tmpcdcval[ii*2+1] = tmpcdcval[jj*2+1]
							endif
						endfor
					endfor
				
					// eliminate same diag
					for (ii=numpnts(wcdi)-1; ii>=0; ii-=1)
						for (jj=ii-1; jj>=0; jj-=1)
							if (tmpindstart[ii*2] == tmpindstart[jj*2] && tmpindstart[ii*2+1] == tmpindstart[jj*2+1])
								if(tmpindend[ii*2] == tmpindend[jj*2] && tmpindend[ii*2+1] == tmpindend[jj*2+1])
									if (tmpcdcval[ii*2] == tmpcdcval[jj*2] && tmpcdcval[ii*2+1] == tmpcdcval[jj*2+1])
										deletepoints 2*ii, 2, tmpindstart
										deletepoints 2*ii, 2, tmpindend
										deletepoints 2*ii, 2, tmpcdcval
									endif
								endif
							endif
						endfor
					endfor
				
					// combine inner overlaps
					for (ii=numpnts(wcdi)-1; ii>=0; ii-=1)
						// separate at the onset of overlap
						if (tmpindstart[ii*2+1] <= tmpindend[ii*2])
							tmpindend[ii*2] = tmpindend[ii*2+1]
							deletepoints 2*ii+1, 1, tmpindstart
							deletepoints 2*ii+1, 1, tmpindend
							deletepoints 2*ii+1, 1, tmpcdcval
						endif
					endfor
				
					// eliminate included diag
					for (ii=numpnts(tmpindstart)-1; ii>=0; ii-=1)
						for (jj=ii-1; jj>=0; jj-=1)
							if (tmpindstart[ii] == tmpindstart[jj] && tmpindend[ii] == tmpindend[jj])
								tmpcdcval[jj] = max(tmpcdcval[ii], tmpcdcval[jj])
								deletepoints ii, 1, tmpindstart
								deletepoints ii, 1, tmpindend
								deletepoints ii, 1, tmpcdcval
							endif
						endfor
					endfor
				
				
					// combine inclusions
					//for (ii=numpnts(tmpindstart)-1; ii>=0; ii-=1)
					//	for (jj=ii-1; jj>=0; jj-=1)
					//		if (tmpindstart[ii] >= tmpindstart[jj] && tmpindend[ii] <= tmpindend[jj])
					//			deletepoints ii, 1, tmpindstart
					//			deletepoints ii, 1, tmpindend
					//			deletepoints ii, 1, tmpcdcval
					//		endif
					//	endfor
					//endfor

				
					// analyze meter (this way might not be a good idea)
					variable numoverlap = 0, stii=0, flagoverlap = 1
					Make /O /N=(numpnts(tmpindstart), 0), logicoverlap
					Make /O /N=(numpnts(tmpindstart), 1), tmplogicoverlap
					logicoverlap = 1
					tmplogicoverlap = 1
					Do
						numoverlap = 0
						for (ii=stii; ii<numpnts(tmpindstart); ii+=1)
						// numelate all the possible combination for overlaps
							for (jj=ii+1; jj<numpnts(tmpindstart); jj+=1)
								if (tmpindstart[jj] <= tmpindend[ii] && tmpindstart[ii] <= tmpindend[jj])
									numoverlap += 1
									Make /O /N=(numpnts(tmpindstart), 2^numoverlap), tmplogicoverlap
									for (kk=0; kk<2^numoverlap/2; kk+=1)
										tmplogicoverlap[][kk+2^numoverlap/2] = tmplogicoverlap[p][kk]
										tmplogicoverlap[ii][kk] = 0
										tmplogicoverlap[ii][kk+2^numoverlap/2] = 1
										tmplogicoverlap[jj][kk] = 1
										tmplogicoverlap[jj][kk+2^numoverlap/2] = 0
									endfor
								endif
							endfor
							if (ii == numpnts(tmpindstart)-1)
								flagoverlap = 0
							endif
							if (numoverlap >= 5)
								stii = ii+1
								break
							endif
						endfor

						for (ii=0; ii<dimsize(logicoverlap,1); ii+=1)
							insertpoints /M=1 inf, 1, tmplogicoverlap
							tmplogicoverlap[][inf] = logicoverlap[p][ii]
						endfor
						
						// erase overlaps with fewer coverage
						variable maxcoverage = 0
						for (ii=dimsize(tmplogicoverlap,1)-1; ii>=0; ii-=1)
							variable coverage = 0
							for (jj=0; jj<dimsize(tmplogicoverlap,0); jj+=1)
								coverage += tmplogicoverlap[jj][ii] * (tmpindend[jj] - tmpindstart[jj] + 1)
							endfor
							if (maxcoverage < coverage)
								if (maxcoverage != 0)
									deletepoints /M=1 ii+1, inf, tmplogicoverlap
								endif
								maxcoverage = coverage
							else
								deletepoints /M=1 ii, 1, tmplogicoverlap
							endif
						endfor
				
						// erase overlaps with lower correlation (tmpcdcval)
						if (dimsize(tmplogicoverlap,1) > 1)
							variable maxcorr = 0
							for (ii=dimsize(tmplogicoverlap,1)-1; ii>=0; ii-=1)
								variable corr = 0
								for (jj=0; jj<dimsize(tmplogicoverlap,0); jj+=1)
									corr += tmplogicoverlap[jj][ii] * tmpcdcval[jj]
								endfor
								if (maxcorr < corr)
									if (maxcorr != 0)
										deletepoints /M=1 ii+1, inf, tmplogicoverlap
									endif
									maxcorr = corr
								else
									deletepoints /M=1 ii, 1, tmplogicoverlap
								endif
							endfor
						endif
					
						Duplicate /O tmplogicoverlap, logicoverlap
					
					While (flagoverlap)
					killwaves tmplogicoverlap
				
					if (dimsize(logicoverlap,1) > 1)
						print " !!! potential error: there are more than 1 column in logicoverlap"
						return 0
					endif

					make /N=(sum(logicoverlap)) /O $metername
					wave wmeter = $metername
					wmeter = 0
					variable indmeter=0
					for (ii=0; ii<dimsize(logicoverlap,0); ii+=1)
						if (logicoverlap[ii][0])
							wmeter[indmeter] = wb[tmpindstart[ii]]
							indmeter += 1
						endif
					endfor
					sort wmeter, wmeter
					
					variable flag_addinnerrhythm = 0
					if (flag_addinnerrhythm)
						// eliminate redundant inner points
						for (ii=0; ii<numpnts(tmpindstart_sep_inner); ii+=1)
							insertpoints inf, 1, wmeter
							wmeter[inf] = wb[tmpindstart_sep_inner[ii]]
						endfor
						for (ii=numpnts(wmeter)-1; ii>=0; ii-=1)
							for (jj=ii-1; jj>=0; jj-=1)
								if (wmeter[ii] == wmeter[jj])
									deletepoints ii, 1, wmeter
									break
								endif
							endfor
						endfor
						sort wmeter, wmeter
					endif
				
					variable flagkill = 0
					if (flagkill)
						killwaves tmpwave_1
						killwaves tmpwave_2
						killwaves tmprootjj
						killwaves tmpNdiag
						killwaves tmpcorrdiag
						killwaves tmpindstart
						killwaves tmpindend
						killwaves tmpcdcval
						killwaves tmpindstart_sep_inner
						killwaves tmpindend_sep_inner
						killwaves tmpcdcval_sep_inner
						//killwaves logicoverlap
					endif
					
				endif

				
				

			aindex+=1
			a_wave = StringFromList(aindex, lista)
			b_wave = StringFromList(aindex, listb)
		While(strlen(a_wave)!=0)
		
		now = datetime
		print now-lasttime, " s "
End


function analyzeBeatAndRhythm ([waveMeter, waveBeat, destname])
	String waveMeter, waveBeat, destname
	if (numType(strlen(waveMeter)) == 2)	// if (wave1 == null) : so there was no input
		waveMeter="cmt_*"; waveBeat = "beat_*"; destname="N_"
		Prompt waveMeter, "Wave meter"
		Prompt waveBeat, "Wave beat"//, popup wavelist ("*",";","")
		Prompt destname, "destname prefix"
		DoPrompt  "analyzeBeatAndRhythm", waveMeter, waveBeat, destname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "analyzeBeatAndRhythm(waveMeter=\"" + waveMeter + "\", waveBeat=\"" + waveBeat + "\", destname=\"" + destname  + "\")"
	endif
	
	string lista , listb , a_wave , b_wave
	lista = WaveList(waveBeat,";","")
	listb = WaveList(waveMeter,";","")

	variable aindex=0
	a_wave = StringFromList(aindex, lista)
	b_wave = StringFromList(aindex, listb)
	Do
		wave wa = $a_wave
		wave wb = $b_wave
		print a_wave, b_wave
		variable xa = dimSize($a_wave,0)
		variable da = deltax($a_wave)
		variable la = leftx($a_wave)
		variable xb = dimSize($b_wave,0)
		variable db = deltax($b_wave)
		variable lb = leftx($b_wave)
		if (numtype(da) ==2 || numtype(db) ==2)
			print  "wave not found"
			break
		endif

		String finaldestname = destname + b_wave
		make /N=(0) /O $finaldestname
		wave wd = $finaldestname

		variable ii, jj
		for (ii=0; ii<xa; ii+=1)
			variable Nbeat=0
			for (jj=0; jj<xb; jj+=1)
				if(wa[ii] == wb[jj])
					insertpoints inf, 1, wd
					wd[ii] = Nbeat
				else
					Nbeat += 1
				endif
			endfor
		endfor
		insertpoints inf, 1, wd
		wd[ii] = Nbeat
		

		aindex+=1
		a_wave = StringFromList(aindex, lista)
		b_wave = StringFromList(aindex, listb)
	While(strlen(a_wave)!=0)
end

