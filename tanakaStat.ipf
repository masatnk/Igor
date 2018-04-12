#pragma rtGlobals=1		// Use modern global access method.



menu  "tanakaStat"
	submenu "Statistical Test"
		"onewayANOVA"
		"twowayANOVA"
	end
	submenu "Curve fit"
		"functionFit"
	end
end

function onewayANOVA ([wave1, dim, type])
	String wave1, type
	variable dim	
	if (numType(strlen(wave1)) == 2)	// if (wave_a == null) : so there was no input
		wave1="data*"; dim=2; type="";
		prompt wave1, "data wave"
		prompt dim, "data dimension"		
		prompt type, "type ", popup, "one-way"
		DoPrompt "ANOVA", wave1, dim, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*ANOVA(wave1=\"" + wave1 + "\", dim=" + num2str(dim) + ", type=\"" + type + "\")" 
	endif

	string lista , a_wave, e_name, t_name, se_name, st_name, s_name
	variable row, col, depth
	variable windex, rowindex, colindex, depthindex
	variable sumrow, sumcol, sumdepth
	string avgrow_name = "AvgRow", avgcol_name = "AvgCol", avgdepth_name = "AvgDepth"
	string numrow_name = "NRow", numcol_name = "NCol", numdepth_name = "NDepth"
	string difrow_name = "difAvgRow", difcol_name = "difAvgCol", difdepth_name = "difAvgDepth"
	string Sdifrow_name = "SdifAvgRow", Sdifcol_name = "SdifAvgCol", Sdifdepth_name = "SdifAvgDepth"
	variable avgT = 0, nT = 0, nF = 0
	variable SST, SSF, SSE, SSS, SSres, dfT, dfF, dfS, dfE, dfres, MST, MSF, MSE, MSS, MSres
	// SS: square sum; MS: mean square
	// T: total; F: factor; E: error
	// 
	//
	lista = WaveList(wave1,";","")
	if (dim == 2)
		windex=0
		a_wave = StringFromList(windex, lista)
		Do
			wave awave = $a_wave
			wavestats /Q awave
			nT = V_npnts
			avgT = V_avg
			e_name = "error_" + a_wave
			se_name = "Se_" + a_wave
			s_name = "S_" + a_wave
			Duplicate /O awave, $e_name
			Duplicate /O awave, $se_name
			wave ewave = $e_name
			wave sewave = $se_name
		
			col = DimSize(awave, 1)
			row = DimSize(awave, 0)
			Make /O /N=(col) $avgcol_name
			Make /O /N=(col) $numcol_name
				wave avgcol = $avgcol_name
				wave numcol = $numcol_name
				avgcol = 0
				numcol = 0

			colindex = 0	// Effect of Col
			Do
				sumcol = 0
				rowindex = 0
				Do
					if (numtype(awave[rowindex][colindex]) != 2)	// != NaN
						numcol[colindex] += 1
						sumcol += awave[rowindex][colindex]
					endif
					rowindex += 1
				While (rowindex < row)
				avgcol[colindex] = sumcol / numcol[colindex]
				colindex += 1
			While (colindex < col)

			ewave[][] = awave[p][q] - avgcol[q]
			sewave = ewave * ewave
			wavestats /Q sewave
			SSE = V_Sum
			dfE = nT - col
			dfF = col - 1
			dfT = nT - 1

		t_name = "total_" + a_wave
		st_name = "St_" + a_wave
		Duplicate /O awave, $t_name
		Duplicate /O awave, $st_name
		wave twave = $t_name
		wave stwave = $st_name
		twave[][] = awave[p][q] - avgT
		stwave = twave * twave
		wavestats /Q stwave
		SST = V_Sum

		Duplicate /O avgcol, $difcol_name
		Duplicate /O avgcol, $Sdifcol_name
		wave difcol = $difcol_name
		wave Sdifcol = $Sdifcol_name
		difcol[] = avgcol[p] - avgT
		Sdifcol = difcol * difcol * numcol
		wavestats /Q Sdifcol
		SSF = V_Sum

		Make /O /N=(row) $avgrow_name
		Make /O /N=(row) $numrow_name
			wave avgrow = $avgrow_name
			wave numrow = $numrow_name
			avgrow = 0
			numrow = 0

			rowindex = 0	// Effect of Row
			Do
				sumrow = 0
				colindex = 0
				Do
					if (numtype(awave[rowindex][colindex]) != 2)	// != NaN
						numrow[rowindex] += 1
						sumrow += awave[rowindex][colindex]
					endif
					colindex += 1
				While (colindex < col)
				avgrow[rowindex] = sumrow / numrow[rowindex]
				rowindex += 1
			While (rowindex < row)

		Duplicate /O avgrow, $difrow_name
		Duplicate /O avgrow, $Sdifrow_name
		wave difrow = $difrow_name
		wave Sdifrow = $Sdifrow_name
		difrow[] = avgrow[p] - avgT
		Sdifrow = difrow * difrow * numrow
		wavestats /Q Sdifrow
		SSS = V_Sum
		dfS = row - 1

		Duplicate /O avgrow, $difrow_name
		Duplicate /O avgrow, $Sdifrow_name
		wave difcol = $difcol_name
		wave Sdifcol = $Sdifcol_name
		difcol[] = avgcol[p] - avgT
		Sdifcol = difcol * difcol * numcol
		wavestats /Q Sdifcol
		SSF = V_Sum

	dfres = dfT - dfF - dfS
	SSres = SST - SSF - SSS

	MST = SST / dfT
	MSE = SSE / dfE
	MSF = SSF / dfF
	MSS = SSS / dfS
	MSres = SSres / dfres

	print "SS"
	print SST
	print SSF
	print SSS
	print SSE
	print SSres

	print "df"
	print dfT
	print dfF
	print dfS
	print dfE
	print dfres
	
	print "MS"
	print MST
	print MSF
	print MSS
	print MSE
	print MSres

	print "F"
	print MSF/MSE
	print MSF/MSres
	print MSS/MSres

			
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	endif
end

function twowayANOVA ([wave1, dim, type])
	String wave1, type
	variable dim	
	if (numType(strlen(wave1)) == 2)	// if (wave_a == null) : so there was no input
		wave1="Matrix_data"; dim=2; type="";
		prompt wave1, "data wave"
		prompt dim, "data dimension"		
		prompt type, "type ", popup, "one-way"
		DoPrompt "ANOVA", wave1, dim, type
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*ANOVA(wave1=\"" + wave1 + "\", dim=" + num2str(dim) + ", type=\"" + type + "\")" 
	endif

	string lista , a_wave, eD_name, t_name, seD_name, st_name, sD_name
	variable row, col, depth
	variable windex, rowindex, colindex, depthindex
	variable sumR, sumC, sumD, sumCD
	string avgR_name = "AvgRow", avgC_name = "AvgCol", avgD_name = "AvgDepth"
	string avgRC_name = "AvgRowCol", avgCD_name = "AvgColDepth", avgRD_name = "AvgRowDepth"
	string numR_name = "NRow", numC_name = "NCol", numD_name = "NDepth"
	string numRC_name = "NRowCol", numCD_name = "NColDepth", numRD_name = "NRowDepth"
	string difR_name = "difAvgRow", difC_name = "difAvgCol", difD_name = "difAvgDepth"
	string difRC_name = "difAvgRowCol", difCD_name = "difAvgColDepth", difRD_name = "difAvgRowDepth"
	string SdifR_name = "SdifAvgRow", SdifC_name = "SdifAvgCol", SdifD_name = "SdifAvgDepth"
	string SdifRC_name = "SdifAvgRowCol", SdifCD_name = "SdifAvgColDepth", SdifRD_name = "SdifAvgRowDepth"
	variable avgT = 0, nT = 0, nF = 0
	variable SST, SSF, SSED, SSS, SSres, dfT, dfF, dfS, dfED, dfres, MST, MSF, MSE, MSS, MSres
	// SS: square sum; MS: mean square
	// T: total; F: factor; E: error
	// 
	//
	lista = WaveList(wave1,";","")
	if (dim == 2)
		windex=0
		a_wave = StringFromList(windex, lista)
		Do
			wave awave = $a_wave
			wavestats /Q awave
			nT = V_npnts
			avgT = V_avg
			SST = V_sdev^2*(nT-1)
			eD_name = "error_D_" + a_wave
			seD_name = "Se_D_" + a_wave
			sD_name = "S_D_" + a_wave
			Duplicate /O awave, $eD_name
			Duplicate /O awave, $seD_name
			wave eDwave = $eD_name
			wave seDwave = $seD_name
		
			row = DimSize(awave, 0)
			col = DimSize(awave, 1)
			depth = DimSize(awave, 2)

			Make /O /N=(col,depth) $avgCD_name
			Make /O /N=(col,depth) $numCD_name
				wave avgCD = $avgCD_name
				wave numCD = $numCD_name
				avgCD = 0
				numCD = 0
			Make /O /N=(depth) $avgD_name
			Make /O /N=(depth) $numD_name
				wave avgD = $avgD_name
				wave numD = $numD_name
				avgD = 0
				numD = 0

			depthindex = 0  // Data[][][0]
			Do
				sumD = 0
				colindex = 0	// Data[][0-col][0]
				Do
					sumCD = 0
					rowindex = 0
					Do
						if (numtype(awave[rowindex][colindex][depthindex]) != 2)	// != NaN
							numCD[colindex][depthindex] += 1
							numD[depthindex] += 1
							sumCD += awave[rowindex][colindex][depthindex]
							sumD += awave[rowindex][colindex][depthindex]
						endif
						rowindex += 1
					While (rowindex < row)
					avgCD[colindex][depthindex] = sumCD / numCD[colindex][depthindex]
					colindex += 1
				While (colindex < col)
				avgD[depthindex] = sumD / numD[depthindex]
				depthindex += 1
			While (depthindex < depth)
			
			eDwave[][][] = awave[p][q][r] - avgD[r]
			seDwave = eDwave * eDwave
			wavestats /Q seDwave
			SSED = V_Sum
			dfED = depth - 1
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)

	endif
end



function functionFit ([wave1, func, sttime, entime, k0, k1, k2, k3, constraints])
	String wave1, func, constraints
	Variable sttime, entime, k0, k1, k2, k3
	if (numType(strlen(wave1)) == 2)	// if (wave_a == null) : so there was no input
		wave1="*4"; func="exp2"; constraints="K0 > -K1; K0 < -K1"
		sttime=0; entime=0; k0=0; k1=0; k2=0; k3=0
		prompt wave1, "fitted wave"
		prompt func, "fit function (only exp2)", popup, "exp2;line;poly;gauss;lor;exp_XOffset;dblexp_XOffset;exp;dblexp;sin;HillEquation;Sigmoid;Power;LogNormal;NMSingleExp;NMBekkers2;NMBekkers3"
		prompt sttime, "range from"
		prompt entime, "to"	
		prompt k0, "first guess K0"
		prompt k1, "first guess K1"
		prompt k2, "first guess K2"
		prompt k3, "first guess K3"
		prompt constraints, "constraints"
		DoPrompt "functionFit", wave1, func, sttime, entime, k0, k1, k2, k3, constraints
		if (V_Flag)	// User canceled
			return -1
		endif
		print "*functionFit(wave1=\"" + wave1 + "\", func=\"" + func + "\", sttime=" + num2str(sttime) + ", entime=" + num2str(entime) + ", k0=" + num2str(k0) + ", k1=" + num2str(k1) + ", k2=" + num2str(k2) + ", k3=" + num2str(k3) + ", constraints=\"" + constraints + "\")" 
	endif


//	Make/D/N=4/O W_coef
//	W_coef[0] = {1,-1,0.1004,0.0002}
//	Make/O/T/N=4 T_Constraints
//	T_Constraints[0] = {"K0 > 1","K0 < 1","K1 > -1","K1 < -1"}

	Make/D/N=4/O W_coef
	W_coef[0] = {k0, k1, k2, k3}
	Make/O/T/N=(ItemsinList(constraints)) T_Constraints
	variable windex = 0
	string constraint = StringFromList(windex, constraints)
	Do
		T_Constraints[windex] = constraint
		windex+=1
		constraint = StringFromList(windex, constraints)
	While(strlen(constraint)!=0)

	string lista , a_wave, destwave
		lista = WaveList(wave1,";","")
		windex=0
		a_wave = StringFromList(windex, lista)
	WAVE/Z awave = $a_wave
	Do
		Display $a_wave
		if (stringmatch(func, "exp2"))
//				FuncFit/NTHR=0 exp2 W_coef awave(sttime, entime) /D /R /C=T_Constraints	// cannot use /NTHR in igor5
//			CurveFit/NTHR=0 line W_coef awave(sttime, entime) /D /R /C=T_Constraints
			ModifyGraph rgb($a_wave)=(8704,8704,8704)
			ModifyGraph rgb($("fit_" +a_wave))=(16384,16384,65280)
			SetAxis bottom (sttime-0.002), (entime+0.002)
			TextBox/C/N=text0/F=0/M/H={0,3,10}/A=MC ("amp = " + num2str(W_coef[0]) + "\rtau = " + num2str(W_coef[3]*1000) + "ms")
		endif
		windex+=1
		a_wave = StringFromList(windex, lista)
	While(strlen(a_wave)!=0)
	
end

Function exp2 (w, x) : FitFunc
	wave w
	variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (K0 + K1*exp(-(x-K2)/K3))^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = K0
	//CurveFitDialog/ w[1] = K1
	//CurveFitDialog/ w[2] = K2
	//CurveFitDialog/ w[3] = K3

	return (w[0] + w[1]*exp(-(x-w[2])/w[3]))^2
End


		t_name = "total_" + a_wave
		st_name = "St_" + a_wave
		Duplicate /O awave, $t_name
		Duplicate /O awave, $st_name
		wave twave = $t_name
		wave stwave = $st_name
		twave[][] = awave[p][q] - avgT
		stwave = twave * twave
		wavestats /Q stwave
		SST = V_Sum

		Duplicate /O avgC, $difC_name
		Duplicate /O avgC, $SdifC_name
		wave difC = $difC_name
		wave SdifC = $SdifC_name
		difC[] = avgC[p] - avgT
		SdifC = difC * difC * numC
		wavestats /Q SdifC
		SSF = V_Sum

		Make /O /N=(row) $avgrow_name
		Make /O /N=(row) $numrow_name
			wave avgrow = $avgrow_name
			wave numrow = $numrow_name
			avgrow = 0
			numrow = 0

			rowindex = 0	// Effect of Row
			Do
				sumrow = 0
				colindex = 0
				Do
					if (numtype(awave[rowindex][colindex]) != 2)	// != NaN
						numrow[rowindex] += 1
						sumrow += awave[rowindex][colindex]
					endif
					colindex += 1
				While (colindex < col)
				avgrow[rowindex] = sumrow / numrow[rowindex]
				rowindex += 1
			While (rowindex < row)

		Duplicate /O avgrow, $difrow_name
		Duplicate /O avgrow, $Sdifrow_name
		wave difrow = $difrow_name
		wave Sdifrow = $Sdifrow_name
		difrow[] = avgrow[p] - avgT
		Sdifrow = difrow * difrow * numrow
		wavestats /Q Sdifrow
		SSS = V_Sum
		dfS = row - 1

		Duplicate /O avgrow, $difrow_name
		Duplicate /O avgrow, $Sdifrow_name
		wave difcol = $difcol_name
		wave Sdifcol = $Sdifcol_name
		difcol[] = avgcol[p] - avgT
		Sdifcol = difcol * difcol * numcol
		wavestats /Q Sdifcol
		SSF = V_Sum

	dfres = dfT - dfF - dfS
	SSres = SST - SSF - SSS

	MST = SST / dfT
	MSE = SSE / dfE
	MSF = SSF / dfF
	MSS = SSS / dfS
	MSres = SSres / dfres

	print "SS"
	print SST
	print SSF
	print SSS
	print SSE
	print SSres

	print "df"
	print dfT
	print dfF
	print dfS
	print dfE
	print dfres
	
	print "MS"
	print MST
	print MSF
	print MSS
	print MSE
	print MSres

	print "F"
	print MSF/MSE
	print MSF/MSres
	print MSS/MSres

			
Function line_user(w,x) : FitFunc
	Wave w
	Variable x
	//T_Constraints[0] = {"K0 > -4*K1","K0 < -4*K1"}

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a + b*x
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b

	return w[0] + w[1]*x
End
