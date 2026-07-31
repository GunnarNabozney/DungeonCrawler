@echo off

rem BatchRandom.bat
rem Project-agnostic deterministic random generation for Windows batch files.
rem Version 1.0.0 - protocol 1.
rem Requirement: caller must enable command extensions and delayed expansion.

set "BRNG.Internal.DelayedProbe=1"
if not "!BRNG.Internal.DelayedProbe!"=="1" (
    echo BatchRandom requires delayed expansion.
    echo Start the caller with: setlocal EnableExtensions EnableDelayedExpansion
    exit /b 61
)

if /i "%~1"=="initialize" goto :Readable.Initialize
if /i "%~1"=="shutdown" goto :Readable.Shutdown
if /i "%~1"=="reseed" goto :Readable.Reseed
if /i "%~1"=="restore" goto :Readable.Restore
if /i "%~1"=="next" goto :Readable.Next
if /i "%~1"=="random" goto :Readable.Random
if /i "%~1"=="roll" goto :Readable.Roll
if /i "%~1"=="choose" goto :Readable.Choose
if /i "%~1"=="shuffle" goto :Readable.Shuffle
if /i "%~1"=="read" goto :Readable.Read
if /i "%~1"=="get" goto :Readable.Get
if /i "%~1"=="show" goto :Readable.Show
if /i "%~1"=="clear" goto :Readable.Clear
if /i "%~1"==":Initialize" goto :Initialize
if /i "%~1"==":Shutdown" goto :Shutdown
if /i "%~1"==":Reseed" goto :Reseed
if /i "%~1"==":Restore" goto :Restore
if /i "%~1"==":Next" goto :Next
if /i "%~1"==":Integer" goto :Integer
if /i "%~1"==":Chance" goto :Chance
if /i "%~1"==":Roll" goto :Roll
if /i "%~1"==":ChooseIndex" goto :ChooseIndex
if /i "%~1"==":WeightedIndex" goto :WeightedIndex
if /i "%~1"==":ShuffleIndices" goto :ShuffleIndices
if /i "%~1"==":GetState" goto :GetState
if /i "%~1"==":GetStat" goto :GetStat
if /i "%~1"==":ReadLastError" goto :ReadLastError
if /i "%~1"==":PrintLastError" goto :PrintLastError
if /i "%~1"==":ClearLastError" goto :ClearLastError

call :SetError 10 UnknownRandomCommand "Unknown BatchRandom command." "" "" "Known random command" "%~1"
exit /b 10

:Readable.Initialize
if /i not "%~2"=="random" goto :Readable.Syntax
if /i not "%~3"=="with" goto :Readable.Syntax
if /i not "%~4"=="seed" goto :Readable.Syntax
call "%~f0" :Initialize "%~5"
exit /b !errorlevel!

:Readable.Shutdown
if /i not "%~2"=="random" goto :Readable.Syntax
call "%~f0" :Shutdown
exit /b !errorlevel!

:Readable.Reseed
if /i not "%~2"=="random" goto :Readable.Syntax
if /i not "%~3"=="with" goto :Readable.Syntax
if /i not "%~4"=="seed" goto :Readable.Syntax
call "%~f0" :Reseed "%~5"
exit /b !errorlevel!

:Readable.Restore
if /i not "%~2"=="random" goto :Readable.Syntax
if /i not "%~3"=="with" goto :Readable.Syntax
if /i not "%~4"=="state" goto :Readable.Syntax
if /i not "%~6"=="and" goto :Readable.Syntax
if /i not "%~7"=="draw" goto :Readable.Syntax
if /i not "%~8"=="count" goto :Readable.Syntax
call "%~f0" :Restore "%~5" "%~9"
exit /b !errorlevel!

:Readable.Next
if /i not "%~2"=="random" goto :Readable.Syntax
if /i not "%~3"=="into" goto :Readable.Syntax
call "%~f0" :Next "%~4"
exit /b !errorlevel!

:Readable.Random
if /i "%~2"=="integer" goto :Readable.RandomInteger
if /i "%~2"=="chance" goto :Readable.RandomChance
goto :Readable.Syntax

:Readable.RandomInteger
if /i not "%~3"=="from" goto :Readable.Syntax
if /i not "%~5"=="to" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Integer "%~4" "%~6" "%~8"
exit /b !errorlevel!

:Readable.RandomChance
if /i not "%~4"=="percent" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :Chance "%~3" "%~6"
exit /b !errorlevel!

:Readable.Roll
if /i not "%~3"=="dice" goto :Readable.Syntax
if /i not "%~4"=="with" goto :Readable.Syntax
if /i not "%~6"=="sides" goto :Readable.Syntax
if /i not "%~7"=="into" goto :Readable.Syntax
call "%~f0" :Roll "%~2" "%~5" "%~8"
exit /b !errorlevel!

:Readable.Choose
if /i "%~2"=="random" goto :Readable.ChooseRandom
if /i "%~2"=="weighted" goto :Readable.ChooseWeighted
goto :Readable.Syntax

:Readable.ChooseRandom
if /i not "%~3"=="index" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :ChooseIndex "%~5" "%~7"
exit /b !errorlevel!

:Readable.ChooseWeighted
if /i not "%~3"=="index" goto :Readable.Syntax
if /i not "%~4"=="from" goto :Readable.Syntax
if /i not "%~6"=="into" goto :Readable.Syntax
call "%~f0" :WeightedIndex "%~5" "%~7"
exit /b !errorlevel!

:Readable.Shuffle
if /i not "%~3"=="indices" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :ShuffleIndices "%~2" "%~5"
exit /b !errorlevel!

:Readable.Read
if /i "%~2"=="random" goto :Readable.ReadState
if /i "%~2"=="last" goto :Readable.ReadLastError
goto :Readable.Syntax

:Readable.ReadState
if /i not "%~3"=="state" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
if /i not "%~6"=="and" goto :Readable.Syntax
if /i not "%~7"=="count" goto :Readable.Syntax
if /i not "%~8"=="into" goto :Readable.Syntax
call "%~f0" :GetState "%~5" "%~9"
exit /b !errorlevel!

:Readable.ReadLastError
if /i not "%~3"=="error" goto :Readable.Syntax
if /i not "%~5"=="into" goto :Readable.Syntax
call "%~f0" :ReadLastError "%~4" "%~6"
exit /b !errorlevel!

:Readable.Get
if /i not "%~2"=="statistic" goto :Readable.Syntax
if /i not "%~4"=="into" goto :Readable.Syntax
call "%~f0" :GetStat "%~3" "%~5"
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
call :SetError 10 InvalidRandomSyntax "BatchRandom command syntax is invalid." "" "" "Valid readable command" "%*"
exit /b 10

:Initialize
if defined BRNG.Initialized (
    call :ClearLastErrorInternal
    exit /b 0
)
call :PrepareSeed "%~2" Initialize
if errorlevel 1 exit /b !errorlevel!
call :Initialize.Commit "!BRNG.Internal.PreparedSeed!"
exit /b !errorlevel!

:Initialize.Commit
call :ClearPrefix "BRNG."
set "BRNG.Initialized=1"
set "BRNG.Version=1.0.0"
set "BRNG.Protocol=1"
set "BRNG.Algorithm=ParkMillerSchrage"
set "BRNG.State=%~1"
set "BRNG.DrawCount=0"
call :ClearLastErrorInternal
exit /b 0

:Shutdown
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearPrefix "BRNG."
exit /b 0

:Reseed
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareSeed "%~2" Reseed
if errorlevel 1 exit /b !errorlevel!
set "BRNG.State=!BRNG.Internal.PreparedSeed!"
set "BRNG.DrawCount=0"
exit /b 0

:Restore
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareSeed "%~2" Restore
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Restore.State=!BRNG.Internal.PreparedSeed!"
call :NormalizeUInt32 "%~3"
if errorlevel 1 (
    call :SetError 20 InvalidDrawCount "Draw count must be an unsigned 32-bit integer." Restore DrawCount "0 through 2147483647" "%~3"
    exit /b 20
)
set "BRNG.State=!BRNG.Internal.Restore.State!"
set "BRNG.DrawCount=!BRNG.Internal.UIntNormalized!"
exit /b 0

:Next
call :BeginOutput Next "%~2"
if errorlevel 1 exit /b !errorlevel!
call :NextRaw
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Raw!"
exit /b 0

:Integer
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareRange Integer "%~2" "%~3"
if errorlevel 1 exit /b !errorlevel!
call :PrepareOutput "%~4" Integer
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~4"
call :GenerateIntegerPrepared
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Generated!"
exit /b 0

:Chance
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :NormalizeUInt32 "%~2"
if errorlevel 1 (
    call :SetError 20 InvalidPercentage "Chance percentage must be an unsigned integer." Chance Percent "0 through 100" "%~2"
    exit /b 20
)
if !BRNG.Internal.UIntNormalized! GTR 100 (
    call :SetError 20 InvalidPercentage "Chance percentage cannot exceed 100." Chance Percent "0 through 100" "!BRNG.Internal.UIntNormalized!"
    exit /b 20
)
set "BRNG.Internal.Chance.Percent=!BRNG.Internal.UIntNormalized!"
call :PrepareOutput "%~3" Chance
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~3"
set "BRNG.Internal.Range.Minimum=1"
set "BRNG.Internal.Range.Width=100"
call :GenerateIntegerPrepared
set "BRNG.Internal.Chance.Hit=0"
if !BRNG.Internal.Generated! LEQ !BRNG.Internal.Chance.Percent! set "BRNG.Internal.Chance.Hit=1"
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Chance.Hit!"
exit /b 0

:Roll
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :NormalizeUInt32 "%~2"
if errorlevel 1 goto :Roll.InvalidCount
set "BRNG.Internal.Roll.Count=!BRNG.Internal.UIntNormalized!"
if !BRNG.Internal.Roll.Count! LSS 1 goto :Roll.InvalidCount
if !BRNG.Internal.Roll.Count! GTR 1000 goto :Roll.InvalidCount
call :NormalizeUInt32 "%~3"
if errorlevel 1 goto :Roll.InvalidSides
set "BRNG.Internal.Roll.Sides=!BRNG.Internal.UIntNormalized!"
if !BRNG.Internal.Roll.Sides! LSS 1 goto :Roll.InvalidSides
if !BRNG.Internal.Roll.Sides! GTR 2147483646 goto :Roll.InvalidSides
call :PrepareOutput "%~4" Roll
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~4"
set /a BRNG.Internal.Roll.MaximumSides=2147483647/BRNG.Internal.Roll.Count
if !BRNG.Internal.Roll.Sides! GTR !BRNG.Internal.Roll.MaximumSides! (
    call :SetError 30 DiceTotalOverflow "The maximum dice total exceeds signed 32-bit range." Roll Dice "Total no greater than 2147483647" "!BRNG.Internal.Roll.Count!d!BRNG.Internal.Roll.Sides!"
    exit /b 30
)
set "BRNG.Internal.Roll.Total=0"
set "BRNG.Internal.Roll.Index=1"
set "BRNG.Internal.Range.Minimum=1"
set "BRNG.Internal.Range.Width=!BRNG.Internal.Roll.Sides!"
:Roll.Next
if !BRNG.Internal.Roll.Index! GTR !BRNG.Internal.Roll.Count! goto :Roll.Done
call :GenerateIntegerPrepared
set /a BRNG.Internal.Roll.Total+=BRNG.Internal.Generated
set /a BRNG.Internal.Roll.Index+=1
goto :Roll.Next
:Roll.Done
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Roll.Total!"
exit /b 0
:Roll.InvalidCount
call :SetError 20 InvalidDiceCount "Dice count must be between 1 and 1000." Roll Count "1 through 1000" "%~2"
exit /b 20
:Roll.InvalidSides
call :SetError 20 InvalidDiceSides "Dice sides must be between 1 and 2147483646." Roll Sides "1 through 2147483646" "%~3"
exit /b 20

:ChooseIndex
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :NormalizeUInt32 "%~2"
if errorlevel 1 goto :ChooseIndex.InvalidCount
set "BRNG.Internal.Choose.Count=!BRNG.Internal.UIntNormalized!"
if !BRNG.Internal.Choose.Count! LSS 1 goto :ChooseIndex.InvalidCount
if !BRNG.Internal.Choose.Count! GTR 2147483646 goto :ChooseIndex.InvalidCount
call :PrepareOutput "%~3" ChooseIndex
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~3"
set "BRNG.Internal.Range.Minimum=1"
set "BRNG.Internal.Range.Width=!BRNG.Internal.Choose.Count!"
call :GenerateIntegerPrepared
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Generated!"
exit /b 0
:ChooseIndex.InvalidCount
call :SetError 20 InvalidChoiceCount "Choice count must be between 1 and 2147483646." ChooseIndex Count "1 through 2147483646" "%~2"
exit /b 20

:WeightedIndex
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareOutput "%~3" WeightedIndex
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~3"
set "BRNG.Internal.Weighted.Input=%~2"
call :ClearPrefix "BRNG.Internal.Weight."
if not defined BRNG.Internal.Weighted.Input goto :WeightedIndex.InvalidList
if not "!BRNG.Internal.Weighted.Input:~512,1!"=="" goto :WeightedIndex.InvalidList
if "!BRNG.Internal.Weighted.Input:~0,1!"=="," goto :WeightedIndex.InvalidList
if "!BRNG.Internal.Weighted.Input:~-1!"=="," goto :WeightedIndex.InvalidList
if not "!BRNG.Internal.Weighted.Input:,,=!"=="!BRNG.Internal.Weighted.Input!" goto :WeightedIndex.InvalidList
set "BRNG.Internal.Weighted.Remaining=!BRNG.Internal.Weighted.Input!"
set "BRNG.Internal.Weighted.Count=0"
set "BRNG.Internal.Weighted.Total=0"
:WeightedIndex.Parse
set "BRNG.Internal.Weighted.Item="
set "BRNG.Internal.Weighted.Rest="
for /f "tokens=1,* delims=," %%A in ("!BRNG.Internal.Weighted.Remaining!") do (
    set "BRNG.Internal.Weighted.Item=%%~A"
    set "BRNG.Internal.Weighted.Rest=%%~B"
)
call :NormalizeUInt32 "!BRNG.Internal.Weighted.Item!"
if errorlevel 1 goto :WeightedIndex.InvalidWeight
set "BRNG.Internal.Weighted.Value=!BRNG.Internal.UIntNormalized!"
if !BRNG.Internal.Weighted.Value! LSS 1 goto :WeightedIndex.InvalidWeight
set /a BRNG.Internal.Weighted.Count+=1
if !BRNG.Internal.Weighted.Count! GTR 64 goto :WeightedIndex.TooMany
set /a BRNG.Internal.Weighted.MaximumPrior=2147483646-BRNG.Internal.Weighted.Value
if !BRNG.Internal.Weighted.Total! GTR !BRNG.Internal.Weighted.MaximumPrior! goto :WeightedIndex.TotalTooLarge
set /a BRNG.Internal.Weighted.Total+=BRNG.Internal.Weighted.Value
set "BRNG.Internal.Weight.Cumulative.!BRNG.Internal.Weighted.Count!=!BRNG.Internal.Weighted.Total!"
if defined BRNG.Internal.Weighted.Rest (
    set "BRNG.Internal.Weighted.Remaining=!BRNG.Internal.Weighted.Rest!"
    goto :WeightedIndex.Parse
)
set "BRNG.Internal.Range.Minimum=1"
set "BRNG.Internal.Range.Width=!BRNG.Internal.Weighted.Total!"
call :GenerateIntegerPrepared
set "BRNG.Internal.Weighted.Ticket=!BRNG.Internal.Generated!"
set "BRNG.Internal.Weighted.Index=1"
:WeightedIndex.Select
for %%I in (!BRNG.Internal.Weighted.Index!) do set "BRNG.Internal.Weighted.Cumulative=!BRNG.Internal.Weight.Cumulative.%%I!"
if !BRNG.Internal.Weighted.Ticket! LEQ !BRNG.Internal.Weighted.Cumulative! goto :WeightedIndex.Selected
set /a BRNG.Internal.Weighted.Index+=1
goto :WeightedIndex.Select
:WeightedIndex.Selected
set "BRNG.Internal.Weighted.Result=!BRNG.Internal.Weighted.Index!"
call :ClearPrefix "BRNG.Internal.Weight."
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.Weighted.Result!"
exit /b 0
:WeightedIndex.InvalidList
call :SetError 20 InvalidWeightList "Weights must be a comma-separated list of positive integers." WeightedIndex Weights "One through 64 positive weights" "%~2"
call :ClearPrefix "BRNG.Internal.Weight."
exit /b 20
:WeightedIndex.InvalidWeight
call :SetError 20 InvalidWeight "Every weight must be a positive unsigned integer." WeightedIndex Weights "Positive unsigned integer" "!BRNG.Internal.Weighted.Item!"
call :ClearPrefix "BRNG.Internal.Weight."
exit /b 20
:WeightedIndex.TooMany
call :SetError 20 TooManyWeights "Weighted choice supports at most 64 entries." WeightedIndex Weights "1 through 64 entries" "!BRNG.Internal.Weighted.Count!"
call :ClearPrefix "BRNG.Internal.Weight."
exit /b 20
:WeightedIndex.TotalTooLarge
call :SetError 20 WeightTotalTooLarge "Weight total cannot exceed 2147483646." WeightedIndex Weights "Total no greater than 2147483646" "!BRNG.Internal.Weighted.Input!"
call :ClearPrefix "BRNG.Internal.Weight."
exit /b 20

:ShuffleIndices
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :NormalizeUInt32 "%~2"
if errorlevel 1 goto :ShuffleIndices.InvalidCount
set "BRNG.Internal.ShuffleCount=!BRNG.Internal.UIntNormalized!"
if !BRNG.Internal.ShuffleCount! LSS 1 goto :ShuffleIndices.InvalidCount
if !BRNG.Internal.ShuffleCount! GTR 256 goto :ShuffleIndices.InvalidCount
call :PrepareOutput "%~3" ShuffleIndices
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~3"
call :ClearPrefix "BRNG.Internal.Shuffle."
for /l %%I in (1,1,!BRNG.Internal.ShuffleCount!) do set "BRNG.Internal.Shuffle.%%I=%%I"
set "BRNG.Internal.ShuffleIndex=!BRNG.Internal.ShuffleCount!"
:ShuffleIndices.Swap
if !BRNG.Internal.ShuffleIndex! LEQ 1 goto :ShuffleIndices.Build
set "BRNG.Internal.Range.Minimum=1"
set "BRNG.Internal.Range.Width=!BRNG.Internal.ShuffleIndex!"
call :GenerateIntegerPrepared
set "BRNG.Internal.ShuffleChoice=!BRNG.Internal.Generated!"
for %%I in (!BRNG.Internal.ShuffleIndex!) do for %%J in (!BRNG.Internal.ShuffleChoice!) do (
    set "BRNG.Internal.ShuffleTemp=!BRNG.Internal.Shuffle.%%I!"
    set "BRNG.Internal.Shuffle.%%I=!BRNG.Internal.Shuffle.%%J!"
    set "BRNG.Internal.Shuffle.%%J=!BRNG.Internal.ShuffleTemp!"
)
set /a BRNG.Internal.ShuffleIndex-=1
goto :ShuffleIndices.Swap
:ShuffleIndices.Build
set "BRNG.Internal.ShuffleResult="
for /l %%I in (1,1,!BRNG.Internal.ShuffleCount!) do (
    if defined BRNG.Internal.ShuffleResult (
        set "BRNG.Internal.ShuffleResult=!BRNG.Internal.ShuffleResult!,!BRNG.Internal.Shuffle.%%I!"
    ) else (
        set "BRNG.Internal.ShuffleResult=!BRNG.Internal.Shuffle.%%I!"
    )
)
call :ClearPrefix "BRNG.Internal.Shuffle."
call :ExportResult "!BRNG.Internal.Output!" "!BRNG.Internal.ShuffleResult!"
exit /b 0
:ShuffleIndices.InvalidCount
call :SetError 20 InvalidShuffleCount "Shuffle count must be between 1 and 256." ShuffleIndices Count "1 through 256" "%~2"
exit /b 20

:GetState
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareOutput "%~2" GetState
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.GetState.StateOutput=%~2"
call :PrepareOutput "%~3" GetState
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.GetState.CountOutput=%~3"
if /i "!BRNG.Internal.GetState.StateOutput!"=="!BRNG.Internal.GetState.CountOutput!" (
    call :SetError 10 DuplicateOutputVariable "State and draw count require different output variables." GetState Output "Two different output variables" "!BRNG.Internal.GetState.StateOutput!"
    exit /b 10
)
call :ExportResult "!BRNG.Internal.GetState.StateOutput!" "!BRNG.State!"
call :ExportResult "!BRNG.Internal.GetState.CountOutput!" "!BRNG.DrawCount!"
exit /b 0

:GetStat
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareOutput "%~3" GetStat
if errorlevel 1 exit /b !errorlevel!
if /i "%~2"=="DrawCount" (
    call :ExportResult "%~3" "!BRNG.DrawCount!"
    exit /b 0
)
if /i "%~2"=="State" (
    call :ExportResult "%~3" "!BRNG.State!"
    exit /b 0
)
call :SetError 20 UnknownRandomStatistic "Unknown BatchRandom statistic." GetStat Statistic "DrawCount or State" "%~2"
exit /b 20

:ReadLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.ReadError.Field=%~2"
set "BRNG.Internal.ReadError.Output=%~3"
call :ValidateErrorField "!BRNG.Internal.ReadError.Field!"
if errorlevel 1 (
    call :SetError 20 UnknownErrorField "Unknown BatchRandom error field." ReadLastError Field "Code, Kind, Message, Operation, Parameter, Expected, or Actual" "!BRNG.Internal.ReadError.Field!"
    exit /b 20
)
call :PrepareOutput "!BRNG.Internal.ReadError.Output!" ReadLastError
if errorlevel 1 exit /b !errorlevel!
for %%F in ("!BRNG.Internal.ReadError.Field!") do set "BRNG.Internal.ReadError.Value=!BRNG.LastError.%%~F!"
call :ExportResult "!BRNG.Internal.ReadError.Output!" "!BRNG.Internal.ReadError.Value!"
exit /b 0

:PrintLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
echo Code: !BRNG.LastError.Code!
echo Kind: !BRNG.LastError.Kind!
echo Message: !BRNG.LastError.Message!
echo Operation: !BRNG.LastError.Operation!
echo Parameter: !BRNG.LastError.Parameter!
echo Expected: !BRNG.LastError.Expected!
echo Actual: !BRNG.LastError.Actual!
exit /b 0

:ClearLastError
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
exit /b 0

:BeginOutput
call :RequireInitialized
if errorlevel 1 exit /b !errorlevel!
call :ClearLastErrorInternal
call :PrepareOutput "%~2" "%~1"
if errorlevel 1 exit /b !errorlevel!
set "BRNG.Internal.Output=%~2"
exit /b 0

:PrepareSeed
call :NormalizeUInt32 "%~1"
if errorlevel 1 (
    call :SetError 20 InvalidSeed "Random seed must be a positive unsigned integer." "%~2" Seed "1 through 2147483646" "%~1"
    exit /b 20
)
if !BRNG.Internal.UIntNormalized! LSS 1 (
    call :SetError 20 InvalidSeed "Random seed cannot be zero." "%~2" Seed "1 through 2147483646" "!BRNG.Internal.UIntNormalized!"
    exit /b 20
)
if !BRNG.Internal.UIntNormalized! GTR 2147483646 (
    call :SetError 20 InvalidSeed "Random seed exceeds the generator state range." "%~2" Seed "1 through 2147483646" "!BRNG.Internal.UIntNormalized!"
    exit /b 20
)
set "BRNG.Internal.PreparedSeed=!BRNG.Internal.UIntNormalized!"
exit /b 0

:PrepareRange
call :NormalizeInt32 "%~2"
if errorlevel 1 (
    call :SetError 20 InvalidRangeBound "Minimum is not a signed 32-bit integer." "%~1" Minimum "-2147483648 through 2147483647" "%~2"
    exit /b 20
)
set "BRNG.Internal.Range.Minimum=!BRNG.Internal.IntNormalized!"
call :NormalizeInt32 "%~3"
if errorlevel 1 (
    call :SetError 20 InvalidRangeBound "Maximum is not a signed 32-bit integer." "%~1" Maximum "-2147483648 through 2147483647" "%~3"
    exit /b 20
)
set "BRNG.Internal.Range.Maximum=!BRNG.Internal.IntNormalized!"
if !BRNG.Internal.Range.Minimum! GTR !BRNG.Internal.Range.Maximum! (
    call :SetError 20 InvalidRange "Minimum cannot be greater than maximum." "%~1" Range "Minimum less than or equal to maximum" "!BRNG.Internal.Range.Minimum! through !BRNG.Internal.Range.Maximum!"
    exit /b 20
)
set /a BRNG.Internal.Range.Difference=BRNG.Internal.Range.Maximum-BRNG.Internal.Range.Minimum
if !BRNG.Internal.Range.Minimum! LSS 0 if !BRNG.Internal.Range.Maximum! GEQ 0 if !BRNG.Internal.Range.Difference! LSS 0 goto :PrepareRange.TooWide
set /a BRNG.Internal.Range.Width=BRNG.Internal.Range.Difference+1
if !BRNG.Internal.Range.Width! LEQ 0 goto :PrepareRange.TooWide
if !BRNG.Internal.Range.Width! GTR 2147483646 goto :PrepareRange.TooWide
exit /b 0
:PrepareRange.TooWide
call :SetError 20 RangeTooWide "Random integer ranges support at most 2147483646 values." "%~1" Range "Inclusive width no greater than 2147483646" "!BRNG.Internal.Range.Minimum! through !BRNG.Internal.Range.Maximum!"
exit /b 20

:PrepareOutput
call :ValidateOutputVariable "%~1"
if errorlevel 1 (
    call :SetError 10 InvalidOutputVariable "Output variables must be safe identifiers." "%~2" Output "Non-reserved identifier" "%~1"
    exit /b 10
)
exit /b 0

:GenerateIntegerPrepared
set /a BRNG.Internal.Range.Remainder=2147483646%%BRNG.Internal.Range.Width
set /a BRNG.Internal.Range.Limit=2147483646-BRNG.Internal.Range.Remainder
:GenerateIntegerPrepared.Draw
call :NextRaw
set /a BRNG.Internal.Range.ZeroBased=BRNG.Internal.Raw-1
if !BRNG.Internal.Range.ZeroBased! GEQ !BRNG.Internal.Range.Limit! goto :GenerateIntegerPrepared.Draw
set /a BRNG.Internal.Range.Offset=BRNG.Internal.Range.ZeroBased%%BRNG.Internal.Range.Width
set /a BRNG.Internal.Generated=BRNG.Internal.Range.Minimum+BRNG.Internal.Range.Offset
exit /b 0

:NextRaw
set /a BRNG.Internal.Next.High=BRNG.State/127773
set /a BRNG.Internal.Next.Low=BRNG.State%%127773
set /a BRNG.Internal.Next.Value=16807*BRNG.Internal.Next.Low-2836*BRNG.Internal.Next.High
if !BRNG.Internal.Next.Value! LEQ 0 set /a BRNG.Internal.Next.Value+=2147483647
set "BRNG.State=!BRNG.Internal.Next.Value!"
if !BRNG.DrawCount! LSS 2147483647 set /a BRNG.DrawCount+=1
set "BRNG.Internal.Raw=!BRNG.State!"
exit /b 0

:ExportResult
for %%O in ("%~1") do set "%%~O=%~2"
exit /b 0

:RequireInitialized
if defined BRNG.Initialized exit /b 0
call :SetError 50 RandomNotInitialized "BatchRandom has not been initialized." "" "" "initialize random with seed" "Not initialized"
exit /b 50

:NormalizeUInt32
set "BRNGValidationResult="
call "%~dp0..\BatchValidate\BatchValidate.bat" :UInt32 "%~1" BRNGValidationResult
if errorlevel 1 (
    set "BRNGValidationResult="
    exit /b 1
)
set "BRNG.Internal.UIntNormalized=!BRNGValidationResult!"
set "BRNGValidationResult="
exit /b 0

:NormalizeInt32
set "BRNGValidationResult="
call "%~dp0..\BatchValidate\BatchValidate.bat" :Int32 "%~1" BRNGValidationResult
if errorlevel 1 (
    set "BRNGValidationResult="
    exit /b 1
)
set "BRNG.Internal.IntNormalized=!BRNGValidationResult!"
set "BRNGValidationResult="
exit /b 0

:ValidateOutputVariable
set "BRNGValidationResult="
call "%~dp0..\BatchValidate\BatchValidate.bat" :Apply "%~1" "Identifier+Not=PATH,ERRORLEVEL,RANDOM,TEMP,TMP,COMSPEC,CD,CMDEXTVERSION,CMDCMDLINE,DATE,TIME,PATHEXT,Frame,ReturnObject+NotPrefix=BRT,BV" BRNGValidationResult
if errorlevel 1 (
    set "BRNGValidationResult="
    exit /b 1
)
set "BRNGValidationResult="
exit /b 0

:ValidateId
set "BRNGValidationResult="
call "%~dp0..\BatchValidate\BatchValidate.bat" :Identifier "%~1" BRNGValidationResult
if errorlevel 1 (
    set "BRNGValidationResult="
    exit /b 1
)
set "BRNGValidationResult="
exit /b 0


:ValidateErrorField
for %%F in (Code Kind Message Operation Parameter Expected Actual) do if /i "%~1"=="%%F" exit /b 0
exit /b 1

:ClearLastErrorInternal
set "BRNG.LastError.Code=0"
set "BRNG.LastError.Kind=None"
set "BRNG.LastError.Message="
set "BRNG.LastError.Operation="
set "BRNG.LastError.Parameter="
set "BRNG.LastError.Expected="
set "BRNG.LastError.Actual="
exit /b 0

:SetError
set "BRNG.LastError.Code=%~1"
set "BRNG.LastError.Kind=%~2"
set "BRNG.LastError.Message=%~3"
set "BRNG.LastError.Operation=%~4"
set "BRNG.LastError.Parameter=%~5"
set "BRNG.LastError.Expected=%~6"
set "BRNG.LastError.Actual=%~7"
exit /b 0

:ClearPrefix
for /f "tokens=1 delims==" %%V in ('set %~1 2^>nul') do set "%%V="
exit /b 0
