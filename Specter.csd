; Specter by Kevin Hosey

; This effect uses HarmTweak.udo which is included in the same folder as this file.
; The input sound can be changed on lines 75-78 below.

<Cabbage>
form caption("Specter") size(550, 585), colour(10,10,10), pluginID("def1")

groupbox bounds(244, 3.5, 15, 15)
checkbox bounds(245, 5, 95, 12) channel("Mute")   text("Bypass") value(0), colour("yellow")
rslider  bounds(  5, 5, 70, 70) channel("Amp")    text("Amp")      textBox(1) range(0, 1, 0.5, 1, 0.01)
rslider  bounds( 85, 5, 70, 70) channel("FB")     text("Feedback") textBox(1) range(0, 1, 0.5, 1, 0.01)
rslider  bounds(165, 5, 70, 70) channel("MaxDel") text("MaxDelay") textBox(1) range(0.05, 10, 0.1, 1, 0.01)
rslider  bounds(285, 5, 70, 70) channel("MinBin") text("MinBin")   textBox(1) range(0, 90, 0, 1, 1)
rslider  bounds(345, 5, 70, 70) channel("MaxBin") text("MaxBin")   textBox(1) range(4, 513, 513, 1, 1)
rslider  bounds(405, 5, 70, 70) channel("Pan")    text("Pan")      textBox(1) range(0, 1, 0.5, 1, 0.1)
rslider  bounds(465, 5, 70, 70) channel("Width")  text("Width")    textBox(1) range(0, 100, 0, 1, 1)
hslider  bounds(175,95, 200,30) channel("DryWet") colour(100,140,150) trackercolour(200,240,250) range(0, 1, 1, 1, 0.01)

groupbox  bounds(  0, 135, 550, 95) text("Number of Bins:")
label     bounds(235,  80,  78, 12) text("Frequency")
label     bounds(235, 120,  78, 12) text("Dry/Wet")
numberbox bounds(250,  55,  46, 20) channel("Freq"),    range(0, 20000, 7, 1, 1 )
numberbox bounds(330, 136,  46, 18) channel("Length")   value(513) max(513) increment(1) 
image 	  bounds(  0, 220, 125, 69) colour(192,192,192) shape("sharp") outlinecolour("DarkSlateGrey") outlinethickness(2) identchannel("Image") rotate(0, 0, 0)

groupbox bounds( 0, 230, 550, 155) text("Delay Tables")
label    bounds(20, 253,  80, 14)  text("Amp.Table") 
combobox bounds(22, 268,  80, 20)  channel("AmpTable") value(1) text("Curve 1", "Curve 2", "Random", "Comb", "Flat") 
gentable bounds(22, 290, 235, 90)  identchannel("AmpTableID") tablecolour:0(0, 100, 100, 200) tablenumber(101), amprange(0,1,101), zoom(-1), active(1) 
label    bounds(270,253,  80, 14)  text("Freq.Table") 
combobox bounds(276,268,  80, 20)  channel("FrqTable") value(4) text("Curve 1", "Curve 2", "Random", "Comb", "Flat") 
gentable bounds(276,290, 235, 90)  identchannel("FrqTableID") tablecolour:0(0, 100, 40, 200) tablenumber(102), amprange(0,1,102), zoom(-1), active(1)  

groupbox bounds(0,  385, 550, 200) text("Harmonics Control")
groupbox bounds( 9, 388.5, 15, 15)
gentable bounds(65, 450, 410, 115) identchannel("table1") tablecolour:0(0, 100, 180, 200), tablenumber(1) amprange(0, 5, 1, 0.1), zoom(-1), active(1) 
button   bounds(10, 415, 80, 20), text("Reset Graph"),   channel("Reset"),  value(0)

checkbox bounds(10, 390, 100, 12) channel("All")  text("Bypass") value(0), colour("yellow")
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

; HarmTweak UDO created by Nathan Holmes
#include "HarmTweak.udo"

; delay tables displays
giViewTabSize	=	            -235*2
giAmpTableView	ftgen	        101,0,giViewTabSize,10,1                                                            
giFrqTableView	ftgen	        102,0,giViewTabSize,10,1

instr 1
kAmpTable		chnget			"AmpTable"
kFrqTable		chnget			"FrqTable"
kAll			chnget			"All"
kAmp			chnget			"Amp"
kFB				chnget			"FB"
kDel			chnget          "MaxDel"
kPan			chnget			"Pan"
kMinBin			chnget			"MinBin"
kMaxBin			chnget			"MaxBin"
kAngle			chnget			"Angle"
kWidth			chnget			"Width"
kDryWet		    chnget			"DryWet"
kMute			chnget			"Mute"
kReset          chnget          "Reset"
aL, aR			diskin2			"guitar.wav", 1, 0, 1	
;aL			    diskin2			"flute.wav", 1, 0, 1	
;aL, aR			diskin2			"pad.wav", 1, 0, 1	
;aL			    diskin2			"piano.wav", 1, 0, 1	
				
kAmpTable		init			1
kFrqTable		init			1
iftlen	        =	            32	
kftlen	        init	        iftlen

; effect mute control
if (kMute) == 0 then	
; harmonics control on/off														                                            
 if (kAll) == 0 then		
; partials and spread value for HarmTweak UDO													                                            
  iPartials		= 				32										                                                    
  iSpread 		= 				15    
; if any values on histogram are changed, update table                                                                                  
  kTrig         changed         kReset
  if kTrig==1 then                                                                                                          
   reinit	REBUILD_TABLE
  endif
  REBUILD_TABLE:
; amp and freq tables for HarmTweak UDO
  giAmpTab      ftgen           1, 0, -8, -2, 1, 1, 1, 1, 1, 1, 1, 1        
  iFreqTab 		ftgen 			1, 0, -8, -2, 1, 1, 1, 1, 1, 1, 1, 1                                                       
; update histogram display
  if kTrig==1 then		                                                                                                
	            chnset	        "tablenumber(1)", "table1"
  endif
  
; fundamental for HarmTweak opcode
  kFund, kAmpH 	ptrack 			aL, 1024      
; HarmTweak UDO call                                                                           
  aHarmL 		HarmTweak 		aL, kFund, iPartials, iSpread, 1024, giAmpTab, iFreqTab                                     
  aHarmR 		HarmTweak 		aL, kFund, iPartials, iSpread, 1024, giAmpTab, iFreqTab  
; If 'Bypass' is selected, bypass harmonic control
 else															                                                        
  aHarmL		=				aL
  aHarmR		=				aL
 endif
 
; display for filter
 if changed(int(kMinBin))==1||changed(int(kMaxBin))==1 then
   Smessage sprintfk "bounds(%d,%d,%d,%d)", kMinBin, 160, kMaxBin, 69                                                          
   chnset Smessage, "Image"
  endif	

 if changed(kDel, kAmpTable, kFrqTable, kMaxBin, kMinBin, kDryWet) == 1 then 												
 reinit	restart
 endif
 restart:
  iFFT		    =				1024 
  iBins		    =				(iFFT / 2) + 1
  iDelay		=				i(kDel)
  
; amplitude delay tables
  iftamps1		ftgen			11, 0, iFFT, -16, 0, iFFT*0.25, -4, iDelay, iFFT*0.75, 4, 0				                    
  iftamps2		ftgen			12, 0, iFFT, -16, 0, iFFT*0.0125,-4, iDelay, iFFT*0.075, 4, 0					            
  iftamps3		ftgen			13, 0, iFFT, -21, 1, iDelay			                                                        
  iftamps4		ftgen			14, 0, iFFT, -19, 8, iDelay*0.5, 0, iDelay*0.5			                                   
  iftamps5		ftgen			15,  0, iFFT, -7, iFFT, iFFT, iFFT								                            
  					 
; frequency delay tables
  iftfrqs1		ftgen			51, 0, iFFT, -16, 0, iFFT*0.25, -4, iDelay, iFFT*0.75, 4, 0							        
  iftfrqs2		ftgen			52, 0, iFFT, -16, 0, iFFT*0.0125,-4, iDelay, iFFT*0.075, 4, 0						        
  iftfrqs3		ftgen			53, 0, iFFT, -21, 1, iDelay								                                   
  iftfrqs4		ftgen			54, 0, iFFT, -19, 8, iDelay*0.5, 0, iDelay*0.5			                                   
  iftfrqs5		ftgen			55, 0, iFFT, -7, iFFT, iFFT, iFFT								                            
  
; tables for display
  giV1			ftgen			201,0,giViewTabSize,-16, 0, abs(giViewTabSize)*0.25, -4, 1, abs(giViewTabSize)*0.75, 4, 0	
  giV2			ftgen			202,0,giViewTabSize,-16, 0, abs(giViewTabSize)*0.0125, -4, 1, abs(giViewTabSize)*0.075, 4, 0					
  giV3			ftgen			203,0,giViewTabSize,-21,1,1	
  giV4			ftgen			204,0,giViewTabSize,-19, 8, 1*0.5, 0, 1*0.5	
  giV5		    ftgen			205,0,giViewTabSize,-7,1,abs(giViewTabSize),1			
  		                                        
                tablecopy 		101,200+i(kAmpTable) 
 				tablecopy		102,200+i(kFrqTable)
 				chnset			"tablenumber(101)","AmpTableID"                                                             
 				chnset			"tablenumber(102)","FrqTableID"
 
; display filter frequency value
  kFreq		    =				kMinBin * sr / iFFT									                        
  chnset		kFreq,			"Freq"	                                                                                    
  
; circular buffer processing
  iMask		    ftgen			0, 0, -iBins, 7, 0, i(kMinBin), 0, 0, 1, i(kMaxBin), 1, 0, 0                               
  fSigL		    pvsanal			aHarmL, iFFT, iFFT/4, iFFT, 1						                                       
  fFBL			pvsinit			iFFT, iFFT/4, iFFT, 1                                                                       
  fDelL		    pvsmix			fSigL, fFBL	
  iBufL,kTimeL	pvsbuffer		fDelL, iDelay							
  fReadL		pvsbufread2		kTimeL, iBufL, 10+i(kAmpTable), 50+i(kFrqTable)                                            
  fMaskL 		pvsmaska 		fReadL, iMask, 1                                                                            
  fFBL			pvsgain			fMaskL, kFB	

; stereo width on/off
 if kWidth == 0 then															                                        
  aWet			pvsynth		    fMaskL	
  aMix			ntrpol		    aHarmL, aWet, kDryWet	
 		outs	aMix*kAmp, aMix*kAmp 
 	
; if width is on, enable pan control
 else																		                                                
  aWetL		    pvsadsyn		fMaskL, int(iBins/2), 1, 0, 2			 
  aWetR		    pvsadsyn		fMaskL, int(iBins/2), 1, 1, 2	
  aMixL		    ntrpol			aHarmL, aWetL, kDryWet
  aMixR		    ntrpol			aHarmR, aWetR, kDryWet	
  aL			=				aMixL*(1-kPan)
  aR			=				aMixR*kPan
 		outs	aL*kAmp, aR*kAmp
 endif
 
; if effect is muted, play dry signal
else																		                                            
		outs	aL, aL
endif
endin

</CsInstruments>
<CsScore>
i 1 0 3600
</CsScore>
</CsoundSynthesizer>
