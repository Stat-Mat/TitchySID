#include once "windows.bi"
#include "win/commdlg.bi"
#include "win/mmsystem.bi"
#include "crt/math.bi"
#include "titchysid.bi"

#define IDI_ICON           101
#define IDD_SID_PLAYER_DLG 102
#define IDR_MUSIC          103
#define IDC_EXIT           1001
#define IDC_INFO_LABELS    1002
#define IDC_INFO           1003
#define IDC_OPEN           1004
#define IDC_NEXT           1005
#define IDC_PREVIOUS       1006
#define IDC_PAUSE_RESUME   1007
#define IDC_STOP           1008
#define IDC_PLAY           1009
#define IDC_SONG_NUM       1010
#define IDC_SPEC           1011

#define SPECWIDTH          368 ' display width
#define SPECHEIGHT         127 ' height (changing requires palette adjustments too)
#define BANDS              28  ' number of equalizer bars

Const APP_NAME           = "TITCHYSID_PLAYER_DEMO_FREEBASIC"
Const PAUSE_TEXT         = "Pause"
Const RESUME_TEXT        = "Resume"

Type BITMAPINFO256
    bmiHeader As BITMAPINFOHEADER
    bmiColors(256) As RGBQUAD
End Type

Dim Shared g_hInst As HINSTANCE = NULL
Dim Shared g_hWnd As HWND = NULL
Dim Shared sid_props As props
Dim Shared g_subsong As UByte
Dim Shared g_running As UByte
Dim Shared g_paused As UByte = 0

Dim Shared buffer As String

Dim Shared specwin As HWND
Dim Shared mmtimer As MMRESULT
Dim Shared bmi As BITMAPINFO256
Dim Shared specbuf(SPECWIDTH * SPECHEIGHT) As UByte

Sub UpdateSIDInfo()
    Dim blocks As Integer

    ' Display the current sub song
    SetWindowText(GetDlgItem(g_hWnd, IDC_SONG_NUM), Str(g_subsong))

    blocks = sid_props.data_size / 256
    If sid_props.data_size Mod 256 > 0 Then : blocks = blocks + 1 : End If

    buffer = "$" + Hex(sid_props.load_addr, 4) + Chr(10) + _
             "$" + Hex(sid_props.init_addr, 4) + Chr(10) + _
             "$" + Hex(sid_props.play_addr, 4) + Chr(10) + _
             Str(sid_props.data_size) + " bytes (" + Str(blocks) + " blocks)" + Chr(10) + _
             Str(sid_props.num_songs) + Chr(10) + _
             Str(sid_props.default_song) + Chr(10) + _
             sid_props.sid_name + Chr(10) + _
             sid_props.author + Chr(10) + _
             sid_props.copyright

    ' Display the SID file properties
    SetWindowText(GetDlgItem(g_hWnd, IDC_INFO), buffer)

End Sub

Sub OpenSID()

    Dim filename As String * MAX_PATH
    Dim filter As String = "SID Files (*.sid)" + Chr(0) + "*.sid" + Chr(0) + Chr(0)
    Dim ofn As OPENFILENAME
    Dim filenum As Integer
    Dim length As Integer
    Dim filebuffer As Byte Ptr

    ofn.lStructSize = sizeof(ofn)
    ofn.hwndOwner = g_hWnd
    ofn.lpstrFilter = Sadd(filter)
    ofn.lpstrFile = Sadd(filename)
    ofn.nMaxFile = MAX_PATH - 1
    ofn.Flags = OFN_FILEMUSTEXIST Or OFN_NONETWORKBUTTON Or OFN_PATHMUSTEXIST Or OFN_LONGNAMES Or OFN_EXPLORER
    ofn.lpstrTitle = @"Choose SID File"

    If GetOpenFileName(@ofn) <> 0 Then
        filenum = FreeFile
        Open filename for Binary as #filenum
        length = Lof(filenum)
        filebuffer = Allocate(length)
        Get #filenum,,*filebuffer,length
        Close #filenum

        ' Start the SID playing 
        SIDOpen(filebuffer, length, SID_MEMORY, SID_DEFAULT, 0)
        SIDGetProps(@sid_props)
        
        g_paused = 0
        g_running = 1
        g_subsong = sid_props.default_song
        UpdateSIDInfo()
        
        Deallocate(filebuffer)
    End If

End Sub

Sub drawBar(byval x as UINT, byval y as UINT, byval height as UINT)
    Dim i As Integer
    
    For i = 0 To Height - 1
        Clear(specbuf(((y + i) * SPECWIDTH + x * Int(SPECWIDTH / BANDS)) + 3), y + 1, SPECWIDTH / BANDS - 2)
    Next
End Sub

' update the spectrum display - the interesting bit :)
Sub UpdateSpectrum(byval uTimerID as UINT, byval uMsg as UINT, byval dwUser as UINT, byval dw1 as UINT, byval dw2 as UINT)

    Dim dc as HDC
    Dim As Integer x, y, y1 
    Dim b0 As Integer = 0
    Dim fft(1024) As Single
    Dim sum As Single
    Dim sc As Integer
    Dim b1 As Integer

    Erase specbuf ' Clear specbuf

    SIDGetFFTData(@fft(0))

    ' Only update if we're not paused and running
    If Not g_paused And g_running Then
        For x = 0 To BANDS - 1
            sum = 0
            b1 = pow(2, (x * 10.0) / (BANDS - 1))
            If (b1 > 1023) Then : b1 = 1023 : End If
            If (b1 <= b0) Then : b1 = b0 + 1 : End If ' make sure it uses at least 1 FFT bin
            sc = 10 + (b1 - b0)
            For b0 = b0 To b1 - 1 : sum += fft(1 + b0) : Next
            y = (sqrt(sum / log10(sc)) * 2.5 * SPECHEIGHT) ' scale it
            If (y > (SPECHEIGHT - 4)) Then : y = SPECHEIGHT - 4 : End If ' cap it
            For b1 = 0 To y - 1 Step 5
                drawBar(x, b1, 4) ' draw bar
            Next
        Next
    End If

    ' update the display
    dc = GetDC(specwin)
    SetDIBitsToDevice(dc, 0, 0, SPECWIDTH, SPECHEIGHT, 0, 0, 0, SPECHEIGHT, @specbuf(0), cast(BITMAPINFO ptr, @bmi), 0)
    ReleaseDC(specwin, dc)
    
End Sub

Function WndProc (byval hWnd as HWND, byval message as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as BOOL
    Dim a As Integer
    Dim pandr As String

    select Case message

        Case WM_INITDIALOG
            ' Check this is the only instance of the app
            If OpenMutex(MUTEX_ALL_ACCESS, FALSE, APP_NAME) = 0 Then
    
                CreateMutex(0, False, APP_NAME)
        
                SendMessage(hWnd, WM_SETICON, 0, cast(LPARAM, LoadIcon(g_hInst, cast(LPCSTR, IDI_ICON))))
        
                g_hWnd = hWnd
                specwin = GetDlgItem(hWnd, IDC_SPEC)

                ' Start the SID music playing from our resource
                SIDOpen(cast(any ptr, IDR_MUSIC), 0, SID_RESOURCE, SID_DEFAULT, 0)
                SIDGetProps(@sid_props)
        
                g_running = 1
                g_subsong = sid_props.default_song
                UpdateSIDInfo()
        
                ' create bitmap to draw spectrum in (8 bit for easy updating)
                bmi.bmiHeader.biSize = Sizeof(BITMAPINFOHEADER)
                bmi.bmiHeader.biWidth = SPECWIDTH
                bmi.bmiHeader.biHeight = SPECHEIGHT ' upside down (line 0=bottom)
                bmi.bmiHeader.biPlanes = 1
                bmi.bmiHeader.biBitCount = 8
                bmi.bmiHeader.biClrUsed = 256
                bmi.bmiHeader.biClrImportant = 256
        
                ' setup palette
                For a = 1 To 127
                    bmi.bmiColors(a).rgbGreen = 256 - 2 * a
                    bmi.bmiColors(a).rgbRed = 2 * a
                Next
        
                For a = 0 To 31
                    bmi.bmiColors(128 + a).rgbBlue = 8 * a
                    bmi.bmiColors(128 + 32 + a).rgbBlue = 255
                    bmi.bmiColors(128 + 32 + a).rgbRed = 8 * a
                    bmi.bmiColors(128 + 64 + a).rgbRed = 255
                    bmi.bmiColors(128 + 64 + a).rgbBlue = 8 * (31 - a)
                    bmi.bmiColors(128 + 64 + a).rgbGreen = 8 * a
                    bmi.bmiColors(128 + 96 + a).rgbRed = 255
                    bmi.bmiColors(128 + 96 + a).rgbGreen = 255
                    bmi.bmiColors(128 + 96 + a).rgbBlue = 8 * a
                Next
        
                ' setup spectrum update timer (50hz)
                mmtimer = timeSetEvent(20, 5, @UpdateSpectrum, 0, TIME_PERIODIC)
    
            ' Another instance of the app is already running, so exit
            Else
                SendMessage(hWnd, WM_CLOSE, NULL, NULL)
            End If

        Case WM_COMMAND
            Select Case wParam
                Case IDC_OPEN
                    ' Open a SID file
                    OpenSID()
                    SetWindowText(GetDlgItem(hWnd, IDC_PAUSE_RESUME), PAUSE_TEXT)

                Case IDC_PLAY

                    ' Start the SID music playing
                    If Not g_paused And Not g_running Then
                        SIDPlay()
                        g_running = 1
                    End If

                Case IDC_STOP

                    ' Stop the SID music playing
                    If Not g_paused And g_running Then
                        SIDStop()
                        g_running = 0
                    End If

                Case IDC_NEXT
                    If Not g_paused Then

                        ' Go to the next sub song
                        If g_subsong < sid_props.num_songs Then
                            g_subsong = g_subsong + 1
                            SIDChangeSong(g_subsong - 1)
                            UpdateSIDInfo()
                        End If
                    End If

                Case IDC_PREVIOUS
                    If Not g_paused Then
                        ' Go to the previous sub song
                        If (g_subsong > 1) Then
                            g_subsong = g_subsong - 1
                            SIDChangeSong(g_subsong - 1)
                            UpdateSIDInfo()
                        End If
                    End If

                Case IDC_PAUSE_RESUME
                    ' Pause or resume playback
                    If g_running Then
                        g_paused = Not g_paused

                        If g_paused Then
                            SIDPause()
                            pandr = RESUME_TEXT
                        Else
                            SIDResume()
                            pandr = PAUSE_TEXT
                        End If

                        SetWindowText(GetDlgItem(hWnd, IDC_PAUSE_RESUME), pandr)
                    End If

                Case IDC_EXIT
                    SendMessage(hWnd, WM_CLOSE, NULL, NULL)
            End Select

        ' Use the HTCAPTION trick to allow dragging of the window
        Case WM_LBUTTONDOWN
            SendMessage(hWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam)

        Case WM_CLOSE
            ' Kill the spectrum timer
            timeKillEvent(mmtimer)
        
            ' Close the SID library
            SIDClose()
            
            EndDialog(hWnd, 0)

        Case Else
            Return False

    End Select

    Return True
End Function

g_hInst = GetModuleHandle(NULL)

DialogBoxParam(g_hInst, cast(LPCSTR, IDD_SID_PLAYER_DLG), NULL, @WndProc, NULL) 

End
