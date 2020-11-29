Strict

Framework pub.win32
Import brl.system
Import brl.math

Import "sidsample.o"
Import "..\..\lib\libtitchysid_extras.a"

Include "titchysid.bmx"

Extern "win32"
    Function EndDialog:Int(hDlg,nResult)
    Function GetDlgItem:Int(hDlg, hWnd)
    Function ReleaseDC:Int(hWnd, hDC)
    Function OpenMutexA:Int(dwDesiredAccess, bInheritHandle, lpName:Byte Ptr)
    Function CreateMutexA:Int(lpMutexAttributes, bInitialOwner, lpName:Byte Ptr)
    Function DialogBoxParamA:Int(hinstance, lpTemplateName:Byte Ptr, hWndParent, lpDialogFunc:Byte Ptr, dwInitParam)
    Function SetDIBitsToDevice:Int(hdc, XDest, YDest, dwWidth, dwHeight, XSrc, YSrc, uStartScan, cScanLines, lpvBits:Byte Ptr, lpbmi:Byte Ptr, fuColorUse)
    Function timeSetEvent:Int(uDelay, uResolution, lpTimeProc:Byte Ptr, dwUser, fuEvent)
    Function timeKillEvent:Int(uTimerID)
EndExtern

Const MUTEX_ALL_ACCESS   = $1F0001
Const HTCAPTION          = 2
Const TIME_PERIODIC      = 1

Const IDI_ICON           = 101
Const IDD_SID_PLAYER_DLG = 102
Const IDR_MUSIC          = 103
Const IDC_EXIT           = 1001
Const IDC_INFO_LABELS    = 1002
Const IDC_INFO           = 1003
Const IDC_OPEN           = 1004
Const IDC_NEXT           = 1005
Const IDC_PREVIOUS       = 1006
Const IDC_PAUSE_RESUME   = 1007
Const IDC_STOP           = 1008
Const IDC_PLAY           = 1009
Const IDC_SONG_NUM       = 1010
Const IDC_SPEC           = 1011

Const SPECWIDTH          = 368 ' display width
Const SPECHEIGHT         = 127 ' height (changing requires palette adjustments too)
Const BANDS              = 28  ' number of equalizer bars

Const AppName:String     = "TITCHYSID_PLAYER_DEMO_BLITZMAX"
Const PauseText:String   = "Pause"
Const ResumeText:String  = "Resume"

Type RGBQuad
    Field rgbBlue:Byte
    Field rgbGreen:Byte
    Field rgbRed:Byte
    Field rgbReserved:Byte
End Type

Global g_hInst
Global g_hWnd
Global sid_props:props = New props
Global g_subsong:Byte
Global g_running:Byte
Global g_paused:Byte = 0

Global buffer:String

Global specwin
Global mmtimer
Global bmiHeader:BITMAPINFOHEADER = New BITMAPINFOHEADER
Global bmiColours:RGBQUAD[256]
Global specbuf:Byte[SPECWIDTH * SPECHEIGHT]

Global fft:Float[1024]

Global BitmapInfo256Buffer:Byte Ptr

Function HexPad$(val:Long,digits=8)
    Local buf:Short[digits]
    
    For Local k = digits - 1 To 0 Step -1
        Local n = (val & 15) + Asc("0")
        If n > Asc("9") n = n + (Asc("A") - Asc("9") - 1)
        buf[k] = n
        val:Shr 4
    Next
    
    Return String.FromShorts(buf, digits)
End Function

Function OpenSID()
    Local memory:TBank
    Local filebuffer:Byte Ptr
    Local length
	Local filter:String
	Local filename:String

    filter$="SID Files:sid"
    filename$=RequestFile("Choose SID File", filter$)

    If filename$
        memory = LoadBank(filename$)
        length = memory.Size()
        filebuffer = LockBank(memory)

        ' Start the SID playing 
        SIDOpen(filebuffer, length, SID_MEMORY, SID_DEFAULT, 0)
        GetProps(sid_props)
        
		g_paused = 0;
        g_running = 1
        g_subsong = sid_props.default_song
        UpdateSIDInfo()
        
        UnlockBank(memory)
    End If

End Function

Function UpdateSIDInfo()
    Local blocks

    ' Display the current sub song
    SetWindowTextA(GetDlgItem(g_hWnd, IDC_SONG_NUM), String.FromInt(g_subsong))

    blocks = sid_props.data_size / 256
    If sid_props.data_size Mod 256 > 0 blocks = blocks + 1

    buffer = "$" + HexPad(sid_props.load_addr, 4) + Chr(10) + "$" + HexPad(sid_props.init_addr, 4) + ..
                        Chr(10) + "$" + HexPad(sid_props.play_addr, 4) + Chr(10) + ..
                        String.FromInt(sid_props.data_size) + ..
                        " bytes (" + String.FromInt(blocks) + " blocks)" + Chr(10) + ..
                        String.FromInt(sid_props.num_songs) + Chr(10) + ..
                        String.FromInt(sid_props.default_song) + Chr(10) + ..
                        sid_props.sid_name + Chr(10) + ..
                        sid_props.author + Chr(10) + ..
                        sid_props.copyright

    ' Display the SID file properties
    SetWindowTextA(GetDlgItem(g_hWnd, IDC_INFO), buffer)

End Function

Function drawBar(x, y, height)
    For Local i = 0 To Height - 1
        For Local j = 0 To SPECWIDTH / BANDS - 3
            specbuf[((y + i) * SPECWIDTH + x * Int(SPECWIDTH / BANDS)) + (j + 3)] = y + 1
        Next
    Next
End Function

' update the spectrum display - the interesting bit :)
Function UpdateSpectrum() '(uTimerID, uMsg, dwUser, dw1, dw2) "Win32" NoDebug
    Local dc
    Local x, y, y1 
    Local b0 = 0
    Local sum:Float
    Local sc
    Local b1

    MemClear(specbuf, SPECWIDTH * SPECHEIGHT) ' Clear specbuf

    SIDGetFFTData(fft)

    ' Only update if we're not paused and running
    If Not g_paused And g_running
        For x = 0 To BANDS - 1
            sum=0
            b1= 2 ^ Float((x * 10.0) / (BANDS - 1))
            If (b1 > 1023) b1 = 1023
            If (b1 <= b0) b1 = b0 + 1 ' make sure it uses at least 1 FFT bin
            sc = 10 + (b1 - b0)
            For b0 = b0 To b1 - 1
                sum = sum + fft[1 + b0]
            Next
            y = (Sqr(sum / Log10(sc)) * 2.5 * SPECHEIGHT) ' scale it
            If (y > (SPECHEIGHT - 4)) y = SPECHEIGHT - 4 ' cap it
            For b1 = 0 To y - 1 Step 5
                drawBar(x, b1, 4) ' draw bar
            Next
        Next
    End If

    ' update the display
    dc = GetDC(specwin)
    SetDIBitsToDevice(dc, 0, 0, SPECWIDTH, SPECHEIGHT, 0, 0, 0, SPECHEIGHT, specbuf, BitmapInfo256Buffer, 0)
    ReleaseDC(specwin, dc)
    
End Function

Function DlgProc:Int(hWnd, uMsg, wParam, lParam) "Win32"
    Local pandr:String
    Local cstr:Byte Ptr
	Local a:Int
	Local memptr:Byte Ptr

    Select uMsg
        Case WM_INITDIALOG
            cstr = AppName.ToCString()
        
            ' Check this is the only instance of the app
            If OpenMutexA(MUTEX_ALL_ACCESS, False, cstr) = 0
        
                CreateMutexA(0, False, cstr)

                SendMessageA(hWnd, WM_SETICON, 0, LoadIconA(g_hInst, Byte Ptr(IDI_ICON)))
            
                g_hWnd = hWnd
                specwin = GetDlgItem(hWnd, IDC_SPEC)
            
                ' Start the SID music playing from our resource
                SIDOpen(Byte Ptr(IDR_MUSIC), 0, SID_RESOURCE, SID_DEFAULT, 0)
                GetProps(sid_props)
                
                g_running = 1
                g_subsong = sid_props.default_song
                UpdateSIDInfo()

                ' create bitmap to draw spectrum in (8 bit for easy updating)
                bmiHeader.biSize = SizeOf(BITMAPINFOHEADER)
                bmiHeader.biWidth = SPECWIDTH
                bmiHeader.biHeight = SPECHEIGHT ' upside down (line 0=bottom)
                bmiHeader.biPlanes = 1
                bmiHeader.biBitCount = 8
                bmiHeader.biClrUsed = 256
                bmiHeader.biClrImportant = 256

				' Create each element of the RGBQUAD array
				For a = 0 To 255
					bmiColours[a] = New RGBQUAD
				Next

                ' setup palette
                For a = 1 To 127
                    bmiColours[a].rgbGreen = 256 - 2 * a
                    bmiColours[a].rgbRed = 2 * a
                Next
                
                For a = 0 To 31
                    bmiColours[128 + a].rgbBlue = 8 * a
                    bmiColours[128 + 32 + a].rgbBlue = 255
                    bmiColours[128 + 32 + a].rgbRed = 8 * a
                    bmiColours[128 + 64 + a].rgbRed = 255
                    bmiColours[128 + 64 + a].rgbBlue = 8 * (31 - a)
                    bmiColours[128 + 64 + a].rgbGreen = 8 * a
                    bmiColours[128 + 96 + a].rgbRed = 255
                    bmiColours[128 + 96 + a].rgbGreen = 255
                    bmiColours[128 + 96 + a].rgbBlue = 8 * a
                Next
				
				' Now we need to create a flat buffer holding the bitmap header followed by the RGBQUAD array
				' This gives us a BITMAPINFO256 structure to pass to the SetDIBitsToDevice Win32 API
				BitmapInfo256Buffer = MemAlloc(SizeOf(BITMAPINFOHEADER) + (SizeOf(RGBQUAD) * 256))

				MemCopy(BitmapInfo256Buffer, Varptr(bmiHeader.biSize), SizeOf(BITMAPINFOHEADER))
				
				memptr = BitmapInfo256Buffer + SizeOf(BITMAPINFOHEADER)
				
				For a = 0 To 255
					memptr[0] = bmiColours[a].rgbBlue
					memptr[1] = bmiColours[a].rgbGreen
					memptr[2] = bmiColours[a].rgbRed
					' We don't need to copy the rgbReserved byte as it's zero
					
					memptr = memptr + SizeOf(RGBQUAD)
				Next

                ' setup update timer (50hz)
                mmtimer = timeSetEvent(20, 5, UpdateSpectrum, 0, TIME_PERIODIC)

            ' Another instance of the app is already running, so exit
            Else
                SendMessageA(hWnd, WM_CLOSE, Null, Null)
            End If
            
            MemFree(cstr)

        Case WM_COMMAND
            Select wParam
                Case IDC_OPEN
                    ' Open a SID file
                    OpenSID()
					SetWindowTextA(GetDlgItem(hWnd, IDC_PAUSE_RESUME), PauseText)

                Case IDC_PLAY
                    ' Start the SID music playing
                    If Not g_paused And Not g_running
                        SIDPlay()
                        g_running = 1
                    End If

                Case IDC_STOP
                    ' Stop the SID music playing
                    If Not g_paused And g_running
                        SIDStop()
                        g_running = 0
                    End If

                Case IDC_NEXT
                    If Not g_paused        
                        ' Go to the next sub song
                        If g_subsong < sid_props.num_songs
                            g_subsong = g_subsong + 1
                            SIDChangeSong(g_subsong - 1)
                            UpdateSIDInfo()
                        End If
                    End If

                Case IDC_PREVIOUS
                    If Not g_paused
                        ' Go to the previous sub song
                        If (g_subsong > 1)
                            g_subsong = g_subsong - 1
                            SIDChangeSong(g_subsong - 1)
                            UpdateSIDInfo()
                        End If
                    End If

                Case IDC_PAUSE_RESUME
                    ' Pause or resume playback
                    If g_running
                        g_paused = Not g_paused
                        
                        If g_paused
                            SIDPause()
                            pandr = ResumeText
                        Else
                            SIDResume()
                            pandr = PauseText
                        End If
                        
                        cstr = pandr.ToCString()
                        SetWindowTextA(GetDlgItem(hWnd, IDC_PAUSE_RESUME), pandr)
                        MemFree(cstr)
                    End If

                Case IDC_EXIT
                    SendMessageA(hWnd, WM_CLOSE, Null, Null)
            EndSelect

        ' Use the HTCAPTION trick to allow dragging of the window
        Case WM_LBUTTONDOWN
            SendMessageA(hWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam)

        Case WM_CLOSE
        	' Kill the spectrum timer
			timeKillEvent(mmtimer)

            ' Close the SID library
            SIDClose()

			' Free up the BITMAPINFO256 memory buffer used for the spectrum
			MemFree(BitmapInfo256Buffer)

            EndDialog(hWnd, 0)

        Default
            Return False
    EndSelect

    Return True
End Function

g_hInst = GetModuleHandleA(Null)

DialogBoxParamA(g_hInst, Byte Ptr(IDD_SID_PLAYER_DLG), 0, DlgProc, 0)
