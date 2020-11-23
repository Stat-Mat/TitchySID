﻿using System;
using System.Runtime.InteropServices;

namespace titchysid_container {
    class titchysid {
        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern IntPtr LoadLibrary(string lpszLib);

        // Use basic or extras DLL name depending on version being used
        const string dllName = "titchysid_extras.dll";

        // Load SID file from a resource
        public const byte SID_RESOURCE = 0;

        // Load SID file from provided memory buffer
        public const byte SID_MEMORY = 1;

        // Options used in SIDOpen()
        // Play default sub song, as found in the PSID header
        public const byte SID_DEFAULT = 1;

        // Play specified sub song
        public const byte SID_NON_DEFAULT = 2;

        /*
        ===================================================================
         SIDOpen()
  
         Purpose: Open the SID library
  
                  Call with *either* a resource ID for the
                  SID music or a pointer to a buffer in memory
                  e.g.:

                  To load a resource within the executable:
          
                  SIDOpen (res_id, 0, SID_RESOURCE, SID_DEFAULT, subsong);

                  To load from a buffer in memory:
 
                  SIDOpen (mem, mem_len, SID_MEMORY, SID_DEFAULT, subsong);

                  Last parameter is subsong (many PSID files contain several
                  subsongs or sound effects). This is ignored if the options
                  parameter has the SID_DEFAULT flag set. If you wish to
                  specify which sub song to play, then you should use the
                  SID_NON_DEFAULT flag instead.

         Returns non-zero on success
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDOpen(byte[] res_mem, uint mem_len,
                        byte mode, byte options,
                        byte subsong);

        /*
        ===================================================================
         SIDClose()

         Purpose : Close the SID library

         Call this in your WM_CLOSE handler
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDClose();

        /*
        ================================================
         The functions below are only available if the
         library is built with SID_EXTRAS enabled
        ================================================
        */

        /*
        ===================================================================
         SIDPlay()

         Purpose : Start the SID playback
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDPlay();

        /*
        ===================================================================
         SIDStop()

         Purpose : Stop the SID playback
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDStop();

        /*
        ===================================================================
         SIDPause()

         Purpose : Pause the currently playing SID song
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDPause();

        /*
        ===================================================================
         SIDResume()

         Purpose : Resume playing the SID song after a pause
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDResume();

        /*
        ===================================================================
         SIDChangeSong()

         Purpose : Change to another sub song in the currently playing SID
                   file

         Parameter : New subsong ID (0 based)
        ===================================================================
        */


        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDChangeSong(byte subsong);

        /*
        ===================================================================
         SIDGetFFTData()

         Purpose : Perform a fast fourier transform (FFT) of the current
                   2048 16-bit samples generated by the SID emulation. This
                   is typically useful for a spectrum analyser.

         Parameter : A pointer to an array of 1024 4-byte floating point
                     values. Upon return, each item in the array will
                     contain a representation of amplitude at a particular
                     frequency band. These values will range between 0 and
                     1.
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDGetFFTData(float[] pFFT);

        /*
        ===================================================================
         SIDGetProps()

         Purpose : Return the properties structure containing all of the
                   information associated with the SID tune loaded with
                   SIDOpen().

         Parameter : A pointer to a memory buffer of suffcient size to
                     hold a copy of the props structure defined above.
        ===================================================================
        */

        [DllImport(dllName, CharSet = CharSet.Ansi)]
        public static extern int SIDGetProps(byte[] sid_props);

        /*
        ===================================================================
         This structure holds all of the SID file info after a successful
         call to SIDOpen().
        ===================================================================
        */

        public struct sid_props {
            // The address where the SID data should be placed in the C64's memory
            public ushort load_addr;

            // The address in the C64's memory where the initialise routine for the
            // SID songs is located (accepts a subsong ID in the accumulator)
            public ushort init_addr;

            // The address in the C64's memory where the play routine is located. This
            // is called frequently to produce continuous sound.
            public ushort play_addr;

            // The total number of subsongs contained in the SID file
            public byte num_songs;

            // The default subsong to be played
            public byte default_song;

            // The song speed
            public byte speed;

            // Just alignment padding
            public byte pad;

            // The total size of the SID data (in bytes)
            public ushort data_size;

            // The name of the SID file (in raw bytes)
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 32)]
            public byte[] sid_name_bytes;

            // The author's name (in raw bytes)
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 32)]
            public byte[] author_bytes;

            // The copyright string (in raw bytes)
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 32)]
            public byte[] copyright_bytes;

            // The name of the SID file
            public string sid_name;

            // The author's name
            public string author;

            // The copyright string
            public string copyright;
        }

        // A helper method to take the unmanaged memory returned by the library and map it to the sid_props structure
        public static void GetSIDProps(ref sid_props props) {
            var buf = new byte[Marshal.SizeOf(props)];
            SIDGetProps(buf);

            GCHandle hDataIn = GCHandle.Alloc(buf, GCHandleType.Pinned);

            // Map the byte array onto our structure
            props =
            (sid_props)Marshal.PtrToStructure(hDataIn.AddrOfPinnedObject(),
            typeof(sid_props));

            // Convert the raw byte fields into more manageable strings
            var enc = System.Text.Encoding.UTF7;
            props.sid_name = enc.GetString(props.sid_name_bytes).Trim('\0');
            props.author = enc.GetString(props.author_bytes).Trim('\0');
            props.copyright = enc.GetString(props.copyright_bytes).Trim('\0');
        }
    }
}