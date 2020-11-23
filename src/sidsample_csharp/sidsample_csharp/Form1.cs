using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows.Forms;
using System.IO;
using System.Runtime.InteropServices;

using titchysid_container;
using sidsample_csharp.Properties;

namespace sidsample_csharp {
    public partial class IDD_SID_PLAYER_DLG : Form {
        const int WM_NCLBUTTONDOWN = 0xA1;
        const int HTCAPTION = 0x2;

        [DllImport("User32.dll")]
        private static extern bool ReleaseCapture();

        [DllImport("User32.dll")]
        private static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);

        const int SPECWIDTH = 368;	// display width
        const int SPECHEIGHT = 127;	// height (changing requires palette adjustments too)
        const int BANDS = 28;		// number of equalizer bars

        byte g_subsong;
        bool g_running;
        bool g_paused = false;

        titchysid.sid_props sid_props = new titchysid.sid_props();

        MultimediaTimer timer;

        Bitmap specbmp;
        Bitmap specbmp2;
        readonly byte[] specbuf = new byte[SPECWIDTH * SPECHEIGHT];

        public IDD_SID_PLAYER_DLG() {
            InitializeComponent();
        }

        private void IDD_SID_PLAYER_DLG_Load(object sender, EventArgs e) {
            int a;
            int rc;
            ColorPalette pal;

            // Start the SID music playing from our resource
            rc = titchysid.SIDOpen(Resources.music, (uint)Resources.music.Length, titchysid.SID_MEMORY, titchysid.SID_DEFAULT, 0);

            g_running = true;

            titchysid.GetSIDProps(ref sid_props);
            g_subsong = sid_props.default_song;
            UpdateSIDInfo();

            specbmp = new Bitmap(SPECWIDTH, SPECHEIGHT, PixelFormat.Format8bppIndexed);
            specbmp2 = new Bitmap(specbmp.Width, specbmp.Height, PixelFormat.Format32bppPArgb);

            IDC_SPEC.Image = specbmp2;

            pal = specbmp.Palette;

            // setup palette
            for (a = 1; a < 128; a++) {
                pal.Entries[a] = Color.FromArgb(2 * a, 256 - 2 * a, 0);
            }

            for (a = 0; a < 32; a++) {
                pal.Entries[128 + a] = Color.FromArgb(pal.Entries[128 + a].R, pal.Entries[128 + a].G, 8 * a);
                pal.Entries[128 + 32 + a] = Color.FromArgb(8 * a, pal.Entries[128 + 32 + a].G, 255);
                pal.Entries[128 + 64 + a] = Color.FromArgb(255, 8 * a, 8 * (31 - a));
                pal.Entries[128 + 96 + a] = Color.FromArgb(255, 255, 8 * a);
            }

            specbmp.Palette = pal;
            IDC_SPEC.Image = specbmp2;

            // setup spectrum update timer (50hz)
            timer = new MultimediaTimer() {
                Interval = 1000 / 50
            };

            timer.Elapsed += UpdateSpectrum;
            timer.Start();

            IDC_INFO_LABELS.MouseDown += new MouseEventHandler(IDD_SID_PLAYER_DLG_MouseDown);
            IDC_INFO.MouseDown += new MouseEventHandler(IDD_SID_PLAYER_DLG_MouseDown);
            IDC_STATIC.MouseDown += new MouseEventHandler(IDD_SID_PLAYER_DLG_MouseDown);
            IDC_SUBSONG.MouseDown += new MouseEventHandler(IDD_SID_PLAYER_DLG_MouseDown);
            IDC_SONG_NUM.MouseDown += new MouseEventHandler(IDD_SID_PLAYER_DLG_MouseDown);
        }

        private void IDC_PLAY_Click(object sender, EventArgs e) {
            // Start the SID music playing
            if (!g_paused && !g_running) {
                titchysid.SIDPlay();
                g_running = true;
            }
        }

        private void IDC_PAUSE_RESUME_Click(object sender, EventArgs e) {
            // Pause or resume playback
            if (g_running) {
                g_paused = !g_paused;

                if(g_paused) {
                    titchysid.SIDPause();
                }
                else {
                    titchysid.SIDResume();
                }

                IDC_PAUSE_RESUME.Text = g_paused ? "Resume" : "Pause";
            }
        }

        private void IDC_STOP_Click(object sender, EventArgs e) {
            // Stop the SID music playing
            if (!g_paused && g_running) {
                titchysid.SIDStop();
                g_running = false;
            }
        }

        // This method uses the HTCAPTION trick to allow dragging of the window
        private void IDD_SID_PLAYER_DLG_MouseDown(object sender, MouseEventArgs e) {
            ReleaseCapture();
            SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
        }

        private void IDC_EXIT_Click(object sender, EventArgs e) {
            Application.Exit();
        }

        private void OpenSID(string filename, ref byte[] data, ref uint len) {
            data = File.ReadAllBytes(filename);
            len = (uint)data.Length;
        }

        private void IDC_OPEN_Click(object sender, EventArgs e) {
            uint len = 0;
            byte[] data = null;

            using(OpenFileDialog ofd = new OpenFileDialog {
                Title = "Choose SID File",
                Filter = "SID Files (*.sid)|*.sid",
                FilterIndex = 1,
                RestoreDirectory = true,
                CheckFileExists = true,
                CheckPathExists = true
            }) {
                if(ofd.ShowDialog() == DialogResult.OK) {
                    OpenSID(ofd.FileName, ref data, ref len);

                    // Start the SID playing 
                    titchysid.SIDOpen(data, len, titchysid.SID_MEMORY, titchysid.SID_DEFAULT, 0);

                    titchysid.GetSIDProps(ref sid_props);
                    g_subsong = sid_props.default_song;
                    UpdateSIDInfo();

                    g_running = true;
                }
            }
        }

        private void IDC_PREVIOUS_Click(object sender, EventArgs e) {
            if (!g_paused) {
                // Go to the previous sub song
                if (g_subsong > 1) {
                    g_subsong--;
                    titchysid.SIDChangeSong((byte)(g_subsong - 1));
                    UpdateSIDInfo();
                }
            }
        }

        private void IDC_NEXT_Click(object sender, EventArgs e) {
            if (!g_paused) {
                // Go to the next sub song
                if (g_subsong < sid_props.num_songs) {
                    g_subsong++;
                    titchysid.SIDChangeSong((byte)(g_subsong - 1));
                    UpdateSIDInfo();
                }
            }
        }

        void drawBar(int x, int y, int height) {
            int i, j;

            for (i = 0; i < height; i++) {
                for (j = 0; j < (SPECWIDTH / BANDS) - 2; j++) {
                    specbuf[(y * SPECWIDTH) + (x * (SPECWIDTH / BANDS) + j) + 3] = (byte)(y + 1);
                    specbuf[((y + 1) * SPECWIDTH) + (x * (SPECWIDTH / BANDS) + j) + 3] = (byte)(y + 1);
                    specbuf[((y + 2) * SPECWIDTH) + (x * (SPECWIDTH / BANDS) + j) + 3] = (byte)(y + 1);
                    specbuf[((y + 3) * SPECWIDTH) + (x * (SPECWIDTH / BANDS) + j) + 3] = (byte)(y + 1);
                }
            }
        }

        private void UpdateSpectrum(object source, EventArgs e) {
            int x, y;
            int b0 = 0;
            float[] fft = new float[1024];

            Array.Clear(specbuf, 0, specbuf.Length);

            titchysid.SIDGetFFTData(fft);

            // Only update if we're not paused and running
            if (!g_paused && g_running) {
                for (x = 0; x < BANDS; x++) {
                    float sum = 0;
                    int sc;
                    int b1 = (int)Math.Pow(2, (x * 10.0) / (BANDS - 1));
                    if (b1 > 1023) b1 = 1023;
                    if (b1 <= b0) b1 = b0 + 1; // make sure it uses at least 1 FFT bin
                    sc = 10 + (b1 - b0);
                    for (; b0 < b1; b0++) sum += fft[1 + b0];
                    y = (int)(Math.Sqrt(sum / Math.Log10(sc)) * 2.5 * SPECHEIGHT); // scale it
                    if (y > (SPECHEIGHT - 4)) y = SPECHEIGHT - 4; // cap it
                    for (b1 = 0; b1 < y; b1 += 5) {
                        drawBar(x, b1, 4); // draw bar
                    }
                }
            }

            BitmapData bmpData = specbmp.LockBits(new Rectangle(0, 0, SPECWIDTH, SPECHEIGHT),
                                                    ImageLockMode.ReadWrite, PixelFormat.Format8bppIndexed);

            // Get the address of the first line
            IntPtr ptr = bmpData.Scan0;

            // Copy the RGB values back to the bitmap
            Marshal.Copy(specbuf, 0, ptr, SPECWIDTH * SPECHEIGHT);

            // Unlock the bits.
            specbmp.UnlockBits(bmpData);

            // Invert the image
            specbmp.RotateFlip(RotateFlipType.RotateNoneFlipY);

            // invoke the method asynchronously
            IAsyncResult result = IDC_SPEC.BeginInvoke((MethodInvoker)delegate() {
                // update the display
                Graphics gr = Graphics.FromImage(specbmp2);
                gr.DrawImageUnscaled(specbmp, 0, 0);
                gr.Dispose();
                IDC_SPEC.Invalidate();
            });

            // get the result of that asynchronous operation
            IDC_SPEC.EndInvoke(result);
        }

        private void UpdateSIDInfo() {
            // Display the current sub song
            IDC_SONG_NUM.Text = string.Format("{0}", g_subsong);

            string buffer =
            string.Format("${0:X4}\r\n${1:X4}\r\n${2:X4}\r\n" +
                            "{3} bytes ({4} blocks)\r\n{5}\r\n{6}\r\n" +
                            "{7}\r\n{8}\r\n{9}",
                            sid_props.load_addr,
                            sid_props.init_addr,
                            sid_props.play_addr,
                            sid_props.data_size,
                            (sid_props.data_size / 256) + ((sid_props.data_size % 256 > 0) ? 1 : 0), // size in blocks
                            sid_props.num_songs,
                            sid_props.default_song,
                            sid_props.sid_name,
                            sid_props.author,
                            sid_props.copyright);

            // Display the SID file properties
            IDC_INFO.Text = buffer;
        }

        private void IDD_SID_PLAYER_DLG_FormClosing(object sender, FormClosingEventArgs e) {
            timer.Stop();
            titchysid.SIDClose();
        }

        private void IDD_SID_PLAYER_DLG_FormClosed(object sender, FormClosedEventArgs e) {
            timer.Dispose();
        }
    }
}
