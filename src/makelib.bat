:: ===================================================================
:: TitchySID v1.5 by StatMat - November 2020
::
:: Based on TinySID by Tammo Hinrichs (kb) and Rainer Sinsch (myth)
::
:: Caveat: This library has been stripped down to the bare essentials
:: required for SID playback. This means that the code is pretty
:: horrible in places, but the idea is to make the thing as small as
:: possible. Everything is hard-coded to run at 44100Hz.
:: ===================================================================

@echo off

:: ********************************************
:: *** Set the path to the MASM_HOME32 directory ***
:: ********************************************

set MASM_HOME=c:\MASM32

:: ********************************************************
:: *** Start by building the standard smaller library.  ***
:: *** The script will loop round a second time to      ***
:: *** build the extras library.                        ***
:: ********************************************************

SET SID_EXTRAS=0

:: *************************************************
:: *** Create the output folder and change to it ***
:: *************************************************

md lib >nul 2>&1
cd lib

:buildloop

:: ******************************************************************
:: *** Setup some vars based on whether extras are enabled or not ***
:: ******************************************************************

IF %SID_EXTRAS%==0 (SET SID_TITCHYSID_OBJ=titchysid) & (SET SID_EMU_OBJ=sidemu) & (SET SID_LIB=titchysid.lib) & (SET SID_LIBA=libtitchysid.a) & (SET SID_DLL=titchysid.dll) & (SET SID_PARAM=) &echo Building standard library...
IF %SID_EXTRAS%==1 (SET SID_TITCHYSID_OBJ=titchysid_extras) & (SET SID_EMU_OBJ=sidemu_extras) & (SET SID_LIB=titchysid_extras.lib) & (SET SID_LIBA=libtitchysid_extras.a) & (SET SID_DLL=titchysid_extras.dll) & (SET SID_PARAM=/D"SID_EXTRAS=1") & echo Building extras library...

:: *******************************************************************
:: *** Assemble the code                                           ***
:: *** Uses JWasm.exe instead of the standard ml.exe which comes   ***
:: *** with MASM_HOME32. The reason for this is that it creates smaller ***
:: *** object files which seem to be more compatible with other    ***
:: *** compilers (i.e. FreeBASIC).                                 ***
:: *** It's available here: https://www.japheth.de/JWasm.html      ***
:: *******************************************************************

"%MASM_HOME%\bin\jwasm.exe" -coff -nologo -zlc -zld -zlf -zls /I"%MASM_HOME%\include" -Fo%SID_TITCHYSID_OBJ%.obj %SID_PARAM% ..\titchysid.asm
"%MASM_HOME%\bin\jwasm.exe" -coff -nologo -zlc -zld -zlf -zls /I"%MASM_HOME%\include" -Fo%SID_TITCHYSID_OBJ%_dll.obj /D"BUILD_DLL=1" %SID_PARAM% ..\titchysid.asm
"%MASM_HOME%\bin\jwasm.exe" -coff -nologo -zlc -zld -zlf -zls /I"%MASM_HOME%\include" -Fo%SID_EMU_OBJ%.obj %SID_PARAM% ..\sidemu.asm
"%MASM_HOME%\bin\jwasm.exe" -coff -nologo -zlc -zld -zlf -zls /I"%MASM_HOME%\include" %SID_PARAM% ..\fft.asm

:: *********************
:: *** Build the DLL ***
:: *********************

IF %SID_EXTRAS%==0 "%MASM_HOME%\bin\link" /DLL /NOLOGO /SUBSYSTEM:WINDOWS /LIBPATH:"%MASM_HOME%\lib" /OUT:%SID_DLL% /DEF:..\titchysid_dll.def kernel32.lib winmm.lib %SID_TITCHYSID_OBJ%_dll.obj %SID_EMU_OBJ%.obj
IF %SID_EXTRAS%==1 "%MASM_HOME%\bin\link" /DLL /NOLOGO /SUBSYSTEM:WINDOWS /LIBPATH:"%MASM_HOME%\lib" /OUT:%SID_DLL% /DEF:..\titchysid_extras_dll.def kernel32.lib winmm.lib %SID_TITCHYSID_OBJ%_dll.obj %SID_EMU_OBJ%.obj fft.obj

:: *******************************
:: *** Build the static libary ***
:: *******************************

IF %SID_EXTRAS%==0 "%MASM_HOME%\bin\link" /LIB /NOLOGO /LIBPATH:"%MASM_HOME%\lib" /OUT:%SID_LIB% %SID_TITCHYSID_OBJ%.obj %SID_EMU_OBJ%.obj
IF %SID_EXTRAS%==1 "%MASM_HOME%\bin\link" /LIB /NOLOGO /LIBPATH:"%MASM_HOME%\lib" /OUT:%SID_LIB% %SID_TITCHYSID_OBJ%.obj %SID_EMU_OBJ%.obj fft.obj

:: **********************************
:: *** Create the GNU .a lib file ***
:: **********************************

copy /Y %SID_LIB% %SID_LIBA%

:: **************************************
:: *** cleanup the intermediate files ***
:: **************************************

del *.obj
del *.exp

IF %SID_EXTRAS%==0 (SET SID_EXTRAS=1) & goto buildloop

cd ..

pause
