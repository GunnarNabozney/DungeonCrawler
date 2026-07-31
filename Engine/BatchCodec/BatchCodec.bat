@echo off

rem BatchCodec.bat
rem Project-agnostic deterministic serialization for Windows batch components.
rem Version 1.0.0 - protocol 1.
rem Requirement: caller must enable command extensions and delayed expansion.
rem
rem Format contract:
rem - BATCHCODEC version 1 is canonical ASCII with CRLF line endings.
rem - Metadata is UTF-8 percent escaped; payload bytes are canonical Base64.
rem - SHA-256 covers the canonical header and record body.
rem - Registry values, object fields, and text records own copied payload bytes.
rem - SaveData documents may contain every record category.
rem - Stored payload content never enters a CMD variable or command line.

set "BC.Internal.DelayedProbe=1"
if not "!BC.Internal.DelayedProbe!"=="1" (
    echo BatchCodec requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="encode" goto :Readable.Encode
if /i "%~1"=="decode" goto :Readable.Decode
if /i "%~1"=="escape" goto :Readable.Escape
if /i "%~1"=="unescape" goto :Readable.Unescape
if /i "%~1"=="release" goto :Readable.Release
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="clear" goto :Readable.Clear

if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":CreateDocument" goto :CreateDocument
if /i "%~1"==":AddRegistryValue" goto :AddRegistryValue
if /i "%~1"==":AddObject" goto :AddObject
if /i "%~1"==":AddObjectField" goto :AddObjectField
if /i "%~1"==":AddText" goto :AddText
if /i "%~1"==":Encode" goto :Encode
if /i "%~1"==":Decode" goto :Decode
if /i "%~1"==":GetRegistryValue" goto :GetRegistryValue
if /i "%~1"==":GetObjectType" goto :GetObjectType
if /i "%~1"==":GetObjectField" goto :GetObjectField
if /i "%~1"==":GetText" goto :GetText
if /i "%~1"==":Escape" goto :Escape
if /i "%~1"==":Unescape" goto :Unescape
if /i "%~1"==":GetDocumentInfo" goto :GetDocumentInfo
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":Release" goto :Release
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :SetError 10 UnknownCodecCommand "Unknown BatchCodec command." Command "Known BatchCodec command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="codec" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="codec" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Create
set "BC.Internal.Readable.Kind="
if /i "%~2"=="save-data" set "BC.Internal.Readable.Kind=SaveData"
if /i "%~2"=="registry" set "BC.Internal.Readable.Kind=Registry"
if /i "%~2"=="object" set "BC.Internal.Readable.Kind=Object"
if /i "%~2"=="text-bundle" set "BC.Internal.Readable.Kind=TextBundle"
if not defined BC.Internal.Readable.Kind goto :Readable.Syntax
if /i not "%~3"=="into" goto :Readable.Syntax
call "%~f0" :CreateDocument "!BC.Internal.Readable.Kind!" "%~4"
exit /b !errorlevel!

:Readable.Encode
if /i not "%~3"=="to" goto :Readable.Syntax
call "%~f0" :Encode "%~2" "%~4"
exit /b !errorlevel!

:Readable.Decode
if /i not "%~3"=="into" goto :Readable.Syntax
call "%~f0" :Decode "%~2" "%~4"
exit /b !errorlevel!

:Readable.Escape
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Escape "%~3" "%~5"
exit /b !errorlevel!

:Readable.Unescape
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :Unescape "%~3" "%~5"
exit /b !errorlevel!

:Readable.Release
if /i not "%~2"=="document" goto :Readable.Syntax
call "%~f0" :Release "%~3"
exit /b !errorlevel!

:Readable.Show
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :PrintLastError
exit /b !errorlevel!

:Readable.Read
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Clear
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :ClearLastError
exit /b !errorlevel!

:Readable.Syntax
call :SetError 10 InvalidCodecSyntax "BatchCodec command syntax is invalid." Syntax "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BC.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :ClearPrefix "BC."
set "BC.Validator=%~dp0..\BatchValidate\BatchValidate.bat"
set "BC.Text=%~dp0..\BatchText\BatchText.bat"
set "BC.Helper=%~dp0BatchCodecOps.ps1"
set "BC.PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "!BC.Validator!" (
    call :SetError 50 ValidationDependencyMissing "BatchValidate is required by BatchCodec." Initialize Dependency "Existing BatchValidate component" "Missing"
    exit /b 50
)
if not exist "!BC.Text!" (
    call :SetError 50 TextDependencyMissing "BatchText is required by BatchCodec." Initialize Dependency "Existing BatchText component" "Missing"
    exit /b 50
)
if not exist "!BC.Helper!" (
    call :SetError 50 CodecHelperMissing "The BatchCodec helper script is missing." Initialize Dependency "Existing BatchCodecOps.ps1" "Missing"
    exit /b 50
)
if not exist "!BC.PowerShell!" (
    call :SetError 50 PowerShellUnavailable "Windows PowerShell 5.1 is required by BatchCodec." Initialize Dependency "Windows PowerShell executable" "Missing"
    exit /b 50
)
set "BC.Root=%TEMP%\BatchCodec-!RANDOM!-!RANDOM!-!RANDOM!"
2>nul mkdir "!BC.Root!"
if errorlevel 1 (
    call :SetError 50 CodecStoreCreationFailed "BatchCodec could not create its temporary store." Initialize Store "Writable temporary directory" "Creation failed"
    exit /b 50
)
set "BC.OwnsText=0"
if not defined BTX.Initialized (
    call "!BC.Text!" :Initialize
    set "BC.Internal.TextInitExit=!errorlevel!"
    if not "!BC.Internal.TextInitExit!"=="0" (
        rmdir /s /q "!BC.Root!" >nul 2>nul
        call :SetError 50 TextInitializationFailed "BatchCodec could not initialize BatchText." Initialize Dependency "Initialized BatchText" "Exit !BC.Internal.TextInitExit!"
        exit /b 50
    )
    set "BC.OwnsText=1"
)
set "BC.Initialized=1"
set "BC.Version=1.0.0"
set "BC.Protocol=1"
set "BC.FormatVersion=1"
set "BC.Document.Sequence=0"
set "BC.Document.Count=0"
set "BC.Temp.Sequence=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ShutdownOwnsText=!BC.OwnsText!"
set "BC.Internal.ShutdownText=!BC.Text!"
if defined BC.Root if exist "!BC.Root!\" rmdir /s /q "!BC.Root!" >nul 2>nul
if "!BC.Internal.ShutdownOwnsText!"=="1" if defined BTX.Initialized call "!BC.Internal.ShutdownText!" :Shutdown >nul 2>nul
call :ClearPrefix "BC."
exit /b 0

:CreateDocument
call :BeginOperation CreateDocument
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" CreateDocument
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Create.Output=!BC.Internal.PreparedOutput!"
call :PrepareKind "%~2" CreateDocument Kind
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Create.Kind=!BC.Internal.PreparedKind!"
call :AllocateDocumentInternal "!BC.Internal.Create.Kind!"
if errorlevel 1 exit /b !errorlevel!
for %%O in ("!BC.Internal.Create.Output!") do set "%%~O=!BC.Internal.NewDocument!"
exit /b 0

:AddRegistryValue
call :BeginOperation AddRegistryValue
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" AddRegistryValue Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddRegistry.Document=!BC.Internal.PreparedDocument!"
call :RequireRecordKind "!BC.Internal.AddRegistry.Document!" R AddRegistryValue
if errorlevel 1 exit /b !errorlevel!
call :PrepareIdentifier "%~3" AddRegistryValue Registry
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddRegistry.Registry=!BC.Internal.PreparedIdentifier!"
call :PrepareDottedIdentifier "%~4" AddRegistryValue Key
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddRegistry.Key=!BC.Internal.PreparedDotted!"
call :PrepareIdentifier "%~5" AddRegistryValue Type
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddRegistry.Type=!BC.Internal.PreparedIdentifier!"
if defined BC.D.!BC.Internal.AddRegistry.Document!.R.!BC.Internal.AddRegistry.Registry!.!BC.Internal.AddRegistry.Key!.Exists (
    call :SetError 30 RegistryValueAlreadyExists "The document already contains this registry value." AddRegistryValue Key "Unused registry and key pair" "Duplicate"
    exit /b 30
)
call :CopyTextPayload "!BC.Internal.AddRegistry.Document!" "%~6" AddRegistryValue Value
if errorlevel 1 exit /b !errorlevel!
call :IncrementDocumentCounter "!BC.Internal.AddRegistry.Document!" RegistryValue.Count
set "BC.Internal.AddRegistry.Index=!BC.Internal.CounterValue!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.Index.!BC.Internal.AddRegistry.Index!.Registry=!BC.Internal.AddRegistry.Registry!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.Index.!BC.Internal.AddRegistry.Index!.Key=!BC.Internal.AddRegistry.Key!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.Index.!BC.Internal.AddRegistry.Index!.Type=!BC.Internal.AddRegistry.Type!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.Index.!BC.Internal.AddRegistry.Index!.Payload=!BC.Internal.CopiedPayloadName!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.!BC.Internal.AddRegistry.Registry!.!BC.Internal.AddRegistry.Key!.Exists=1"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.!BC.Internal.AddRegistry.Registry!.!BC.Internal.AddRegistry.Key!.Type=!BC.Internal.AddRegistry.Type!"
set "BC.D.!BC.Internal.AddRegistry.Document!.R.!BC.Internal.AddRegistry.Registry!.!BC.Internal.AddRegistry.Key!.Path=!BC.Internal.CopiedPayloadPath!"
exit /b 0

:AddObject
call :BeginOperation AddObject
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" AddObject Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddObject.Document=!BC.Internal.PreparedDocument!"
call :RequireRecordKind "!BC.Internal.AddObject.Document!" O AddObject
if errorlevel 1 exit /b !errorlevel!
call :PrepareIdentifier "%~3" AddObject Object
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddObject.Name=!BC.Internal.PreparedIdentifier!"
call :PrepareTypeId "%~4" AddObject TypeId
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddObject.TypeId=!BC.Internal.PreparedTypeId!"
if defined BC.D.!BC.Internal.AddObject.Document!.O.!BC.Internal.AddObject.Name!.Exists (
    call :SetError 30 ObjectAlreadyExists "The document already contains this object." AddObject Object "Unused object name" "Duplicate"
    exit /b 30
)
call :IncrementDocumentCounter "!BC.Internal.AddObject.Document!" Object.Count
set "BC.Internal.AddObject.Index=!BC.Internal.CounterValue!"
set "BC.D.!BC.Internal.AddObject.Document!.O.Index.!BC.Internal.AddObject.Index!.Name=!BC.Internal.AddObject.Name!"
set "BC.D.!BC.Internal.AddObject.Document!.O.Index.!BC.Internal.AddObject.Index!.TypeId=!BC.Internal.AddObject.TypeId!"
set "BC.D.!BC.Internal.AddObject.Document!.O.!BC.Internal.AddObject.Name!.Exists=1"
set "BC.D.!BC.Internal.AddObject.Document!.O.!BC.Internal.AddObject.Name!.TypeId=!BC.Internal.AddObject.TypeId!"
exit /b 0

:AddObjectField
call :BeginOperation AddObjectField
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" AddObjectField Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddField.Document=!BC.Internal.PreparedDocument!"
call :RequireRecordKind "!BC.Internal.AddField.Document!" F AddObjectField
if errorlevel 1 exit /b !errorlevel!
call :PrepareIdentifier "%~3" AddObjectField Object
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddField.Object=!BC.Internal.PreparedIdentifier!"
if not defined BC.D.!BC.Internal.AddField.Document!.O.!BC.Internal.AddField.Object!.Exists (
    call :SetError 30 ObjectNotFound "The object receiving the field does not exist in this document." AddObjectField Object "Existing object record" "Missing"
    exit /b 30
)
call :PrepareIdentifier "%~4" AddObjectField Field
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddField.Field=!BC.Internal.PreparedIdentifier!"
call :PrepareIdentifier "%~5" AddObjectField Type
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddField.Type=!BC.Internal.PreparedIdentifier!"
if defined BC.D.!BC.Internal.AddField.Document!.F.!BC.Internal.AddField.Object!.!BC.Internal.AddField.Field!.Exists (
    call :SetError 30 ObjectFieldAlreadyExists "The document already contains this object field." AddObjectField Field "Unused object and field pair" "Duplicate"
    exit /b 30
)
call :CopyTextPayload "!BC.Internal.AddField.Document!" "%~6" AddObjectField Value
if errorlevel 1 exit /b !errorlevel!
call :IncrementDocumentCounter "!BC.Internal.AddField.Document!" ObjectField.Count
set "BC.Internal.AddField.Index=!BC.Internal.CounterValue!"
set "BC.D.!BC.Internal.AddField.Document!.F.Index.!BC.Internal.AddField.Index!.Object=!BC.Internal.AddField.Object!"
set "BC.D.!BC.Internal.AddField.Document!.F.Index.!BC.Internal.AddField.Index!.Field=!BC.Internal.AddField.Field!"
set "BC.D.!BC.Internal.AddField.Document!.F.Index.!BC.Internal.AddField.Index!.Type=!BC.Internal.AddField.Type!"
set "BC.D.!BC.Internal.AddField.Document!.F.Index.!BC.Internal.AddField.Index!.Payload=!BC.Internal.CopiedPayloadName!"
set "BC.D.!BC.Internal.AddField.Document!.F.!BC.Internal.AddField.Object!.!BC.Internal.AddField.Field!.Exists=1"
set "BC.D.!BC.Internal.AddField.Document!.F.!BC.Internal.AddField.Object!.!BC.Internal.AddField.Field!.Type=!BC.Internal.AddField.Type!"
set "BC.D.!BC.Internal.AddField.Document!.F.!BC.Internal.AddField.Object!.!BC.Internal.AddField.Field!.Path=!BC.Internal.CopiedPayloadPath!"
exit /b 0

:AddText
call :BeginOperation AddText
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" AddText Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddText.Document=!BC.Internal.PreparedDocument!"
call :RequireRecordKind "!BC.Internal.AddText.Document!" T AddText
if errorlevel 1 exit /b !errorlevel!
call :PrepareDottedIdentifier "%~3" AddText Name
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.AddText.Name=!BC.Internal.PreparedDotted!"
if defined BC.D.!BC.Internal.AddText.Document!.T.!BC.Internal.AddText.Name!.Exists (
    call :SetError 30 TextRecordAlreadyExists "The document already contains this text record." AddText Name "Unused text name" "Duplicate"
    exit /b 30
)
call :CopyTextPayload "!BC.Internal.AddText.Document!" "%~4" AddText Text
if errorlevel 1 exit /b !errorlevel!
call :IncrementDocumentCounter "!BC.Internal.AddText.Document!" Text.Count
set "BC.Internal.AddText.Index=!BC.Internal.CounterValue!"
set "BC.D.!BC.Internal.AddText.Document!.T.Index.!BC.Internal.AddText.Index!.Name=!BC.Internal.AddText.Name!"
set "BC.D.!BC.Internal.AddText.Document!.T.Index.!BC.Internal.AddText.Index!.Payload=!BC.Internal.CopiedPayloadName!"
set "BC.D.!BC.Internal.AddText.Document!.T.!BC.Internal.AddText.Name!.Exists=1"
set "BC.D.!BC.Internal.AddText.Document!.T.!BC.Internal.AddText.Name!.Path=!BC.Internal.CopiedPayloadPath!"
exit /b 0

:Encode
call :BeginOperation Encode
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" Encode Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Encode.Document=!BC.Internal.PreparedDocument!"
call :PreparePath "%~3" File Encode Target
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Encode.Target=!BC.Internal.PreparedPath!"
for %%D in ("!BC.Internal.Encode.Document!") do set "BC.Internal.Encode.Root=!BC.D.%%~D.Root!"
set "BC.Internal.Encode.Descriptor=!BC.Internal.Encode.Root!\encode.descriptor"
call :WriteDescriptor "!BC.Internal.Encode.Document!" "!BC.Internal.Encode.Descriptor!"
if errorlevel 1 exit /b !errorlevel!
"!BC.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BC.Helper!" Encode "!BC.Internal.Encode.Descriptor!" "!BC.Internal.Encode.Root!" "!BC.Internal.Encode.Target!"
set "BC.Internal.HelperExit=!errorlevel!"
del /q "!BC.Internal.Encode.Descriptor!" >nul 2>nul
if not "!BC.Internal.HelperExit!"=="0" (
    call :SetHelperError Encode "!BC.Internal.HelperExit!"
    exit /b !BC.LastError.Code!
)
exit /b 0

:Decode
call :BeginOperation Decode
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" Decode
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Decode.Output=!BC.Internal.PreparedOutput!"
call :PreparePath "%~2" ExistingFile Decode Source
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Decode.Source=!BC.Internal.PreparedPath!"
call :AllocateDocumentInternal Pending
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Decode.Document=!BC.Internal.NewDocument!"
set "BC.Internal.Decode.Root=!BC.Internal.NewDocumentRoot!"
set "BC.Internal.Decode.Descriptor=!BC.Internal.Decode.Root!\decode.descriptor"
"!BC.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BC.Helper!" Decode "!BC.Internal.Decode.Source!" "!BC.Internal.Decode.Descriptor!" "!BC.Internal.Decode.Root!"
set "BC.Internal.HelperExit=!errorlevel!"
if not "!BC.Internal.HelperExit!"=="0" (
    call :ReleaseInternal "!BC.Internal.Decode.Document!"
    call :SetHelperError Decode "!BC.Internal.HelperExit!"
    exit /b !BC.LastError.Code!
)
call :ImportDescriptor "!BC.Internal.Decode.Document!" "!BC.Internal.Decode.Descriptor!"
set "BC.Internal.ImportExit=!errorlevel!"
del /q "!BC.Internal.Decode.Descriptor!" >nul 2>nul
if not "!BC.Internal.ImportExit!"=="0" (
    call :ReleaseInternal "!BC.Internal.Decode.Document!"
    exit /b !BC.Internal.ImportExit!
)
for %%O in ("!BC.Internal.Decode.Output!") do set "%%~O=!BC.Internal.Decode.Document!"
exit /b 0

:GetRegistryValue
call :BeginOperation GetRegistryValue
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" GetRegistryValue Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetRegistry.Document=!BC.Internal.PreparedDocument!"
call :PrepareIdentifier "%~3" GetRegistryValue Registry
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetRegistry.Registry=!BC.Internal.PreparedIdentifier!"
call :PrepareDottedIdentifier "%~4" GetRegistryValue Key
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetRegistry.Key=!BC.Internal.PreparedDotted!"
call :PrepareOutput "%~5" GetRegistryValue TypeOutput
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetRegistry.TypeOutput=!BC.Internal.PreparedOutput!"
call :PrepareOutput "%~6" GetRegistryValue TextOutput
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetRegistry.TextOutput=!BC.Internal.PreparedOutput!"
if /i "!BC.Internal.GetRegistry.TypeOutput!"=="!BC.Internal.GetRegistry.TextOutput!" (
    call :SetError 10 DuplicateOutputVariable "Type and text outputs must use different variables." GetRegistryValue Output "Distinct output variables" "Duplicate"
    exit /b 10
)
if not defined BC.D.!BC.Internal.GetRegistry.Document!.R.!BC.Internal.GetRegistry.Registry!.!BC.Internal.GetRegistry.Key!.Exists (
    call :SetError 30 RegistryValueNotFound "The requested registry value is not present in the document." GetRegistryValue Key "Existing registry and key pair" "Missing"
    exit /b 30
)
for %%D in ("!BC.Internal.GetRegistry.Document!") do for %%R in ("!BC.Internal.GetRegistry.Registry!") do for %%K in ("!BC.Internal.GetRegistry.Key!") do (
    set "BC.Internal.GetRegistry.Type=!BC.D.%%~D.R.%%~R.%%~K.Type!"
    set "BC.Internal.GetRegistry.Path=!BC.D.%%~D.R.%%~R.%%~K.Path!"
)
call "!BC.Text!" :Load "!BC.Internal.GetRegistry.Path!" "!BC.Internal.GetRegistry.TextOutput!"
set "BC.Internal.TextExit=!errorlevel!"
if not "!BC.Internal.TextExit!"=="0" (
    call :SetError 50 TextMaterializationFailed "BatchCodec could not create a BatchText handle for the registry value." GetRegistryValue Text "Readable stored payload" "Exit !BC.Internal.TextExit!"
    exit /b 50
)
for %%O in ("!BC.Internal.GetRegistry.TypeOutput!") do set "%%~O=!BC.Internal.GetRegistry.Type!"
exit /b 0

:GetObjectType
call :BeginOperation GetObjectType
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" GetObjectType Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetObject.Document=!BC.Internal.PreparedDocument!"
call :PrepareIdentifier "%~3" GetObjectType Object
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetObject.Object=!BC.Internal.PreparedIdentifier!"
call :PrepareOutput "%~4" GetObjectType Output
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetObject.Output=!BC.Internal.PreparedOutput!"
if not defined BC.D.!BC.Internal.GetObject.Document!.O.!BC.Internal.GetObject.Object!.Exists (
    call :SetError 30 ObjectNotFound "The requested object is not present in the document." GetObjectType Object "Existing object record" "Missing"
    exit /b 30
)
for %%D in ("!BC.Internal.GetObject.Document!") do for %%O in ("!BC.Internal.GetObject.Object!") do set "BC.Internal.GetObject.TypeId=!BC.D.%%~D.O.%%~O.TypeId!"
for %%O in ("!BC.Internal.GetObject.Output!") do set "%%~O=!BC.Internal.GetObject.TypeId!"
exit /b 0

:GetObjectField
call :BeginOperation GetObjectField
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" GetObjectField Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetField.Document=!BC.Internal.PreparedDocument!"
call :PrepareIdentifier "%~3" GetObjectField Object
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetField.Object=!BC.Internal.PreparedIdentifier!"
call :PrepareIdentifier "%~4" GetObjectField Field
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetField.Field=!BC.Internal.PreparedIdentifier!"
call :PrepareOutput "%~5" GetObjectField TypeOutput
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetField.TypeOutput=!BC.Internal.PreparedOutput!"
call :PrepareOutput "%~6" GetObjectField TextOutput
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetField.TextOutput=!BC.Internal.PreparedOutput!"
if /i "!BC.Internal.GetField.TypeOutput!"=="!BC.Internal.GetField.TextOutput!" (
    call :SetError 10 DuplicateOutputVariable "Type and text outputs must use different variables." GetObjectField Output "Distinct output variables" "Duplicate"
    exit /b 10
)
if not defined BC.D.!BC.Internal.GetField.Document!.F.!BC.Internal.GetField.Object!.!BC.Internal.GetField.Field!.Exists (
    call :SetError 30 ObjectFieldNotFound "The requested object field is not present in the document." GetObjectField Field "Existing object field record" "Missing"
    exit /b 30
)
for %%D in ("!BC.Internal.GetField.Document!") do for %%O in ("!BC.Internal.GetField.Object!") do for %%F in ("!BC.Internal.GetField.Field!") do (
    set "BC.Internal.GetField.Type=!BC.D.%%~D.F.%%~O.%%~F.Type!"
    set "BC.Internal.GetField.Path=!BC.D.%%~D.F.%%~O.%%~F.Path!"
)
call "!BC.Text!" :Load "!BC.Internal.GetField.Path!" "!BC.Internal.GetField.TextOutput!"
set "BC.Internal.TextExit=!errorlevel!"
if not "!BC.Internal.TextExit!"=="0" (
    call :SetError 50 TextMaterializationFailed "BatchCodec could not create a BatchText handle for the object field." GetObjectField Text "Readable stored payload" "Exit !BC.Internal.TextExit!"
    exit /b 50
)
for %%O in ("!BC.Internal.GetField.TypeOutput!") do set "%%~O=!BC.Internal.GetField.Type!"
exit /b 0

:GetText
call :BeginOperation GetText
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" GetText Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetText.Document=!BC.Internal.PreparedDocument!"
call :PrepareDottedIdentifier "%~3" GetText Name
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetText.Name=!BC.Internal.PreparedDotted!"
call :PrepareOutput "%~4" GetText Output
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.GetText.Output=!BC.Internal.PreparedOutput!"
if not defined BC.D.!BC.Internal.GetText.Document!.T.!BC.Internal.GetText.Name!.Exists (
    call :SetError 30 TextRecordNotFound "The requested text record is not present in the document." GetText Name "Existing text record" "Missing"
    exit /b 30
)
for %%D in ("!BC.Internal.GetText.Document!") do for %%N in ("!BC.Internal.GetText.Name!") do set "BC.Internal.GetText.Path=!BC.D.%%~D.T.%%~N.Path!"
call "!BC.Text!" :Load "!BC.Internal.GetText.Path!" "!BC.Internal.GetText.Output!"
set "BC.Internal.TextExit=!errorlevel!"
if not "!BC.Internal.TextExit!"=="0" (
    call :SetError 50 TextMaterializationFailed "BatchCodec could not create a BatchText handle for the text record." GetText Text "Readable stored payload" "Exit !BC.Internal.TextExit!"
    exit /b 50
)
exit /b 0

:Escape
call :TransformText Escape "%~2" "%~3"
exit /b !errorlevel!

:Unescape
call :TransformText Unescape "%~2" "%~3"
exit /b !errorlevel!

:GetDocumentInfo
call :BeginOperation GetDocumentInfo
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" GetDocumentInfo Document
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Info.Document=!BC.Internal.PreparedDocument!"
call :PrepareOutput "%~4" GetDocumentInfo Output
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Info.Output=!BC.Internal.PreparedOutput!"
set "BC.Internal.Info.Value="
for %%D in ("!BC.Internal.Info.Document!") do (
    if /i "%~3"=="Kind" set "BC.Internal.Info.Value=!BC.D.%%~D.Kind!"
    if /i "%~3"=="Version" set "BC.Internal.Info.Value=!BC.D.%%~D.Version!"
    if /i "%~3"=="RegistryValueCount" set "BC.Internal.Info.Value=!BC.D.%%~D.RegistryValue.Count!"
    if /i "%~3"=="ObjectCount" set "BC.Internal.Info.Value=!BC.D.%%~D.Object.Count!"
    if /i "%~3"=="ObjectFieldCount" set "BC.Internal.Info.Value=!BC.D.%%~D.ObjectField.Count!"
    if /i "%~3"=="TextCount" set "BC.Internal.Info.Value=!BC.D.%%~D.Text.Count!"
)
if not defined BC.Internal.Info.Value (
    call :SetError 20 UnknownDocumentInfoField "Unknown BatchCodec document information field." GetDocumentInfo Field "Kind, Version, RegistryValueCount, ObjectCount, ObjectFieldCount, or TextCount" "%~3"
    exit /b 20
)
for %%O in ("!BC.Internal.Info.Output!") do set "%%~O=!BC.Internal.Info.Value!"
exit /b 0

:GetStat
call :BeginOperation GetStat
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" GetStat Output
if errorlevel 1 exit /b !errorlevel!
if /i "%~2"=="DocumentCount" (
    for %%O in ("!BC.Internal.PreparedOutput!") do set "%%~O=!BC.Document.Count!"
    exit /b 0
)
call :SetError 20 UnknownCodecStatistic "Unknown BatchCodec statistic." GetStat Statistic "DocumentCount" "%~2"
exit /b 20

:Release
call :BeginOperation Release
if errorlevel 1 exit /b !errorlevel!
call :PrepareDocument "%~2" Release Document
if errorlevel 1 exit /b !errorlevel!
call :ReleaseInternal "!BC.Internal.PreparedDocument!"
exit /b 0

:ReadLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.ReadError.Field=%~2"
call :ValidateErrorField "!BC.Internal.ReadError.Field!"
if errorlevel 1 (
    call :SetError 20 UnknownErrorField "Unknown BatchCodec error field." ReadLastError Field "Code, Kind, Message, Operation, Parameter, Expected, or Actual" "Unknown"
    exit /b 20
)
call :PrepareOutput "%~3" ReadLastError Output
if errorlevel 1 exit /b !errorlevel!
for %%F in ("!BC.Internal.ReadError.Field!") do set "BC.Internal.ReadError.Value=!BC.LastError.%%~F!"
for %%O in ("!BC.Internal.PreparedOutput!") do set "%%~O=!BC.Internal.ReadError.Value!"
exit /b 0

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
echo Code: !BC.LastError.Code!
echo Kind: !BC.LastError.Kind!
echo Message: !BC.LastError.Message!
echo Operation: !BC.LastError.Operation!
echo Parameter: !BC.LastError.Parameter!
echo Expected: !BC.LastError.Expected!
echo Actual: !BC.LastError.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:TransformText
call :BeginOperation "%~1"
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Transform.Operation=%~1"
call :PrepareOutput "%~3" "!BC.Internal.Transform.Operation!" Output
if errorlevel 1 exit /b !errorlevel!
set "BC.Internal.Transform.Output=!BC.Internal.PreparedOutput!"
call :CreateTempPath input
set "BC.Internal.Transform.Input=!BC.Internal.TempPath!"
call :CreateTempPath output
set "BC.Internal.Transform.Result=!BC.Internal.TempPath!"
call "!BC.Text!" :Save "%~2" "!BC.Internal.Transform.Input!"
set "BC.Internal.TextExit=!errorlevel!"
if not "!BC.Internal.TextExit!"=="0" (
    del /q "!BC.Internal.Transform.Input!" "!BC.Internal.Transform.Result!" >nul 2>nul
    call :SetError 30 TextNotFound "The source BatchText handle is invalid or unavailable." "!BC.Internal.Transform.Operation!" Text "Existing BatchText handle" "Exit !BC.Internal.TextExit!"
    exit /b 30
)
"!BC.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BC.Helper!" "!BC.Internal.Transform.Operation!" "!BC.Internal.Transform.Input!" "!BC.Internal.Transform.Result!"
set "BC.Internal.HelperExit=!errorlevel!"
if not "!BC.Internal.HelperExit!"=="0" (
    del /q "!BC.Internal.Transform.Input!" "!BC.Internal.Transform.Result!" >nul 2>nul
    call :SetHelperError "!BC.Internal.Transform.Operation!" "!BC.Internal.HelperExit!"
    exit /b !BC.LastError.Code!
)
call "!BC.Text!" :Load "!BC.Internal.Transform.Result!" "!BC.Internal.Transform.Output!"
set "BC.Internal.TextExit=!errorlevel!"
del /q "!BC.Internal.Transform.Input!" "!BC.Internal.Transform.Result!" >nul 2>nul
if not "!BC.Internal.TextExit!"=="0" (
    call :SetError 50 TextMaterializationFailed "BatchCodec could not create the transformed BatchText handle." "!BC.Internal.Transform.Operation!" Output "Writable BatchText store" "Exit !BC.Internal.TextExit!"
    exit /b 50
)
exit /b 0

:BeginOperation
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BC.Internal."
call :ClearLastErrorInternal
set "BC.Internal.Operation=%~1"
exit /b 0

:PrepareOutput
set "BCValidationResult="
call "!BC.Validator!" :Apply "%~1" "Identifier+Not=PATH,ERRORLEVEL,RANDOM,TEMP,TMP,COMSPEC,CD,CMDEXTVERSION,CMDCMDLINE,DATE,TIME,PATHEXT,Frame,ReturnObject+NotPrefix=BC,BTX,BV,BRT,BR,BM,BRNG" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "%~2" "%~3" "Non-reserved identifier" "Invalid"
    exit /b 10
)
set "BC.Internal.PreparedOutput=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PrepareKind
set "BCValidationResult="
call "!BC.Validator!" :Enum "%~1" "SaveData,Registry,Object,TextBundle" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidDocumentKind "BatchCodec document kind is invalid." "%~2" "%~3" "SaveData, Registry, Object, or TextBundle" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedKind=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PrepareIdentifier
set "BCValidationResult="
call "!BC.Validator!" :Identifier "%~1" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidIdentifier "A BatchCodec identifier is invalid." "%~2" "%~3" "Identifier" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedIdentifier=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PrepareDottedIdentifier
set "BCValidationResult="
call "!BC.Validator!" :DottedIdentifier "%~1" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidDottedIdentifier "A BatchCodec dotted identifier is invalid." "%~2" "%~3" "Dotted identifier" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedDotted=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PrepareTypeId
set "BCValidationResult="
call "!BC.Validator!" :TypeId "%~1" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidTypeId "A BatchCodec object type identifier is invalid." "%~2" "%~3" "Dotted type identifier" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedTypeId=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PreparePath
set "BCValidationResult="
call "!BC.Validator!" :Path "%~1" "%~2" BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidPath "A supplied BatchCodec path is invalid." "%~3" "%~4" "%~2 path" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedPath=!BCValidationResult!"
set "BCValidationResult="
exit /b 0

:PrepareDocument
set "BCValidationResult="
call "!BC.Validator!" :Handle "%~1" BC 6 BCValidationResult
if errorlevel 1 (
    set "BCValidationResult="
    call :SetError 20 InvalidCodecHandle "BatchCodec handles use BC followed by six digits." "%~2" "%~3" "BC followed by six digits" "Invalid"
    exit /b 20
)
set "BC.Internal.PreparedDocument=!BCValidationResult!"
set "BCValidationResult="
if not defined BC.D.!BC.Internal.PreparedDocument!.__Exists (
    call :SetError 30 CodecDocumentNotFound "The requested BatchCodec document does not exist." "%~2" "%~3" "Existing BatchCodec document" "Missing"
    exit /b 30
)
exit /b 0

:RequireRecordKind
set "BC.Internal.KindCheck.Document=%~1"
set "BC.Internal.KindCheck.Record=%~2"
set "BC.Internal.KindCheck.Operation=%~3"
for %%D in ("!BC.Internal.KindCheck.Document!") do set "BC.Internal.KindCheck.Kind=!BC.D.%%~D.Kind!"
if /i "!BC.Internal.KindCheck.Kind!"=="SaveData" exit /b 0
if /i "!BC.Internal.KindCheck.Record!"=="R" if /i "!BC.Internal.KindCheck.Kind!"=="Registry" exit /b 0
if /i "!BC.Internal.KindCheck.Record!"=="O" if /i "!BC.Internal.KindCheck.Kind!"=="Object" exit /b 0
if /i "!BC.Internal.KindCheck.Record!"=="F" if /i "!BC.Internal.KindCheck.Kind!"=="Object" exit /b 0
if /i "!BC.Internal.KindCheck.Record!"=="T" if /i "!BC.Internal.KindCheck.Kind!"=="TextBundle" exit /b 0
call :SetError 20 IncompatibleDocumentKind "This record category is incompatible with the document kind." "!BC.Internal.KindCheck.Operation!" Kind "Compatible document kind" "!BC.Internal.KindCheck.Kind!"
exit /b 20

:AllocateDocumentInternal
if !BC.Document.Sequence! GEQ 999999 (
    call :SetError 50 CodecHandleSpaceExhausted "BatchCodec cannot allocate another six-digit handle." "!BC.Internal.Operation!" Document "Available document handle" "Exhausted"
    exit /b 50
)
set /a BC.Document.Sequence+=1
set "BC.Internal.Padded=000000!BC.Document.Sequence!"
set "BC.Internal.NewDocument=BC!BC.Internal.Padded:~-6!"
set "BC.Internal.NewDocumentRoot=!BC.Root!\!BC.Internal.NewDocument!"
2>nul mkdir "!BC.Internal.NewDocumentRoot!"
if errorlevel 1 (
    call :SetError 50 CodecAllocationFailed "BatchCodec could not allocate a document store." "!BC.Internal.Operation!" Document "Writable codec store" "Directory creation failed"
    exit /b 50
)
set "BC.D.!BC.Internal.NewDocument!.__Exists=1"
set "BC.D.!BC.Internal.NewDocument!.Root=!BC.Internal.NewDocumentRoot!"
set "BC.D.!BC.Internal.NewDocument!.Kind=%~1"
set "BC.D.!BC.Internal.NewDocument!.Version=1"
set "BC.D.!BC.Internal.NewDocument!.Payload.Sequence=0"
set "BC.D.!BC.Internal.NewDocument!.RegistryValue.Count=0"
set "BC.D.!BC.Internal.NewDocument!.Object.Count=0"
set "BC.D.!BC.Internal.NewDocument!.ObjectField.Count=0"
set "BC.D.!BC.Internal.NewDocument!.Text.Count=0"
set /a BC.Document.Count+=1
exit /b 0

:AllocatePayload
set "BC.Internal.Payload.Document=%~1"
call :IncrementDocumentCounter "!BC.Internal.Payload.Document!" Payload.Sequence
set "BC.Internal.Payload.Sequence=!BC.Internal.CounterValue!"
if !BC.Internal.Payload.Sequence! GTR 999999 (
    call :SetError 50 PayloadSpaceExhausted "The BatchCodec document cannot allocate another payload." "!BC.Internal.Operation!" Payload "Available payload identifier" "Exhausted"
    exit /b 50
)
set "BC.Internal.Payload.Padded=000000!BC.Internal.Payload.Sequence!"
set "BC.Internal.NewPayloadName=P!BC.Internal.Payload.Padded:~-6!.bin"
for %%D in ("!BC.Internal.Payload.Document!") do set "BC.Internal.NewPayloadPath=!BC.D.%%~D.Root!\!BC.Internal.NewPayloadName!"
exit /b 0

:CopyTextPayload
call :AllocatePayload "%~1"
if errorlevel 1 exit /b !errorlevel!
call "!BC.Text!" :Save "%~2" "!BC.Internal.NewPayloadPath!"
set "BC.Internal.TextExit=!errorlevel!"
if not "!BC.Internal.TextExit!"=="0" (
    del /q "!BC.Internal.NewPayloadPath!" >nul 2>nul
    call :SetError 30 TextNotFound "The supplied BatchText handle is invalid or unavailable." "%~3" "%~4" "Existing BatchText handle" "Exit !BC.Internal.TextExit!"
    exit /b 30
)
set "BC.Internal.CopiedPayloadName=!BC.Internal.NewPayloadName!"
set "BC.Internal.CopiedPayloadPath=!BC.Internal.NewPayloadPath!"
exit /b 0

:WriteDescriptor
set "BC.Internal.Descriptor.Document=%~1"
set "BC.Internal.Descriptor.Path=%~2"
for %%D in ("!BC.Internal.Descriptor.Document!") do (
    set "BC.Internal.Descriptor.Kind=!BC.D.%%~D.Kind!"
    set "BC.Internal.Descriptor.Version=!BC.D.%%~D.Version!"
)
>"!BC.Internal.Descriptor.Path!" echo K^|!BC.Internal.Descriptor.Kind!^|!BC.Internal.Descriptor.Version!
if errorlevel 1 (
    call :SetError 50 DescriptorWriteFailed "BatchCodec could not create its encoding descriptor." Encode Descriptor "Writable codec store" "Write failed"
    exit /b 50
)
set "BC.Internal.Descriptor.Index=1"
:WriteDescriptor.RegistryNext
for %%D in ("!BC.Internal.Descriptor.Document!") do set "BC.Internal.Descriptor.Count=!BC.D.%%~D.RegistryValue.Count!"
if !BC.Internal.Descriptor.Index! GTR !BC.Internal.Descriptor.Count! goto :WriteDescriptor.Objects
for %%D in ("!BC.Internal.Descriptor.Document!") do for %%I in (!BC.Internal.Descriptor.Index!) do (
    set "BC.Internal.Descriptor.Registry=!BC.D.%%~D.R.Index.%%I.Registry!"
    set "BC.Internal.Descriptor.Key=!BC.D.%%~D.R.Index.%%I.Key!"
    set "BC.Internal.Descriptor.Type=!BC.D.%%~D.R.Index.%%I.Type!"
    set "BC.Internal.Descriptor.Payload=!BC.D.%%~D.R.Index.%%I.Payload!"
)
>>"!BC.Internal.Descriptor.Path!" echo R^|!BC.Internal.Descriptor.Registry!^|!BC.Internal.Descriptor.Key!^|!BC.Internal.Descriptor.Type!^|!BC.Internal.Descriptor.Payload!
set /a BC.Internal.Descriptor.Index+=1
goto :WriteDescriptor.RegistryNext
:WriteDescriptor.Objects
set "BC.Internal.Descriptor.Index=1"
:WriteDescriptor.ObjectNext
for %%D in ("!BC.Internal.Descriptor.Document!") do set "BC.Internal.Descriptor.Count=!BC.D.%%~D.Object.Count!"
if !BC.Internal.Descriptor.Index! GTR !BC.Internal.Descriptor.Count! goto :WriteDescriptor.Fields
for %%D in ("!BC.Internal.Descriptor.Document!") do for %%I in (!BC.Internal.Descriptor.Index!) do (
    set "BC.Internal.Descriptor.Object=!BC.D.%%~D.O.Index.%%I.Name!"
    set "BC.Internal.Descriptor.TypeId=!BC.D.%%~D.O.Index.%%I.TypeId!"
)
>>"!BC.Internal.Descriptor.Path!" echo O^|!BC.Internal.Descriptor.Object!^|!BC.Internal.Descriptor.TypeId!
set /a BC.Internal.Descriptor.Index+=1
goto :WriteDescriptor.ObjectNext
:WriteDescriptor.Fields
set "BC.Internal.Descriptor.Index=1"
:WriteDescriptor.FieldNext
for %%D in ("!BC.Internal.Descriptor.Document!") do set "BC.Internal.Descriptor.Count=!BC.D.%%~D.ObjectField.Count!"
if !BC.Internal.Descriptor.Index! GTR !BC.Internal.Descriptor.Count! goto :WriteDescriptor.Texts
for %%D in ("!BC.Internal.Descriptor.Document!") do for %%I in (!BC.Internal.Descriptor.Index!) do (
    set "BC.Internal.Descriptor.Object=!BC.D.%%~D.F.Index.%%I.Object!"
    set "BC.Internal.Descriptor.Field=!BC.D.%%~D.F.Index.%%I.Field!"
    set "BC.Internal.Descriptor.Type=!BC.D.%%~D.F.Index.%%I.Type!"
    set "BC.Internal.Descriptor.Payload=!BC.D.%%~D.F.Index.%%I.Payload!"
)
>>"!BC.Internal.Descriptor.Path!" echo F^|!BC.Internal.Descriptor.Object!^|!BC.Internal.Descriptor.Field!^|!BC.Internal.Descriptor.Type!^|!BC.Internal.Descriptor.Payload!
set /a BC.Internal.Descriptor.Index+=1
goto :WriteDescriptor.FieldNext
:WriteDescriptor.Texts
set "BC.Internal.Descriptor.Index=1"
:WriteDescriptor.TextNext
for %%D in ("!BC.Internal.Descriptor.Document!") do set "BC.Internal.Descriptor.Count=!BC.D.%%~D.Text.Count!"
if !BC.Internal.Descriptor.Index! GTR !BC.Internal.Descriptor.Count! exit /b 0
for %%D in ("!BC.Internal.Descriptor.Document!") do for %%I in (!BC.Internal.Descriptor.Index!) do (
    set "BC.Internal.Descriptor.Name=!BC.D.%%~D.T.Index.%%I.Name!"
    set "BC.Internal.Descriptor.Payload=!BC.D.%%~D.T.Index.%%I.Payload!"
)
>>"!BC.Internal.Descriptor.Path!" echo T^|!BC.Internal.Descriptor.Name!^|!BC.Internal.Descriptor.Payload!
set /a BC.Internal.Descriptor.Index+=1
goto :WriteDescriptor.TextNext

:ImportDescriptor
set "BC.Internal.Import.Document=%~1"
set "BC.Internal.Import.Path=%~2"
set "BC.Internal.Import.Error=0"
for /f "usebackq tokens=1-5 delims=|" %%A in ("!BC.Internal.Import.Path!") do call :ImportDescriptorLine "%%~A" "%%~B" "%%~C" "%%~D" "%%~E"
if not "!BC.Internal.Import.Error!"=="0" (
    call :SetError 50 InvalidDecodedDescriptor "BatchCodec helper produced an invalid descriptor." Decode Descriptor "Validated helper descriptor" "Invalid"
    exit /b 50
)
for %%D in ("!BC.Internal.Import.Document!") do set "BC.Internal.Import.Kind=!BC.D.%%~D.Kind!"
if /i "!BC.Internal.Import.Kind!"=="Pending" (
    call :SetError 50 InvalidDecodedDescriptor "BatchCodec helper descriptor did not identify its document kind." Decode Descriptor "Kind header" "Missing"
    exit /b 50
)
exit /b 0

:ImportDescriptorLine
if "!BC.Internal.Import.Error!"=="1" exit /b 0
if /i "%~1"=="K" (
    set "BC.D.!BC.Internal.Import.Document!.Kind=%~2"
    set "BC.D.!BC.Internal.Import.Document!.Version=%~3"
    exit /b 0
)
if /i "%~1"=="R" (
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" Payload.Sequence
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" RegistryValue.Count
    set "BC.Internal.Import.Index=!BC.Internal.CounterValue!"
    set "BC.D.!BC.Internal.Import.Document!.R.Index.!BC.Internal.Import.Index!.Registry=%~2"
    set "BC.D.!BC.Internal.Import.Document!.R.Index.!BC.Internal.Import.Index!.Key=%~3"
    set "BC.D.!BC.Internal.Import.Document!.R.Index.!BC.Internal.Import.Index!.Type=%~4"
    set "BC.D.!BC.Internal.Import.Document!.R.Index.!BC.Internal.Import.Index!.Payload=%~5"
    set "BC.D.!BC.Internal.Import.Document!.R.%~2.%~3.Exists=1"
    set "BC.D.!BC.Internal.Import.Document!.R.%~2.%~3.Type=%~4"
    for %%D in ("!BC.Internal.Import.Document!") do set "BC.D.%%~D.R.%~2.%~3.Path=!BC.D.%%~D.Root!\%~5"
    exit /b 0
)
if /i "%~1"=="O" (
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" Object.Count
    set "BC.Internal.Import.Index=!BC.Internal.CounterValue!"
    set "BC.D.!BC.Internal.Import.Document!.O.Index.!BC.Internal.Import.Index!.Name=%~2"
    set "BC.D.!BC.Internal.Import.Document!.O.Index.!BC.Internal.Import.Index!.TypeId=%~3"
    set "BC.D.!BC.Internal.Import.Document!.O.%~2.Exists=1"
    set "BC.D.!BC.Internal.Import.Document!.O.%~2.TypeId=%~3"
    exit /b 0
)
if /i "%~1"=="F" (
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" Payload.Sequence
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" ObjectField.Count
    set "BC.Internal.Import.Index=!BC.Internal.CounterValue!"
    set "BC.D.!BC.Internal.Import.Document!.F.Index.!BC.Internal.Import.Index!.Object=%~2"
    set "BC.D.!BC.Internal.Import.Document!.F.Index.!BC.Internal.Import.Index!.Field=%~3"
    set "BC.D.!BC.Internal.Import.Document!.F.Index.!BC.Internal.Import.Index!.Type=%~4"
    set "BC.D.!BC.Internal.Import.Document!.F.Index.!BC.Internal.Import.Index!.Payload=%~5"
    set "BC.D.!BC.Internal.Import.Document!.F.%~2.%~3.Exists=1"
    set "BC.D.!BC.Internal.Import.Document!.F.%~2.%~3.Type=%~4"
    for %%D in ("!BC.Internal.Import.Document!") do set "BC.D.%%~D.F.%~2.%~3.Path=!BC.D.%%~D.Root!\%~5"
    exit /b 0
)
if /i "%~1"=="T" (
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" Payload.Sequence
    call :IncrementDocumentCounter "!BC.Internal.Import.Document!" Text.Count
    set "BC.Internal.Import.Index=!BC.Internal.CounterValue!"
    set "BC.D.!BC.Internal.Import.Document!.T.Index.!BC.Internal.Import.Index!.Name=%~2"
    set "BC.D.!BC.Internal.Import.Document!.T.Index.!BC.Internal.Import.Index!.Payload=%~3"
    set "BC.D.!BC.Internal.Import.Document!.T.%~2.Exists=1"
    for %%D in ("!BC.Internal.Import.Document!") do set "BC.D.%%~D.T.%~2.Path=!BC.D.%%~D.Root!\%~3"
    exit /b 0
)
set "BC.Internal.Import.Error=1"
exit /b 0

:IncrementDocumentCounter
set "BC.Internal.Counter.Document=%~1"
set "BC.Internal.Counter.Name=%~2"
for %%D in ("!BC.Internal.Counter.Document!") do for %%C in ("!BC.Internal.Counter.Name!") do set "BC.Internal.CounterValue=!BC.D.%%~D.%%~C!"
if not defined BC.Internal.CounterValue set "BC.Internal.CounterValue=0"
set /a BC.Internal.CounterValue+=1
for %%D in ("!BC.Internal.Counter.Document!") do for %%C in ("!BC.Internal.Counter.Name!") do set "BC.D.%%~D.%%~C=!BC.Internal.CounterValue!"
exit /b 0

:ReleaseInternal
set "BC.Internal.Release.Document=%~1"
for %%D in ("!BC.Internal.Release.Document!") do set "BC.Internal.Release.Root=!BC.D.%%~D.Root!"
if defined BC.Internal.Release.Root if exist "!BC.Internal.Release.Root!\" rmdir /s /q "!BC.Internal.Release.Root!" >nul 2>nul
call :ClearPrefix "BC.D.!BC.Internal.Release.Document!."
if !BC.Document.Count! GTR 0 set /a BC.Document.Count-=1
exit /b 0

:CreateTempPath
set /a BC.Temp.Sequence+=1
set "BC.Internal.TempPath=!BC.Root!\temp-!BC.Temp.Sequence!-%~1.tmp"
del /q "!BC.Internal.TempPath!" >nul 2>nul
exit /b 0

:SetHelperError
set "BC.Internal.Helper.Operation=%~1"
set "BC.Internal.Helper.Code=%~2"
if "!BC.Internal.Helper.Code!"=="3" (
    call :SetError 30 CodecSourceNotFound "A required codec source or backing file is missing." "!BC.Internal.Helper.Operation!" Source "Existing source file" "Missing"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="4" (
    call :SetError 20 MalformedCodecData "Serialized data is malformed or non-canonical." "!BC.Internal.Helper.Operation!" Data "Canonical BatchCodec version 1 data" "Malformed"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="5" (
    call :SetError 30 UnsupportedCodecVersion "Serialized data uses an unsupported format version." "!BC.Internal.Helper.Operation!" Version "BatchCodec format version 1" "Unsupported"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="6" (
    call :SetError 20 CodecIntegrityMismatch "Serialized data failed its integrity check." "!BC.Internal.Helper.Operation!" Integrity "Matching SHA-256 body digest" "Mismatch"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="7" (
    call :SetError 20 IncompatibleCodecData "Serialized records are incompatible with the document kind." "!BC.Internal.Helper.Operation!" Kind "Compatible record categories" "Incompatible"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="8" (
    call :SetError 20 MalformedEscapedData "Escaped data contains an invalid or incomplete percent escape." "!BC.Internal.Helper.Operation!" Escape "Unreserved ASCII or percent-hex bytes" "Malformed"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="9" (
    call :SetError 20 DuplicateCodecRecord "Serialized data contains a duplicate logical record." "!BC.Internal.Helper.Operation!" Record "Unique case-insensitive record keys" "Duplicate"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="10" (
    call :SetError 20 CodecDataTooLarge "Serialized data exceeds BatchCodec size or record limits." "!BC.Internal.Helper.Operation!" Size "Supported package limits" "Too large"
    exit /b 0
)
if "!BC.Internal.Helper.Code!"=="2" (
    call :SetError 20 InvalidCodecDescriptor "BatchCodec could not build a valid serialization descriptor." "!BC.Internal.Helper.Operation!" Descriptor "Valid internal descriptor" "Invalid"
    exit /b 0
)
call :SetError 50 CodecOperationFailed "The BatchCodec helper failed." "!BC.Internal.Helper.Operation!" Helper "Successful helper operation" "Exit !BC.Internal.Helper.Code!"
exit /b 0

:RequireInitialized
if defined BC.Initialized exit /b 0
call :SetError 50 CodecNotInitialized "BatchCodec has not been initialized." Runtime State "initialize codec" "Not initialized"
exit /b 50

:ValidateErrorField
for %%F in (Code Kind Message Operation Parameter Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearLastErrorInternal
set "BC.LastError.Code=0"
set "BC.LastError.Kind=None"
set "BC.LastError.Message="
set "BC.LastError.Operation="
set "BC.LastError.Parameter="
set "BC.LastError.Expected="
set "BC.LastError.Actual="
exit /b 0

:SetError
set "BC.LastError.Code=%~1"
set "BC.LastError.Kind=%~2"
set "BC.LastError.Message=%~3"
set "BC.LastError.Operation=%~4"
set "BC.LastError.Parameter=%~5"
set "BC.LastError.Expected=%~6"
set "BC.LastError.Actual=%~7"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
