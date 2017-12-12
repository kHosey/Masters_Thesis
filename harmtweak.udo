/* 
HarmTweak - modify harmonic magnitudes and frequencies of an audio signal

DESCRIPTION 
	Modify the frequency and amplitude of bins that fall within the harmonic series above 
a user-supplied	fundamental. HarmTweak ("harmonic tweak") takes two tables of scalar values: 
one table for frequency and one for amplitude. Each element in each table corresponds to a 
harmonic, with the fundamental (kfund) corresponding to the first element. The value of each
element is multiplied directly with PV bins that match the appropriate frequency, with a 
"tolerance" or "width" that can be modified via the ispread parameter. 
	The ispread parameter, in turn, is given in Hz, and it controls how wide or narrow the 
spectral change will be for each harmonic. Thus, nearby bins will be affected to a greater or 
lesser extent, depending on ispread's value. This does not scale as frequency increases, but is 
instead simply added and subtracted to each harmonic frequency, as is. So, e.g., if kfund = 100
and ispread = 10, the first harmonic will be treated as though it falls between 90 Hz and 110 Hz, 
while the second harmonic will fall between 190 Hz and 210 Hz, and the third between 290 Hz 
and 310 Hz, etc. Too large a value may cause overlapping in the "bands", which may give
unwanted results, as the scaling from one harmonic will overwrite scaling from another.
	Typically, a user will probably use one of Csound's pitchtracking opcodes (ptrack, plltrack, etc.),
then pass the result to HarmTweak through kfund. HarmTweak will generally work best on monophonic,
periodic instruments, but another viable use is to choose a fundamental, and then impose
harmonics upon any rich noise source (for example, white noise).

	Example tables for iamptab, with descriptions of their influence:
	
	f 1 0 -5 -2  1  0  2  0  0      ; The fundamental (first harmonic) is left unaltered,
                                    ; the second, fourth, and fifth harmonics are zeroed 
                                    ; out, and the third harmonic is doubled.
	
	f 2 0 -5 -2  1  1  1  1  1      ; All harmonic amplitudes multiplied by 1. No change to input
                                    ; signal.
	
	f 3 0 -5 -2 0.3 0.3 0.3 2.5 2.5	; Harmonics 1-3 are lowered, harmonics 4 and 5 are
                                    ; boosted.
									
	Example tables for ifreqtab:
	
	f 1 0 -5 -2 1  1   1   1  1      ; No change to signal
	
	f 2 0 -5 -2 1 1.2 1.2 1.2 1.2    ; All harmonics sharpened except fundamental 

	f 2 0 -5 -2 1  1  0.9  1   1     ; Third harmonic flattened

SYNTAX
aout HarmTweak asig, kfund, ipartials, ispread, ifftsize, iamptab, ifreqtab

INITIALIZATION
ipartials - Number of harmonics to be read from iamptab (should be size of iamptab and ifreqtab or smaller)
ispread   - A Hz value that determines the "width" of harmonic change in the spectrum
ifftsize  - FFT window size used in PV analysis
iamptab  - Table number for scalars to be applied to each harmonic's amplitude. See DESCRIPTION
for format examples.
ifreqtab - Table number for scalars to be applied to each harmonic's frequency. See DESCRIPTION
for format examples.

PERFORMANCE
aout      - Modified audio signal output
asig	  - Audio signal to be modified
kfund     - Fundamental frequency of the signal
	
CREDITS	
Nathan Holmes, 2017. Inspired by an email discussion on the Csound mailing list. Also draws much
from William Brent's Pure Data external, pitchEnv~.
*/

opcode HarmTweak, a, akiiiii
	asig, kfund, ipartials, ispread, ifftsize, iamptab, ifreqtab xin
	inumbins = ifftsize/2 + 1

	ifreqin ftgen 0, 0, inumbins, 2, 0
	iampin ftgen 0, 0, inumbins, 2, 0
	ifreqout ftgen 0, 0, inumbins, 2, 0	
	iampout ftgen 0, 0, inumbins, 2, 0

	fsig pvsanal asig, ifftsize, ifftsize/4, ifftsize*2, 1

	ktrig pvsftw fsig, iampin, ifreqin

	; only read bins when there is a frame available (i.e. when ktrig > 0)
	if ktrig > 0 then		
		; copy output tables to start
		tablecopy iampout, iampin
		tablecopy ifreqout, ifreqin

		; the basic strategy is, for each harmonic frequency (kcurpartial * kfund),
		; look through all the frequency bins to find bins which fall within the
		; range given by (kcurpartial * kfund) +- ispread.

		kcurpartial = 1
		while kcurpartial <= ipartials && kfund * kcurpartial + ispread < sr/2 && kfund > 20 do

			; establish upper and lower frequency boundaries, then use those values to find matching bins
			klow = kfund * kcurpartial - ispread
			if klow < 20 then
				klow = 20
			endif
			khigh = kfund * kcurpartial + ispread 	; no upper boundary check because that should be handled
												; by the "while" condition
			
			kampscale table kcurpartial-1, iamptab
			kfreqscale table kcurpartial-1, ifreqtab

			kbin = 0
			while kbin < inumbins do 
				kcuramp table kbin, iampin
				kcurfreq table kbin, ifreqin
				
				if kcurfreq > klow && kcurfreq < khigh then
					knewamp = kcuramp * kampscale
					knewfreq = kcurfreq * kfreqscale
					tabw knewamp, kbin, iampout
					tabw knewfreq, kbin, ifreqout
				endif
				
				kbin = kbin + 1
			od ; while kbin < inumbins
			
			kcurpartial = kcurpartial + 1
		od ; while kcurpartial < ipartials &&...
		
		; write table values back to pv stream
		pvsftr fsig, iampout, ifreqout 	
	endif ; if ktrig > 0

	aout pvsynth fsig
	
	xout aout
endop
	
