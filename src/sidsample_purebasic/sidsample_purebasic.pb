IncludeFile  "titchysid.pbi"

Import "sidsample.res" : EndImport

#IDI_ICON           = 101
#IDD_SID_PLAYER_DLG = 102
#IDR_MUSIC          = 103
#IDC_EXIT           = 1001
#IDC_INFO_LABELS    = 1002
#IDC_INFO           = 1003
#IDC_OPEN           = 1004
#IDC_NEXT           = 1005
#IDC_PREVIOUS       = 1006
#IDC_PAUSE_RESUME   = 1007
#IDC_STOP           = 1008
#IDC_PLAY           = 1009
#IDC_SONG_NUM       = 1010
#IDC_SPEC           = 1011

#SPECWIDTH          = 368 ; display width
#SPECHEIGHT         = 127 ; height (changing requires palette adjustments too)
#BANDS              = 28  ; number of equalizer bars

#APP_NAME           = "TITCHYSID_PLAYER_DEMO_PUREBASIC"
#PAUSE_TEXT         = "Pause"
#RESUME_TEXT        = "Resume"

Structure BITMAPINFO256
    bmiHeader.BITMAPINFOHEADER
    bmiColors.RGBQUAD[256]
EndStructure

Global g_hInst.i
Global g_hWnd.i
Global sid_props.props
Global g_subsong.c
Global g_running.c
Global g_paused.c = 0

Global buffer.s

Global specwin.i
Global mmtimer.i
Global bmi.BITMAPINFO256
Global Dim specbuf.b(#SPECWIDTH * #SPECHEIGHT)

Procedure UpdateSIDInfo()
    blocks.i

    ; Display the current sub song
    SetWindowText_(GetDlgItem_(g_hWnd, #IDC_SONG_NUM), StrU(g_subsong))

    blocks = sid_props\data_size / 256
    If sid_props\data_size % 256 > 0 : blocks = blocks + 1 : EndIf

    buffer = "$" + Hex(sid_props\load_addr) + Chr(10) +
             "$" + Hex(sid_props\init_addr) + Chr(10) +
             "$" + Hex(sid_props\play_addr) + Chr(10) +
             StrU(sid_props\data_size) + " bytes (" + StrU(blocks) + " blocks)" + Chr(10) +
             StrU(sid_props\num_songs) + Chr(10) +
             StrU(sid_props\default_song) + Chr(10) +
             PeekS(@sid_props\sid_name, -1, #PB_Ascii) + Chr(10) +
             PeekS(@sid_props\author, -1, #PB_Ascii) + Chr(10) +
             PeekS(@sid_props\copyright, -1, #PB_Ascii)

    ; Display the SID file properties
    SetWindowText_(GetDlgItem_(g_hWnd, #IDC_INFO), buffer)
EndProcedure

Procedure OpenSID()
    FileName$ = OpenFileRequester("Choose SID File","","SID Files (*.sid)|*.sid",0)
    
    If FileName$
        If ReadFile(0, FileName$)
            length = Lof(0)
            *FilePtr = AllocateMemory(length)
            
            If *FilePtr
                ReadData(0, *FilePtr, length)

                ; Start the SID playing 
                SIDOpen(*FilePtr, length, #SID_MEMORY, #SID_DEFAULT, 0)
                SIDGetProps(@sid_props)

                g_paused = 0
                g_running = 1
                g_subsong = sid_props\default_song
                UpdateSIDInfo()
            EndIf
            
            CloseFile(0)
        EndIf
    EndIf
EndProcedure

Procedure drawBar(x.i, y.i, height.i)
    For i = 0 To Height - 1
        FillMemory(@specbuf((y + i) * #SPECWIDTH + x * Int(#SPECWIDTH / #BANDS)) + 3, #SPECWIDTH / #BANDS - 2, y + 1)
    Next
EndProcedure

; update the spectrum display - the interesting bit :)
Procedure UpdateSpectrum(uTimerID, uMsg, dwUser, dw1, dw2)
    dc.i
    x.i
    y.i
    b0.i = 0
    Dim fft.f(1024)
    
    sum.f
    sc.i
    b1.i

    FillMemory(@specbuf(), #SPECWIDTH * #SPECHEIGHT, 0) ; Clear specbuf
    
    SIDGetFFTData(@fft())

    ; Only update if we're not paused and running
    If (Not g_paused And g_running)
        For x = 0 To #BANDS - 1
            sum = 0
            b1 = Pow(2 ,(x * 10.0) / (#BANDS - 1))
            If (b1 > 1023): b1 = 1023 : EndIf
            If (b1 <= b0) : b1 = b0 + 1 : EndIf ; make sure it uses at least 1 FFT bin
            sc = 10 + (b1 - b0)
            For b0 = b0 To b1 - 1 : sum = sum + fft(1 + b0) : Next
            y = (Sqr(sum / Log10(sc)) * 2.5 * #SPECHEIGHT) ; scale it
            If (y > (#SPECHEIGHT - 4)) : y = #SPECHEIGHT - 4 : EndIf ; cap it
            For b1 = 0 To y - 1 Step 5
                drawBar(x, b1, 4); ; draw bar
            Next
        Next
    EndIf

    dc = GetDC_(specwin)
    SetDIBitsToDevice_(dc, 0, 0, #SPECWIDTH, #SPECHEIGHT, 0, 0, 0, #SPECHEIGHT, @specbuf(), @bmi, 0)
    ReleaseDC_(specwin, dc)    
EndProcedure

Procedure WndProc(hWnd, message, wParam, lParam)
  Select message
    Case #WM_INITDIALOG

        ; Check this is the only instance of the app
        If (OpenMutex_(#MUTEX_ALL_ACCESS, False, #APP_NAME) = 0)

            CreateMutex_(0, False, #APP_NAME)
            
            g_hWnd = hWnd                
            specwin = GetDlgItem_(hWnd, #IDC_SPEC)
            
            SendMessage_(hWnd, #WM_SETICON, 0, LoadIcon_(g_hInst, #IDI_ICON))
            
            ; Start the SID music playing from our resource
            SIDOpen(#IDR_MUSIC, 0, #SID_RESOURCE, #SID_DEFAULT, 0)
            SIDGetProps(@sid_props)
            
            g_running = 1
            g_subsong = sid_props\default_song
            UpdateSIDInfo()
            
            ; create bitmap to draw spectrum in (8 bit for easy updating)
            bmi\bmiHeader\biSize = SizeOf(BITMAPINFOHEADER)
            bmi\bmiHeader\biWidth = #SPECWIDTH
            bmi\bmiHeader\biHeight = #SPECHEIGHT ; upside down (line 0=bottom)
            bmi\bmiHeader\biPlanes = 1
            bmi\bmiHeader\biBitCount = 8
            bmi\bmiHeader\biClrUsed = 256
            bmi\bmiHeader\biClrImportant = 256

            ; setup palette
            For a = 1 To 127
                bmi\bmiColors[a]\rgbGreen = 256 - 2 * a
                bmi\bmiColors[a]\rgbRed = 2 * a
            Next

            For a = 0 To 31
                bmi\bmiColors[128 + a]\rgbBlue = 8 * a
                bmi\bmiColors[128 + 32 + a]\rgbBlue = 255
                bmi\bmiColors[128 + 32 + a]\rgbRed = 8 * a
                bmi\bmiColors[128 + 64 + a]\rgbRed = 255
                bmi\bmiColors[128 + 64 + a]\rgbBlue = 8 * (31 - a)
                bmi\bmiColors[128 + 64 + a]\rgbGreen = 8 * a
                bmi\bmiColors[128 + 96 + a]\rgbRed = 255
                bmi\bmiColors[128 + 96 + a]\rgbGreen = 255
                bmi\bmiColors[128 + 96 + a]\rgbBlue = 8 * a
            Next

            ; setup spectrum update timer (50hz)
            mmtimer = timeSetEvent_(20, 5, @UpdateSpectrum(), 0, #TIME_PERIODIC)
        Else
            SendMessage_(hWnd, #WM_CLOSE, NULL, NULL)
        EndIf

    Case #WM_COMMAND
        Select wParam
            Case #IDC_OPEN
                ; Open a SID file
              OpenSID()
              SetWindowText_(GetDlgItem_(hWnd, #IDC_PAUSE_RESUME), #PAUSE_TEXT)

            Case #IDC_PLAY
                ; Start the SID music playing
                If Not g_paused And Not g_running
                    SIDPlay()
                    g_running = 1
                EndIf

            Case #IDC_STOP
                ; Stop the SID music playing
                If Not g_paused And g_running
                    SIDStop()
                    g_running = 0
                EndIf

            Case #IDC_NEXT
                If Not g_paused
                    ; Go to the next sub song
                    If g_subsong < sid_props\num_songs
                        g_subsong = g_subsong + 1
                        SIDChangeSong(g_subsong - 1)
                        UpdateSIDInfo()
                    EndIf
                EndIf

            Case #IDC_PREVIOUS
              If Not g_paused
                  ; Go to the previous sub song
                  If g_subsong > 1
                      g_subsong = g_subsong - 1
                      SIDChangeSong(g_subsong - 1)
                      UpdateSIDInfo()
                  EndIf
              EndIf

            Case #IDC_PAUSE_RESUME
                ; Pause or resume playback
                If g_running
                    g_paused = ~g_paused

                    If g_paused
                        SIDPause()
                        pandr$ = #RESUME_TEXT
                    Else
                        SIDResume()
                        pandr$ = #PAUSE_TEXT
                    EndIf

                    SetWindowText_(GetDlgItem_(hWnd, #IDC_PAUSE_RESUME), pandr$)
                EndIf

            Case #IDC_EXIT
                SendMessage_(hWnd, #WM_CLOSE, NULL, NULL)
                
        EndSelect
      
        ; Use the HTCAPTION trick to allow dragging of the window
        Case #WM_LBUTTONDOWN
            SendMessage_(hWnd, #WM_NCLBUTTONDOWN, #HTCAPTION, lParam)

        Case #WM_CLOSE
        	; Kill the spectrum timer
			timeKillEvent_(mmtimer)
        
            ; Close the SID library
            SIDClose()

            EndDialog_(hWnd, 0)

        Default
            ProcedureReturn False
            
    EndSelect
  
    ProcedureReturn True 
EndProcedure

g_hInst = GetModuleHandle_(NULL)

DialogBoxParam_(g_hInst, #IDD_SID_PLAYER_DLG, 0, @WndProc(), 0)
