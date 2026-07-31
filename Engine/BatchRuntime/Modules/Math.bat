@echo off

rem Math.bat
rem Reusable arithmetic module for BatchRuntime protocol 1.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=Math"
set "BRT.X.Manifest.Version=1.1.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=3"
set "BRT.X.Manifest.Export.1=Add"
set "BRT.X.Manifest.Export.2=Clamp"
set "BRT.X.Manifest.Export.3=FloorDivide"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i "%~3"=="Add" goto :Describe.Add
if /i "%~3"=="Clamp" goto :Describe.Clamp
if /i "%~3"=="FloorDivide" goto :Describe.FloorDivide
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

:Describe.FloorDivide
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Dividend"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Divisor"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Quotient"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Invoke
if /i "%~3"=="Add" goto :Invoke.Add
if /i "%~3"=="Clamp" goto :Invoke.Clamp
if /i "%~3"=="FloorDivide" goto :Invoke.FloorDivide
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
if !Left! GTR 0 if !Right! GTR 0 if !Sum! LSS 0 (
    endlocal
    exit /b 30
)
if !Left! LSS 0 if !Right! LSS 0 if !Sum! GEQ 0 (
    endlocal
    exit /b 30
)
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

:Invoke.FloorDivide
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 (
    endlocal
    exit /b 30
)
if "!Divisor!"=="0" (
    endlocal
    exit /b 30
)
if "!Dividend!"=="-2147483648" if "!Divisor!"=="-1" (
    endlocal
    exit /b 30
)
set /a Quotient=Dividend/Divisor
set /a Remainder=Dividend%%Divisor
if not "!Remainder!"=="0" (
    if !Dividend! LSS 0 if !Divisor! GTR 0 set /a Quotient-=1
    if !Dividend! GTR 0 if !Divisor! LSS 0 set /a Quotient-=1
)
endlocal & set "BRT.O.%ReturnObject%.Quotient=%Quotient%"
exit /b 0
