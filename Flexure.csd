; Flexure by Kevin Hosey

; The input sound can be changed on lines 79-80 below.

<Cabbage>
form caption("Flexure") size(400, 400), colour(13, 50, 67,50), pluginID("def1")
gentable bounds(10, 10, 380, 200), tablenumbers(1), tablecolour("blue"), tablebackgroundcolour("white"), tablegridcolour(230,230,230), identchannel("table"), amprange(0,20,2), zoom(-1), active(1)
gentable bounds(10, 10, 380, 200), tablenumbers(2), tablecolour("blue"), tablebackgroundcolour("white"), tablegridcolour(230,230,230), identchannel("table2"), amprange(0,20,20), zoom(-1), active(1)
gentable bounds(10, 10, 380, 200), tablenumbers(3), tablecolour("blue"), tablebackgroundcolour("white"), tablegridcolour(230,230,230), identchannel("table3"), amprange(0,1025,3), zoom(-1), active(1)

combobox bounds(10, 220, 80, 20), text("Graph","Knobs"), channel("Select"), value(1)
combobox bounds(10, 245, 80, 20), text("Linear","Log.",), channel("Mapping"), value(1)
combobox bounds(10, 270, 80, 20), text("Lines","Bars",), channel("Bars"), value(1)
button   bounds(10, 295, 80, 20), text("Reset Graph"),   channel("Reset"),  value(0)

label    bounds( 1, 380, 178, 12),text("Envelope extraction method:"), 
combobox bounds(10, 350,125, 25),text("Liftered cepstrum method","True envelope method"), channel("Method"), value(1)
rslider bounds(120, 220, 50, 70), text("Scale"),    channel("scale"), range(0.1, 4, 1, 0.5, 0.001), colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
rslider bounds(180, 220, 50, 70), text("Shift"),    channel("shift"), range(-5000, 5000, 0),        colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
rslider bounds(240, 220, 50, 70), text("Feedback"), channel("FB"),    range(0, 0.99, 0),            colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
rslider bounds(160, 295, 50, 70), text("Mix"),      channel("mix"),   range(0, 1.00, 1),            colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
rslider bounds(220, 295, 50, 70), text("Level"),    channel("level"), range(0, 1.00, 0.5),          colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
rslider bounds(310, 315, 80, 80), text("Warp Gain"),channel("WarpGain"), range(0, 1.00, 1, 0.5),    colour("LightSlateGrey"), textcolour("white"), trackercolour("white")
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

; frequency warp UDO by Peiman Khosravi 
; available at http://csoundjournal.com/issue12/implementingFrequencyWarping.html
opcode warp,0,iiiiiii                                   
	iNumBins, iAmpIn, iFreqIn, iAmpOut, iFreqOut, iWarp, iCount xin
iClear 		    ftgen 		    0, 0, iNumBins, -2, 0
			    tablecopy 		iAmpOut,  iClear
			    tablecopy 		iFreqOut, iClear
kIndex 		    = 			    0 
loop:
kWarp			table   		kIndex, iWarp
kAmp			table   		kIndex, iAmpIn	
kFreq			table   		kIndex, iFreqIn
kAmpTest		table   		kWarp,  iAmpOut
kCount		    table   		kWarp,  iCount
kAverage 		= 			    1/(kCount+1)	
			    tablew  		kAverage, kWarp, iCount
if (kCount = 0) 	then
	tablew  	kFreq, kWarp, iFreqOut
	tablew  	kAmp, kWarp, iAmpOut  
elseif (kAmp>kAmpTest) then
	tablew  	kFreq, kWarp, iFreqOut
	tablew  	kAmp+kAmpTest, kWarp, iAmpOut
elseif (kAmp<kAmpTest) then
	tablew  	kAmp+kAmpTest, kWarp, iAmpOut
endif

kIndex 		    = 			    kIndex + 1
if (kIndex < iNumBins) kgoto loop
	vmultv  	iAmpOut, iCount, iNumBins
endop

instr 1 	
kWarpGain       chnget          "WarpGain"
kMapping        chnget          "Mapping"
kMouseL         chnget          "MOUSE_X"
kSelect         chnget          "Select"
kMethod         chnget          "Method"
kReset          chnget          "Reset"
kShift		    chnget		    "shift"
kScale		    chnget		    "scale"
kLevel		    chnget		    "level"
kBars           chnget          "Bars"
kMix			chnget		    "mix"
kFB			    chnget		    "FB"
;aL, aR			diskin2			"guitar.wav", 1, 0, 1	
aL, aR			diskin2			"pad.wav", 1, 0, 1	

iRange          =               800 
iFFT			=			    2048
iBins			=			    (iFFT / 2) + 1 

; initialize output and analyze input signal
aOut		    init			0                                                          
fSig    	    pvsanal	        aL+(aOut*kFB), iFFT, iFFT/4, iFFT, 1   

; initialize empty amplitude and frequency tables for warp UDO
iFreqIn 		ftgen 		    0, 0, iBins, 2, 0                                           
iAmpIn  		ftgen 		    0, 0, iBins, 2, 0
iFreqOut 		ftgen 		    0, 0, iBins, 2, 0
iAmpOut  		ftgen 		    0, 0, iBins, 2, 0
iCount  		ftgen 		    0, 0, iBins, 2, 0

; initialize tables for morphing
iFlatTab        ftgen           0, 0, iBins, -7, 0, iBins, iBins
iMixTabLin      ftgen           0, 0, iBins, -7, 0, iBins, iBins
iTabs4MorfLin   ftgen           0, 0, 2, -2, iFlatTab, 1
iMixTabLog      ftgen           0, 0, iBins, -5, 0.01, iBins, iBins
iTabs4MorfLog   ftgen           0, 0, 2, -2, iFlatTab, 2

iWarpTab		ftgen 		    3, 0, 32, -2, 0 
iCheck          =               0   
while iCheck<ftlen(iWarpTab) do
  tableiw (iCheck/(ftlen(iWarpTab)-1))*1025,iCheck,iWarpTab
  iCheck += 1
od
                   
; if 'graph' is selected enable warping via graph  
if kSelect == 1 then                                                                         
  kTrig         changed         kReset                           
   if kTrig==1 then                                                                      
    reinit	REBUILD_TABLE
   endif
   REBUILD_TABLE:
    iWarpTabLin	ftgen 		    1, 0, iBins, -7, 0, iBins, iBins                    ; warp table linear
    iWarpTabLog	ftgen 		    2, 0, iBins, -5, 20, iBins, iBins                   ; warp table log
    iWarpTabBar ftgen           0, 0, iBins, -18, iWarpTab, 1, 0, iRange            ; bars table
   rireturn
   
; log table visibility    
  if changed(kMapping)==1 then                                                                    
    Smessage	sprintfk	    "visible(%d)", kMapping-1
    chnset	Smessage, "table2"
  endif

; bars table visibility
  if changed(kBars)==1 then                                                                
   Smessage	    sprintfk	    "visible(%d)", kBars-1
   chnset	Smessage, "table3"
  endif
    
; update table displays
  if kTrig==1 then
                chnset	        "tablenumber(1)", "table"                               
                chnset	        "tablenumber(2)", "table2"  
                chnset	        "tablenumber(3)", "table3"                                  
  endif
  
; if GUI function table has been altered, ftmorf needs to be reinited
  if changed(kMouseL)==1 then
   reinit REINIT_FTMORF                                                                 
  endif
  REINIT_FTMORF:
; mix between a default/flat table and the GUI table
                ftmorf          kWarpGain, iTabs4MorfLin, iMixTabLin                        
                ftmorf          kWarpGain, iTabs4MorfLog, iMixTabLog 
  rireturn
    
; write fsig data to ampltide and frequency tables
  kFlag 		pvsftw 		    fSig, iAmpIn, iFreqIn   
      
; only write when there is data                            
  if (kFlag > 0) 	then                
     
; Call warp UDO with the table that is currently displayed                                                  
   if kMapping == 1 && kBars == 1 then
                warp		    iBins, iAmpIn, iFreqIn, iAmpOut, iFreqOut, iMixTabLin, iCount           
   elseif kMapping == 2 && kBars == 1 then
                warp		    iBins, iAmpIn, iFreqIn, iAmpOut, iFreqOut, iMixTabLog, iCount
   elseif kMapping == 2 && kBars == 2 then
                warp		    iBins, iAmpIn, iFreqIn, iAmpOut, iFreqOut, iWarpTabBar, iCount          
   endif
   
; read data back from table
                pvsftr	        fSig, iAmpOut, iFreqOut                                                
  endif
  
 aOut			pvsynth 	    fSig                                                        
 
; else if 'knobs' is selected enable warping via knobs
else            
; warp with pvswarp                                                                        
 fWarp		    pvswarp	        fSig, kScale, kShift, 0, kMethod                            
 aOut		    pvsynth         fWarp                                                      
 if(kFB>0) then
  aOut		clip	aOut, 0, 0dbfs
 endif
endif

aMixL			ntrpol		    aL, aOut, kMix
aMixR			ntrpol		    aR, aOut, kMix

	outs		aMixL*kLevel, aMixR*kLevel
endin

</CsInstruments>
<CsScore>
i 1 0 3600
</CsScore>
</CsoundSynthesizer>
