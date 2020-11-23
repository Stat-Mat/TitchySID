;===================================================================
; TitchySID v1.4 by StatMat - November 2020
;
; Based on TinySID by Tammo Hinrichs (kb) and Rainer Sinsch (myth)
;
; Caveat: This library has been stripped down to the bare essentials
; required for SID playback. This means that the code is pretty
; horrible in places, but the idea is to make the thing as small as
; possible. Everything is hard-coded to run at 44100Hz.
;===================================================================

.486
.MODEL FLAT, STDCALL
OPTION CASEMAP :NONE   ; case sensitive

; We need to include this for various defines
include titchysid.inc

PUBLIC c64Init
PUBLIC cpuJSR

.CONST

FLAG_N equ 128
FLAG_V equ 64
FLAG_B equ 16
FLAG_D equ 8
FLAG_I equ 4
FLAG_Z equ 2
FLAG_C equ 1

; The ordering of the SID modes and opcodes is different from TinySID.
; This is to save bytes in many pieces of flow-control code, so don't change!

; SID modes

abs  equ 1
absx equ 2
absy equ 3
zp   equ 4
zpx  equ 5
zpy  equ 6
indx equ 7
indy equ 8
imm  equ 9
acc  equ 10
rel  equ 11
imp  equ 12
ind  equ 13
xxx  equ 14

; SID opcodes

_bcc equ 0
_bcs equ 1
_bne equ 2
_beq equ 3
_bpl equ 4
_bmi equ 5
_bvc equ 6
_bvs equ 7

_clc equ 8
_sec equ 9
_cld equ 10
_sed equ 11
_cli equ 12
_sei equ 13
_clv equ 14

_sta equ 15
_stx equ 16
_sty equ 17

_pha equ 18
_php equ 19

_brk equ 20
_jmp equ 21
_jsr equ 22
_plp equ 23
_rti equ 24
_rts equ 25
_txs equ 26

_dex equ 27
_inx equ 28
_tax equ 29
_tsx equ 30
_dey equ 31
_iny equ 32
_tay equ 33
_pla equ 34
_txa equ 35
_tya equ 36

; Need both
_and equ 37
_eor equ 38
_ora equ 39
_dec equ 40
_inc equ 41
_bit equ 42

; Need one
_lda equ 43
_ldx equ 44
_ldy equ 45
_asl equ 46

; Need both
_lsr equ 47
_cmp equ 48
_cpx equ 49
_cpy equ 50
_rol equ 51
_ror equ 52

; Need one
_adc equ 53
_sbc equ 54

_nop equ 55
_xxx equ 56

; Some magic values for res calculation
REZ_MAGIC1 equ 2621        ; (int) 0.04 * 65536
REZ_MAGIC2 equ 78643       ; (int) 1.2 * 65536

; SID register definitions

; 7 bytes
sidvoice STRUCT
    freq WORD ?   ; 0
    pulse WORD ?  ; 2
    wave BYTE ?   ; 4
    ad BYTE ?     ; 5
    sr BYTE ?     ; 6
sidvoice ENDS

; 25 bytes
s6581 STRUCT
    v sidvoice 3 dup (<>)  ; 0 
    ffreqlo BYTE ?         ; 21
    ffreqhi BYTE ?         ; 22
    res_ftv BYTE ?         ; 23
    ftp_vol BYTE ?         ; 24
s6581 ENDS

; Internal oscillator def
; 44 bytes
sidosc STRUCT
    freq DWORD ?     ; 0
    pulse DWORD ?    ; 4
    wave BYTE ?      ; 8
    filter BYTE ?    ; 9
    attack DWORD ?   ; 10
    decay DWORD ?    ; 14
    sustain DWORD ?  ; 18
    release DWORD ?  ; 22
    counter DWORD ?  ; 26
    envval SDWORD ?  ; 30
    envphase BYTE ?  ; 34
    noisepos DWORD ? ; 35
    noiseval DWORD ? ; 39
    noiseout BYTE ?  ; 43
sidosc ENDS

; Internal filter def
; 28 bytes
sidfilt STRUCT
    freq DWORD ? ; 0
    l_ena BYTE ? ; 4
    b_ena BYTE ? ; 5
    h_ena BYTE ? ; 6
    v3ena BYTE ? ; 7
    vol DWORD ?  ; 8
    rez DWORD ?  ; 12
    h DWORD ?    ; 16
    b DWORD ?    ; 20
    l DWORD ?    ; 24
sidfilt ENDS

SIDOSC           equ 0
SIDOSC_FREQ      equ 0
SIDOSC_PULSE     equ 4
SIDOSC_WAVE      equ 8
SIDOSC_FILTER    equ 9
SIDOSC_ATTACK    equ 10
SIDOSC_DECAY     equ 14
SIDOSC_SUSTAIN   equ 18
SIDOSC_RELEASE   equ 22
SIDOSC_COUNTER   equ 26
SIDOSC_ENVVAL    equ 30
SIDOSC_ENVPHASE  equ 34
SIDOSC_NOISEPOS  equ 35
SIDOSC_NOISEVAL  equ 39
SIDOSC_NOISEOUT  equ 43

SID              equ 132
SID_VOICE_FREQ   equ 0 ; + 7 & 14 (voice 2 & 3)
SID_VOICE_PULSE  equ 2 ; + 9 & 16 (voice 2 & 3)
SID_VOICE_WAVE   equ 4 ; + 11 & 18 (voice 2 & 3)
SID_VOICE_AD     equ 5 ; + 12 & 19 (voice 2 & 3)
SID_VOICE_SR     equ 6 ; + 13 & 20 (voice 2 & 3)
SID_FFREQLO      equ 21
SID_FFREQHI      equ 22
SID_RES_FTV      equ 23
SID_FTP_VOL      equ 24

SIDFILT          equ 157
SIDFILT_FREQ     equ 0
SIDFILT_L_ENA    equ 4
SIDFILT_B_ENA    equ 5
SIDFILT_H_ENA    equ 6
SIDFILT_V3ENA    equ 7
SIDFILT_VOL      equ 8
SIDFILT_REZ      equ 12
SIDFILT_H        equ 16
SIDFILT_B        equ 20
SIDFILT_L        equ 24

BVAL_OFFSET      equ 185
BVAL             equ 0
WVAL             equ 1
A                equ 3
X                equ 4
Y                equ 5
P                equ 6
S                equ 7
PC               equ 8

MEMORY           equ 10
MEMORY_OFFSET    equ 195
MEMORY_COPY      equ MEMORY_OFFSET+65536

FMT1             equ 0
MODES            equ 68
OPCODES          equ 82

.DATA?

; Don't change the ordering of vars! Offsets are expected.

; ------------------------------------------------------------ globals

osc sidosc 3 dup (<>)
sid s6581 {}
filter sidfilt {}

; ------------------------------------------------------ C64 Emu Stuff
bval BYTE ? ; 0
wval WORD ? ; 1

; -------------------------------------------------- Register & memory
a BYTE ?    ; 3
x BYTE ?    ; 4
y BYTE ?    ; 5
p BYTE ?    ; 6
s BYTE ?    ; 7
pc WORD ?   ; 8

memory BYTE 65536 dup (?) ; 10
PUBLIC memory

data_end = $

memory_copy BYTE 65536 dup (?)

.DATA

; ------ pseudo-constants (all pre-calculated at a frequency of 44100Hz)

; 32 bytes
attacks WORD 42217, 11873, 6031, 3999, 2550, 1727, 1423, 1214, 969
        WORD 389, 194, 121, 97, 32, 19, 12

; 32 bytes
releases WORD 42660, 15469, 7857, 5211, 3322, 2250, 1854, 1582, 1263
         WORD 507, 253, 158, 127, 42, 25, 16

; ---------------------------------------------------------- constants

; 68 bytes
fmt1 db 004h,020h,054h,030h,00Dh
     db 080h,004h,090h,003h,022h
     db 054h,033h,00Dh,080h,004h
     db 090h,004h,020h,054h,033h
     db 00Dh,080h,004h,090h,004h
     db 020h,054h,03Bh,00Dh,080h
     db 004h,090h,000h,022h,044h
     db 033h,00Dh,0C8h,044h,000h
     db 011h,022h,044h,033h,00Dh
     db 0C8h,044h,0A9h,001h,022h
     db 044h,033h,00Dh,080h,004h
     db 090h,001h,022h,044h,033h
     db 00Dh,080h,004h,090h
     db 026h,031h,087h,09Ah ; $ZZXXXY01 INSTR'S

; 14 bytes
modes db xxx  ; ERR
      db imm  ; IMM
      db zp   ; Z-PAGE
      db abs  ; ABS
      db imp  ; IMPLIED
      db acc  ; ACCUMULATOR
      db indx ; (ZPAG,X)
      db indy ; (ZPAG),Y
      db zpx  ; ZPAG,X
      db absx ; ABS,X
      db absy ; ABS,Y
      db ind  ; (ABS)
      db zpy  ; ZPAG,Y
      db rel  ; RELATIVE

; 64 bytes
opcodes db _brk,_php,_bpl,_clc,_jsr,_plp,_bmi,_sec
        db _rti,_pha,_bvc,_cli,_rts,_pla,_bvs,_sei
        db _xxx,_dey,_bcc,_tya,_ldy,_tay,_bcs,_clv
        db _cpy,_iny,_bne,_cld,_cpx,_inx,_beq,_sed
        db _xxx,_bit,_jmp,_jmp,_sty,_ldy,_cpy,_cpx
        db _txa,_txs,_tax,_tsx,_dex,_xxx,_nop,_xxx
        db _asl,_rol,_lsr,_ror,_stx,_ldx,_dec,_inc
        db _ora,_and,_eor,_adc,_sta,_lda,_cmp,_sbc

.CODE

oscESI:
    mov esi, OFFSET osc
    ret

; ------------------------------------------------------------- synthesis

; render a buffer of n samples with the actual register contents
synth_render PROC uses ESI EDI buffer:PTR SWORD, len:DWORD
    LOCAL bpc:DWORD
    LOCAL triout:BYTE
    LOCAL sawout:BYTE
    LOCAL plsout:BYTE
    LOCAL outv:BYTE
    LOCAL outo:DWORD
    LOCAL outf:DWORD
    LOCAL bit:BYTE

    call oscESI

    xor ecx,ecx
    mov bpc,ecx
    mov edi,esi
    add edi,SID ; edi = OFFSET sid
    push esi
    movzx eax,BYTE PTR [edi+SID_RES_FTV] ; sid.res_ftv
    push eax

    ; step 1: convert the not easily processable sid registers into some
    ;         more convenient and fast values (makes the thing much faster
    ;         if you process more than 1 sample value at once)

    mov cl,3
    @step1:

        push ecx

        movzx eax,WORD PTR [edi+SID_VOICE_PULSE] ; sid.v[v].pulse
        and ax,0fffh
        shl eax,16
        mov [esi+SIDOSC_PULSE],eax ; osc[v].pulse
        
        shr DWORD PTR SS:[esp+4],1 ; sid.res_ftv >> 1
        setc BYTE PTR [esi+SIDOSC_FILTER] ; osc[v].filter

        movzx ecx,BYTE PTR [edi+SID_VOICE_AD] ; sid.v[v].ad
        mov eax,ecx
        shr eax,4
        mov edx,OFFSET attacks
        movzx eax,WORD PTR [edx + eax*2] ; attacks[eax]
        shl eax,2
        mov [esi+SIDOSC_ATTACK],eax ; osc[v].attack

        add edx,32 ; OFFSET releases

        and cl,0fh
        movzx eax,WORD PTR [edx + ecx*2] ; releases[ecx]
        mov [esi+SIDOSC_DECAY],eax ; osc[v].decay

        movzx ecx,BYTE PTR [edi+6] ; sid.v[v].sr
        push ecx
        and cl,0fh
        movzx eax,WORD PTR [edx + ecx*2] ; releases[ecx]
        mov [esi+SIDOSC_RELEASE],eax ; osc[v].release

        pop eax ; sid.v[v].sr
        and al,0f0h
        mov [esi+SIDOSC_SUSTAIN],eax ; osc[v].sustain

        mov al,BYTE PTR [edi+SID_VOICE_WAVE] ; sid.v[v].wave
        mov BYTE PTR [esi+SIDOSC_WAVE],al ; osc[v].wave

        movzx eax,WORD PTR [edi] ; sid.v[v].freq
        mov cx,359 ; Magic value for frequency calculation
        mul ecx
        mov [esi],eax ; osc[v].freq

        add edi,SIZEOF sidvoice
        add esi,SIZEOF sidosc
        
        pop ecx ; Loop counter

    loop @step1

    pop eax ; clear sid.res_ftv off the stack

    ; edi now points to sid.ffreqlo after above loop

    movzx eax,BYTE PTR [edi+1] ; sid.ffreqhi
    shl eax,4 ; eax x 16
    movzx ecx,BYTE PTR [edi] ; sid.ffreqlo
    and cl,7h
    add eax,ecx
    shl eax,5 ; eax x 32

    ; this isn't correct at all - the problem is that the filter
    ;   works only up to rmxfreq/4 - this is sufficient for 44KHz but isnt
    ;   for 32KHz and lower - well, but sound quality is bad enough then to
    ;   neglect the fact that the filter doesnt come that high ;)

    mov ecx,32768

    ; filter.freq > 32768
    .IF eax > ecx
        xchg eax,ecx
    .ENDIF
    
    mov [edi+4],eax ; filter.freq

    movzx edx, BYTE PTR [edi+3] ; sid.ftp_vol

    xor ecx,ecx
    mov cl,5

    ; get l_ena, b_ena, h_ena and v3ena flags
    @getflags:
        mov eax,edx
        shr eax,cl
        setc al
        mov BYTE PTR [edi+ecx+3],al
        inc ecx
        cmp cl,9
    jne @getflags
            
    xor BYTE PTR [edi+11],1 ; v3ena

    and dl,0fh ; dl = sid.ftp_vol
    mov [edi+12],edx ; filter.vol

    mov eax,REZ_MAGIC1
    movzx ecx,BYTE PTR [edi+2] ; sid.res_ftv
    shr cl,4
    mul ecx
    mov ecx,REZ_MAGIC2
    sub ecx,eax
    
    ; We precalculate part of the quick float operation, saves time in loop later
    shr ecx,8
    mov [edi+16],ecx ; filter.rez

    ; now render the buffer
    .REPEAT
        xor ecx,ecx

        mov outo,ecx
        mov outf,ecx

        ; Get the pointer to osc from the stack for repeated use below
        mov edi,DWORD PTR SS:[esp] ; OFFSET osc

        .WHILE ecx < 3
        
            ; Store current voice on the stack
            push ecx

            ; update wave counter
            mov eax,[edi]
            add [edi+SIDOSC_COUNTER],eax
            and DWORD PTR [edi+SIDOSC_COUNTER],0fffffffh

            xor eax,eax

            ; reset counter / noise generator if reset get_bit set
            .IF BYTE PTR [edi+SIDOSC_WAVE] & 08h ; osc[v].wave
                mov [edi+SIDOSC_COUNTER],eax ; osc[v].counter
                mov [edi+SIDOSC_NOISEPOS],eax ; osc[v].noisepos
                mov DWORD PTR [edi+SIDOSC_NOISEVAL],0ffffffh ; osc[v].noiseval
            .ENDIF

            ; reference oscillator for sync/ring
            dec cl

            ; Check not less than zero
            jns positive
            mov cl,2
            positive:

            ; Get pointer to osc[refosc] (al = refosc)
            mov eax,SIZEOF sidosc
            mul ecx
            mov esi,DWORD PTR SS:[esp+4] ; OFFSET osc
            add esi,eax ; ESI is now osc[refosc]

            ; sync oscillator to refosc if sync bit set
            .IF BYTE PTR [edi+SIDOSC_WAVE] & 02h ; osc[v].wave

                mov eax,[esi+SIDOSC_COUNTER] ; osc[refosc].counter
                mov ecx,[esi]    ; osc[refosc].freq

                .IF eax < ecx
                    mul DWORD PTR [edi] ; osc[v].freq
                    xor edx,edx
                    div ecx
                    mov [edi+SIDOSC_COUNTER],eax ; osc[v].counter
                .ENDIF
            .ENDIF

            mov eax,[edi+SIDOSC_COUNTER] ; osc[v].counter
            xor ecx,ecx

            .IF eax <= DWORD PTR [edi+SIDOSC_PULSE] ; osc[v].pulse
                dec cl ; cl = 0xff
            .ENDIF
        
            mov plsout,cl

            ; generate waveforms with really simple algorithms

            shr eax,19 ; osc[v].counter >> 19
            mov triout,al

            shr eax,1 ; osc[v].counter >> 20
            mov sawout,al

            ; generate noise waveform exactly as the SID does.
            
            shr eax,3 ; osc[v].counter >> 23

            .IF DWORD PTR [edi+SIDOSC_NOISEPOS] != eax ; osc[v].noisepos
                mov [edi+SIDOSC_NOISEPOS],eax 
                
                shl DWORD PTR [edi+SIDOSC_NOISEVAL],1 ; osc[v].noiseval

                xor edx,edx
                mov eax,[edi+SIDOSC_NOISEVAL]
                shr eax,18
                setc dl
                shr eax,5
                setc al

                xor dl,al
                or [edi+SIDOSC_NOISEVAL],edx

                xor ecx,ecx
                mov bit,cl
                xor edx,edx
                mov al,3
                mov cl,7
                mov dl,25

                .WHILE cl != 0ffh
                    
                    sub dl,al
                    dec al
                    
                    .IF al == 1
                        mov al,4
                    .ENDIF
                
                    push eax
                    push ecx

                    mov eax,[edi+SIDOSC_NOISEVAL]
                    mov cl,dl
                    shr eax,cl
                    and eax,1

                    pop ecx

                    shl eax,cl
                    or bit,al

                    pop eax
                    dec cl
                .ENDW
                
                mov al,bit
                mov BYTE PTR [edi+SIDOSC_NOISEOUT],al ; osc[v].noiseout
            .ENDIF

            mov cl,0ffh

            mov eax,[edi+SIDOSC_COUNTER] ; osc[v].counter
            shr eax,27 ; osc[v].counter >> 27
            
            jnz skipxor
            xor triout,cl
            skipxor:

            .IF BYTE PTR [edi+SIDOSC_WAVE] & 04h ; osc[v].wave
                                ; esi = osc[refosc]
                .IF DWORD PTR [esi+SIDOSC_COUNTER] < 8000000h ; osc[refosc].counter < 8000000h
                    xor triout,cl
                .ENDIF
            .ENDIF

            ; now mix the oscillators with an AND operation as stated in
            ;   the SID's reference manual - even if this is completely wrong.
            ;   well, at least, the $30 and $70 waveform sounds correct and there's
            ;   no real solution to do $50 and $60, so who cares.

            ; cl = 0ffh from above
            mov al,BYTE PTR [edi+SIDOSC_WAVE] ; osc[v].wave

            .IF al & 10h
                mov cl,triout
            .ENDIF

            .IF al & 20h
                mov cl,sawout
            .ENDIF

            .IF al & 40h
                mov cl,plsout
            .ENDIF

            .IF al & 80h
                mov cl,BYTE PTR [edi+SIDOSC_NOISEOUT] ; osc[v].noiseout
            .ENDIF

            mov outv,cl
            
            ; so now process the volume according to the phase and adsr values

            movzx eax,BYTE PTR [edi+SIDOSC_ENVPHASE] ; osc[v].envphase
            mov ch,al
            mov cl,4
            mul cl
            add al,10
                        
            mov eax,[edi+eax] ; osc[v].attack/decay/sustain/release
            lea edx,[edi+SIDOSC_ENVVAL] ; osc[v].envval
                        
            ; Phase 0 : Attack
            .IF ch == 0 ; osc[v].envphase
                add SDWORD PTR [edx],eax ; osc[v].envval
                mov eax,0ffffffh

                .IF SDWORD PTR [edx] >= SDWORD PTR eax
                    mov SDWORD PTR [edx],eax
                    inc BYTE PTR [edi+SIDOSC_ENVPHASE] ; osc[v].envphase = 1
                .ENDIF

            ; Phase 1 : Decay
            .ELSEIF ch == 1
                sub SDWORD PTR [edx],eax
                mov eax,[edi+SIDOSC_SUSTAIN] ; osc[v].sustain
                shl eax,16

                .IF SDWORD PTR [edx] <= SDWORD PTR eax
                    mov SDWORD PTR [edx],eax
                    inc BYTE PTR [edi+SIDOSC_ENVPHASE] ; osc[v].envphase = 2
                .ENDIF

            ; Phase 2 : Sustain
            .ELSEIF ch == 2
                shl eax,16

                .IF SDWORD PTR [edx] != SDWORD PTR eax
                    dec BYTE PTR [edi+SIDOSC_ENVPHASE] ; osc[v].envphase = 1
                .ENDIF
                ; :) yes, thats exactly how the SID works. and maybe
                ;   a music routine out there supports this, so better
                ;   let it in, thanks :)

            ; Phase 3 : Release
            .ELSE ; ch == 3
                sub SDWORD PTR [edx],eax
                mov eax,40000h

                .IF SDWORD PTR [edx] < SDWORD PTR eax
                    mov SDWORD PTR [edx],eax
                .ENDIF

                ; the volume offset is because the SID does not
                ;   completely silence the voices when it should. most
                ;   emulators do so though and thats the main reason
                ;   why the sound of emulators is too, err... emulated :)
            
            .ENDIF

            ; now route the voice output to either the non-filtered or the
            ;   filtered channel and dont forget to blank out osc3 if desired

            ; Get current voice from back from the stack
            pop ecx

            mov esi,DWORD PTR [esp] ; OFFSET osc
            add esi,SIDFILT ; esi = OFFSET filter

            .IF (cl < 2) || BYTE PTR [esi+SIDFILT_V3ENA] ; filter.v3ena
                movzx eax,outv
                lea eax,[eax-80h]
                mul SDWORD PTR [edi+SIDOSC_ENVVAL] ; osc[v].envval
                sar eax,22

                .IF BYTE PTR [edi+SIDOSC_FILTER] ; osc[v].filter
                    add outf,eax
                .ELSE
                    add outo,eax
                .ENDIF
            .ENDIF

            inc ecx
            add edi,SIZEOF sidosc
        .ENDW

        ; step 3
        ; so, now theres finally time to apply the multi-mode resonant filter
        ; to the signal. The easiest thing is just modelling a real electronic
        ; filter circuit instead of fiddling around with complex IIRs or even
        ; FIRs ...
        ; it sounds as good as them or maybe better and needs only 3 MULs and
        ; 4 ADDs for EVERYTHING. SIDPlay uses this kind of filter, too, but
        ; Mage messed the whole thing completely up - as the rest of the
        ; emulator.
        ; This filter sounds a lot like the 8580, as the low-quality, dirty
        ; sound of the 6581 is uuh too hard to achieve :)
        
        ; esi = OFFSET filter from above loop

        mov ecx,outf
        sal ecx,16
        mov eax,[esi+SIDFILT_B] ; filter.b
        sar eax,8
        mul DWORD PTR [esi+SIDFILT_REZ] ; filter.rez
        sub ecx,eax
        sub ecx,[esi+SIDFILT_L] ; filter.l
        mov [esi+SIDFILT_H],ecx ; filter.h

        xor ecx,ecx
        mov outf,ecx

        .WHILE ecx < 2
            mov eax,[esi] ; filter.freq
            sar eax,8
            mov edi,[esi + ecx*4 + 16] ; filter.h/filter.b
            sar edi,8
            mul edi
            add [esi+ ecx*4 + 20],eax ; filter.b/filter.l
            
            inc ecx
        .ENDW

        mov edi,esi
        add edi,4

        .WHILE cl != 0ffh ; cl is 2 from loop above
            .IF BYTE PTR [edi]
                mov eax,[esi + ecx*4 + 16]
                sar eax,16
                add outf,eax
            .ENDIF
            inc edi
            dec cl
        .ENDW

        mov eax,outo
        add eax,outf
        mul DWORD PTR [esi+SIDFILT_VOL] ; filter.vol

        ; Write out the final sample
        mov ecx,bpc
        mov edx,buffer
        shr eax,2 ; Just chop the sample down a bit
        mov SWORD PTR [edx+ecx*2],ax

        inc bpc
        mov eax,len
    .UNTIL bpc == eax

    pop esi ; Clear OFFSET osc off the stack (added right near the top of this sub)

    ret
synth_render ENDP

; * Don't use ECX or EDX *
; Params: address:WORD, inc_pc:DWORD
getmem:
    movzx eax,WORD PTR [esp+4] ; address

    .IF ax == 0dd0dh
        mov BYTE PTR [esi+eax+MEMORY],0 ; memory[eax] = 0
    .ENDIF

    movzx eax,BYTE PTR [esi+eax+MEMORY] ; memory[eax]

    .IF DWORD PTR [esp+6] ; inc_pc
        inc WORD PTR [esi+8] ; pc
    .ENDIF
    
    ret 6

; Params: address:WORD, value:WORD
setmem:
    push esi
    push edi

    call oscESI
    push esi ; store OFFSET osc on the stack

    movzx eax,WORD PTR [esp+16] ; address
    mov cl,BYTE PTR [esp+18] ; value
    mov BYTE PTR [esi+eax+MEMORY_OFFSET],cl
    movzx ecx,al
    and ah,0fch

    .IF ah == 0d4h
        and cl,1fh ; reg
        
        ; Poke a value into the sid register
        
        xor edi,edi ; voice
    
        .IF (cl >= 7) && (cl <= 13)
            inc edi
            sub cl,7
        .ELSEIF (cl >= 14) && (cl <= 20)
            add edi,2
            sub cl,14
        .ENDIF

        add esi,SID ; esi = OFFSET sid.v
        mov eax,SIZEOF sidvoice
        mul edi
        add esi,eax
    
        movzx edx,BYTE PTR [esp+18] ; value
    
        .IF cl > 3
            ; cl = 4  - sid.v[voice].wave
            ; cl = 5  - sid.v[voice].ad
            ; cl = 6  - sid.v[voice].sr
            ; cl = 21 - sid.ffreqlo
            ; cl = 22 - sid.ffreqhi
            ; cl = 23 - sid.res_ftv
            ; cl = 24 - sid.ftp_vol
    
            mov BYTE PTR [esi+ecx],dl

        .ELSE
            movzx eax,WORD PTR [esi+SID_VOICE_PULSE] ; sid.v[voice].pulse
    
            .IF cl <= 1
                movzx eax,WORD PTR [esi] ; sid.v[voice].freq
            .ENDIF
    
            ; Set frequency: High byte or
            ; Set pulse width: High byte
            .IF cl & 1 ; reg == 1 or reg == 3
                xor ah,ah ; mask off lower byte
                shl edx,8
    
            ; Set frequency: Low byte or
            ; Set pulse width: Low byte
            .ELSE
                xor al,al ; mask off upper byte
    
            .ENDIF
            
            add eax,edx
    
            xor edx,edx
            .IF cl > 1
                inc edx
            .ENDIF
            
            mov WORD PTR [esi+edx*2],ax ; sid.v[voice].freq or sid.v[voice].pulse
        .ENDIF
   
        .IF cl == 4
            mov eax,SIZEOF sidosc
            mul edi
            mov edx,[esp] ; OFFSET osc
            add edx,eax

            ; Directly look at GATE-Bit!
            ; a change may happen twice or more often during one cpujsr
            ; Put the Envelope Generator into attack or release phase if desired 
            
            .IF !(BYTE PTR [esp+18] & 1) ; value & 1
                mov BYTE PTR [edx+SIDOSC_ENVPHASE],3 ; osc[voice].envphase
    
            .ELSEIF BYTE PTR [edx+SIDOSC_ENVPHASE] == 3
                mov BYTE PTR [edx+SIDOSC_ENVPHASE],0
            .ENDIF
    
        .ENDIF
    .ENDIF

    pop esi ; clear OFFSET osc off the stack

    pop edi
    pop esi

    ret 4

; is_not_set = 0 - set
; is_not_set = 1 - put
; is_not_set = 2 - get
; Params: mode:DWORD, val:WORD, is_not_set:DWORD
set_put_get_addr:
    push edi

    xor eax,eax
    mov edi,DWORD PTR [esp+8] ; mode

    ; Nothing to do if absy or zpy for set
    .IF ((edi == absy) || (edi == zpy)) && !DWORD PTR [esp+14] ; is_not_set
        ret 10
    .ENDIF

    ; Shove a repeating code sequence here to save bytes
    ; Don't perform for acc, rel, imp, or ind (we do nothing
    ; for rel, imp, and ind, just return 0)

    mov ecx,indy
    add ecx,DWORD PTR [esp+14] ; is_not_set

    .IF DWORD PTR [esp+14] && (edi < ecx)
        push 1
        push WORD PTR [esi+PC]
        call getmem
        mov cx,ax
    .ENDIF

    movzx edx,WORD PTR [esi+PC]

    ; abs, absx and absy
    .IF edi <= absy

        .IF !DWORD PTR [esp+14] ; is_not_set
            lea edx,[edx-2] ; edx = pc
            push 0
            push dx
            call getmem
            mov cx,ax
            inc edx
        .ENDIF

        push DWORD PTR [esp+14] ; is_not_set
        push dx
        call getmem
        shl eax,8 ; quick multiply by 256
        or cx,ax

        xor eax,eax

        .IF edi != abs
            movzx eax,BYTE PTR [esi+Y]

            .IF edi == absx
                movzx eax,BYTE PTR [esi+X]
            .ENDIF
        .ENDIF
        
        .IF (edi == absx) || DWORD PTR [esp+14] ; is_not_set
            add cx,ax
        .ENDIF

        ; zp, zpx and zpy
    .ELSEIF edi <= zpy

        .IF !DWORD PTR [esp+14] ; is_not_set
            dec edx ; edx = PC
            push 0
            push dx
            call getmem
            mov cx,ax
        .ENDIF

        ; Do nothing for zp if get/put
        .IF edi != zp
            movzx eax,BYTE PTR [esi+Y]
        
            .IF edi == zpx
                movzx eax,BYTE PTR [esi+X]
            .ENDIF

            add cx,ax
            and cx,0ffh
        .ENDIF

    ; indx and indy
    .ELSEIF DWORD PTR [esp+14] && (edi <= indy)

        je notindx
            movzx eax,BYTE PTR [esi+X]
            add cx,ax
            movzx eax,cx
            and ax,0ffh
        notindx:

        push 0
        push ax
        call getmem
        push ax
        inc cx
        and cx,0ffh
        push 0
        push cx
        call getmem
        shl ax,8
        pop cx
        or ax,cx

        .IF edi == indy
            movzx ecx,BYTE PTR [esi+Y]
            add ax,cx
        .ENDIF

        mov cx,ax

    .ELSEIF edi == acc

        .IF DWORD PTR [esp+14] == 2 ; is_not_set == 2
            movzx eax,BYTE PTR [esi+A]

        .ELSE
            mov al,BYTE PTR [esp+12] ; val
            mov BYTE PTR [esi+A],al
        .ENDIF

    .ENDIF

    ; More repeated code for abs, absx, absy, zp, zpx, zpy, indx and indy
    .IF edi <= indy
    
        ; get
        .IF DWORD PTR [esp+14] == 2 ; is_not_set == 2
            push 0
            push cx
            call getmem
        
        ; set and put
        .ELSE

            ; no indx or indy for set
            .IF (edi >= indx) && !DWORD PTR [esp+14] ; is_not_set
                ret
            .ENDIF

             movzx eax,BYTE PTR [esp+12] ; val
             push ax
             push cx
             call setmem
        .ENDIF
    .ENDIF

    pop edi

    ret 10

; * Do not use ECX or EDX *
; Params: flag:DWORD, cond:DWORD
setflags:

  mov eax,DWORD PTR [esp+4] ; flag
  
  .IF DWORD PTR [esp+8] ; cond
      or BYTE PTR [esi+P],al ; or p,al
  .ELSE
      not al
      and BYTE PTR [esi+P],al ; and p,al
  .ENDIF
  
  ret 8

; * Don't use EAX or EDX *
; Params: val:WORD
_push:
    movzx ecx,BYTE PTR [esi+S]
    
    .IF cl
        dec BYTE PTR [esi+S]
    .ENDIF

    inc ch ; add 256 to cx
    push WORD PTR [esp+4] ; val
    push cx
    call setmem

    ret 2

; Params: none
_pop:
    
    inc BYTE PTR [esi+S]
    jnz nodec
    dec BYTE PTR [esi+S] ; back to 0ffh from 0 if necessary
    nodec:
    
    movzx eax,BYTE PTR [esi+S]
    inc ah ; add 256 to ax
    push 0
    push ax
    call getmem

    ret

; Params: none
c64Init:

    push esi
    push edi

    call oscESI
    push esi ; store OFFSET osc on the stack

    ; initialise SID and frequency dependant values

    xor eax,eax

IFDEF SID_EXTRAS

; We only need to reset the data if the extras are enabled
; because this function could be called multiple times during
; execution. We don't care otherwise as Windows itself will init
; the whole data? section to zero on program start.

    cld ; clear the direction flag for ops below

    ; Initialise whole DATA? section to zero in one go
    mov edi,esi
    mov ecx,data_end
    sub ecx,edi
    rep stosb
    
    ; Restore the initial copy of C64 memory
    add esi,MEMORY_COPY ; esi = OFFSET memory_copy
    mov edi,esi
    not cx
    inc ecx ; ecx = 65536 (was already zero after rep stosb above)
    sub edi,ecx ; OFFSET memory
    shr ecx,2 ; ecx = 16384
    rep movsd

ENDIF ; SID_EXTRAS

    mov esi,[esp] ; OFFSET osc
    dec BYTE PTR [esi+BVAL_OFFSET+S] ; sets s to 255 (as it's already 0)

    ; Setup the noiseval vars
    .WHILE eax < 3
        mov DWORD PTR [esi+SIDOSC_NOISEVAL],0ffffffh
        add esi,SIZEOF sidosc
        inc eax
    .ENDW
    
    pop esi ; clear OFFSET osc off the stack
    
    pop edi
    pop esi
    
    ret

; * Don't re-order the processing of opcodes *
; TinySID uses alphabetical ordering for the opcodes,
; but everything here is placed to save bytes.

cpuParse PROC uses EDI

    LOCAL _addr :DWORD

    ; ESI is already a pointer to bval from cpuJSR, so we can
    ; use ESI as a base for bval, wval, a, x, y, p, s and pc

    push 1
    push WORD PTR [esi+PC]
    call getmem ; GET OP CODE

    mov edi,OFFSET fmt1

    ; The following opcode decoder was taken from the Apple II System Monitor
    ; written by Steve Wozniak and Allen Baum all the way back in 1977...

    mov cl,al
    shr al,1    ; EVEN/ODD TEST
    jnc IEVEN
    rcr al,1    ; BIT 1 TEST

; Error checking is optional...
;    jc ERR      ; XXXXXX11 INVALID OP
;    cmp al,0A2h
;    je ERR      ; OPCODE $89 INVALID

    and al,087h ; MASK BITS
IEVEN:
    shr al,1    ; LSB INTO CARRY FOR L/R TEST
    mov al,byte ptr [edi+eax]  ; GET FORMAT INDEX BYTE 
    jnc RTMSKZ  ; R/L H-BYTE ON CARRY - IF EVEN, USE LO H
    shr al,4    ; SHIFT HIGH HALF BYTE DOWN
RTMSKZ:
    and al,00Fh ; MASK 4-BITS
    
; Error checking is optional...
;    jne GETFMT
;ERR:
;    mov cl,080h ; SUBSTITUTE $80 FOR INVALID OPS
;    xor al,al   ; SET PRINT FORMAT INDEX TO 0

GETFMT:
    push eax    ; push calculated mode value onto the stack
    mov al,cl   ; OPCODE TO A
    and cl,08Fh ; MASK FOR 1XXX1010 TEST
    mov dl,003h
    cmp cl,08Ah
    je MNNDX3
MNNDX1:
    shr al,1
    jnc MNNDX3  ; FORM INDEX INTO OPCODE TABLE
    shr al,1
MNNDX2:
    shr al,1    ; 1) 1XXX1010-&gt00101XXX
    or al,020h  ; 2) XXXYYY01-&gt00111XXX
    dec dl      ; 3) XXXYYY10-&gt00110XXX
    jne MNNDX2  ; 4) XXXYY100-&gt00100XXX
    inc dl      ; 5) XXXXX000-&gt000XXXXX
MNNDX3:
    dec dl
    jne MNNDX1
    
    pop edx
    movzx edx,BYTE PTR [edi+edx+MODES] ; get the mode
    movzx edi,BYTE PTR [edi+eax+OPCODES] ; store the opcode in EDI
    mov _addr,edx

    ; Shove a repeating code sequence here to save bytes
    ; Only perform for anything above tya (except nop and xxx)
    .IF (edi > _tya) && (edi < _nop)
        
        ; get
        push 2
        pushw 0
        push _addr
        call set_put_get_addr
        
        ; Only for everything below adc (except for lda, ldx, ldy and asl)
        .IF (edi < _adc) && ((edi < _lda) || (edi > _asl))
            mov BYTE PTR [esi],al ; bval
        .ENDIF
    .ENDIF

    ; bcc, bcs, bne, beq, bpl, bmi, bvc and bvs
    .IF edi <= _bvs
        movzx edx,BYTE PTR [esi+P]
        
        ; bvc + bvs (which isn't in the if block below to save bytes)
        mov al,FLAG_V
        
        .IF edi <= _bcs
            mov al,FLAG_C

        .ELSEIF edi <= _beq
            mov al,FLAG_Z

        .ELSEIF edi <= _bmi
            mov al,FLAG_N

        .ENDIF
        
        and dl,al
        setz al

        shr edi,1
        jc isodd
            ; _bcc, _bne, _bpl, _bvc
            mov dl,al
        isodd:
        
        push edx

        ; get
        push 2
        pushw 0
        push imm
        call set_put_get_addr
    
        cbw
        add ax,WORD PTR [esi+PC]
        mov WORD PTR [esi+WVAL],ax
        
        pop edx
        
        .IF edx
            mov WORD PTR [esi+PC],ax
        .ENDIF

    ; clc, cld, cli, clv, sec, sed and sei
    .ELSEIF edi <= _clv
        xor eax,eax
        xor edx,edx

        ; clv (which isn't in the if block below to save bytes)
        mov al,FLAG_V

        ; clc + sec
        .IF edi <= _sec
            mov al,FLAG_C

        ; cld + sed
        .ELSEIF edi <= _sed
            mov al,FLAG_D

        ; cli + sei
        .ELSEIF edi <= _sei
            mov al,FLAG_I
        .ENDIF

        shr edi,1
        jnc notodd
            ; _sec, _sed, _sei
            inc edx
        notodd:

        push edx
        push eax
        call setflags

    ; sta, stx and sty
    .ELSEIF edi <= _sty

        mov edx,edi
        sub edx,_sta
        add dl,3
        mov al,BYTE PTR [esi+edx] ; a/x/y
        
        ; put
        push 1
        push ax
        push _addr
        call set_put_get_addr

    ; pha and php
    .ELSEIF edi <= _php

        ; php (which isn't in the if block below to save bytes)
        mov al,BYTE PTR [esi+P]

        je notpha
            mov al,BYTE PTR [esi+A]
        notpha:

        push ax
        call _push

    .ELSEIF edi == _brk

        mov WORD PTR [esi+PC],0 ; Just quit the emulation

    ; jmp + jsr
    .ELSEIF edi <= _jsr

        jne notjsr
                
        mov ax,WORD PTR [esi+PC]
        inc ax
        mov dx,ax
        shr ax,8
        push ax
        call _push
        push dx
        call _push
        
        notjsr:

        push 1
        push WORD PTR [esi+PC]
        call getmem
        mov WORD PTR [esi+WVAL],ax
        push 1
        push WORD PTR [esi+PC]
        call getmem

        shl eax,8 ; quick multiply by 256        
        or WORD PTR [esi+WVAL],ax

        mov dx,WORD PTR [esi+WVAL]

        .IF (edi == _jsr) || (_addr == abs)
            mov WORD PTR [esi+PC],dx

        .ELSEIF _addr == ind
            
            push 0
            push dx
            call getmem
            inc dx
            mov WORD PTR [esi+PC],ax
            push 0
            push dx
            call getmem
            
            shl eax,8 ; quick multiply by 256        
            or WORD PTR [esi+PC],ax
        .ENDIF

    .ELSEIF edi == _plp

        call _pop
        mov BYTE PTR [esi+P],al

    ; rti and rts
    ; Treat RTI like RTS
    .ELSEIF edi <= _rts

        call _pop
        mov WORD PTR [esi+WVAL],ax
        call _pop
        shl ax,8
        or WORD PTR [esi+WVAL],ax
        mov ax,WORD PTR [esi+WVAL]
        inc ax
        mov WORD PTR [esi+PC],ax

    .ELSEIF edi == _txs

        mov al,BYTE PTR [esi+X]
        mov BYTE PTR [esi+S],al

    ; and, asl, bit, dec, dex, dey, eor, inc, inx, iny, lda,
    ; ldx, ldy, lsr, ora, pla, tax, tay, tsx, txa and tya
    ; Bloody ugly, but saves lots of bytes! ;)
    .ELSEIF edi <= _lsr

        .IF edi == _dex
            dec BYTE PTR [esi+X]

        .ELSEIF edi == _inx
            inc BYTE PTR [esi+X]

        .ELSEIF edi == _tax
            mov al,BYTE PTR [esi+A]
            mov BYTE PTR [esi+X],al

        .ELSEIF edi == _tsx
            mov al,BYTE PTR [esi+S]
            mov BYTE PTR [esi+X],al

        .ELSEIF edi == _dey
            dec BYTE PTR [esi+Y]

        .ELSEIF edi == _iny
            inc BYTE PTR [esi+Y]

        .ELSEIF edi == _tay
            mov al,BYTE PTR [esi+A]
            mov BYTE PTR [esi+Y],al

        ; _pla, _txa, _tya
        .ELSEIF edi <= _tya

            ; txa and tya (will be wrong for pla, but overwritten below)
            mov edx,edi
            sub edx,_txa
            add dl,4
            mov al,BYTE PTR [esi+edx] ; a/x/y

            .IF edi == _pla
                call _pop
            .ENDIF
        
        mov BYTE PTR [esi+A],al

        .ELSEIF edi == _and
            and BYTE PTR [esi+A],al

        .ELSEIF edi == _eor
            xor BYTE PTR [esi+A],al

        .ELSEIF edi == _ora
            or BYTE PTR [esi+A],al

        ; dec + inc
        .ELSEIF edi <= _inc

            jne notinc
                add BYTE PTR [esi],2 ; bval += 2
            notinc:
            
            dec BYTE PTR [esi]

            ; set
            push 0
            push WORD PTR [esi]
            push _addr
            call set_put_get_addr

        .ELSEIF edi == _bit
            and al,BYTE PTR [esi+A]

        ; lda, ldx and ldy
        .ELSEIF edi <= _ldy

            mov edx,edi
            sub edx,_lda
            add dl,3
            mov BYTE PTR [esi+edx],al ; a/x/y

        ; asl + lsr
        .ELSE
            .IF edi == _asl
                shl eax,1
            .ELSE
                shr eax,1
            .ENDIF        

            mov WORD PTR [esi+WVAL],ax
            
            ; set
            push 0
            push ax
            push _addr
            call set_put_get_addr

        .ENDIF

        xor edx,edx

        .IF edi < _asl

        ; and, eor, lda, ora, pla, txa and tya
        .IF (edi != _dec) && (edi != _inc)
            mov dl,A
        
            ; dex, inx, ldx, tax and tsx
            .IF (edi <= _tsx) || (edi == _ldx)
                mov dl,X
            
            ; dey, iny, ldy, and tay
            .ELSEIF (edi <= _tay) || (edi == _ldy)
                mov dl,Y
            
            .ENDIF
        
        .ENDIF
        
        ; dec and inc will be edx=0
        mov dl,BYTE PTR [esi+edx]
        
        .IF edi == _bit
            and dl,al
        .ENDIF
        
        ; asl + lsr
        .ELSE
            mov dx,WORD PTR [esi+WVAL]

        .ENDIF

        xor eax,eax
        .IF !edx
            inc eax
        .ENDIF

        push eax
        push FLAG_Z
        call setflags

        .IF edi == _bit
            movzx edx,BYTE PTR [esi] ; bval
        .ENDIF

        and dx,80h
        push edx
        push FLAG_N
        call setflags

        ; asl, bit and lsr
        .IF (edi == _bit) || (edi >= _asl)
            xor edx,edx
            movzx eax,BYTE PTR [esi] ; bval
            mov dl,FLAG_C

            .IF edi == _asl
                mov ax,WORD PTR [esi+WVAL]
                and ax,100h

            .ELSEIF edi == _bit
                and al,40h
                mov dl,FLAG_V

            ; lsr
            .ELSE
                and al,1

            .ENDIF

            push eax
            push edx
            call setflags
        .ENDIF

    ; cmp, cpx and cpy
    .ELSEIF edi <= _cpy

        xor edx,edx
        xor ecx,ecx
        
        mov ecx,edi
        sub ecx,_cmp
        add cl,3
        mov dl,BYTE PTR [esi+ecx]
        push edx

        sub dx,ax
        mov WORD PTR [esi+WVAL],dx
        setz cl

        push ecx
        push FLAG_Z
        call setflags

        ; edx still contains wval
        and dx,80h
        push edx
        push FLAG_N
        call setflags

        xor eax,eax
        pop edx

        .IF dl >= BYTE PTR [esi] ; bval
            inc eax
        .ENDIF

        push eax
        push FLAG_C
        call setflags

    ; rol and ror
    .ELSEIF edi <= _ror

        movzx edx,BYTE PTR [esi+P]
        and dl,FLAG_C
        
        .IF edi == _rol
            and al,80h ; al still contains bval
            shl BYTE PTR [esi],1 ; shl bval,1
        
        ; ror
        .ELSE
            and al,1
            shr BYTE PTR [esi],1 ; shr bval,1
            shl edx,7 ; quick multiply by 128
        .ENDIF

        push eax
        push FLAG_C
        call setflags
        or BYTE PTR [esi],dl ; or bval,dl
        
        ; set
        push 0
        push WORD PTR [esi] ; bval (can't push byte, so word will have to do)
        push _addr
        call set_put_get_addr

        movzx eax,BYTE PTR [esi] ; bval
        xor edx,edx

        .IF !al
            inc edx
        .ENDIF

        and al,80h
        push eax
        push FLAG_N
        call setflags
        push edx
        push FLAG_Z
        call setflags

    ; adc + sbc
    .ELSEIF edi <= _sbc
        
        jne notsbc
            xor al,0ffh
            mov BYTE PTR [esi],al ; bval
        notsbc:

        movzx edx,BYTE PTR [esi+A]
        add eax,edx

        .IF (BYTE PTR [esi+P] & FLAG_C)
            inc eax
        .ENDIF

        mov WORD PTR [esi+WVAL],ax
        and ax,100h
        push eax
        push FLAG_C
        call setflags
        movzx eax,WORD PTR [esi+WVAL]
        mov BYTE PTR [esi+A],al
        xor edx,edx

        .IF !al
            inc edx
        .ENDIF

        push edx
        push FLAG_Z
        call setflags
        
        .IF edi == _adc
            movzx eax,BYTE PTR [esi+A]
            and al,80h

        .ELSE
            xor eax,eax
            .IF BYTE PTR [esi+A] > 127
                inc eax
            .ENDIF
        .ENDIF

        push eax
        push FLAG_N
        call setflags
        movzx eax,BYTE PTR [esi+P]
        mov ecx,eax
        and al,FLAG_C
        and cl,FLAG_N
        xor eax,ecx
        push eax
        push FLAG_V
        call setflags

    ;.ELSEIF edi == _nop

    .ENDIF

    ret

cpuParse ENDP

; Params: npc:WORD, na:WORD - na is subsong
cpuJSR:

    ; More saving of bytes with a pointer
    ; This must be done here, as this function will
    ; be called from outside the emulation module
    ; (so ESI is not guaranteed and must be preserved)
    push esi

    call oscESI
    add esi,BVAL_OFFSET ; esi = OFFSET bval

    mov al,BYTE PTR [esp+10] ; na (subsong)
    mov BYTE PTR [esi+A],al

    xor eax,eax
    mov DWORD PTR [esi+X],eax ; sets x, y, p and s to zero
    dec BYTE PTR [esi+S] ; sets s to 255

    mov cx,WORD PTR [esp+8] ; npc
    mov WORD PTR [esi+PC],cx ; pc

    push eax ; 2 x WORD = 0
    call _push
    call _push

    .WHILE WORD PTR [esi+PC] > 1
        call cpuParse
    .ENDW

    pop esi

    ret 4

END
