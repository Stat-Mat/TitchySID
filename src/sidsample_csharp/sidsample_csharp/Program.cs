using System;
using System.Windows.Forms;
using System.Threading;

namespace sidsample_csharp {
    static class Program {
        const string AppName = "TITCHYSID_PLAYER_DEMO_C#";
        static Mutex m;

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main() {
            // Check this is the only instance of the app
            m = new Mutex(true, AppName, out bool ok);

            if (!ok) {
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new IDD_SID_PLAYER_DLG());
        }
    }
}
