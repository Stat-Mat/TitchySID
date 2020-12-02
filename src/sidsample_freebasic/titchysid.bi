#inclib "winmm"
#inclib "user32"

#inclib "..\lib\titchysid_extras"

' Load SID file from a resource
#define SID_RESOURCE     0

' Load SID file from provided memory
#define SID_MEMORY       1

' Options used in SIDOpen()
' Play default sub song, as found in the PSID header
#define SID_DEFAULT      1

' Play specified sub song
#define SID_NON_DEFAULT  2

'===================================================================
' This structure holds all of the SID file info after a successful
' call to SIDOpen().
'
' Note: Needs to be 4 byte aligned for C etc (hence the pad byte)
'===================================================================

type props

    ' The address where the SID data should be placed in the C64's memory
    load_addr as ushort
    
    ' The address in the C64's memory where the initialise routine for the
    ' SID songs is located (accepts a subsong ID in the accumulator)
    init_addr as ushort

    ' The address in the C64's memory where the play routine is located. This
    ' is called frequently to produce continuous sound.
    play_addr as ushort

    ' The total number of subsongs contained in the SID file
    num_songs as ubyte
    
    ' The default subsong to be played
    default_song as ubyte

    ' The song speed
    speed as ubyte

    ' Just alignment padding
    pad as ubyte

    ' The total size of the SID data (in bytes)
    data_size as ushort

    ' The name of the SID file
    sid_name as string * 31
    
    ' The author's name
    author as string * 31

    ' The copyright string
    copyright as string * 31

end type

Extern "Windows"

    '===================================================================
    ' SIDOpen()
    '  
    ' Purpose: Open the SID library
    '
    '          Call with *either* a resource ID for the
    '          SID music or a pointer to a buffer in memory
    '          e.g.:
    '
    '          To load a resource within the executable:
    '          
    '          SIDOpen (res_id, 0, SID_RESOURCE, SID_DEFAULT, subsong);
    '
    '          To load from a buffer in memory:
    ' 
    '          SIDOpen (mem, mem_len, SID_MEMORY, SID_DEFAULT, subsong);
    '
    '          Last parameter is subsong (many PSID files contain several
    '          subsongs or sound effects). This is ignored if the options
    '          parameter has the SID_DEFAULT flag set. If you wish to
    '          specify which sub song to play, then you should use the
    '          SID_NON_DEFAULT flag instead.o play,
    '          then you should use the SID_NON_DEFAULT flag instead.
    '
    ' Returns non-zero on success
    '====================================================================

    Declare Function SIDOpen(byval as any ptr, byval as uinteger, byval as ubyte, byval as ubyte, byval as ubyte) as integer

    '===================================================================
    '  SIDClose()
    '
    '  Purpose : Close the SID library
    '
    '  Call this in your WM_CLOSE handler
    '===================================================================

    Declare Function SIDClose() as integer

    '=================================================
    ' The functions below are only available if the
    ' library is built with SID_EXTRAS enabled
    '=================================================

    '===================================================================
    ' SIDPlay()
    '
    ' Purpose : Start the SID playback
    '===================================================================

    Declare Function SIDPlay() as integer

    '===================================================================
    ' SIDStop()
    '
    ' Purpose : Stop the SID playback
    '===================================================================

    Declare Function SIDStop() as integer

    '===================================================================
    ' SIDPause()
    '
    ' Purpose : Pause the currently playing SID song
    '===================================================================

    Declare Function SIDPause() as integer

    '===================================================================
    ' SIDResume()
    '
    ' Purpose : Resume playing the SID song after a pause
    '===================================================================

    Declare Function SIDResume() as integer

    '===================================================================
    ' SIDChangeSong()
    '
    ' Purpose : Change to another sub song in the currently playing SID
    '                file
    '
    '  Parameter : New subsong ID
    '===================================================================

    Declare Function SIDChangeSong(byval as ubyte) as integer

    '===================================================================
    ' SIDGetFFTData()
    '
    ' Purpose : Perform a fast fourier transform (FFT) of the current
    '           2048 16-bit samples generated by the SID emulation. This
    '           is typically useful for a spectrum analyser.
    '
    ' Parameter : A pointer to an array of 1024 4-byte floating point
    '             values. Upon return, each item in the array will
    '             contain a representation of amplitude at a particular
    '             frequency band. These values will range between 0 and
    '             1.
    '===================================================================

    Declare Function SIDGetFFTData(byval as any ptr) as integer

    '===================================================================
    ' SIDGetProps()
    '
    ' Purpose : Return the properties structure containing all of the
    '           information associated with the SID tune loaded with
    '           SIDOpen().
    '
    ' Parameter : A pointer to a memory buffer of suffcient size to
    '             hold a copy of the props structure defined above.
    '===================================================================

    Declare Function SIDGetProps(byval as any ptr) as integer

End Extern
