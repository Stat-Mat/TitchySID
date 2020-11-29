# TitchySID Library

Based on TinySID by Tammo Hinrichs (kb) and Rainer Sinsch (myth)

Caveat: this library has been stripped down to the bare essentials required for SID playback. This means that the code is pretty difficult to understand in places, but the idea is to keep it as small as possible. This does mean the library is not 100% compatible with all SID files, but it does work with a large percentage of them. Everything is hard-coded to run at 44100Hz.

## 1. What is TitchySID? 

TitchySID is a library written in MASM32 which can play [SID](https://en.wikipedia.org/wiki/MOS_Technology_6581) chiptunes from the Commodore 64. It currently only supports PSID format files, but it is hoped that other formats will be added in the future. It aims to be the smallest SID player library available which can be added easily to any development project on Microsoft platforms. It can be used either as a static library or a DLL.

![MOS_Technologies_6581](https://upload.wikimedia.org/wikipedia/commons/b/b7/MOS_Technologies_6581.jpg)

![titchysid_csharp_sample](https://github.com/Stat-Mat/TitchySID/blob/master/titchysid_csharp_sample.jpg)
 
## 2. Usage 

The release package contains the full source code for both the library and several demo projects for the following environments: MASM32, C#, C for Visual C++, C for MinGW, BlitzMax, BlitzMax NG, FreeBASIC and PureBasic. This should enable most developers to understand how to use the library.

The library currently only supports 32-bit builds, as the work to port the MASM32 code to 64-bit will be quite extensive. However, support for 64-bit should be added in the future.

Note: in order to use the static library within your project, you must include winmm.lib for the neccessary Windows multimedia API sound functions.
 
The library consists of several simple functions **(see the appropriate titchysid.inc/.h/.cs/.bmx/.bi/.pbi in the sample project of your choice for more details)**. The basic process requires the developer to first instantiate the library with the **SIDOpen()** function in order to start playing SID tunes. Then, once the application no longer needs playback, it should use the **SIDClose()** function.

## 2.1 SIDOpen() 

This function opens up the library for SID playback and starts playing immediately. Here are examples of the two ways in which the **SIDOpen()** function is called:
 
**SIDOpen (res_id, 0, SID_RESOURCE, SID_DEFAULT, subsong);**
 
or
 
**SIDOpen (mem, mem_len, SID_MEMORY, SID_DEFAULT, subsong);**
 
The first demonstrates how to load a PSID file from a binary resource contained within the executable. The second shows the caller passing in a block of memory that contains the PSID file data.
 
The parameter breakdown is as follows:
 
* The first parameter can be used to pass a resource ID to the library. The library will then use this ID to load the PSID file from a binary resource within the executable. Alternatively, it can be used to pass a pointer to a block of memory that contains the contents of a PSID file.

* The second parameter gives the length of the memory block pointed to by the first parameter. If the third parameter is set to SID_RESOURCE (meaning the first parameter is a resource ID, not a memory pointer), then it is ignored.

* The third parameter determines how the library interprets the first parameter. If the first parameter is a resource ID, then this should be set to SID_RESOURCE. If the first parameter is a pointer to a memory block, then it should be set to SID_MEMORY.
 
* The fourth parameter tells the library to play either the default sub song inside the SID file (as given in the PSID header), or to play a sub song chosen by the caller (as passed in the next parameter). For the former you should use SID_DEFAULT, and the latter SID_NON_DEFAULT.
    
* The fifth parameter is the sub song that the caller wishes to be played first. If the previous parameter is set to SID_DEFAULT, this parameter is ignored. It has a valid range of 0-255, as PSID files can contain a maximum of 256 sub songs.

The **SIDopen()** function has a non-zero return value on success and zero on failure.

## 2.2 SIDClose() 

Once your application no longer needs the SID playback, the **SIDClose()** function must be called. A good example of when to do this is inside your WM_CLOSE handler. The function does not require any parameters.
 
## 2.3 Extras 

The library can be built with some extra features included, but this does of course increase it's size. The build script **(makelib.bat)** will build both standard and extras versions of the library automatically in the libs folder.

If you only wish to use the **SIDOpen()** and **SIDClose()** functions from above, then you can use **titchysid.lib**, **titchysid.a** or **titchysid.dll** depending on which compiler and language you are using. If however you want to use the extra features below, then use **titchysid_extras.lib**, **titchysid_extras.a** or **titchysid_extras.dll**. Pre-built versions of both libraries are included in the release package.

## 2.3.1 SIDPlay() 

This function allows the caller to start playing the current sub song. It has no parameters, and simply plays the last selected sub song (from the beginning) before being stopped (see **SIDStop()** below).

## 2.3.2 SIDStop() 

This function allows the caller to stop playing the current sub song. It has no parameters, and simply stops the SID playback. It does not unload the previously loaded SID file such that the caller may use the **SIDPlay()** function above to start playing again.

## 2.3.3 SIDPause() 

This function allows the caller to pause the playback of the currently playing sub song. It has no parameters. The caller can then resume the playback from the same point when desired (see **SIDResume()** below).

## 2.3.4 SIDResume() 

This function allows the caller to resume the playback of the current sub song. It has no parameters.

## 2.3.5 SIDChangeSong() 

This function allows the caller to change to another sub song within the SID file. It has one parameter which determines which sub song to play. This parameter has a valid range of 0-255 just like **SIDOpen()**.

## 2.3.6 SIDGetFFTData() 

This function performs a fast fourier transform (FFT) of the current 2048 16-bit samples generated by the SID emulation. This is typically useful for a spectrum analyser. It has one parameter which is pointer to an array of 1024 4-byte floating point values. Upon return, each item in the array will contain a representation of amplitude at a particular frequency band. These values will range between 0 and 1.

## 2.3.7 SIDGetProps()

After a successful call to **SIDOpen()**, the global sid_props structure contains the properties of the loaded SID file. This data can be obtained by calling **SIDGetProps()**. The structure has the following fields:
 
```
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
```
 
## 3. Credits and Thanks 

I would like to thank Tammo Hinrichs and Rainer Sinsch for all their hard work on producing the TinySID engine which started me out on this in the first place.
 
I would also like to thank The Tea Drinker for his excellent remake of the classic Amiga mod tune Echoing by Banana, which I have included in the demos.
