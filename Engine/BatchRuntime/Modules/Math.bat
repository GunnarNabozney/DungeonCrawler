@echo off

rem Math.bat
rem Example BatchRuntime protocol 1 module.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=Math"
set "BRT.X.Manifest.Version=1.0.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=2"
set "BRT.X.Manifest.Export.1=Add"
set "BRT.X.Manifest.Export.2=Clamp"
exit /b 0

:Describe
if /i "%~3"=="Add" goto :Describe.Add
if /i "%~3"=="Clamp" goto :Describe.Clamp
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

:Invoke
if /i "%~3"=="Add" goto :Invoke.Add
if /i "%~3"=="Clamp" goto :Invoke.Clamp
exit /b 65

:Invoke.Add
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 (
    endlocal
    exit /b 30
)
set /a Sum=Left+Right
endlocal & set "BRT.O.%ReturnObject%.Sum=%Sum%"
exit /b 0

:Invoke.Clamp
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 (
    endlocal
    exit /b 30
)
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
