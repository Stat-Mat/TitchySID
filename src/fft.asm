;===================================================================
; TitchySID v1.5 by StatMat - November 2020
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

.CONST

; Number of bits needed to store indices (for 1024 samples)
NUM_BITS        equ 10

; FFT sizes
FFT_SIZE        equ 2048
FFT_HALF        equ FFT_SIZE/2

FFT_DATA_OFFSET equ 8184

.DATA?

; 1024 samples requires a 2046 DWORD LUT
gFFTBitTable DWORD 2046 dup (?)

; Space for 5 arrays with FFT_HALF x float elements
gFFTData REAL4 FFT_HALF*5 dup (?)

.CODE

gFFTBitTableESI:
    mov esi, OFFSET gFFTBitTable
    ret

; Complex Fast Fourier Transform
; Based on a free FFT routine in C by Don Cross. The basic algorithm
; for his code was based on Numerical Recipes in Fortran.
; Of course, to keep things smaller, everything superfluous has been
; removed.

FFT PROC uses ESI EDI NumSamples:DWORD, \
                      RealIn:PTR REAL4 , ImagIn:PTR REAL4, \
                      RealOut:PTR REAL4, ImagOut:PTR REAL4

    LOCAL i:DWORD
    LOCAL BlockSize:DWORD
    LOCAL j:DWORD
    LOCAL k:DWORD
    LOCAL n:DWORD
    LOCAL BlockEnd:DWORD
    LOCAL angle_numerator:REAL8
    LOCAL tr:REAL8 ; temp real
    LOCAL ti:REAL8 ; temp imaginary

    LOCAL delta_angle:REAL8
    LOCAL sm2:REAL8
    LOCAL sm1:REAL8
    LOCAL cm2:REAL8
    LOCAL cm1:REAL8
    LOCAL w:REAL8
    LOCAL ar0:REAL8
    LOCAL ar1:REAL8
    LOCAL ar2:REAL8
    LOCAL ai0:REAL8
    LOCAL ai1:REAL8
    LOCAL ai2:REAL8

    call gFFTBitTableESI
    push esi ; Store OFFSET gFFTBitTable on the stack

    ; Generate our fast bit LUT for 1024 samples. Once LUT is generated,
    ; gFFTBitTable[1] won't be zero, so allows us to do only once.

    .IF DWORD PTR [esi+4] == 0 ; gFFTBitTable[1]

        xor edi, edi

        .REPEAT

            ; Reverse the bits
            xor eax, eax
            mov edx, edi
            mov ecx, NUM_BITS
            
            @reverse:
                shr edx, 1
                rcl eax, 1
            loop @reverse
            
            mov DWORD PTR [esi+edi*4], eax
            inc edi
        .UNTIL di == FFT_HALF

    .ENDIF

    mov i, 2
    finit
    fild i
    fldpi
    fmul
    fstp angle_numerator

    ; Do simultaneous data copy and bit-reversal ordering into outputs...

    mov ecx, NumSamples
    @lut:

    ; Reverse the bits quickly using our generated LUT
    mov eax, [esp] ; OFFSET gFFTBitTable
    mov eax, DWORD PTR [eax+ecx*4]
    
    mov edi, RealOut
    mov esi, RealIn
    mov edx, [esi+ecx*4] ; RealIn[i]
    mov [edi+eax*4], edx ; RealOut[j]

    mov edi, ImagOut
    mov esi, ImagIn
    mov edx, [esi+ecx*4] ; ImagIn[i]
    mov [edi+eax*4], edx ; ImagOut[j]
    loop @lut

    pop eax ; Clear OFFSET gFFTBitTable off the stack

    xor eax, eax
    inc eax
    mov BlockEnd, eax
    inc eax
    mov BlockSize, eax
    mov edi, RealOut
    mov esi, ImagOut

    ; Do the FFT itself...
    .REPEAT
        fld angle_numerator
        fild BlockSize
        fdiv
        fstp delta_angle

        mov i, -2
        fild i
        fld delta_angle
        fmul
        fsincos
        fstp cm2
        fstp sm2

        fld delta_angle
        fchs
        fsincos
        fstp cm1
        fstp sm1
        
        neg i ; i = 2
        fild i
        fld cm1
        fmul
        fstp w
        
        mov i, 0

        .REPEAT
            fld cm2
            fstp ar2
            fld cm1
            fstp ar1
            
            fld sm2
            fstp ai2
            fld sm1
            fstp ai1

            mov eax, i
            mov j, eax
            xor ecx, ecx
         
            .WHILE ecx < BlockEnd
                fld w
                fld ar1
                fmul
                fld ar2
                fsub
                fstp ar0
                
                fld ar1
                fstp ar2
                fld ar0
                fstp ar1

                fld w
                fld ai1
                fmul
                fld ai2
                fsub
                fstp ai0
                
                fld ai1
                fstp ai2
                fld ai0
                fstp ai1
    
                mov eax, j
                mov edx, eax
                add eax, BlockEnd
                mov k, eax
                
                fld ar0
                fld REAL4 PTR [edi+eax*4] ; RealOut[k]
                fmul
                fld ai0
                fld REAL4 PTR [esi+eax*4] ; ImagOut[k]
                fmul
                fsub
                fstp tr

                fld ar0
                fld REAL4 PTR [esi+eax*4] ; ImagOut[k]
                fmul
                fld ai0
                fld REAL4 PTR [edi+eax*4] ; RealOut[k]
                fmul
                fadd
                fstp ti

                fld REAL4 PTR [edi+edx*4] ; RealOut[j]
                fld tr
                fsub
                fstp REAL4 PTR [edi+eax*4] ; RealOut[k]

                fld REAL4 PTR [esi+edx*4] ; ImagOut[j]
                fld ti
                fsub
                fstp REAL4 PTR [esi+eax*4] ; ImagOut[k]

                fld tr
                fld REAL4 PTR [edi+edx*4] ; RealOut[j]
                fadd
                fstp REAL4 PTR [edi+edx*4] ; RealOut[j]

                fld ti
                fld REAL4 PTR [esi+edx*4] ; ImagOut[j]
                fadd
                fstp REAL4 PTR [esi+edx*4] ; ImagOut[j]

                inc j
                inc ecx
            .ENDW

            mov ecx, NumSamples
            mov eax, BlockSize
            add i, eax
        .UNTIL i >= ecx

        mov eax, BlockSize
        mov BlockEnd, eax

        mov ecx, NumSamples
        shl BlockSize, 1
    .UNTIL BlockSize > ecx
   
   ret
FFT ENDP

; This function computes the FFT then adds the squares of the real and
; imaginary part of each coefficient, extracting the amplitude and throwing 
; away the phase.

AmplitudeSpectrum PROC uses ESI EDI pIn:PTR REAL4, pOut:PTR REAL4

    LOCAL NumSamples:DWORD
    LOCAL Half:DWORD
    LOCAL i:DWORD
    LOCAL i3:DWORD
    LOCAL theta:REAL4
    LOCAL wtemp:REAL4
    LOCAL wpr:REAL4
    LOCAL wpi:REAL4
    LOCAL wr:REAL4
    LOCAL wi:REAL4
    LOCAL h1r:REAL4
    LOCAL h1i:REAL4
    LOCAL h2r:REAL4
    LOCAL h2i:REAL4
    LOCAL rt:REAL4
    LOCAL it:REAL4
    LOCAL tmpReal:PTR REAL4
    LOCAL tmpImag:PTR REAL4
    LOCAL RealOut:PTR REAL4
    LOCAL ImagOut:PTR REAL4
    LOCAL copyIn:PTR REAL4
    LOCAL ftHalf: REAL4
    
    mov ftHalf, 3F000000h ; ftHalf = 0.5
    mov NumSamples, FFT_SIZE
    mov eax, FFT_HALF
    mov Half, eax
    shl eax, 2 ; FFT_HALF x 4

    call gFFTBitTableESI
    add esi,FFT_DATA_OFFSET

    lea edx, copyIn ; Remember, local vars are below EBP, so start at last var
    xor ecx, ecx
    
    ; Setup the tmpReal, tmpImag, RealOut, ImagOut and copyIn pointers
    .REPEAT
        mov REAL4 PTR [edx+ecx*4], esi
        add esi, eax
        inc ecx
    .UNTIL cl == 5

    finit
    fldpi
    fild Half
    fdiv
    fstp theta

    mov esi, pIn
    mov edi, copyIn
    mov edx, NumSamples
    dec edx

    mov ecx, NumSamples
    @process:

        ; Normalize 16-bit sample into the range -1 to 1
        mov eax, REAL4 PTR [esi+ecx*4] ; pIn[i]
        mov wtemp, eax
        fld wtemp
        mov i, 32768
        fild i
        fdiv
        
        ; Double sample to account for FFT mirroring
        mov i, 2
        fild i
        fmul
        fild Half
        fdiv
        
        ; Apply Hann window to sample
        fldpi
        fild i
        fmul
        mov i, ecx
        fild i
        fmul
        mov i, edx ; edx = NumSamples-1
        fild i
        fdiv
        fcos
        fld ftHalf
        fmul
        fld ftHalf
        fsub
        fmul
        fstp REAL4 PTR [edi+ecx*4] ; copyIn[i]
    loop @process

    mov esi, copyIn
    mov i, 0
  
    .REPEAT
        mov edx, i
        mov ecx, edx
        shl edx, 1

        mov eax, REAL4 PTR [esi+edx*4] ; copyIn[2 * i]
        mov edi, tmpReal
        mov REAL4 PTR [edi+ecx*4], eax ; tmpReal[i]

        inc edx
        mov eax, REAL4 PTR [esi+edx*4] ; copyIn[2 * i + 1]
        mov edi, tmpImag
        mov REAL4 PTR [edi+ecx*4], eax ; tmpImag[i]

        mov ecx, Half
        inc i
    .UNTIL i == ecx

    invoke FFT, Half, tmpReal, tmpImag, RealOut, ImagOut

    fld ftHalf
    fld theta
    fmul
    fsin
    fstp wtemp

    mov i, -2
    fild i
    fld wtemp
    fmul
    fld wtemp
    fmul
    fstp wpr

    fld theta
    fsin
    fst wpi
    fstp wi
  
    fld1
    fld wpr
    fadd
    fstp wr

    mov i, 1
    mov edi, pOut
    
    .REPEAT
        mov edx, i

        mov esi, RealOut
        mov eax, REAL4 PTR [esi+edx*4] ; RealOut[i]

        mov ecx, Half
        sub ecx, edx
        mov ecx, REAL4 PTR [esi+ecx*4] ; RealOut[i3]
        
        mov wtemp, eax
        fld wtemp
        mov wtemp, ecx
        fld wtemp
        fadd
        fld ftHalf
        fmul
        fstp h1r
        
        mov wtemp, eax
        fld wtemp
        mov wtemp, ecx
        fld wtemp
        fsub
        fld ftHalf
        fchs
        fmul
        fstp h2i

        mov esi, ImagOut
        mov eax, REAL4 PTR [esi+edx*4] ; ImagOut[i]

        mov ecx, Half
        sub ecx, edx
        mov ecx, REAL4 PTR [esi+ecx*4] ; ImagOut[i3]
        
        mov wtemp, eax
        fld wtemp
        mov wtemp, ecx
        fld wtemp
        fadd
        fld ftHalf
        fmul
        fstp h2r

        mov wtemp, eax
        fld wtemp
        mov wtemp, ecx
        fld wtemp
        fsub
        fld ftHalf
        fmul
        fstp h1i
  
        fld h1r
        fld wr
        fld h2r
        fmul
        fadd
        fld wi
        fld h2i
        fmul
        fsub
        fstp rt

        fld h1i
        fld wr
        fld h2i
        fmul
        fadd
        fld wi
        fld h2r
        fmul
        fadd
        fstp it
 
        fld it
        fld st
        fmul
        fld rt
        fld st
        fmul
        fadd
        fstp REAL4 PTR [edi+edx*4] ; pOut[i]

        fld h1r
        fld wr
        fld h2r
        fmul
        fsub
        fld wi
        fld h2i
        fmul
        fadd
        fstp rt

        fld h1i
        fchs
        fld wr
        fld h2i
        fmul
        fadd
        fld wi
        fld h2r
        fmul
        fadd
        fstp it
  
        mov ecx, Half
        sub ecx, edx
        fld it
        fld st
        fmul
        fld rt
        fld st
        fmul
        fadd
        fstp REAL4 PTR [edi+ecx*4] ; pOut[i3]
  
        fld wr
        fst wtemp
        fld wpr
        fmul
        fld wi
        fld wpi
        fmul
        fsub
        fld wr
        fadd
        fstp wr

        fld wi
        fld wpr
        fmul
        fld wtemp
        fld wpi
        fmul
        fadd
        fld wi
        fadd
        fstp wi

        mov ecx, Half
        shr ecx, 1
        inc i
    .UNTIL i == ecx

    mov esi, RealOut
    mov edi, ImagOut
    mov eax, pOut

    ; Calculate the DC bin
    fld REAL4 PTR [esi] ; RealOut[0]
    fst h1r
    fld REAL4 PTR [edi] ; ImagOut[0]
    fadd
    fld st
    fmul
    
    fld h1r
    fld REAL4 PTR [edi] ; ImagOut[0]
    fsub
    fld st
    fmul
    fadd
    fstp REAL4 PTR [eax] ; pOut[0]

    ; Calculate the Nyquist bin
    mov edx, Half
    mov ecx, edx
    shr edx, 1
    fld REAL4 PTR [esi+edx*4] ; RealOut[Half / 2]
    fld st
    fmul
    fld REAL4 PTR [edi+edx*4] ; ImagOut[Half / 2]
    fld st
    fmul
    fadd
    fstp REAL4 PTR [eax+edx*4] ; pOut[Half / 2]

    ; Convert from power spectrum to amplitude spectrum (magnitude)
    @ampspec:
        dec ecx
        fld REAL4 PTR [eax+ecx*4] ; pOut[i]
        fsqrt
        fstp REAL4 PTR [eax+ecx*4] ; pOut[i]
    jnz @ampspec
  
    ret
AmplitudeSpectrum ENDP

END
