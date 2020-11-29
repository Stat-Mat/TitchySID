:: ***********************************
:: *** Set the FreeBASIC home path ***
:: ***********************************

set FREEBASIC_HOME=C:\Compilers\FreeBASIC

:: ********************************
:: *** Create the output folder ***
:: ********************************

md Release >nul 2>&1

:: ****************************
:: *** Build the executable ***
:: ****************************

"%FREEBASIC_HOME%\fbc.exe" -s gui -x Release\sidsample_freebasic.exe sidsample.rc sidsample_freebasic.bas

pause
