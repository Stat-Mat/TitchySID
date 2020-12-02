.486
.MODEL FLAT, STDCALL
OPTION CASEMAP :NONE   ; case sensitive

include \masm32\include\windows.inc 
include \masm32\include\comdlg32.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\winmm.inc
include \masm32\include\gdi32.inc
include \masm32\include\Fpu.inc

includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\winmm.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\Fpu.lib

include resource.inc
include ..\titchysid.inc
includelib ..\lib\titchysid_extras.lib

; Forward declarations of functions included in this code module
WndProc            PROTO :DWORD,:DWORD,:DWORD,:DWORD
OpenSID            PROTO
UpdateSIDInfo      PROTO
UpdateSpectrum     PROTO :UINT,:UINT,:DWORD,:DWORD,:DWORD
SpectrumWindowProc PROTO :HWND,:DWORD,:WPARAM,:LPARAM

.CONST

MUTEX_ALL_ACCESS equ STANDARD_RIGHTS_REQUIRED + SYNCHRONIZE + MUTANT_QUERY_STATE

SPECWIDTH        equ 368 ; display width
SPECHEIGHT       equ 127 ; height (changing requires palette adjustments too)
BANDS            equ 28  ; number of equalizer bars

.DATA

AppName          db "TITCHYSID_PLAYER_DEMO_ASM",0

; Open file dialog stuff
OpenTitle        db "Choose SID File",0
FiltString       db "SID Files (*.sid)",0,"*.sid",0,0,0

szSubSong        db "%d",0
szSIDProps       db "$%04X",10,"$%04X",10,"$%04X",10
                 db "%d bytes (%d blocks)",10,"%d",10,"%d",10
                 db "%s",10,"%s",10,"%s",0

szPause          db "Pause",0
szResume         db "Resume",0

.DATA?

g_hInst HINSTANCE ?
g_hWnd HWND ?
g_Spec_hWnd HWND ?

sid_props props {}

g_subsong BYTE ?
g_running BYTE ?
g_paused BYTE ?

buffer BYTE 512 dup (?)

fft REAL4 1024 dup (?)

bh_data BYTE 2000 dup (?)
pal DWORD ?

specdc HDC ?
specbmp HBITMAP ?
oldspecbmp HBITMAP ?
specbuf DWORD ?
mmtimer DWORD ?

.DATA

ftTwoPointFive REAL4 2.5

.CODE

start:
    invoke GetModuleHandle,NULL
    mov g_hInst,eax

    invoke DialogBoxParam, g_hInst, IDD_SID_PLAYER_DLG, 0, ADDR WndProc, 0

    invoke ExitProcess,0

WndProc PROC USES esi hWnd:HWND, message:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL pnr :DWORD

    .IF message == WM_INITDIALOG
        invoke OpenMutex,MUTEX_ALL_ACCESS,FALSE,ADDR AppName

        ; Check this is the only instance of the app
        .IF eax == 0
            invoke CreateMutex,0,FALSE,ADDR AppName

            mov eax,hWnd
            mov g_hWnd,eax

            ; Load icon from the resources, and set it on the title bar
            invoke LoadIcon, g_hInst, IDI_ICON
            invoke SendMessage, hWnd, WM_SETICON, 0, eax
            
            ; Get the window handle of the spectrum control for use later
            invoke GetDlgItem,hWnd,IDC_SPEC
            mov g_Spec_hWnd,eax
      
            ; Start the SID music playing from our resource
            invoke SIDOpen, IDR_MUSIC, 0, SID_RESOURCE, SID_DEFAULT, 0
            invoke SIDGetProps, ADDR sid_props

            mov g_running, 1
            mov al, sid_props.default_song
            mov g_subsong, al
            call UpdateSIDInfo

            ; create bitmap to draw spectrum in (8 bit for easy updating)
            mov esi,OFFSET bh_data
            ASSUME esi: PTR BITMAPINFOHEADER
            mov [esi].biSize,SIZEOF(BITMAPINFOHEADER)
            mov [esi].biWidth,SPECWIDTH
            mov [esi].biHeight,SPECHEIGHT ; upside down (line 0=bottom)
            mov [esi].biPlanes,1
            mov [esi].biBitCount,8
            mov [esi].biClrUsed,256
            mov [esi].biClrImportant,256
            ASSUME esi: NOTHING

            ; setup palette
            add esi,SIZEOF(BITMAPINFOHEADER)
            mov pal,esi
            ASSUME esi: PTR RGBQUAD
            xor ecx,ecx
            inc ecx

            .WHILE ecx < 128
                mov dx,cx
                shl dx,1 ; edx*2
                mov ax,256
                sub ax,dx
                mov [esi+4].rgbGreen,al
                mov [esi+4].rgbRed,dl
                add esi,SIZEOF RGBQUAD
                inc ecx
            .ENDW
    
            xor ecx,ecx
            mov esi,pal
            
            .WHILE ecx < 32
                mov eax,ecx
                add eax,128
                shl eax,2
                push eax
                mov edx,ecx
                shl edx,3 ; edx*8
                
                mov [esi+eax].rgbBlue,dl
                
                add eax,128
                mov [esi+eax].rgbBlue,255
                mov [esi+eax].rgbRed,dl
                
                add eax,256
                mov [esi+eax].rgbRed,255
                mov [esi+eax].rgbGreen,dl
                
                add eax,384
                mov [esi+eax].rgbRed,255
                mov [esi+eax].rgbGreen,255
                mov [esi+eax].rgbBlue,dl
                
                mov edx,31
                sub edx,ecx
                shl edx,3
                pop eax
                add eax,256
                mov [esi+eax].rgbBlue,dl
                
                inc ecx
            .ENDW
    
            ASSUME esi: NOTHING

            ; create the bitmap
            invoke CreateDIBSection,0,ADDR bh_data,DIB_RGB_COLORS,ADDR specbuf,0,0
            mov specbmp,eax
            invoke CreateCompatibleDC,0
            mov specdc,eax
            invoke SelectObject,specdc,specbmp
            mov oldspecbmp,eax

            ; setup update timer (50hz)
            invoke timeSetEvent,20,5,ADDR UpdateSpectrum,NULL,TIME_PERIODIC
            mov mmtimer,eax

        ; Another instance of the app is already running, so exit
        .ELSE           
            invoke SendMessage, hWnd, WM_CLOSE, NULL, NULL
        .ENDIF
         
    .ELSEIF message == WM_COMMAND

        .IF wParam == IDC_OPEN

            ; Open a SID file
            call OpenSID
            
            invoke GetDlgItem, hWnd, IDC_PAUSE_RESUME
            invoke SetWindowText, eax, OFFSET szPause

        .ELSEIF wParam == IDC_PLAY
                
            ; Start the SID music playing
            .IF !g_paused && !g_running
                call SIDPlay
                mov g_running, 1
            .ENDIF

        .ELSEIF wParam == IDC_STOP

            ; Stop the SID music playing
            .IF !g_paused && g_running
                call SIDStop
                mov g_running, 0
            .ENDIF

        .ELSEIF wParam == IDC_NEXT

            .IF !g_paused

                mov al, g_subsong
    
                ; Go to the next sub song
                .IF al < sid_props.num_songs
                    inc g_subsong
                    invoke SIDChangeSong, al

                    call UpdateSIDInfo
                .ENDIF
            .ENDIF

        .ELSEIF wParam == IDC_PREVIOUS

            .IF !g_paused

                ; Go to the previous sub song   
                .IF g_subsong > 1
                    mov al, g_subsong
                    sub al,2
                    dec g_subsong
                    invoke SIDChangeSong, al

                    call UpdateSIDInfo
                .ENDIF
            .ENDIF

        .ELSEIF wParam == IDC_PAUSE_RESUME

            ; Pause or resume playback
            .IF g_running
                not g_paused

                .IF g_paused
                      call SIDPause
                      mov pnr,OFFSET szResume
                .ELSE
                      call SIDResume
                      mov pnr,OFFSET szPause
                .ENDIF

                invoke GetDlgItem, hWnd, IDC_PAUSE_RESUME
                invoke SetWindowText, eax, pnr
            .ENDIF

        .ELSEIF wParam == IDC_EXIT

             invoke SendMessage, hWnd, WM_CLOSE, NULL, NULL

        .ENDIF

    ; Use the HTCAPTION trick to allow dragging of the window
    .ELSEIF message == WM_LBUTTONDOWN
        invoke SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

    .ELSEIF message == WM_CLOSE
        .IF mmtimer
            invoke timeKillEvent,mmtimer
        .ENDIF

        ; Free up the spectrum DC and bitmap
        .IF specdc
            .IF specbmp
                invoke SelectObject,specdc,oldspecbmp
                invoke DeleteObject,specbmp
            .ENDIF

            invoke DeleteDC,specdc
        .ENDIF
        
        ; Close the SID library
        call SIDClose

        invoke EndDialog, hWnd, 0
    
    .ELSE
        xor eax,eax
        ret

    .ENDIF
    
    xor eax,eax 
    ret
WndProc ENDP

OpenSID PROC uses EDI
  
    LOCAL FilePtr :DWORD
    LOCAL FileSize :DWORD
    LOCAL FileName[MAX_PATH] :BYTE
    LOCAL hFile :HANDLE
    LOCAL bytesread :DWORD
    LOCAL attr :WIN32_FILE_ATTRIBUTE_DATA
    LOCAL ofn :OPENFILENAME

    ; Our own memsets
    xor eax, eax
    lea edi, FileName
    mov ecx, MAX_PATH
    rep stosb

    lea edi, ofn
    mov ecx, SIZEOF OPENFILENAME
    rep stosb

    mov ofn.lStructSize, SIZEOF OPENFILENAME
    mov eax, g_hWnd
    mov ofn.hwndOwner, eax
    mov ofn.lpstrFilter, OFFSET FiltString
    lea eax,FileName
    mov ofn.lpstrFile, eax
    mov ofn.nMaxFile, MAX_PATH-1
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_NONETWORKBUTTON or \
              OFN_PATHMUSTEXIST or OFN_LONGNAMES or \
              OFN_EXPLORER or OFN_HIDEREADONLY
    mov ofn.lpstrTitle, OFFSET OpenTitle
  
    invoke GetOpenFileName, ADDR ofn

    .IF eax
        invoke GetFileAttributesEx, ADDR FileName, 0, ADDR attr

        invoke GlobalAlloc, GPTR, attr.nFileSizeLow
        mov FilePtr, eax

        invoke CreateFile, ADDR FileName, GENERIC_READ, FILE_SHARE_READ,
                          NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
 
        mov hFile,eax

        invoke ReadFile, hFile, FilePtr, attr.nFileSizeLow, ADDR bytesread, NULL
        invoke CloseHandle, hFile
    
        mov eax, attr.nFileSizeLow
        mov FileSize, eax
    
        ; Start the SID playing 
        invoke SIDOpen, FilePtr, FileSize, SID_MEMORY, SID_DEFAULT, 0
        invoke SIDGetProps, ADDR sid_props

        invoke GlobalFree, FilePtr

        mov g_paused, 0
        mov g_running, 1
        mov al, sid_props.default_song
        mov g_subsong, al
        call UpdateSIDInfo
    .ENDIF

    ret
OpenSID ENDP

UpdateSIDInfo PROC
  
    ; Must convert to a DWORD for wsprintf below
    movzx eax, g_subsong
  
    ; Display the current sub song
    invoke wsprintf, ADDR buffer, ADDR szSubSong, eax
    invoke GetDlgItem, g_hWnd, IDC_SONG_NUM
    invoke SetWindowText, eax, ADDR buffer

    ; All this faffing because wsprintf expects DWORD length params...
    push OFFSET sid_props.copyright
    push OFFSET sid_props.author
    push OFFSET sid_props.sid_name
    movzx eax, sid_props.default_song
    push eax
    movzx eax, sid_props.num_songs
    push eax
    movzx eax, sid_props.data_size

    mov ecx, 256
    xor edx,edx
    div ecx

    ; There's a remainder, so round up the block count
    .IF edx
        inc eax
    .ENDIF

    push eax ; size in blocks

    movzx eax, sid_props.data_size
    push eax
    movzx eax, sid_props.play_addr
    push eax
    movzx eax, sid_props.init_addr
    push eax
    movzx eax, sid_props.load_addr
    push eax
    push OFFSET szSIDProps
    push OFFSET buffer

    call wsprintf

    ; Must update the stack pointer ourselves because we used call
    ; instead of invoke, as wprintf uses C calling convention,
    ; and there'll be a crash otherwise.
    ; (We add 12*4 because there were 12 params pushed above)

    add esp,(12*4)

    ; Display the SID file properties
    invoke GetDlgItem, g_hWnd, IDC_INFO
    invoke SetWindowText, eax, ADDR buffer

    ret
UpdateSIDInfo ENDP

; update the spectrum display - the interesting bit :)
UpdateSpectrum PROC uses EDI uID:UINT, uMsg:UINT, dwUser:DWORD, dw1:DWORD, dw2:DWORD
    LOCAL dc :HDC
    LOCAL x :SDWORD
    LOCAL y :SDWORD
    LOCAL y1 :SDWORD
    LOCAL b0 :SDWORD
    LOCAL sum :REAL4
    LOCAL sc :SDWORD
    LOCAL b1 :SDWORD

    cld ; clear the direction flag just in case
    
    ; Initialise fft array
    mov edi,OFFSET fft
    mov ecx,1024
    xor eax,eax
    rep stosd
    
    ; Initialise specbuf
    mov edi,specbuf
    mov eax,SPECWIDTH
    mov ecx,SPECHEIGHT
    mul ecx
    mov ecx,eax
    xor eax,eax
    rep stosb

    invoke SIDGetFFTData, ADDR fft

    .IF !g_paused && g_running
        mov x,0
        mov b0,0
        
        .WHILE x < BANDS
            
            finit
            mov eax,x
            mov ecx,10
            mul ecx
            mov ecx,BANDS
            dec ecx
            
            mov sum,eax
            fild sum
            mov sum,ecx
            fild sum
            fdiv
            
            invoke FpuXexpY, 2, 0, 0, SRC1_DIMM or SRC2_FPU or DEST_FPU
            fistp b1

            mov edx,1023
            .IF b1 > edx
                mov b1,edx
            .ENDIF
            
            mov eax,b0
            .IF b1 <= eax
                inc eax
                mov b1,eax
            .ENDIF
            
            mov eax,b1
            sub eax,b0
            add eax,10
            mov sc,eax

            mov edi,OFFSET fft
            mov eax,b0
            inc eax
            shl eax,2
            add edi,eax

            fldz
            mov ecx,b1
            
            .WHILE b0 < ecx
                fld REAL4 PTR [edi]
                fadd
                add edi,SIZEOF REAL4
                inc b0
            .ENDW

            invoke FpuLogx, ADDR sc, 0, SRC1_DMEM or DEST_FPU
            fdiv
            fsqrt
            fld ftTwoPointFive
            fmul
            mov b1,SPECHEIGHT
            fild b1
            fmul
            mov b1,4
            fild b1
            fsub
            fistp y
            
            .IF y > SPECHEIGHT
                mov y,SPECHEIGHT
            .ENDIF
            
            xor ecx,ecx
            mov b1,ecx
           
            .WHILE ecx < y
                
                ; y*SPECWIDTH
                mov eax,ecx
                mov ecx,SPECWIDTH
                mul ecx
                mov sc,eax
                
                ; x*(SPECWIDTH/bands)
                mov eax,SPECWIDTH
                mov ecx,BANDS
                xor edx,edx
                div ecx
                mov ecx,x
                mul ecx
                
                ; y*SPECWIDTH + (x*(SPECWIDTH/bands)) + 3
                add sc,eax
                add sc,3
                
                ; (SPECWIDTH/bands)-2
                mov eax,SPECWIDTH
                mov ecx,BANDS
                xor edx,edx
                div ecx
                sub eax,2
                mov y1,eax
                
                xor edx,edx
                
                .WHILE edx < 4
                    push edx
                    mov edi,specbuf
                    add edi,sc
                    mov eax,SPECWIDTH
                    mov ecx,edx
                    mul ecx
                    add edi,eax
                    mov eax,b1
                    inc eax
                    mov ecx,y1
                    rep stosb
                    pop edx
                    inc edx
                .ENDW

                add b1,5
                mov ecx,b1
            .ENDW
            
            inc x
        .ENDW
    .ENDIF

    ; update the display
    invoke GetDC,g_Spec_hWnd
    mov dc,eax
    invoke BitBlt,eax,0,0,SPECWIDTH,SPECHEIGHT,specdc,0,0,SRCCOPY
    invoke ReleaseDC,g_Spec_hWnd,dc

    ret
UpdateSpectrum ENDP

END start
