:: ***********************************
:: *** Set the PureBasic home path ***
:: ***********************************

set PUREBASIC_HOME=C:\Compilers\PureBasic

:: ********************************
:: *** Create the output folder ***
:: ********************************

md Release >nul 2>&1

:: **************************************************
:: *** Compile the RC file to create the RES file ***
:: **************************************************

"%PUREBASIC_HOME%\Compilers\porc" sidsample.rc

:: ****************************
:: *** Build the executable ***
:: ****************************

"%PUREBASIC_HOME%\Compilers\pbcompiler" /EXE Release\sidsample_purebasic.exe sidsample_purebasic.pb

:: **************************************
:: *** Cleanup the intermediate files ***
:: **************************************

del *.res

pause
