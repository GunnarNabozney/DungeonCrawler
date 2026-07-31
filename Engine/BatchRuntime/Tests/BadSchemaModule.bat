@echo off

rem BadSchemaModule.bat
rem Deliberately invalid schemas used by BatchRuntime tests.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" exit /b 65
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=BadSchemaModule"
set "BRT.X.Manifest.Version=1.0.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=6"
set "BRT.X.Manifest.Export.1=DuplicateNames"
set "BRT.X.Manifest.Export.2=DuplicatePositions"
set "BRT.X.Manifest.Export.3=BadDefault"
set "BRT.X.Manifest.Export.4=EmptyEnum"
set "BRT.X.Manifest.Export.5=DuplicateEnum"
set "BRT.X.Manifest.Export.6=UnknownProperty"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i "%~3"=="DuplicateNames" goto :DuplicateNames
if /i "%~3"=="DuplicatePositions" goto :DuplicatePositions
if /i "%~3"=="BadDefault" goto :BadDefault
if /i "%~3"=="EmptyEnum" goto :EmptyEnum
if /i "%~3"=="DuplicateEnum" goto :DuplicateEnum
if /i "%~3"=="UnknownProperty" goto :UnknownProperty
exit /b 65

:BaseReturn
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:DuplicateNames
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Value"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
call :BaseReturn
exit /b 0

:DuplicatePositions
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Left"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Right"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=1"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
call :BaseReturn
exit /b 0

:BadDefault
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=0"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=1"
set "BRT.X.Schema.Parameter.1.Default=banana"
call :BaseReturn
exit /b 0

:EmptyEnum
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Color"
set "BRT.X.Schema.Parameter.1.Type=Enum"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.1.Choices="
call :BaseReturn
exit /b 0

:DuplicateEnum
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Color"
set "BRT.X.Schema.Parameter.1.Type=Enum"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.1.Choices=Red,Green,red"
call :BaseReturn
exit /b 0

:UnknownProperty
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.1.Mystery=1"
call :BaseReturn
exit /b 0
