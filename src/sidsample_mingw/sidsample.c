// sidsample.c : Defines the entry point for the application.
//

#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <mmsystem.h>
#include <math.h>
#include <commdlg.h>

#include "resource.h"
#include "titchysid.h"

#define SPECWIDTH 368	// display width
#define SPECHEIGHT 127	// height (changing requires palette adjustments too)
#define BANDS 28		// number of equalizer bars

typedef struct {
	BITMAPINFOHEADER bmiHeader;
	RGBQUAD bmiColors[256];
} BITMAPINFO256;

// Forward declarations of functions included in this code module
LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
int OpenSID(void);
void UpdateSIDInfo(void);
long FAR PASCAL SpectrumWindowProc(HWND h, UINT m, WPARAM w, LPARAM l);
void CALLBACK UpdateSpectrum(UINT uTimerID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2);

char AppName[] = "TITCHYSID_PLAYER_DEMO_C";
char PauseText[] = "Pause";
char ResumeText[] = "Resume";

HINSTANCE g_hInst = NULL;
HWND g_hWnd = NULL;
props sid_props;
char g_subsong;
char g_running;
char g_paused = 0;

char buffer[512];

HWND specwin = NULL;
DWORD mmtimer = 0;
BITMAPINFO256 bmi;
BYTE specbuf[SPECWIDTH * SPECHEIGHT];

int WINAPI WinMain(HINSTANCE hInstance,
                    HINSTANCE hPrevInstance,
                    LPSTR lpCmdLine,
                    int nCmdShow)
{
	g_hInst = hInstance;

	DialogBoxParam(hInstance, MAKEINTRESOURCE(IDD_SID_PLAYER_DLG), 0, WndProc, 0);

	ExitProcess(0);
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	int a;

	switch (message) {
		case WM_INITDIALOG:

			// Check this is the only instance of the app
			if (!OpenMutex(MUTEX_ALL_ACCESS, FALSE, AppName)) {

				CreateMutex(0, FALSE, AppName);

				SendMessage(hWnd, WM_SETICON, 0, (LPARAM)LoadIcon(g_hInst, (LPCSTR)IDI_ICON));

				g_hWnd = hWnd;
				specwin = GetDlgItem(hWnd, IDC_SPEC);

				// Start the SID music playing from our resource
				SIDOpen(IDR_MUSIC, 0, SID_RESOURCE, SID_DEFAULT, 0);
				SIDGetProps(&sid_props);

				g_running = 1;
				g_subsong = sid_props.default_song;
				UpdateSIDInfo();

				// create bitmap to draw spectrum in (8 bit for easy updating)
				bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
				bmi.bmiHeader.biWidth = SPECWIDTH;
				bmi.bmiHeader.biHeight = SPECHEIGHT; // upside down (line 0=bottom)
				bmi.bmiHeader.biPlanes = 1;
				bmi.bmiHeader.biBitCount = 8;
				bmi.bmiHeader.biClrUsed = 256;
				bmi.bmiHeader.biClrImportant = 256;

				// setup palette
				for (a = 1; a < 128; a++) {
					bmi.bmiColors[a].rgbGreen = 256 - 2 * a;
					bmi.bmiColors[a].rgbRed = 2 * a;
				}

				for (a = 0; a < 32; a++) {
					bmi.bmiColors[128 + a].rgbBlue = 8 * a;
					bmi.bmiColors[128 + 32 + a].rgbBlue = 255;
					bmi.bmiColors[128 + 32 + a].rgbRed = 8 * a;
					bmi.bmiColors[128 + 64 + a].rgbRed = 255;
					bmi.bmiColors[128 + 64 + a].rgbBlue = 8 * (31 - a);
					bmi.bmiColors[128 + 64 + a].rgbGreen = 8 * a;
					bmi.bmiColors[128 + 96 + a].rgbRed = 255;
					bmi.bmiColors[128 + 96 + a].rgbGreen = 255;
					bmi.bmiColors[128 + 96 + a].rgbBlue = 8 * a;
				}

				// setup update timer (50hz)
				mmtimer = timeSetEvent(20, 5, (LPTIMECALLBACK)&UpdateSpectrum, 0, TIME_PERIODIC);
			}

			// Another instance of the app is already running, so exit
			else {
				SendMessage(hWnd, WM_CLOSE, NULL, NULL);
			}

			break;

		case WM_COMMAND:
			switch (wParam) {
			case IDC_OPEN:
				// Open a SID file
				OpenSID();
				SetWindowText(GetDlgItem(hWnd, IDC_PAUSE_RESUME), PauseText);
				break;

			case IDC_PLAY:
				// Start the SID music playing
				if (!g_paused && !g_running) {
					SIDPlay();
					g_running = 1;
				}
				break;

			case IDC_STOP:
				// Stop the SID music playing
				if (!g_paused && g_running) {
					SIDStop();
					g_running = 0;
				}
				break;

			case IDC_NEXT:
				if (!g_paused) {
					// Go to the next sub song
					if (g_subsong < sid_props.num_songs) {
						SIDChangeSong((++g_subsong) - 1);
						UpdateSIDInfo();
					}
				}
				break;

			case IDC_PREVIOUS:
				if (!g_paused) {
					// Go to the previous sub song
					if (g_subsong > 1) {
						SIDChangeSong((--g_subsong) - 1);
						UpdateSIDInfo();
					}
				}
				break;

			case IDC_PAUSE_RESUME:
				// Pause or resume playback
				if (g_running) {
					g_paused = !g_paused;

					if (g_paused) {
						SIDPause();
					}
					else {
						SIDResume();
					}

					SetWindowText(GetDlgItem(hWnd, IDC_PAUSE_RESUME),
						g_paused ? ResumeText : PauseText);
				}

				break;

			case IDC_EXIT:
				SendMessage(hWnd, WM_CLOSE, NULL, NULL);
				break;
			}

			break;

			// Use the HTCAPTION trick to allow dragging of the window
		case WM_LBUTTONDOWN:
			SendMessage(hWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam);

			break;

		case WM_CLOSE:
			// Kill the spectrum timer
			timeKillEvent(mmtimer);

			// Close the SID library
			SIDClose();

			EndDialog(hWnd, 0);

			break;

		default:
			return FALSE;
	}

	return TRUE;
}

int OpenSID(void) {
	char* FilePtr = NULL;
	char FileName[MAX_PATH] = { "" };
	HANDLE hFile;
	int bytesread;
	WIN32_FILE_ATTRIBUTE_DATA attr;
	OPENFILENAME ofn;

	memset(&ofn, 0, sizeof(OPENFILENAME));

	ofn.lStructSize = sizeof(OPENFILENAME);
	ofn.hwndOwner = g_hWnd;
	ofn.lpstrFilter = "SID Files (*.sid)\0*.sid\0\0";
	ofn.lpstrFile = FileName;
	ofn.nMaxFile = MAX_PATH - 1;
	ofn.Flags = OFN_FILEMUSTEXIST | OFN_NONETWORKBUTTON |
		OFN_PATHMUSTEXIST | OFN_LONGNAMES | OFN_EXPLORER;
	ofn.lpstrTitle = "Choose SID File\0";

	if (GetOpenFileName(&ofn)) {
		GetFileAttributesEx(FileName, 0, &attr);

		FilePtr = GlobalAlloc(GPTR, attr.nFileSizeLow);

		hFile = CreateFile(FileName, GENERIC_READ, FILE_SHARE_READ,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

		if (ReadFile(hFile, FilePtr, attr.nFileSizeLow, &bytesread, NULL)) {
			// Start the SID playing 
			SIDOpen(FilePtr, attr.nFileSizeLow, SID_MEMORY, SID_DEFAULT, 0);
			SIDGetProps(&sid_props);

			g_paused = 0;
			g_running = 1;
			g_subsong = sid_props.default_song;
			UpdateSIDInfo();
		}

		CloseHandle(hFile);
		GlobalFree(FilePtr);
	}

	return 0;
}

void UpdateSIDInfo(void) {
	// Display the current sub song
	wsprintf(buffer, "%d", g_subsong);
	SetWindowText(GetDlgItem(g_hWnd, IDC_SONG_NUM), buffer);

	wsprintf(buffer, "$%04X\n$%04X\n$%04X\n"
		"%d bytes (%d blocks)\n%d\n%d\n"
		"%s\n%s\n%s",
		sid_props.load_addr,
		sid_props.init_addr,
		sid_props.play_addr,
		sid_props.data_size,
		(sid_props.data_size / 256) + (sid_props.data_size % 256 ? 1 : 0), // size in blocks
		sid_props.num_songs,
		sid_props.default_song,
		sid_props.sid_name,
		sid_props.author,
		sid_props.copyright);

	// Display the SID file properties
	SetWindowText(GetDlgItem(g_hWnd, IDC_INFO), buffer);
}

void drawBar(int x, int y, int height) {
	int i;

	for (i = 0; i < height; i++) {
		memset(specbuf + ((y + i) * SPECWIDTH) + (x * (SPECWIDTH / BANDS)) + 3, y + 1, (SPECWIDTH / BANDS) - 2);
	}
}

// update the spectrum display - the interesting bit :)
void CALLBACK UpdateSpectrum(UINT uTimerID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2) {
	HDC dc;
	int x, y;
	int b0 = 0;
	float fft[1024];

	memset(specbuf, 0, SPECWIDTH * SPECHEIGHT); // Clear specbuf

	SIDGetFFTData(fft);

	// Only update if we're not paused and running
	if (!g_paused && g_running) {
		for (x = 0; x < BANDS; x++) {
			float sum = 0;
			int sc;
			int b1 = pow(2, (x * 10.0) / (BANDS - 1));
			if (b1 > 1023) b1 = 1023;
			if (b1 <= b0) b1 = b0 + 1; // make sure it uses at least 1 FFT bin
			sc = 10 + (b1 - b0);
			for (; b0 < b1; b0++) sum += fft[1 + b0];
			y = (sqrt(sum / log10(sc)) * 2.5 * SPECHEIGHT); // scale it
			if (y > (SPECHEIGHT - 4)) y = SPECHEIGHT - 4; // cap it
			for (b1 = 0; b1 < y; b1 += 5) {
				drawBar(x, b1, 4); // draw bar
			}
		}
	}

	// update the display
	dc = GetDC(specwin);
	SetDIBitsToDevice(dc, 0, 0, SPECWIDTH, SPECHEIGHT, 0, 0, 0, SPECHEIGHT, &specbuf, &bmi, 0);
	ReleaseDC(specwin, dc);
}
