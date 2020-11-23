;===================================================================
; TitchySID v1.4 by StatMat - November 2020
;
; Based on TinySID by Tammo Hinrichs (kb) and Rainer Sinsch
;
; Caveat: This library has been stripped down to the bare essentials
; required for SID playback. This means that the code is pretty
; horrible in places, but the idea is to make the thing as small as
; possible. Everything is hard-coded to run at 44100Hz.
;===================================================================

synth_render PROTO :PTR SWORD, :DWORD

EXTERNDEF memory :BYTE
