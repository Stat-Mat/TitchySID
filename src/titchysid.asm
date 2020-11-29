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

include windows.inc
include kernel32.inc
include winmm.inc

EXTERNDEF c64Init:NEAR
EXTERNDEF cpuJSR:NEAR

include sidemu.inc
include titchysid.inc
include fft.inc

.CONST

; Allow for conditional DLL building

IFDEF BUILD_DLL
    StartLabel equ LibMain
ELSE
    StartLabel equ
ENDIF

; Number of samples to generate on each call to GenSamples.
; This allows us a nicely defined window of sample data
; for our fast fourier transform (FFT) calcs.
SAMPLES_PER_CALL equ 2048
FRAGMENTSMASK    equ 15
TOTALBLOCKS      equ FRAGMENTSMASK + 1
BLOCKSIZE        equ SAMPLES_PER_CALL * 4 ; 1024x4 stereo word samples (4096 bytes)
BUFFERSIZE       equ BLOCKSIZE * TOTALBLOCKS

; The number of samples we process for the FFT
FFT_SIZE         equ 2048

; Our data? section var offsets

; sid_props structure offsets
LOAD_ADDR        equ 108
INIT_ADDR        equ 106
PLAY_ADDR        equ 104
NUM_SONGS        equ 102
DEFAULT_SONG     equ 101
SPEED            equ 100
DATA_SIZE        equ 98
SID_NAME         equ 96
AUTHOR           equ 64
COPYRIGHT        equ 32

HTHREAD          equ 0 ; our mid point (offsets are one byte either side of this)
HWAVEOUT         equ 4
FILLBLOCK        equ 8
MIXBLOCK         equ 12
MMT              equ 44

SW_EXIT          equ 56
THREADRUNNING    equ 57
PLAYING          equ 58
CURRENTSONG      equ 59
SAMPLESTORENDER  equ 60
SAMPLESRENDERED  equ 64
SEMAPHORE        equ 68

SOUNDBUF         equ 72
DATABUF          equ SOUNDBUF + (SAMPLES_PER_CALL * 2)
REALIN           equ DATABUF + (BUFFERSIZE * 2)

.DATA?

; Don't change the ordering of the vars! Offsets are expected.

sid_props props {}      ; 0 (offset)

hThread DWORD ?         ; 108
hWaveOut DWORD ?        ; 112

FillBlock DWORD ?       ; 116
MixBlock WAVEHDR {}     ; 120
mmt MMTIME {}           ; 152

SW_Exit BYTE ?          ; 164
ThreadRunning BYTE ?    ; 165
Playing BYTE ?          ; 166
CurrentSong BYTE ?      ; 167
SamplesToRender DWORD ? ; 168
SamplesRendered DWORD ? ; 172
Semaphore DWORD ?       ; 176

; Enough space for 1024 word length samples (2048 bytes) ; 180
soundBuf SWORD SAMPLES_PER_CALL dup (?)

; Enough space for BLOCKSIZE x 16 stereo word samples (65536 bytes)
dataBuf WORD BUFFERSIZE dup (?)

; Our real input array for the FFT
RealIn REAL4 FFT_SIZE dup (?)

.DATA

; WAVEFORMATEX structure contents
wfx dd 20001h, 44100, 44100*4, 100004h

.CODE

IFDEF BUILD_DLL
    
LibMain PROC hInstDLL:DWORD, reason:DWORD, unused:DWORD
    mov eax,1
    ret
LibMain ENDP

ENDIF

; Generate samples in 16-bit stereo
GenSamples PROC uses ESI EDI

    call hThreadESI
    mov edi, esi
    add edi, DATABUF
    
    lea ecx,[esi+FILLBLOCK]

    mov eax, BLOCKSIZE
    mul DWORD PTR [ecx] ; FillBlock
    add edi, eax ; jump to the block offset

    xor eax, eax
    inc DWORD PTR [ecx] ; FillBlock

    .IF DWORD PTR [ecx] == TOTALBLOCKS
        mov [ecx], eax
    .ENDIF

    mov DWORD PTR [esi+SAMPLESRENDERED], eax

    ; Now render the music into soundBuf
    .REPEAT
        .IF DWORD PTR [esi+SAMPLESTORENDER] == 0
            pushw 0
            push WORD PTR [esi-PLAY_ADDR]
            call cpuJSR
            
            ; Find out if CIA timing is used and how many samples
            ; have to be calculated for each cpuJSR
            xor ecx,ecx
            movzx eax, WORD PTR [c64_memory+0dc04h]
            mov cx, 20000
            mul ecx
            xor edx,edx
            mov cx, 4c00h
            div ecx

            .IF (ax == 0) || (BYTE PTR [esi-SPEED] == 0)

                ; If CIA timing is not used, or the song speed is zero,
                ; then just setup a value that will give the result of
                ; 882 below (PAL SID single speed is 44100/50Hz = 882)
            
                mov eax, 20000
            .ENDIF

            mov cx, 44100
            mul ecx
            xor edx,edx
            mov ecx, 1000000
            div ecx
            mov DWORD PTR [esi+SAMPLESTORENDER], eax
        .ENDIF

        mov eax, SAMPLES_PER_CALL
        mov ecx, DWORD PTR [esi+SAMPLESRENDERED]
        mov edx, ecx
        shl edx, 1 ; x2
        add edx,esi
        add edx,SOUNDBUF
        add ecx, DWORD PTR [esi+SAMPLESTORENDER]

        .IF ecx > eax
            mov ecx, DWORD PTR [esi+SAMPLESRENDERED]
            sub eax, ecx
            push eax
            mov eax, SAMPLES_PER_CALL
            mov DWORD PTR [esi+SAMPLESRENDERED], eax
            sub eax, ecx
            sub DWORD PTR [esi+SAMPLESTORENDER], eax
        .ELSE
            mov eax, DWORD PTR [esi+SAMPLESTORENDER]
            push eax
            add DWORD PTR [esi+SAMPLESRENDERED], eax
            push 0
            pop DWORD PTR [esi+SAMPLESTORENDER]
        .ENDIF
        
        push edx
        call synth_render

        mov ecx, SAMPLES_PER_CALL
    .UNTIL DWORD PTR [esi+SAMPLESRENDERED] == ecx

    ; Convert the mono data to stereo
    ; ecx = SAMPLES_PER_CALL from last iteration of loop above
    @mono2stereo:
        movsx eax, SWORD PTR [esi+SOUNDBUF]

        mov [edi], ax
        mov [edi+2], ax

        add esi, SIZEOF SWORD
        add edi, SIZEOF SWORD * 2
    loop @mono2stereo

    ret
GenSamples ENDP

; ESI must contain OFFSET hThread
waveOutStop:
    push DWORD PTR [esi+HWAVEOUT]
    call waveOutReset
    ret

; ESI must contain OFFSET hThread
waveOutCall:
    push SIZEOF WAVEHDR
    lea eax,[esi+MIXBLOCK]
    push eax ; OFFSET MixBlock.lpData
    push DWORD PTR [esi+HWAVEOUT]
    call DWORD PTR [esp+16]
    ret 4

hThreadESI:
    mov esi, OFFSET hThread
    ret

SIDThread PROC uses ESI EDI param:LPVOID

    call hThreadESI

    xor eax, eax
    mov DWORD PTR [esi+FILLBLOCK],eax

    ; try to open the default wave device. WAVE_MAPPER is
    ; a constant defined in mmsystem.h, it always points to the
    ; default wave device on the system (some people have 2 or
    ; more sound cards).
    
    push eax
    push eax
    push eax
    push OFFSET wfx
    push WAVE_MAPPER
    lea eax,[esi+HWAVEOUT]
    push eax ; OFFSET hWaveOut
    call waveOutOpen
    
    ; Unable to open wave mapper device
    ;.IF eax != MMSYSERR_NOERROR
    ;    invoke ExitThread,1
    ;.ENDIF

    mov DWORD PTR [esi+MIXBLOCK+4], BUFFERSIZE ; MixBlock.dwBufferLength
    or DWORD PTR [esi+MIXBLOCK+20], -1 ; MixBlock.dwLoops
    lea eax,[esi+DATABUF]
    mov DWORD PTR [esi+MIXBLOCK], eax ; MixBlock.lpData
    push 12 ; WHDR_BEGINLOOP | WHDR_ENDLOOP
    pop DWORD PTR [esi+MIXBLOCK+16] ; MixBlock.dwFlags

    push waveOutPrepareHeader
    call waveOutCall

    ; Prefill the sound buffers
    .REPEAT
        invoke GenSamples
    .UNTIL DWORD PTR [esi+FILLBLOCK] == 0

    push waveOutWrite
    call waveOutCall

IFDEF SID_EXTRAS
    inc BYTE PTR [esi+PLAYING]
ENDIF

    .WHILE BYTE PTR [esi+SW_EXIT] == 0

IFDEF SID_EXTRAS

        ; Wait for the semaphore to be nonsignaled before
        ; doing any sound update
        call WaitSemaphore
ENDIF

        lea eax,[esi+MMT] ; OFFSET mmt
        push 4
        pop [eax] ; mmt.wType
          
        push SIZEOF MMTIME
        push eax ; OFFSET mmt
        push DWORD PTR [esi+HWAVEOUT]
        call waveOutGetPosition

        mov eax, [esi+MMT+4] ; mmt.cb
        xor edx, edx
        mov ecx, BLOCKSIZE
        div ecx ; / BLOCKSIZE
        and eax, FRAGMENTSMASK   ; % TOTALBLOCKS

        .IF DWORD PTR [esi+FILLBLOCK] != eax ; FillBlock != eax

IFDEF SID_EXTRAS

            mov ecx, eax
            lea edi,[esi+DATABUF]
            mov eax, BLOCKSIZE
            mul ecx
            add edi, eax ; jump to the block offset

            lea edx, [esi+REALIN]

            mov ecx,FFT_SIZE
            @copyfft:
                
                ; Copy the sample data to our real values array for the FFT      
                fild SWORD PTR [edi]
                fstp REAL4 PTR [edx]

                ; Skip every second byte as it's identical. This is because
                ; the SID output is mono even though the mixing block is stereo.
                add edi, SIZEOF SWORD * 2
                add edx, SIZEOF REAL4
            loop @copyfft

ENDIF ; SID_EXTRAS

            call GenSamples

        .ELSE
            ; Take a little nap
            invoke WaitForSingleObject, [esi], 5
        .ENDIF

IFDEF SID_EXTRAS

        call RelSemaphore

ENDIF

    .ENDW

    ; Stop sound output
    call waveOutStop

    push waveOutUnprepareHeader
    call waveOutCall
      
    ; Close the PCM driver
    ; I think we can get away without doing this...
    ;invoke waveOutClose, DWORD PTR [esi+HWAVEOUT]

    ; We should be able to do without this also...
    ;invoke ExitThread, 0

    ret
SIDThread ENDP

; Returns non-zero on success
SIDOpen PROC uses ESI EDI sid:DWORD, sidlen:DWORD, mode:BYTE, options:BYTE, subsong:BYTE

    call hThreadESI
    mov edi,esi

    ; Thread is already running, so stop it first
    .IF BYTE PTR [edi+THREADRUNNING]
        call SIDClose
    .ENDIF

    ; Just init ESI as if sid param is a pointer to
    ; a block of memory passed by the caller
    mov esi,sid
    
    push edi ; store OFFSET hThread on the stack
  
    ; Load the SID data from a resource in the exe
    .IF mode == SID_RESOURCE
        assume fs:nothing
        
        ; Get image base
        mov edi, fs:[30h] 
        mov edi, [edi+8]
        push edi

        assume fs:error

        ; Get PE header address
        add edi, [edi+3ch]

        ; Get Resource directory RVA
        add edi, IMAGE_SIZEOF_FILE_HEADER + 100 + IMAGE_DIRECTORY_ENTRY_RESOURCE * SIZEOF(IMAGE_DATA_DIRECTORY)

        ; Get Resource directory address
        mov edx, DWORD PTR SS:[esp]
        add edx, [edi]
        mov edi, edx
        
        ; Traverse the three levels of resource directories to get our SID resource
        xor ecx,ecx
        push ecx
        push esi
        push RT_RCDATA
        mov cl,3
        scan_entries:
            pop eax
            push ecx
            movzx ecx, word ptr [edi+14]
            add edi, SIZEOF IMAGE_RESOURCE_DIRECTORY
            
            entries:
                .IF cx > 1
                    cmp [edi], eax
                    je found_entry
                    add edi, SIZEOF IMAGE_RESOURCE_DIRECTORY_ENTRY
                .ENDIF
            loop entries

            found_entry:
            movzx edi, word ptr [edi+4]
            add edi, edx
            pop ecx
        loop scan_entries
        
        pop esi
        add esi, [edi]
        
        mov eax, [edi+4]
        mov sidlen, eax
    .ENDIF

    cld ; clear the direction flag just in case

    call c64Init

    mov edi,[esp] ; OFFSET hThread
    push esi ; Store SID data pointer for use later

    movzx edx,BYTE PTR [esi+7] ; data file offset

    ; Load address
    movzx eax,WORD PTR [esi+edx]
    mov WORD PTR [edi-LOAD_ADDR],ax ; sid_props.load_addr

    ; Get init and play addresses (also convert to little endian)
    mov eax,DWORD PTR [esi+10]
    xchg al,ah
    rol eax,16
    xchg al,ah
    rol eax,16
    mov DWORD PTR [edi-INIT_ADDR],eax ; sid_props.init_addr + sid_props.play_addr (2 x WORD)
    
    mov ah,BYTE PTR [esi+15h] ; Speed
    shl eax,8
    mov ah,BYTE PTR [esi+11h] ; Default song
    mov al,BYTE PTR [esi+0fh] ; Number of songs
    mov DWORD PTR [edi-NUM_SONGS],eax ; sid_props.num_songs + sid_props.default_song + sid_props.speed

    ; Calc src
    add dl,2 ; data file offset
    add esi,edx ; esi is still pointing to the sid file data

    ; Calc len
    mov ecx,sidlen
    sub ecx,edx
    mov WORD PTR [edi-DATA_SIZE],cx ; sid_props.data_size
    
    ; Calc dest
    movzx edi,WORD PTR [edi-LOAD_ADDR] ; sid_props.load_addr
    mov eax,OFFSET c64_memory
    push eax ; store C64 memory offset for use later
    add edi,eax

    ; Copy the SID data to the C64 memory
    rep movsb

IFDEF SID_EXTRAS
    
    ; Take a copy of the C64 memory
    mov esi,[esp] ; esi = OFFSET c64_memory
    mov edi,esi
    not cx
    inc ecx ; ecx = 65536 (was already zero after rep movsb above)
    add edi,ecx ; edi = OFFSET c64_memory_copy
    shr ecx,2 ; ecx = 16384
    rep movsd

ENDIF ; SID_EXTRAS

    pop esi ; esi = OFFSET c64_memory
    mov edi,[esp+4] ; edi = OFFSET hThread
 
    .IF WORD PTR [edi-PLAY_ADDR] == 0 ; props.play_addr
        push DWORD PTR [edi-INIT_ADDR] ; props.init_addr
        call cpuJSR

        movzx eax,WORD PTR [esi+314h] ; c64_memory+314h - address of interrupt service routine (raster IRQ)
        mov WORD PTR [edi-PLAY_ADDR],ax ; props.play_addr
    .ENDIF

    pop esi ; sid_file

IFDEF SID_EXTRAS

    sub edi,SID_NAME ; edi = props.sid_name

    ; Copy name, author and copyright strings to the sid_props struct
    push 24 ; 24 dwords, 96 bytes
    pop ecx
    add esi,16h ; skip to name field in sid file data
    rep movsd

ENDIF

    pop edi ; OFFSET hThread

    mov al, subsong

    ; Use default song if flag is set
    .IF options & SID_DEFAULT
        mov al, BYTE PTR [edi-DEFAULT_SONG] ; sid_props.default_song
        dec al
    .ENDIF

IFDEF SID_EXTRAS
    mov BYTE PTR [edi+CURRENTSONG],al
ENDIF

    push ax ; play_addr
    push WORD PTR [edi-INIT_ADDR] ; sid_props.init_addr
    call cpuJSR
  
    xor eax,eax
    push eax
    push eax
    push eax
    push SIDThread
    push eax
    push eax
    call CreateThread
    mov [edi], eax ; Store hThread
      
    ; Should really check that a valid thread
    ; handle is returned, but oh well... :p
    ;.IF eax
    ;    invoke SetThreadPriority, eax, THREAD_PRIORITY_TIME_CRITICAL
        inc BYTE PTR [edi+THREADRUNNING]
    ;.ENDIF

    ret
SIDOpen ENDP

SIDClose PROC uses ESI

    call hThreadESI
    inc BYTE PTR [esi+SW_EXIT]

    mov eax,DWORD PTR [esi]
    push eax
    push INFINITE
    push eax ; push thread handle twice for WaitForSingleObject and CloseHandle
    call WaitForSingleObject
    call CloseHandle

    ; Set SW_Exit, ThreadRunning, Playing and CurrentSong to zero
    xor eax,eax
    mov DWORD PTR [esi+SW_EXIT],eax

    ret
SIDClose ENDP

IFDEF SID_EXTRAS

; ESI must contain OFFSET hThread
WaitSemaphore:
    invoke WaitForSingleObject, [esi], 5
    xor eax ,eax
    inc eax                ; Set the EAX register to 1.       
 
    xchg eax, [esi+SEMAPHORE] ; Atomically swap the EAX register with
                              ; the lock variable.
                              ; This will always store 1 to the lock, leaving
                              ; previous value in the EAX register.
 
    test eax, eax       ; Test EAX with itself. Among other things, this will
                        ; set the processor's Zero Flag if EAX is 0.
                        ; If EAX is 0, then the lock was unlocked and
                        ; we just locked it.
                        ; Otherwise, EAX is 1 and we didn't acquire the lock.
                        
    jnz WaitSemaphore   ; Jump back to the MOV instruction if the Zero Flag is
                        ; not set; the lock was previously locked, and so
                        ; we need to spin until it becomes unlocked.
    ret

; ESI must contain OFFSET hThread
RelSemaphore:
    xor eax, eax                ; Set the EAX register to 0.
    xchg eax, [esi+SEMAPHORE]   ; Atomically swap the EAX register with
                                ; the lock variable.
    ret

SIDPlay PROC uses ESI

    call hThreadESI

    ; Restart sound output
    push waveOutWrite
    call waveOutCall

    inc BYTE PTR [esi+PLAYING]

    ret
SIDPlay ENDP

SIDStop PROC uses ESI

    call hThreadESI

    ; We must wait for the semaphore to be nonsignaled before
    ; proceeding to prevent the playing thread from messing up
    ; the sound output (by calling GenSamples() more than once
    ; at the same time etc)
    call WaitSemaphore

    ; Stop sound output
    call waveOutStop

    cld ; clear the direction flag just in case

    ; Reset the emulation
    call c64Init

    ; Reset the FFT input array (eax is already zero)
    lea edi, [esi+REALIN]
    mov ecx, FFT_SIZE
    rep stosd
    
    mov DWORD PTR [esi+FILLBLOCK], ecx ; ecx = 0 after rep stosd above
    mov BYTE PTR [esi+PLAYING], cl

    push WORD PTR [esi+CURRENTSONG]
    push WORD PTR [esi-INIT_ADDR]
    call cpuJSR

    ; Prefill the sound buffers
    .REPEAT
        invoke GenSamples
    .UNTIL DWORD PTR [esi+FILLBLOCK] == 0

    call RelSemaphore

    ret
SIDStop ENDP

SIDPause PROC uses ESI
    call hThreadESI
    push DWORD PTR [esi+HWAVEOUT]
    call waveOutPause
    ret
SIDPause ENDP

SIDResume PROC uses ESI
    call hThreadESI
    push DWORD PTR [esi+HWAVEOUT]
    call waveOutRestart
    ret
SIDResume ENDP

SIDChangeSong PROC uses ESI subsong:BYTE

    call hThreadESI

    ; Don't do anything if the thread isn't running
    .IF BYTE PTR [esi+THREADRUNNING]
        mov al,subsong

        ; Check the song is inside bounds
        .IF al < BYTE PTR [esi-NUM_SONGS]
            
            mov BYTE PTR [esi+CURRENTSONG],al

            ; Hijack subsong var to store the playing flag before this call
            mov al,BYTE PTR [esi+PLAYING]
            mov subsong,al
            
            invoke SIDStop
            
            ; subsong is playing flag
            .IF subsong

                ; Restart sound output
                call SIDPlay
            .ENDIF
        .ENDIF
   .ENDIF

    ret
SIDChangeSong ENDP

SIDGetFFTData PROC uses ESI pFFT:PTR REAL4
    call hThreadESI
    call WaitSemaphore
    invoke AmplitudeSpectrum, ADDR REAL4 PTR [esi+REALIN], pFFT
    call RelSemaphore
    ret
SIDGetFFTData ENDP

SIDGetProps PROC uses ESI EDI pSIDProps:PTR props
    mov esi,OFFSET sid_props
    mov edi,pSIDProps
    mov ecx,SIZEOF sid_props
    rep movsb
    ret
SIDGetProps ENDP

ENDIF ; SID_EXTRAS

END StartLabel
