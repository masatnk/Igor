#pragma rtGlobals=1		// Use modern global access method.

menu "tanakaMusic"
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
	"playPartOfSound"
	"makeSineMusic"
	"drawRhythmDiagram"
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