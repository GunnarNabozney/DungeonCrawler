@echo off

rem Math.bat
rem BatchRuntime adapter for the standalone BatchMath component.
rem Version 1.0.0 - BatchRuntime protocol 1.

if /i not "%~1"=="__BRT__" exit /b 64
if /i "%~2"=="MANIFEST" goto :Manifest
if /i "%~2"=="DESCRIBE" goto :Describe
if /i "%~2"=="INVOKE" goto :Invoke
exit /b 64

:Manifest
set "BRT.X.Manifest.Name=Math"
set "BRT.X.Manifest.Version=1.0.0"
set "BRT.X.Manifest.ProtocolVersion=1"
set "BRT.X.Manifest.Export.Count=14"
set "BRT.X.Manifest.Export.1=Add"
set "BRT.X.Manifest.Export.2=Subtract"
set "BRT.X.Manifest.Export.3=Multiply"
set "BRT.X.Manifest.Export.4=Divide"
set "BRT.X.Manifest.Export.5=Modulo"
set "BRT.X.Manifest.Export.6=FloorDivide"
set "BRT.X.Manifest.Export.7=FloorModulo"
set "BRT.X.Manifest.Export.8=Absolute"
set "BRT.X.Manifest.Export.9=Minimum"
set "BRT.X.Manifest.Export.10=Maximum"
set "BRT.X.Manifest.Export.11=Clamp"
set "BRT.X.Manifest.Export.12=Compare"
set "BRT.X.Manifest.Export.13=InRange"
set "BRT.X.Manifest.Export.14=Sign"
set "BRT.X.Manifest.Dependency.Count=0"
exit /b 0

:Describe
if /i "%~3"=="Add" goto :Describe.Add
if /i "%~3"=="Subtract" goto :Describe.Subtract
if /i "%~3"=="Multiply" goto :Describe.Multiply
if /i "%~3"=="Divide" goto :Describe.Divide
if /i "%~3"=="Modulo" goto :Describe.Modulo
if /i "%~3"=="FloorDivide" goto :Describe.FloorDivide
if /i "%~3"=="FloorModulo" goto :Describe.FloorModulo
if /i "%~3"=="Absolute" goto :Describe.Absolute
if /i "%~3"=="Minimum" goto :Describe.Minimum
if /i "%~3"=="Maximum" goto :Describe.Maximum
if /i "%~3"=="Clamp" goto :Describe.Clamp
if /i "%~3"=="Compare" goto :Describe.Compare
if /i "%~3"=="InRange" goto :Describe.InRange
if /i "%~3"=="Sign" goto :Describe.Sign
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

:Describe.Subtract
set "BRT.X.Schema.Parameter.Count=2"
set "BRT.X.Schema.Parameter.1.Name=Minuend"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Subtrahend"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Difference"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Multiply
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
set "BRT.X.Schema.Return.1.Name=Product"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Divide
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

:Describe.Modulo
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
set "BRT.X.Schema.Return.1.Name=Remainder"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
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

:Describe.FloorModulo
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
set "BRT.X.Schema.Return.1.Name=Remainder"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Absolute
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Magnitude"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Minimum
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
set "BRT.X.Schema.Return.1.Name=Value"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Maximum
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
set "BRT.X.Schema.Return.1.Name=Value"
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

:Describe.Compare
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
set "BRT.X.Schema.Return.1.Name=Comparison"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.InRange
set "BRT.X.Schema.Parameter.Count=3"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Parameter.2.Name=Minimum"
set "BRT.X.Schema.Parameter.2.Type=Int"
set "BRT.X.Schema.Parameter.2.Required=1"
set "BRT.X.Schema.Parameter.2.Position=2"
set "BRT.X.Schema.Parameter.2.HasDefault=0"
set "BRT.X.Schema.Parameter.3.Name=Maximum"
set "BRT.X.Schema.Parameter.3.Type=Int"
set "BRT.X.Schema.Parameter.3.Required=1"
set "BRT.X.Schema.Parameter.3.Position=3"
set "BRT.X.Schema.Parameter.3.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=IsInRange"
set "BRT.X.Schema.Return.1.Type=Bool"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Describe.Sign
set "BRT.X.Schema.Parameter.Count=1"
set "BRT.X.Schema.Parameter.1.Name=Value"
set "BRT.X.Schema.Parameter.1.Type=Int"
set "BRT.X.Schema.Parameter.1.Required=1"
set "BRT.X.Schema.Parameter.1.Position=1"
set "BRT.X.Schema.Parameter.1.HasDefault=0"
set "BRT.X.Schema.Return.Count=1"
set "BRT.X.Schema.Return.1.Name=Sign"
set "BRT.X.Schema.Return.1.Type=Int"
set "BRT.X.Schema.Return.1.Required=1"
exit /b 0

:Invoke
if /i "%~3"=="Add" goto :Invoke.Add
if /i "%~3"=="Subtract" goto :Invoke.Subtract
if /i "%~3"=="Multiply" goto :Invoke.Multiply
if /i "%~3"=="Divide" goto :Invoke.Divide
if /i "%~3"=="Modulo" goto :Invoke.Modulo
if /i "%~3"=="FloorDivide" goto :Invoke.FloorDivide
if /i "%~3"=="FloorModulo" goto :Invoke.FloorModulo
if /i "%~3"=="Absolute" goto :Invoke.Absolute
if /i "%~3"=="Minimum" goto :Invoke.Minimum
if /i "%~3"=="Maximum" goto :Invoke.Maximum
if /i "%~3"=="Clamp" goto :Invoke.Clamp
if /i "%~3"=="Compare" goto :Invoke.Compare
if /i "%~3"=="InRange" goto :Invoke.InRange
if /i "%~3"=="Sign" goto :Invoke.Sign
exit /b 65

:Invoke.Add
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Add"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Add "!Left!" "!Right!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Sum=%Result%"
exit /b 0

:Invoke.Subtract
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Subtract"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Subtract "!Minuend!" "!Subtrahend!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Difference=%Result%"
exit /b 0

:Invoke.Multiply
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Multiply"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Multiply "!Left!" "!Right!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Product=%Result%"
exit /b 0

:Invoke.Divide
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Divide"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Divide "!Dividend!" "!Divisor!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Quotient=%Result%"
exit /b 0

:Invoke.Modulo
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Modulo"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Modulo "!Dividend!" "!Divisor!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Remainder=%Result%"
exit /b 0

:Invoke.FloorDivide
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=FloorDivide"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :FloorDivide "!Dividend!" "!Divisor!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Quotient=%Result%"
exit /b 0

:Invoke.FloorModulo
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=FloorModulo"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :FloorModulo "!Dividend!" "!Divisor!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Remainder=%Result%"
exit /b 0

:Invoke.Absolute
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Absolute"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Absolute "!Value!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Magnitude=%Result%"
exit /b 0

:Invoke.Minimum
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Minimum"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Minimum "!Left!" "!Right!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Value=%Result%"
exit /b 0

:Invoke.Maximum
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Maximum"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Maximum "!Left!" "!Right!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Value=%Result%"
exit /b 0

:Invoke.Clamp
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Clamp"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Clamp "!Value!" "!Minimum!" "!Maximum!" Result
if errorlevel 1 goto :Invoke.FailMath
set "WasClamped=0"
if not "!Result!"=="!Value!" set "WasClamped=1"
endlocal & (
    set "BRT.O.%ReturnObject%.Value=%Result%"
    set "BRT.O.%ReturnObject%.WasClamped=%WasClamped%"
)
exit /b 0

:Invoke.Compare
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Compare"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Compare "!Left!" "!Right!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Comparison=%Result%"
exit /b 0

:Invoke.InRange
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=InRange"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :InRange "!Value!" "!Minimum!" "!Maximum!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.IsInRange=%Result%"
exit /b 0

:Invoke.Sign
setlocal EnableExtensions EnableDelayedExpansion
set "Frame=%~4"
set "ReturnObject=%~5"
set "Function=Sign"
set "MathComponent=%~dp0..\..\BatchMath\BatchMath.bat"
call "!BRT.Runtime!" :BindParameters "!Frame!"
if errorlevel 1 goto :Invoke.FailRuntime
call "!MathComponent!" :Initialize
if errorlevel 1 goto :Invoke.FailMath
call "!MathComponent!" :Sign "!Value!" Result
if errorlevel 1 goto :Invoke.FailMath
endlocal & set "BRT.O.%ReturnObject%.Sign=%Result%"
exit /b 0

:Invoke.FailMath
set "FailureExit=!errorlevel!"
set "MathErrorKind=MathOperationFailed"
set "MathErrorMessage=BatchMath operation failed without structured error."
set "MathErrorOperand="
set "MathErrorExpected=Successful BatchMath operation"
set "MathErrorActual=Missing structured error"
call "!MathComponent!" :ReadLastError Kind MathErrorKind
call "!MathComponent!" :ReadLastError Message MathErrorMessage
call "!MathComponent!" :ReadLastError Operand MathErrorOperand
call "!MathComponent!" :ReadLastError Expected MathErrorExpected
call "!MathComponent!" :ReadLastError Actual MathErrorActual
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRT.F.%Frame%.PropagatedError=1" & set "BRT.F.%Frame%.Error.Code=%FailureExit%" & set "BRT.F.%Frame%.Error.Kind=%MathErrorKind%" & set "BRT.F.%Frame%.Error.Message=%MathErrorMessage%" & set "BRT.F.%Frame%.Error.Module=Math" & set "BRT.F.%Frame%.Error.Function=%Function%" & set "BRT.F.%Frame%.Error.Parameter=%MathErrorOperand%" & set "BRT.F.%Frame%.Error.Expected=%MathErrorExpected%" & set "BRT.F.%Frame%.Error.Actual=%MathErrorActual%" & exit /b %FailureExit%

:Invoke.FailRuntime
call "!BRT.Runtime!" :ReturnError
set "FailureExit=!errorlevel!"
setlocal DisableDelayedExpansion
endlocal & endlocal & set "BRT.F.%Frame%.PropagatedError=1" & set "BRT.F.%Frame%.Error.Code=%BRT.ReturnError.Code%" & set "BRT.F.%Frame%.Error.Kind=%BRT.ReturnError.Kind%" & set "BRT.F.%Frame%.Error.Message=%BRT.ReturnError.Message%" & set "BRT.F.%Frame%.Error.Module=%BRT.ReturnError.Module%" & set "BRT.F.%Frame%.Error.Function=%BRT.ReturnError.Function%" & set "BRT.F.%Frame%.Error.Parameter=%BRT.ReturnError.Parameter%" & set "BRT.F.%Frame%.Error.Expected=%BRT.ReturnError.Expected%" & set "BRT.F.%Frame%.Error.Actual=%BRT.ReturnError.Actual%" & exit /b %FailureExit%
