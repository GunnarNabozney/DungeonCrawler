@echo off

rem MissingDependencyModule.bat

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=MissingDependencyModule"
set "BRT.X.Manifest.Version=1.0.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=1"
set "BRT.X.Manifest.Export.1=Ready"
set "BRT.X.Manifest.Dependency.Count=1"
set "BRT.X.Manifest.Dependency.1=NotImported"
exit /b 0

:Describe
if /i not "%~3"=="Ready" exit /b 65
set "BRT.X.Schema.Parameter.Count=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Ready"
set "BRT.X.Schema.Return.1.Type=Bool"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Invoke
if /i not "%~3"=="Ready" exit /b 65
setlocal EnableExtensions EnableDelayedExpansion
set "ReturnObject=%~5"
endlocal & set "BRT.O.%ReturnObject%.Ready=1"
exit /b 0
