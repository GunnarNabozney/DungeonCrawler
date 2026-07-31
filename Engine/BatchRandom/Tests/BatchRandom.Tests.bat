@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Random=%~dp0..\BatchRandom.bat"
set "BatchTest=%~dp0..\..\BatchRuntime\BatchTest.bat"
set "Runtime=%~dp0..\..\BatchRuntime\BatchRuntime.bat"
set "RandomModule=%~dp0..\..\BatchRuntime\Modules\Random.bat"

call "!BatchTest!" begin suite "BatchRandom 1.0 deterministic self-test"

call "!Random!" :Next Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject draws before initialization"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal RandomNotInitialized because "Report an uninitialized random component"

call "!Random!" :Initialize 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a zero seed"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidSeed because "Report a zero seed"

call "!Random!" initialize random with seed 1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize deterministic random state"

call "!Random!" read random state into StateValue and count into DrawCountValue
call "!BatchTest!" expect value "!StateValue!" to equal 1 because "Initial state matches the seed"
call "!BatchTest!" expect value "!DrawCountValue!" to equal 0 because "Initial draw count is zero"

call "!Random!" initialize random with seed 2
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Repeated initialization is idempotent"
call "!Random!" read random state into StateValue and count into DrawCountValue
call "!BatchTest!" expect value "!StateValue!" to equal 1 because "Repeated initialization preserves state"

call "!Random!" next random into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Generate the first raw value"
call "!BatchTest!" expect value "!Actual!" to equal 16807 because "First Park-Miller vector matches"
call "!Random!" next random into Actual
call "!BatchTest!" expect value "!Actual!" to equal 282475249 because "Second Park-Miller vector matches"
call "!Random!" next random into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1622650073 because "Third Park-Miller vector matches"
call "!Random!" read random state into StateValue and count into DrawCountValue
call "!BatchTest!" expect value "!StateValue!" to equal 1622650073 because "State advances with raw draws"
call "!BatchTest!" expect value "!DrawCountValue!" to equal 3 because "Raw draw count advances"

call "!Random!" restore random with state 1 and draw count 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Restore a saved generator state"
call "!Random!" next random into Actual
call "!BatchTest!" expect value "!Actual!" to equal 16807 because "Restored state resumes the same sequence"

call "!Random!" reseed random with seed 12345
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Reseed the generator"
call "!Random!" read random state into StateValue and count into DrawCountValue
call "!BatchTest!" expect value "!StateValue!" to equal 12345 because "Reseed replaces state"
call "!BatchTest!" expect value "!DrawCountValue!" to equal 0 because "Reseed resets draw count"

call "!Random!" :Reseed 1
call "!Random!" random integer from -5 to 5 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Generate an inclusive signed range"
call "!BatchTest!" expect value "!Actual!" to equal 4 because "Signed range mapping is deterministic"

call "!Random!" :Reseed 1
call "!Random!" random integer from 42 to 42 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 42 because "A single-value range returns its bound"
call "!Random!" get statistic DrawCount into DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 1 because "Single-value ranges still consume a draw"

call "!Random!" :Reseed 100000
call "!Random!" :Integer 0 1073741823 Actual
call "!BatchTest!" expect value "!Actual!" to equal 28330344 because "Rejection sampling returns the expected value"
call "!Random!" :GetState StateValue DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 4 because "Rejected values count as raw draws"

call "!Random!" :Reseed 1
call "!Random!" :Integer 5 4 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an inverted range"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidRange because "Report an inverted range"

call "!Random!" :Integer -2147483647 0 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a range wider than the generator domain"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal RangeTooWide because "Report an oversized range"
call "!Random!" :GetState StateValue DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 0 because "Range validation does not consume state"

call "!Random!" :Reseed 1
call "!Random!" random chance 25 percent into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "A deterministic 25 percent check succeeds"
call "!Random!" :Reseed 1
call "!Random!" random chance 5 percent into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "A deterministic 5 percent check fails"
call "!Random!" :Reseed 1
call "!Random!" :Chance 0 Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Zero percent always fails"
call "!Random!" get statistic DrawCount into DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 1 because "Zero percent still consumes a draw"
call "!Random!" :Reseed 1
call "!Random!" :Chance 100 Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "One hundred percent always succeeds"

call "!Random!" :Reseed 1
call "!Random!" roll 3 dice with 6 sides into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Roll multiple dice"
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Three deterministic six-sided dice total seven"
call "!Random!" :GetState StateValue DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 3 because "Dice consume one accepted draw per die"

call "!Random!" :Reseed 1
call "!Random!" :Roll 1000 2147484 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a possible dice-total overflow"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal DiceTotalOverflow because "Report dice-total overflow"
call "!Random!" :GetState StateValue DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 0 because "Dice validation does not consume state"

call "!Random!" :Reseed 1
call "!Random!" choose random index from 10 into Actual
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Choose a deterministic unweighted index"

call "!Random!" :Reseed 1
call "!Random!" choose weighted index from "1,3,6" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Choose a weighted index"
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Weighted selection uses cumulative weights"

call "!Random!" :Reseed 1
call "!Random!" :WeightedIndex "1,,2" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an empty weight"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidWeightList because "Report malformed weight lists"
call "!Random!" :WeightedIndex "1,0,2" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a zero weight"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidWeight because "Report an invalid weight"
call "!Random!" :WeightedIndex "2147483646,1" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an oversized weight total"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal WeightTotalTooLarge because "Report an oversized weight total"

call "!Random!" :Reseed 1
call "!Random!" shuffle 5 indices into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shuffle a bounded index set"
call "!BatchTest!" expect value "!Actual!" to equal 4,3,5,1,2 because "Fisher-Yates order is deterministic"
call "!Random!" :ShuffleIndices 257 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an oversized shuffle"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidShuffleCount because "Report an oversized shuffle"

call "!Random!" :Next PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidOutputVariable because "Report an unsafe output variable"

call "!Random!" :Chance 101 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a percentage above one hundred"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidPercentage because "Report an invalid percentage"

call "!Random!" :Restore 0 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an invalid restored state"
call "!Random!" :Restore 1 2147483648
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an invalid restored draw count"
call "!BatchTest!" expect value "!BRNG.LastError.Kind!" to equal InvalidDrawCount because "Report an invalid restored draw count"

call "!Random!" :Reseed 12345
for /l %%I in (1,1,6) do set "Face.%%I=0"
for /l %%I in (1,1,120) do (
    call "!Random!" :Integer 1 6 Face
    for %%F in (!Face!) do set /a Face.%%F+=1
)
call "!BatchTest!" expect value "!Face.1!" to equal 17 because "Deterministic distribution count for face one"
call "!BatchTest!" expect value "!Face.2!" to equal 20 because "Deterministic distribution count for face two"
call "!BatchTest!" expect value "!Face.3!" to equal 23 because "Deterministic distribution count for face three"
call "!BatchTest!" expect value "!Face.4!" to equal 17 because "Deterministic distribution count for face four"
call "!BatchTest!" expect value "!Face.5!" to equal 20 because "Deterministic distribution count for face five"
call "!BatchTest!" expect value "!Face.6!" to equal 23 because "Deterministic distribution count for face six"
call "!Random!" :GetState StateValue DrawCountValue
call "!BatchTest!" expect value "!DrawCountValue!" to equal 120 because "Distribution sample consumes 120 raw draws"

call "!Random!" shutdown random
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown the standalone random component"

call "!Runtime!" initialize runtime
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchRuntime for adapter tests"
if defined BT.Abort goto :Summary

call "!Runtime!" import module Random from "!RandomModule!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Import the BatchRandom adapter"
if defined BT.Abort goto :Summary

call "!Runtime!" run Random Initialize into Result with Seed 1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize random state through Runtime"
call "!Runtime!" read field State from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Runtime initialization returns state"
call "!Runtime!" read field DrawCount from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Runtime initialization returns draw count"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Next into Result
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Generate a raw value through Runtime"
call "!Runtime!" read field Value from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 16807 because "Runtime adapter preserves the deterministic sequence"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Integer into Result with Minimum -5 and Maximum 5
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Generate a signed range through Runtime"
call "!Runtime!" read field Value from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal -5 because "Runtime range uses the next generator value"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Chance into Result with Percent 75
call "!Runtime!" read field Hit from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Runtime chance returns a Boolean"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Reseed into Result with Seed 1
call "!Runtime!" release object "!Result!"
call "!Runtime!" run Random Roll into Result with Count 3 and Sides 6
call "!Runtime!" read field Total from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Runtime dice use the standalone component"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random GetState into Result
call "!Runtime!" read field State from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1622650073 because "Runtime adapter persists generator state"
call "!Runtime!" read field DrawCount from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Runtime adapter persists draw count"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Restore into Result with State 1 and DrawCount 0
call "!Runtime!" read field State from object "!Result!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Runtime restore returns the restored state"
call "!Runtime!" release object "!Result!"

call "!Runtime!" run Random Integer into ShouldNotExist with Minimum -2147483647 and Maximum 0
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Propagate a Random adapter range failure"
call "!Runtime!" read field Kind from object "!BRT.LastError!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal RangeTooWide because "Preserve the Random component error kind"
call "!Runtime!" clear last error

call "!Runtime!" get statistic ObjectCount into Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Runtime adapter tests release all objects"

call "!Runtime!" shutdown runtime
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown BatchRuntime after adapter tests"

call "!Random!" shutdown random
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown adapter-owned random state"

:Summary
call "!BatchTest!" finish suite
exit /b !errorlevel!
