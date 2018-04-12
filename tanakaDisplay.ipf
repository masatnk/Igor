#pragma rtGlobals=1		// Use modern global access method.


Menu "tanakaDisplay"
	Submenu "Input Output"
		"saveFiles"
		"openWAV"
		"openWAVFiles"
		"open_pClampATF"
		"open_pClampIBW"
		"open_txtWave"
		"open_EvTAFcbin"
	end
	Submenu "File management"
		"moveRawData"
		"moveToFolder"
		"moveToFolderWithLabel"
		"moveWithStim"
		"moveWithVrest"
		"moveWithIrest"
		"prep_waveclusWave"
		"prep_pClampWaves"
		"sortWaves"
		"deletesWaves"
	end
	Submenu "make Graphs"
		"displayWaves"
		"displayWavesEachWin"
		"displayWavesCircleSize"
		"displayRamp"
		"displayEvoke"
		"displayLight"
		"displayPPD"
		"displayCmJump"
		"displaySpontaneous"
		"displaySpontaneous200ms"
		"displayGinput"
		"displayCrosscorrelo"
		"calcCorr"
	end
end

macro saveFiles(sttime, entime)
	Variable sttime=895, entime=901
	String igtDir = "", pxpDir=""
	newPath IGORTXT, "C:HEKA:Data:matsumoto:igorTxt:"
	Variable index = sttime
	do
		igtDir = "B" + num2str(index) + ".itx"
		pxpDir = "B" + num2str(index) + ".pxp"
		LoadWave /P=IGORTXT /T igtDir
		SaveExperiment /P=IGORTXT as pxpDir
		KillDataFolder root:raw
		newDataFolder /O root:raw
		setDataFolder root:raw
		index += 1
	while (index < (entime+1))
endmacro

function openWAV([filename, waveid])
	String filename
	Variable waveid
	if (numType(strlen(filename)) == 2)		// if (waves == null) : so there was no input
		filename ="N:\\Masa\\yel1030_postinjection\\215\\p967_41490.41248413_8_4_11_27_28.wav"
		waveid = -1
		Prompt filename, "File name"
		Prompt waveid, "wave id (if -1, use filename)"
		DoPrompt  "openWAV", filename, waveid
		if (V_Flag)	// User canceled
			return -1
		endif
		print "openWAV(filename=\"" + filename + "\", waveid=" + num2str(waveid) + ")"
	endif
	String pathname, filenameorg, tmpfilename
	String query_RIFF, query_WAVE, query_fmt, query_data
	variable query_filesize, query_Nbyte, query_formatID, query_NCh
	variable query_samplerate,query_byterate,query_blocksize,query_bitPerSample, query_Ndata, query_val
	query_RIFF = "aaaa"
	query_WAVE = "aaaa"
	query_fmt = "aaaa"
	query_data = "aaaa"

	tmpfilename = "tmp"
	filenameorg = filename
	filename = replaceString("\\", filename, ":")
	filename = replaceString("::", filename, ":")
	variable filenamepos, refNum
	filenamepos = strsearch(filename,":",inf,1)
	if (strlen(filename) == 0)
		newPath /Z /O /Q CurrentPath
		Open /R /P=CurrentPath /F="*" refNum as filename
	elseif (filenamepos == -1)
		Open /Z /R /P=home refNum as filename
	else
		// Most of the case it runs here
		pathname = filename[0,filenamepos]
		filename = filename[filenamepos+1,inf]
//		print "\t path :\t", pathname
//		print "\t file :\t", filename
		newPath /Z /O /Q CurrentPath, pathname
		Open /R /P=CurrentPath refNum as filename
	endif
	if (V_flag != 0)
		print "!!! error: file not found", V_Flag
		abort
	endif
	print filename
	//filename = S_filename
	FBinRead /F=3 /B=2  refNum, query_RIFF
	FBinRead /F=3 /B=0 /U refNum, query_filesize
	FBinRead /F=3 /B=2 /U refNum, query_WAVE
	FBinRead /F=3 /B=2 /U refNum, query_fmt
	FBinRead /F=3 /B=0 /U refNum, query_Nbyte
	FBinRead /F=2 /B=0 /U refNum, query_formatID
	FBinRead /F=2 /B=0 /U refNum, query_NCh
	FBinRead /F=3 /B=0 /U refNum, query_samplerate
	FBinRead /F=3 /B=0 /U refNum, query_byterate
	FBinRead /F=2 /B=0 /U refNum, query_blocksize
	FBinRead /F=2 /B=0 /U refNum, query_bitPerSample
	FBinRead /B=0 /U refNum, query_data
	FBinRead /F=3 /B=0 /U refNum, query_Ndata
	print "\t\t", S_filename, " (", query_samplerate, "Hz; ", query_bitPerSample, "bits/rate; ", query_NCh, "Chs)"
	variable nlast = query_Ndata / 2
	variable delta = 1/query_samplerate
	if (waveid == -1)
		filename = replaceString(".wav", filename, "")
		filename = "wav" + filename[strsearch(filename, "_", strsearch(filename, ".", 0))+1, inf]
	else
		filename = "wav" + num2str(waveid)
	endif
	variable nindex = 0
	if (query_NCh == 1)
//		make /W /N=(nlast) /O $filename
		make /N=(nlast) /O $filename
		wave d = $filename
		Do
			FBinRead /F=2 /B=3 refNum, query_val
			d[nindex] = query_val
			SetScale/P x 0,delta,"s", d
			nindex += 1
		While (nindex < nlast)
	elseif (query_NCh == 2)
		string filename_L = filename + "_L"
		string filename_R = filename + "_R"
//		make /W /N=(nlast/2) /O $filename_L
//		make /W /N=(nlast/2) /O $filename_R
		make /N=(nlast/2) /O $filename_L
		make /N=(nlast/2) /O $filename_R
		wave dL = $filename_L
		wave dR = $filename_R
		Do
			FBinRead /F=2 /B=3 refNum, query_val
			dL[nindex] = query_val
			FBinRead /F=2 /B=3 refNum, query_val
			dR[nindex] = query_val
			SetScale/P x 0,delta,"s", dL
			SetScale/P x 0,delta,"s", dR
			nindex += 1
		While (nindex < nlast/2)
	endif
	Close refNum

	string headerFile = "header.txt"
	Open /A /P=home refNum as headerFile
	fprintf refNum, filenameorg
	fprintf refNum, "\t%s", query_RIFF
	fprintf refNum, "\t%d", (query_filesize+8)
	fprintf refNum, "\t%s", query_WAVE
	fprintf refNum, "\t%s", query_fmt
	fprintf refNum, "\t%d", query_Nbyte
	fprintf refNum, "\t%d", query_formatID
	fprintf refNum, "\t%d", query_NCh
	fprintf refNum, "\t%d", query_samplerate
	fprintf refNum, "\t%d", query_byterate
	fprintf refNum, "\t%d", query_blocksize
	fprintf refNum, "\t%d", query_bitPerSample
	fprintf refNum, "\t%s", query_data
	fprintf refNum, "\t%d", query_Ndata
	fprintf refNum, "\r\n"
	Close refNum
end

function openWAVFiles([type, nametype, filename, wavname])
	String filename, wavname
	Variable type, nametype
	if (numType(strlen(filename)) == 2)		// if (waves == null) : so there was no input
		filename ="filelist.txt"; wavname="*.wav"
		type = 1;	nametype = 1;
		Prompt type, "type to open 0/1(txt/dir&file)"
		Prompt nametype, "name type 0/1(SAPdate/id)"
		Prompt filename, "Wavlist (.txt) name (if 0)"
		Prompt wavname, "Wav file name to open (if 1)"
		DoPrompt  "openWAVFiles", type, nametype, filename, wavname
		if (V_Flag)	// User canceled
			return -1
		endif
		print "openWAVFiles(type=" + num2str(type) + ", nametype=" + num2str(nametype) + ", filename=\"" + filename + "\", wavname=\"" + wavname + "\")"
	endif

	variable refNumTXT, refNum
	string filepath, filepathlist, pathname
	variable windex = 0

	if (type == 0)
		Open /Z /R /D /P=home refNumTXT as filename
		if (V_flag != 0)
			print "!!! error: file not found", V_Flag
			abort
		endif
		print "S_filename:", S_fileName
		FReadLine refNumTXT, filepath // this also read the terminator (2 charactors)
		filepathlist = filepath[0,strlen(filepath)-2]
		Do 
			FReadLine refNumTXT, filepath 
			filepathlist = filepathlist + ";" + filepath[0,strlen(filepath)-2]
		While (strlen(filepath) != 0)
		Close refNumTXT
			
		print "   processing ... "
		filepath = StringFromList(windex, filepathlist)
		if (nametype == 0)
			Do 
				openWAV(filename=filepath, waveid=-1)
				windex += 1
				filepath = StringFromList(windex, filepathlist)
			While (strlen(filepath)!=0)
		else
			Do
				print filepath
				openWAV(filename=filepath, waveid=windex)
				windex += 1
				filepath = StringFromList(windex, filepathlist)
			While (strlen(filepath)!=0)
		endif
		print windex, "files"
	else
//		NewPath /O wavpath
//		print "   processing ... "
		
//		filename = fileprefix + "_" + filenumstr + "_" + ChStr + ".ibw"
//			GetFileFolderInfo /P=wavpath /Q /Z filename
//			if (V_flag==0)
//				print filename
//				LoadWave /A /H /Q /W /P=IBWpath filename
//				wave awave = $ChStr
//				waveprefix = filenumstr + "_" + ChStr
//				matrixToVector(waves=ChStr, namewave=waveprefix, strow=-1, enrow=29, stcol=0, encol=Dimsize(awave,1)-1, stdepth=0, endepth=0)
//				Killwaves awave
//			endif
//			ChIndex += 1

		string a_file, filelist
		variable findex
		
		newPath /Z /O /Q CurrentPath
		pathinfo CurrentPath
		pathname = S_path
		filelist = IndexedFile(CurrentPath, -1, ".wav")
		a_file = StringFromList(findex, filelist)
		findex = 0
		Do
			if (stringmatch(a_file,wavname))
				filepath = pathname + a_file
				if (nametype == 0)
					openWAV(filename=filepath, waveid=-1)
					windex += 1
				else
					openWAV(filename=filepath, waveid=windex)
					windex += 1
				endif
			endif
			
//				if (stringmatch(a_file, "*_amplifier_data_*"))	// for concatenated data
//					splitString /E="times_.*_amplifier_data_(.*)_class([0-9]+).*" a_file, recCh, class
//					namewave = "amp_" + recCh + "_" + class
//					ampList = ampList + namewave + ";"
//					LoadWave /A /H /Q /W /N=$(namewave) /G /P=$pathName a_file
//					rename $(namewave + num2str(0)), $namewave


			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
				
	endif

end

function open_pClampATF([fileprefix, sttime, entime])
	String fileprefix
	Variable sttime, entime
	if (numType(strlen(fileprefix)) == 2)		// if (waves == null) : so there was no input
		fileprefix="20130724"
		sttime=0; entime=10
		Prompt fileprefix, "File name"
		Prompt sttime, "num from"
		Prompt entime, "num to"
		DoPrompt  "open_pClampATF", fileprefix, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* open_pClampATF(fileprefix=\"" + fileprefix + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif
	string filename, pxpDir
	variable filenum = sttime
	string filenumstr = ""
	String columnInfoStr = "", columnInfo1 = "",  columnInfo2 = "",  columnInfo3 = ""
	variable index = 0
	Do
		if (filenum < 10)
			filenumstr = "000" + num2str(filenum)
		else
			if (filenum < 100)
				filenumstr = "00" + num2str(filenum)
			else
				if (filenum < 1000)
					filenumstr = "0" + num2str(filenum)
				else
					filenumstr = num2str(filenum)
				endif 
			endif
		endif
		filename = fileprefix + "_" + filenumstr + ".atf"
//		filename = "D:DATA_ana:MATSUMOTO:" + filename
		print filename
//		newPath CurrentPath, filename
		columnInfo1 = fileprefix + "_" + filenumstr + "_"
//		columnInfoStr = "C=1,F=7,T=2,N=column1;"
//		columnInfoStr += "C=1,F=0,T=4,N=column2;"
//		columnInfoStr += "C=1,F=0,T=4,W=16,N=column3;"
		if (index == 0)
			NewPath /O ATFpath
		endif
//		LoadWave /A /B=columnInfoStr /G /Q /P=ATFpath filename
		LoadWave /A /G /Q /W /P=ATFpath filename
//		renameWaves(waves="column2", namewave=columnInfo2, useOldname=0, useNum=0,  num=0, num2=0)
//		renameWaves(waves="column3", namewave=columnInfo3, useOldname=0, useNum=0,  num=0, num2=0)

//		Open /R /D=2 /P=CurrentPath refNum 
		renameWaves(waves="T*", namewave=columnInfo1, useOldname=1, useNum=0,  num=0, num2=0)
		filenum += 1
		index += 1
	While (filenum <= entime)


//	pxpDir = fileprefix + ".pxp"
//	SaveExperiment /P=IGORTXT as pxpDir

//		KillDataFolder root:raw
//		newDataFolder /O root:raw
//		setDataFolder root:raw

end

function open_pClampIBW([fileprefix, sttime, entime])
	String fileprefix
	Variable sttime, entime
	if (numType(strlen(fileprefix)) == 2)		// if (waves == null) : so there was no input
		fileprefix="20130724_1"
		sttime=0; entime=10
		Prompt fileprefix, "File name"
		Prompt sttime, "num from"
		Prompt entime, "num to"
		DoPrompt  "open_pClampIBW", fileprefix, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "open_pClampIBW(fileprefix=\"" + fileprefix + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ")"
	endif
	print "   processing ... "

	string listCh = "Im1_IC;Vm1_IC;Im1_VC;Vm1_VC;Im2_IC;Vm2_IC;Im2_VC;Vm2_VC;IN 4;IN 5;IN 11"
	string filename, pxpDir, filenumstr = "",  waveprefix = "", ChStr = "", pathName = ""
	variable filenum = sttime, index = 0, ChIndex = 0
	Do
		if (filenum < 10)
			filenumstr = "000" + num2str(filenum)
		else
			if (filenum < 100)
				filenumstr = "00" + num2str(filenum)
			else
				if (filenum < 1000)
					filenumstr = "0" + num2str(filenum)
				else
					filenumstr = num2str(filenum)
				endif
			endif
		endif
		if (index == 0)
			NewPath /O IBWpath
		endif
		ChIndex = 0
		ChStr = StringFromList(ChIndex, listCh)
		Do 
			filename = fileprefix + "_" + filenumstr + "_" + ChStr + ".ibw"
			GetFileFolderInfo /P=IBWpath /Q /Z filename
			if (V_flag==0)
				print filename
				LoadWave /A /H /Q /W /P=IBWpath filename
				wave awave = $ChStr
				waveprefix = filenumstr + "_" + ChStr
				matrixToVector(waves=ChStr, namewave=waveprefix, strow=-1, enrow=29, stcol=0, encol=Dimsize(awave,1)-1, stdepth=0, endepth=0)
				Killwaves awave
			endif
			ChIndex += 1
			ChStr = StringFromList(ChIndex, listCh)
		While (strlen(ChStr)!=0)
		filenum += 1
		index += 1
	While (filenum <= entime)
end



function open_txtWave([filename, type])
	String filename
	Variable type
	if (numType(strlen(filename)) == 2)		// if (waves == null) : so there was no input
		filename=".*"
		type = 1
		Prompt filename, "File name"
		Prompt type, "File type 0/1/2/3/4/5/6: WClus/RS/Osort/intan?/csv/SongPres/other"
		DoPrompt  "open_txtWave", filename, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "open_txtWave(filename=\"" + filename + "\", type=", num2str(type) + ")"
	endif
	print "   processing ... "
		string a_file, pathName = "", filelist, namewave, txt_t, txt_vm, txt_mic, regExpr
		string rectime, recCh, fileprefix, class, wlist, a_wave, spikename
		variable findex, windex

	if (type == 0) // WaveClus
		string tList, ampList, adcList, spikeList, stRec, enRec, targetFolder, recdate, loadname
		variable recindex, lengthRecw, nindex
		stRec = "stRec"
		enRec = "enRec"
		ampList =""
		adcList = ""
		//pathName = "home"
		//filelist = IndexedFile($pathName, -1, ".txt")
		// a_file = StringFromList(findex, filelist)

		regExpr = "([0-9,a-z]+)_.*_([0-9]+)_([a-z]+).txt"

		newPath /Z /O /Q CurrentPath
		pathinfo CurrentPath
		pathName = S_path
		findex = 0
		//filepath = pathname + a_file
		
		filelist = IndexedFile(CurrentPath, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		Do
			fileprefix = ""
			recCh = ""
			class = ""
			if (GrepString(a_file,filename))
				if (stringmatch(a_file, "*_amplifier_data_*"))	// for concatenated data
					splitString /E="times_.*_amplifier_data_(.*)_class([0-9]+).*" a_file, recCh, class
					namewave = "amp_" + recCh + "_" + class
					ampList = ampList + namewave + ";"
					LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
					rename $(namewave + num2str(0)), $namewave
				elseif (stringmatch(a_file, "*_board_adc_data_*"))	// for concatenated data
					splitString /E=".*_board_adc_data_(.*).txt" a_file, recCh
					namewave = "ADC"  + "_" + recCh
					adcList = adcList + namewave + ";"
					LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
					rename $(namewave + num2str(0)), $namewave
				elseif (stringmatch(a_file, "*t_amplifier*"))	// for concatenated data
					splitString /E=".*_t_amplifier.txt" a_file
					namewave = "time_amp"
					tList = namewave
					LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
					rename $(namewave + num2str(0)), $namewave
				elseif (stringmatch(a_file, "*_amp.txt"))	// for each data (new Masa_loadIntandata)
					splitString /E=".*_.*_(.*)_amp.txt" a_file, recdate
					LoadWave /H /Q /W/A /G /P=CurrentPath a_file
					wlist = DataFolderDir(2)
					windex = 0
					a_wave = StringFromList(windex, wlist, ",")
					Do
						if (stringmatch(a_wave, "A*"))
							splitString /E="(.*)" a_wave, recCh
							namewave = recdate + "_" + recCh
						elseif (stringmatch(a_wave, "*time*"))
							namewave = recdate + "_time"
						else
							namewave = a_wave
						endif
						rename $(a_wave), $namewave
						windex += 1
						a_wave = StringFromList(windex, wlist, ",")				
					While(strlen(a_wave)!=0)
				endif
				print "\t", findex, " : ", a_file, " as ", namewave
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)

		// for concatenated data
		spikeList = ""
		findex = 0
		a_file = StringFromList(findex, ampList)
		Do
			splitString /E="amp_(.*)" a_file, fileprefix
			namewave = "spike_" + fileprefix
			Duplicate /O $tList, $namewave
			spikeList = spikeList + namewave + ";"
			wave wwave = $namewave
			wave awave = $a_file
			wwave = 0
			nindex = 0
			variable lengthwave = DimSize(awave,0)
			Do
				wwave[awave[nindex]] = 1
				nindex += 1
			While(nindex < lengthwave)
			findex+=1
			a_file = StringFromList(findex, ampList)
		While(strlen(a_file)!=0)

		// for concatenated data
		stepdifWave(waves=tList, destname="d")
		string dtList = "d_" + tList
		FindLevels /DEST=$enRec /Edge=2 /P /Q $dtList, -0.1
		wave enRecw = $enRec
		enRecw += 1
		InsertPoints inf, 1, $enRec
		enRecw[inf] = Dimsize($tList, 0)-1
		Duplicate /O $enRec, $stRec
		wave stRecw = $stRec
		stRecw[] = enRecw[p-1]+1
		stRecw[0] = 0
		lengthRecw = Dimsize(enRecw, 0)
	elseif (type == 1) // RS
		pathName = "home"
		txt_t = "_t"
		txt_vm = "_vm"
		txt_mic = "_mic"
		regExpr = "([0-9,a-z]+)_.*_([0-9]+)_([a-z]+).txt"
		filelist = IndexedFile($pathName, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		findex = 0
		Do
			if (GrepString(a_file,filename))
				splitString /E=(regExpr) a_file, fileprefix, rectime, recCh
				namewave = fileprefix + "_" + rectime + "_" + recCh
//				print fileprefix, rectime, recCh
				print "\t", findex, " : ", a_file, " as ", namewave
				LoadWave /A /H /Q /W /N=$(namewave) /G /P=$pathName a_file
				rename $(namewave + num2str(0)), $namewave
//				matrixToVector(waves=ChStr, namewave=waveprefix, strow=-1, enrow=29, stcol=0, encol=Dimsize(awave,1)-1, stdepth=0, endepth=0)
//				Killwaves awave
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
	elseif (type == 2) // Osort
		pathName = "home"
		txt_t = "_t"
		txt_vm = "_vm"
		txt_mic = "_mic"
		regExpr = "([0-9a-z]+)_.*_([0-9]+)_Osort_A([0-9]+)_([a-zA-Z0-9]+).txt"
		findex = 0
		newPath /Z /O /Q CurrentPath
		filelist = IndexedFile(CurrentPath, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		pathinfo CurrentPath
		pathName = S_path
		Do
			if (GrepString(a_file,filename))
				splitString /E=(regExpr) a_file, fileprefix, rectime, recCh, spikename
				namewave = "Os" + rectime + "_A" + recCh + spikename

				print "\t", findex, " : ", a_file, " as ", namewave
				LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
				Duplicate /O $(namewave + num2str(0)), $namewave
				Killwaves $(namewave + num2str(0))
//				matrixToVector(waves=ChStr, namewave=waveprefix, strow=-1, enrow=29, stcol=0, encol=Dimsize(awave,1)-1, stdepth=0, endepth=0)
//				Killwaves awave
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
	elseif (type == 3) // intan?
		pathName = "home"
		findex = 0
		newPath /Z /O /Q CurrentPath
		filelist = IndexedFile(CurrentPath, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		pathinfo CurrentPath
		pathName = S_path
		Do
			if (GrepString(a_file,filename))
				if (stringmatch(a_file, "*_amp*"))
					regExpr = "[0-9a-z]+_[0-9]+_([0-9]+)_ampA([0-9]+).txt"
					fileprefix = "amp"
				elseif  (stringmatch(a_file, "*_adc*"))
					regExpr = "[0-9a-z]+_[0-9]+_([0-9]+)_adcADC([0-9]+).txt"
					fileprefix = "adc"
				elseif (stringmatch(a_file, "*_t*"))
					regExpr = "[0-9a-z]+_[0-9]+_([0-9]+)_t.txt"
					fileprefix = "t"
				endif
				splitString /E=(regExpr) a_file, rectime, recCh
				namewave = fileprefix + rectime + "_" + recCh
				print "\t", findex, " : ", a_file, " as ", namewave
				LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
				Duplicate /O $(namewave + num2str(0)), $namewave
				Killwaves $(namewave + num2str(0))
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
	elseif (type == 4) // csv. (features from MasaClassifySyllable)
		pathName = "home"
		newPath /Z /O /Q CurrentPath
		filelist = IndexedFile(CurrentPath, -1, ".csv")
		pathinfo CurrentPath
		pathName = S_path
		findex = 0
		a_file = StringFromList(findex, filelist)
		Do
			if (GrepString(a_file,filename))
				namewave = replaceString(".csv", a_file, "")
				if (strlen(namewave) > 20)
					namewave = namewave[strlen(namewave)-20, strlen(namewave)-1]
					//namewave = namewave[strlen(namewave)-26, strlen(namewave)-1]
				endif
				print "\t", findex, " : ", a_file, " as ", namewave // this gives error when the file is empty

				//LoadWave /A /H /Q /W /J /N=$(namewave) /P=CurrentPath a_file
				LoadWave /A /H /Q /W /J /O /N=$(namewave) /P=CurrentPath a_file
				//rename $(namewave + num2str(0)), $namewave
 				//renameWaves(waves="*", namewave=namewave, useOldname=1, useNum=1,  num=0, num2=0)
				moveToFolder(wave_a="*", foldername="loaded") 
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
		
	elseif (type == 5) // SongPres
		pathName = "home"
		newPath /Z /O /Q CurrentPath
		pathinfo CurrentPath
		pathName = S_path
		findex = 0
		regExpr = "([0-9a-z]+)_.*_([a-zA-Z0-9]+)_([a-zA-Z]+).txt"
		filelist = IndexedFile(CurrentPath, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		variable filenum = 0
		Do
			if (GrepString(a_file,filename))
				splitString /E=(regExpr) a_file, fileprefix, rectime, recCh // rectime is actually a name of the songstim
				namewave = fileprefix + "_" +  num2str(filenum) + "_" + recCh
				print "\t", findex, " : ", a_file, " as ", namewave
				LoadWave /A /H /Q /W /N=$(namewave) /G /P=CurrentPath a_file
				// Duplicate /O $(namewave + num2str(0)), $namewave
				// Killwaves $(namewave + num2str(0))
				filenum+=1
			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
	elseif (type == 6) // general txt
		pathName = "home"
		newPath /Z /O /Q CurrentPath
		pathinfo CurrentPath
		pathName = S_path
		findex = 0
		//filepath = pathname + a_file

//		print "\t path :\t", pathname
//		print "\t file :\t", filename
				
		filelist = IndexedFile(CurrentPath, -1, ".txt")
		a_file = StringFromList(findex, filelist)
		Do
			if (GrepString(a_file,filename))
				namewave = replaceString(".txt", a_file, "")
				if (strlen(namewave) > 18)
					namewave = namewave[strlen(namewave)-18, strlen(namewave)-1]
					//namewave = namewave[strlen(namewave)-26, strlen(namewave)-1]
				endif
				print "\t", findex, " : ", a_file, " as ", namewave // this gives error when the file is empty
				LoadWave /A /H /Q /W /J /O /N=$(namewave) /P=CurrentPath a_file
 				renameWaves(waves="*", namewave=namewave, useOldname=1, useNum=1,  num=0, num2=0)
				moveToFolder(wave_a="*", foldername="loaded") 
 			endif
			findex+=1
			a_file = StringFromList(findex, filelist)
		While(strlen(a_file)!=0)
	endif
end



function open_EvTAFcbin([filename, type])
	String filename
	Variable type
	if (numType(strlen(filename)) == 2)		// if (waves == null) : so there was no input
		filename="*"
		type = 1
		Prompt filename, "File name"
		Prompt type, "File type 0/1/2/3: WaveClus/RS/Osort/amp,adc,t"
		DoPrompt  "open_txtWave", filename, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "open_txtWave(filename=\"" + filename + "\", type=", num2str(type) + ")"
	endif
	print "   processing ... "
		string a_file, pathName = "", filelist, namewave, txt_t, txt_vm, txt_mic, regExpr
		string rectime, recCh, fileprefix, class, wlist, a_wave, spikename
		variable findex, windex
end


function prep_waveclusWave([folderwave, type, st, en])
	String folderwave
	Variable type, st, en
	if (numType(strlen(folderwave)) == 2)		// if (waves == null) : so there was no input
		folderwave="foldernamewave"
		type = 1; st=-inf; en=inf;
		Prompt type, "Foldername wave? (0/1)"
		Prompt folderwave, "If 1, wave of foldername"
		Prompt st, "Separate files from"
		Prompt en, "to"
		DoPrompt  "prep_waveclusWave", type, folderwave, st, en
		if (V_Flag)	// User canceled
			return -1
		endif
		print "prep_waveclusWave(folderwave=\"" + folderwave + "\", type=", num2str(type) + ", st=", num2str(st) + ", en=", num2str(en) + ")"
	endif
	print "   processing ... "
	string a_file, filelist, List, stRec, enRec, targetFolder
	string rectime, recCh, fileprefix, class, slist, s_file
	variable findex,  recindex, sttime, entime, a_file_left, a_file_delta, sindex
	stRec = "stRec"
	enRec = "enRec"
	wave stRecw = $stRec
	wave enRecw = $enRec
	if (st == -inf)
		sttime = 0
	else
		sttime = st
	endif
	if (en == inf)
		entime = Dimsize(enRecw, 0)
	else
		entime = en
	endif
	if (sttime < 0 || sttime > entime || entime > Dimsize(enRecw, 0))
		abort
	endif

	filelist = WaveList("time_amp",";","")
	filelist = filelist + WaveList("spike*",";","")
	filelist = filelist + WaveList("ADC*",";","")
	findex = 0
	a_file = StringFromList(findex, filelist)
	Do
		recindex = sttime
		Do
			if (type == 1)
				wave /T fw = $folderwave
				targetFolder = fw[recindex]
				targetFolder = replacestring(".wav", targetFolder, "")
				targetFolder = replacestring(".rhd", targetFolder, "")
				targetFolder = replacestring(".mat", targetFolder, "")
				targetFolder = replacestring(".", targetFolder, "")
			else
				targetFolder = "rec" + num2str(recindex)
			endif
			newDataFolder /O $targetFolder
			Duplicate /O /R=[stRecw[recindex], enRecw[recindex]]  $a_file, $(a_file+"_rec"+(num2str(recindex)))
			MoveWave $(a_file+"_rec"+(num2str(recindex))), $(":"+targetFolder+":")
			recindex += 1
		While (recindex < entime)
		Killwaves $a_file
		findex+=1
		a_file = StringFromList(findex, filelist)
	While(strlen(a_file)!=0)
		
	recindex = sttime
	Do
		SetDataFolder $targetFolder
		slist = WaveList("*",";","")
		sindex = 0
		s_file = StringFromList(sindex, slist)
		wave wvt = $s_file
		a_file_left =  wvt[0]
		a_file_delta = round((wvt[1] - wvt[0])*1e5)/1e5
		sindex = 1
		s_file = StringFromList(sindex, slist)
		Do
			SetScale /P x (a_file_left), (a_file_delta), "s", $s_file
			sindex+=1
			s_file = StringFromList(sindex, slist)
		While(strlen(s_file)!=0)
		SetDataFolder ::
		recindex += 1
	While (recindex < entime)

end		

function prep_pClampWaves ([wave1])
	String wave1
	if (numType(strlen(wave1)) == 2)		// if (wave == null) : so there was no input
		wave1="*";
		Prompt wave1, "wave name" //, popup wavelist ("*",";","")
		DoPrompt  "prep_pClampWaves", wave1
		if (V_Flag)	// User canceled
			return -1
		endif
		print "prep_pClampWaves(wave1=\"" + wave1 + "\")"
	endif

	string lista, a_wave
	variable windex=0, pnt_a, sttime, entime
		lista = WaveList(wave1,";","")
		a_wave = StringFromList(windex, lista)
	variable pnt, pntstep
	Do
		wave a = $a_wave
		pnt_a = numpnts(a) 
		sttime = trunc(pnt_a / 64)
		entime = pnt_a - trunc(pnt_a / 64) - 1
		DuplicateWave(wave1=a_wave, destname="", sttime=sttime, entime=entime, dpn=0, printToCmd=0)
				// truncate the first and last holding periods
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
	setWaveScale(waves="*", axis=0, mode=0, delta=50e-6,  sttime=0, entime=0, unitStr="s")
	setWaveScale(waves="*Im*", axis=1, mode=2, delta=0,  sttime=0, entime=0, unitStr="pA")
	setWaveScale(waves="*Vm*", axis=1, mode=2, delta=0,  sttime=0, entime=0, unitStr="mV")
	truncWavename(waves="*", order=1, num=0, num2=1)
	truncWavename(waves="*", order=1, num=2, num2=3)
end

function moveRawData()
	setDataFolder root:raw
	string lista = wavelist("*", ";", "")
	variable windex = 0, dV=0, nMoved = 0, waveLen = 0
	string prefix=""
	string a_wave = stringFromList(windex, lista)
	string last_wave="", targetFolder="", waveStr="", folderStr=""
	print "*moveRawData()"
	print "   processing ... "
	Do
		setDataFolder root:raw
		
		if(numpnts($a_wave) == 50)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:drug"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 388)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_50Hz"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 718)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_40Hz"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 1260 || numpnts($a_wave) == 970)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_20Hz"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 1938)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_10Hz"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 4224 || numpnts($a_wave) == 3876)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_5Hz"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 15280 || numpnts($a_wave) == 14804)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_hyp"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 22600 || numpnts($a_wave) == 21894 || numpnts($a_wave) == 28328)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:VC_IV"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 15056 || numpnts($a_wave) == 15540 || numpnts($a_wave) == 34874)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_hyp"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 15288 || numpnts($a_wave) ==  19860 || numpnts($a_wave) ==  22196 || numpnts($a_wave) ==  32790)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_IV"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 15326)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_D20ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 15366)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_D50ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
//Duke
		if(numpnts($a_wave) == 25906)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_puff_laser10ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 27320)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_puffIV"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 30032)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:seal"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 30904)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser5ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 31000)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser1ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 31194)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:laser1msPPD50ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 32164)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:laser1msPPD100ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 32280)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser5msISI100ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 32416)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msISI100ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 34062)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:Estim:EstimVC"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 24510)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:Estim:EstimIC"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 35016)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:Estim:Estim100HzTetVC"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 42432)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:Estim:Estim100HzTet_IC_dep"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 44582)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:Estim_puff500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 34430)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msISI200ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 34992)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 35030)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser20ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 36058)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI100ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 36814)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser1msISI200ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 36232)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser1msISI100msX4"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 36852)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msX4"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 36876)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msX4"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 38208)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI200ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 38402)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser100ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 40030)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI100msX4"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 40552)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msISI500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 40688 || numpnts($a_wave) == 42626)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser1msISI500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 40340)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser5msISI500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 44020)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 42878)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_dep_puff500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 44602)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_dep"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 44990)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser5ms_50Hz_once"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 45378)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_100Hz_once"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 45436)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms_50Hz_once"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 46500)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser10ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 46462)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser5ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 46618)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser20ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 48230)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:IC_laser1ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 50376)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:laser1msPPD1000ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 50414)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msISI500ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 54038)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI1000ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 70216)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser5msISI2000ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 74192)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:EstimISI2000ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 90288)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_puffSpont"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 130588)
			prefix = a_wave[0, strlen(a_wave)-2]
			targetFolder = "root:VC_laser10msISI5000ms"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 640000 || numpnts($a_wave) == 620000)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:VC_spont"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		if(numpnts($a_wave) == 600626)
			prefix = a_wave[0, strlen(a_wave)-4]
			targetFolder = "root:IC_spont"
			newDataFolder /O $targetFolder
			do
				moveWave $a_wave, $(targetFolder+":")
				nMoved += 1
				windex+=1
				a_wave = StringFromList(windex, lista)
			while(stringmatch(a_wave, prefix+"*"))
			print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
			continue
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!= 0)
	print windex, " waves have been processed."
	print nMoved, " waves have been MOVED."
	Silent 1; PauseUpdate
end


function moveWithStim([wave_a, type, sttime, entime, r_sttime, r_entime])
	String wave_a
	Variable type, sttime, entime, r_sttime, r_entime
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "B*4"; sttime=0.5; entime=0.7; r_sttime=0; r_entime=0.5
		Prompt wave_a, "Wave (resting Voltage) name"
		Prompt type, "stim type 0/1 (I/V)"
		Prompt sttime, "stim range (from"
		Prompt entime, "to (s) )"
		Prompt r_sttime, "rest range (from"
		Prompt r_entime, "to (s) )"
		DoPrompt "moveWithStim", wave_a, type, sttime, entime, r_sttime, r_entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*moveWithStim(wave_a=\"" + wave_a + "\", type=" + num2str(type) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", r_sttime=" + num2str(r_sttime) + ", r_entime=" + num2str(r_entime) + " )" 
	endif

	string lista = wavelist(wave_a, ";", "")
	string listall = wavelist("*", ";", "")
	variable windex = 0, allindex=0, dV=0, nMoved = 0
	string prefix=""
	string Vstim_wave = stringFromList(windex, lista)
	string a_wave = stringFromList(allindex, listall)
	string last_wave=""
	string targetFolder=""	
	print "*moveWithStim()"
	print "   processing ... "
	Do
		prefix = Vstim_wave[0, strlen(Vstim_wave)-2]
		wavestats /Q /R=(r_sttime, r_entime) $Vstim_wave
			dV = V_avg
		wavestats /Q /R=(sttime, entime) $Vstim_wave
			dV = V_avg - dV
		if (type == 0)
			if(198e-12 < dV)	//  (> 200pA)
				targetFolder = "p_above200"
			elseif(193e-12 < dV)
				targetFolder = "p195"
			elseif(188e-12 < dV)
				targetFolder = "p190"
			elseif(183e-12 < dV)
				targetFolder = "p185"
			elseif(178e-12 < dV)
				targetFolder = "p180"
			elseif(173e-12 < dV)
				targetFolder = "p175"
			elseif(168e-12 < dV)
				targetFolder = "p170"
			elseif(163e-12 < dV)
				targetFolder = "p165"
			elseif(158e-12 < dV)
				targetFolder = "p160"
			elseif(153e-12 < dV)
				targetFolder = "p155"
			elseif(148e-12 < dV)
				targetFolder = "p150"
			elseif(143e-12 < dV)
				targetFolder = "p145"
			elseif(138e-12 < dV)
				targetFolder = "p140"
			elseif(133e-12 < dV)
				targetFolder = "p135"
			elseif(128e-12 < dV)
				targetFolder = "p130"
			elseif(123e-12 < dV)
				targetFolder = "p125"
			elseif(118e-12 < dV)
				targetFolder = "p120"
			elseif(113e-12 < dV)
				targetFolder = "p115"
			elseif(108e-12 < dV)
				targetFolder = "p110"
			elseif(103e-12 < dV)
				targetFolder = "p105"
			elseif(98e-12 < dV)
				targetFolder = "p100"
			elseif(93e-12 < dV)
				targetFolder = "p95"
			elseif(88e-12 < dV)
				targetFolder = "p90"
			elseif(83e-12 < dV)
				targetFolder = "p85"
			elseif(78e-12 < dV)
				targetFolder = "p80"
			elseif(73e-12 < dV)
				targetFolder = "p75"
			elseif(68e-12 < dV)
				targetFolder = "p70"
			elseif(63e-12 < dV)
				targetFolder = "p65"
			elseif(58e-12 < dV)
				targetFolder = "p60"
			elseif(53e-12 < dV)
				targetFolder = "p55"
			elseif(48e-12 < dV)
				targetFolder = "p50"
			elseif(43e-12 < dV)
				targetFolder = "p45"
			elseif(38e-12 < dV)
				targetFolder = "p40"
			elseif(33e-12 < dV)
				targetFolder = "p35"
			elseif(28e-12 < dV)
				targetFolder = "p30"
			elseif(23e-12 < dV)
				targetFolder = "p25"
			elseif(18e-12 < dV)
				targetFolder = "p20"
			elseif(13e-12 < dV)
				targetFolder = "p15"
			elseif(8e-12 < dV)
				targetFolder = "p10"
			elseif(3e-12 < dV)
				targetFolder = "p5"
			elseif(-2e-12 < dV)
				targetFolder = "p0"
			elseif(-7e-12 < dV)
				targetFolder = "m5"
			elseif(-12e-12 < dV)
				targetFolder = "m10"
			elseif(-17e-12 < dV)
				targetFolder = "m15"
			elseif(-22e-12 < dV)
				targetFolder = "m20"
			elseif(-27e-12 < dV)
				targetFolder = "m25"
			elseif(-32e-12 < dV)
				targetFolder = "m30"
			elseif(-37e-12 < dV)
				targetFolder = "m35"
			elseif(-42e-12 < dV)
				targetFolder = "m40"
			elseif(-47e-12 < dV)
				targetFolder = "m45"
			elseif(-52e-12 < dV)
				targetFolder = "m50"
			else
				targetFolder = "below_m50"
			endif
		else
			if(75e-3 < V_avg)
				targetFolder = "above_p80"
			elseif(65e-3 < V_avg)
				targetFolder = "p70"
			elseif(55e-3 < V_avg)
				targetFolder = "p60"
			elseif(45e-3 < V_avg)
				targetFolder = "p50"
			elseif(35e-3 < V_avg)
				targetFolder = "p40"
			elseif(25e-3 < V_avg)
				targetFolder = "p30"
			elseif(15e-3 < V_avg)
				targetFolder = "p20"
			elseif(5e-3 < V_avg)
				targetFolder = "p10"
			elseif(-5e-3 < V_avg)
				targetFolder = "p0"
			elseif(-15e-3 < V_avg)
				targetFolder = "m10"
			elseif(-25e-3 < V_avg)
				targetFolder = "m20"
			elseif(-35e-3 < V_avg)
				targetFolder = "m30"
			elseif(-45e-3 < V_avg)
				targetFolder = "m40"
			elseif(-55e-3 < V_avg)
				targetFolder = "m50"
			elseif(-65e-3 < V_avg)
				targetFolder = "m60"
			elseif(-75e-3 < V_avg)
				targetFolder = "m70"
			elseif(-85e-3 < V_avg)
				targetFolder = "m80"
			elseif(-95e-3 < V_avg)
				targetFolder = "m90"
			else
				targetFolder = "below_m90"
			endif
		endif
		newDataFolder /O $targetFolder
		do
			moveWave $a_wave, $(":" + targetFolder + ":")
			nMoved += 1
			allindex+=1
			a_wave = StringFromList(allindex, listall)
		while(stringmatch(a_wave, prefix+"*"))
		print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
		windex +=1
		Vstim_wave = StringFromList(windex, lista)		
	While(strlen(a_wave)!= 0)
	print windex, " waves have been processed."
	print nMoved, " waves have been MOVED."
	Silent 1; PauseUpdate
end

////

function moveToFolder([wave_a, foldername])
	String wave_a, foldername
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "B*4"; foldername = "";
		Prompt wave_a, "Wave (resting Voltage) name"
		Prompt foldername, "folder name"
		DoPrompt "moveToFolder", wave_a, foldername
		if (V_Flag)	// User canceled
			return -1
		endif
		print "moveToFolder(wave_a=\"" + wave_a + "\", foldername=\"" + foldername + "\")" 
	endif

	string lista, a_wave, targetFolder
	variable windex
	if (stringmatch(foldername, ""))
		targetFolder = "waves"
	else
		targetFolder = foldername
	endif
	newDataFolder /O $targetFolder
	lista = wavelist(wave_a, ";", "")
	windex = 0
	a_wave = stringFromList(windex, lista)
	Do
		if (strlen(a_wave)== 0)
			break
		endif
		moveWave $a_wave, $(":" + targetFolder + ":")
		windex +=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!= 0)
	print windex, " waves have been moved."
end



function moveToFolderWithLabel([wave_a, foldername, labelwave, labeltype, sttime, entime, interval])
	String wave_a, foldername, labelwave
	Variable labeltype, sttime, entime, interval
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "song_bout_*"; foldername = "hour"; labelwave = "songOnset_t_hour"
		labeltype = 0; sttime=0; entime=24; interval=1
		Prompt wave_a, "Wave (resting Voltage) name"
		Prompt foldername, "folder name"
		Prompt labelwave, "label name"
		Prompt labeltype, "0/1: (num/str)"	// !!!!!!!!!!!!!!!!!!!!!!!!!!!!! This works with only 0 
		Prompt sttime, "label from (<=)"
		Prompt entime, "to (>)"
		Prompt interval, "label interval "
		DoPrompt "moveToFolderWithLabel", wave_a, foldername, labelwave, labeltype, sttime, entime, interval
		if (V_Flag)	// User canceled
			return -1
		endif
		print "moveToFolderWithLabel(wave_a=\"" + wave_a + "\", foldername=\"" + foldername + "\", labelwave=\"" + labelwave + "\", labeltype=" + num2str(labeltype) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", interval=" + num2str(interval) + ")" 
	endif

	string lista, a_wave, targetFolder
	variable windex, len_l, lindex
	if (interval > (entime - sttime))
		interval = entime - sttime
	endif
	wave l = $labelwave
	len_l = numpnts(l)
	lista = wavelist(wave_a, ";", "")
	windex = 0
	a_wave = stringFromList(windex, lista)
	Do
		if (l[windex] < sttime)
			targetFolder = foldername + "_lower"
		elseif (l[windex] >= entime)
			targetFolder = foldername + "_upper"
		else
			lindex = sttime
			Do				
				if (l[windex] < (lindex+interval))
					targetFolder = foldername + "_"+ ReplaceString(".", num2str(lindex), "_")
					break
				endif
				lindex +=interval
			While(lindex <= entime)
		endif
		newDataFolder /O $targetFolder
		moveWave $a_wave, $(":" + targetFolder + ":")
		windex +=1
		a_wave = StringFromList(windex, lista)
	While(windex < len_l)
	print windex, " waves have been moved."


end


/////


function moveWithVrest([wave_a, sttime, entime])
	String wave_a
	Variable sttime, entime
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "*Vm*"; sttime=0; entime=0
		Prompt wave_a, "Wave (resting Voltage) name"
		Prompt sttime, "range from"
		Prompt entime, "to"
		DoPrompt "moveWithVrest", wave_a, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*moveWithVrest(wave_a=\"" + wave_a + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + " )" 
	endif
	
	string lista = wavelist(wave_a, ";", "")
	string listall = wavelist("*", ";", "")
	variable windex = 0, allindex=0, restV=0, nMoved = 0
	variable unit = 1
	string prefix=""
	string Vrest_wave = stringFromList(windex, lista)
	string a_wave = stringFromList(allindex, listall)
	string last_wave
	string targetFolder
	print "   processing . . . "

	Do
		prefix = Vrest_wave[0, strlen(a_wave)-10]
		if(entime==0)
			entime = deltax($a_wave)*(numpnts($a_wave)-1)
		endif
		if(entime<=sttime)
			abort
		endif
		wavestats /Q /R=(sttime, entime) $Vrest_wave
			restV = V_avg
		if(65*unit < restV)	//  (-70mV + >145mV = +75mV)
			targetFolder = "Vh70mV"
		elseif(55*unit < restV)
			targetFolder = "Vh60mV"
		elseif(45*unit < restV)
			targetFolder = "Vh50mV"
		elseif(35*unit < restV)
			targetFolder = "Vh40mV"
		elseif(25*unit < restV)
			targetFolder = "Vh30mV"
		elseif(15*unit < restV)
			targetFolder = "Vh20mV"
		elseif(5*unit < restV)
			targetFolder = "Vh10mV"
		elseif(-5*unit < restV)
			targetFolder = "Vh0mV"
		elseif(-15*unit < restV)
			targetFolder = "Vh_m10mV"
		elseif(-25*unit < restV)
			targetFolder = "Vh_m20mV"
		elseif(-35*unit < restV)
			targetFolder = "Vh_m30mV"
		elseif(-45*unit < restV)
			targetFolder = "Vh_m40mV"
		elseif(-52.5*unit < restV)
			targetFolder = "Vh_m50mV"
		elseif(-57.5*unit < restV)
			targetFolder = "Vh_m55mV"
		elseif(-65*unit < restV)
			targetFolder = "Vh_m60mV"
		elseif(-75*unit < restV)
			targetFolder = "Vh_m70mV"
		elseif(-8*unit < restV)
			targetFolder = "Vh_m80mV"
		elseif(-95*unit < restV)
			targetFolder = "Vh_m90mV"
		elseif(-105*unit < restV)
			targetFolder = "Vh_m100mV"
		elseif(-115*unit < restV)
			targetFolder = "Vh_m110mV"
		elseif(-125*unit < restV)
			targetFolder = "Vh_m120mV"
		endif
		newDataFolder /O $targetFolder

		do
			moveWave $a_wave, $(":" + targetFolder + ":")
			nMoved += 1
			allindex+=1
			a_wave = StringFromList(allindex, listall)
		while(stringmatch(a_wave, prefix+"*"))
		
		print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
		windex +=1
		Vrest_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!= 0)
	print " . . . finished"
end


function moveWithIrest([wave_a, sttime, entime])
	String wave_a
	Variable sttime, entime
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "*Im*"; sttime=0; entime=0
		Prompt wave_a, "Wave (resting Current) name"
		Prompt sttime, "range from"
		Prompt entime, "to"
		DoPrompt "moveWithIrest", wave_a, sttime, entime
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*moveWithIrest(wave_a=\"" + wave_a + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + " )" 
	endif
	
	string lista = wavelist(wave_a, ";", "")
	string listall = wavelist("*", ";", "")
	variable windex = 0, allindex=0, restV=0, nMoved = 0, labelV = 0
	variable unit = 1
	string prefix=""
	string Vrest_wave = stringFromList(windex, lista)
	string a_wave = stringFromList(allindex, listall)
	string last_wave
	string targetFolder
	print "   processing . . . "

	Do
		if (strlen(a_wave) == 0)
			print "      no wave found."
			break
		endif
		prefix = Vrest_wave[0, 3]	// for Axoclamp data
		if(entime==0)
			entime = deltax($a_wave)*(numpnts($a_wave)-1)
		endif
		if(entime<=sttime)
			abort
		endif
		wavestats /Q /R=(sttime, entime) $Vrest_wave
			restV = V_avg
			if (restV > 0)
				labelV = trunc((restV/unit + 2.5) / 5) * 5
			else
				labelV = trunc((restV/unit - 2.5) / 5) * 5
			endif
		if (labelV >= 0)
			targetFolder = "Ih_" + num2str(labelV) + "pA"
		else
			targetFolder = "Ih_m" + num2str(abs(labelV)) + "pA"
		endif
		newDataFolder /O $targetFolder
		do
			if (!stringmatch(a_wave, prefix+"*") || strlen(a_wave) == 0)
				break
			endif
			moveWave $a_wave, $(":" + targetFolder + ":")
			nMoved += 1
			allindex+=1
			a_wave = StringFromList(allindex, listall)
		while(stringmatch(a_wave, prefix+"*"))
		print "   " + num2str(windex) + " : " + prefix + " -> " + targetFolder
		windex +=1
		Vrest_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!= 0)
	print " . . . finished"
end

function sortWaves ()
	string lista = wavelist("*", ";", "")
	lista = sortList(lista, ";", 16)
	variable windex = 0, dV=0, nMoved = 0
	string a_wave = stringFromList(windex, lista)
	newDataFolder /O temp
	do
		moveWave $a_wave, :temp:
		nMoved += 1
		windex += 1
		a_wave = StringFromList(windex, lista)
	while(strlen(a_wave)!=0)
end


function deletesWaves ([wave_a, type, condition, cond_val])
	String wave_a
	Variable type, condition, cond_val
	if (numType(strlen(wave_a)) == 2)	// if (wave_a == null) : so there was no input
		wave_a = "phrase*"; type=0
		Prompt wave_a, "Wave name"
		Prompt type, "0/1 only current/include sub"
		Prompt condition, "0/1 (none/val<sttime)"
		Prompt cond_val, "condition value"
		DoPrompt "deletesWaves", wave_a, type, condition, cond_val
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*deletesWaves(wave_a=\"" + wave_a + "\", type=" + num2str(type) + ", condition=" + num2str(condition) + ", cond_val=" + num2str(cond_val) + ")" 
	endif

	string lista, a_wave, listFolder, a_folder, home_folder
	variable findex = 0, windex = 0
	lista = wavelist(wave_a, ";", "")
	a_wave = stringFromList(windex, lista)
	do
		if (condition == 1)
			if (cond_val < leftx($a_wave))
				killwaves $a_wave
				print  "\t", a_wave, "deleted"
			endif
		else
			killWaves $a_wave
			print  "\t", a_wave, "deleted"
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	while(strlen(a_wave)!=0)
	if (type == 1)
		home_folder = getDataFolder(1)
		listFolder = dataFolderDir(1)
		
		print listFolder
		a_folder = stringFromList(findex, listFolder, ",")
		do
			SetDataFolder $a_folder
			lista = wavelist(wave_a, ";", "")
			windex = 0
			a_wave = stringFromList(windex, lista)
			do
				if (condition == 1)
					if (cond_val < leftx($a_wave))
						killwaves $a_wave
						print  "\t", a_folder, a_wave, "deleted"
					endif
				else
					killWaves $a_wave
					print  "\t", a_folder, a_wave, "deleted"
				endif
				windex += 1
				a_wave = StringFromList(windex, lista)
			while(strlen(a_wave)!=0)
			SetDataFolder $home_folder
			findex += 1
			a_folder = stringFromList(findex, listFolder, ",")
		while(strlen(a_folder)!=0)
	endif
end


function displayWaves ([ waveY, waveX, stY, enY, sttime, entime, Laxislabel, Raxislabel, color, dpn])
	String waveY, waveX, Laxislabel, Raxislabel
	Variable sttime, entime, stY, enY, color, dpn
	if (numType(strlen(waveY)) == 2)	// if (waveY == null) : so there was no input
		waveY = "*Im*"; waveX = ""; Laxislabel = "left"; Raxislabel = "";
		sttime=-inf; entime=inf; stY=0; enY=1; color=0; dpn=1;
		Prompt waveY, "Wave y name"
		Prompt waveX, "Wave x name"
		Prompt stY,"Y from"
		Prompt enY,"to (0-1)"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt Laxislabel,"Left axis label"
		Prompt Raxislabel,"Right axis label"
		Prompt color,"color 0/1(BK/Random)"
		Prompt dpn,"1/2 (new/append)"
		DoPrompt  "displayWaves", waveY, waveX, stY, enY, sttime, entime, Laxislabel, Raxislabel, color, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print " displayWaves(waveY=\"" + waveY + "\", waveX=\"" + waveX + "\", stY=" + num2str(stY)  + ", enY=" + num2str(enY) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", Laxislabel=\"" + Laxislabel + "\", Raxislabel=\"" + Raxislabel + "\", color=" + num2str(color) + ", dpn=" + num2str(dpn) + ")"
	endif
	
	if (dpn == 1)
		Display /K=0
	endif

	variable stmin=0, enmax=0, windex
	string listY , Y_wave, listX , X_wave
	wave wx
	listY = WaveList(waveY,";","")
	windex=0
	Y_wave = StringFromList(windex, listY)	
	if (strlen(waveX)!=0)
		listX = WaveList(waveX,";","")
		X_wave = StringFromList(windex, listX)
	endif
	if (strlen(Y_wave)!=0)
		do
			Y_wave = StringFromList(windex, listY)
			if (sttime == -inf)
				if (strlen(waveX)!=0)
					wavestats /Q $X_wave
					stmin = min(stmin, V_min)
				else
					stmin = min(stmin, leftx($Y_wave))
				endif
			endif
			if (entime == inf)
				if (strlen(waveX)!=0)
					wavestats /Q $X_wave
					enmax = max(enmax, V_max)
				else
					enmax = max(enmax, rightx($Y_wave))
				endif
			endif
			if (strlen(Laxislabel) != 0)
				if (strlen(waveX)!=0)
					AppendToGraph/L=$Laxislabel $Y_wave vs $X_wave
				else
					AppendToGraph/L=$Laxislabel $Y_wave
				endif
				ModifyGraph axisEnab($Laxislabel)={stY,enY}
				ModifyGraph freePos($Laxislabel)=0
			elseif (strlen(Raxislabel) != 0)
				if (strlen(waveX)!=0)
					AppendToGraph/R=$Raxislabel $Y_wave vs $X_wave
				else
					AppendToGraph/R=$Raxislabel $Y_wave
				endif
				ModifyGraph axisEnab($Raxislabel)={stY,enY}
				ModifyGraph freePos($Raxislabel)=0
			endif
			if (color)
				ModifyGraph rgb($Y_wave)=(abs(enoise(65535)),abs(enoise(65535)),abs(enoise(65535)))
			else
				ModifyGraph rgb($Y_wave)=(18704,18704,18704)	// gray
			endif
			windex+=1		
			Y_wave = StringFromList(windex, listY)
			if (strlen(waveX)!=0)
				X_wave = StringFromList(windex, listX)
			endif
		while(strlen(Y_wave)!=0)
	endif
	SetAxis bottom stmin, enmax
end



function displayWavesCircleSize ([ waveL, waveR, sttime, entime, axis, color, dpn])
	String waveL, waveR, axis
	Variable sttime, entime, color, dpn
	if (numType(strlen(waveL)) == 2)	// if (waveL == null) : so there was no input
		waveL = "i_p*"; waveR = ""; axis="left1"
		sttime=-inf; entime=inf; color=0; dpn=1;
		Prompt waveL, "Wave1(size) name"
		Prompt waveR, "Wave2(x) name"
		Prompt sttime,"RANGE from (sec)"
		Prompt entime,"to (sec)"
		Prompt axis,"axis name"
		Prompt color,"0/1 blk/red"
		Prompt dpn,"1/2 (new/append)"
		DoPrompt  "displayWavesCircleSize", waveL, waveR, sttime, entime, axis, color, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*displayWavesCircleSize(waveL=\"" + waveL + "\", waveR=\"" + waveR + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", axis=\"" + axis + "\", color=" + num2str(color) + ", dpn=" + num2str(dpn) + ")"
	endif
	
	if (dpn == 1)
		Display /K=0
	endif

	variable stmin=0, enmax=0
	string listL , L_wave, ywave
		listL = WaveList(waveL,";","")
		variable windex=0
		L_wave = StringFromList(windex, listL)
		if (strlen(L_wave)!=0)
			do
				L_wave = StringFromList(windex, listL)
				if (sttime == -inf)
					stmin = min(stmin, leftx($L_wave))
				endif
				if (entime == inf)
					enmax = max(enmax, rightx($L_wave))
				endif

  				assignValues(waves=(L_wave), destname="y", type=1, value=num2str(windex), sttime=-inf, entime=inf, dpn=3)
  				ywave = "y_" + L_wave
  				AppendToGraph/L=$axis $ywave
				ModifyGraph zmrkSize($ywave)={$L_wave,1,20,1,10}	// range 1-20
				ModifyGraph zColor($ywave)={$L_wave,1,20,Grays,1}	// range 1-20
				ModifyGraph mode($ywave)=3
				ModifyGraph marker($ywave)=8
				ModifyGraph rgb($ywave)=(18704,18704,18704)	// gray
				windex+=1
				L_wave = StringFromList(windex, listL)
			while(strlen(L_wave)!=0)
		endif
//		SetAxis bottom stmin, enmax
end

function displayWavesEachWin ([waves, numwin, stY, enY, sttime, entime, order, color, dpn])
	String waves
	Variable numwin, sttime, entime, stY, enY, order, color, dpn
	if (numType(strlen(waves)) == 2)	// if (waveL == null) : so there was no input
		waves = "FR*"
		sttime=-inf; entime=inf; numwin=0; stY=-inf; enY=inf; order=0; color=0; dpn=1;
		Prompt waves, "Wave name"
		Prompt numwin, "numwin (if 0, num waves)"
		Prompt stY,"Y from"
		Prompt enY,"to"
		Prompt sttime,"X from (sec)"
		Prompt entime,"to (sec)"
		Prompt order, "order 0/1 (from top/bottom)"
		Prompt color,"color 0/1(BK/Random)"
		Prompt dpn,"1/2 (new/append)"
		DoPrompt  "displayWaves", waves, numwin, stY, enY, sttime, entime, color, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*displayWavesEachWin(waves=\"" + waves + "\", numwin=" + num2str(numwin) + ", stY=" + num2str(stY)  + ", enY=" + num2str(enY) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", color=" + num2str(color) + ", dpn=" + num2str(dpn) + ")"
	endif
	
	if (dpn == 1)
		Display /K=0
	endif

	variable stmin=0, enmax=0
	string lista , awave, axisname
	variable windex=0
	lista = WaveList(waves,";","")
	awave = StringFromList(windex, lista)	
	if (strlen(awave)!=0)
		do
			if (sttime == -inf)
				stmin = min(stmin, leftx($awave))
			endif
			if (entime == inf)
				enmax = max(enmax, rightx($awave))
			endif
			axisname = "axisL" + num2str(windex)
			AppendToGraph /L=$axisname $awave
			if (color)
				ModifyGraph rgb($awave)=(abs(enoise(65535)),abs(enoise(65535)),abs(enoise(65535)))
			else
				ModifyGraph rgb($awave)=(18704,18704,18704)	// gray
			endif
			windex+=1		
			awave = StringFromList(windex, lista)
		while(strlen(awave)!=0)
	endif
	if (numwin == 0)
		numwin = windex
	endif
	if (windex < numwin)
		Do
			axisname = "axisL" + num2str(windex)			
			AppendToGraph /L=$axisname
			windex += 1
		While (windex < numwin)
	endif
	windex = 0
	Do
		axisname = "axisL" + num2str(windex)
		if (order == 0)
			ModifyGraph axisEnab($axisname)={1-(1/numwin*windex+1/numwin*0.8), 1-1/numwin*windex}
		else
			ModifyGraph axisEnab($axisname)={1/numwin*windex,1/numwin*windex+1/numwin*0.8}
		endif
		ModifyGraph freePos($axisname)=0
		windex += 1
	While (windex < numwin)
	SetAxis bottom stmin, enmax

end



macro displayCmJump (waveI, waveCm, waveGm, waveGs, sttime, entime, text)
	String waveI, waveCm, waveGm, waveGs, text="Control"
	Variable sttime=0, entime=0
	Prompt waveI, "WaveCurrent name", popup wavelist ("*",";","")
	Prompt waveCm, "WaveCm name", popup wavelist ("*",";","")
	Prompt waveGm, "WaveGm name", popup wavelist ("*",";","")
	Prompt waveGs, "WaveGs name", popup wavelist ("*",";","")
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	Prompt text, "annotation"
	
	if(entime==0)
		entime = deltax($waveI)*(numpnts($waveI)-1)
	endif
	if(entime<=sttime)
			abort
	endif

Display /K=0

TextBox/C/N=text0/F=0/M/H={0,3,10}/A=LB text

AppendToGraph/L $waveI
AppendToGraph/L=left2 $waveCm
AppendToGraph/R $waveGm
AppendToGraph/R=right2 $waveGs

ModifyGraph axisEnab(left)={0.22,0.7}
ModifyGraph axisEnab(left2)={0,0.2},freePos(left2)=0
ModifyGraph axisEnab(right)={0.75,0.9}
ModifyGraph axisEnab(right2)={0.92,1},freePos(right2)=0

ModifyGraph rgb($waveI)=(8704,8704,8704)		// black
ModifyGraph rgb($waveGm)=(0,52224,0)			// green
ModifyGraph rgb($waveGs)=(0,12800,52224)		// blue

SetAxis bottom sttime,entime
end

macro displayRamp (waveI, waveV, sttime, entime, text)
	String waveI, waveV, text="PTX,STR\r1 mV/ms"
	Variable sttime=0, entime=0
	Prompt waveI, "Wave(I) name", popup wavelist ("*",";","")
	Prompt waveV, "Wave(V) name", popup wavelist ("*",";","")
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	Prompt text, "annotation"
	
	if(entime==0)
		entime = deltax($waveI)*(numpnts($waveI)-1)
	endif
	if(entime<=sttime)
			abort
	endif

Display /K=0

TextBox/C/N=text0/F=0/M/H={0,3,10}/A=LT "\Z12"+ text

AppendToGraph/R $waveV
AppendToGraph/L $waveI

ModifyGraph axisEnab(left)={0,1}
	ModifyGraph rgb($waveI)=(18704,18704,18704)	// gray
ModifyGraph axisEnab(right)={0,1}
	ModifyGraph rgb($waveV)=(5000,5000,52224)		// blue

SetAxis bottom sttime,entime
end

macro displayEvoke (wavePre, wavePost, waveEvoke, sttime, entime, text)
	String wavePre, wavePost, waveEvoke, text="PTX,STR"
	Variable sttime=0, entime=0
	Prompt wavePre, "Wave1(pre) name", popup wavelist ("*",";","")
	Prompt wavePost, "Wave2(post) name", popup wavelist ("*",";","")
	Prompt waveEvoke, "WaveEvoke name", popup wavelist ("*",";","")
	Prompt text, "annotation"
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	
	if(entime==0)
		entime = deltax($wavePre)*(numpnts($wavePre)-1)
	endif
	if(entime<=sttime)
			abort
	endif

Display /K=0

TextBox/C/N=text0/F=0/M/H={0,3,10}/A=RT "\Z12"+ text

AppendToGraph/R $waveEvoke
AppendToGraph/L $wavePre
AppendToGraph/L=left2 $wavePost

ModifyGraph axisEnab(left)={0.6,1}
	ModifyGraph rgb($wavePre)=(18704,18704,18704)	// gray
ModifyGraph axisEnab(left2)={0,0.55},freePos(left2)=0
	ModifyGraph rgb($wavePost)=(8704,8704,8704)	// black
ModifyGraph axisEnab(right)={0,1}
	ModifyGraph rgb($waveEvoke)=(60000, 15000,15000)	// red
	SetAxis right -0.071,-0.009

SetAxis bottom sttime,entime
end


macro displayLight (waveI1, waveI2, waveLight, displayBoth, sttime, entime, text)
	String waveI1, waveI2, waveLight, text="PTX,STR\r-70mV"
	Variable displayBoth=1, sttime=0, entime=0
	Prompt waveI1, "Wave1(upper) name", popup wavelist ("*",";","")
	Prompt waveI2, "Wave2(lower) name", popup wavelist ("*",";","")
	Prompt waveLight, "WaveLight name", popup wavelist ("*",";","")
	Prompt displayBoth,"display both waves? (1/0 : YES/NO)"
	Prompt sttime,"RANGE from (sec)"
	Prompt entime,"to (sec)"
	Prompt text, "annotation"
	
	if(entime==0)
		entime = deltax($waveI1)*(numpnts($waveI1)-1)
	endif
	if(entime<=sttime)
			abort
	endif

Display /K=0

TextBox/C/N=text0/F=0/M/H={0,3,10}/A=RB "\Z12"+ text

AppendToGraph/R $waveLight
AppendToGraph/L $waveI1

variable endpoint = 0
if (displayBoth)
	endpoint = 0.6
	AppendToGraph/L=left2 $waveI2
	ModifyGraph axisEnab(left2)={0,endpoint - 0.05},freePos(left2)=0
	ModifyGraph rgb($waveI2)=(8704,8704,8704)		// black
endif
ModifyGraph axisEnab(left)={endpoint,1}
	ModifyGraph rgb($waveI1)=(18704,18704,18704)	// gray
ModifyGraph axisEnab(right)={0,1}
	ModifyGraph rgb($waveLight)=(5000,52224,5000)	// green

SetAxis bottom sttime,entime
end


macro DisplayPPD (waveI, waveCm, dur1, dur2, onset, int, text, suffix)
	String waveI, waveCm, text="Control", suffix
	Variable onset=1500, dur1=200, dur2=200, int=700
	Prompt waveI, "WaveCurrent name", popup wavelist ("*",";","")
	Prompt waveCm, "IGNORE this textbox", popup wavelist ("*",";","")
	Prompt dur1, "stim1 duration (ms)"
	Prompt dur2, "stim2 duration (ms)"
	Prompt onset, "stim onset (ms)"
	Prompt int, "stim interval (ms)"
	Prompt text, "annotation"
	Prompt suffix, "SUFFIX of wave name"

Display /K=0
TextBox/C/N=text0/F=0/M/H={0,3,10}/A=RB "\Z12interval "+ num2str(int) + " ms.\r" + text

string targetWave
variable sttime, entime, margin
margin = 100
//if (dur2 == 200)
//	margin = dur2/2
//else
//	margin = dur2
//endif
//if (dur == 20)
//	margin = dur
//endif
	onset /= 1000
	dur1 /= 1000
	dur2 /= 1000
	int /= 1000
	margin /= 1000

	targetWave = "PPD1st" + suffix
	sttime = onset - margin
	entime = onset + dur1 + margin
	Duplicate/R=(sttime,entime)/O $waveI $targetWave
	AppendToGraph/L $targetwave
	ModifyGraph rgb($targetwave)=(8704,8704,8704)		// black
	SetScale/P x -margin,deltax($waveI),"s", $targetWave
//	ModifyGraph offset($targetwave)={-sttime-margin,0}

	targetWave = "PPD2nd" + suffix
	sttime = onset + dur1 + int - margin
	entime = onset + dur1 + int + dur2 + margin
	Duplicate/R=(sttime,entime)/O $waveI $targetWave
	AppendToGraph/L $targetwave
	SetScale/P x -margin,deltax($waveI),"s", $targetWave
//	ModifyGraph offset($targetwave)={-sttime-margin,0}

//SetAxis bottom sttime,entime
end
Window Graph7() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(5.25,42.5,399.75,251)
	TextBox/N=text0/F=0/M/H={0,3,10}/A=RB "\\Z12interval 700 ms.\rControl"
EndMacro



macro displaySpontaneous()

subtract("W*2","sub_0-2.5_",Inf,0,0,2.5,1,3)
subtract("W*2","sub_3-5.5_",Inf,0,3,5.5,1,3)
SetScale/P x 2.5e-05,0.0001,"s", 'sub_3-5.5_0','sub_3-5.5_1','sub_3-5.5_2';DelayUpdate
SetScale/P x 2.5e-05,0.0001,"s", 'sub_3-5.5_3','sub_3-5.5_4'
cumulatePlot("sub*",0,0,0,0,"ABS",3)
Display CumulativePlot0ABS,CumulativePlot1ABS,CumulativePlot2ABS,CumulativePlot3ABS,CumulativePlot4ABS,CumulativePlot5ABS,CumulativePlot6ABS,CumulativePlot7ABS,CumulativePlot8ABS,CumulativePlot9ABS as "spontaneous"
ModifyGraph rgb=(52224,52224,52224)
averageWaves("cum*",0,0,"spontaneous",2)
Duplicate Avgspontaneous spontaneousfit
curvefit line, Avgspontaneous /D=spontaneousfit
AppendToGraph spontaneousfit
ModifyGraph rgb(Avgspontaneous)=(13056,13056,13056)
TextBox/C/N=text0/F=0/M/H={0,3,10}/A=RB "\\Z18spontaneous\r( pC/sec)"
end

macro displaySpontaneous200ms()
subtract("W*2","sub_0.0-0.2_",Inf,0,0.0,0.2,1,3)
subtract("W*2","sub_0.2-0.4_",Inf,0,0.2,0.4,1,3)
subtract("W*2","sub_0.4-0.6_",Inf,0,0.4,0.6,1,3)
subtract("W*2","sub_0.6-0.8_",Inf,0,0.6,0.8,1,3)
subtract("W*2","sub_0.8-1.0_",Inf,0,0.8,1.0,1,3)
subtract("W*2","sub_1.0-1.2_",Inf,0,1.0,1.2,1,3)
subtract("W*2","sub_1.2-1.4_",Inf,0,1.2,1.4,1,3)
subtract("W*2","sub_1.4-1.6_",Inf,0,1.4,1.6,1,3)
subtract("W*2","sub_1.6-1.8_",Inf,0,1.6,1.8,1,3)
subtract("W*2","sub_1.8-2.0_",Inf,0,1.8,2.0,1,3)
subtract("W*2","sub_2.0-2.2_",Inf,0,2.0,2.2,1,3)
subtract("W*2","sub_2.2-2.4_",Inf,0,2.2,2.4,1,3)
subtract("W*2","sub_2.4-2.6_",Inf,0,2.4,2.6,1,3)
subtract("W*2","sub_2.6-2.8_",Inf,0,2.6,2.8,1,3)
subtract("W*2","sub_2.8-3.0_",Inf,0,2.8,3.0,1,3)
subtract("W*2","sub_3.0-3.2_",Inf,0,3.0,3.2,1,3)
subtract("W*2","sub_3.2-3.4_",Inf,0,3.2,3.4,1,3)
subtract("W*2","sub_3.4-3.6_",Inf,0,3.4,3.6,1,3)
subtract("W*2","sub_3.6-3.8_",Inf,0,3.6,3.8,1,3)
subtract("W*2","sub_3.8-4.0_",Inf,0,3.8,4.0,1,3)
subtract("W*2","sub_4.0-4.2_",Inf,0,4.0,4.2,1,3)
subtract("W*2","sub_4.2-4.4_",Inf,0,4.2,4.4,1,3)
subtract("W*2","sub_4.4-4.6_",Inf,0,4.4,4.6,1,3)
subtract("W*2","sub_4.6-4.8_",Inf,0,4.6,4.8,1,3)
subtract("W*2","sub_4.8-5.0_",Inf,0,4.8,5.0,1,3)
subtract("W*2","sub_5.0-5.2_",Inf,0,5.0,5.2,1,3)
subtract("W*2","sub_5.2-5.4_",Inf,0,5.2,5.4,1,3)
subtract("W*2","sub_5.4-5.6_",Inf,0,5.4,5.6,1,3)
subtract("W*2","sub_5.6-5.8_",Inf,0,5.6,5.8,1,3)
subtract("W*2","sub_5.8-6.0_",Inf,0,5.8,6.0,1,3)
subtract("W*2","sub_6.0-6.2_",Inf,0,6.0,6.2,1,3)
subtract("W*2","sub_6.2-6.4_",Inf,0,6.2,6.4,1,3)
subtract("W*2","sub_6.4-6.6_",Inf,0,6.4,6.6,1,3)
subtract("W*2","sub_6.6-6.8_",Inf,0,6.6,6.8,1,3)
subtract("W*2","sub_6.8-7.0_",Inf,0,6.8,7.0,1,3)

string lista , a_wave
lista = WaveList("sub*",";","")
variable windex=0
a_wave = StringFromList(windex, lista)
do
	SetScale/P x 2.5e-05,0.0001,"s", $a_wave
	windex+=1
	a_wave = StringFromList(windex, lista)
while(strlen(a_wave)!=0)
display as "spontaneous"
cumulatePlot("sub*",0,0,0,0,"ABS",2)
ModifyGraph rgb=(52224,52224,52224)
averageWaves("cum*",0,0,"spontaneous",2)
Duplicate Avgspontaneous spontaneousfit
curvefit line, Avgspontaneous /D=spontaneousfit
AppendToGraph spontaneousfit
ModifyGraph rgb(Avgspontaneous)=(13056,13056,13056)
TextBox/C/N=text0/F=0/M/H={0,3,10}/A=RB "\\Z18spontaneous\r( pC/sec)"
end



function displayCrosscorrelo ([wave1, wave2, winrange, step,stt,ent, type, destname,dpn ])
	String wave1, wave2, destname
	Variable winrange, step, stt, ent, type, dpn
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		stt=-inf; ent=inf; dpn = 1; type=1;
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt wave2, "Wave2 name"//, popup wavelist ("*",";","")
		Prompt winrange, "tau range (ms)"
		Prompt step, "tau step (ms)"
		Prompt stt,"RANGE from (sec)"
		Prompt ent,"to (sec)"
		prompt destname, "SUFFIX of the destination wave"
		Prompt type,"all-to-all 1/0(y/n)"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "displayCrosscorrelo", wave1, wave2, winrange, step, stt, ent, destname, type, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "displayCrosscorrelo(wave1=\"" + wave1 + "\",wave2=\"" + wave2 + "\",winrange=" + num2str(winrange)  + ",step=" + num2str(step) + ",stt=" + num2str(stt) + ",ent=" + num2str(ent) + ",destname=\"" + destname + "\",type=" + num2str(type) + ",dpn=" + num2str(dpn) + ")"
	endif	
	step /= 1000			// to [sec]
	winrange /=1000		// to [sec]
	
	variable length, width
	string awave, bwave, destwave
	awave = "wave_f"
	bwave = "wave_g"
	variable flag_alltoall, aindex=0, bindex=0, sttime, entime, srcRMS, srcLen, destRMS, destLen, Avgcorr=0, Ncorr=0
	flag_alltoall = type

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	listb = WaveList(wave2,";","")

	if (flag_alltoall)
		aindex=0
		a_wave = StringFromList(aindex, lista)
		Do
			bindex = 0
			b_wave = StringFromList(bindex, listb)
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
				if (strlen(destname) > 0)
					if (stringmatch(a_wave, b_wave))
						destwave = "CorrA_" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
					else
						destwave = "CorrC_" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
					endif
				else
					if (stringmatch(a_wave, b_wave))
						destwave = "CorrA_" + num2str(aindex) + "_" + num2str(bindex)
					else
						destwave = "CorrC_" + num2str(aindex) + "_" + num2str(bindex)
					endif
				endif
				Duplicate /R=(sttime,entime) /O $a_wave, $awave
				Duplicate /R=(sttime,entime) /O $b_wave, $destwave
				WaveStats/Q $awave
				srcRMS= V_rms
				srcLen= numpnts($awave)
				WaveStats/Q $destwave
				destRMS= V_rms
				destLen= numpnts($destwave)	
				Correlate $awave, $destwave
				wave dw = $destwave
				dw /= (srcRMS * sqrt(srcLen) * destRMS * sqrt(destLen))
				wavestats /Q /R=(-winrange, winrange) dw
				if (stringmatch(a_wave, b_wave))
					print " auto-correlogram of ", a_wave, " and ", b_wave, " : ", num2str(V_max), " (", sttime, "to", entime, ")"
				else
					print " crosscorrelogram of ", a_wave, " and ", b_wave, " : ", num2str(V_max), " (", sttime, "to", entime, ")"
					if (numtype(V_max) != 2) /// ! NaN
						Avgcorr += V_max
						Ncorr+=1
					endif
				endif
				killwaves $awave
				if(dpn==1)
					display $destwave
				elseif(dpn==2)
					appendtograph $destwave
				endif
				bindex+=1
				b_wave = StringFromList(bindex, listb)
			While(strlen(b_wave)!=0)
			aindex+=1
			a_wave = StringFromList(aindex, lista)
		While(strlen(a_wave)!=0)
		Avgcorr /= Ncorr
		print " Avg of Cross-correlations of ", Ncorr, " pairs : ", Avgcorr
	else
		variable windex=0
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
		Do
			length =  deltax($a_wave)*(numpnts($a_wave)-1)
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
			print " crosscorrelogram of ", a_wave, " and ", b_wave, " (", sttime, "to", entime, ")"
			
			Duplicate/R=(sttime,entime)/O $a_wave $awave
			Duplicate/R=(sttime,entime)/O $b_wave $bwave
			destwave = "Correlo_" + num2str(windex) + "_" +  destname
			
			//Duplicate/R=(sttime,entime)/O $bwave $destwave
			//wave wa = $awave
			//wave wb = $bwave
			//wave wd = $destwave
			//correlate wa, wd // w2 is now crosscorrelogram
			//wavestats /Q wa
			//variable RMS1 = V_rms
			//variable Len1 = V_npnts
			//wavestats /Q wb
			//variable RMS2 = V_rms
			//variable Len2 = V_npnts
			//wd /= (RMS1 * sqrt(Len1) * RMS2 * sqrt(Len2))	

			crosscorreloNorm(awave, bwave, destwave, winrange,sttime, entime,step)
			killwaves $awave, $bwave
			if(dpn==1)
				display $destwave
			elseif(dpn==2)
				appendtograph $destwave
			endif
			SetScale/I x (winrange*(-1)),winrange,"", $destwave

			windex+=1
			a_wave = StringFromList(windex, lista)
			b_wave = StringFromList(windex, listb)
		While(strlen(a_wave)!=0)
	endif
End


function calcCorr ()
  variable ii = 0
  string target, dest
  Do
	target = "f_FR*_" + num2str(ii)
	dest = num2str(ii)
	  displayCrosscorrelo(wave1=(target),wave2=(target),winrange=500,step=10,stt=-inf,ent=inf,destname=(dest),dpn=3)
	  ii += 1
  While (ii < 100)
End


Function crosscorreloNorm(awave, bwave,destwave, winrange,sttime, entime, taustep)
	string awave, bwave, destwave
	Variable winrange, sttime, entime,taustep

	Make/O/N=((winrange/taustep)*2+1) $destwave
	wave wawave = $awave
	wave wbwave = $bwave
	wave wdestwave = $destwave
	
	variable zt=0, index, len, tau, xtime, pnt,step
	len = entime - sttime
	xtime = sttime
		
	variable  SDa, SDb, avga, avgb
	WaveStats/Q wawave
	SDa=V_sdev
	avga = V_avg
	WaveStats/Q wbwave
	SDb=V_sdev
	avgb = V_avg
	wawave -=avga
	wbwave -=avgb

	tau=(-1)*winrange
	do
		pnt = 0
		step = deltax(wawave)
		for (xtime=sttime; xtime<(entime-step); xtime+=step)
			zt += (wawave(xtime))*(wbwave(xtime+tau))
			xtime += step
			pnt +=1
		endfor
		wdestwave[index]=zt/SDa/SDb/pnt		// normalized
		index +=1
		zt=0
		tau+=taustep
	while (tau<=(winrange+taustep))
	//print "xtime", xtime, ", pnt", pnt, ", index", index

end


function displayGinput ([wave1, dV, sttime, entime, destname, kill, dpn])
	String wave1, destname
	Variable sttime, entime, dV, kill, dpn
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		wave1="0*Im*"; destname="-20mV"
		sttime=0.1; entime=0.6; dV=-20; kill=0; dpn=1
		Prompt wave1, "Wave Im name"//, popup wavelist ("*",";","")
		Prompt dV,"pulse amplitude (mV)"
		Prompt sttime,"pulse from (sec)"
		Prompt entime,"to (sec)"
		prompt destname, "SUFFIX of the destination wave"
		prompt kill, "kill avgWaves? (0/1: No/Yes)"
		prompt dpn, "display? (1/2/3: Yes/append/none)"	
		DoPrompt  "displayGinput", wave1, dV, sttime, entime, destname, kill, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "displayGinput(wave1=\"" + wave1 + "\",dV=" + num2str(dV) + ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", destname=\"" + destname + "\", kill=" + num2str(kill) + ", dpn=" + num2str(dpn) + ")"
	endif

	dV /= 1000

	variable Irest, Istim, Ginput, windex=0, num=0
	string awave, destwave, lista, a_wave
		destwave = "Ginput_" + destname
	
	if(entime<=sttime)
			abort
	endif

	Make/O/N=100 $destwave
	wave d = $destwave
	windex = 0
	lista = WaveList(wave1,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave aw = $a_wave
		wave a = $awave
		if (mod(windex,10) == 0)
			if (windex != 0)
				a /= 10
				printPercentile(wave1=awave, percentile=0.5, stt=0, ent=sttime, suffix="hist_", step=0, kill=1, printToCmd=0)
					Irest = K18 // resting current( mode current from 0 to sttime)
				printPercentile(wave1=awave, percentile=0.5, stt=sttime, ent=entime, suffix="hist_", step=0, kill=1, printToCmd=0)
					Istim = K18
					Ginput = (Istim - Irest) / dV
						print " [" + num2str(num) + "] " + awave + ": G_input: " + num2str(Ginput) +  ", Irest: " + num2str(Irest) + ", Istim : " + num2str(Istim)
				d[num] = Ginput
				if (kill)
					killwaves $awave
				endif
			endif
			awave = "Avg_" + a_wave + "_" + num2str(num)
			Duplicate /O $a_wave $awave
			num+=1
		else
			a = (a * 1) + (aw * 1)
		endif

		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	a /= 10
		printPercentile(wave1=awave, percentile=0.5, stt=0, ent=sttime, suffix="hist_", step=0, kill=1, printToCmd=0)
			Irest = K18 // resting current( mode current from 0 to sttime)
		printPercentile(wave1=awave, percentile=0.5, stt=sttime, ent=entime, suffix="hist_", step=0, kill=1, printToCmd=0)
			Istim = K18
			Ginput = (Istim - Irest) / dV
					print  " [" + num2str(num) + "] " + awave + " : G_input: " + num2str(Ginput) +  ", Irest: " + num2str(Irest) + ", Istim : " + num2str(Istim)
			d[num] = Ginput
		killvariables /Z V_maxloc
		waveStats /Q /R=(1,num) $destwave
//		SetScale /I y V_min, V_max, "S", $destwave
		SetScale /I y V_min, V_max, "pS", $destwave
		if (dpn == 1)
			display $destwave
				SetAxis bottom 1,num
				ModifyGraph mode=3,marker=18,rgb=(13056,13056,13056)
				SetDrawEnv linefgc= (65280,0,0)
				SetDrawEnv xcoord= bottom
				SetDrawEnv linethick= 2.00
				drawLine 2, 0, 2, 3e-9
		endif
		if (dpn == 2)
			appendtograph $destwave
		endif
		if (dpn ==3)
			print " * V_avg: ", V_avg, " nS"
		endif
	Beep
End
