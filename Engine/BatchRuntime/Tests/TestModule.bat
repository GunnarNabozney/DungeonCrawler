@echo off

rem TestModule.bat
rem Reference module for BatchRuntime protocol 1.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=TestModule"
set "BRT.X.Manifest.Version=1.1.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=11"
set "BRT.X.Manifest.Export.1=Add"
set "BRT.X.Manifest.Export.2=Clamp"
set "BRT.X.Manifest.Export.3=MakePair"
set "BRT.X.Manifest.Export.4=SumPair"
set "BRT.X.Manifest.Export.5=NestedAdd"
set "BRT.X.Manifest.Export.6=ChooseColor"
set "BRT.X.Manifest.Export.7=BrokenReturn"
set "BRT.X.Manifest.Export.8=NestedFailure"
set "BRT.X.Manifest.Export.9=NestedBrokenReturn"
set "BRT.X.Manifest.Export.10=DeepNest"
set "BRT.X.Manifest.Export.11=LeakTemporary"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i "%~3"=="Add" goto :Describe.Add
if /i "%~3"=="Clamp" goto :Describe.Clamp
if /i "%~3"=="MakePair" goto :Describe.MakePair
if /i "%~3"=="SumPair" goto :Describe.SumPair
if /i "%~3"=="NestedAdd" goto :Describe.NestedAdd
if /i "%~3"=="ChooseColor" goto :Describe.ChooseColor
if /i "%~3"=="BrokenReturn" goto :Describe.BrokenReturn
if /i "%~3"=="NestedFailure" goto :Describe.NestedFailure
if /i "%~3"=="NestedBrokenReturn" goto :Describe.NestedBrokenReturn
if /i "%~3"=="DeepNest" goto :Describe.DeepNest
if /i "%~3"=="LeakTemporary" goto :Describe.LeakTemporary
exit /b 65

:Describe.Add
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Left"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Right"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Sum"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Clamp
set "BRT.X.Schema.Parameter.Count=3"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Minimum"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=0"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=1"
set "BRT.X.Schema.Parameter.2.Default=0"
set "BRT.X.Schema.Parameter.3.Name=Maximum"
set "BRT.X.Schema.Parameter.3.Type=Int"
set "BRT.X.Schema.Parameter.3.Required=0"
set "BRT.X.Schema.Parameter.3.Position=3"
set "BRT.X.Schema.Parameter.3.HasDefault=1"
set "BRT.X.Schema.Parameter.3.Default=100"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=WasClamped"
set "BRT.X.Schema.Return.2.Type=Bool"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.MakePair
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Left"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Right"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=Left"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.2.Name=Right"
set "BRT.X.Schema.Return.2.Type=Int"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.SumPair
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Pair"
set "BRT.X.Schema.Parameter.1.Type=Object"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.1.ObjectType=TestModule.MakePair.Result"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Sum"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.NestedAdd
call :Describe.Add
exit /b !errorlevel!

:Describe.ChooseColor
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Color"
set "BRT.X.Schema.Parameter.1.Type=Enum"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.1.Choices=Red,Green,Blue"
set "BRT.X.Schema.Parameter.2.Name=Bright"
set "BRT.X.Schema.Parameter.2.Type=Bool"
set "BRT.X.Schema.Parameter.2.Required=0"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=1"
set "BRT.X.Schema.Parameter.2.Default=false"
set "BRT.X.Schema.Return.Count=2"
set "BRT.X.Schema.Return.1.Name=Color"
set "BRT.X.Schema.Return.1.Type=Enum"
set "BRT.X.Schema.Return.1.Required=1"
set "BRT.X.Schema.Return.1.Choices=Red,Green,Blue"
set "BRT.X.Schema.Return.2.Name=Bright"
set "BRT.X.Schema.Return.2.Type=Bool"
set "BRT.X.Schema.Return.2.Required=1"
exit /b 0

:Describe.BrokenReturn
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=RequiredValue"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.NestedFailure
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Never"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.NestedBrokenReturn
call :Describe.NestedFailure
exit /b !errorlevel!

:Describe.DeepNest
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Depth"
set "BRT.X.Schema.Parameter.1.Type=UInt"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Sum"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.LeakTemporary
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Invoke
if /i "%~3"=="Add" goto :Invoke.Add
if /i "%~3"=="Clamp" goto :Invoke.Clamp
if /i "%~3"=="MakePair" goto :Invoke.MakePair
if /i "%~3"=="SumPair" goto :Invoke.SumPair
if /i "%~3"=="NestedAdd" goto :Invoke.NestedAdd
if /i "%~3"=="ChooseColor" goto :Invoke.ChooseColor
if /i "%~3"=="BrokenReturn" goto :Invoke.BrokenReturn
if /i "%~3"=="NestedFailure" goto :Invoke.NestedFailure
if /i "%~3"=="NestedBrokenReturn" goto :Invoke.NestedBrokenReturn
if /i "%~3"=="DeepNest" goto :Invoke.DeepNest
if /i "%~3"=="LeakTemporary" goto :Invoke.LeakTemporary
exit /b 65

:Invoke.Add
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
set /a Sum=Left+Right
endlocal & set "BRT.O.%ReturnObject%.Sum=%Sum%"
exit /b 0

:Invoke.Clamp
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
set "ClampedValue=!Value!"
set "WasClamped=0"
if !ClampedValue! LSS !Minimum! (
    set "ClampedValue=!Minimum!"
    set "WasClamped=1"
)
if !ClampedValue! GTR !Maximum! (
    set "ClampedValue=!Maximum!"
    set "WasClamped=1"
)
endlocal & (
    set "BRT.O.%ReturnObject%.Value=%ClampedValue%"
    set "BRT.O.%ReturnObject%.WasClamped=%WasClamped%"
)
exit /b 0

:Invoke.MakePair
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & (
    set "BRT.O.%ReturnObject%.Left=%Left%"
    set "BRT.O.%ReturnObject%.Right=%Right%"
)
exit /b 0

:Invoke.SumPair
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!BRT.Runtime!" :Object.Get "!Pair!" Left PairLeft
if errorlevel 1 goto :Invoke.FailRuntime
call "!BRT.Runtime!" :Object.Get "!Pair!" Right PairRight
if errorlevel 1 goto :Invoke.FailRuntime
set /a Sum=PairLeft+PairRight
endlocal & set "BRT.O.%ReturnObject%.Sum=%Sum%"
exit /b 0

:Invoke.NestedAdd
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
set "SelfAlias=!BRT.F.%Frame%.Module!"
call "!BRT.Runtime!" :Invoke "!SelfAlias!" Add InnerResult --Left "!Left!" --Right "!Right!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!BRT.Runtime!" :Object.Get "!InnerResult!" Sum NestedSum
if errorlevel 1 goto :Invoke.FailRuntime
call "!BRT.Runtime!" :Object.Release "!InnerResult!"
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & set "BRT.O.%ReturnObject%.Sum=%NestedSum%"
exit /b 0

:Invoke.ChooseColor
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & (
    set "BRT.O.%ReturnObject%.Color=%Color%"
    set "BRT.O.%ReturnObject%.Bright=%Bright%"
)
exit /b 0

:Invoke.BrokenReturn
exit /b 0

:Invoke.NestedFailure
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "SelfAlias=!BRT.F.%Frame%.Module!"
call "!BRT.Runtime!" :Invoke "!SelfAlias!" Add InnerResult --Left 1
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & exit /b 30

:Invoke.NestedBrokenReturn
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "SelfAlias=!BRT.F.%Frame%.Module!"
call "!BRT.Runtime!" :Invoke "!SelfAlias!" BrokenReturn InnerResult
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & exit /b 30

:Invoke.DeepNest
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
set "SelfAlias=!BRT.F.%Frame%.Module!"
if "!Depth!"=="0" (
    set "NestedSum=2"
) else (
    set /a NextDepth=Depth-1
    call "!BRT.Runtime!" :Invoke "!SelfAlias!" DeepNest InnerResult --Depth "!NextDepth!"
    if errorlevel 1 goto :Invoke.FailRuntime
    call "!BRT.Runtime!" :Object.Get "!InnerResult!" Sum NestedSum
    if errorlevel 1 goto :Invoke.FailRuntime
    call "!BRT.Runtime!" :Object.Release "!InnerResult!"
    if errorlevel 1 goto :Invoke.FailRuntime
)
endlocal & set "BRT.O.%ReturnObject%.Sum=%NestedSum%"
exit /b 0

:Invoke.LeakTemporary
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "SelfAlias=!BRT.F.%Frame%.Module!"
call "!BRT.Runtime!" :Invoke "!SelfAlias!" MakePair TemporaryObject --Left 20 --Right 22
if errorlevel 1 goto :Invoke.FailRuntime
endlocal & set "BRT.O.%ReturnObject%.Value=42"
exit /b 0

:Invoke.FailRuntime
call "!BRT.Runtime!" :ReturnError
set "FailureExit=!errorlevel!"
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRT.F.%Frame%.PropagatedError=1" & set "BRT.F.%Frame%.Error.Code=%BRT.ReturnError.Code%" & set "BRT.F.%Frame%.Error.Kind=%BRT.ReturnError.Kind%" & set "BRT.F.%Frame%.Error.Message=%BRT.ReturnError.Message%" & set "BRT.F.%Frame%.Error.Module=%BRT.ReturnError.Module%" & set "BRT.F.%Frame%.Error.Function=%BRT.ReturnError.Function%" & set "BRT.F.%Frame%.Error.Parameter=%BRT.ReturnError.Parameter%" & set "BRT.F.%Frame%.Error.Expected=%BRT.ReturnError.Expected%" & set "BRT.F.%Frame%.Error.Actual=%BRT.ReturnError.Actual%" & exit /b %FailureExit%
