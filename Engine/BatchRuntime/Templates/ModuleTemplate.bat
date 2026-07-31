@echo off

rem ModuleTemplate.bat
rem Copy this file, rename the module and function, then expand the schema.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=ExampleModule"
set "BRT.X.Manifest.Version=1.1.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=1"
set "BRT.X.Manifest.Export.1=EchoInt"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i not "%~3"=="EchoInt" exit /b 65
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Invoke
if /i not "%~3"=="EchoInt" exit /b 65
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 (
    endlocal
    exit /b 30
)
endlocal & set "BRT.O.%ReturnObject%.Value=%Value%"
exit /b 0
