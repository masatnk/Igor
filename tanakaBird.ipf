#pragma rtGlobals=1		// Use modern global access method.

menu "tanakaBird"
	submenu "song extraction"
		"boutCount"
		"boutToSong"
		"calcSongPattern"
		"extractSongPattern"
		"makeONOFFwave"
		"discernSongs"
	end
	submenu "sequence"
		"findSongSequence"
		"replaceSongSequence"
		"replaceSongSeqToProb"
		"makeTransitionMatrix"
		"drawTransitionDiagram"
	end
	submenu "song statistics"
		"calcSongDuration"
		"calcConsistencyScore"
		"calcSequenceLinearity"
		"calcWienerEntropy"
	end
end

function boutCount ([thresInt, type, waveT, waveON, filenamewave, waveDur, waveClass])
	String waveT, waveON, filenamewave, waveDur, waveClass
	Variable thresInt, type

	if (numType(strlen(waveClass)) == 2)	// if (wave1 == null) : so there was no input
		waveClass = "syllable_classified"; waveT = "syllable_time"; waveON = "syllable_start_on"; filenamewave="syllable_file_name"; waveDur="syllable_duration";
		thresInt = 500; type = 1;
		Prompt thresInt, "interval for bout separation (ms)"
		Prompt type, "time wave exists? 0/1"
		Prompt waveT, "If 1, time wave"//, popup wavelist ("*",";","")
		Prompt waveON, "If 0, start_on wave"//, popup wavelist ("*",";","")
		Prompt filenamewave, "filename wave"
		Prompt waveDur, "Syllable duration wave"//, popup wavelist ("*",";","")
		Prompt waveClass, "Syllable classified wave"//, popup wavelist ("*",";","")
		DoPrompt  "boutCount", thresInt, type, waveT, waveON, filenamewave, waveDur, waveClass
		if (V_Flag)	// User canceled
			return -1
		endif
		print "boutCount(thresInt=" + num2str(thresInt) + ", type=" + num2str(type) + ", waveT=\"" + waveT + "\", waveON=\"" + waveON + "\", filenamewave=\"" + filenamewave  + "\", waveDur=\"" + waveDur + "\", waveClass=\"" + waveClass + "\")"
	endif

	string bout_wave, destname, listBout, lastfile, targetfolder
	variable windex=0, nBout = 0, nindex = 0, bindex = 0, flagKill = 0, vocalDur = 0, flagBout=0, flagLastBout=0
	variable sttime, entime, enpnt, interval_lap = 0, nTotalVocal=0, nVocal
	wave class = $waveClass
	wave dur = $waveDur
	nVocal = numpnts(class)

	string boutCount_onset = "boutOnset_n"
	string boutCount_offset = "boutOffset_n"
	string vocal_file = "boutFileName"
		Make  /O /N=(nVocal) $boutCount_onset
		Make  /O /N=(nVocal) $boutCount_offset
		Make  /O /T /N=(nVocal) $vocal_file
		wave bouton = $boutCount_onset
		wave boutoff = $boutCount_offset
		wave /T wfile = $filenamewave		
		wave /T wvfile = $vocal_file
		bouton = 0
		boutoff = 0

	entime = -1
	flagBout = 0
	nindex = 0
	bindex = 0
	if (type == 1)
		wave t = $waveT
		Do
			if (entime == -1)
				bouton[bindex] = nindex
				wvfile[bindex] = wfile[nindex]
			else
				if (t[nindex] - entime > thresInt)
					if (flagBout == 1)
						wvfile[bindex+1] = wfile[nindex]
						bouton[bindex+1] = nindex
						boutoff[bindex] = enpnt
						bindex += 1
						flagBout = 0
					else
						bouton[bindex] = nindex
					endif
				endif
			endif
			if (class[nindex] != 9 && class[nindex] != 0)
				nTotalVocal += 1
				flagBout = 1
			endif
			enpnt = nindex
			entime = t[nindex] + dur[nindex]
			nindex += 1
		While (nindex < nVocal)
	else
		wave on = $waveON
		Do
			if (entime == -1)
	 			bouton[bindex] = nindex
				wvfile[bindex] = wfile[nindex]
			else
				if (stringmatch(wfile[nindex], lastfile))
					if (on[nindex] - entime > thresInt)
						if (flagBout == 1)
							wvfile[bindex+1] = wfile[nindex]
							bouton[bindex+1] = nindex
							boutoff[bindex] = enpnt
							bindex += 1
							flagBout = 0
						else
							bouton[bindex] = nindex
						endif
					endif
				else
					wvfile[bindex+1] = wfile[nindex]
					bouton[bindex+1] = nindex
					boutoff[bindex] = enpnt
					bindex += 1
					flagBout = 0
				endif
			endif
			if (class[nindex] != 9 && class[nindex] != 0)
				nTotalVocal += 1
				flagBout = 1
			endif
			enpnt = nindex
			entime = on[nindex] + dur[nindex]
			lastfile = wfile[nindex]
			nindex += 1
		While (nindex < nVocal)
	endif
	if (flagBout == 1)
		boutoff[bindex] = enpnt
	else
		bindex -= 1
	endif	
	nBout = bindex + 1	
	Redimension /N=(nBout) bouton
	Redimension /N=(nBout) boutoff
	Redimension /N=(nBout) wvfile
	
	string boutCount_onset_t = "boutOnset_t"
	string boutCount_offset_t = "boutOffset_t"
	string boutDur = "boutDuration"
	Duplicate /O bouton, $boutCount_onset_t
	Duplicate /O boutoff, $boutCount_offset_t
	Duplicate /O boutoff, $boutDur
	wave bouton_t = $boutCount_onset_t
	wave boutoff_t = $boutCount_offset_t
	wave boutd = $boutDur
	bouton_t[] = t[bouton[p]]
	boutoff_t[] = t[boutoff[p]] + dur[boutoff[p]]
	boutd[] = boutoff_t[p] - bouton_t[p]
	
	nindex = 0
	Do
		destname = "bout_" + num2str(nindex)
		Duplicate /O /R=(bouton[nindex], boutoff[nindex]) class, $destname
		listBout = WaveList("boutCount_bout*",";","")
		nindex += 1
	While (nindex < nBout)

	print "total vocalization : ", nTotalVocal
	print "total bouts : ", num2str(nBout)
	
End

function boutToSong ([waveBout, numVocal, sylList, exList])
	String waveBout, sylList, exList
	Variable numVocal
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "bout_*"; sylList = "2;3;4"; exList = "0;9"; numVocal = 3;
		Prompt waveBout, "Wave bout name"//, popup wavelist ("*",";","")
		Prompt numVocal, "N vocal required for song"//, popup wavelist ("*",";","")
		Prompt sylList "syllable list required for song"//, popup wavelist ("*",";","")
		Prompt exList "syllable list to be excluded"//, popup wavelist ("*",";","")
		DoPrompt  "boutToSong", waveBout, numVocal, sylList, exList
		if (V_Flag)	// User canceled
			return -1
		endif
		print "boutToSong(waveBout=\"" + waveBout + "\", numVocal=" + num2str(numVocal) +  ", sylList=\"" + sylList +  "\", exList=\"" + exList + "\")"
	endif
	
	string listBout, bout_wave, destname, targetFolder
	string sylTemp
	string wave_onset = "boutOnset_n"
	string wave_offset = "boutOffset_n"
	string wave_onset_t = "boutOnset_t"
	string wave_offset_t = "boutOffset_t"
	string wave_dur = "boutDuration"
	string vocal_filename = "boutFileName"
	wave on = $wave_onset
	wave off = $wave_offset
	wave on_t = $wave_onset_t
	wave off_t = $wave_offset_t
	wave dur = $wave_dur
	wave /T vocalfile = $vocal_filename
	string wavesong_onset = "songOnset_n"
		Duplicate /O $wave_onset, $wavesong_onset
		wave songon = $wavesong_onset
	string wavesong_offset = "songOffset_n"
		Duplicate /O $wave_offset, $wavesong_offset
		wave songoff = $wavesong_offset
	string wavesong_onset_t = "songOnset_t"
		Duplicate /O $wave_onset_t, $wavesong_onset_t
		wave songon_t = $wavesong_onset_t
	string wavesong_offset_t = "songOffset_t"
		Duplicate /O $wave_offset_t, $wavesong_offset_t
		wave songoff_t = $wavesong_offset_t
	string wavesong_dur = "songDuration"
		Duplicate /O $wave_dur, $wavesong_dur
		wave songdur = $wavesong_dur
	string song_filename = "songFileName"
		Duplicate /O $vocal_filename, $song_filename
		wave /T songfile = $song_filename
	listBout = WaveList(waveBout,";","")
	variable windex, sindex, dindex, flagTemp, flagNotEx
	dindex = 0
	windex = 0
	bout_wave = StringFromList(windex, listBout)
	Do
		flagTemp = 0
		flagNotEx = 0
		if (numpnts($bout_wave) >= numVocal)
			sindex=0
			sylTemp = StringFromList(sindex, sylList)
			Do
				FindValue /V=(str2num(sylTemp)) /Z $bout_wave
				if (V_value != -1)
					flagTemp = 1
					break
				endif
				sindex += 1
				sylTemp = StringFromList(sindex, sylList)	
			While(strlen(sylTemp)!=0)
			sindex=0
			sylTemp = StringFromList(sindex, exList)
			Do
				FindValue /V=(str2num(sylTemp)) /Z $bout_wave
				if (V_value != -1)
					flagNotEx = 0
					break
				endif
				flagNotEx = 1
				sindex += 1
				sylTemp = StringFromList(sindex, exList)
			While(strlen(sylTemp)!=0)
			if (flagTemp && flagNotEx)
				destname = "song_" + bout_wave + "_" + num2str(dindex)
				Duplicate /O $bout_wave, $destname
				songon[dindex] = on[windex]
				songoff[dindex] = off[windex]
				songon_t[dindex] = on_t[windex]
				songoff_t[dindex] = off_t[windex]
				songdur[dindex] = dur[windex]
				songfile[dindex] = vocalfile[windex]
				dindex += 1
			endif
		endif
		windex+=1
		bout_wave = StringFromList(windex, listBout)
	While(strlen(bout_wave)!=0)
	Redimension /N=(dindex) songon
	Redimension /N=(dindex) songoff
	Redimension /N=(dindex) songon_t
	Redimension /N=(dindex) songoff_t
	Redimension /N=(dindex) songdur
	Redimension /N=(dindex) songfile
	
	wavestats songDuration
	
	targetFolder = "bouts"
		killDataFolder /Z $targetFolder
		newDataFolder $targetFolder
	listBout = WaveList("bout*",";","")
	windex = 0
	bout_wave = StringFromList(windex, listBout)
	Do
		moveWave $bout_wave, $(":" + targetFolder + ":")
		windex += 1
		bout_wave = StringFromList(windex, listBout)
	While(strlen(bout_wave)!=0)
	
	targetFolder = "songs"
		killDataFolder /Z $targetFolder
		newDataFolder $targetFolder
	listBout = WaveList("song*",";","")
	windex = 0
	bout_wave = StringFromList(windex, listBout)
	Do
		moveWave $bout_wave, $(":" + targetFolder + ":")
		windex += 1
		bout_wave = StringFromList(windex, listBout)
	While(strlen(bout_wave)!=0)
	
	print "total song : ", dindex
End


function calcSongPattern ([waveBout])
	String waveBout
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "song_bout_*";
		Prompt waveBout, "Wave song name"//, popup wavelist ("*",";","")
		DoPrompt  "calcSongPattern", waveBout
		if (V_Flag)	// User canceled
			return -1
		endif
		print "calcSongPattern(waveBout=\"" + waveBout + "\")"
	endif
	string boutCountList, destname, bout_wave, listBout
	string listPattern, pattern_wave
	variable windex, nBout, bindex, pindex, flagKill=0
	boutCountList = "patternCountList"
	string waveSongOnset = "songOnset_n"
	nBout = numpnts($waveSongOnset)
		Make /O /N=(nBout) $boutCountList
		wave wave_boutCountList = $boutCountList
		wave_boutCountList = 0

	listBout = WaveList(waveBout,";","")
	pindex = 0
	windex = 0
	bout_wave = StringFromList(windex, listBout)
	Do
		wave bout = $bout_wave
		destname = "songPattern_" + num2str(pindex)
		Duplicate /O $bout_wave, $destname
		wave destwave = $destname
		bindex = 0
		flagKill = 0
		listPattern = WaveList("songPattern_*",";","")
		pattern_wave = StringFromList(bindex, listPattern)
		Do
			wave pwave = $pattern_wave
			if (!(stringmatch(destname, pattern_wave)) && equalwaves(destwave, pwave, 1))
				killwaves $destname
				wave_boutCountList[bindex] += 1
				flagKill = 1
				break
			endif
			bindex += 1
			pattern_wave = StringFromList(bindex, listPattern)
		While (strlen(pattern_wave)!=0)
		if (!flagKill)
			wave_boutCountList[pindex] = 1
			pindex += 1
		endif
		windex+=1
		bout_wave = StringFromList(windex, listBout)
	While(strlen(bout_wave)!=0)
	Redimension /N=(pindex) wave_boutCountList
end


function extractSongPattern ([waveBout, maxNotes])
	String waveBout
	Variable maxNotes
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "song_bout*";
		maxNotes = 20
		Prompt waveBout, "Wave song name"//, popup wavelist ("*",";","")
		Prompt maxNotes, "max notes"
		DoPrompt  "extractSongPattern", waveBout, maxNotes
		if (V_Flag)	// User canceled
			return -1
		endif
		print "extractSongPattern(waveBout=\"" + waveBout + "\", maxNotes=" + num2str(maxNotes) + ")"
	endif
	
	string lista, name_a, targetFolder, targetwave, textP, listP, nPname, nPlabel, nPrname, nPpname, last_nPpname, minus_nPpname
	string stPname, enPname, stPlabel, enPlabel, liststP, listenP
	variable windex, nindex, length_a, nPall, col_a, length_ph, last_ph_onset, pindex, tindex, flagEnd, sylAll, nwave, stindex, enindex, stN, enN, listnum
	lista = WaveList(waveBout,";","")
	length_ph = 1
	Do
		listP = ""; liststP = "", listenP = ""
		nPname = "nPattern_" + num2str(length_ph) + "notes"
		nPrname = "nPattern_" + num2str(length_ph) + "notes_ratio"
		nPpname = "nPattern_" + num2str(length_ph) + "notes_propotion"
		last_nPpname = "last_nP_" + num2str(length_ph) + "notes_propotion"
		minus_nPpname = "minus_nP_" + num2str(length_ph) + "notes_propotion"
		stPname = "stPattern_" + num2str(length_ph) + "notes_ratio"
		enPname = "enPattern_" + num2str(length_ph) + "notes_ratio"
		nPlabel = "nPattern_" + num2str(length_ph) + "notes_label"
		stPlabel = "stPattern_" + num2str(length_ph) + "notes_label"
		enPlabel = "enPattern_" + num2str(length_ph) + "notes_label"
		make /O /N=0 $nPname
		make /O /N=0 $last_nPpname
		make /O /N=0 $minus_nPpname
		make /O /N=0 $stPname
		make /O /N=0 $enPname
		make /T /O /N=0 $nPlabel
		make /T /O /N=0 $stPlabel
		make /T /O /N=0 $enPlabel
		wave nP = $nPname
		wave last_nPp = $last_nPpname
		wave minus_nPp = $minus_nPpname
		wave stP = $stPname
		wave enP = $enPname
		wave /T nPl = $nPlabel
		wave /T stPl = $stPlabel
		wave /T enPl = $enPlabel
		targetFolder = "pattern_" + num2str(length_ph) + "notes"
		killDataFolder /Z $targetFolder
		newDataFolder $targetFolder
		stN = 0
		enN = 0
		nPall = 0
		pindex = 0
		stindex = 0
		enindex = 0
		windex=0
		name_a = StringFromList(windex, lista)
		Do
			wave wave_a = $name_a
			length_a = DimSize(wave_a, 0)
			if (length_ph == 1)
				sylAll += length_a
			endif
			last_ph_onset = length_a - length_ph + 1
			last_nPp = 0
			flagEnd = 0
			nindex = 0
			Do
				if ((nindex + length_ph) > length_a)
					flagEnd = 1
					break
				endif
				textP = ""
				tindex=0
				Do
					textP += num2str(wave_a[nindex+tindex])
					tindex += 1
				While(tindex < length_ph)
				listnum = whichListItem(textP, listP, ";", 0) 
				if (listnum == -1)
					targetwave = "pattern_" + num2str(length_ph) + "notes_" + num2str(pindex)
					Duplicate /O /R=[nindex, (nindex+length_ph-1)] wave_a, $targetwave			
					insertPoints inf,1,nP
					nP[pindex] = 1
					insertPoints inf,1,nPl
					nPl[pindex] = textP
					insertPoints inf,1,last_nPp
					last_nPp[pindex] = nindex
					insertPoints inf,1,minus_nPp
					minus_nPp[pindex] = 0
					listP += textP + ";"
					pindex += 1
					moveWave $targetwave, $(":" + targetFolder + ":")
//					print textP, nP
				else
//					print textP, listP, whichListItem(textP, listP, ";", 0)
					nP[listnum] += 1
					if (nindex >= length_ph && nindex < last_nPp[listnum] + length_ph)
						minus_nPp[listnum] += 1
					else
						last_nPp[listnum] = nindex
					endif
				endif
				listnum = whichListItem(textP, liststP, ";", 0) 
				if (nindex == 0)
					if (listnum== -1)
						insertPoints inf,1,stP
						stP[stindex] = 1
						insertPoints inf,1,stPl
						stPl[stindex] = textP
						liststP += textP + ";"
						stindex += 1
					else
						stP[listnum] += 1
					endif
					stN += 1
				endif
				listnum = whichListItem(textP, listenP, ";", 0) 
				if (nindex + 1 == last_ph_onset)
					if (listnum == -1)
						insertPoints inf,1,enP
						enP[enindex] = 1
						insertPoints inf,1,enPl
						enPl[enindex] = textP
						listenP += textP + ";"
						enindex += 1
					else
						enP[listnum] += 1
					endif
					enN += 1
				endif
				nPall += 1
				nindex += 1
			while(nindex < last_ph_onset)
			windex+=1
			name_a = StringFromList(windex, lista)
		While(strlen(name_a)!=0)
		Duplicate /O nP, $nPrname
		Duplicate /O nP, $nPpname
		wave nPr = $nPrname
		wave nPp = $nPpname
		nPr /= nPall
		nPp = (nPp - minus_nPp) / sylAll * length_ph
		stP /= stN
		enP /= enN
		Killwaves last_nPp
		Killwaves minus_nPp
		sort /R nP, nPl, nPr, nPp
		sort /R nP, nP
		sort /R stP, stPl
		sort /R stP, stP
		sort /R enP, enPl
		sort /R enP, enP
		print "\t", length_ph , " Notes, ", pindex, " patterns : ", listP
		moveWave nP, $(":" + targetFolder + ":")
		moveWave nPr, $(":" + targetFolder + ":")
		moveWave nPp, $(":" + targetFolder + ":")
		moveWave nPl, $(":" + targetFolder + ":")
		moveWave stP, $(":" + targetFolder + ":")
		moveWave stPl, $(":" + targetFolder + ":")
		moveWave enP, $(":" + targetFolder + ":")
		moveWave enPl, $(":" + targetFolder + ":")
		length_ph += 1
	While (length_ph <= maxNotes)
	length_ph = 1
	Do
			targetFolder = "pattern_" + num2str(length_ph) + "notes"
			nPpname = "nPattern_" + num2str(length_ph) + "notes_propotion"
			if (length_ph == 1)
				setDataFolder $(":" + targetFolder + ":")
				Display $nPpname
			else
				setDataFolder $("::" + targetFolder + ":")
				Appendtograph $nPpname
			endif
			length_ph += 1
	While (length_ph <= maxNotes)
	setTracesColor(graphname="", waves="*", type=0, stred=65535, stgrn=0, stblu=0, enred=0, engrn=0, enblu=65535)
end


function drawTransitionDiagram ([waveBout, nSyl])
	String waveBout
	variable nSyl
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "song_bout*";
		nSyl = 8;
		Prompt waveBout, "Wave song name"//, popup wavelist ("*",";","")
		Prompt nSyl, "Number of syllables"//, popup wavelist ("*",";","")
		DoPrompt  "drawTransitionDiagram", waveBout, nSyl
		if (V_Flag)	// User canceled
			return -1
		endif
		print "drawTransitionDiagram(waveBout=\"" + waveBout + "\", Nsyl=" + num2str(nSyl) + ")"
	endif
	
	string lista, name_a, xname, yname, sxname, syname, txname, tyname, end_xname, end_yname, st_xname, st_yname, trxname, tryname, lxname, lyname
	variable windex, nindex, length_a, last_n, wred, wgrn, wblu, nColor, nnoise, preX, preY, postX, postY, snoise, linethickness, preSyl, postSyl, ssnoise
	// replace syllables
	variable repSylfrom1=98, repSylto1=95
	variable repSylfrom2=97, repSylto2=91
	variable repSylfrom3=98, repSylto3=98
	variable repSylfrom4=99, repSylto4=99
	variable repSylfrom5=100, repSylto5=100
	// for Bezier
	variable useBezier = 0
	variable txpre, typre, lxpost, lypost
	xname = "coord_x"
	yname = "coord_y"
	end_xname = "coord_x_end"
	end_yname = "coord_y_end"
	st_xname = "coord_x_st"
	st_yname = "coord_y_st"
	sxname = "coord_x_small"
	syname = "coord_y_small"
	txname = "coord_x_text"
	tyname = "coord_y_text"
	trxname = "coord_x_trail"
	tryname = "coord_y_trail"
	lxname = "coord_x_lead"
	lyname = "coord_y_lead"
	if (nSyl < 0)
		abort
	endif
	nnoise=0.015		// 0.025	
	snoise = 0.005	// 0.015
	ssnoise = 0.005	// 0.012
	linethickness = 0.3
	Display as "Transition Diagram"
	Make /N=(nSyl) /O $xname
	Make /N=(nSyl) /O $yname
	Make /N=(nSyl) /O $end_xname
	Make /N=(nSyl) /O $end_yname
	Make /N=(nSyl) /O $st_xname
	Make /N=(nSyl) /O $st_yname
	Make /N=(nSyl) /O $sxname
	Make /N=(nSyl) /O $syname
	Make /N=(nSyl) /O $txname
	Make /N=(nSyl) /O $tyname
	Make /N=(nSyl) /O $trxname
	Make /N=(nSyl) /O $tryname
	Make /N=(nSyl) /O $lxname
	Make /N=(nSyl) /O $lyname
	wave xwave = $xname
	wave ywave = $yname
	wave end_xwave = $end_xname
	wave end_ywave = $end_yname
	wave st_xwave = $st_xname
	wave st_ywave = $st_yname
	wave sxwave = $sxname
	wave sywave = $syname
	wave txwave = $txname
	wave tywave = $tyname
	wave trxwave = $trxname
	wave trywave = $tryname
	wave lxwave = $lxname
	wave lywave = $lyname
	nindex=0
	Do
		xwave[nindex] = cos(Pi+2*Pi/nSyl*nindex) / 4 + 0.5			// syl X radium = 1/4 from the center
		ywave[nindex] = sin(Pi+2*Pi/nSyl*nindex) / 4 + 0.5			// syl Y radium = 1/4 from the center
		end_xwave[nindex] = cos(Pi+2*Pi/nSyl*nindex) / 2.5 + 0.5		// end X (gray) radium = 1/2.5 from the center
		end_ywave[nindex] = sin(Pi+2*Pi/nSyl*nindex) / 2.5 + 0.5		// end Y (gray) radium = 1/2.5 from the center
		st_xwave[nindex] = cos(Pi+2*Pi/nSyl*nindex) / 2.2 + 0.5		// start X (colored) radium = 1/2.2 from the center
		st_ywave[nindex] = sin(Pi+2*Pi/nSyl*nindex) / 2.2 + 0.5		// start Y (colored) radium = 1/2.2 from the center
		sxwave[nindex] = cos(Pi+2*Pi/nSyl*nindex) / 20				// small circle depending on pre syl; radium = 1/20
		sywave[nindex] = sin(Pi+2*Pi/nSyl*nindex) / 20				// small circle depending on pre syl; radium = 1/20
		trxwave[nindex] = cos(Pi+2*Pi/nSyl*nindex) / 8				// trailing curs for Bezier; radium = 1/8
		trywave[nindex] = sin(Pi+2*Pi/nSyl*nindex) / 8				// trailing curs for Bezier; radium = 1/8
		nindex += 1
	While (nindex < nSyl)
	lista = WaveList(waveBout,";","")
	windex=0
	name_a = StringFromList(windex, lista)
	Do
		wave wave_a = $name_a
		length_a = DimSize(wave_a, 0)
		last_n = length_a - 2
		nindex = 0
		// replacement of labeling
		if (wave_a[nindex] == repSylfrom1)
			preSyl = repSylto1
		elseif ( wave_a[nindex] == repSylfrom2)
			preSyl = repSylto2
		elseif ( wave_a[nindex] == repSylfrom3)
			preSyl = repSylto3
		elseif ( wave_a[nindex] == repSylfrom4)
			preSyl = repSylto4
		elseif ( wave_a[nindex] == repSylfrom5)
			preSyl = repSylto5
		else
			preSyl = wave_a[nindex]
		endif
		if (preSyl <= nSyl)
			preX = xwave[preSyl-1] + sxwave[preSyl-1]*1.4 +gnoise(snoise)
			preY = ywave[preSyl-1] + sywave[preSyl-1]*1.4 + gnoise(snoise)
			wred = 50000
			wgrn = 50000
			wblu = 50000
			setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness
			DrawLine st_xwave[preSyl-1], st_ywave[preSyl-1], preX, preY
		else
			preX = 0
			preY = 0
		endif
		Do
			// replacement of labeling
			if (wave_a[nindex] == repSylfrom1)
				preSyl = repSylto1
			elseif ( wave_a[nindex] == repSylfrom2)
				preSyl = repSylto2
			elseif ( wave_a[nindex] == repSylfrom3)
				preSyl = repSylto3
			elseif ( wave_a[nindex] == repSylfrom4)
				preSyl = repSylto4
			elseif ( wave_a[nindex] == repSylfrom5)
				preSyl = repSylto5
			else
				preSyl = wave_a[nindex]
			endif
			// replacement of labeling
			if (wave_a[nindex+1] == repSylfrom1)
				postSyl = repSylto1
			elseif (wave_a[nindex+1] == repSylfrom2)
				postSyl = repSylto2
			elseif (wave_a[nindex+1] == repSylfrom3)
				postSyl = repSylto3
			elseif ( wave_a[nindex+1] == repSylfrom4)
				postSyl = repSylto4
			elseif ( wave_a[nindex+1] == repSylfrom5)
				postSyl = repSylto5
			else
				postSyl = wave_a[nindex+1]
			endif
			if (preSyl > nSyl)
				nindex += 1
				continue
			elseif(preX == 0 && preY == 0)
				preX = xwave[preSyl-1]+gnoise(snoise) + sxwave[preSyl-1]
				preY = ywave[preSyl-1]+gnoise(snoise) + sywave[preSyl-1]
			endif
			
			nColor = preSyl-1
			if (nColor <= nSyl*1/3)
				wred = 65535
				wgrn = 60000 * nColor / ((nSyl) * 1/3)
				wblu = 0
			elseif (nColor <= nSyl*1/2)
				wred = 65535 - 65535 *  (nColor - (nSyl) * 1/3) / ((nSyl) * 1/6)
				wgrn = 60000
				wblu = 0
			elseif (nColor <= nSyl*2/3)
				wred = 0
				wgrn = 65535 - 65535 *  (nColor - (nSyl) * 1/2) / ((nSyl) * 1/6)
				wblu = 60000 * (nColor - (nSyl) * 1/2) / ((nSyl) * 1/6)
			elseif (nColor <= nSyl*5/6)
				wred = 19456 * (nColor - (nSyl) * 2/3) / ((nSyl) * 1/6)
				wgrn = 0
				wblu = 65535 - 33535 *  (nColor - (nSyl) * 2/3) / ((nSyl) * 1/6)
			else
				wred = 19456 + 17264 * (nColor - (nSyl) * 5/6) / ((nSyl) * 1/6)
				wgrn = 0
				wblu = 33535 + 32000 * (nColor - (nSyl) * 5/6) / ((nSyl) * 1/6)
			endif
			if (postSyl <= nSyl)
				if (preSyl == postSyl)
					wred = (65535 - wred) *1/3 + wred 
					wgrn = (65535 - wgrn) *1/4 + wgrn 
					wblu = (65535 - wblu)  *1/4 + wblu 
				endif
				if (preSyl == postSyl && useBezier)
					setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness
					postX = xwave[postSyl-1]+gnoise(snoise) + sxwave[postSyl-1]
					postY = ywave[postSyl-1]+gnoise(snoise) + sywave[postSyl-1]
					txpre =  (preX+postX)/2 + trxwave[mod(postSyl-1 - round(nSyl/8)+nSyl,nSyl)] + gnoise(ssnoise)
					typre =  (preY+postY)/2 + trywave[mod(postSyl-1 - round(nSyl/8)+nSyl,nSyl)] + gnoise(ssnoise)
					lxpost =  (preX+postX)/2 + trxwave[mod(postSyl-1 + round(nSyl/8)+nSyl,nSyl)] + gnoise(ssnoise)
					lypost =  (preY+postY)/2 + trywave[mod(postSyl-1 + round(nSyl/8)+nSyl,nSyl)] + gnoise(ssnoise)
					setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness, fillpat=0
					DrawBezier preX, preY, 1, 1, {preX, preY, txpre, typre,     lxpost, lypost, postX, postY}
//				drawtext txpre, typre, "+"
//				drawtext lxpost, lypost, "-"
//				DrawOval xwave[postSyl-1]+sxwave[postSyl-1]+gnoise(0.005)-0.03, ywave[postSyl-1]+sywave[postSyl-1]+gnoise(0.005)-0.03, xwave[postSyl-1]+sxwave[postSyl-1]+gnoise(0.005)+0.03, ywave[postSyl-1]+sywave[postSyl-1]+gnoise(0.005)+0.03
				else
					setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness
					postX = xwave[postSyl-1]+gnoise(snoise) + sxwave[preSyl-1]
					postY = ywave[postSyl-1]+gnoise(snoise) + sywave[preSyl-1]
		//			postX = xwave[wave_a[nindex+1]-1]+enoise(nnoise)
		//			postY = ywave[wave_a[nindex+1]-1]+enoise(nnoise)
					DrawLine preX, preY, postX, postY

		//			DrawLine xwave[wave_a[nindex]-1]+enoise(nnoise), ywave[wave_a[nindex]-1]+enoise(nnoise), xwave[wave_a[nindex+1]-1]+enoise(nnoise), ywave[wave_a[nindex+1]-1]+enoise(nnoise)
				endif
				preX = postX
				preY = postY
			else
				preX = 0
				preY = 0
			endif

//			DrawLine xwave[wave_a[nindex]-1], ywave[wave_a[nindex]-1], xwave[wave_a[nindex+1]-1], ywave[wave_a[nindex+1]-1]
			nindex += 1
		While (nindex < last_n)		

		// last syllable
		// replacement of labeling
		if (wave_a[nindex] == repSylfrom1)
			preSyl = repSylto1
		elseif ( wave_a[nindex] == repSylfrom2)
			preSyl = repSylto2
		elseif ( wave_a[nindex] == repSylfrom3)
			preSyl = repSylto3
		elseif ( wave_a[nindex] == repSylfrom4)
			preSyl = repSylto4
		elseif ( wave_a[nindex] == repSylfrom5)
			preSyl = repSylto5
		else
			preSyl = wave_a[nindex]
		endif

		nColor = preSyl-1
		if (nColor <= nSyl*1/3)
			wred = 65535
			wgrn = 60000 * nColor / ((nSyl) * 1/3)
			wblu = 0
		elseif (nColor <= nSyl*1/2)
			wred = 65535 - 65535 *  (nColor - (nSyl) * 1/3) / ((nSyl) * 1/6)
			wgrn = 60000
			wblu = 0
		elseif (nColor <= nSyl*2/3)
			wred = 0
			wgrn = 60000 - 60000 *  (nColor - (nSyl) * 1/2) / ((nSyl) * 1/6)
			wblu = 65535 * (nColor - (nSyl) * 1/2) / ((nSyl) * 1/6)
		elseif (nColor <= nSyl*5/6)
			wred = 19456 * (nColor - (nSyl) * 2/3) / ((nSyl) * 1/6)
			wgrn = 0
			wblu = 65535 - 33535 *  (nColor - (nSyl) * 2/3) / ((nSyl) * 1/6)
		else
			wred = 19456 + 17264 * (nColor - (nSyl) * 5/6) / ((nSyl) * 1/6)
			wgrn = 0
			wblu = 33535 + 32000 * (nColor - (nSyl) * 5/6) / ((nSyl) * 1/6)
		endif
		if (preSyl <= nSyl)
			setDrawEnv linefgc=(wred,wgrn,wblu), linethick=linethickness
			DrawLine preX, preY, end_xwave[preSyl-1], end_ywave[preSyl-1]
			// DrawLine preX, preY, end_xwave[wave_a[nindex]-1]+enoise(nnoise), end_ywave[wave_a[nindex]-1]+enoise(nnoise)
		endif
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
	
	nindex=0	
	Do
		setDrawEnv textrgb=(0, 0, 0), textxjust=1, textyjust=1, fsize = 22
		DrawText cos(Pi+2*Pi/nSyl*nindex) / 3 + 0.5, sin(Pi+2*Pi/nSyl*nindex) / 3 + 0.5, num2str(nindex+1)
		nindex += 1
	While (nindex < nSyl)

	
end


function findSongSequence ([waveBout, waveSeq, filename])
	String waveBout, waveSeq, filename
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "syllable_classified"; waveSeq="FindThisSequence"; filename="syllable_file_name"
		Prompt waveBout, "Wave classified name"//, popup wavelist ("*",";","")
		Prompt waveSeq, "Wave song patten"
		Prompt filename, "Wave filename"
		DoPrompt  "findSongSequence", waveBout, waveSeq, filename
		if (V_Flag)	// User canceled
			return -1
		endif
		print "findSongSequence(waveBout=\"" + waveBout + "\", waveSeq=\"" + waveSeq  + "\", filename=\"" + filename + "\")"
	endif
	
	string lista, name_a, listseq, name_seq, listfile, name_file
	string textSeq, textP, listP, nPname, nPlabel, nPrname, nPpname, last_nPpname, minus_nPpname
	string stPname, enPname, stPlabel, enPlabel, liststP, listenP
	string onsetname, offsetname, filewave, durname
	variable windex, nindex, length_a, nPall, col_a, length_ph, last_ph_onset, pindex, tindex, flagEnd, sylAll, nwave, stindex, enindex, stN, enN, listnum
	lista = WaveList(waveBout,";","")
	listseq = WaveList(waveSeq,";","")
	listfile = WaveList(filename,";","")	
	pindex=0
	windex=0
	name_a = StringFromList(windex, lista)
	name_seq = StringFromList(windex, listseq)
	name_file = StringFromList(windex, listfile)
	Do
		wave wave_a = $name_a
		wave wave_seq = $name_seq
		wave /T wave_file = $name_file
		onsetname = "SeqOnset" + num2str(windex)
		offsetname = "SeqOffset" + num2str(windex)
		filewave = "SeqFilename" + num2str(windex)
		Make /N=0 /O $onsetname
		Make /N=0 /O $offsetname
		Make /N=0 /O /T $filewave
		wave on = $onsetname
		wave off = $offsetname
		wave /T filew = $filewave
		length_ph = numpnts(wave_seq)
		textSeq = ""
		tindex=0
		Do
			textSeq += num2str(wave_seq[tindex])
			tindex += 1
		While(tindex < length_ph)
		length_a = DimSize(wave_a, 0)
		last_ph_onset = length_a - length_ph + 1
		flagEnd = 0
		nindex = 0
		Do
			if ((nindex + length_ph) > length_a)
				flagEnd = 1
				break
			endif
			textP = ""
			tindex=0
			Do
				textP += num2str(wave_a[nindex+tindex])
				tindex += 1
			While(tindex < length_ph)
			if (stringmatch(textSeq, textP))
				if (stringmatch(wave_file[nindex], wave_file[nindex+length_ph-1]) )
					Insertpoints pindex, 1, on
					Insertpoints pindex, 1, off
					Insertpoints pindex, 1, filew
					on[pindex] = nindex
					off[pindex] = nindex+length_ph-1
					filew[pindex] = wave_file[nindex]
					pindex += 1
				endif
			endif
			nindex += 1
		while(nindex <= last_ph_onset)
		windex+=1
		name_a = StringFromList(windex, lista)
		name_file = StringFromList(windex, listfile)
	While(strlen(name_a)!=0)

end



function replaceSongSequence ([waveBout, waveSeq, waveRep])
	String waveBout, waveSeq, waveRep
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "syllable_classified"; waveSeq="findThisSequence"; waveRep="replacedSequence"
		Prompt waveBout, "Wave classified name"//, popup wavelist ("*",";","")
		Prompt waveSeq, "Wave target sequence"
		Prompt waveRep, "Wave replaced sequence"
		DoPrompt  "replaceSongSequence", waveBout, waveSeq, waveRep
		if (V_Flag)	// User canceled
			return -1
		endif
		print "replaceSongSequence(waveBout=\"" + waveBout + "\", waveSeq=\"" + waveSeq  + "\", waveRep=\"" + waveRep + "\")"
	endif
	
	string lista, name_a, listseq, name_seq, listrep, name_rep
	string textSeq, textP, listP, nPname, nPlabel, nPrname, nPpname, last_nPpname, minus_nPpname
	string stPname, enPname, stPlabel, enPlabel, liststP, listenP
	string onsetname, offsetname, filewave, durname
	variable windex, nindex, length_a, nPall, col_a, length_seq, last_seq_onset, pindex, tindex
	variable flagEnd, sylAll, nwave, stindex, enindex, stN, enN, listnum, length_rep
	lista = WaveList(waveBout,";","")
	listseq = WaveList(waveSeq,";","")
	listrep = WaveList(waveRep,";","")
	pindex=0
	windex=0
	name_a = StringFromList(windex, lista)
	name_seq = StringFromList(windex, listseq)
	name_rep = StringFromList(windex, listrep)
	Do
		wave wave_a = $name_a
		wave wave_seq = $name_seq
		wave wave_rep = $name_rep
		length_seq = numpnts(wave_seq)
		length_rep = numpnts(wave_rep)
		if (length_seq > 0 && length_rep > 0)
			textSeq = ""
			tindex=0
			Do
				textSeq += num2str(wave_seq[tindex])
				tindex += 1
			While(tindex < length_seq)
			length_a = DimSize(wave_a, 0)
			last_seq_onset = length_a - length_seq + 1
			flagEnd = 0
			nindex = 0
			Do
				if (nindex > last_seq_onset)
					flagEnd = 1
					break
				endif
				textP = ""
				tindex=0
				Do
					textP += num2str(wave_a[nindex+tindex])
					tindex += 1
				While(tindex < length_seq)
				if (stringmatch(textSeq, textP))
					if (length_seq < length_rep)
						insertpoints nindex, (length_rep - length_seq), wave_a
						last_seq_onset += length_rep - length_seq
					endif
					wave_a[nindex, nindex+length_rep-1] = wave_rep[p-nindex]
					if (length_seq > length_rep)
						deletepoints nindex+length_rep, (length_seq - length_rep), wave_a
					endif
					nindex = nindex+length_rep-1
				endif
				nindex += 1
			while(nindex <= last_seq_onset)
		endif
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
end



function replaceSongSeqToProb ([waveBout, waveSeq, waveRep])
	String waveBout, waveSeq, waveRep
	if (numType(strlen(waveBout)) == 2)	// if (wave1 == null) : so there was no input
		waveBout = "SqStr"; waveSeq="labelStr"; waveRep="labelP"
		Prompt waveBout, "Wave sequence name"//, popup wavelist ("*",";","")
		Prompt waveSeq, "Wave label sequence"
		Prompt waveRep, "Wave label probability"
		DoPrompt  "replaceSongSeqToProb", waveBout, waveSeq, waveRep
		if (V_Flag)	// User canceled
			return -1
		endif
		print "replaceSongSeqToProb(waveBout=\"" + waveBout + "\", waveSeq=\"" + waveSeq  + "\", waveRep=\"" + waveRep + "\")"
	endif
	
	string lista, name_a, listseq, name_seq, listrep, name_rep, destname, destwave, boutstr
	destname = "strproblist"
	string textSeq, textP, listP, nPname, nPlabel, nPrname, nPpname, last_nPpname, minus_nPpname
	string stPname, enPname, stPlabel, enPlabel, liststP, listenP
	string onsetname, offsetname, filewave, durname
	variable windex, nindex, length_a, nPall, col_a, length_seq, last_seq_onset, pindex, tindex, lindex, boutnum
	variable flagEnd, sylAll, nwave, stindex, enindex, stN, enN, listnum, length_rep, foundpnt
	lista = WaveList(waveBout,";","")
	listseq = WaveList(waveSeq,";","")
	listrep = WaveList(waveRep,";","")
	pindex=0
	windex=0
	name_a = StringFromList(windex, lista)
	name_seq = StringFromList(windex, listseq)
	name_rep = StringFromList(windex, listrep)
	wave /T wave_seq = $name_seq
	wave wave_rep = $name_rep
	Do
		wave /T wave_a = $name_a
		length_seq = numpnts(wave_seq)
		length_rep = numpnts(wave_rep)
		
		length_a = DimSize(wave_a, 0)
		nindex = 0
		Do
			boutstr = wave_a[nindex]
			boutstr = replacestring("'", boutstr, "")
			print boutstr
			boutnum = strlen(boutstr)
			destwave = destname + num2str(nindex)
			Make /O /N=(boutnum-1) $destwave
			wave dw = $destwave
			dw = 0
			tindex = 0
			Do
				lindex = 0
				Do
					foundpnt = strsearch(replacestring("'", wave_seq[lindex], ""), boutstr[tindex,tindex+1], 0)
					if (foundpnt != -1)
						dw[tindex] = wave_rep[lindex]
						break
					endif
//						print "[", lindex, "]", replacestring("'", wave_seq[lindex], ""), " = ",  boutstr[tindex,tindex+1]
					lindex += 1
				While(lindex < length_seq)
				tindex += 1
			While(tindex < boutnum-1)
			nindex += 1
		While(nindex < length_a)
		windex+=1
		name_a = StringFromList(windex, lista)
	While(strlen(name_a)!=0)
end



function makeTransitionMatrix ([waveRatio, waveLabel])
	String waveRatio, waveLabel
	if (numType(strlen(waveRatio)) == 2)	// if (wave1 == null) : so there was no input
		waveRatio = "nPattern_2notes_ratio"; waveLabel="nPattern_2notes_label";
		Prompt waveRatio, "Wave transition ratio"//, popup wavelist ("*",";","")
		Prompt waveLabel, "Wave transition ratio label"
		DoPrompt  "makeTransitionMatrix", waveRatio, waveLabel
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeTransitionMatrix(waveRatio=\"" + waveRatio + "\", waveLabel=\"" + waveLabel + "\")"
	endif
	
	string lista, namea, namelabel, listLabel, targetname, picname
	variable windex, nindex, len_transition
	lista = WaveList(waveRatio,";","")
	listLabel = WaveList(waveLabel,";","")
	windex = 0
	namea = StringFromList(windex, lista)
	namelabel = StringFromList(windex, listLabel)
	Do
		targetname = "M_" + namea
		Make /O /N=(10,10) $targetname
		wave a = $namea
		len_transition = DimSize(a, 0)
		wave /T l = $namelabel
		wave mat = $targetname
		mat = 0
		nindex = 0
		Do
			mat[str2num((l[nindex])[0])][str2num((l[nindex])[1])] = a[nindex]
			nindex += 1
		While(nindex < len_transition)
		picname = "P_" + targetname
		Duplicate /O $targetname, $picname
		wave picn = $picname
		picn[][] = mat[q][p]
		NewImage  picn
		ModifyGraph manTick(top)={0,1,0,0},manMinor(top)={0,0}
		ModifyGraph manTick(left)={0,1,0,0},manMinor(left)={0,0}
		windex+=1
		namea = StringFromList(windex, lista)
		namelabel = StringFromList(windex, listLabel)
	While(strlen(namea)!=0)
end

function discernSongs ([wave1, num])
	String wave1
	Variable num
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "wav*"
		num = 100
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt num, "num of waves" 
		DoPrompt  "discernSongs", wave1, num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "discernSongs(wave1=\"" + wave1 + "\", num=" + num2str(num) + ")"
	endif

	string destname = "song"
	string lista, a_wave
	lista = WaveList(wave1,";","")
	variable thres, sttime, deltaa, entime, interval, mInt, nMoved, lastRise, flagVocal, lastVocal, lastFall
	variable windex=0, pindex=0, iindex=0
	a_wave = StringFromList(windex, lista)
	string destwave, destint, destcross, destmax, destmint, destvar, targetFolder
	destwave = destname + "_name"
	make /O /T /N=(num) $destwave
	destint = destname + "_interval"
	make /O /N=(num) $destint
	destcross = destname + "_cross"
	make /O /N=(num) $destcross
	destmax = destname + "_min"
	make /O /N=(num) $destmax
	destmint = destname + "_mInt"
	make /O /N=(num) $destmint
	destvar = destname + "_var"
	make /O /N=(num) $destvar
	Do
		mint = 0; interval = 0; lastRise = 0; lastVocal = 0; lastFall = 0; flagVocal = 0
		destname = "levels_" + a_wave
		wavestats /R=(rightx($a_wave)-1, inf) /Q $a_wave
		thres = -1.8
		wavestats /Q $a_wave
//		thres = V_avg  + 1000
		sttime = leftx($a_wave)
		entime = rightx($a_wave)
		deltaa = deltax($a_wave)
		pindex=0
		iindex=0
		mInt = 0
		Do
			findlevel /Q /R=(sttime, entime) $a_wave, thres
			if (V_flag)
				if (flagVocal)
					flagVocal = 0
					interval = lastRise - lastVocal
					mint += interval
					iindex += 1
				endif
				break
			else
				if (!V_rising)	// down
					if (flagVocal)
						if (V_LevelX - lastRise > 0.080)
							flagVocal = 0
							interval = lastRise - lastVocal
							mint += interval
							iindex += 1
//							print "hit ", V_levelX , "int ", interval
						endif
					endif
					lastFall = V_LevelX
				else			// up
					if (lastFall != 0)
						interval = V_LevelX - lastFall
						if (interval > 0.040 && interval < 0.500)
							if (!flagVocal)
								flagVocal = 1
								lastVocal = lastFall
//								print "vocal", lastVocal
							endif
						endif
					endif
					lastRise = V_LevelX
				endif
				sttime = V_LevelX + deltaa
				pindex+=1
			endif
		While (1)
		wave /T d = $destwave
		d[windex] = a_wave
		wave e = $destint
		e[windex] = iindex / rightx($a_wave)
		wave e = $destmint
		e[windex] = mInt / iindex
		wave e = $destcross
		e[windex] = pindex
		wave e = $destvar
		e[windex] = V_sdev
		wave e = $destmax
		e[windex] = V_min
//		if (V_max > 10000)
//			targetFolder = ":noise"
//			newDataFolder /O $targetFolder
//			moveWave $a_wave, $(targetFolder+":")
//			nMoved += 1
//		endif
		
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	Beep
End

function calcConsistencyScore ([waveRatio, waveLabel, nSong])
	String waveRatio, waveLabel
	variable nSong
	if (numType(strlen(waveRatio)) == 2)	// if (wave1 == null) : so there was no input
		waveRatio = "M_nPattern_2notes_ratio"; waveLabel="nPattern_2notes_label";
		Prompt waveRatio, "Matrix transition ratio"//, popup wavelist ("*",";","")
		Prompt waveLabel, "Wave transition ratio label"
		Prompt nSong, "num song"
		DoPrompt  " calcConsistencyScore", waveRatio, waveLabel, nSong
		if (V_Flag)	// User canceled
			return -1
		endif
		print " calcConsistencyScore(waveRatio=\"" + waveRatio + "\", waveLabel=\"" + waveLabel + "\", nSong=" + num2str(nSong) + ")"
	endif

	string lista, namea, namelabel, listLabel, targetname, typList, transList, tempTyp, enname, sylListNname, sylListname
	variable windex, rindex, cindex, typListN, transListN, maxN, st_r, st_c, en_r, en_c, flagMax , len_sylList, countN, nindex, transN, enMax
	enname = "enPattern_2notes_ratio"
	sylListNname = "nPattern_2notes"
	sylListname = "nPattern_2notes_label"
	lista = WaveList(waveRatio,";","")
	listLabel = WaveList(waveLabel,";","")
	windex = 0
	namea = StringFromList(windex, lista)
	namelabel = StringFromList(windex, listLabel)
		st_r = 2
		st_c = 2
		en_r = 9
		en_c = 9	
	Do
		targetname = "cons_" + namelabel
		Make /O /N=(1) $targetname
		wave a = $namea
		wave t = $targetname
		t = 0
		wave /T l = $namelabel
		typList = ""
		transList = ""
		typListN = 0
		transListN = 0
		rindex = st_r
		Do
			maxN = 0
			flagMax = 0
			cindex = st_c
			Do
				if (a[rindex][cindex] > 0 && a[rindex][cindex] > maxN)
					tempTyp = num2str(rindex) + num2str(cindex)
					maxN = a[rindex][cindex]
					flagMax = 1
				endif
				cindex += 1
			While(cindex < en_c)
			if (flagMax)
				typList = typList + tempTyp + ";"
				typListN += 1
			endif
			rindex += 1
		While(rindex < en_r)
		wave enl = $enname
		enMax = enl[0]
		wave sylListN = $sylListNname
		wave /T sylList = $sylListname
		len_sylList = rightx(sylList)
		nindex = 0
		Do 
			if (str2num((sylList[nindex])[0]) != 1 && str2num((sylList[nindex])[1]) != 1 )
				transN += sylListN[nindex]
			endif
			if (WhichListItem(sylList[nindex], typList) != -1)
				countN += sylListN[nindex]
			endif
			nindex += 1
		While (nindex < len_sylList)
		t[0] = (countN + nSong * enMax) / ( transN + nSong )
		print "sylList : ",  typList
		print "Consistency score : ", t[0]
		windex+=1
		namea = StringFromList(windex, lista)
		namelabel = StringFromList(windex, listLabel)
	While(strlen(namea)!=0)
End


function calcSequenceLinearity ([waveRatio, waveLabel])
	String waveRatio, waveLabel
	if (numType(strlen(waveRatio)) == 2)	// if (wave1 == null) : so there was no input
		waveRatio = "nPattern_2notes_ratio"; waveLabel="nPattern_2notes_label";
		Prompt waveRatio, "Wave transition ratio"//, popup wavelist ("*",";","")
		Prompt waveLabel, "Wave transition ratio label"
		DoPrompt  " calcSequenceLinearity", waveRatio, waveLabel
		if (V_Flag)	// User canceled
			return -1
		endif
		print " calcSequenceLinearity(waveRatio=\"" + waveRatio + "\", waveLabel=\"" + waveLabel + "\")"
	endif

	string lista, namea, namelabel, listLabel, targetname, sylList, transList
	variable windex, nindex, len_transition, sylListN, transListN
	lista = WaveList(waveRatio,";","")
	listLabel = WaveList(waveLabel,";","")
	windex = 0
	namea = StringFromList(windex, lista)
	namelabel = StringFromList(windex, listLabel)
	Do
		targetname = "seqLinear" + namea
		Make /O /N=(1) $targetname
		wave a = $namea
		wave t = $targetname
		t = 0
		wave /T l = $namelabel
		len_transition = DimSize(a, 0)
		sylList = ""
		transList = ""
		sylListN = 0
		transListN = 0
		nindex = 0
		Do
			if (str2num((l[nindex])[0]) != 1)
				if (WhichListItem((l[nindex])[0], sylList) == -1)
					sylList = sylList + (l[nindex])[0] + ";"
					sylListN += 1
				endif
			endif
			if (str2num((l[nindex])[1]) != 1)
				if (WhichListItem((l[nindex])[1], sylList) == -1)
					sylList = sylList + (l[nindex])[1] + ";"
					sylListN += 1
				endif
			endif
			if (str2num((l[nindex])[0]) != 1 && str2num((l[nindex])[1]) != 1)
					transList = transList + (l[nindex]) + ";"
					transListN += 1
			endif
			nindex += 1
		While(nindex < len_transition)
		t = (sylListN - 1) / transListN
		print "sylList ( ", num2str(sylListN), " ) : ",  sylList
		print "transList ( ", num2str(transListN), " ) : ",  transList
		print "Sequence Linearity : ", t[0]
		windex+=1
		namea = StringFromList(windex, lista)
		namelabel = StringFromList(windex, listLabel)
	While(strlen(namea)!=0)
End

function calcSongDuration ([vocalname, vocaldur, onsetname, offsetname, targetname, type])
	String vocalname, vocaldur, onsetname, offsetname, targetname
	Variable type
	if (numType(strlen(vocalname)) == 2)	// if (wave1 == null) : so there was no input
		vocalname = "syllable_time"; vocaldur="syllable_duration"; onsetname = "songOnset"; offsetname = "songOffset"; targetname = "songDuration"
		Prompt vocalname, "Wave vocalization name"//, popup wavelist ("*",";","")
		Prompt vocaldur, "Wave vocal dur name"//, popup wavelist ("*",";","")
		Prompt onsetname, "Wave onset name"//, popup wavelist ("*",";","")
		Prompt offsetname, "Wave offset name"//, popup wavelist ("*",";","")
		Prompt targetname, "Wave target name"//, popup wavelist ("*",";","")
		Prompt type, "type 0/1(dur/int)"//, popup wavelist ("*",";","")
		DoPrompt  "calcSongDuration", vocalname, vocaldur, onsetname, offsetname, targetname, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "calcSongDuration(vocalname=\"" + vocalname + "\",vocaldur=\"" + vocaldur + "\",onsetname=\"" + onsetname + "\",offsetname=\"" + offsetname + "\",targetname=\"" + targetname + "\", type=" + num2str(type) + ")"
	endif

	Duplicate /O $onsetname, $targetname
	wave vocal = $vocalname
	wave vocal_dur = $vocaldur
	wave on = $onsetname
	wave off = $offsetname
	wave target = $targetname
	target = 0
	if (type == 0)
		target[] = vocal[off[p]] - vocal[on[p]] + vocal_dur[off[p]]
	else
		target[] = vocal[on[p+1]] - vocal[off[p]] - vocal_dur[off[p]]
		DeletePoints (x2pnt(target, rightx(target))-1), 1, target
	endif
	wavestats /Q target
	print "Song Duration : avg = ", V_avg, " , SD = " , V_sdev 
End

function calcWienerEntropy ([wave1, type, stfreq, enfreq])
	String wave1
	Variable type, stfreq, enfreq
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1 = "S_wav*"
		type=0; stfreq=100; enfreq=1500
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt type, "type 0/1/2(0-1/log/Shannon)" 
		Prompt stfreq, "freq from" 
		Prompt enfreq, "to" 
		DoPrompt  "calcWienerEntropy", wave1, type, stfreq, enfreq
		if (V_Flag)	// User canceled
			return -1
		endif
		print "calcWienerEntropy(wave1=\"" + wave1 + "\", type=" + num2str(type) +", stfreq=" + num2str(stfreq) + ", enfreq=" + num2str(enfreq) + ")"
	endif

	string destname = "W_", destwave
	string lista, a_wave
	lista = WaveList(wave1,";","")
	variable windex=0, a_pntc, a_pntr, cindex, rindex, a_deltac, a_offc, endc, Nc,sumc
	variable sumNlog=0, sumN=0, sumEnt=0
	a_wave = StringFromList(windex, lista)
	Do
		a_pntr = DimSize($a_wave, 0)
		a_pntc = DimSize($a_wave, 1)
		a_deltac = DimDelta($a_wave, 1)
		a_offc = DimOffset($a_wave, 1)
		destwave = destname + a_wave
		make /O /N=(a_pntr) $destwave
		wave a = $a_wave
		wave d = $destwave
		rindex = 0
		Do
			sumN = 0
			sumNlog = 0
			endc =  min((enfreq - a_offc) / a_deltac, a_pntc)
			cindex = max((stfreq - a_offc) / a_deltac, 0)
			Nc = endc - cindex + 1
			sumc = 0
			Do 
				sumN += a[rindex][cindex] / Nc // maybe it devides each time to avoid overflow
				sumNlog += ln(a[rindex][cindex]) / Nc
				sumc += a[rindex][cindex]
				cindex += 1
			While (cindex < endc)

			/// final result
			if (type == 0)
				d[rindex] = exp(sumNlog) / sumN
			elseif (type == 1)
				d[rindex] = ln(exp(sumNlog) / sumN)
			elseif (type == 2)
				///// this is to literally calculate entropy ///////
				sumEnt = 0
				cindex = max((stfreq - a_offc) / a_deltac, 0)
				Do 
					sumEnt += -a[rindex][cindex] / sumc * ln(a[rindex][cindex] / sumc)
					cindex += 1
				While (cindex < endc)
				d[rindex] = sumEnt
			endif
			rindex += 1
		While (rindex < a_pntr)
		SetScale/P x DimOffset($a_wave, 0), DimDelta($a_wave, 0), "s", $destwave
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	Beep
End

function makeONOFFwave ([vocalname, vocaldur, onsetname, offsetname, filename, targetname, type, typepnt])
	String vocalname, vocaldur, onsetname, offsetname, targetname, filename
	Variable type, typepnt
	if (numType(strlen(vocalname)) == 2)	// if (wave1 == null) : so there was no input
		vocalname = "syllable_start_on"; vocaldur="syllable_duration"; onsetname = "songOnset"; offsetname = "songOffset"; filename="songFileName"; targetname = "song_"
		type=1
		Prompt vocalname, "Wave vocal time name"//, popup wavelist ("*",";","")
		Prompt vocaldur, "Wave vocal dur name"//, popup wavelist ("*",";","")
		Prompt onsetname, "Wave onset name"//, popup wavelist ("*",";","")
		Prompt offsetname, "Wave offset name"//, popup wavelist ("*",";","")
		Prompt filename, "Wave file name"//, popup wavelist ("*",";","")
		Prompt targetname, "Wave target prefix"//, popup wavelist ("*",";","")
		Prompt type, "separate with filename? 0/1"//, popup wavelist ("*",";","")
		Prompt typepnt, "pnt val/abs val? 0/1"
		DoPrompt  "makeONOFFwave", vocalname, vocaldur, onsetname, offsetname, filename, targetname, type, typepnt
		if (V_Flag)	// User canceled
			return -1
		endif
		print "makeONOFFwave(vocalname=\"" + vocalname + "\",vocaldur=\"" + vocaldur + "\",onsetname=\"" + onsetname + "\",offsetname=\"" + offsetname + "\",filename=\"" + filename + "\",targetname=\"" + targetname + "\", type=" + num2str(type)+ ", typepnt=" + num2str(typepnt) + ")"
	endif
	
	//example  makeONOFFwave(vocalname="syllable_start_pnt",vocaldur="syllable_duration_pnt",onsetname="songOnset_n",offsetname="songOffset_n",filename="songFileName",targetname="bout_", type=1, typepnt=0)

	string targetON, targetOFF, lastfile, fileprefix, rectime, recCh, regExpr
	variable pindex, windex, lenp, dindex
	wave vocal = $vocalname
	wave vocal_dur = $vocaldur
	wave on = $onsetname
	wave off = $offsetname
	regExpr =  "([0-9,a-z]+)_.*_([0-9]+).mat"
	if (type == 1)
		wave /T datafile = $filename
		lenp = numpnts(on)
		dindex = 0
		windex = 0
		pindex = 0
		Do
			if (!stringmatch(lastfile, datafile[pindex]))
				splitString /E=(regExpr) datafile[pindex], fileprefix, rectime, recCh
				if (stringmatch(rectime,""))
					rectime = num2str(windex)
				endif
				targetON = targetname + "onset_" + rectime
				targetOFF = targetname + "offset_" + rectime
				Make /O /N=1 $targetON
				Make /O /N=1 $targetOFF
				wave tON = $targetON
				wave tOFF = $targetOFF
				if (typepnt == 1)
					tON[dindex] = on[pindex]
					tOFF[dindex] = off[pindex]
				else
					tON[dindex] = vocal[on[pindex]]
					tOFF[dindex] = vocal[off[pindex]] + vocal_dur[off[pindex]]
//					tOFF[dindex] = vocal[off[pindex]]
				endif
				windex += 1
				dindex += 1
			else
				Insertpoints dindex, 1, tON
				Insertpoints dindex, 1, tOFF
				if (typepnt == 1)
					tON[dindex] = on[pindex]
					tOFF[dindex] = off[pindex]
				else
					tON[dindex] = vocal[on[pindex]]
					tOFF[dindex] = vocal[off[pindex]] + vocal_dur[off[pindex]]
//					tOFF[dindex] = vocal[off[pindex]]
				endif
				dindex += 1
			endif
			lastfile = datafile[pindex]
			pindex += 1
		While(pindex < lenp)
		print "created ", num2str(windex) , " waves"
	else
		targetON = targetname + "onset_abs_" + num2str(windex)
		targetOFF = targetname + "offset_abs_" + num2str(windex)
		Duplicate /O on, $targetON
		Duplicate /O off, $targetOFF
		wave tON = $targetON
		wave tOFF = $targetOFF
		tON[] = vocal[on[p]]
		tOFF[] = vocal[off[p]] + vocal_dur[off[p]]
	endif

End
