@echo off

rem BatchText.bat
rem Project-agnostic file-backed text storage for Windows batch files.
rem Version 1.0.0 - protocol 1.
rem Requirement: caller must enable command extensions and delayed expansion.
rem
rem Storage contract:
rem - Handles own opaque byte streams; UTF-8 without BOM is recommended.
rem - Load and save are byte-for-byte. No encoding conversion is performed.
rem - BOM bytes and CR, LF, or CRLF newline bytes are never normalized.
rem - Length and slice offsets are byte counts, not Unicode character counts.
rem - Search and replace are exact, case-sensitive byte-sequence operations.
rem - Replace processes all non-overlapping matches from left to right.
rem - Append mutates its target; concatenate, slice, and replace create handles.
rem - Append and concatenate insert no separator or newline.
rem - Stored content never enters a CMD variable or command line.

set "BTX.Internal.DelayedProbe=1"
if not "!BTX.Internal.DelayedProbe!"=="1" (
    echo BatchText requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="create" goto :Readable.Create
if /i "%~1"=="load" goto :Readable.Load
if /i "%~1"=="save" goto :Readable.Save
if /i "%~1"=="compare" goto :Readable.Compare
if /i "%~1"=="append" goto :Readable.Append
if /i "%~1"=="concatenate" goto :Readable.Concatenate
if /i "%~1"=="slice" goto :Readable.Slice
if /i "%~1"=="search" goto :Readable.Search
if /i "%~1"=="replace" goto :Readable.Replace
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"=="release" goto :Readable.Release
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="clear" goto :Readable.Clear

if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":CreateEmpty" goto :CreateEmpty
if /i "%~1"==":Load" goto :Load
if /i "%~1"==":Save" goto :Save
if /i "%~1"==":Compare" goto :Compare
if /i "%~1"==":Append" goto :Append
if /i "%~1"==":Concatenate" goto :Concatenate
if /i "%~1"==":Slice" goto :Slice
if /i "%~1"==":Search" goto :Search
if /i "%~1"==":Replace" goto :Replace
if /i "%~1"==":Length" goto :Length
if /i "%~1"==":Release" goto :Release
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :SetError 10 UnknownTextCommand "Unknown BatchText command." Command "Known BatchText command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="text" goto :Readable.Syntax
call "%~f0" :Initialize
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="text" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Create
if /i not "%~2"=="empty" goto :Readable.Syntax
if /i not "%~3"=="text" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :CreateEmpty "%~5"
exit /b !errorlevel!

:Readable.Load
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~3"=="from" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Load "%~4" "%~6"
exit /b !errorlevel!

:Readable.Save
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="to" goto :Readable.Syntax
call "%~f0" :Save "%~3" "%~5"
exit /b !errorlevel!

:Readable.Compare
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :Compare "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.Append
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="to" goto :Readable.Syntax
call "%~f0" :Append "%~5" "%~3"
exit /b !errorlevel!

:Readable.Concatenate
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :Concatenate "%~3" "%~5" "%~7"
exit /b !errorlevel!

:Readable.Slice
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~6"=="for" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :Slice "%~3" "%~5" "%~7" "%~9"
exit /b !errorlevel!

:Readable.Search
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="in" goto :Readable.Syntax
if /i not "%~6"=="from" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :Search "%~5" "%~3" "%~7" "%~9"
exit /b !errorlevel!

:Readable.Replace
if /i not "%~2"=="text" goto :Readable.Syntax
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~6"=="in" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :Replace "%~7" "%~3" "%~5" "%~9"
exit /b !errorlevel!

:Readable.Get
if /i "%~2"=="length" (
    if /i not "%~3"=="of" goto :Readable.Syntax
    if /i not "%~4"=="text" goto :Readable.Syntax
    if /i not "%~6"=="into" goto :Readable.Syntax
    call "%~f0" :Length "%~5" "%~7"
    exit /b !errorlevel!
)
if /i "%~2"=="statistic" (
    if /i not "%~4"=="into" goto :Readable.Syntax
    call "%~f0" :GetStat "%~3" "%~5"
    exit /b !errorlevel!
)
goto :Readable.Syntax

:Readable.Release
if /i not "%~2"=="text" goto :Readable.Syntax
call "%~f0" :Release "%~3"
exit /b !errorlevel!

:Readable.Read
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Show
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :PrintLastError
exit /b !errorlevel!

:Readable.Clear
if /i not "%~2"=="last" goto :Readable.Syntax
if /i not "%~3"=="error" goto :Readable.Syntax
call "%~f0" :ClearLastError
exit /b !errorlevel!

:Readable.Syntax
call :SetError 10 InvalidTextSyntax "BatchText command syntax is invalid." Syntax "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BTX.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :ClearPrefix "BTX."
set "BTX.Validator=%~dp0..\BatchValidate\BatchValidate.bat"
set "BTX.Helper=%~dp0BatchTextOps.ps1"
set "BTX.PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "!BTX.Validator!" (
    call :SetError 50 ValidationDependencyMissing "BatchValidate is required by BatchText." Initialize Dependency "Existing BatchValidate component" "Missing"
    exit /b 50
)
if not exist "!BTX.Helper!" (
    call :SetError 50 TextHelperMissing "The BatchText helper script is missing." Initialize Dependency "Existing BatchTextOps.ps1" "Missing"
    exit /b 50
)
if not exist "!BTX.PowerShell!" (
    call :SetError 50 PowerShellUnavailable "Windows PowerShell 5.1 is required by BatchText." Initialize Dependency "Windows PowerShell executable" "Missing"
    exit /b 50
)
set "BTX.Initialized=1"
set "BTX.Version=1.0.0"
set "BTX.Protocol=1"
set "BTX.Text.Sequence=0"
set "BTX.Text.Count=0"
set "BTX.Temp.Sequence=0"
set "BTX.EncodingPolicy=OpaqueBytes"
set "BTX.NewlinePolicy=Preserve"
set "BTX.TextRoot=%TEMP%\BatchText-!RANDOM!-!RANDOM!-!RANDOM!"
2>nul mkdir "!BTX.TextRoot!"
if errorlevel 1 (
    set "BTX.Initialized="
    call :SetError 50 TextStoreCreationFailed "BatchText could not create its temporary text store." Initialize TextRoot "Writable temporary directory" "Creation failed"
    exit /b 50
)
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
if defined BTX.TextRoot if exist "!BTX.TextRoot!\" (
    2>nul rmdir /s /q "!BTX.TextRoot!"
)
call :ClearPrefix "BTX."
exit /b 0

:CreateEmpty
call :BeginOperation CreateEmpty
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~2" CreateEmpty
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Create.Output=!BTX.Internal.PreparedOutput!"
call :AllocateHandle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Result=!BTX.Internal.NewHandle!"
for %%O in ("!BTX.Internal.Create.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Load
call :BeginOperation Load
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" Load
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Load.Output=!BTX.Internal.PreparedOutput!"
call :PreparePath "%~2" File Load Source
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Load.Source=!BTX.Internal.PreparedPath!"
if not exist "!BTX.Internal.Load.Source!" (
    call :SetError 30 TextSourceNotFound "The source text file does not exist." Load Source "Existing file" "Missing"
    exit /b 30
)
for %%P in ("!BTX.Internal.Load.Source!") do set "BTX.Internal.Load.Attributes=%%~aP"
if /i "!BTX.Internal.Load.Attributes:~0,1!"=="d" (
    call :SetError 20 PathTypeMismatch "The source path is a directory rather than a file." Load Source "File path" "Directory"
    exit /b 20
)
call :AllocateHandle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Load.Handle=!BTX.Internal.NewHandle!"
set "BTX.Internal.Load.Target=!BTX.Internal.NewPath!"
copy /b /y "!BTX.Internal.Load.Source!" "!BTX.Internal.Load.Target!" >nul
if errorlevel 1 (
    call :ReleaseInternal "!BTX.Internal.Load.Handle!"
    call :SetError 50 TextLoadFailed "BatchText could not copy the source file into its text store." Load Source "Readable file" "Copy failed"
    exit /b 50
)
set "BTX.Internal.Result=!BTX.Internal.Load.Handle!"
for %%O in ("!BTX.Internal.Load.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Save
call :BeginOperation Save
if errorlevel 1 exit /b !errorlevel!
call :PrepareHandle "%~2" Save Text
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Save.Handle=!BTX.Internal.PreparedHandle!"
set "BTX.Internal.Save.Source=!BTX.Internal.PreparedHandlePath!"
call :PreparePath "%~3" File Save Target
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Save.Target=!BTX.Internal.PreparedPath!"
copy /b /y "!BTX.Internal.Save.Source!" "!BTX.Internal.Save.Target!" >nul
if errorlevel 1 (
    call :SetError 50 TextSaveFailed "BatchText could not write the target file." Save Target "Writable file path" "Copy failed"
    exit /b 50
)
exit /b 0

:Compare
call :BeginOperation Compare
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~4" Compare
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Compare.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Compare Left
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Compare.LeftPath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~3" Compare Right
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Compare.RightPath=!BTX.Internal.PreparedHandlePath!"
call :CreateTempPath result
set "BTX.Internal.Compare.ResultPath=!BTX.Internal.TempPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Compare "!BTX.Internal.Compare.LeftPath!" "!BTX.Internal.Compare.RightPath!" "!BTX.Internal.Compare.ResultPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    del /q "!BTX.Internal.Compare.ResultPath!" >nul 2>nul
    call :SetHelperError Compare "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result="
set /p "BTX.Internal.Result="<"!BTX.Internal.Compare.ResultPath!"
del /q "!BTX.Internal.Compare.ResultPath!" >nul 2>nul
if not "!BTX.Internal.Result!"=="0" if not "!BTX.Internal.Result!"=="1" (
    call :SetError 50 InvalidHelperResult "BatchText helper returned an invalid comparison result." Compare Result "0 or 1" "Invalid"
    exit /b 50
)
for %%O in ("!BTX.Internal.Compare.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Append
call :BeginOperation Append
if errorlevel 1 exit /b !errorlevel!
call :PrepareHandle "%~2" Append Target
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Append.TargetHandle=!BTX.Internal.PreparedHandle!"
set "BTX.Internal.Append.TargetPath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~3" Append Source
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Append.SourcePath=!BTX.Internal.PreparedHandlePath!"
call :CreateTempPath append
set "BTX.Internal.Append.TempPath=!BTX.Internal.TempPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Concatenate "!BTX.Internal.Append.TargetPath!" "!BTX.Internal.Append.SourcePath!" "!BTX.Internal.Append.TempPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    del /q "!BTX.Internal.Append.TempPath!" >nul 2>nul
    call :SetHelperError Append "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
move /y "!BTX.Internal.Append.TempPath!" "!BTX.Internal.Append.TargetPath!" >nul
if errorlevel 1 (
    del /q "!BTX.Internal.Append.TempPath!" >nul 2>nul
    call :SetError 50 TextAppendFailed "BatchText could not commit the appended text." Append Target "Writable text handle" "Move failed"
    exit /b 50
)
exit /b 0

:Concatenate
call :BeginOperation Concatenate
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~4" Concatenate
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Concat.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Concatenate Left
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Concat.LeftPath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~3" Concatenate Right
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Concat.RightPath=!BTX.Internal.PreparedHandlePath!"
call :AllocateHandle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Concat.Handle=!BTX.Internal.NewHandle!"
set "BTX.Internal.Concat.TargetPath=!BTX.Internal.NewPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Concatenate "!BTX.Internal.Concat.LeftPath!" "!BTX.Internal.Concat.RightPath!" "!BTX.Internal.Concat.TargetPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    call :ReleaseInternal "!BTX.Internal.Concat.Handle!"
    call :SetHelperError Concatenate "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result=!BTX.Internal.Concat.Handle!"
for %%O in ("!BTX.Internal.Concat.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Slice
call :BeginOperation Slice
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~5" Slice
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Slice.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Slice Text
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Slice.SourcePath=!BTX.Internal.PreparedHandlePath!"
call :PrepareUInt "%~3" Slice Start
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Slice.Start=!BTX.Internal.PreparedUInt!"
call :PrepareUInt "%~4" Slice Length
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Slice.Length=!BTX.Internal.PreparedUInt!"
call :AllocateHandle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Slice.Handle=!BTX.Internal.NewHandle!"
set "BTX.Internal.Slice.TargetPath=!BTX.Internal.NewPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Slice "!BTX.Internal.Slice.SourcePath!" "!BTX.Internal.Slice.Start!" "!BTX.Internal.Slice.Length!" "!BTX.Internal.Slice.TargetPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    call :ReleaseInternal "!BTX.Internal.Slice.Handle!"
    call :SetHelperError Slice "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result=!BTX.Internal.Slice.Handle!"
for %%O in ("!BTX.Internal.Slice.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Search
call :BeginOperation Search
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~5" Search
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Search.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Search Text
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Search.TextPath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~3" Search Needle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Search.NeedlePath=!BTX.Internal.PreparedHandlePath!"
call :PrepareUInt "%~4" Search Start
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Search.Start=!BTX.Internal.PreparedUInt!"
call :CreateTempPath result
set "BTX.Internal.Search.ResultPath=!BTX.Internal.TempPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Search "!BTX.Internal.Search.TextPath!" "!BTX.Internal.Search.NeedlePath!" "!BTX.Internal.Search.Start!" "!BTX.Internal.Search.ResultPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    del /q "!BTX.Internal.Search.ResultPath!" >nul 2>nul
    call :SetHelperError Search "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result="
set /p "BTX.Internal.Result="<"!BTX.Internal.Search.ResultPath!"
del /q "!BTX.Internal.Search.ResultPath!" >nul 2>nul
if not defined BTX.Internal.Result (
    call :SetError 50 InvalidHelperResult "BatchText helper returned an empty search result." Search Result "Signed byte index" "Empty"
    exit /b 50
)
for %%O in ("!BTX.Internal.Search.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Replace
call :BeginOperation Replace
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~5" Replace
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Replace.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Replace Text
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Replace.SourcePath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~3" Replace Search
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Replace.SearchPath=!BTX.Internal.PreparedHandlePath!"
call :PrepareHandle "%~4" Replace Replacement
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Replace.ReplacementPath=!BTX.Internal.PreparedHandlePath!"
call :AllocateHandle
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Replace.Handle=!BTX.Internal.NewHandle!"
set "BTX.Internal.Replace.TargetPath=!BTX.Internal.NewPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Replace "!BTX.Internal.Replace.SourcePath!" "!BTX.Internal.Replace.SearchPath!" "!BTX.Internal.Replace.ReplacementPath!" "!BTX.Internal.Replace.TargetPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    call :ReleaseInternal "!BTX.Internal.Replace.Handle!"
    call :SetHelperError Replace "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result=!BTX.Internal.Replace.Handle!"
for %%O in ("!BTX.Internal.Replace.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Length
call :BeginOperation Length
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" Length
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Length.Output=!BTX.Internal.PreparedOutput!"
call :PrepareHandle "%~2" Length Text
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Length.TextPath=!BTX.Internal.PreparedHandlePath!"
call :CreateTempPath result
set "BTX.Internal.Length.ResultPath=!BTX.Internal.TempPath!"
"!BTX.PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!BTX.Helper!" Length "!BTX.Internal.Length.TextPath!" "!BTX.Internal.Length.ResultPath!"
set "BTX.Internal.HelperExit=!errorlevel!"
if not "!BTX.Internal.HelperExit!"=="0" (
    del /q "!BTX.Internal.Length.ResultPath!" >nul 2>nul
    call :SetHelperError Length "!BTX.Internal.HelperExit!"
    exit /b !BTX.LastError.Code!
)
set "BTX.Internal.Result="
set /p "BTX.Internal.Result="<"!BTX.Internal.Length.ResultPath!"
del /q "!BTX.Internal.Length.ResultPath!" >nul 2>nul
if not defined BTX.Internal.Result set "BTX.Internal.Result=0"
for %%O in ("!BTX.Internal.Length.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:Release
call :BeginOperation Release
if errorlevel 1 exit /b !errorlevel!
call :PrepareHandle "%~2" Release Text
if errorlevel 1 exit /b !errorlevel!
call :ReleaseInternal "!BTX.Internal.PreparedHandle!"
exit /b 0

:GetStat
call :BeginOperation GetStat
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~3" GetStat
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.Stat.Output=!BTX.Internal.PreparedOutput!"
if /i "%~2"=="TextCount" (
    set "BTX.Internal.Result=!BTX.Text.Count!"
    for %%O in ("!BTX.Internal.Stat.Output!") do set "%%~O=!BTX.Internal.Result!"
    exit /b 0
)
call :SetError 20 UnknownTextStatistic "Unknown BatchText statistic." GetStat Statistic "TextCount" "%~2"
exit /b 20

:ReadLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.ReadError.Field=%~2"
set "BTX.Internal.ReadError.Output=%~3"
call :ValidateErrorField "!BTX.Internal.ReadError.Field!"
if errorlevel 1 (
    call :SetError 20 UnknownErrorField "Unknown BatchText error field." ReadLastError Field "Code, Kind, Message, Operation, Parameter, Expected, or Actual" "Unknown"
    exit /b 20
)
call :PrepareOutput "!BTX.Internal.ReadError.Output!" ReadLastError
if errorlevel 1 exit /b !errorlevel!
set "BTX.Internal.ReadError.Output=!BTX.Internal.PreparedOutput!"
for %%F in ("!BTX.Internal.ReadError.Field!") do set "BTX.Internal.Result=!BTX.LastError.%%~F!"
for %%O in ("!BTX.Internal.ReadError.Output!") do set "%%~O=!BTX.Internal.Result!"
exit /b 0

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
echo Code: !BTX.LastError.Code!
echo Kind: !BTX.LastError.Kind!
echo Message: !BTX.LastError.Message!
echo Operation: !BTX.LastError.Operation!
echo Parameter: !BTX.LastError.Parameter!
echo Expected: !BTX.LastError.Expected!
echo Actual: !BTX.LastError.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:BeginOperation
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BTX.Internal."
call :ClearLastErrorInternal
set "BTX.Internal.Operation=%~1"
exit /b 0

:PrepareOutput
set "BTXValidationResult="
call "!BTX.Validator!" :Apply "%~1" "Identifier+Not=PATH,ERRORLEVEL,RANDOM,TEMP,TMP,COMSPEC,CD,CMDEXTVERSION,CMDCMDLINE,DATE,TIME,PATHEXT,Frame,ReturnObject+NotPrefix=BTX,BV,BRT" BTXValidationResult
if errorlevel 1 (
    set "BTXValidationResult="
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "%~2" Output "Non-reserved identifier" "Invalid"
    exit /b 10
)
set "BTX.Internal.PreparedOutput=!BTXValidationResult!"
set "BTXValidationResult="
exit /b 0

:PreparePath
set "BTXValidationResult="
call "!BTX.Validator!" :Path "%~1" "%~2" BTXValidationResult
if errorlevel 1 (
    set "BTXValidationResult="
    call :SetError 20 InvalidPath "A supplied path is invalid." "%~3" "%~4" "%~2 path" "Invalid"
    exit /b 20
)
set "BTX.Internal.PreparedPath=!BTXValidationResult!"
set "BTXValidationResult="
exit /b 0

:PrepareUInt
set "BTXValidationResult="
call "!BTX.Validator!" :UInt32 "%~1" BTXValidationResult
if errorlevel 1 (
    set "BTXValidationResult="
    call :SetError 20 InvalidUnsignedInteger "A byte offset or length is invalid." "%~2" "%~3" "0 through 2147483647" "Invalid"
    exit /b 20
)
set "BTX.Internal.PreparedUInt=!BTXValidationResult!"
set "BTXValidationResult="
exit /b 0

:PrepareHandle
set "BTXValidationResult="
call "!BTX.Validator!" :Handle "%~1" TX 6 BTXValidationResult
if errorlevel 1 (
    set "BTXValidationResult="
    call :SetError 20 InvalidTextHandle "Text handles must use the TX prefix followed by six digits." "%~2" "%~3" "TX followed by six digits" "Invalid"
    exit /b 20
)
set "BTX.Internal.PreparedHandle=!BTXValidationResult!"
for %%H in ("!BTX.Internal.PreparedHandle!") do (
    set "BTX.Internal.HandleExists=!BTX.T.%%~H.__Exists!"
    set "BTX.Internal.PreparedHandlePath=!BTX.T.%%~H.Path!"
)
set "BTXValidationResult="
if not "!BTX.Internal.HandleExists!"=="1" (
    call :SetError 30 TextNotFound "The requested BatchText handle does not exist." "%~2" "%~3" "Existing text handle" "Missing"
    exit /b 30
)
exit /b 0

:AllocateHandle
if !BTX.Text.Sequence! GEQ 999999 (
    call :SetError 50 TextHandleSpaceExhausted "BatchText cannot allocate another six-digit handle." "!BTX.Internal.Operation!" Text "Available handle identifier" "Exhausted"
    exit /b 50
)
set /a BTX.Text.Sequence+=1
set "BTX.Internal.Padded=000000!BTX.Text.Sequence!"
set "BTX.Internal.NewHandle=TX!BTX.Internal.Padded:~-6!"
set "BTX.Internal.NewPath=!BTX.TextRoot!\!BTX.Internal.NewHandle!.bin"
type nul >"!BTX.Internal.NewPath!"
if errorlevel 1 (
    call :SetError 50 TextAllocationFailed "BatchText could not allocate a backing file." "!BTX.Internal.Operation!" Text "Writable text store" "File creation failed"
    exit /b 50
)
set "BTX.T.!BTX.Internal.NewHandle!.__Exists=1"
set "BTX.T.!BTX.Internal.NewHandle!.Path=!BTX.Internal.NewPath!"
set /a BTX.Text.Count+=1
exit /b 0

:ReleaseInternal
set "BTX.Internal.Release.Handle=%~1"
for %%H in ("!BTX.Internal.Release.Handle!") do set "BTX.Internal.Release.Path=!BTX.T.%%~H.Path!"
if defined BTX.Internal.Release.Path del /q "!BTX.Internal.Release.Path!" >nul 2>nul
call :ClearPrefix "BTX.T.!BTX.Internal.Release.Handle!."
if !BTX.Text.Count! GTR 0 set /a BTX.Text.Count-=1
exit /b 0

:CreateTempPath
set /a BTX.Temp.Sequence+=1
set "BTX.Internal.TempPath=!BTX.TextRoot!\temp-!BTX.Temp.Sequence!-%~1.tmp"
del /q "!BTX.Internal.TempPath!" >nul 2>nul
exit /b 0

:SetHelperError
set "BTX.Internal.Helper.Operation=%~1"
set "BTX.Internal.Helper.Code=%~2"
if "!BTX.Internal.Helper.Code!"=="4" (
    call :SetError 20 TextRangeOutOfBounds "The requested byte range is outside the text." "!BTX.Internal.Helper.Operation!" Range "Range within text length" "Out of bounds"
    exit /b 0
)
if "!BTX.Internal.Helper.Code!"=="5" (
    call :SetError 20 EmptySearchText "Replace requires a non-empty search text." "!BTX.Internal.Helper.Operation!" Search "Non-empty text handle" "Empty"
    exit /b 0
)
if "!BTX.Internal.Helper.Code!"=="6" (
    call :SetError 20 TextTooLarge "The text operation exceeds the signed 32-bit byte limit." "!BTX.Internal.Helper.Operation!" Length "0 through 2147483647 bytes" "Too large"
    exit /b 0
)
if "!BTX.Internal.Helper.Code!"=="3" (
    call :SetError 50 BackingFileMissing "A BatchText backing file is missing." "!BTX.Internal.Helper.Operation!" Text "Existing backing file" "Missing"
    exit /b 0
)
call :SetError 50 TextOperationFailed "The byte-safe BatchText helper failed." "!BTX.Internal.Helper.Operation!" Helper "Successful helper operation" "Exit !BTX.Internal.Helper.Code!"
exit /b 0

:RequireInitialized
if defined BTX.Initialized exit /b 0
call :SetError 50 TextNotInitialized "BatchText has not been initialized." Runtime State "initialize text" "Not initialized"
exit /b 50

:ValidateErrorField
for %%F in (Code Kind Message Operation Parameter Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearLastErrorInternal
set "BTX.LastError.Code=0"
set "BTX.LastError.Kind=None"
set "BTX.LastError.Message="
set "BTX.LastError.Operation="
set "BTX.LastError.Parameter="
set "BTX.LastError.Expected="
set "BTX.LastError.Actual="
exit /b 0

:SetError
set "BTX.LastError.Code=%~1"
set "BTX.LastError.Kind=%~2"
set "BTX.LastError.Message=%~3"
set "BTX.LastError.Operation=%~4"
set "BTX.LastError.Parameter=%~5"
set "BTX.LastError.Expected=%~6"
set "BTX.LastError.Actual=%~7"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
