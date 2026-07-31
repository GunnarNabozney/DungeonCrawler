@echo off

rem Random.bat
rem BatchRuntime adapter for the standalone BatchRandom component.
rem Version 1.0.0 - BatchRuntime protocol 1.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=Random"
set "BRT.X.Manifest.Version=1.0.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=9"
set "BRT.X.Manifest.Export.1=Initialize"
set "BRT.X.Manifest.Export.2=Reseed"
set "BRT.X.Manifest.Export.3=Next"
set "BRT.X.Manifest.Export.4=Integer"
set "BRT.X.Manifest.Export.5=Chance"
set "BRT.X.Manifest.Export.6=Roll"
set "BRT.X.Manifest.Export.7=ChooseIndex"
set "BRT.X.Manifest.Export.8=GetState"
set "BRT.X.Manifest.Export.9=Restore"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i "%~3"=="Initialize" goto :Describe.Initialize
if /i "%~3"=="Reseed" goto :Describe.Reseed
if /i "%~3"=="Next" goto :Describe.Next
if /i "%~3"=="Integer" goto :Describe.Integer
if /i "%~3"=="Chance" goto :Describe.Chance
if /i "%~3"=="Roll" goto :Describe.Roll
if /i "%~3"=="ChooseIndex" goto :Describe.ChooseIndex
if /i "%~3"=="GetState" goto :Describe.GetState
if /i "%~3"=="Restore" goto :Describe.Restore
exit /b 65

:Describe.Initialize
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Seed"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=State"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=DrawCount"
set "BRT.X.Schema.Return.2.Type=UInt"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.Reseed
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Seed"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=State"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=DrawCount"
set "BRT.X.Schema.Return.2.Type=UInt"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.Next
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Integer
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Minimum"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Maximum"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Chance
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Percent"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Hit"
set "BRT.X.Schema.Return.1.Type=Bool"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Roll
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Count"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Sides"
set "BRT.X.Schema.Parameter.2.Type=UInt"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Total"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.ChooseIndex
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Count"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Index"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.GetState
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=State"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=DrawCount"
set "BRT.X.Schema.Return.2.Type=UInt"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.Restore
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=State"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=DrawCount"
set "BRT.X.Schema.Parameter.2.Type=UInt"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=State"
set "BRT.X.Schema.Return.1.Type=UInt"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=DrawCount"
set "BRT.X.Schema.Return.2.Type=UInt"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Invoke
if /i "%~3"=="Initialize" goto :Invoke.Initialize
if /i "%~3"=="Reseed" goto :Invoke.Reseed
if /i "%~3"=="Next" goto :Invoke.Next
if /i "%~3"=="Integer" goto :Invoke.Integer
if /i "%~3"=="Chance" goto :Invoke.Chance
if /i "%~3"=="Roll" goto :Invoke.Roll
if /i "%~3"=="ChooseIndex" goto :Invoke.ChooseIndex
if /i "%~3"=="GetState" goto :Invoke.GetState
if /i "%~3"=="Restore" goto :Invoke.Restore
exit /b 65

:Invoke.Initialize
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Initialize"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Initialize "!Seed!"
if errorlevel 1 goto :Invoke.FailRandom
set "StateValue=!BRNG.State!"
set "DrawCountValue=!BRNG.DrawCount!"
set "Result1Name=State"
set "Result1Value=!StateValue!"
set "Result2Name=DrawCount"
set "Result2Value=!DrawCountValue!"
goto :Invoke.Success2

:Invoke.Reseed
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Reseed"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Reseed "!Seed!"
if errorlevel 1 goto :Invoke.FailRandom
set "StateValue=!BRNG.State!"
set "DrawCountValue=!BRNG.DrawCount!"
set "Result1Name=State"
set "Result1Value=!StateValue!"
set "Result2Name=DrawCount"
set "Result2Value=!DrawCountValue!"
goto :Invoke.Success2

:Invoke.Next
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Next"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Next Value
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=Value"
set "Result1Value=!Value!"
goto :Invoke.Success1

:Invoke.Integer
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Integer"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Integer "!Minimum!" "!Maximum!" Value
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=Value"
set "Result1Value=!Value!"
goto :Invoke.Success1

:Invoke.Chance
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Chance"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Chance "!Percent!" Hit
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=Hit"
set "Result1Value=!Hit!"
goto :Invoke.Success1

:Invoke.Roll
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Roll"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Roll "!Count!" "!Sides!" Total
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=Total"
set "Result1Value=!Total!"
goto :Invoke.Success1

:Invoke.ChooseIndex
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=ChooseIndex"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :ChooseIndex "!Count!" Index
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=Index"
set "Result1Value=!Index!"
goto :Invoke.Success1

:Invoke.GetState
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=GetState"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :GetState StateValue DrawCountValue
if errorlevel 1 goto :Invoke.FailRandom
set "Result1Name=State"
set "Result1Value=!StateValue!"
set "Result2Name=DrawCount"
set "Result2Value=!DrawCountValue!"
goto :Invoke.Success2

:Invoke.Restore
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Restore"
set "RandomComponent=%~dp0..\..\BatchRandom\BatchRandom.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!RandomComponent!" :Restore "!State!" "!DrawCount!"
if errorlevel 1 goto :Invoke.FailRandom
set "StateValue=!BRNG.State!"
set "DrawCountValue=!BRNG.DrawCount!"
set "Result1Name=State"
set "Result1Value=!StateValue!"
set "Result2Name=DrawCount"
set "Result2Value=!DrawCountValue!"
goto :Invoke.Success2

:Invoke.Success1
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRNG.Initialized=%BRNG.Initialized%" & set "BRNG.Version=%BRNG.Version%" & set "BRNG.Protocol=%BRNG.Protocol%" & set "BRNG.Algorithm=%BRNG.Algorithm%" & set "BRNG.State=%BRNG.State%" & set "BRNG.DrawCount=%BRNG.DrawCount%" & set "BRNG.LastError.Code=%BRNG.LastError.Code%" & set "BRNG.LastError.Kind=%BRNG.LastError.Kind%" & set "BRNG.LastError.Message=%BRNG.LastError.Message%" & set "BRNG.LastError.Operation=%BRNG.LastError.Operation%" & set "BRNG.LastError.Parameter=%BRNG.LastError.Parameter%" & set "BRNG.LastError.Expected=%BRNG.LastError.Expected%" & set "BRNG.LastError.Actual=%BRNG.LastError.Actual%" & set "BRT.O.%ReturnObject%.%Result1Name%=%Result1Value%"
exit /b 0

:Invoke.Success2
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRNG.Initialized=%BRNG.Initialized%" & set "BRNG.Version=%BRNG.Version%" & set "BRNG.Protocol=%BRNG.Protocol%" & set "BRNG.Algorithm=%BRNG.Algorithm%" & set "BRNG.State=%BRNG.State%" & set "BRNG.DrawCount=%BRNG.DrawCount%" & set "BRNG.LastError.Code=%BRNG.LastError.Code%" & set "BRNG.LastError.Kind=%BRNG.LastError.Kind%" & set "BRNG.LastError.Message=%BRNG.LastError.Message%" & set "BRNG.LastError.Operation=%BRNG.LastError.Operation%" & set "BRNG.LastError.Parameter=%BRNG.LastError.Parameter%" & set "BRNG.LastError.Expected=%BRNG.LastError.Expected%" & set "BRNG.LastError.Actual=%BRNG.LastError.Actual%" & set "BRT.O.%ReturnObject%.%Result1Name%=%Result1Value%" & set "BRT.O.%ReturnObject%.%Result2Name%=%Result2Value%"
exit /b 0

:Invoke.FailRandom
set "FailureExit=!errorlevel!"
set "FailureCode=!BRNG.LastError.Code!"
set "FailureKind=!BRNG.LastError.Kind!"
set "FailureMessage=!BRNG.LastError.Message!"
set "FailureParameter=!BRNG.LastError.Parameter!"
set "FailureExpected=!BRNG.LastError.Expected!"
set "FailureActual=!BRNG.LastError.Actual!"
set "FailureModule=!BRT.F.%Frame%.Module!"
set "FailureFunction=!Function!"
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRNG.Initialized=%BRNG.Initialized%" & set "BRNG.Version=%BRNG.Version%" & set "BRNG.Protocol=%BRNG.Protocol%" & set "BRNG.Algorithm=%BRNG.Algorithm%" & set "BRNG.State=%BRNG.State%" & set "BRNG.DrawCount=%BRNG.DrawCount%" & set "BRNG.LastError.Code=%BRNG.LastError.Code%" & set "BRNG.LastError.Kind=%BRNG.LastError.Kind%" & set "BRNG.LastError.Message=%BRNG.LastError.Message%" & set "BRNG.LastError.Operation=%BRNG.LastError.Operation%" & set "BRNG.LastError.Parameter=%BRNG.LastError.Parameter%" & set "BRNG.LastError.Expected=%BRNG.LastError.Expected%" & set "BRNG.LastError.Actual=%BRNG.LastError.Actual%" & set "BRT.F.%Frame%.PropagatedError=1" & set "BRT.F.%Frame%.Error.Code=%FailureCode%" & set "BRT.F.%Frame%.Error.Kind=%FailureKind%" & set "BRT.F.%Frame%.Error.Message=%FailureMessage%" & set "BRT.F.%Frame%.Error.Module=%FailureModule%" & set "BRT.F.%Frame%.Error.Function=%FailureFunction%" & set "BRT.F.%Frame%.Error.Parameter=%FailureParameter%" & set "BRT.F.%Frame%.Error.Expected=%FailureExpected%" & set "BRT.F.%Frame%.Error.Actual=%FailureActual%" & exit /b %FailureExit%

:Invoke.FailRuntime
call "!BRT.Runtime!" :ReturnError
set "FailureExit=!errorlevel!"
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRT.F.%Frame%.PropagatedError=1" & set "BRT.F.%Frame%.Error.Code=%BRT.ReturnError.Code%" & set "BRT.F.%Frame%.Error.Kind=%BRT.ReturnError.Kind%" & set "BRT.F.%Frame%.Error.Message=%BRT.ReturnError.Message%" & set "BRT.F.%Frame%.Error.Module=%BRT.ReturnError.Module%" & set "BRT.F.%Frame%.Error.Function=%BRT.ReturnError.Function%" & set "BRT.F.%Frame%.Error.Parameter=%BRT.ReturnError.Parameter%" & set "BRT.F.%Frame%.Error.Expected=%BRT.ReturnError.Expected%" & set "BRT.F.%Frame%.Error.Actual=%BRT.ReturnError.Actual%" & exit /b %FailureExit%
