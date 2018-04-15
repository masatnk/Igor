#pragma rtGlobals=1		// Use modern global access method.

menu "tanakaImage"
	submenu "Information"
		"lineProfiles"
		"averageLines"
		"lineProfileHistogram"
		"imageStats3D"
		"patternSpectrogram"
		"correlationScore"
	end
	submenu "Transform"
		"imageEnlarge"
		"subtractMeanImage"
		"adjustImageToTemplate"
	end
	submenu "3D conversion"
		"assignSignals"
		"assembleToMatrix"
		"VectorTo3D"
		"matrixToVector"
		"matrixToMovie"
		"play3Dwave"
		"makeSlidingImages"
		"makeVibratingImages"
		"slide3DImagesWithWaves"
		"average3DImagesTo2D"
	end
	submenu "ROI"
		"makeROISurround"
		"ROItoVector"
	end	
end


function assembleToMatrix([waves, dim, imaginary, namewave])
	String waves, namewave
	Variable dim, imaginary
	if (dim == 0)		// if (dim == null) : so there was no input
		waves="O_I_F_GaussSD10"; namewave="Matrix_O"; dim=1; imaginary=0;
		Prompt waves, "waves (suffix_row_col)"
		Prompt dim, "wave dimension(1-2)"
		Prompt imaginary, "type 0/1 (real/imag)"
		Prompt namewave, "target name"
		DoPrompt  "assembleToMatrix", waves, dim, imaginary, namewave
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* assembleToMatrix(waves=\"" + waves + "\", dim=" + num2str(dim) + ", imaginary=" + num2str(imaginary) + ", namewave=\"" + namewave + "\")"
	endif

	string a_wave, lista
	variable row, col, depth
	variable windex, rowindex, colindex
	lista = WaveList(waves,";","")
	if (dim==1)	// Vector to 2D
		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			row = max(row, numpnts($a_wave))
			windex+=1
			a_wave = StringFromList(windex, lista)
		While (strlen(a_wave) != 0)
		col = windex
		Make /O /N=(row, col) /D $namewave
		wave matrix = $namewave

		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			print a_wave
			wave awave = $a_wave
			if (!waveExists(awave))
				print "null wave during the assignment."
				abort
			endif
			if (imaginary)
				matrix[][windex] = imag(awave[p])
			else
				matrix[][windex] = awave[p]
			endif
			windex+=1
			a_wave = StringFromList(windex, lista)
		While (strlen(a_wave) != 0)
	elseif (dim==2)	// 2D to 3D
		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			row = max(row, DimSize($a_wave, 0))
			col = max(col, DimSize($a_wave, 1))
			windex+=1
			a_wave = StringFromList(windex, lista)
		While (strlen(a_wave) != 0)
		depth = windex
		Make /O /N=(row, col, depth) /D $namewave
		wave matrix = $namewave
		
		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			wave awave = $a_wave
			if (!waveExists(awave))
				print "null wave during the assignment."
				abort
			endif
			if (imaginary)
				matrix[][][windex] = imag(awave[p][q])
			else
				matrix[][][windex] = awave[p][q]
			endif
			windex+=1
			a_wave = StringFromList(windex, lista)
		While (strlen(a_wave) != 0)
	endif

end

```
function vectorTo3D([waves, type, row, col, imaginary, namewave])
	String waves, namewave
	Variable type, row, col, imaginary
	if (row == 0)		// if (row == null) : so there was no input
		waves="O_I_F_GaussSD10"; namewave="Matrix_O"; row=40; col=40; imaginary=0;
		Prompt waves, "waves (suffix_row_col)"
		Prompt type, "waves type 0/1(prefix/waves)"
		Prompt row, "row pnts"
		Prompt col, "col pnts"
		Prompt imaginary, "type 0/1 (real/imag)"
		Prompt namewave, "target name"
		DoPrompt  "vectorTo3D", waves, type, row, col, imaginary, namewave
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* vectorTo3D(waves=\"" + waves + "\", type=" + num2str(type) +  ",row=" + num2str(row) + ", col=" + num2str(col) + ", imaginary=" + num2str(imaginary) + ", namewave=\"" + namewave + "\")"
	endif

	string a_wave, lista
	variable windex, rowindex, colindex, length=0
	if (type==1)
		lista = WaveList(waves,";","")
		windex = 0
		a_wave = StringFromList(windex, lista)
		Do
			length = max(length, numpnts($a_wave))
			windex+=1
			a_wave = StringFromList(windex, lista)
		While (strlen(a_wave) != 0)
		Make /O /N=(row, col, length) /D $namewave
		wave matrix = $namewave

		windex = 0
		rowindex=0
		Do
			colindex=0
			Do
				a_wave = StringFromList(windex, lista)
				wave vector = $a_wave
				if (!waveExists(vector))
					print "null wave during the assignment."
					abort
				endif
				if (imaginary)
					matrix[rowindex][colindex][] = imag(vector[r])
				else
					matrix[rowindex][colindex][] = vector[r]
				endif
				colindex += 1		
				windex += 1
			While(colindex < col)
			rowindex += 1
		While(rowindex < row)
	else
		rowindex=0
		Do
			colindex=0
			Do
				a_wave = waves + "_" + num2str(rowindex) + "_" + num2str(colindex)
				wave vector = $a_wave
				length = max(length, numpnts(vector))
				colindex += 1
			While(colindex < col)
			rowindex += 1
		While(rowindex < row)
		Make /O /N=(row, col, length) /D $namewave
		wave matrix = $namewave
		
		rowindex=0
		Do
			colindex=0
			Do
				a_wave = waves + "_" + num2str(rowindex) + "_" + num2str(colindex)
				wave vector = $a_wave
				if (imaginary)
					matrix[rowindex][colindex][] = imag(vector[r])
				else
					matrix[rowindex][colindex][] = vector[r]
				endif
				colindex += 1
			While(colindex < col)
			rowindex += 1
		While(rowindex < row)
	endif
end
```

function matrixToVector([waves, namewave, strow, enrow, stcol, encol, stdepth, endepth])
	String waves, namewave
	Variable strow, enrow, stcol, encol, stdepth, endepth
	if (enrow == 0)		// if (row == null) : so there was no input
		waves="V_I*"; namewave="Vline";
		strow = 10; enrow=29; stcol=10; encol=29; stdepth=-1; endepth=inf;
		Prompt waves, "3D wave name"
		Prompt namewave, "target name suffix"
		Prompt strow, "row from(if -1, rowline)"
		Prompt enrow, "to"
		Prompt stcol, "col (if -1, colline)"
		Prompt encol, "to"
		Prompt stdepth, "depth (if -1, depthline)"
		Prompt endepth, "to"
		DoPrompt  "matrixToVector", waves, namewave, strow, enrow, stcol, encol, stdepth, endepth
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* matrixToVector(waves=\"" + waves + "\", namewave=\"" + namewave + "\",strow=" + num2str(strow) + ", enrow=" + num2str(enrow) + ", stcol=" + num2str(stcol) + ", encol=" + num2str(encol) + ", stdepth=" + num2str(stdepth) + ", endepth=" + num2str(endepth) + ")"
	endif
	
	string lista, a_wave, targetname, dimstr
	variable rowpnt=1, colpnt=1, depthpnt=1, rowleft=0, colleft=0, depthleft=0
	variable windex=0, n1index=0, n2index=0
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave matrix = $a_wave
		rowpnt = DimSize(matrix ,0)
		rowleft = DimOffset(matrix, 0)
		colpnt = DimSize(matrix ,1)
		colleft = DimOffset(matrix, 1)
		depthleft = DimOffset(matrix, 2)
		depthpnt = DimSize(matrix ,2)
		
		if (strow == -1)
			stcol = max(stcol, colleft)
			encol = min(encol, (colleft + colpnt - 1))
			stdepth = max(stdepth, depthleft)
			endepth = min(endepth, (depthleft + depthpnt - 1))
			n1index=stcol
			Do 
				n2index=stdepth
				Do 
					targetname = namewave + "_p_" + num2str(n1index) + "_" + num2str(n2index)
					Make /O /N=(rowpnt) /D $targetname
					wave vector = $targetname
					vector[] = matrix[p][n1index][n2index]
					n2index += 1
				While (n2index<= endepth)
				n1index += 1
			While (n1index<= encol)
		endif
		if (stcol == -1)
			strow = max(strow, rowleft)
			enrow = min(enrow, (rowleft + rowpnt - 1))
			stdepth = max(stdepth, depthleft)
			endepth = min(endepth, (depthleft + depthpnt - 1))
			n1index=strow
			Do 
				n2index=stdepth
				Do 
					targetname = namewave + "_" + num2str(n1index) + "_p_" + num2str(n2index)
					Make /O /N=(colpnt) /D $targetname
					wave vector = $targetname
					vector[] = matrix[n1index][p][n2index]
					n2index += 1
				While (n2index<= endepth)
				n1index += 1
			While (n1index<= enrow)
		endif
		if (stdepth == -1)
			strow = max(strow, rowleft)
			enrow = min(enrow, (rowleft + rowpnt - 1))
			stcol = max(stcol, colleft)
			encol = min(encol, (colleft + colpnt - 1))
			n1index=strow
			Do 
				n2index=stcol
				Do 
					targetname = namewave + "_" + num2str(n1index) + "_" + num2str(n2index) + "_p"
					Make /O /N=(depthpnt) /D $targetname
					wave vector = $targetname
					vector[] = matrix[n1index][n2index][p]
					n2index += 1
				While (n2index<= encol)
				n1index += 1
			While (n1index<= enrow)
		endif
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function matrixToMovie([waves, moviename, sttime, entime, depth])
	String waves, moviename
	Variable sttime, entime, depth
	if (depth == 0)		// if (row == null) : so there was no input
		waves="Matrix_O*"; moviename="Output"; entime=600; sttime=0; depth=1;
		Prompt waves, "matrix wave"
		Prompt moviename, "movie name"
		Prompt sttime, "depth from"
		Prompt entime, "depth to"
		Prompt depth, "depth/frame"
		DoPrompt  "matrixToMovie", waves, moviename, sttime, entime, depth
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* matrixToMovie(waves=\"" + waves + "\", moviename=\"" + moviename + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", depth=" + num2str(depth) + ")"
	endif

	string a_wave, lista, targetname
	variable depthindex, windex	
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	windex = 0
	Do
//		NewImage $a_wave
//		ModifyImage $a_wave ctab= {-0.07,-0.02,Grays,0}
		targetname = moviename + num2str(windex)
		newmovie /O /a /f=10 as moviename
//		newmovie /O /f=15 as moviename
		depthindex=sttime
		Do
//			wave targetgraph = $targetname
			ModifyImage $a_wave plane= depthindex
			ModifyImage $(a_wave+"#1") plane= depthindex
			DoUpdate
			addmovieframe
			depthindex += depth
		While(depthindex < entime)
		closemovie
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function play3Dwave([waves, moviename, sttime, entime, depth])
	String waves, moviename
	Variable sttime, entime, depth
	if (depth == 0)		// if (row == null) : so there was no input
		waves="Matrix_O*"; moviename="Output"; entime=600; sttime=0; depth=1;
		Prompt waves, "matrix wave"
		Prompt moviename, "movie name"
		Prompt sttime, "depth from"
		Prompt entime, "depth to"
		Prompt depth, "depth/frame"
		DoPrompt  "play3Dwave", waves, moviename, sttime, entime, depth
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* play3Dwave(waves=\"" + waves + "\", moviename=\"" + moviename + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", depth=" + num2str(depth) + ")"
	endif

	string a_wave, lista, targetname
	variable depthindex, windex	
		lista = WaveList(waves,";","")
		a_wave = StringFromList(windex, lista)
	windex = 0
	Do
		textbox /A=LT /N=movieTime /C /B=1 /X=0 /Y=0 0
		depthindex=sttime
		Do
			ModifyImage $a_wave plane= depthindex
			DoUpdate
			ReplaceText /N=movieTime num2str(depthindex)
			depthindex += depth
		While(depthindex < entime)
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function assignSignals([strow, enrow, stcol, encol, sttime, entime, val])
	Variable strow, enrow, stcol, encol, sttime, entime, val
	if (enrow==0)		// if (wave == null) : so there was no input
		strow=12; enrow=27; stcol=12; encol=27; sttime=50; entime=149; val=0.002
		Prompt strow, "row from"
		Prompt enrow, "to"
		Prompt stcol, "column from"
		Prompt encol, "to"
		Prompt sttime, "from"
		Prompt entime, "to"
		Prompt val, "value"
		DoPrompt  "assignSignals", strow, enrow, stcol, encol, sttime, entime, val
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* assignSignals(strow=" + num2str(strow) + ", enrow=" + num2str(enrow) + ", stcol=" + num2str(stcol) + ", encol=" + num2str(encol) +  ", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", val=" + num2str(val) + ")"
	endif

	variable rowindex, colindex
	string targetsuffix = "S10", targetwave = ""

	rowindex = strow
	Do
		colindex = stcol
		Do
			targetwave =  targetsuffix + "_" + num2str(rowindex) + "_" + num2str(colindex)
			wave target = $targetwave
			target[sttime, entime] = val
			colindex += 1
		While(colindex <= encol)
		rowindex += 1
	While(rowindex <= enrow)

End


function lineProfiles ([waves, lineWidth, stX, stY, enX, enY, destname, showLine, cmd])
	String waves, destname
	Variable lineWidth, stX, stY, enX, enY, showLine, cmd
	if (numtype(strlen(waves)) == 2)
		lineWidth=0; stX=0; stY=0; enX=0; enY=0; showLine=0; cmd=0
		Prompt waves, "Wave name"
		Prompt lineWidth,"line width (averaged)[pnt]"
		Prompt stX,"from X [s]"
		Prompt stY,"from Y [s]"
		Prompt enX,"to X [s]"
		Prompt enY,"to Y [s]"
		prompt destname, "SUFFIX of the destination wave"
		Prompt showLine, "draw Line? 0/1/2 (no/newImage/append)"
		Prompt cmd, "show results? 0/1 (no/yes)"
		DoPrompt  "lineProfiles", waves, lineWidth, stX, stY, enX, enY, destname, showLine, cmd
		if (V_Flag)	// User canceled
			return -1
		endif
		print " lineProfiles(waves=\"" + waves + "\", lineWidth=" + num2str(lineWidth) + ", stX=" + num2str(stX) + ", stY=" + num2str(stY) + ", enX=" + num2str(enX) + ", enY=" + num2str(enY) + ", destname=\"" + destname + "\", showLine=" + num2str(showLine) + ", cmd=" + num2str(cmd) + ")"
	endif

	variable funcWidth = lineWidth/2 - 1
	variable stXp, enXp, stYp, enYp
	string beamavg = "W_ISBeamAvg"
	string beammax = "W_ISBeamMax"
	string beammin = "W_ISBeamMin"	
	wave wbavg = $beamavg
	wave wbmax = $beammax
	wave wbmin = $beammin
	
	string lista, a_wave, destwave
	variable n=0, length
		lista = WaveList(waves,";","")
		a_wave = StringFromList(n, lista)
	Do
		destwave = "line" + num2Str(n) + "_" + destname
		if(stX==0 && enX==0 && stY == 0 && enY==0)
			stX = DimOffset($a_wave, 0)
			stY = DimOffset($a_wave, 1)
			enX = stX + (DimSize($a_wave, 0) - 1) * DimDelta($a_wave, 0) 
			enY = stY + (DimSize($a_wave, 1) - 1) * DimDelta($a_wave, 1)
		endif
		if (stX < DimOffset($a_wave, 0) || enX >  DimOffset($a_wave, 0) + (DimSize($a_wave, 0) - 1) * DimDelta($a_wave, 0) ) 
			break
		endif
		if (stY < DimOffset($a_wave, 1) || enY >  DimOffset($a_wave, 1) + (DimSize($a_wave, 1) - 1) * DimDelta($a_wave, 1) ) 
			break
		endif
		stXp = (stX - DimOffset($a_wave, 0) ) / DimDelta($a_wave, 0)
		enXp = (enX - DimOffset($a_wave, 0) ) / DimDelta($a_wave, 0)
		stYp = (stY - DimOffset($a_wave, 1) ) / DimDelta($a_wave, 1)
		enYp = (enY - DimOffset($a_wave, 1) ) / DimDelta($a_wave, 1)
		make /O /n=2 xTrace={stX, enX}
		make /O /n=2 yTrace={stY, enY}

		if (cmd)
			print "    - - line analysis"
			print "    ", n, " : ",  a_wave, " ( [ ", stXp, " , ", stYp, " ] - [ ", enXp, " , ", enYp,  " ] )"
		endif
		ImageLineProfile xWave=xTrace, yWave=yTrace, srcwave=$a_wave, width=funcWidth
		
		if ( Stringmatch(destname,""))	
			destname =a_wave
		endif
		Duplicate/O  W_ImageLineProfile, $destwave
		KillWaves W_ImageLineProfile
		if (stX == enX)
			SetScale/P x stY,DimDelta($a_wave,1), waveunits($a_wave,1), $destwave
		elseif (stY == enY)
			SetScale/P x stX,DimDelta($a_wave,0), waveunits($a_wave,0), $destwave
		endif
		if (cmd)
			print "    - - rectangular analysis"
		endif
		if (DimSize($a_wave, 2) > 0)
			ImageStats /BEAM /M=1 /RECT={stXp, enXp, stYp, enYp} $a_wave
				// calculates only V_avg, V_minLoc, V_maxLoc because /M=1
			variable dim=0
			do
				if (cmd)
					print "      [", dim, "] : avg = ", wbavg[dim], " ; max = ", wbmax[dim], " ; min = ", wbmin[dim]
				endif
				dim+=1
			while (dim < rightX(W_ISBeamAvg))
			KillWaves wbavg
			KillWaves wbmax
			KillWaves wbmin
		else
			V_flag = 0
			ImageStats /M=1 /G={stXp, enXp, stYp, enYp} $a_wave
				// calculates only V_avg, V_minLoc, V_maxLoc because /M=1
			if (cmd)
				if (V_flag == 0)
					print "         avg = ", V_avg, " ; max = ", V_max, " [", V_maxRowLoc, ",", V_maxColLoc, "] ; min = ", V_min, " [", V_minRowLoc, ",", V_minColLoc, "] "
				else
					print "! ! ! ! ! ! ! ! ! ! ! ! ! ! out of range ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! "
				endif
			endif
		endif
		
		if (showLine == 1)
			NewImage  $a_wave
		endif
		if (showLine != 0)
			SetDrawEnv xcoord= top, ycoord= left,linefgc= (65535,65535,65535)
			drawLine stX, stY, enX, enY
		endif

		n+=1
		a_wave = StringFromList(n, lista)
	While(strlen(a_wave)!=0)


End


function lineProfileHistogram ([waves, lineWidth, stX, stY, enX, enY, step, distance, type, normwave])
	String waves, normwave
	Variable lineWidth, stX, stY, enX, enY, step, type, distance
	if (numtype(strlen(waves)) == 2)
		lineWidth=0; stX=0; stY=0; enX=0.1; enY=0.1; step=0.01; type=3; distance=inf;
		Prompt waves, "Wave name"
		Prompt lineWidth,"line width [pnt]"
		Prompt stX,"from X [s]"
		Prompt stY,"from Y [s]"
		Prompt enX,"to X [s]"
		Prompt enY,"to Y [s]"
		Prompt step, "step [s]"
		Prompt distance, "distance (>0: change Y, <0: change X)"
		Prompt type, "type 0/1/2/3: avg/med/Normavg"
		prompt normwave, "wave name for norm (if type==2)"
		DoPrompt  "lineProfileHistogram", waves, lineWidth, stX, stY, enX, enY, step, distance, type, normwave
		if (V_Flag)	// User canceled
			return -1
		endif
		print " lineProfileHistogram(waves=\"" + waves + "\", lineWidth=" + num2str(lineWidth) + ", stX=" + num2str(stX) + ", stY=" + num2str(stY) + ", enX=" + num2str(enX) + ", enY=" + num2str(enY) + ", step=" + num2str(step) + ", distance=" + num2str(distance) + ", type=" + num2str(type) + ", normwave=\"" + normwave + "\")"
	endif
	
	string lista, a_wave, destwave, linename, linename2, resultname, destname, destname2, listb, b_wave
	destname = "tmp"
	destname2 = "tmp_norm"
	linename = "line0_" + destname
	linename2 = "line0_"  + destname2
	resultname = "lineProfileHisto"
	variable n=0, xa, ya, lenx, leny, xx, yy, dxa, dya, leftxa, rightxa, leftya, rightya, Nsum, rindex, rlen, maxy
	lenx = enX - stX
	leny = enY - stY
		lista = WaveList(waves,";","")
		a_wave = StringFromList(n, lista)
		listb = WaveList(normwave,";","")
		b_wave = StringFromList(n, listb)
	Do
		wave wa = $a_wave
		xa = dimSize(wa, 0)
		ya = dimSize(wa, 1)
		dxa = dimDelta(wa, 0)
		dya = dimDelta(wa, 1)
		maxy = dimOffset(wa, 1) + dya * (ya - 1)
		if (distance > 0) // change Y (goes parallel to Y-axis)
			rlen = floor(distance/step)+1
			Make /N=(rlen) /O $resultname
			wave wresult = $resultname
			rindex = 0
			for (rindex=0; rindex<rlen; rindex+=1)
				yy = stY + step * rindex
				if (yy+leny < maxy)
					lineProfiles(waves=a_wave, lineWidth=lineWidth, stX=stX, stY=yy, enX=enX, enY=(yy+leny), destname=destname, showLine=0, cmd=0)
					if (type == 0)
						wresult[rindex] = mean($linename)
					elseif (type ==1)
						wresult[rindex] = statsmedian($linename)
					else
						wave wline = $linename
						lineProfiles(waves=b_wave, lineWidth=lineWidth, stX=stX, stY=yy, enX=enX, enY=(yy+leny), destname=destname2, showLine=0, cmd=0)
						wave wline2 = $linename2
						if (type ==2)
							wline = wline * wline2
							wresult[rindex] = sum(wline) / sum(wline2)
						endif
					endif
				else
					deletepoints rindex, rlen-rindex+1, wresult
					break
				endif
			endfor
			SetScale/P x stY, step,"s", wresult
		endif
		n+=1
		a_wave = StringFromList(n, lista)
		b_wave = StringFromList(n, listb)
	While(strlen(a_wave)!=0)


End



function averageLines([waves, namewave, stpnt, enpnt, dim])
	String waves, namewave
	Variable stpnt, enpnt, dim
	if (stpnt == 0)		// if (row == null) : so there was no input
		waves="V_I*"; namewave="Vline";
		stpnt = -inf; enpnt=inf; dim=0;
		Prompt waves, "3D wave name"
		Prompt namewave, "target name suffix"
		Prompt stpnt, "pnt from"
		Prompt enpnt, "to"
		Prompt dim, "dimension 0/1(row/col section)"
		DoPrompt  "averageLines", waves, namewave, stpnt, enpnt, dim
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* averageLines(waves=\"" + waves + "\", namewave=\"" + namewave + "\", stpnt=" + num2str(stpnt) + ", enpnt=" + num2str(enpnt) + ", dim=" + num2str(dim) + ")"
	endif
	
	string lista, a_wave, targetname, dimstr
	variable windex, pindex, rowpnt=1, colpnt=1, depthpnt=1, nondim = abs(dim-1)
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		targetname = namewave + "_" + a_wave
		if(stpnt < x2pnt(a, DimOffset(a, nondim)))
			stpnt = x2pnt(a, DimOffset(a, nondim))
		endif
		if(enpnt > x2pnt(a, DimOffset(a, nondim)) + DimSize(a, nondim) - 1)
			enpnt = x2pnt(a, DimOffset(a, nondim)) + DimSize(a, nondim) - 1
		endif
		if (stpnt > enpnt)
			abort
		endif
		make /O /N=(DimSize(a, dim)) $targetname
		wave target = $targetname
		print "   " + a_wave + " [ " + num2str(stpnt) + " - " + num2str(enpnt) + " ]"
		pindex=stpnt
		Do
			if (dim == 0)
				target[] += a[p][pindex]
			else
				target[] += a[pindex][p]
			endif
			pindex +=1
		While(pindex <= enpnt)
		target /= pindex
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


function imageStats3D([waves, namewave, type, ROI, stX, enX, stY, enY, stZ, enZ])
	String waves, namewave, ROI
	Variable type, stX, enX, stY, enY, stZ, enZ
	if (enX == 0)		// if (row == null) : so there was no input
		waves="V_I*"; namewave="V";
		type = 1; ROI = "ROIimage";
		stX = 10; enX=29;
		stY = 10; enY=29;
		stZ = -inf; enZ=inf;
		Prompt waves, "3D wave name"
		Prompt namewave, "target name suffix"
		Prompt type, "ROI type 0/1(val/ROIwave)"
		Prompt ROI, "ROI wave (in Folder :ROI:)"
		Prompt stX, "ROI X from"
		Prompt enX, "to"
		Prompt stY, "ROI Y from"
		Prompt enY, "to"
		Prompt stZ, "ROI Z(plane) from"
		Prompt enZ, "to"
		DoPrompt  "imageStats3D", waves, namewave, type, ROI, stX, enX, stY, enY, stZ, enZ
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* imageStats3D(waves=\"" + waves + "\", namewave=\"" + namewave + "\", type=" + num2str(type) + ", ROI=\"" + ROI + "\", stX=" + num2str(stX) + ", enX=" + num2str(enX) + ", stY=" + num2str(stY) + ", enY=" + num2str(enY) + ", stZ=" + num2str(stZ) + ", enZ=" + num2str(enZ) + ")"
	endif
	
	string lista, a_wave, avg, SD, var, RMS, ROIfolder=":ROI:", ROIfolder2=""
	variable windex, pindex, length
	ROIfolder2 = ROI[-inf, strsearch(ROI, ":",0)]
	ROIfolder += ROIfolder2
	ROI = ROI[strsearch(ROI, ":",0)+1, inf]
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		if(stZ < x2pnt(a, DimOffset(a, 2)))
			stZ = x2pnt(a, DimOffset(a, 2))
		endif
		if(enZ > x2pnt(a, DimOffset(a, 2)) + DimSize(a, 2) - 1)
			enZ = x2pnt(a, DimOffset(a, 2)) + DimSize(a, 2) - 1
		endif
		length = enZ - stZ + 1
		if (type)
			avg = namewave + "_avg_" + ROI
			SD = namewave + "_sd_" + ROI
			var = namewave + "_var_" + ROI
			RMS = namewave + "_RMS_" + ROI
			make /O /N=(length) $avg
			make /O /N=(length) $SD
			make /O /N=(length) $var
			make /O /N=(length) $RMS
			wave wavg = $avg
			wave wSD = $SD
			wave wvar = $var
			wave wRMS = $RMS
			pindex=stZ
			Do
				imagestats /R=$(ROIfolder + ROI) /P=(pindex) $a_wave
				wavg[(pindex-stZ)] = V_avg
				wSD[(pindex-stZ)] = V_sdev
				wvar[(pindex-stZ)] = V_sdev * V_sdev
				wRMS[(pindex-stZ)] = V_rms
				pindex +=1
			While(pindex <= enZ)
		else
			if(stX < x2pnt(a, DimOffset(a, 0)))
				stX = x2pnt(a, DimOffset(a, 0))
			endif
			if(enX > x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1)
				enX = x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1
			endif
			if(stY < x2pnt(a, DimOffset(a, 1)))
				stY = x2pnt(a, DimOffset(a, 1))
			endif
			if(enY > x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1)
				enY = x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1
			endif
			if (stX > enX || stY > enY || stZ > enZ)
				abort
			endif
			avg = namewave + "_avg_" + num2str(stX) + "-" + num2str(enX) + "_" + num2str(stY) + "-" + num2str(enY) + "_" + num2str(stZ) + "-" + num2str(enZ)
			SD = namewave + "_sd_" + num2str(stX) + "-" + num2str(enX) + "_" + num2str(stY) + "-" + num2str(enY) + "_" + num2str(stZ) + "-" + num2str(enZ)
			var = namewave + "_var_" + num2str(stX) + "-" + num2str(enX) + "_" + num2str(stY) + "-" + num2str(enY) + "_" + num2str(stZ) + "-" + num2str(enZ)
			RMS = namewave + "_RMS_" + num2str(stX) + "-" + num2str(enX) + "_" + num2str(stY) + "-" + num2str(enY) + "_" + num2str(stZ) + "-" + num2str(enZ)	
			make /O /N=(length) $avg
			make /O /N=(length) $SD
			make /O /N=(length) $var
			make /O /N=(length) $RMS
			wave wavg = $avg
			wave wSD = $SD
			wave wvar = $var
			wave wRMS = $RMS
			pindex=stZ
			Do
				imagestats /G={stX, enX, stY, enY} /P=(pindex) $a_wave
				wavg[pindex] = V_avg
				wSD[pindex] = V_sdev
				wvar[pindex] = V_sdev * V_sdev
				wRMS[pindex] = V_rms
				pindex +=1
			While(pindex <= enZ)
		endif
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


function patternSpectrogram ([wave1, winwidth, step, winrange, rangestep, destname,dpn ])
	// almost same as sliding correlation
	String wave1, destname
	Variable winwidth, step, winrange, rangestep, dpn
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		winwidth=2000; winrange=1000; step=10; rangestep=1; dpn = 1
		Prompt wave1, "Wave1 name"//, popup wavelist ("*",";","")
		Prompt winwidth, "window width (ms)"
		Prompt step, "window step (ms)"
		Prompt winrange, "range (ms)"
		Prompt rangestep, "range step (ms)"
		prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "patternSpectrogram", wave1, winwidth, step, winrange, rangestep, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "patternSpectrogram(wave1=\"" + wave1 + "\",winwidth=" + num2str(winwidth)  + ",step=" + num2str(step)  + ",winrange=" + num2str(winrange)  + ",rangestep=" + num2str(rangestep)  + ",destname=\"" + destname + "\",dpn=" + num2str(dpn) + ")"
	endif
	step /= 1000			// to [sec]
	winwidth /=1000		// to [sec]
	
	variable length, width
	string awave, bwave, destwave, finalpntname, correloname
	awave = "wave_f"
	bwave = "wave_g"
	finalpntname = "patternSpectrogram0"
	correloname = "cR_Correlo_0_0"
	variable flag_alltoall=1, aindex=0, bindex=0, sttime, entime, srcRMS, srcLen, destRMS, destLen, Avgcorr=0, Ncorr=0
	variable ii, jj, xa, xb, da, db, winpnt, steppnt, now, lasttime, ind_a, ind_b, winrangepnt
	variable tmpnum, lenarea, srcSum, destSum

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")

	lasttime = datetime
	if (flag_alltoall)
	
		aindex=0
		a_wave = StringFromList(aindex, lista)
		xa = dimSize($a_wave,0)
		da = deltax($a_wave)
		winpnt = round(winwidth/da)
		winrangepnt = round(winrange/da)
		steppnt = round(step/da)
		Do
			if (numtype(da) ==2 )
				print  "wave not found"
				continue
			endif

			if (strlen(destname) > 0)
				destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
			else
				destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex)
			endif

				make /N=((xa-winpnt)/steppnt+1, winrange/rangestep+1) /O $finalpntname
				SetScale/P x winwidth/2,step,"s", $finalpntname
				SetScale/P y 0,rangestep/1000,"s", $finalpntname
				wave wnd = $finalpntname
				wnd = 0
				ind_a = 0
				for (ii = 0; ii<=xa-winpnt; ii+=steppnt)
					if (strlen(destname) > 0)
						destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
					else
						destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex)
					endif
					Duplicate /R=[ii, ii+winpnt-1] /O $a_wave, $awave
					Duplicate /R=[ii, ii+winpnt-1] /O $a_wave, $destwave
					SetScale/P x 0,da,"s", $awave
					SetScale/P x 0,da,"s", $destwave
					wave wa = $awave
					WaveStats/Q $awave
					srcRMS= V_rms
					srcLen= numpnts($awave)
					WaveStats/Q $destwave
					destRMS= V_rms
					destLen= numpnts($destwave)	
					Correlate $awave, $destwave
					wave dw = $destwave
					dw /= (srcRMS * sqrt(srcLen) * destRMS * sqrt(destLen))
					
					// ** I dont know why this worked before, but this gives me an error
					//RectifyWave(waves=destwave, destname="R", dpn=3)
					compressWave(waves=("R_"+destwave), type=2, bin=(rangestep/1000), width=0, sttime=0, entime=(winrange/1000), destname="c", dpn=3)
					wave dw = $("cR_" + destwave)
					wnd[ind_a][] = dw[q]
					ind_a +=1
				endfor

				
			aindex+=1
			a_wave = StringFromList(aindex, lista)
		While(strlen(a_wave)!=0)

		now = datetime
		print now-lasttime, " s "
	else
		variable windex=0
		a_wave = StringFromList(windex, lista)
		b_wave = StringFromList(windex, listb)
		Do
			length =  deltax($a_wave)*(numpnts($a_wave)-1)
			print " crosscorrelogram of ", a_wave, " and ", b_wave, " (", sttime, "to", entime, ")"
			Duplicate/R=(sttime,entime)/O $a_wave $awave
			Duplicate/R=(sttime,entime)/O $b_wave $bwave
			destwave = "Correlo_" + num2str(windex) + "_" +  destname
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


function correlationScore ([wave1, wave2, winrange, step,stt,ent, destname,dpn ])
	String wave1, wave2, destname
	Variable winrange, step, stt, ent, dpn
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		stt=500; ent=10000; dpn = 1
		Prompt wave1, "Spectrogram1 name"//, popup wavelist ("*",";","")
		Prompt wave2, "Spectrogram2 name"//, popup wavelist ("*",";","")
		Prompt winrange, "window width (ms)"
		Prompt step, "window step (ms)"
		Prompt stt,"Y RANGE from (Hz)"
		Prompt ent,"to (Hz)"
		prompt destname, "SUFFIX of the destination wave"
		Prompt dpn, "Graph 1/2/3 (Display/Append/None)"
		DoPrompt  "correlationScore", wave1, wave2, winrange, step, stt, ent, destname, dpn
		if (V_Flag)	// User canceled
			return -1
		endif
		print "correlationScore(wave1=\"" + wave1 + "\",wave2=\"" + wave2 + "\",winrange=" + num2str(winrange)  + ",step=" + num2str(step) + ",stt=" + num2str(stt) + ",ent=" + num2str(ent) + ",destname=\"" + destname + "\",dpn=" + num2str(dpn) + ")"
	endif	
	/// This function seems to show a bit smaller value when the window size is large
	/// probably due to the smeared effect of the sliding window (moving average degrades the high correlation of a point)
	
	
	step /= 1000			// to [sec]
	winrange /=1000		// to [sec]
	
	variable length, width
	string awave, bwave, destwave, finaldestname, normalname, finalpntname, finalnormname, weightname, weightname2
	awave = "wave_f"
	bwave = "wave_g"
	finaldestname = "result_correlationScore"
	normalname = "norm_correlationScore"
	weightname = "weight_correlationScore"
	weightname2 = "weight2_correlationScore"
	finalpntname = "result_tmp_correlationScore"
	finalnormname = "norm_tmp_correlationScore"
	variable flag_alltoall=1, aindex=0, bindex=0, sttime, entime, srcRMS, srcLen, destRMS, destLen, Avgcorr=0, Ncorr=0
	variable ii, jj, xa, xb, da, db, winpnt, steppnt, now, lasttime, ind_a, ind_b, la, lb
	variable tmpnum, lenarea, srcSum, destSum, avga, avgb, sda, sdb, normcoef, maxa, maxb, avgb2, avga2, normcoef2, ampa, ampb
	variable flagcoef1, flagcoef2
	flagcoef1 = 1
	flagcoef2 = 1

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	listb = WaveList(wave2,";","")

	lasttime = datetime
	if (flag_alltoall)
	
		aindex=0
		a_wave = StringFromList(aindex, lista)
		xa = dimSize($a_wave,0)
		da = deltax($a_wave)
		la = leftx($a_wave)
		winpnt = round(winrange/da)
		steppnt = round(step/da)
		Do
			bindex = 0
			b_wave = StringFromList(bindex, listb)
			xb = dimSize($b_wave,0)
			db = deltax($b_wave)
			lb = leftx($b_wave)
			if (numtype(da) ==2 || numtype(db) ==2)
				print  "wave not found"
				break
			endif
			if (db != da)
				// have to think about the different dx , later
				print db, da
				bindex+=1
				b_wave = StringFromList(bindex, listb)
				continue
			endif
			Do
				if (strlen(destname) > 0)
					destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex) + "_" + destname
				else
					destwave = "Correlo_" + num2str(aindex) + "_" + num2str(bindex)
				endif
				wavestats /Q $a_wave
				avga = V_avg
				sda = V_sdev
				wavestats /Q $b_wave
				avgb = V_avg
				sdb = V_sdev

				make /N=(xa, xb) /O $finaldestname
				make /N=(xa, xb) /O $normalname
				make /N=(xa, xb) /O $weightname
				make /N=(xa, xb) /O $weightname2
				SetScale/P x la,da,"s", $finaldestname
				SetScale/P y lb,db,"s", $finaldestname
				SetScale/P x la,da,"s", $normalname
				SetScale/P y lb,db,"s", $normalname
				SetScale/P x la,da,"s", $weightname
				SetScale/P y lb,db,"s", $weightname
				SetScale/P x la,da,"s", $weightname2
				SetScale/P y lb,db,"s", $weightname2
				wave wd = $finaldestname
				wave wn = $normalname
				wave ww = $weightname
				wave ww2 = $weightname2
				make /N=((xa-winpnt)/steppnt+1, (xb-winpnt)/steppnt+1) /O $finalpntname
				make /N=((xa-winpnt)/steppnt+1, (xb-winpnt)/steppnt+1) /O $finalnormname
				SetScale/P x la,step,"s", $finalpntname
				SetScale/P y lb,step,"s", $finalpntname
				wave wnd = $finalpntname
				wave wnn = $finalnormname
				wd = 0
				wn = 0
				ww = 0
				ww2 = 0
				wnd = 0
				wnn = 0
				ind_a = 0
				for (ii = 0; ii<=xa-winpnt; ii+=steppnt)
					Duplicate /R=[ii, ii+winpnt-1](stt,ent) /O $a_wave, $awave
					wave wa = $awave
//					wa -= mean(wa)
					WaveStats/Q $awave
					srcRMS= V_rms
					srcSum = V_sum
					srcLen= V_npnts
					ind_b = 0
					for (jj = 0; jj<=xb-winpnt; jj+=steppnt)
						Duplicate /R=[jj, jj+winpnt-1](stt,ent) /O $b_wave, $bwave
						wave wb = $bwave
//						wb -= mean(wb)
						//Duplicate /O $bwave, $destwave
						//WaveStats/Q $destwave
						//destRMS= V_rms
						//destSum = V_sum
						//destLen= V_npnts
						//lenarea = destLen * srcLen
						//wb = wa * wb
						// zero-mean normalized cross-correlation
						//tmpnum = sum(wb) * lenarea - srcSum*destSum 
						//tmpnum = tmpnum /  sqrt((lenarea*srcRMS*srcRMS*srcLen - srcSum*srcSum) * (lenarea*destRMS*destRMS*destLen - destSum*destSum))

						// normalized cross-correlation
//						tmpnum = sum(wb) / (srcRMS * sqrt(srcLen) * destRMS * sqrt(destLen))

						//wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += tmpnum

//						wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += sum(wb) / (srcRMS * sqrt(srcLen) * destRMS * sqrt(destLen)) // very slow (77s)

						//wn[ii,ii+winpnt-1][jj,jj+winpnt-1] += 1
//						wnd[ind_a][ind_b] = sum(wb) / (srcRMS * sqrt(srcLen) * destRMS * sqrt(destLen))

//						print ii, jj, wd[ii][jj]
						wavestats /Q wb
						//wb = (wb - V_min) / (V_max - V_min) // peak-normalized
						wb = (wb - V_avg) / V_sdev // SD-normalized
						maxb = V_max
						avgb2 = V_avg
						wavestats /Q wa
						maxa = V_max
						avga2 = V_avg

						//wb = wb - (wa - V_min) / (V_max - V_min) // peak-normalized
						wb = wb - (wa - V_avg) / V_sdev // Sd-normalized
						
						// coef1: reduce the contribution of comparison of weak amplitude windows 
						if (flagcoef1)
							ampa = (avga2 - avga) / sda + 0.1
							ampb = (avgb2 - avgb) / sdb + 0.1
							// normcoef = ( (maxa - avga) / sda + (maxb - avgb) / sdb ) * 1
							normcoef = ((ampa + ampb)) * 3
							if (normcoef <= 0)
								normcoef = 0
							else
								normcoef = 1 - 1/exp(normcoef)
							endif
						endif
						
						// coef2: reduce the score if amplitude is very different 
						if (flagcoef2)
							ampa = (avga2 - avga) / sda - 0.2
							ampb = (avgb2 - avgb) / sdb - 0.2
							if (ampa * ampb < 0) // amplitude went to opposite
								normcoef2 = ((ampa - ampb) * 0.6 ) ^2
							else
								normcoef2 = 0
							endif
							if (normcoef2 <= 0)
								normcoef2 = 1
							else
								normcoef2 = 1/exp(normcoef2) // reduce the correlation if amplitude went to opposite
							endif
						endif

						//print  jj,normcoef, maxb, avgb, sdb
 						// calculate SSD
 						wb = wb * wb
 						// calculate SAD
 						// wb = abs(wb)

						tmpnum = mean(wb) * 0.7 /// magical number to set the S/N and baseline
//						wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += (1-tmpnum*tmpnum) * normcoef * normcoef2
						if (flagcoef2)
							wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += (1-tmpnum*tmpnum) * normcoef2
						else
							wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += (1-tmpnum*tmpnum)						
						endif
//						wd[ii,ii+winpnt-1][jj,jj+winpnt-1] += (1-tmpnum*tmpnum)
						wn[ii,ii+winpnt-1][jj,jj+winpnt-1] += 1
						ww[ii,ii+winpnt-1][jj,jj+winpnt-1] += normcoef
						ww2[ii,ii+winpnt-1][jj,jj+winpnt-1] += normcoef2
						ind_b += 1
					endfor
					ind_a +=1
				endfor

				wd = wd / wn
				ww = ww / wn
				ww2 = ww2 / wn

//				killwaves $awave
//				killwaves $bwave
//				killwaves $bwave
				
				bindex+=1
				b_wave = StringFromList(bindex, listb)
			While(strlen(b_wave)!=0)
			aindex+=1
			a_wave = StringFromList(aindex, lista)
		While(strlen(a_wave)!=0)

		now = datetime
		print now-lasttime, " s "
	else
		//// probably not working
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



function subtractMeanImage ([wave1, destname, stt,ent])
	String wave1, destname
	Variable stt, ent
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		destname="d"; stt=0; ent=0.01;
		Prompt wave1, "Spectrogram1 name"//, popup wavelist ("*",";","")
		prompt destname, "PREFIX of the destination wave"
		Prompt stt,"X from (s)"
		Prompt ent,"to (s)"
		DoPrompt  "subtractMeanImage", wave1, destname, stt, ent
		if (V_Flag)	// User canceled
			return -1
		endif
		print "subtractMeanImage(wave1=\"" + wave1 + "\", destname=\"" + destname + "\",stt=" + num2str(stt) + ",ent=" + num2str(ent) + ")"
	endif	
	
	variable length, width
	string awave, bwave, destwave
	bwave = "image_baseline"

	variable aindex=0, sttime, entime
	variable ii, xa, ya, nindex, dya, oya

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	aindex=0
	a_wave = StringFromList(aindex, lista)
	Do
		if (strlen(destname) > 0)
			destwave = destname + a_wave
		else
			destwave = a_wave
		endif
		xa = Dimsize($a_wave, 0)
		ya = Dimsize($a_wave, 1)
		dya = DimDelta($a_wave, 1)
		oya = DimOffset($a_wave, 1)
		make /N=(1, ya) /O $bwave
		Duplicate /O $a_wave, $destwave
		wave wa  = $a_wave
		wave wb  = $bwave
		wave wd  = $destwave
		SetScale/P y oya, dya,"Hz", wb
		wb = 0
		if (stt < leftx(wa))
			stt = leftx(wa)
		endif
		if (ent > rightx(wa))
			ent = rightx(wa)
		endif
		if (stt > ent )
			print "!!! invalid x range"
			abort
		endif
		
		nindex = 0
		for (ii = x2pnt(wa, stt); ii<=x2pnt(wa, ent); ii+=1)
			wb[][] += wa[ii][q]
			nindex += 1
		endfor
		wb /= nindex
		
		wd[][] -= wb[0][q]
		
		aindex+=1
		a_wave = StringFromList(aindex, lista)
	While(strlen(a_wave)!=0)
End


function adjustImageToTemplate ([wave1, tempwave, destname, type, errX, errY, offX, offY, stepX, stepY])
	String wave1, tempwave, destname
	Variable type, errX, errY, offX, offY, stepX, stepY
	if (numType(strlen(wave1)) == 2)	// if (wave1 == null) : so there was no input
		destname="d"; type=0; errX=5; errY=1; offX=0.015; offY=0; stepX=0.5; stepY=0.1
		Prompt wave1, "Spectrogram1 name"//, popup wavelist ("*",";","")
		Prompt tempwave, "template wave name"
		prompt destname, "PREFIX of the destination wave"
		Prompt type, "type 0(maxCorr)"
		Prompt errX,"X error [%]"
		Prompt errY,"Y error [%]"
		Prompt offX,"X offset [s]"
		Prompt offY,"Y offset [Hz]"
		Prompt stepX,"X step [%]"
		Prompt stepY,"Y step [%]"
		DoPrompt  "adjustImageToTemplate", wave1, tempwave, destname, type, errX, errY, offX, offY, stepX, stepY
		if (V_Flag)	// User canceled
			return -1
		endif
		print "adjustImageToTemplate(wave1=\"" + wave1 + "\", tempwave=\"" + tempwave + "\", destname=\"" + destname + "\",type=" + num2str(type) + ",errX=" + num2str(errX) + ",errY=" + num2str(errY) + ",offX=" + num2str(offX) + ",offY=" + num2str(offY) + ",stepX=" + num2str(stepX) + ",stepY=" + num2str(stepY) + ")"
	endif	

	if (errX / stepX > 1000 || errY / stepY > 1000)
		print "!!! aborted because too much calculation was required."
		abort
	endif
	if (errX < 0 || stepX < 0 || errY < 0 || stepY < 0)
		print "!!! invalid value."
		abort
	endif

	errX /= 100
	errY /= 100
	stepX /= 100
	stepY /= 100
	
	variable length, width
	string awave, bwave, destwave, tmpwave, bestxwave, bestywave, bestwave
	tmpwave = "tmpwave"
	destwave = "tmp2wave"
	bestxwave = "bestXwave"
	bestywave = "bestYwave"
	make /O /N=(0) $bestxwave
	make /O /N=(0) $bestywave
	wave wbestx = $bestxwave
	wave wbesty = $bestywave

	variable aindex, bindex, sttime, entime, nonbestx, nonbesty
	variable ii, xa, ya, nindex, dya, oya, dxa, oxa, indx, indy, bestCorr, curCorr
	variable bestX, bestY, noffX, noffY, nerrX, nerrY, nstepx, nstepy, avgb, avgd, sdb, sdd

	string lista , listb , a_wave , b_wave
	lista = WaveList(wave1,";","")
	listb = WaveList(tempwave,";","")
	aindex=0
	bindex=0
	a_wave = StringFromList(aindex, lista)
	b_wave = StringFromList(bindex, listb)
	Do
		if (strlen(destname) > 0)
			bestwave = destname + a_wave
		else
			bestwave = a_wave
		endif
		xa = Dimsize($a_wave, 0)
		ya = Dimsize($a_wave, 1)
		dxa = DimDelta($a_wave, 0)
		oxa = DimOffset($a_wave, 0)
		dya = DimDelta($a_wave, 1)
		oya = DimOffset($a_wave, 1)
		noffX = (offX-oxa)/dxa
		noffY = (offY-oya)/dya
		nerrX = errX/dxa
		nerrY = errY/dya
		nstepx = stepX/dxa
		nstepy = stepY/dya

		Duplicate /O $a_wave, $destwave
		Duplicate /O $a_wave, $tmpwave
		Duplicate /O $a_wave, $bestwave
		wave wa  = $a_wave
		wave wb  = $b_wave
		wave wd  = $destwave
		wave wt  = $tmpwave
		wave wbest  = $bestwave
		wavestats/Q wb
		avgb = V_avg
		sdb = V_sdev

		wd = 0
		wt = 0
		wbest = 0
		
		bestX = 0
		bestY = 0
		bestCorr = 0
		curCorr = 0
		nonbestx = 0
		nonbesty = 0
		for (indx = 0; indx<=errX; indx+=stepX)
			nonbesty = 0
			for (indy = 0; indy<=errY; indy+=stepY)
				// print a_wave, indx, indy, "(", noffX, noffY, ")"
				wt[][] = wa[p+noffX][q+noffY]
				if (noffX > 0)
					wt[xa-noffX,xa-1][] = 0
				endif
				if (noffY > 0)
					wt[][ya-noffY,ya-1] = 0
				endif
				wd[][] = wt[p*(1+indx)][q*(1+indy)]
				if (round(xa/(1+indx)) <= xa-1)
					wd[round(xa/(1+indx)),xa-1][] = 0
				endif
				if (round(ya/(1+indy)) <= ya-1)
					wd[][round(ya/(1+indy)),ya-1] = 0
				endif
				wt[][] = wd[p-noffX][q-noffY]
				if (noffX > 0)
					wt[0,noffX-1][] = wa[p][q]
				endif
				if (noffY > 0)
					wt[][0,noffY-1] = wa[p][q]
				endif
				wd = wt
				//// calc correlation
				wavestats/Q wd
				avgd = V_avg
				sdd = V_sdev
				wt = (wd - avgd) * (wb - avgb)
				wt = wt / sdb / sdd
				curCorr =  mean(wt)
				if (bestCorr < curCorr)
					bestCorr = curCorr
					bestX = -indx
					bestY = -indy
					nonbestx = 0
					nonbesty = 0
					wbest = wd
					//print "best", curCorr, "(", bestX, bestY, ")"
				else
					//print CurCorr
					nonbesty += 1
				endif
				
				wt[][] = wa[p+noffX][q+noffY]
				if (noffX > 0)
					wt[xa-noffX,xa-1][] = 0
				endif
				if (noffY > 0)
					wt[][ya-noffY,ya-1] = 0
				endif
				wd[][] = wt[p*(1+indx)][q*(1-indy)]
				if (round(xa-noffX)/(1+indx) <= xa-1)
					wd[round(xa/(1+indx)),xa-1][] = 0
				endif
				wt[][] = wd[p-noffX][q-noffY]
				if (noffX > 0)
					wt[0,noffX-1][] = wa[p][q]
				endif
				if (noffY > 0)
					wt[][0,noffY-1] = wa[p][q]
				endif
				wd = wt
				//// calc correlation
				wavestats/Q wd
				avgd = V_avg
				sdd = V_sdev
				wt = (wd - avgd) * (wb - avgb)
				wt = wt / sdb / sdd
				curCorr =  mean(wt)
				if (bestCorr < curCorr)
					bestCorr = curCorr
					bestX = -indx
					bestY = indy
					nonbestx = 0
					nonbesty = 0
					wbest = wd
					//print "best", curCorr, "(", bestX, bestY, ")"
				else
					//print CurCorr
					nonbesty += 1
				endif
				//if (indx==0.02 && indy == 0.004)
				//	wbest = wd
				//	nonbestx = 500
				//	nonbesty = 500
				//	break
				//endif

				wt[][] = wa[p+noffX][q+noffY]
				if (noffX > 0)
					wt[xa-noffX,xa-1][] = 0
				endif
				if (noffY > 0)
					wt[][ya-noffY,ya-1] = 0
				endif
				wd[][] = wt[p*(1-indx)][q*(1+indy)]
				if (round(ya/(1+indy)) <= ya-1)
					wd[][ya/(1+indy),ya-1] = 0
				endif
				wt[][] = wd[p-noffX][q-noffY]
				if (noffX > 0)
					wt[0,noffX-1][] = wa[p][q]
				endif
				if (noffY > 0)
					wt[][0,noffY-1] = wa[p][q]
				endif
				wd = wt
				//// calc correlation
				wavestats/Q wd
				avgd = V_avg
				sdd = V_sdev
				wt = (wd - avgd) * (wb - avgb)
				wt = wt / sdb / sdd
				curCorr =  mean(wt)
				if (bestCorr < curCorr)
					bestCorr = curCorr
					bestX = indx
					bestY = -indy
					nonbestx = 0
					nonbesty = 0
					wbest = wd
					//print "best", curCorr, "(", bestX, bestY, ")"
				else
					//print CurCorr
					nonbesty += 1
				endif
				
				wt[][] = wa[p+noffX][q+noffY]
				if (noffX > 0)
					wt[xa-noffX,xa-1][] = 0
				endif
				if (noffY > 0)
					wt[][ya-noffY,ya-1] = 0
				endif
				wd[][] = wt[p*(1-indx)][q*(1-indy)]
				wt[][] = wd[p-noffX][q-noffY]
				if (noffX > 0)
					wt[0,noffX-1][] = wa[p][q]
				endif
				if (noffY > 0)
					wt[][0,noffY-1] = wa[p][q]
				endif
				wd = wt
				//// calc correlation
				wavestats/Q wd
				avgd = V_avg
				sdd = V_sdev
				wt = (wd - avgd) * (wb - avgb)
				wt = wt / sdb / sdd
				curCorr =  mean(wt)
				if (bestCorr < curCorr)
					bestCorr = curCorr
					bestX = indx
					bestY = indy
					nonbestx = 0
					nonbesty = 0
					wbest = wd
					//print "best", curCorr, "(", bestX, bestY, ")"
				else
					//print CurCorr
					nonbesty += 1
				endif
				
				if (nonbesty > 25)
					break
				endif
			endfor
			nonbestx += 1
			if (nonbestx > 4)
				break
			endif
		endfor
		print a_wave, ": " , bestX, bestY, "(Corr: ", bestCorr, ")"

		insertpoints numpnts(wbestx), 1, wbestx
		wbestx[inf] = bestX
		insertpoints numpnts(wbesty), 1, wbesty
		wbesty[inf] = bestY

		aindex+=1
		a_wave = StringFromList(aindex, lista)
	While(strlen(a_wave)!=0)
End


function imageEnlarge([waves, namewave, stX, enX, stY, enY, stZ, enZ, scale])
	String waves, namewave
	Variable stX, enX, stY, enY, stZ, enZ, scale
	if (enX == 0)		// if (row == null) : so there was no input
		waves="V_I*"; namewave="V";
		stX = 10; enX=29;
		stY = 10; enY=29;
		stZ = -inf; enZ=inf;
		scale = 2;
		Prompt waves, "3D wave name"
		Prompt namewave, "target name suffix"
		Prompt stX, "ROI X from"
		Prompt enX, "to"
		Prompt stY, "ROI Y from"
		Prompt enY, "to"
		Prompt stZ, "ROI Z(plane) from"
		Prompt enZ, "to"
		Prompt scale, "scale (integer)"
		DoPrompt  "imageEnlarge", waves, namewave, stX, enX, stY, enY, stZ, enZ, scale
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* imageEnlarge(waves=\"" + waves + "\", namewave=\"" + namewave + "\", stX=" + num2str(stX) + ", enX=" + num2str(enX) + ", stY=" + num2str(stY) + ", enY=" + num2str(enY) + ", stZ=" + num2str(stZ) + ", enZ=" + num2str(enZ) + ", scale=" + num2str(scale) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, pindex, lengthX, lengthY, lengthZ
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		targetname = namewave + a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		if(stX < x2pnt(a, DimOffset(a, 0)))
			stX = x2pnt(a, DimOffset(a, 0))
		endif
		if(enX > x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1)
			enX = x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1
		endif
		if(stY < x2pnt(a, DimOffset(a, 1)))
			stY = x2pnt(a, DimOffset(a, 1))
		endif
		if(enY > x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1)
			enY = x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1
		endif
		if(stZ < x2pnt(a, DimOffset(a, 2)))
			stZ = x2pnt(a, DimOffset(a, 2))
		endif
		if(enZ > x2pnt(a, DimOffset(a, 2)) + DimSize(a, 2) - 1)
			enZ = x2pnt(a, DimOffset(a, 2)) + DimSize(a, 2) - 1
		endif
		if (stX > enX || stY > enY || stZ > enZ)
			abort
		endif
		lengthX = (enX - stX + 1)*scale
		lengthY = (enY - stY + 1)*scale
		lengthZ = enZ - stZ + 1

		make /O /N=(lengthX, lengthY, lengthZ) $targetname
		wave target = $targetname
		pindex=stZ
		Do
			target[][][pindex] = a[trunc(p/scale)][trunc(q/scale)][pindex]

			pindex +=1
		While(pindex <= enZ)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function makeROISurround([waves, namewave, stX, enX, stY, enY])
	String waves, namewave
	Variable stX, enX, stY, enY
	if (enX == 0)		// if (row == null) : so there was no input
		waves="V_I*"; namewave="V";
		stX = 10; enX=29;
		stY = 10; enY=29;
		Prompt waves, "3D wave name"
		Prompt namewave, "target name prefix"
		Prompt stX, "ROI X from"
		Prompt enX, "to"
		Prompt stY, "ROI Y from"
		Prompt enY, "to"
		DoPrompt  "makeROISurround", waves, namewave, stX, enX, stY, enY
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*makeROISurround(waves=\"" + waves + "\", namewave=\"" + namewave + "\", stX=" + num2str(stX) + ", enX=" + num2str(enX) + ", stY=" + num2str(stY) + ", enY=" + num2str(enY) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, pindex, lengthX, lengthY, lengthZ, xindex, yindex, flag=0
	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		targetname = namewave + a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		if(stX < x2pnt(a, DimOffset(a, 0)))
			stX = x2pnt(a, DimOffset(a, 0))
		endif
		if(enX > x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1)
			enX = x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1
		endif
		if(stY < x2pnt(a, DimOffset(a, 1)))
			stY = x2pnt(a, DimOffset(a, 1))
		endif
		if(enY > x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1)
			enY = x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1
		endif
		Duplicate /O $a_wave,  $targetname
		wave d = $targetname
		d = 1
		xindex=stX
		Do
			yindex=stY
			Do
				if (a[xindex][yindex] != 0)
					flag = 1
					if (xindex != x2pnt(a, DimOffset(a, 0)))
						flag *= a[xindex-1][yindex]
						if (yindex != x2pnt(a, DimOffset(a, 1)))
							flag *= a[xindex-1][yindex-1]
						endif
						if (yindex != (x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1))
							flag *= a[xindex-1][yindex+1]
						endif
					endif
					if (xindex != (x2pnt(a, DimOffset(a, 0)) + DimSize(a, 0) - 1) )
						flag *= a[xindex+1][yindex]
						if (yindex != x2pnt(a, DimOffset(a, 1)))
							flag *= a[xindex+1][yindex-1]
						endif
						if (yindex != (x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1))
							flag *= a[xindex+1][yindex+1]
						endif
					endif
					if (yindex != x2pnt(a, DimOffset(a, 1)))
						flag *= a[xindex][yindex-1]
					endif
					if (yindex != (x2pnt(a, DimOffset(a, 1)) + DimSize(a, 1) - 1))
						flag *= a[xindex][yindex+1]
					endif
					d[xindex][yindex] = flag
				endif
				yindex +=1
			While(yindex <= enY)
			xindex +=1
		While(xindex<= enX)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

function ROItoVector([waves, namewave, length, onset, step, val])	/// this program needs to be improved
	String waves, namewave
	Variable step, val, onset, length
	if (val == 0)		// if (row == null) : so there was no input
		waves="ROIstim*"; namewave="S10";
		step=200; onset=0; length=1000; val=0.002;
		Prompt waves, "ROI wave name"
		Prompt namewave, "target name suffix"
		Prompt length, "x length"
		Prompt onset, "x onset ROI"
		Prompt step, "x step per ROI"
		Prompt val, "ROI value"
		DoPrompt  "ROItoVector", waves, namewave, length, onset, step, val
		if (V_Flag)	// User canceled
			return -1
		endif
		print "* ROItoVector(waves=\"" + waves + "\", namewave=\"" + namewave + "\", length=" + num2str(length) + ", onset=" + num2str(onset) + ", step=" + num2str(step) + ", val=" + num2str(val) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, rowindex, colindex, strow, stcol, enrow, encol

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		strow = x2pnt(a, DimOffset(a, 0))
		stcol = x2pnt(a, DimOffset(a, 1))
		enrow = x2pnt(a, DimOffset(a, 0)) + DimSize(a,0) - 1
		encol = x2pnt(a, DimOffset(a, 1)) + DimSize(a,1) - 1
		rowindex = strow
		Do
			colindex = stcol
			Do
				targetname = namewave + "_" + num2str(rowindex) + "_" + num2str(colindex)
				if (windex == 0)
					Make /O /N=(length) $targetname
				endif
				wave d = $targetname
				if (a[rowindex][colindex] == 0)	//	I dont know why but it enters even if a[][] is other than 0
					d[(windex*step)+onset, ((windex+1)*step-1)+onset] = val
				endif
				colindex += 1
			While (colindex <= encol)
			rowindex += 1
		While (rowindex <= enrow)

		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end



function makeSlidingImages([waves, namewave, stX, enX, stY, enY, horizontal, offset, step, num])
	String waves, namewave
	Variable stX, enX, stY, enY, horizontal, offset, step, num
	if (enX == 0)		// if (row == null) : so there was no input
		waves="*"; namewave="slide_";
		stX = 0; enX=39;
		stY = 0; enY=39;
		horizontal = 1; offset = -39; step=1; num=79
		Prompt waves, "2D 8bit unsigned wave"
		Prompt namewave, "target name prefix"
		Prompt stX, "ROI X from"
		Prompt enX, "to"
		Prompt stY, "ROI Y from"
		Prompt enY, "to"
		Prompt horizontal, "direction 0/1 (Vert/Horiz)"
		Prompt offset, "offset"
		Prompt step, "dx for sliding"
		Prompt num, "times for sliding"
		DoPrompt  "makeSlidingImages", waves, namewave, stX, enX, stY, enY, horizontal, offset, step, num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*makeSlidingImages(waves=\"" + waves + "\", namewave=\"" + namewave + "\", stX=" + num2str(stX) + ", enX=" + num2str(enX) + ", stY=" + num2str(stY) + ", enY=" + num2str(enY) + ", horizontal=" + num2str(horizontal) + ",  offset=" + num2str(offset) + ", step=" + num2str(step) + ", num=" + num2str(num) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, lengthX, lengthY, xindex, yindex, nindex, flag
	if (enX < stX || enY < stY)
		print "enX < stX || enY < st Y"
		abort
	endif
	lengthX = enX - stX +1
	lengthY = enY - stY +1

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		nindex=0
		Do
			targetname = namewave + a_wave + num2str(nindex)
			make /O /u /b /N=(lengthX, lengthY) $targetname
			wave d = $targetname			
			if (horizontal)
				d[][] = a[p-(nindex*step)-offset][q]
			else
				d[][] = a[p][q-(nindex*step)-offset]
			endif
			nindex += 1
		While (nindex < num)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


function makeVibratingImages([waves, namewave, makeGauss, direction, freq, SD, num])
	String waves, namewave
	Variable makeGauss, direction, freq, SD, num
	if (num == 0)		// if (row == null) : so there was no input
		waves="*"; namewave="slide_";
		direction = 1; makeGauss=1; freq = 50; SD=1; num=500
		Prompt waves, "2D wave name"
		Prompt namewave, "target name prefix"
		Prompt makeGauss, "make random seeds?"
		Prompt direction, "direction 0/1/2 (Vert/Horiz/both)"
		Prompt freq, "cutoff freq (Hz)"
		Prompt SD, "SD for noise"
		Prompt num, "frame pnts while vibration"
		DoPrompt  "makeVibratingImages", waves, namewave, makeGauss, direction, freq, SD, num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*makeVibratingImages(waves=\"" + waves + "\", namewave=\"" + namewave + "\", makeGauss=" + num2str(makeGauss)  + ", direction=" + num2str(direction) + ",  freq=" + num2str(freq) + ", SD=" + num2str(SD) + ", num=" + num2str(num) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, lengthX, lengthY, xnum, ynum, nindex, flag

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		lengthX = DimSize(a, 0)
		lengthY = DimSize(a, 1)
		if (makeGauss)
			execute "makeGaussianNoise(0," + num2str(SD) + "," + num2str(num/1000) + ",1,1,1,\"_x\",3)"
			execute "makeGaussianNoise(0," + num2str(SD) + "," + num2str(num/1000) +  ",1,1,1,\"_y\",3)"
			execute "FFT_Wave(\"Gauss*\",\"F_\",0,0,0,3,1)"
			assignValues(waves="F*", destname="", type=0, value="0", sttime=freq, entime=inf, dpn=3)
			execute "FFT_Wave(\"F*\",\"I_\",0,0,1,3,1)"
			execute "subtract(\"I*\",\"\",NaN,0,-inf,inf,0,3)"
			execute "normWave(\"I*\",\"\",-inf,inf,-inf,inf," + num2str(SD) + ",3,3,1)"
		endif
		wave xGauss = I_F_Gauss_x_0
		wave yGauss = I_F_Gauss_y_0
		nindex=0
		Do
			targetname = namewave + a_wave + num2str(nindex)
			make /O /u /b /N=(lengthX, lengthY) $targetname
			wave d = $targetname
			if (direction == 0)
				ynum = round(yGauss[nindex])
				d[][] = a[p][q+ynum]
			elseif (direction == 1)
				xnum = round(xGauss[nindex])
				d[][] = a[p+xnum][q]
			else
				xnum = round(xGauss[nindex])
				ynum = round(yGauss[nindex])
				d[][] = a[p+xnum][q+ynum]
			endif
			nindex += 1
		While (nindex < num)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end



function slide3DImagesWithWaves([waves, namewave, xwave, ywave, offset, num, sFolder])
	String waves, namewave, xwave, ywave, sFolder
	Variable offset, num
	if (num == 0)		// if (row == null) : so there was no input
		waves="Re_V_I_F_*"; namewave="SNR_"; 
		xwave="I_F_Gauss_x_00"; ywave="I_F_Gauss_y_00";
		offset=250; num=500; sFolder=""
		Prompt waves, "3D wave name"
		Prompt namewave, "target name prefix"
		Prompt xwave, "Xwave"
		Prompt ywave, "Ywave"
		Prompt offset, "offset"
		Prompt num, "times for sliding"
		Prompt sFolder, "folder containing Xwave"
		DoPrompt  "slide3DImagesWithWaves", waves, namewave, xwave, ywave, offset, num
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*slide3DImagesWithWaves(waves=\"" + waves + "\", namewave=\"" + namewave + "\", xwave=\"" + xwave + "\", ywave=\"" + ywave + "\",  offset=" + num2str(offset) + ", num=" + num2str(num) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, zindex, xnum, ynum
	if (!stringmatch(sFolder, ""))
		sFolder = ":" + sFolder + ":"
		xwave = sFolder + xwave
		ywave = sFolder + ywave
	endif

	if (waveExists($xwave))
		wave xGauss = $xwave
	else
		print "Xwave does not exist."
		abort
	endif
	if (waveExists($ywave))
		wave yGauss = $ywave
	else
		print "Ywave does not exist."
		abort
	endif

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		targetname = namewave + a_wave
		Duplicate /O $a_wave $targetname
		wave d = $targetname
		zindex=0
		Do
			xnum = xGauss[zindex]
			ynum = yGauss[zindex]
			d[][][zindex+offset] = a[p-xnum][q-ynum][zindex + offset]
			zindex += 1
		While (zindex < num)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end


function average3DImagesTo2D([waves, namewave, stZ, enZ])
	String waves, namewave
	Variable stZ, enZ
	if (enZ == 0)		// if (row == null) : so there was no input
		waves="SNR_Re_V_I_F_*"; namewave="avg_";
		stZ=250; enZ=749
		Prompt waves, "3D wave name"
		Prompt namewave, "target name prefix"
		Prompt stZ, "avg layer from"
		Prompt enZ, "to"
		DoPrompt  "average3DImagesTo2D", waves, namewave, stZ, enZ
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*average3DImagesTo2D(waves=\"" + waves + "\", namewave=\"" + namewave + "\", stZ=" + num2str(stZ) + ", enZ=" + num2str(enZ) + ")"
	endif
	
	string lista, a_wave, targetname
	variable windex, zindex, zlength
	zlength = enZ - stZ + 1

	windex = 0
	lista = WaveList(waves,";","")
	a_wave = StringFromList(windex, lista)
	Do
		wave a = $a_wave
		if (waveExists(a) == 0)
			print "not exist such a wave"
			abort
		endif
		targetname = namewave + a_wave + "_" + num2str(stZ) + "to" + num2str(enZ)
		Make /O /N=(Dimsize($a_wave,0), Dimsize($a_wave,1)) $targetname
		wave d = $targetname
		zindex=stZ
		Do
			d[][][zindex] += (a[p][q][zindex] / zlength)
			zindex += 1
		While (zindex <= enZ)
		
		windex += 1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
end

