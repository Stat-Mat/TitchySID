Import "winmm.lib" : EndImport

; Load SID file from a resource
#SID_RESOURCE    = 0

; Load SID file from provided memory
#SID_MEMORY      = 1

; Options used in SIDOpen()
; Play default sub song, as found in the PSID header
#SID_DEFAULT     = 1

; Play specified sub song
#SID_NON_DEFAULT = 2

;===================================================================
; This structure holds all of the SID file info after a successful
; call to SIDOpen().
;
; Note: Needs to be 4 byte aligned for C etc (hence the pad byte)
;===================================================================

Structure props

    ; The address where the SID data should be placed in the C64's memory
    load_addr.u
    
    ; The address in the C64's memory where the initialise routine for the
    ; SID songs is located (accepts a subsong ID in the accumulator)
    init_addr.u

    ; The address in the C64's memory where the play routine is located. This
    ; is called frequently to produce continuous sound.
    play_addr.u

    ; The total number of subsongs contained in the SID file
    num_songs.b
    
    ; The default subsong to be played
    default_song.b

    ; The song speed
    speed.b

    ; Just alignment padding
    pad.b

    ; The total size of the SID data (in bytes)
    data_size.u

    ; The name of the SID file
    sid_name.b[32]
    
    ; The author's name
    author.b[32]

    ; The copyright string
    copyright.b[32]

EndStructure

Import "..\lib\titchysid_extras.lib"

    ;===================================================================
    ; SIDOpen()
    ;  
    ; Purpose: Open the SID library
    ;
    ;          Call with *either* a resource ID for the
    ;          SID music or a pointer to a buffer in memory
    ;          e.g.:
    ;
    ;          To load a resource within the executable:
    ;          
    ;          SIDOpen (res_id, 0, SID_RESOURCE, SID_DEFAULT, subsong);
    ;
    ;          To load from a buffer in memory:
    ; 
    ;          SIDOpen (mem, mem_len, SID_MEMORY, SID_DEFAULT, subsong);
    ;
    ;          Last parameter is subsong (many PSID files contain several
    ;          subsongs or sound effects). This is ignored if the options
    ;          parameter has the SID_DEFAULT flag set. If you wish to
    ;          specify which sub song to play, then you should use the
    ;          SID_NON_DEFAULT flag instead.o play,
    ;          then you should use the SID_NON_DEFAULT flag instead.
    ;
    ; Returns non-zero on success
    ;====================================================================

    SIDOpen(res_mem.i, mem_len.i, mode.c, options.c, subsong.c) As "_SIDOpen@20"

    ;===================================================================
    ;  SIDClose()
    ;
    ;  Purpose : Close the SID library
    ;
    ;  Call this in your WM_CLOSE handler
    ;===================================================================

    SIDClose() As "_SIDClose@0"

    ;=================================================
    ; The functions below are only available if the
    ; library is built with SID_EXTRAS enabled
    ;=================================================

    ;===================================================================
    ; SIDPlay()
    ;
    ; Purpose : Start the SID playback
    ;===================================================================

    SIDPlay() As "_SIDPlay@0"

    ;===================================================================
    ; SIDStop()
    ;
    ; Purpose : Stop the SID playback
    ;===================================================================

    SIDStop() As "_SIDStop@0"

    ;===================================================================
    ; SIDPause()
    ;
    ; Purpose : Pause the currently playing SID song
    ;===================================================================

    SIDPause() As "_SIDPause@0"

    ;===================================================================
    ; SIDResume()
    ;
    ; Purpose : Resume playing the SID song after a pause
    ;===================================================================

    SIDResume() As "_SIDResume@0"

    ;===================================================================
    ; SIDChangeSong()
    ;
    ; Purpose : Change to another sub song in the currently playing SID
    ;                file
    ;
    ;  Parameter : New subsong ID
    ;===================================================================

    SIDChangeSong(subsong.c) As "_SIDChangeSong@4"

    ;===================================================================
    ; SIDGetFFTData()
    ;
    ; Purpose : Perform a fast fourier transform (FFT) of the current
    ;           2048 16-bit samples generated by the SID emulation. This
    ;           is typically useful for a spectrum analyser.
    ;
    ; Parameter : A pointer to an array of 1024 4-byte floating point
    ;             values. Upon return, each item in the array will
    ;             contain a representation of amplitude at a particular
    ;             frequency band. These values will range between 0 and
    ;             1.
    ;===================================================================

    SIDGetFFTData(*pFFT) As "_SIDGetFFTData@4"

    ;===================================================================
    ; SIDGetProps()
    ;
    ; Purpose : Return the properties structure containing all of the
    ;           information associated with the SID tune loaded with
    ;           SIDOpen().
    ;
    ; Parameter : A pointer to a memory buffer of suffcient size to
    ;             hold a copy of the props structure defined above.
    ;===================================================================

    SIDGetProps(*props) As "_SIDGetProps@4"

EndImport
