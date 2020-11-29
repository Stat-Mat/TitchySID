:: *************************************
:: *** Set the BlitzMax NG home path ***
:: *************************************

set BLITZMAX_HOME=C:\Compilers\BlitzMaxNG
set START_PATH=%~dp0

:: ********************************
:: *** Create the output folder ***
:: ********************************

md Release >nul 2>&1

:: *****************************************************
:: *** Compile the RC file to create the object file ***
:: *****************************************************

pushd "%BLITZMAX_HOME%\MinGW32x86\bin"
windres.exe -i "%START_PATH%sidsample.rc" -o "%START_PATH%sidsample.o"
popd

:: ****************************
:: *** Build the executable ***
:: ****************************

"%BLITZMAX_HOME%\bin\bmk.exe" makeapp -a -r -t gui -o Release\sidsample_blitzmax_ng.exe sidsample_blitzmax_ng.bmx

:: **************************************
:: *** Cleanup the intermediate files ***
:: **************************************

del *.o

pause
