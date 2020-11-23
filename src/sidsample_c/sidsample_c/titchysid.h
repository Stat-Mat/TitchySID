/*
 ===================================================================
 TitchySID v1.4 by StatMat - November 2020

 Based on TinySID by Tammo Hinrichs (kb) and Rainer Sinsch

 Caveat: This library has been stripped down to the bare essentials
 required for SID playback. This means that the code is pretty
 horrible in places, but the idea is to make the thing as small as
 possible. Everything is hard-coded to run at 44100Hz.
 ===================================================================
*/

// Load SID file from a resource
#define SID_RESOURCE    0

// Load SID file from provided memory buffer
#define SID_MEMORY      1

// Options used in SIDOpen()
// Play default sub song, as found in the PSID header
#define SID_DEFAULT     1

// Play specified sub song
#define SID_NON_DEFAULT 2

/*
===================================================================
 This structure holds all of the SID file info after a successful
 call to SIDOpen().
===================================================================
*/

typedef struct {
    // The address where the SID data should be placed in the C64's memory
    unsigned short load_addr;
    
    // The address in the C64's memory where the initialise routine for the
    // SID songs is located (accepts a subsong ID in the accumulator)
    unsigned short init_addr;

    // The address in the C64's memory where the play routine is located. This
    // is called frequently to produce continuous sound.
    unsigned short play_addr;

    // The total number of subsongs contained in the SID file
    unsigned char num_songs;
    
    // The default subsong to be played
    unsigned char default_song;

    // The song speed
    unsigned char speed;

    // The total size of the SID data (in bytes)
    unsigned short data_size;

    // The name of the SID file
    char sid_name[32];
    
    // The author's name
    char author[32];

    // The copyright string
    char copyright[32];

} props;

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

int __stdcall SIDOpen (unsigned long res_mem, unsigned long mem_len,
						unsigned char mode, unsigned char options,
						unsigned char subsong);

/*
===================================================================
 SIDClose()

 Purpose : Close the SID library

 Call this in your WM_CLOSE handler
===================================================================
*/

int __stdcall SIDClose (void);

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

int __stdcall SIDPlay (void);

/*
===================================================================
 SIDStop()

 Purpose : Stop the SID playback
===================================================================
*/

int __stdcall SIDStop (void);

/*
===================================================================
 SIDPause()

 Purpose : Pause the currently playing SID song
===================================================================
*/

int __stdcall SIDPause (void);

/*
===================================================================
 SIDResume()

 Purpose : Resume playing the SID song after a pause
===================================================================
*/

int __stdcall SIDResume (void);

/*
===================================================================
 SIDChangeSong()

 Purpose : Change to another sub song in the currently playing SID
		   file

 Parameter : New subsong ID (0 based)
===================================================================
*/

int __stdcall SIDChangeSong (unsigned char subsong);

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

int __stdcall SIDGetFFTData (float *pFFT);

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

int __stdcall SIDGetProps(props* sid_props);
