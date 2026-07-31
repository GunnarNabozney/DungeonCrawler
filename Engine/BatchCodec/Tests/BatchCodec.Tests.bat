@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Codec=%~dp0..\BatchCodec.bat"
set "Helper=%~dp0..\BatchCodecOps.ps1"
set "Text=%~dp0..\..\BatchText\BatchText.bat"
set "BatchTest=%~dp0..\..\BatchRuntime\BatchTest.bat"
set "PowerShell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "FixtureRoot=%TEMP%\BatchCodecTests-!RANDOM!-!RANDOM!-!RANDOM!"
set "Documents="
set "TextHandles="
set "Actual="
set "ActualType="
set "ActualText="

call "!BatchTest!" begin suite "BatchCodec 1.0 deterministic self-test"

"!PowerShell!" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "!Helper!" CreateFixtures "!FixtureRoot!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create deterministic codec fixtures"
if defined BT.Abort goto :Summary

call "!Text!" initialize text
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchText dependency"
if defined BT.Abort goto :Summary

call "!Codec!" initialize codec
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchCodec"
if defined BT.Abort goto :Summary

call "!Codec!" :GetStat DocumentCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Codec document count starts at zero"

call :LoadText "health.bin" HealthText "Load registry integer bytes"
call :LoadText "enabled.bin" EnabledText "Load registry Boolean bytes"
call :LoadText "level.bin" LevelText "Load object integer bytes"
call :LoadText "name.bin" NameText "Load object name bytes"
call :LoadText "special.bin" SpecialText "Load arbitrary text bytes"
if defined BT.Abort goto :Summary

set "EscapedText="
call "!Codec!" escape text "!SpecialText!" into EscapedText
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Escape arbitrary text through a BatchText handle"
if defined BT.Abort goto :Summary
call :TrackText "!EscapedText!"
call :ExpectTextFile "!EscapedText!" "special-escaped.bin" "Escaping is deterministic and byte-safe"

set "UnescapedText="
call "!Codec!" unescape text "!EscapedText!" into UnescapedText
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Unescape escaped text"
if defined BT.Abort goto :Summary
call :TrackText "!UnescapedText!"
call :ExpectTextFile "!UnescapedText!" "special.bin" "Escape and unescape round-trip every byte"

call :LoadText "malformed-escape.bin" MalformedEscapeText "Load malformed escaped input"
if defined BT.Abort goto :Summary
call "!Codec!" :Unescape "!MalformedEscapeText!" ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject malformed percent escapes"
call "!Codec!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal MalformedEscapedData because "Report malformed escaped data"

call :LoadText "lowercase-escape.bin" LowercaseEscapeText "Load a lowercase percent escape"
call "!Codec!" :Unescape "!LowercaseEscapeText!" ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject lowercase percent escapes as non-canonical"

call :LoadText "overescaped.bin" OverescapedText "Load an over-escaped unreserved byte"
call "!Codec!" :Unescape "!OverescapedText!" ShouldNotExist
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject over-escaped unreserved bytes"

set "SaveDocument="
call "!Codec!" create save-data into SaveDocument
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a versioned save-data document"
if defined BT.Abort goto :Summary
call :TrackDocument "!SaveDocument!"
call "!Codec!" :GetDocumentInfo "!SaveDocument!" Version Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "New documents use format version one"
call "!Codec!" :GetDocumentInfo "!SaveDocument!" Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal SaveData because "Save document reports its kind"

call "!Codec!" :AddRegistryValue "!SaveDocument!" Player Health Int "!HealthText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add a typed registry integer"
call "!Codec!" :AddRegistryValue "!SaveDocument!" Player Enabled Bool "!EnabledText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add a typed registry Boolean"
call "!Codec!" :AddRegistryValue "!SaveDocument!" Player Profile.Raw String "!SpecialText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add arbitrary bytes as a registry string payload"
call "!Codec!" :AddRegistryValue "!SaveDocument!" player health Int "!HealthText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject case-insensitive duplicate registry records"
call "!Codec!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal RegistryValueAlreadyExists because "Report duplicate registry records"

call "!Codec!" :AddObject "!SaveDocument!" Hero Game.Character
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add a typed object declaration"
call "!Codec!" :AddObjectField "!SaveDocument!" Hero Name String "!SpecialText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add an object string field"
call "!Codec!" :AddObjectField "!SaveDocument!" Hero Level Int "!LevelText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add an object integer field"
call "!Codec!" :AddObjectField "!SaveDocument!" Missing Value Int "!LevelText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a field for a missing object"
call "!Codec!" :AddObjectField "!SaveDocument!" Hero level Int "!LevelText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject case-insensitive duplicate object fields"

call "!Codec!" :AddText "!SaveDocument!" Journal.Raw "!SpecialText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add an arbitrary BatchText record"
call "!Codec!" :AddText "!SaveDocument!" journal.raw "!SpecialText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject case-insensitive duplicate text records"

call "!Codec!" :GetDocumentInfo "!SaveDocument!" RegistryValueCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Track registry value records"
call "!Codec!" :GetDocumentInfo "!SaveDocument!" ObjectCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Track object declarations"
call "!Codec!" :GetDocumentInfo "!SaveDocument!" ObjectFieldCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Track object fields"
call "!Codec!" :GetDocumentInfo "!SaveDocument!" TextCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Track text records"

call "!Text!" :Release "!SpecialText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Release the source text after records copy their bytes"

set "SaveOne=!FixtureRoot!\save-one.btc"
set "SaveTwo=!FixtureRoot!\save-two.btc"
set "SaveThree=!FixtureRoot!\save-three.btc"
call "!Codec!" encode "!SaveDocument!" to "!SaveOne!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Encode save data"
if defined BT.Abort goto :Summary
call "!Codec!" :Encode "!SaveDocument!" "!SaveTwo!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Encode the same document again"
call :ExpectFilesEqual "!SaveOne!" "!SaveTwo!" "Repeated encoding is byte deterministic"

set "AlternateDocument="
set "SaveAlternate=!FixtureRoot!\save-alternate.btc"
call "!Codec!" :CreateDocument SaveData AlternateDocument
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create an equivalent document with different insertion order"
if defined BT.Abort goto :Summary
call :TrackDocument "!AlternateDocument!"
call "!Codec!" :AddText "!AlternateDocument!" Journal.Raw "!UnescapedText!"
call "!Codec!" :AddObject "!AlternateDocument!" Hero Game.Character
call "!Codec!" :AddObjectField "!AlternateDocument!" Hero Level Int "!LevelText!"
call "!Codec!" :AddObjectField "!AlternateDocument!" Hero Name String "!UnescapedText!"
call "!Codec!" :AddRegistryValue "!AlternateDocument!" Player Profile.Raw String "!UnescapedText!"
call "!Codec!" :AddRegistryValue "!AlternateDocument!" Player Enabled Bool "!EnabledText!"
call "!Codec!" :AddRegistryValue "!AlternateDocument!" Player Health Int "!HealthText!"
call "!Codec!" :Encode "!AlternateDocument!" "!SaveAlternate!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Encode equivalent records added in reverse category order"
call :ExpectFilesEqual "!SaveOne!" "!SaveAlternate!" "Canonical ordering ignores insertion order"

set "DecodedDocument="
call "!Codec!" decode "!SaveOne!" into DecodedDocument
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode canonical save data"
if "!ActualExit!"=="0" call :TrackDocument "!DecodedDocument!"
if defined BT.Abort goto :Summary
call "!Codec!" :GetDocumentInfo "!DecodedDocument!" Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal SaveData because "Decoded data preserves document kind"
call "!Codec!" :GetDocumentInfo "!DecodedDocument!" Version Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Decoded data preserves format version"

set "DecodedHealth="
call "!Codec!" :GetRegistryValue "!DecodedDocument!" Player Health ActualType DecodedHealth
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode a registry value"
if defined BT.Abort goto :Summary
call :TrackText "!DecodedHealth!"
call "!BatchTest!" expect value "!ActualType!" to equal Int because "Registry value preserves its type"
call :ExpectTextFile "!DecodedHealth!" "health.bin" "Registry value preserves its bytes"

set "DecodedRaw="
call "!Codec!" :GetRegistryValue "!DecodedDocument!" Player Profile.Raw ActualType DecodedRaw
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode arbitrary registry bytes"
if defined BT.Abort goto :Summary
call :TrackText "!DecodedRaw!"
call "!BatchTest!" expect value "!ActualType!" to equal String because "Arbitrary registry value preserves its type"
call :ExpectTextFile "!DecodedRaw!" "special.bin" "Arbitrary registry value round-trips every byte"

call "!Codec!" :GetObjectType "!DecodedDocument!" Hero Actual
call "!BatchTest!" expect value "!Actual!" to equal Game.Character because "Object declaration preserves its type identifier"
set "DecodedLevel="
call "!Codec!" :GetObjectField "!DecodedDocument!" Hero Level ActualType DecodedLevel
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode an object field"
if defined BT.Abort goto :Summary
call :TrackText "!DecodedLevel!"
call "!BatchTest!" expect value "!ActualType!" to equal Int because "Object field preserves its type"
call :ExpectTextFile "!DecodedLevel!" "level.bin" "Object field preserves its bytes"
set "DecodedName="
call "!Codec!" :GetObjectField "!DecodedDocument!" Hero Name ActualType DecodedName
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode an arbitrary object field"
if defined BT.Abort goto :Summary
call :TrackText "!DecodedName!"
call "!BatchTest!" expect value "!ActualType!" to equal String because "Arbitrary object field preserves its type"
call :ExpectTextFile "!DecodedName!" "special.bin" "Object fields round-trip every byte"

set "DecodedJournal="
call "!Codec!" :GetText "!DecodedDocument!" Journal.Raw DecodedJournal
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Decode a text record into a BatchText handle"
if defined BT.Abort goto :Summary
call :TrackText "!DecodedJournal!"
call :ExpectTextFile "!DecodedJournal!" "special.bin" "Text handles preserve arbitrary bytes"

call "!Codec!" :Encode "!DecodedDocument!" "!SaveThree!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Re-encode decoded save data"
call :ExpectFilesEqual "!SaveOne!" "!SaveThree!" "Encode-decode-encode is byte deterministic"

call :ExpectDecodeFailure "bad-magic.btc" 20 MalformedCodecData "Reject an invalid codec signature"
call :ExpectDecodeFailure "version-2.btc" 30 UnsupportedCodecVersion "Reject an unsupported codec version"
call :ExpectDecodeFailure "bad-integrity.btc" 20 CodecIntegrityMismatch "Detect modified serialized data"
call :ExpectDecodeFailure "bad-escape.btc" 20 MalformedEscapedData "Reject malformed metadata escaping"
call :ExpectDecodeFailure "lowercase-escape.btc" 20 MalformedEscapedData "Reject lowercase metadata escapes"
call :ExpectDecodeFailure "overescaped.btc" 20 MalformedEscapedData "Reject over-escaped metadata"
call :ExpectDecodeFailure "bad-base64.btc" 20 MalformedCodecData "Reject malformed Base64 payloads"
call :ExpectDecodeFailure "duplicate.btc" 20 DuplicateCodecRecord "Reject duplicate logical records"
call :ExpectDecodeFailure "incompatible.btc" 20 IncompatibleCodecData "Reject records incompatible with document kind"
call :ExpectDecodeFailure "bad-count.btc" 20 MalformedCodecData "Reject incorrect record counts"
call :ExpectDecodeFailure "noncanonical.btc" 20 MalformedCodecData "Reject non-canonical record order"
call :ExpectDecodeFailure "truncated.btc" 20 MalformedCodecData "Reject truncated serialized data"

set "RegistryDocument="
call "!Codec!" :CreateDocument Registry RegistryDocument
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a registry-only document"
if "!ActualExit!"=="0" call :TrackDocument "!RegistryDocument!"
if defined BT.Abort goto :Summary
call "!Codec!" :AddText "!RegistryDocument!" Notes "!NameText!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject text records in registry-only documents"
call "!Codec!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal IncompatibleDocumentKind because "Report incompatible document record categories"

call "!Codec!" :GetRegistryValue "!DecodedDocument!" Player Missing ActualType ActualText
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a missing decoded registry value"
call "!Codec!" :GetText BC999999 Notes ActualText
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a missing codec document"
call "!Codec!" :CreateDocument SaveData PATH
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 10 because "Reject a reserved output variable"
call "!Codec!" :GetDocumentInfo "!DecodedDocument!" Unknown Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an unknown document information field"

:Summary
for %%H in (!TextHandles!) do call "!Text!" :Release "%%~H" >nul 2>nul
for %%D in (!Documents!) do call "!Codec!" :Release "%%~D" >nul 2>nul

if defined BC.Initialized (
    call "!Codec!" :GetStat DocumentCount Actual
    call "!BatchTest!" expect value "!Actual!" to equal 0 because "Cleanup releases every codec document"
    call "!Codec!" shutdown codec
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Shutdown BatchCodec"
    call "!Codec!" :GetStat DocumentCount Actual
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 50 because "Reject codec operations after shutdown"
)

if defined BTX.Initialized call "!Text!" shutdown text >nul 2>nul
call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
rmdir /s /q "!FixtureRoot!" >nul 2>nul
exit /b !TestExit!

:LoadText
set "%~2="
call "!Text!" :Load "!FixtureRoot!\%~1" "%~2"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "%~3"
if "!ActualExit!"=="0" call :TrackText "!%~2!"
exit /b 0

:TrackText
set "TextHandles=!TextHandles! %~1"
exit /b 0

:TrackDocument
set "Documents=!Documents! %~1"
exit /b 0

:ExpectFilesEqual
fc /b "%~1" "%~2" >nul
set "CompareExit=!errorlevel!"
call "!BatchTest!" expect exit "!CompareExit!" to equal 0 because "%~3"
exit /b 0

:ExpectTextFile
set "TextResult=!FixtureRoot!\text-result-!RANDOM!-!RANDOM!.bin"
call "!Text!" :Save "%~1" "!TextResult!"
set "SaveExit=!errorlevel!"
call "!BatchTest!" expect exit "!SaveExit!" to equal 0 because "%~3 can be materialized"
if "!SaveExit!"=="0" call :ExpectFilesEqual "!TextResult!" "!FixtureRoot!\%~2" "%~3"
del /q "!TextResult!" >nul 2>nul
exit /b 0

:ExpectDecodeFailure
set "RejectedDocument="
call "!Codec!" :Decode "!FixtureRoot!\%~1" RejectedDocument
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal "%~2" because "%~4"
call "!Codec!" :ReadLastError Kind Actual
call "!BatchTest!" expect value "!Actual!" to equal "%~3" because "%~4 reports %~3"
if defined RejectedDocument call "!Codec!" :Release "!RejectedDocument!" >nul 2>nul
exit /b 0
