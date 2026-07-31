@echo off

rem BatchRuntime.bat
rem Project-agnostic module/function runtime for Windows batch files.
rem Version 1.0.0 - protocol 1
rem Requirement: caller must enable command extensions and delayed expansion.

set "BRT.Internal.DelayedProbe=1"
if not "!BRT.Internal.DelayedProbe!"=="1" (
    echo BatchRuntime requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Import" goto :Import
if /i "%~1"==":Invoke" goto :Invoke
if /i "%~1"==":BindParameters" goto :BindParameters
if /i "%~1"==":Object.Get" goto :Object.Get
if /i "%~1"==":Object.Has" goto :Object.Has
if /i "%~1"==":Object.Release" goto :Object.Release
if /i "%~1"==":Object.Describe" goto :Object.Describe
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError
if /i "%~1"==":ListModules" goto :ListModules
if /i "%~1"==":Describe" goto :Describe
if /i "%~1"==":RuntimeInfo" goto :RuntimeInfo
if /i "%~1"==":GetStat" goto :GetStat

call :SetError 60 UnknownRuntimeCommand "Unknown BatchRuntime command: %~1" "" "" "" "Known runtime command" "%~1"
exit /b 60

:Initialize
if defined BRT.Initialized exit /b 0
for /f "tokens=1 delims==" %%V in ('set BRT. 2^>nul') do set "%%V="
set "BRT.Initialized=1"
set "BRT.Runtime=%~f0"
set "BRT.Version=1.0.0"
set "BRT.ProtocolVersion=1"
set "BRT.ObjectSequence=0"
set "BRT.FrameSequence=0"
set "BRT.ObjectCount=0"
set "BRT.FrameCount=0"
set "BRT.ModuleCount=0"
set "BRT.MaxDepth=32"
set "BRT.ActiveFrame=@NULL"
set "BRT.LastError=@NULL"
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
for /f "tokens=1 delims==" %%V in ('set BRT. 2^>nul') do set "%%V="
exit /b 0

:Import
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BRT.Internal.Alias=%~2"
set "BRT.Internal.ModulePath=%~f3"
call :ValidateId "!BRT.Internal.Alias!"
if errorlevel 1 (
    call :SetError 20 InvalidModuleAlias "Module alias must begin with a letter and contain only letters, digits, or underscores." "!BRT.Internal.Alias!" "" "Alias" "Identifier" "!BRT.Internal.Alias!"
    exit /b 20
)
if not exist "!BRT.Internal.ModulePath!" (
    call :SetError 30 ModuleNotFound "Module file was not found." "!BRT.Internal.Alias!" "" "Path" "Existing batch file" "!BRT.Internal.ModulePath!"
    exit /b 30
)
if defined BRT.M.!BRT.Internal.Alias!.Path (
    call :SetError 30 ModuleAlreadyImported "A module is already imported under this alias." "!BRT.Internal.Alias!" "" "Alias" "Unused alias" "!BRT.Internal.Alias!"
    exit /b 30
)
call :ClearPrefix "BRT.X.Manifest."
call "!BRT.Internal.ModulePath!" __BRT__ MANIFEST
set "BRT.Internal.ModuleExit=!errorlevel!"
if not "!BRT.Internal.ModuleExit!"=="0" (
    call :SetError 60 ModuleManifestFailed "The module did not provide a valid manifest." "!BRT.Internal.Alias!" "" "" "Protocol manifest" "Exit !BRT.Internal.ModuleExit!"
    exit /b 60
)
if not "!BRT.X.Manifest.ProtocolVersion!"=="1" (
    call :SetError 60 ProtocolVersionMismatch "The module protocol version is unsupported." "!BRT.Internal.Alias!" "" "ProtocolVersion" "1" "!BRT.X.Manifest.ProtocolVersion!"
    exit /b 60
)
call :ValidateId "!BRT.X.Manifest.Name!"
if errorlevel 1 (
    call :SetError 60 InvalidManifestName "The module manifest name is invalid." "!BRT.Internal.Alias!" "" "Name" "Identifier" "!BRT.X.Manifest.Name!"
    exit /b 60
)
call :ValidateUInt "!BRT.X.Manifest.Export.Count!"
if errorlevel 1 (
    call :SetError 60 InvalidExportCount "The module export count is invalid." "!BRT.Internal.Alias!" "" "Export.Count" "Unsigned integer" "!BRT.X.Manifest.Export.Count!"
    exit /b 60
)
if "!BRT.X.Manifest.Export.Count!"=="0" (
    call :SetError 60 EmptyModuleManifest "A module must export at least one function." "!BRT.Internal.Alias!" "" "Export.Count" "At least 1" "0"
    exit /b 60
)
set "BRT.Internal.ExportIndex=1"
:Import.ValidateExport
if !BRT.Internal.ExportIndex! GTR !BRT.X.Manifest.Export.Count! goto :Import.Commit
set "BRT.Internal.ExportName=!BRT.X.Manifest.Export.%BRT.Internal.ExportIndex%!"
call :ValidateId "!BRT.Internal.ExportName!"
if errorlevel 1 (
    call :SetError 60 InvalidExportName "The module manifest contains an invalid export name." "!BRT.Internal.Alias!" "" "Export" "Identifier" "!BRT.Internal.ExportName!"
    exit /b 60
)
set "BRT.Internal.DuplicateIndex=1"
:Import.CheckDuplicate
if !BRT.Internal.DuplicateIndex! GEQ !BRT.Internal.ExportIndex! goto :Import.NextExport
set "BRT.Internal.OtherExport=!BRT.X.Manifest.Export.%BRT.Internal.DuplicateIndex%!"
if /i "!BRT.Internal.OtherExport!"=="!BRT.Internal.ExportName!" (
    call :SetError 60 DuplicateExport "The module manifest contains a duplicate export." "!BRT.Internal.Alias!" "" "Export" "Unique export name" "!BRT.Internal.ExportName!"
    exit /b 60
)
set /a BRT.Internal.DuplicateIndex+=1
goto :Import.CheckDuplicate
:Import.NextExport
set /a BRT.Internal.ExportIndex+=1
goto :Import.ValidateExport
:Import.Commit
set "BRT.M.!BRT.Internal.Alias!.Path=!BRT.Internal.ModulePath!"
set "BRT.M.!BRT.Internal.Alias!.Name=!BRT.X.Manifest.Name!"
set "BRT.M.!BRT.Internal.Alias!.Version=!BRT.X.Manifest.Version!"
set "BRT.M.!BRT.Internal.Alias!.ProtocolVersion=!BRT.X.Manifest.ProtocolVersion!"
set "BRT.M.!BRT.Internal.Alias!.Export.Count=!BRT.X.Manifest.Export.Count!"
set "BRT.Internal.ExportIndex=1"
:Import.CopyExport
if !BRT.Internal.ExportIndex! GTR !BRT.X.Manifest.Export.Count! goto :Import.Finish
set "BRT.Internal.ExportName=!BRT.X.Manifest.Export.%BRT.Internal.ExportIndex%!"
set "BRT.M.!BRT.Internal.Alias!.Export.!BRT.Internal.ExportIndex!=!BRT.Internal.ExportName!"
set /a BRT.Internal.ExportIndex+=1
goto :Import.CopyExport
:Import.Finish
set /a BRT.ModuleCount+=1
set "BRT.Module.!BRT.ModuleCount!=!BRT.Internal.Alias!"
call :ClearPrefix "BRT.X.Manifest."
exit /b 0

:Invoke
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BRT.Internal.Invoke.Module=%~2"
set "BRT.Internal.Invoke.Function=%~3"
set "BRT.Internal.Invoke.OutputVar=%~4"
call :ValidateId "!BRT.Internal.Invoke.Module!"
if errorlevel 1 (
    call :SetError 10 InvalidModuleAlias "The invocation module alias is invalid." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "Module" "Identifier" "!BRT.Internal.Invoke.Module!"
    exit /b 10
)
call :ValidateId "!BRT.Internal.Invoke.Function!"
if errorlevel 1 (
    call :SetError 10 InvalidFunctionName "The invocation function name is invalid." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "Function" "Identifier" "!BRT.Internal.Invoke.Function!"
    exit /b 10
)
call :ValidateId "!BRT.Internal.Invoke.OutputVar!"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "The return-handle output variable name is invalid." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "OutputVariable" "Identifier" "!BRT.Internal.Invoke.OutputVar!"
    exit /b 10
)
set "BRT.Internal.Invoke.ModulePath=!BRT.M.%BRT.Internal.Invoke.Module%.Path!"
if not defined BRT.Internal.Invoke.ModulePath (
    call :SetError 30 ModuleNotImported "The requested module has not been imported." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "Module" "Imported module alias" "!BRT.Internal.Invoke.Module!"
    exit /b 30
)
call :FindExport "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!"
if not "!BRT.Internal.Found!"=="1" (
    call :SetError 30 FunctionNotExported "The requested function is not exported by the module." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "Function" "Exported function" "!BRT.Internal.Invoke.Function!"
    exit /b 30
)
call :LoadSchema "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!"
if errorlevel 1 exit /b !errorlevel!
call :CreateFrame "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!"
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Invoke.Frame=!BRT.Internal.Handle!"
call :CopySchemaToFrame "!BRT.Internal.Invoke.Frame!"
if errorlevel 1 goto :Invoke.FailProtocol
call :CreateReturnObject "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!"
if errorlevel 1 goto :Invoke.FailProtocol
set "BRT.Internal.Invoke.ReturnObject=!BRT.Internal.Handle!"
set "BRT.F.!BRT.Internal.Invoke.Frame!.ReturnObject=!BRT.Internal.Invoke.ReturnObject!"
shift
shift
shift
shift
set "BRT.Internal.Invoke.Position=1"
goto :Invoke.ParseNext

:Invoke.ParseNext
if "%~1"=="" goto :Invoke.ApplyDefaults
set "BRT.Internal.Invoke.Token=%~1"
if "!BRT.Internal.Invoke.Token:~0,2!"=="--" goto :Invoke.ParseNamed
goto :Invoke.ParsePositional

:Invoke.ParseNamed
set "BRT.Internal.Invoke.ParameterName=!BRT.Internal.Invoke.Token:~2!"
call :ValidateId "!BRT.Internal.Invoke.ParameterName!"
if errorlevel 1 goto :Invoke.FailUnknownParameter
call :FindParameterByName "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!"
if not "!BRT.Internal.Found!"=="1" goto :Invoke.FailUnknownParameter
if defined BRT.F.!BRT.Internal.Invoke.Frame!.P.!BRT.Internal.Invoke.ParameterName!.__Set goto :Invoke.FailDuplicateParameter
set "BRT.Internal.Invoke.ParameterType=!BRT.F.%BRT.Internal.Invoke.Frame%.P.%BRT.Internal.Invoke.ParameterName%.Type!"
if /i "!BRT.Internal.Invoke.ParameterType!"=="Bool" goto :Invoke.ParseBoolean
if "%~2"=="" goto :Invoke.FailMissingValue
set "BRT.Internal.Invoke.ParameterValue=%~2"
call :AssignParameter "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!" "!BRT.Internal.Invoke.ParameterValue!"
if errorlevel 1 goto :Invoke.FailValidation
shift
shift
goto :Invoke.ParseNext

:Invoke.ParseBoolean
if "%~2"=="" goto :Invoke.ParseBooleanBare
set "BRT.Internal.Invoke.NextToken=%~2"
if "!BRT.Internal.Invoke.NextToken:~0,2!"=="--" goto :Invoke.ParseBooleanBare
set "BRT.Internal.Invoke.ParameterValue=%~2"
call :AssignParameter "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!" "!BRT.Internal.Invoke.ParameterValue!"
if errorlevel 1 goto :Invoke.FailValidation
shift
shift
goto :Invoke.ParseNext
:Invoke.ParseBooleanBare
set "BRT.Internal.Invoke.ParameterValue=true"
call :AssignParameter "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!" "true"
if errorlevel 1 goto :Invoke.FailValidation
shift
goto :Invoke.ParseNext

:Invoke.ParsePositional
call :FindParameterByPosition "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.Position!"
if not "!BRT.Internal.Found!"=="1" goto :Invoke.FailTooManyPositionals
set "BRT.Internal.Invoke.ParameterName=!BRT.Internal.ParameterName!"
if defined BRT.F.!BRT.Internal.Invoke.Frame!.P.!BRT.Internal.Invoke.ParameterName!.__Set goto :Invoke.FailDuplicateParameter
set "BRT.Internal.Invoke.ParameterValue=%~1"
call :AssignParameter "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!" "!BRT.Internal.Invoke.ParameterValue!"
if errorlevel 1 goto :Invoke.FailValidation
set /a BRT.Internal.Invoke.Position+=1
shift
goto :Invoke.ParseNext

:Invoke.ApplyDefaults
set "BRT.Internal.Invoke.Index=1"
set "BRT.Internal.Invoke.Count=!BRT.F.%BRT.Internal.Invoke.Frame%.Parameter.Count!"
:Invoke.ApplyDefaultNext
if !BRT.Internal.Invoke.Index! GTR !BRT.Internal.Invoke.Count! goto :Invoke.CallModule
set "BRT.Internal.Invoke.ParameterName=!BRT.F.%BRT.Internal.Invoke.Frame%.Parameter.%BRT.Internal.Invoke.Index%.Name!"
if defined BRT.F.!BRT.Internal.Invoke.Frame!.P.!BRT.Internal.Invoke.ParameterName!.__Set goto :Invoke.ApplyDefaultAdvance
set "BRT.Internal.Invoke.HasDefault=!BRT.F.%BRT.Internal.Invoke.Frame%.P.%BRT.Internal.Invoke.ParameterName%.HasDefault!"
if "!BRT.Internal.Invoke.HasDefault!"=="1" goto :Invoke.UseDefault
set "BRT.Internal.Invoke.Required=!BRT.F.%BRT.Internal.Invoke.Frame%.P.%BRT.Internal.Invoke.ParameterName%.Required!"
if "!BRT.Internal.Invoke.Required!"=="1" goto :Invoke.FailRequired
set "BRT.F.!BRT.Internal.Invoke.Frame!.P.!BRT.Internal.Invoke.ParameterName!=@NULL"
set "BRT.F.!BRT.Internal.Invoke.Frame!.P.!BRT.Internal.Invoke.ParameterName!.__Set=1"
goto :Invoke.ApplyDefaultAdvance
:Invoke.UseDefault
set "BRT.Internal.Invoke.ParameterValue=!BRT.F.%BRT.Internal.Invoke.Frame%.P.%BRT.Internal.Invoke.ParameterName%.Default!"
call :AssignParameter "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ParameterName!" "!BRT.Internal.Invoke.ParameterValue!"
if errorlevel 1 goto :Invoke.FailProtocol
:Invoke.ApplyDefaultAdvance
set /a BRT.Internal.Invoke.Index+=1
goto :Invoke.ApplyDefaultNext

:Invoke.CallModule
set "BRT.ActiveFrame=!BRT.Internal.Invoke.Frame!"
call "!BRT.Internal.Invoke.ModulePath!" __BRT__ INVOKE "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.Frame!" "!BRT.Internal.Invoke.ReturnObject!"
set "BRT.Internal.Invoke.ModuleExit=!errorlevel!"
set "BRT.ActiveFrame=!BRT.F.%BRT.Internal.Invoke.Frame%.ParentFrame!"
if not "!BRT.Internal.Invoke.ModuleExit!"=="0" goto :Invoke.FailModule
call :ValidateReturnObject "!BRT.Internal.Invoke.ReturnObject!"
if errorlevel 1 goto :Invoke.FailReturn
set "BRT.O.!BRT.Internal.Invoke.ReturnObject!.__Sealed=1"
set "!BRT.Internal.Invoke.OutputVar!=!BRT.Internal.Invoke.ReturnObject!"
call :ReleaseFrame "!BRT.Internal.Invoke.Frame!"
call :ClearPrefix "BRT.X.Schema."
exit /b 0

:Invoke.FailUnknownParameter
call :SetError 20 UnknownParameter "The function schema does not contain the supplied named parameter." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.ParameterName!" "Declared parameter" "!BRT.Internal.Invoke.ParameterName!"
goto :Invoke.Cleanup20
:Invoke.FailDuplicateParameter
call :SetError 20 DuplicateParameter "A parameter was supplied more than once." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.ParameterName!" "One value" "Duplicate value"
goto :Invoke.Cleanup20
:Invoke.FailMissingValue
call :SetError 20 MissingParameterValue "A named parameter requires a value." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.ParameterName!" "Parameter value" "Missing"
goto :Invoke.Cleanup20
:Invoke.FailTooManyPositionals
call :SetError 20 TooManyPositionalArguments "The function received more positional arguments than its schema allows." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "Position" "Declared position" "!BRT.Internal.Invoke.Position!"
goto :Invoke.Cleanup20
:Invoke.FailRequired
call :SetError 20 MissingRequiredParameter "A required parameter was not supplied." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.ParameterName!" "Required value" "Missing"
goto :Invoke.Cleanup20
:Invoke.FailValidation
if "!BRT.LastError!"=="@NULL" call :SetError 20 InvalidParameterValue "A parameter value failed validation." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "!BRT.Internal.Invoke.ParameterName!" "Valid value" "!BRT.Internal.Invoke.ParameterValue!"
goto :Invoke.Cleanup20
:Invoke.FailProtocol
if "!BRT.LastError!"=="@NULL" call :SetError 60 InvalidFunctionSchema "The module supplied an invalid function schema." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "" "Valid schema" "Invalid schema"
goto :Invoke.Cleanup60
:Invoke.FailModule
if "!BRT.LastError!"=="@NULL" call :SetError 30 ModuleInvocationFailed "The module function returned a nonzero exit code." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "" "Exit 0" "Exit !BRT.Internal.Invoke.ModuleExit!"
goto :Invoke.Cleanup30
:Invoke.FailReturn
if "!BRT.LastError!"=="@NULL" call :SetError 40 InvalidReturnObject "The module returned an invalid object." "!BRT.Internal.Invoke.Module!" "!BRT.Internal.Invoke.Function!" "" "Valid return object" "Invalid return object"
goto :Invoke.Cleanup40
:Invoke.Cleanup20
call :ReleaseObjectInternal "!BRT.Internal.Invoke.ReturnObject!"
call :ReleaseFrame "!BRT.Internal.Invoke.Frame!"
call :ClearPrefix "BRT.X.Schema."
exit /b 20
:Invoke.Cleanup30
call :ReleaseObjectInternal "!BRT.Internal.Invoke.ReturnObject!"
call :ReleaseFrame "!BRT.Internal.Invoke.Frame!"
call :ClearPrefix "BRT.X.Schema."
exit /b 30
:Invoke.Cleanup40
call :ReleaseObjectInternal "!BRT.Internal.Invoke.ReturnObject!"
call :ReleaseFrame "!BRT.Internal.Invoke.Frame!"
call :ClearPrefix "BRT.X.Schema."
exit /b 40
:Invoke.Cleanup60
call :ReleaseObjectInternal "!BRT.Internal.Invoke.ReturnObject!"
call :ReleaseFrame "!BRT.Internal.Invoke.Frame!"
call :ClearPrefix "BRT.X.Schema."
exit /b 60

:BindParameters
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Bind.Frame=%~2"
if not "!BRT.F.%BRT.Internal.Bind.Frame%.__Exists!"=="1" (
    call :SetError 50 InvalidFrame "The supplied call frame does not exist." "" "" "Frame" "Active frame handle" "!BRT.Internal.Bind.Frame!"
    exit /b 50
)
set "BRT.Internal.Bind.Count=!BRT.F.%BRT.Internal.Bind.Frame%.Parameter.Count!"
set "BRT.Internal.Bind.Index=1"
:BindParameters.Next
if !BRT.Internal.Bind.Index! GTR !BRT.Internal.Bind.Count! exit /b 0
set "BRT.Internal.Bind.Name=!BRT.F.%BRT.Internal.Bind.Frame%.Parameter.%BRT.Internal.Bind.Index%.Name!"
set "BRT.Internal.Bind.Value=!BRT.F.%BRT.Internal.Bind.Frame%.P.%BRT.Internal.Bind.Name%!"
set "!BRT.Internal.Bind.Name!=!BRT.Internal.Bind.Value!"
set /a BRT.Internal.Bind.Index+=1
goto :BindParameters.Next

:Object.Get
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Object=%~2"
set "BRT.Internal.Field=%~3"
set "BRT.Internal.OutputVar=%~4"
call :ValidateId "!BRT.Internal.Field!"
if errorlevel 1 (
    call :SetError 50 InvalidFieldName "The requested object field name is invalid." "" "" "!BRT.Internal.Field!" "Identifier" "!BRT.Internal.Field!"
    exit /b 50
)
call :ValidateId "!BRT.Internal.OutputVar!"
if errorlevel 1 (
    call :SetError 50 InvalidOutputVariable "The object output variable name is invalid." "" "" "!BRT.Internal.OutputVar!" "Identifier" "!BRT.Internal.OutputVar!"
    exit /b 50
)
if not "!BRT.O.%BRT.Internal.Object%.__Exists!"=="1" (
    call :SetError 50 ObjectNotFound "The requested object handle does not exist." "" "" "Object" "Existing object handle" "!BRT.Internal.Object!"
    exit /b 50
)
if not "!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Field%.Declared!"=="1" (
    call :SetError 50 ObjectFieldNotFound "The requested field is not declared on this object." "" "" "!BRT.Internal.Field!" "Declared field" "!BRT.Internal.Field!"
    exit /b 50
)
set "!BRT.Internal.OutputVar!=!BRT.O.%BRT.Internal.Object%.%BRT.Internal.Field%!"
exit /b 0

:Object.Has
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Object=%~2"
set "BRT.Internal.Field=%~3"
set "BRT.Internal.OutputVar=%~4"
call :ValidateId "!BRT.Internal.OutputVar!"
if errorlevel 1 (
    call :SetError 50 InvalidOutputVariable "The object presence output variable name is invalid." "" "" "!BRT.Internal.OutputVar!" "Identifier" "!BRT.Internal.OutputVar!"
    exit /b 50
)
set "!BRT.Internal.OutputVar!=0"
if "!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Field%.Declared!"=="1" set "!BRT.Internal.OutputVar!=1"
exit /b 0

:Object.Release
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Object=%~2"
if not "!BRT.O.%BRT.Internal.Object%.__Exists!"=="1" (
    call :SetError 50 ObjectNotFound "The requested object handle does not exist." "" "" "Object" "Existing object handle" "!BRT.Internal.Object!"
    exit /b 50
)
call :ReleaseObjectInternal "!BRT.Internal.Object!"
exit /b 0

:Object.Describe
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Object=%~2"
if not "!BRT.O.%BRT.Internal.Object%.__Exists!"=="1" (
    call :SetError 50 ObjectNotFound "The requested object handle does not exist." "" "" "Object" "Existing object handle" "!BRT.Internal.Object!"
    exit /b 50
)
echo Object: !BRT.Internal.Object!
echo Type: !BRT.O.%BRT.Internal.Object%.__Type!
echo Sealed: !BRT.O.%BRT.Internal.Object%.__Sealed!
set "BRT.Internal.Count=!BRT.O.%BRT.Internal.Object%.__Field.Count!"
set "BRT.Internal.Index=1"
:Object.Describe.Next
if !BRT.Internal.Index! GTR !BRT.Internal.Count! exit /b 0
set "BRT.Internal.Name=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Index%.Name!"
set "BRT.Internal.FieldType=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Name%.Type!"
set "BRT.Internal.Value=!BRT.O.%BRT.Internal.Object%.%BRT.Internal.Name%!"
echo   !BRT.Internal.Name! [!BRT.Internal.FieldType!] = !BRT.Internal.Value!
set /a BRT.Internal.Index+=1
goto :Object.Describe.Next

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
if "!BRT.LastError!"=="@NULL" (
    echo No BatchRuntime error is currently recorded.
    exit /b 0
)
echo BatchRuntime error !BRT.O.%BRT.LastError%.Code! [!BRT.O.%BRT.LastError%.Kind!]
echo   Message: !BRT.O.%BRT.LastError%.Message!
if defined BRT.O.%BRT.LastError%.Module echo   Module: !BRT.O.%BRT.LastError%.Module!
if defined BRT.O.%BRT.LastError%.Function echo   Function: !BRT.O.%BRT.LastError%.Function!
if defined BRT.O.%BRT.LastError%.Parameter echo   Parameter: !BRT.O.%BRT.LastError%.Parameter!
if defined BRT.O.%BRT.LastError%.Expected echo   Expected: !BRT.O.%BRT.LastError%.Expected!
if defined BRT.O.%BRT.LastError%.Actual echo   Actual: !BRT.O.%BRT.LastError%.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:ListModules
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
if "!BRT.ModuleCount!"=="0" (
    echo No modules imported.
    exit /b 0
)
set "BRT.Internal.Index=1"
:ListModules.Next
if !BRT.Internal.Index! GTR !BRT.ModuleCount! exit /b 0
set "BRT.Internal.Alias=!BRT.Module.%BRT.Internal.Index%!"
echo !BRT.Internal.Alias! - !BRT.M.%BRT.Internal.Alias%.Name! !BRT.M.%BRT.Internal.Alias%.Version!
set /a BRT.Internal.Index+=1
goto :ListModules.Next

:Describe
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
set "BRT.Internal.Describe.Module=%~2"
set "BRT.Internal.Describe.Function=%~3"
call :LoadSchema "!BRT.Internal.Describe.Module!" "!BRT.Internal.Describe.Function!"
if errorlevel 1 exit /b !errorlevel!
echo !BRT.Internal.Describe.Module!.!BRT.Internal.Describe.Function!
echo Parameters:
set "BRT.Internal.Index=1"
:Describe.ParameterNext
if !BRT.Internal.Index! GTR !BRT.X.Schema.Parameter.Count! goto :Describe.Returns
set "BRT.Internal.Name=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Type=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Type!"
set "BRT.Internal.Required=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Required!"
set "BRT.Internal.Position=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Position!"
set "BRT.Internal.HasDefault=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.HasDefault!"
set "BRT.Internal.Detail=Optional"
if "!BRT.Internal.Required!"=="1" set "BRT.Internal.Detail=Required"
if "!BRT.Internal.HasDefault!"=="1" set "BRT.Internal.Detail=Default !BRT.X.Schema.Parameter.%BRT.Internal.Index%.Default!"
echo   !BRT.Internal.Name! [!BRT.Internal.Type!] !BRT.Internal.Detail! Position !BRT.Internal.Position!
set /a BRT.Internal.Index+=1
goto :Describe.ParameterNext
:Describe.Returns
echo Returns:
set "BRT.Internal.Index=1"
:Describe.ReturnNext
if !BRT.Internal.Index! GTR !BRT.X.Schema.Return.Count! goto :Describe.Finish
set "BRT.Internal.Name=!BRT.X.Schema.Return.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Type=!BRT.X.Schema.Return.%BRT.Internal.Index%.Type!"
set "BRT.Internal.Required=!BRT.X.Schema.Return.%BRT.Internal.Index%.Required!"
set "BRT.Internal.Detail=Optional"
if "!BRT.Internal.Required!"=="1" set "BRT.Internal.Detail=Required"
echo   !BRT.Internal.Name! [!BRT.Internal.Type!] !BRT.Internal.Detail!
set /a BRT.Internal.Index+=1
goto :Describe.ReturnNext
:Describe.Finish
call :ClearPrefix "BRT.X.Schema."
exit /b 0

:RuntimeInfo
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
echo BatchRuntime !BRT.Version!
echo Protocol: !BRT.ProtocolVersion!
echo Modules: !BRT.ModuleCount!
echo Objects: !BRT.ObjectCount!
echo Frames: !BRT.FrameCount!
echo Maximum call depth: !BRT.MaxDepth!
exit /b 0

:GetStat
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRT.Internal.Stat=%~2"
set "BRT.Internal.OutputVar=%~3"
call :ValidateId "!BRT.Internal.OutputVar!"
if errorlevel 1 (
    call :SetError 50 InvalidOutputVariable "The statistics output variable name is invalid." "" "" "!BRT.Internal.OutputVar!" "Identifier" "!BRT.Internal.OutputVar!"
    exit /b 50
)
if /i "!BRT.Internal.Stat!"=="ObjectCount" (
    set "!BRT.Internal.OutputVar!=!BRT.ObjectCount!"
    exit /b 0
)
if /i "!BRT.Internal.Stat!"=="FrameCount" (
    set "!BRT.Internal.OutputVar!=!BRT.FrameCount!"
    exit /b 0
)
if /i "!BRT.Internal.Stat!"=="ModuleCount" (
    set "!BRT.Internal.OutputVar!=!BRT.ModuleCount!"
    exit /b 0
)
call :SetError 50 UnknownStatistic "The requested runtime statistic is unknown." "" "" "Statistic" "ObjectCount, FrameCount, or ModuleCount" "!BRT.Internal.Stat!"
exit /b 50

:RequireInitialized
if defined BRT.Initialized exit /b 0
call :SetError 50 RuntimeNotInitialized "BatchRuntime must be initialized before this command is used." "" "" "Runtime" "Initialized runtime" "Not initialized"
exit /b 50

:LoadSchema
set "BRT.Internal.Schema.Module=%~1"
set "BRT.Internal.Schema.Function=%~2"
set "BRT.Internal.Schema.ModulePath=!BRT.M.%BRT.Internal.Schema.Module%.Path!"
if not defined BRT.Internal.Schema.ModulePath (
    call :SetError 30 ModuleNotImported "The requested module has not been imported." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "Module" "Imported module alias" "!BRT.Internal.Schema.Module!"
    exit /b 30
)
call :FindExport "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!"
if not "!BRT.Internal.Found!"=="1" (
    call :SetError 30 FunctionNotExported "The requested function is not exported by the module." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "Function" "Exported function" "!BRT.Internal.Schema.Function!"
    exit /b 30
)
call :ClearPrefix "BRT.X.Schema."
call "!BRT.Internal.Schema.ModulePath!" __BRT__ DESCRIBE "!BRT.Internal.Schema.Function!"
set "BRT.Internal.Schema.Exit=!errorlevel!"
if not "!BRT.Internal.Schema.Exit!"=="0" (
    call :SetError 60 SchemaRequestFailed "The module did not describe the exported function." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "" "Function schema" "Exit !BRT.Internal.Schema.Exit!"
    exit /b 60
)
call :ValidateSchema "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!"
exit /b !errorlevel!

:ValidateSchema
set "BRT.Internal.Schema.Module=%~1"
set "BRT.Internal.Schema.Function=%~2"
call :ValidateUInt "!BRT.X.Schema.Parameter.Count!"
if errorlevel 1 goto :ValidateSchema.BadParameterCount
call :ValidateUInt "!BRT.X.Schema.Return.Count!"
if errorlevel 1 goto :ValidateSchema.BadReturnCount
if "!BRT.X.Schema.Return.Count!"=="0" goto :ValidateSchema.BadReturnCount
set "BRT.Internal.Index=1"
:ValidateSchema.ParameterNext
if !BRT.Internal.Index! GTR !BRT.X.Schema.Parameter.Count! goto :ValidateSchema.Returns
set "BRT.Internal.Name=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Type=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Type!"
set "BRT.Internal.Required=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Required!"
set "BRT.Internal.Position=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Position!"
set "BRT.Internal.HasDefault=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.HasDefault!"
call :ValidateId "!BRT.Internal.Name!"
if errorlevel 1 goto :ValidateSchema.BadParameter
call :ValidateTypeName "!BRT.Internal.Type!"
if errorlevel 1 goto :ValidateSchema.BadParameter
call :ValidateBool "!BRT.Internal.Required!"
if errorlevel 1 goto :ValidateSchema.BadParameter
call :ValidateUInt "!BRT.Internal.Position!"
if errorlevel 1 goto :ValidateSchema.BadParameter
if "!BRT.Internal.Position!"=="0" goto :ValidateSchema.BadParameter
if not defined BRT.Internal.HasDefault set "BRT.X.Schema.Parameter.!BRT.Internal.Index!.HasDefault=0"
if defined BRT.Internal.HasDefault (
    call :ValidateBool "!BRT.Internal.HasDefault!"
    if errorlevel 1 goto :ValidateSchema.BadParameter
)
set /a BRT.Internal.Index+=1
goto :ValidateSchema.ParameterNext
:ValidateSchema.Returns
set "BRT.Internal.Index=1"
:ValidateSchema.ReturnNext
if !BRT.Internal.Index! GTR !BRT.X.Schema.Return.Count! exit /b 0
set "BRT.Internal.Name=!BRT.X.Schema.Return.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Type=!BRT.X.Schema.Return.%BRT.Internal.Index%.Type!"
set "BRT.Internal.Required=!BRT.X.Schema.Return.%BRT.Internal.Index%.Required!"
call :ValidateId "!BRT.Internal.Name!"
if errorlevel 1 goto :ValidateSchema.BadReturn
call :ValidateTypeName "!BRT.Internal.Type!"
if errorlevel 1 goto :ValidateSchema.BadReturn
call :ValidateBool "!BRT.Internal.Required!"
if errorlevel 1 goto :ValidateSchema.BadReturn
set /a BRT.Internal.Index+=1
goto :ValidateSchema.ReturnNext
:ValidateSchema.BadParameterCount
call :SetError 60 InvalidParameterCount "The function schema parameter count is invalid." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "Parameter.Count" "Unsigned integer" "!BRT.X.Schema.Parameter.Count!"
exit /b 60
:ValidateSchema.BadReturnCount
call :SetError 60 InvalidReturnCount "The function schema return count is invalid." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "Return.Count" "At least one return field" "!BRT.X.Schema.Return.Count!"
exit /b 60
:ValidateSchema.BadParameter
call :SetError 60 InvalidParameterSchema "A function parameter schema entry is invalid." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "!BRT.Internal.Name!" "Valid parameter schema" "Invalid parameter schema"
exit /b 60
:ValidateSchema.BadReturn
call :SetError 60 InvalidReturnSchema "A function return schema entry is invalid." "!BRT.Internal.Schema.Module!" "!BRT.Internal.Schema.Function!" "!BRT.Internal.Name!" "Valid return schema" "Invalid return schema"
exit /b 60

:CopySchemaToFrame
set "BRT.Internal.Frame=%~1"
set "BRT.F.!BRT.Internal.Frame!.Parameter.Count=!BRT.X.Schema.Parameter.Count!"
set "BRT.Internal.Index=1"
:CopySchemaToFrame.Next
if !BRT.Internal.Index! GTR !BRT.X.Schema.Parameter.Count! exit /b 0
set "BRT.Internal.Name=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.Name!"
set "BRT.F.!BRT.Internal.Frame!.Parameter.!BRT.Internal.Index!.Name=!BRT.Internal.Name!"
for %%P in (Type Required Position HasDefault Default Choices ObjectType) do set "BRT.F.!BRT.Internal.Frame!.P.!BRT.Internal.Name!.%%P=!BRT.X.Schema.Parameter.%BRT.Internal.Index%.%%P!"
set /a BRT.Internal.Index+=1
goto :CopySchemaToFrame.Next

:CreateReturnObject
set "BRT.Internal.Module=%~1"
set "BRT.Internal.Function=%~2"
set "BRT.Internal.CanonicalModule=!BRT.M.%BRT.Internal.Module%.Name!"
call :CreateObject "!BRT.Internal.CanonicalModule!.!BRT.Internal.Function!.Result"
set "BRT.Internal.ReturnObject=!BRT.Internal.Handle!"
set "BRT.O.!BRT.Internal.ReturnObject!.__Field.Count=!BRT.X.Schema.Return.Count!"
set "BRT.Internal.Index=1"
:CreateReturnObject.Next
if !BRT.Internal.Index! GTR !BRT.X.Schema.Return.Count! (
    set "BRT.Internal.Handle=!BRT.Internal.ReturnObject!"
    exit /b 0
)
set "BRT.Internal.Name=!BRT.X.Schema.Return.%BRT.Internal.Index%.Name!"
set "BRT.O.!BRT.Internal.ReturnObject!.__Field.!BRT.Internal.Index!.Name=!BRT.Internal.Name!"
set "BRT.O.!BRT.Internal.ReturnObject!.__Field.!BRT.Internal.Name!.Declared=1"
for %%P in (Type Required Choices ObjectType) do set "BRT.O.!BRT.Internal.ReturnObject!.__Field.!BRT.Internal.Name!.%%P=!BRT.X.Schema.Return.%BRT.Internal.Index%.%%P!"
set /a BRT.Internal.Index+=1
goto :CreateReturnObject.Next

:ValidateReturnObject
set "BRT.Internal.Object=%~1"
set "BRT.Internal.Count=!BRT.O.%BRT.Internal.Object%.__Field.Count!"
set "BRT.Internal.Index=1"
:ValidateReturnObject.Next
if !BRT.Internal.Index! GTR !BRT.Internal.Count! exit /b 0
set "BRT.Internal.Name=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Required=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Name%.Required!"
if not defined BRT.O.!BRT.Internal.Object!.!BRT.Internal.Name! goto :ValidateReturnObject.Missing
set "BRT.Internal.Value=!BRT.O.%BRT.Internal.Object%.%BRT.Internal.Name%!"
set "BRT.Internal.Type=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Name%.Type!"
set "BRT.Internal.Choices=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Name%.Choices!"
set "BRT.Internal.ObjectType=!BRT.O.%BRT.Internal.Object%.__Field.%BRT.Internal.Name%.ObjectType!"
call :ValidateValue "!BRT.Internal.Type!" "!BRT.Internal.Value!" "!BRT.Internal.Choices!" "!BRT.Internal.ObjectType!"
if errorlevel 1 (
    call :SetError 40 InvalidReturnField "A return field failed type validation." "" "" "!BRT.Internal.Name!" "!BRT.Internal.Type!" "!BRT.Internal.Value!"
    exit /b 40
)
set "BRT.O.!BRT.Internal.Object!.!BRT.Internal.Name!=!BRT.Internal.Normalized!"
goto :ValidateReturnObject.Advance
:ValidateReturnObject.Missing
if "!BRT.Internal.Required!"=="1" (
    call :SetError 40 MissingReturnField "A required return field was not set by the module." "" "" "!BRT.Internal.Name!" "Required return value" "Missing"
    exit /b 40
)
set "BRT.O.!BRT.Internal.Object!.!BRT.Internal.Name!=@NULL"
:ValidateReturnObject.Advance
set /a BRT.Internal.Index+=1
goto :ValidateReturnObject.Next

:AssignParameter
set "BRT.Internal.Frame=%~1"
set "BRT.Internal.Name=%~2"
set "BRT.Internal.Value=%~3"
set "BRT.Internal.Type=!BRT.F.%BRT.Internal.Frame%.P.%BRT.Internal.Name%.Type!"
set "BRT.Internal.Choices=!BRT.F.%BRT.Internal.Frame%.P.%BRT.Internal.Name%.Choices!"
set "BRT.Internal.ObjectType=!BRT.F.%BRT.Internal.Frame%.P.%BRT.Internal.Name%.ObjectType!"
call :ValidateValue "!BRT.Internal.Type!" "!BRT.Internal.Value!" "!BRT.Internal.Choices!" "!BRT.Internal.ObjectType!"
if errorlevel 1 (
    call :SetError 20 InvalidParameterType "A parameter value failed type validation." "" "" "!BRT.Internal.Name!" "!BRT.Internal.Type!" "!BRT.Internal.Value!"
    exit /b 20
)
set "BRT.F.!BRT.Internal.Frame!.P.!BRT.Internal.Name!=!BRT.Internal.Normalized!"
set "BRT.F.!BRT.Internal.Frame!.P.!BRT.Internal.Name!.__Set=1"
exit /b 0

:ValidateValue
set "BRT.Internal.Type=%~1"
set "BRT.Internal.Value=%~2"
set "BRT.Internal.Choices=%~3"
set "BRT.Internal.ObjectType=%~4"
set "BRT.Internal.Normalized=!BRT.Internal.Value!"
if /i "!BRT.Internal.Type!"=="Int" goto :ValidateValue.Int
if /i "!BRT.Internal.Type!"=="UInt" goto :ValidateValue.UInt
if /i "!BRT.Internal.Type!"=="Bool" goto :ValidateValue.Bool
if /i "!BRT.Internal.Type!"=="Id" goto :ValidateValue.Id
if /i "!BRT.Internal.Type!"=="Enum" goto :ValidateValue.Enum
if /i "!BRT.Internal.Type!"=="Object" goto :ValidateValue.Object
exit /b 1
:ValidateValue.Int
call :ValidateInt "!BRT.Internal.Value!"
exit /b !errorlevel!
:ValidateValue.UInt
call :ValidateUInt "!BRT.Internal.Value!"
exit /b !errorlevel!
:ValidateValue.Bool
call :NormalizeBool "!BRT.Internal.Value!"
if errorlevel 1 exit /b 1
set "BRT.Internal.Normalized=!BRT.Internal.Bool!"
exit /b 0
:ValidateValue.Id
call :ValidateId "!BRT.Internal.Value!"
exit /b !errorlevel!
:ValidateValue.Enum
if not defined BRT.Internal.Choices exit /b 1
for %%C in (!BRT.Internal.Choices:|= !) do (
    if /i "%%~C"=="!BRT.Internal.Value!" (
        set "BRT.Internal.Normalized=%%~C"
        exit /b 0
    )
)
exit /b 1
:ValidateValue.Object
call :ValidateObjectHandle "!BRT.Internal.Value!"
if errorlevel 1 exit /b 1
if not defined BRT.Internal.ObjectType exit /b 0
set "BRT.Internal.ActualType=!BRT.O.%BRT.Internal.Value%.__Type!"
if /i not "!BRT.Internal.ActualType!"=="!BRT.Internal.ObjectType!" exit /b 1
exit /b 0

:FindExport
set "BRT.Internal.Found=0"
set "BRT.Internal.Module=%~1"
set "BRT.Internal.Function=%~2"
set "BRT.Internal.Count=!BRT.M.%BRT.Internal.Module%.Export.Count!"
if not defined BRT.Internal.Count exit /b 0
set "BRT.Internal.Index=1"
:FindExport.Next
if !BRT.Internal.Index! GTR !BRT.Internal.Count! exit /b 0
set "BRT.Internal.Name=!BRT.M.%BRT.Internal.Module%.Export.%BRT.Internal.Index%!"
if /i "!BRT.Internal.Name!"=="!BRT.Internal.Function!" (
    set "BRT.Internal.Found=1"
    exit /b 0
)
set /a BRT.Internal.Index+=1
goto :FindExport.Next

:FindParameterByName
set "BRT.Internal.Found=0"
set "BRT.Internal.Frame=%~1"
set "BRT.Internal.SearchName=%~2"
set "BRT.Internal.Count=!BRT.F.%BRT.Internal.Frame%.Parameter.Count!"
set "BRT.Internal.Index=1"
:FindParameterByName.Next
if !BRT.Internal.Index! GTR !BRT.Internal.Count! exit /b 0
set "BRT.Internal.Name=!BRT.F.%BRT.Internal.Frame%.Parameter.%BRT.Internal.Index%.Name!"
if /i "!BRT.Internal.Name!"=="!BRT.Internal.SearchName!" (
    set "BRT.Internal.Found=1"
    set "BRT.Internal.ParameterName=!BRT.Internal.Name!"
    exit /b 0
)
set /a BRT.Internal.Index+=1
goto :FindParameterByName.Next

:FindParameterByPosition
set "BRT.Internal.Found=0"
set "BRT.Internal.Frame=%~1"
set "BRT.Internal.SearchPosition=%~2"
set "BRT.Internal.Count=!BRT.F.%BRT.Internal.Frame%.Parameter.Count!"
set "BRT.Internal.Index=1"
:FindParameterByPosition.Next
if !BRT.Internal.Index! GTR !BRT.Internal.Count! exit /b 0
set "BRT.Internal.Name=!BRT.F.%BRT.Internal.Frame%.Parameter.%BRT.Internal.Index%.Name!"
set "BRT.Internal.Position=!BRT.F.%BRT.Internal.Frame%.P.%BRT.Internal.Name%.Position!"
if "!BRT.Internal.Position!"=="!BRT.Internal.SearchPosition!" (
    set "BRT.Internal.Found=1"
    set "BRT.Internal.ParameterName=!BRT.Internal.Name!"
    exit /b 0
)
set /a BRT.Internal.Index+=1
goto :FindParameterByPosition.Next

:CreateObject
set /a BRT.ObjectSequence+=1
set "BRT.Internal.Padded=000000!BRT.ObjectSequence!"
set "BRT.Internal.Handle=O!BRT.Internal.Padded:~-6!"
set "BRT.O.!BRT.Internal.Handle!.__Exists=1"
set "BRT.O.!BRT.Internal.Handle!.__Type=%~1"
set "BRT.O.!BRT.Internal.Handle!.__Sealed=0"
set "BRT.O.!BRT.Internal.Handle!.__Field.Count=0"
set /a BRT.ObjectCount+=1
exit /b 0

:CreateFrame
set /a BRT.FrameSequence+=1
set "BRT.Internal.Padded=000000!BRT.FrameSequence!"
set "BRT.Internal.Handle=F!BRT.Internal.Padded:~-6!"
call :GetFrameDepth "!BRT.ActiveFrame!"
set /a BRT.Internal.Depth+=1
if !BRT.Internal.Depth! GTR !BRT.MaxDepth! (
    call :SetError 50 MaximumCallDepthExceeded "The maximum BatchRuntime call depth was exceeded." "%~1" "%~2" "Depth" "!BRT.MaxDepth!" "!BRT.Internal.Depth!"
    exit /b 50
)
set "BRT.F.!BRT.Internal.Handle!.__Exists=1"
set "BRT.F.!BRT.Internal.Handle!.Module=%~1"
set "BRT.F.!BRT.Internal.Handle!.Function=%~2"
set "BRT.F.!BRT.Internal.Handle!.ParentFrame=!BRT.ActiveFrame!"
set "BRT.F.!BRT.Internal.Handle!.Depth=!BRT.Internal.Depth!"
set /a BRT.FrameCount+=1
exit /b 0

:GetFrameDepth
set "BRT.Internal.Parent=%~1"
if "!BRT.Internal.Parent!"=="@NULL" (
    set "BRT.Internal.Depth=0"
    exit /b 0
)
set "BRT.Internal.Depth=!BRT.F.%BRT.Internal.Parent%.Depth!"
if not defined BRT.Internal.Depth set "BRT.Internal.Depth=0"
exit /b 0

:ReleaseFrame
set "BRT.Internal.Frame=%~1"
if not defined BRT.Internal.Frame exit /b 0
if not "!BRT.F.%BRT.Internal.Frame%.__Exists!"=="1" exit /b 0
call :ClearPrefix "BRT.F.!BRT.Internal.Frame!."
set /a BRT.FrameCount-=1
exit /b 0

:ReleaseObjectInternal
set "BRT.Internal.Object=%~1"
if not defined BRT.Internal.Object exit /b 0
if not "!BRT.O.%BRT.Internal.Object%.__Exists!"=="1" exit /b 0
call :ClearPrefix "BRT.O.!BRT.Internal.Object!."
set /a BRT.ObjectCount-=1
if "!BRT.LastError!"=="!BRT.Internal.Object!" set "BRT.LastError=@NULL"
exit /b 0

:ClearLastErrorInternal
if not defined BRT.LastError set "BRT.LastError=@NULL"
if "!BRT.LastError!"=="@NULL" exit /b 0
call :ReleaseObjectInternal "!BRT.LastError!"
set "BRT.LastError=@NULL"
exit /b 0

:SetError
if defined BRT.Initialized call :ClearLastErrorInternal
if not defined BRT.ObjectSequence set "BRT.ObjectSequence=0"
if not defined BRT.ObjectCount set "BRT.ObjectCount=0"
call :CreateObject "BatchRuntime.Error"
set "BRT.LastError=!BRT.Internal.Handle!"
set "BRT.O.!BRT.LastError!.__Field.Count=8"
set "BRT.Internal.Index=1"
for %%F in (Code Kind Message Module Function Parameter Expected Actual) do (
    set "BRT.O.!BRT.LastError!.__Field.!BRT.Internal.Index!.Name=%%F"
    set "BRT.O.!BRT.LastError!.__Field.%%F.Declared=1"
    set /a BRT.Internal.Index+=1
)
set "BRT.O.!BRT.LastError!.Code=%~1"
set "BRT.O.!BRT.LastError!.Kind=%~2"
set "BRT.O.!BRT.LastError!.Message=%~3"
set "BRT.O.!BRT.LastError!.Module=%~4"
set "BRT.O.!BRT.LastError!.Function=%~5"
set "BRT.O.!BRT.LastError!.Parameter=%~6"
set "BRT.O.!BRT.LastError!.Expected=%~7"
set "BRT.O.!BRT.LastError!.Actual=%~8"
set "BRT.O.!BRT.LastError!.__Sealed=1"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0

:ValidateTypeName
if /i "%~1"=="Int" exit /b 0
if /i "%~1"=="UInt" exit /b 0
if /i "%~1"=="Bool" exit /b 0
if /i "%~1"=="Id" exit /b 0
if /i "%~1"=="Enum" exit /b 0
if /i "%~1"=="Object" exit /b 0
exit /b 1

:ValidateId
set "BRT.Internal.Test=%~1"
if not defined BRT.Internal.Test exit /b 1
set "BRT.Internal.First=!BRT.Internal.Test:~0,1!"
set "BRT.Internal.Work=!BRT.Internal.First!"
for %%C in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "BRT.Internal.Work=!BRT.Internal.Work:%%C=!"
if defined BRT.Internal.Work exit /b 1
set "BRT.Internal.Work=!BRT.Internal.Test!"
for %%C in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 _) do set "BRT.Internal.Work=!BRT.Internal.Work:%%C=!"
if defined BRT.Internal.Work exit /b 1
exit /b 0

:ValidateInt
set "BRT.Internal.Work=%~1"
if not defined BRT.Internal.Work exit /b 1
if "!BRT.Internal.Work:~0,1!"=="-" set "BRT.Internal.Work=!BRT.Internal.Work:~1!"
if not defined BRT.Internal.Work exit /b 1
for %%C in (0 1 2 3 4 5 6 7 8 9) do set "BRT.Internal.Work=!BRT.Internal.Work:%%C=!"
if defined BRT.Internal.Work exit /b 1
exit /b 0

:ValidateUInt
set "BRT.Internal.Work=%~1"
if not defined BRT.Internal.Work exit /b 1
for %%C in (0 1 2 3 4 5 6 7 8 9) do set "BRT.Internal.Work=!BRT.Internal.Work:%%C=!"
if defined BRT.Internal.Work exit /b 1
exit /b 0

:ValidateBool
call :NormalizeBool "%~1"
exit /b !errorlevel!

:NormalizeBool
set "BRT.Internal.Bool="
if /i "%~1"=="1" (
    set "BRT.Internal.Bool=1"
    exit /b 0
)
if /i "%~1"=="true" (
    set "BRT.Internal.Bool=1"
    exit /b 0
)
if /i "%~1"=="yes" (
    set "BRT.Internal.Bool=1"
    exit /b 0
)
if /i "%~1"=="on" (
    set "BRT.Internal.Bool=1"
    exit /b 0
)
if /i "%~1"=="0" (
    set "BRT.Internal.Bool=0"
    exit /b 0
)
if /i "%~1"=="false" (
    set "BRT.Internal.Bool=0"
    exit /b 0
)
if /i "%~1"=="no" (
    set "BRT.Internal.Bool=0"
    exit /b 0
)
if /i "%~1"=="off" (
    set "BRT.Internal.Bool=0"
    exit /b 0
)
exit /b 1

:ValidateObjectHandle
set "BRT.Internal.Object=%~1"
if not defined BRT.Internal.Object exit /b 1
if /i not "!BRT.Internal.Object:~0,1!"=="O" exit /b 1
if not "!BRT.O.%BRT.Internal.Object%.__Exists!"=="1" exit /b 1
exit /b 0
