:: **********************************
:: *** Set the BlitzMax home path ***
:: **********************************

set BLITZMAX_HOME=C:\Compilers\BlitzMax

:: ****************************************************************
:: *** Note: you need to set the MingW home path as we need the ***
:: *** WINDRES.EXE tool which isn't included with the original  ***
:: *** BlitzMax. This is used to compile the sidsample.rc file. ***
:: ****************************************************************

set MINGW_HOME=C:\MinGW

set START_PATH=%~dp0

:: ********************************
:: *** Create the output folder ***
:: ********************************

md Release >nul 2>&1

:: *****************************************************
:: *** Compile the RC file to create the object file ***
:: *****************************************************

pushd "%MINGW_HOME%\bin"
windres.exe -i "%START_PATH%sidsample.rc" -o "%START_PATH%sidsample.o"
popd

:: ****************************
:: *** Build the executable ***
:: ****************************

"%BLITZMAX_HOME%\bin\bmk.exe" makeapp -a -r -t gui -o Release\sidsample_blitzmax.exe sidsample_blitzmax.bmx

:: **************************************
:: *** Cleanup the intermediate files ***
:: **************************************

del *.o

pause
