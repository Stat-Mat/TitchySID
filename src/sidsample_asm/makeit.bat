:: ********************************
:: *** Set the MASM32 home path ***
:: ********************************

set MASM_HOME=c:\masm32

:: ********************************
:: *** Create the output folder ***
:: ********************************

md Release >nul 2>&1

:: *****************************************************
:: *** Compile the RC file to create the object file ***
:: *****************************************************

"%MASM_HOME%\bin\rc" sidsample.rc

:: ****************************
:: *** Build the executable ***
:: ****************************

"%MASM_HOME%\bin\ml.exe" /c /coff /Cp /nologo sidsample.asm
"%MASM_HOME%\bin\polink" /OPT:NOWIN98 /OUT:"Release\sidsample_asm.exe" /SUBSYSTEM:WINDOWS sidsample.obj sidsample.res

:: **************************************
:: *** Cleanup the intermediate files ***
:: **************************************

del *.obj
del *.res

pause
