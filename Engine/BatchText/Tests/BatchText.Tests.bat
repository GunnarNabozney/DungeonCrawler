@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Text=%~dp0..\BatchText.bat"
set "BatchTest=%~dp0..\..\BatchRuntime\BatchTest.bat"
set "FixtureBuilder=%~dp0Create-BatchTextFixtures.ps1"
set "PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "FixtureRoot=%TEMP%\BatchText-Tests-!RANDOM!-!RANDOM!"
set "MarkerPath=!FixtureRoot!\injected.marker"
set "Handles="

call "!BatchTest!" begin suite "BatchText 1.0 deterministic self-test"

"!PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!FixtureBuilder!" -Root "!FixtureRoot!" -MarkerPath "!MarkerPath!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create exact byte fixtures"
if defined BT.Abort goto :Summary

call "!Text!" initialize text
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchText"
if defined BT.Abort goto :Summary

call "!Text!" get statistic TextCount into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read initial text count"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Text count starts at zero"

set "EmptyHandle="
call "!Text!" create empty text into EmptyHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create an empty text handle"
if defined BT.Abort goto :Summary
call :TrackHandle "!EmptyHandle!"
call "!Text!" get length of text "!EmptyHandle!" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Measure empty text"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Empty text has zero bytes"
call "!Text!" save text "!EmptyHandle!" to "!FixtureRoot!\empty-roundtrip.bin"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Save empty text"
call :ExpectFilesEqual "!FixtureRoot!\empty.bin" "!FixtureRoot!\empty-roundtrip.bin" "Empty text round-trips byte-for-byte"

set "SpecialHandle="
call "!Text!" load text from "!FixtureRoot!\special.bin" into SpecialHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load command-sensitive text"
if defined BT.Abort goto :Summary
call :TrackHandle "!SpecialHandle!"
call "!Text!" save text "!SpecialHandle!" to "!FixtureRoot!\special-roundtrip.bin"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Save command-sensitive text"
call :ExpectFilesEqual "!FixtureRoot!\special.bin" "!FixtureRoot!\special-roundtrip.bin" "Percent, bang, metacharacters, quotes, and multiline bytes round-trip"
set /p "ExpectedLength="<"!FixtureRoot!\special.length.txt"
call "!Text!" get length of text "!SpecialHandle!" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Measure command-sensitive text"
call "!BatchTest!" expect value "!Actual!" to equal "!ExpectedLength!" because "Length reports exact stored byte count"

set "AllBytesHandle="
call "!Text!" :Load "!FixtureRoot!\allbytes.bin" AllBytesHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load every byte value"
if defined BT.Abort goto :Summary
call :TrackHandle "!AllBytesHandle!"
call "!Text!" :Save "!AllBytesHandle!" "!FixtureRoot!\allbytes-roundtrip.bin"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Save every byte value"
call :ExpectFilesEqual "!FixtureRoot!\allbytes.bin" "!FixtureRoot!\allbytes-roundtrip.bin" "All 256 byte values round-trip without transcoding"
call "!Text!" :Length "!AllBytesHandle!" Actual
call "!BatchTest!" expect value "!Actual!" to equal 256 because "Opaque byte length includes zero and high bytes"

set "SpecialClone="
call "!Text!" :Load "!FixtureRoot!\special.bin" SpecialClone
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load an identical comparison handle"
if defined BT.Abort goto :Summary
call :TrackHandle "!SpecialClone!"
call "!Text!" compare text "!SpecialHandle!" with "!SpecialClone!" into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Compare identical text handles"
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Identical byte streams compare equal"
call "!Text!" :Compare "!SpecialHandle!" "!AllBytesHandle!" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Compare different text handles"
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Different byte streams compare unequal"

set "AlphaHandle="
set "BetaHandle="
call "!Text!" :Load "!FixtureRoot!\alpha.bin" AlphaHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load append target text"
if defined BT.Abort goto :Summary
call :TrackHandle "!AlphaHandle!"
call "!Text!" :Load "!FixtureRoot!\beta.bin" BetaHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load append source text"
if defined BT.Abort goto :Summary
call :TrackHandle "!BetaHandle!"
call "!Text!" append text "!BetaHandle!" to "!AlphaHandle!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Append one text handle to another"
call "!Text!" :Save "!AlphaHandle!" "!FixtureRoot!\append-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\alphabeta.bin" "!FixtureRoot!\append-result.bin" "Append writes exact source bytes without a separator"
call "!Text!" :Save "!BetaHandle!" "!FixtureRoot!\append-source-after.bin"
call :ExpectFilesEqual "!FixtureRoot!\beta.bin" "!FixtureRoot!\append-source-after.bin" "Append leaves the source handle unchanged"
call "!Text!" :Append "!BetaHandle!" "!EmptyHandle!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Append empty text"
call "!Text!" :Save "!BetaHandle!" "!FixtureRoot!\append-empty-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\beta.bin" "!FixtureRoot!\append-empty-result.bin" "Appending empty text changes no bytes"

set "SelfHandle="
call "!Text!" :Load "!FixtureRoot!\alpha.bin" SelfHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load self-append text"
if defined BT.Abort goto :Summary
call :TrackHandle "!SelfHandle!"
call "!Text!" :Append "!SelfHandle!" "!SelfHandle!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Append a handle to itself"
call "!Text!" :Save "!SelfHandle!" "!FixtureRoot!\self-append-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\alphaalpha.bin" "!FixtureRoot!\self-append-result.bin" "Self-append duplicates the original bytes exactly"

set "LeftHandle="
set "RightHandle="
set "ConcatHandle="
call "!Text!" :Load "!FixtureRoot!\left.bin" LeftHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load concatenate left text"
if defined BT.Abort goto :Summary
call :TrackHandle "!LeftHandle!"
call "!Text!" :Load "!FixtureRoot!\right.bin" RightHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load concatenate right text"
if defined BT.Abort goto :Summary
call :TrackHandle "!RightHandle!"
call "!Text!" concatenate text "!LeftHandle!" with "!RightHandle!" into ConcatHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Concatenate two text handles"
if defined BT.Abort goto :Summary
call :TrackHandle "!ConcatHandle!"
call "!Text!" :Save "!ConcatHandle!" "!FixtureRoot!\concat-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\leftright.bin" "!FixtureRoot!\concat-result.bin" "Concatenate inserts no newline or separator"
call "!Text!" :Save "!LeftHandle!" "!FixtureRoot!\concat-left-after.bin"
call :ExpectFilesEqual "!FixtureRoot!\left.bin" "!FixtureRoot!\concat-left-after.bin" "Concatenate leaves the left input unchanged"
call "!Text!" :Save "!RightHandle!" "!FixtureRoot!\concat-right-after.bin"
call :ExpectFilesEqual "!FixtureRoot!\right.bin" "!FixtureRoot!\concat-right-after.bin" "Concatenate leaves the right input unchanged"

set "DigitsHandle="
set "SliceHandle="
set "EmptySlice="
set "FullSlice="
call "!Text!" :Load "!FixtureRoot!\digits.bin" DigitsHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load slice source text"
if defined BT.Abort goto :Summary
call :TrackHandle "!DigitsHandle!"
call "!Text!" slice text "!DigitsHandle!" from 3 for 4 into SliceHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Slice a byte range"
if defined BT.Abort goto :Summary
call :TrackHandle "!SliceHandle!"
call "!Text!" :Save "!SliceHandle!" "!FixtureRoot!\slice-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\slice.bin" "!FixtureRoot!\slice-result.bin" "Slice uses zero-based byte offsets"
call "!Text!" :Slice "!DigitsHandle!" 10 0 EmptySlice
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Slice an empty range at end of text"
if defined BT.Abort goto :Summary
call :TrackHandle "!EmptySlice!"
call "!Text!" :Compare "!EmptyHandle!" "!EmptySlice!" Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "An end-position zero-length slice is empty"
call "!Text!" :Slice "!DigitsHandle!" 0 10 FullSlice
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Slice the complete text"
if defined BT.Abort goto :Summary
call :TrackHandle "!FullSlice!"
call "!Text!" :Compare "!DigitsHandle!" "!FullSlice!" Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "A full-range slice preserves every byte"
set "ShouldNotExist="
call "!Text!" :Slice "!DigitsHandle!" 11 0 ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a slice start beyond text length"
call "!Text!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal TextRangeOutOfBounds because "Report an out-of-bounds slice"
call "!Text!" :Slice "!DigitsHandle!" 8 3 ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a slice extending past text length"
call "!Text!" :Slice "!DigitsHandle!" invalid 1 ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a nonnumeric slice offset"

set "HaystackHandle="
set "NeedleHandle="
set "MissingHandle="
call "!Text!" :Load "!FixtureRoot!\haystack.bin" HaystackHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load search text"
if defined BT.Abort goto :Summary
call :TrackHandle "!HaystackHandle!"
call "!Text!" :Load "!FixtureRoot!\needle.bin" NeedleHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load search needle"
if defined BT.Abort goto :Summary
call :TrackHandle "!NeedleHandle!"
call "!Text!" :Load "!FixtureRoot!\missing.bin" MissingHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load missing search needle"
if defined BT.Abort goto :Summary
call :TrackHandle "!MissingHandle!"
call "!Text!" search text "!NeedleHandle!" in "!HaystackHandle!" from 0 into Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Search from the beginning"
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Search returns the first zero-based byte index"
call "!Text!" :Search "!HaystackHandle!" "!NeedleHandle!" 3 Actual
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Search honors the starting byte offset"
call "!Text!" :Search "!HaystackHandle!" "!MissingHandle!" 0 Actual
call "!BatchTest!" expect value "!Actual!" to equal -1 because "Search returns minus one when bytes are absent"
call "!Text!" :Search "!HaystackHandle!" "!EmptyHandle!" 4 Actual
call "!BatchTest!" expect value "!Actual!" to equal 4 because "An empty search text matches at the requested start"
call "!Text!" :Search "!HaystackHandle!" "!NeedleHandle!" 11 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a search start beyond text length"

set "ReplacementHandle="
set "ReplacedHandle="
set "DeletedHandle="
set "MissingReplaceHandle="
call "!Text!" :Load "!FixtureRoot!\replacement.bin" ReplacementHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load replacement text"
if defined BT.Abort goto :Summary
call :TrackHandle "!ReplacementHandle!"
call "!Text!" replace text "!NeedleHandle!" with "!ReplacementHandle!" in "!HaystackHandle!" into ReplacedHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Replace every non-overlapping match"
if defined BT.Abort goto :Summary
call :TrackHandle "!ReplacedHandle!"
call "!Text!" :Save "!ReplacedHandle!" "!FixtureRoot!\replace-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\replaced.bin" "!FixtureRoot!\replace-result.bin" "Replace writes exact replacement bytes"
call "!Text!" :Replace "!HaystackHandle!" "!NeedleHandle!" "!EmptyHandle!" DeletedHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Replace matches with empty text"
if defined BT.Abort goto :Summary
call :TrackHandle "!DeletedHandle!"
call "!Text!" :Save "!DeletedHandle!" "!FixtureRoot!\delete-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\deleted.bin" "!FixtureRoot!\delete-result.bin" "Empty replacement deletes matched bytes"
call "!Text!" :Replace "!HaystackHandle!" "!MissingHandle!" "!ReplacementHandle!" MissingReplaceHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Replace an absent byte sequence"
if defined BT.Abort goto :Summary
call :TrackHandle "!MissingReplaceHandle!"
call "!Text!" :Compare "!HaystackHandle!" "!MissingReplaceHandle!" Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Replacing absent bytes preserves the source"
call "!Text!" :Replace "!HaystackHandle!" "!EmptyHandle!" "!ReplacementHandle!" ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an empty replacement search text"
call "!Text!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal EmptySearchText because "Report an empty replacement search"

set "OverlapHandle="
set "DoubleAHandle="
set "LowerBHandle="
set "OverlapResult="
call "!Text!" :Load "!FixtureRoot!\overlap.bin" OverlapHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load overlapping replacement source"
if defined BT.Abort goto :Summary
call :TrackHandle "!OverlapHandle!"
call "!Text!" :Load "!FixtureRoot!\doublea.bin" DoubleAHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load overlapping replacement search"
if defined BT.Abort goto :Summary
call :TrackHandle "!DoubleAHandle!"
call "!Text!" :Load "!FixtureRoot!\lowerb.bin" LowerBHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load overlapping replacement value"
if defined BT.Abort goto :Summary
call :TrackHandle "!LowerBHandle!"
call "!Text!" :Replace "!OverlapHandle!" "!DoubleAHandle!" "!LowerBHandle!" OverlapResult
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Replace overlapping candidates left to right"
if defined BT.Abort goto :Summary
call :TrackHandle "!OverlapResult!"
call "!Text!" :Save "!OverlapResult!" "!FixtureRoot!\overlap-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\bb.bin" "!FixtureRoot!\overlap-result.bin" "Replace uses non-overlapping left-to-right matches"

set "MultilineHandle="
call "!Text!" :Load "!FixtureRoot!\multiline.bin" MultilineHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load mixed-newline text"
if defined BT.Abort goto :Summary
call :TrackHandle "!MultilineHandle!"
call "!Text!" :Save "!MultilineHandle!" "!FixtureRoot!\multiline-roundtrip.bin"
call :ExpectFilesEqual "!FixtureRoot!\multiline.bin" "!FixtureRoot!\multiline-roundtrip.bin" "CR, LF, CRLF, and missing final newline are preserved"

set "Utf8Handle="
set "Utf8First="
set "EmojiHandle="
set "Utf8Replacement="
call "!Text!" :Load "!FixtureRoot!\utf8.bin" Utf8Handle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load UTF-8 bytes"
if defined BT.Abort goto :Summary
call :TrackHandle "!Utf8Handle!"
set /p "ExpectedLength="<"!FixtureRoot!\utf8.length.txt"
call "!Text!" :Length "!Utf8Handle!" Actual
call "!BatchTest!" expect value "!Actual!" to equal "!ExpectedLength!" because "UTF-8 length is reported in bytes"
call "!Text!" :Slice "!Utf8Handle!" 0 2 Utf8First
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Slice a complete multibyte UTF-8 sequence by bytes"
if defined BT.Abort goto :Summary
call :TrackHandle "!Utf8First!"
call "!Text!" :Save "!Utf8First!" "!FixtureRoot!\utf8-first-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\utf8-first.bin" "!FixtureRoot!\utf8-first-result.bin" "Byte slicing preserves selected UTF-8 bytes"
call "!Text!" :Load "!FixtureRoot!\emoji.bin" EmojiHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load UTF-8 search bytes"
if defined BT.Abort goto :Summary
call :TrackHandle "!EmojiHandle!"
call "!Text!" :Search "!Utf8Handle!" "!EmojiHandle!" 0 Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "UTF-8 search returns a byte offset"
call "!Text!" :Replace "!Utf8Handle!" "!EmojiHandle!" "!ReplacementHandle!" Utf8Replacement
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Replace a multibyte UTF-8 sequence"
if defined BT.Abort goto :Summary
call :TrackHandle "!Utf8Replacement!"
call "!Text!" :Save "!Utf8Replacement!" "!FixtureRoot!\utf8-replace-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\utf8-replaced.bin" "!FixtureRoot!\utf8-replace-result.bin" "UTF-8 replacement preserves surrounding bytes"

set "InjectionHandle="
set "InjectionCopy="
call "!Text!" :Load "!FixtureRoot!\injection.bin" InjectionHandle
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Load hostile command text as data"
if defined BT.Abort goto :Summary
call :TrackHandle "!InjectionHandle!"
call :AssertMarkerAbsent "Loading hostile text cannot execute a command"
call "!Text!" :Save "!InjectionHandle!" "!FixtureRoot!\injection-roundtrip.bin"
call :ExpectFilesEqual "!FixtureRoot!\injection.bin" "!FixtureRoot!\injection-roundtrip.bin" "Hostile command text round-trips exactly"
call :AssertMarkerAbsent "Saving hostile text cannot execute a command"
call "!Text!" :Concatenate "!InjectionHandle!" "!InjectionHandle!" InjectionCopy
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Concatenate hostile command text"
if defined BT.Abort goto :Summary
call :TrackHandle "!InjectionCopy!"
call "!Text!" :Save "!InjectionCopy!" "!FixtureRoot!\injection-double-result.bin"
call :ExpectFilesEqual "!FixtureRoot!\injection-doubled.bin" "!FixtureRoot!\injection-double-result.bin" "Concatenating hostile text preserves exact bytes"
call :AssertMarkerAbsent "Concatenating hostile text cannot execute a command"

set "MissingSource=!FixtureRoot!\does-not-exist.bin"
call "!Text!" :Load "!MissingSource!" ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a missing source file"
call "!Text!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal TextSourceNotFound because "Report a missing text source"
call "!Text!" :Length TX999999 Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a missing text handle"
call "!Text!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal TextNotFound because "Report a missing text handle"
call "!Text!" :Length invalid Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a malformed text handle"
call "!Text!" :Length "!SpecialHandle!" PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!Text!" :GetStat Unknown Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an unknown text statistic"

call "!Text!" :GetStat TextCount Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Read active text count"
call "!BatchTest!" expect value "!Actual!" to equal 32 because "Text count tracks active handles"

call "!Text!" :Release "!SliceHandle!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Release a text handle"
call "!Text!" :Length "!SliceHandle!" Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Released text handles are unavailable"

:Summary
for %%H in (!Handles!) do call "!Text!" :Release "%%~H" >nul 2>nul

if defined BTX.Initialized (
    call "!Text!" :GetStat TextCount Actual
    call "!BatchTest!" expect value "!Actual!" to equal 0 because "Cleanup releases every active text handle"
    call "!Text!" shutdown text
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown BatchText"
    call "!Text!" :Length TX000001 Actual
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject operations after shutdown"
)

call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
rmdir /s /q "!FixtureRoot!" >nul 2>nul
exit /b !TestExit!

:TrackHandle
set "Handles=!Handles! %~1"
exit /b 0

:ExpectFilesEqual
fc /b "%~1" "%~2" >nul
set "CompareExit=!errorlevel!"
call "!BatchTest!" expect exit "!CompareExit!" to equal 0 because "%~3"
exit /b 0

:AssertMarkerAbsent
if exist "!MarkerPath!" (
    call "!BatchTest!" record failure because "%~1"
) else (
    call "!BatchTest!" record pass because "%~1"
)
exit /b 0
