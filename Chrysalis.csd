; Chrysalis by Kevin Hosey

; The input sound can be changed on lines 72-73 below.

<Cabbage>
form caption("Chrysalis") size(500, 510), colour(13, 50, 67, 50), pluginID("def1")

gentable bounds(10, 310, 480, 200), tablenumbers(1), tablecolour("green"), tablebackgroundcolour("white"), tablegridcolour(230,230,230), identchannel("table"), amprange(0,1,1), zoom(-1), active(1)
gentable bounds(10, 310, 480, 200), tablenumbers(2), tablecolour("green"), tablebackgroundcolour("white"), tablegridcolour(230,230,230), identchannel("table2"), amprange(0,1,2), zoom(-1), active(1)

combobox bounds(110,  5, 80, 20), text("Graph On","Graph Off"), channel("Select"), value(1)
combobox bounds(110, 35, 80, 20), text("Blur Type 1","Blur Type 2"), channel("Type"), value(1)
combobox bounds(310, 35, 80, 20), text("Linear","Log.",), channel("Table"), value(1)
button   bounds(310,  5, 80, 20), text("Reset Graph"),    channel("Reset"),  value(0)

groupbox bounds(225, 65, 51, 51)
checkbox bounds(225, 65, 50,50),   channel("Evo"),   value(1), colour("green"), shape("square")
label    bounds(200, 125, 100,13), text("B L U R") , align(centre) 

hslider bounds(100, 245, 300,50), channel("Mix"),      range(0, 1, 1)	
label   bounds(200, 285, 100,13), text("Dry/Wet Mix"), align(centre)
rslider bounds(120, 150, 80, 80), text("Crossover Freq."), channel("CrossFreq"), range(20,12000, 1000, 0.5, 1, 1), colour("white"), textcolour("grey"), trackercolour("Green")
rslider bounds(210, 150, 80, 80), text("Blur Low"),        channel("BlurLow"),   range(0, 5, 0, 0.5),    colour("white"), textcolour("grey"), trackercolour("Green")
rslider bounds(300, 150, 80, 80), text("Blur High"),       channel("BlurHigh"),  range(0, 5, 0, 0.5),    colour("white"), textcolour("grey"), trackercolour("Green")

</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d 
</CsOptions>
<CsInstruments>
sr     = 44100
ksmps  = 32
nchnls = 2
0dbfs  = 1

; define UDO
opcode PVS_BinStack,a,fiiiik							                                
 fsig,icount,imax,iincr,iBlurTable,kSelect	xin			
 
; analyse frequency and amplitude data for the bin corresponding to current counter value	                            
 kamp,kfr	        pvsbin          fsig, icount					                    
 kBlurTime          table           icount, iBlurTable                                 
 
 if (kSelect) == 1 then
  kamp              portk           kamp, kBlurTime                                     
  kfr               portk           kfr,  kBlurTime                 
  asig		        oscil		    a(kamp),a(kfr)
 else
  aamp              tone            a(kamp), kBlurTime                                  
  afr               tone            a(kfr),  kBlurTime                                
  asig		        oscil		    aamp,afr			                            
 endif
 
; if the stack call hasn't completed, call the UDO again
 if icount<imax then								                                    
  amix	            PVS_BinStack    fsig,icount+iincr,imax,iincr,iBlurTable,kSelect
 endif
	xout	asig + amix                                                                
endop 
      
instr 1
kCrossFreq          chnget          "CrossFreq"
kBlurHigh           chnget          "BlurHigh"
kBlurLow            chnget          "BlurLow"
kSelect             chnget          "Select"
kTable              chnget          "Table"
kReset              chnget          "Reset"
kType               chnget          "Type"
kEvo				chnget			"Evo"	
kMix				chnget			"Mix"	
aL, aR			    diskin2			"guitar.wav", 1, 0, 1	
;aL, aR			    diskin2			"pad.wav", 1, 0, 1	

; effect on/off   
if (kEvo) == 1 then      
; initialize FFT size and analyze signal                                                                                                                     
  iFFT				=				1024 
  iBins			    =			    (iFFT / 2) + 1
  fSig				pvsanal			aL, iFFT, iFFT/4, iFFT, 1		                
  
; Reset table display to default if 'Reset graph' is pressed
  if changed(kReset)==1 then 
   reinit	REBUILD_TABLE
  endif
  REBUILD_TABLE:
  iBlurTable        ftgen           1, 0, iBins, -7, 0, iBins, 0
  iBlurTabLog	    ftgen 		    2, 0, iBins, -5, 0.05, iBins, 1 
  rireturn
  
; log table visibility  
  if changed(kTable)==1 then                                                                     
    Smessage	    sprintfk	    "visible(%d)", kTable-1
    chnset	Smessage, "table2"
  endif
  
; update table displays  
  if changed(kReset)==1 then 
                    chnset	        "tablenumber(1)", "table" 
                    chnset	        "tablenumber(2)", "table2" 
  endif

; if graph is on, blur with the UDO 
  if (kSelect) == 1 then
   iBinOS	        =			    1							                      
   iBinMax	        =			    300                                                
   iBinIncr	        =			    1
   fBandLow         pvsbandp        fSig, 0, 0, kCrossFreq, kCrossFreq+1
   fBandHigh        pvsbandp        fSig, kCrossFreq, kCrossFreq+1, sr/2, sr/2
   fBlurLow         pvsblur         fBandLow, kBlurLow, 10
   fBlurHigh        pvsblur         fBandHigh, kBlurHigh, 10
   fMix             pvsmix          fBlurLow, fBlurHigh
   
   if (kTable) == 1 then
    aOut		    PVS_BinStack	fMix, iBinOS, iBinMax, iBinIncr, iBlurTable, kType  
   else
    aOut		    PVS_BinStack	fMix, iBinOS, iBinMax, iBinIncr, iBlurTabLog, kType  
   endif
   
; if graph is off, blur with pvsblur
  else				          
   fBandLow         pvsbandp        fSig, 50, 50, kCrossFreq, kCrossFreq+1
   fBandHigh        pvsbandp        fSig, kCrossFreq, kCrossFreq+1, 15000, 15000
   fBlurLow         pvsblur         fBandLow, kBlurLow, 10
   fBlurHigh        pvsblur         fBandHigh, kBlurHigh, 10 
   fMix             pvsmix          fBlurLow, fBlurHigh             
   aOut			    pvsynth			fMix
  endif
 							   
 aMixL				ntrpol			aL, aOut, kMix
 aMixR				ntrpol			aR, aOut, kMix
		outs	aMixL, aMixR
else
		outs	aL, aR
endif
endin

</CsInstruments>
<CsScore>
i 1 0 3600
</CsScore>
</CsoundSynthesizer>
