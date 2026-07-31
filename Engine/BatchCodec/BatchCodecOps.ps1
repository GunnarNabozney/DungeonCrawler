[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Operation,

    [Parameter(Position = 1)]
    [string]$Argument1,

    [Parameter(Position = 2)]
    [string]$Argument2,

    [Parameter(Position = 3)]
    [string]$Argument3,

    [Parameter(Position = 4)]
    [string]$Argument4
)

$CommandTitle = 'BatchCodecOps-1-0'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Ascii = New-Object -TypeName System.Text.ASCIIEncoding
$Utf8Strict = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false, $true)
$Utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false)
$Invariant = [System.Globalization.CultureInfo]::InvariantCulture
$Ordinal = [System.StringComparer]::Ordinal
$MaximumPayloadBytes = [int64]16777216
$MaximumPackageBytes = [int64]67108864
$MaximumRecords = 10000

function Exit-WithCode {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Code
    )

    exit $Code
}

function Read-LimitedBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int64]$Maximum
    )

    if (-not [System.IO.File]::Exists($Path)) {
        Exit-WithCode -Code 3
    }

    $Length = (Get-Item -LiteralPath $Path -Force).Length

    if ($Length -gt $Maximum) {
        Exit-WithCode -Code 10
    }

    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    return ,$Bytes
}

function Write-BytesAtomically {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $Parent = Split-Path -Parent $Path

    if (-not [string]::IsNullOrEmpty($Parent)) {
        [System.IO.Directory]::CreateDirectory($Parent) | Out-Null
    }

    $Temporary = $Path + '.tmp-' + [Guid]::NewGuid().ToString('N')

    try {
        [System.IO.File]::WriteAllBytes($Temporary, $Bytes)

        if ([System.IO.File]::Exists($Path)) {
            [System.IO.File]::Delete($Path)
        }

        [System.IO.File]::Move($Temporary, $Path)
    }
    finally {
        if ([System.IO.File]::Exists($Temporary)) {
            [System.IO.File]::Delete($Temporary)
        }
    }
}

function Test-UnreservedByte {
    param(
        [Parameter(Mandatory = $true)]
        [byte]$Value
    )

    if ($Value -ge 48 -and $Value -le 57) {
        return $true
    }

    if ($Value -ge 65 -and $Value -le 90) {
        return $true
    }

    if ($Value -ge 97 -and $Value -le 122) {
        return $true
    }

    if ($Value -eq 45 -or $Value -eq 46 -or $Value -eq 95 -or $Value -eq 126) {
        return $true
    }

    return $false
}

function ConvertTo-EscapedAscii {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $Builder = New-Object -TypeName System.Text.StringBuilder

    foreach ($Byte in $Bytes) {
        if (Test-UnreservedByte -Value $Byte) {
            [void]$Builder.Append([char]$Byte)
        }
        else {
            [void]$Builder.Append('%')
            [void]$Builder.Append($Byte.ToString('X2', $Invariant))
        }
    }

    return $Builder.ToString()
}

function Get-HexNibble {
    param(
        [Parameter(Mandatory = $true)]
        [byte]$Value
    )

    if ($Value -ge 48 -and $Value -le 57) {
        return [int]($Value - 48)
    }

    if ($Value -ge 65 -and $Value -le 70) {
        return [int]($Value - 55)
    }

    return -1
}

function ConvertFrom-EscapedAsciiBytes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $Result = New-Object 'System.Collections.Generic.List[byte]'
    $Index = 0

    while ($Index -lt $Bytes.Length) {
        $Byte = $Bytes[$Index]

        if (Test-UnreservedByte -Value $Byte) {
            $Result.Add($Byte)
            $Index++
            continue
        }

        if ($Byte -ne 37 -or ($Index + 2) -ge $Bytes.Length) {
            Exit-WithCode -Code 8
        }

        $High = Get-HexNibble -Value $Bytes[$Index + 1]
        $Low = Get-HexNibble -Value $Bytes[$Index + 2]

        if ($High -lt 0 -or $Low -lt 0) {
            Exit-WithCode -Code 8
        }

        $Decoded = [byte](($High * 16) + $Low)

        if (Test-UnreservedByte -Value $Decoded) {
            Exit-WithCode -Code 8
        }

        $Result.Add($Decoded)
        $Index += 3
    }

    $ByteArray = $Result.ToArray()
    return ,$ByteArray
}

function Escape-Metadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $Bytes = $Utf8NoBom.GetBytes($Value)
    return ConvertTo-EscapedAscii -Bytes $Bytes
}

function Unescape-Metadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    foreach ($Character in $Value.ToCharArray()) {
        if ([int][char]$Character -gt 127) {
            Exit-WithCode -Code 8
        }
    }

    $EscapedBytes = $Ascii.GetBytes($Value)
    $Bytes = ConvertFrom-EscapedAsciiBytes -Bytes $EscapedBytes

    try {
        return $Utf8Strict.GetString($Bytes)
    }
    catch {
        Exit-WithCode -Code 8
    }
}

function Test-Identifier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return $Value -match '^[A-Za-z][A-Za-z0-9_]{0,63}$'
}

function Test-DottedIdentifier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value.Length -gt 512) {
        return $false
    }

    $Segments = $Value.Split([char]'.')

    if ($Segments.Length -eq 0) {
        return $false
    }

    foreach ($Segment in $Segments) {
        if (-not (Test-Identifier -Value $Segment)) {
            return $false
        }
    }

    return $true
}

function Test-DocumentKind {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return $Value -in @('SaveData', 'Registry', 'Object', 'TextBundle')
}

function Test-RecordAllowed {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Kind,

        [Parameter(Mandatory = $true)]
        [string]$RecordType
    )

    if ($Kind -eq 'SaveData') {
        return $true
    }

    if ($Kind -eq 'Registry' -and $RecordType -eq 'R') {
        return $true
    }

    if ($Kind -eq 'Object' -and $RecordType -in @('O', 'F')) {
        return $true
    }

    if ($Kind -eq 'TextBundle' -and $RecordType -eq 'T') {
        return $true
    }

    return $false
}

function Parse-NonNegativeInt64 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [int]$FailureCode
    )

    $Parsed = [int64]0

    if (-not [int64]::TryParse($Value, [ref]$Parsed)) {
        Exit-WithCode -Code $FailureCode
    }

    if ($Parsed -lt 0) {
        Exit-WithCode -Code $FailureCode
    }

    return $Parsed
}

function Get-Sha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $Algorithm = [System.Security.Cryptography.SHA256]::Create()

    try {
        $Hash = $Algorithm.ComputeHash($Bytes)
    }
    finally {
        $Algorithm.Dispose()
    }

    return ([System.BitConverter]::ToString($Hash)).Replace('-', '')
}

function New-Record {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Line,

        [Parameter(Mandatory = $true)]
        [string]$SortKey,

        [AllowEmptyCollection()]
        [byte[]]$Payload,

        [string]$DescriptorLine
    )

    return [pscustomobject]@{
        Type = $Type
        Line = $Line
        SortKey = $SortKey
        Payload = $Payload
        DescriptorLine = $DescriptorLine
    }
}

function Sort-RecordsOrdinal {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Records
    )

    $Sorted = @($Records)

    for ($Index = 1; $Index -lt $Sorted.Length; $Index++) {
        $Current = $Sorted[$Index]
        $Position = $Index - 1

        while (
            $Position -ge 0 -and
            $Ordinal.Compare($Sorted[$Position].SortKey, $Current.SortKey) -gt 0
        ) {
            $Sorted[$Position + 1] = $Sorted[$Position]
            $Position--
        }

        $Sorted[$Position + 1] = $Current
    }

    return $Sorted
}

function Get-StrictTextLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes,

        [Parameter(Mandatory = $true)]
        [System.Text.Encoding]$Encoding,

        [Parameter(Mandatory = $true)]
        [int]$FailureCode
    )

    try {
        $Text = $Encoding.GetString($Bytes)
    }
    catch {
        Exit-WithCode -Code $FailureCode
    }

    if (-not $Text.EndsWith("`r`n", [System.StringComparison]::Ordinal)) {
        Exit-WithCode -Code $FailureCode
    }

    $WithoutPairs = $Text.Replace("`r`n", '')

    if (
        $WithoutPairs.IndexOf("`r", [System.StringComparison]::Ordinal) -ge 0 -or
        $WithoutPairs.IndexOf("`n", [System.StringComparison]::Ordinal) -ge 0
    ) {
        Exit-WithCode -Code $FailureCode
    }

    $Trimmed = $Text.Substring(0, $Text.Length - 2)
    $Lines = $Trimmed.Split([string[]]@("`r`n"), [System.StringSplitOptions]::None)
    return ,$Lines
}

function Read-DescriptorRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DescriptorPath,

        [Parameter(Mandatory = $true)]
        [string]$StoreRoot
    )

    $DescriptorBytes = Read-LimitedBytes -Path $DescriptorPath -Maximum $MaximumPackageBytes
    $Lines = Get-StrictTextLines -Bytes $DescriptorBytes -Encoding $Utf8Strict -FailureCode 2

    if ($Lines.Length -lt 1) {
        Exit-WithCode -Code 2
    }

    $Header = $Lines[0].Split([char]'|')

    if ($Header.Length -ne 3 -or $Header[0] -ne 'K') {
        Exit-WithCode -Code 2
    }

    $Kind = $Header[1]
    $Version = $Header[2]

    if (-not (Test-DocumentKind -Value $Kind)) {
        Exit-WithCode -Code 2
    }

    if ($Version -ne '1') {
        Exit-WithCode -Code 5
    }

    $Records = New-Object 'System.Collections.Generic.List[object]'
    $DuplicateKeys = @{}
    $ObjectNames = @{}
    $FieldObjects = New-Object 'System.Collections.Generic.List[string]'

    for ($LineIndex = 1; $LineIndex -lt $Lines.Length; $LineIndex++) {
        if ($Records.Count -ge $MaximumRecords) {
            Exit-WithCode -Code 10
        }

        $Parts = $Lines[$LineIndex].Split([char]'|')
        $RecordType = $Parts[0]

        if (-not (Test-RecordAllowed -Kind $Kind -RecordType $RecordType)) {
            Exit-WithCode -Code 7
        }

        if ($RecordType -eq 'R') {
            if ($Parts.Length -ne 5) {
                Exit-WithCode -Code 2
            }

            $Registry = $Parts[1]
            $Key = $Parts[2]
            $ValueType = $Parts[3]
            $PayloadName = $Parts[4]

            if (
                -not (Test-Identifier -Value $Registry) -or
                -not (Test-DottedIdentifier -Value $Key) -or
                -not (Test-Identifier -Value $ValueType) -or
                $PayloadName -notmatch '^P[0-9]{6}\.bin$'
            ) {
                Exit-WithCode -Code 2
            }

            $DuplicateKey = ('R|' + $Registry + '|' + $Key).ToUpperInvariant()

            if ($DuplicateKeys.ContainsKey($DuplicateKey)) {
                Exit-WithCode -Code 9
            }

            $DuplicateKeys[$DuplicateKey] = $true
            $PayloadPath = Join-Path $StoreRoot $PayloadName
            $Payload = Read-LimitedBytes -Path $PayloadPath -Maximum $MaximumPayloadBytes
            $EscapedRegistry = Escape-Metadata -Value $Registry
            $EscapedKey = Escape-Metadata -Value $Key
            $EscapedType = Escape-Metadata -Value $ValueType
            $Base64 = [Convert]::ToBase64String($Payload)
            $Line = 'R|' + $EscapedRegistry + '|' + $EscapedKey + '|' + $EscapedType + '|' + $Payload.Length + '|' + $Base64
            $SortKey = '0|' + $EscapedRegistry + '|' + $EscapedKey
            $Records.Add((New-Record -Type R -Line $Line -SortKey $SortKey -Payload $Payload -DescriptorLine $Lines[$LineIndex]))
            continue
        }

        if ($RecordType -eq 'O') {
            if ($Parts.Length -ne 3) {
                Exit-WithCode -Code 2
            }

            $ObjectName = $Parts[1]
            $TypeId = $Parts[2]

            if (-not (Test-Identifier -Value $ObjectName) -or -not (Test-DottedIdentifier -Value $TypeId)) {
                Exit-WithCode -Code 2
            }

            $DuplicateKey = ('O|' + $ObjectName).ToUpperInvariant()

            if ($DuplicateKeys.ContainsKey($DuplicateKey)) {
                Exit-WithCode -Code 9
            }

            $DuplicateKeys[$DuplicateKey] = $true
            $ObjectNames[$ObjectName.ToUpperInvariant()] = $true
            $EscapedObject = Escape-Metadata -Value $ObjectName
            $EscapedTypeId = Escape-Metadata -Value $TypeId
            $Line = 'O|' + $EscapedObject + '|' + $EscapedTypeId
            $SortKey = '1|' + $EscapedObject
            $Records.Add((New-Record -Type O -Line $Line -SortKey $SortKey -DescriptorLine $Lines[$LineIndex]))
            continue
        }

        if ($RecordType -eq 'F') {
            if ($Parts.Length -ne 5) {
                Exit-WithCode -Code 2
            }

            $ObjectName = $Parts[1]
            $FieldName = $Parts[2]
            $ValueType = $Parts[3]
            $PayloadName = $Parts[4]

            if (
                -not (Test-Identifier -Value $ObjectName) -or
                -not (Test-Identifier -Value $FieldName) -or
                -not (Test-Identifier -Value $ValueType) -or
                $PayloadName -notmatch '^P[0-9]{6}\.bin$'
            ) {
                Exit-WithCode -Code 2
            }

            $DuplicateKey = ('F|' + $ObjectName + '|' + $FieldName).ToUpperInvariant()

            if ($DuplicateKeys.ContainsKey($DuplicateKey)) {
                Exit-WithCode -Code 9
            }

            $DuplicateKeys[$DuplicateKey] = $true
            $FieldObjects.Add($ObjectName.ToUpperInvariant())
            $PayloadPath = Join-Path $StoreRoot $PayloadName
            $Payload = Read-LimitedBytes -Path $PayloadPath -Maximum $MaximumPayloadBytes
            $EscapedObject = Escape-Metadata -Value $ObjectName
            $EscapedField = Escape-Metadata -Value $FieldName
            $EscapedType = Escape-Metadata -Value $ValueType
            $Base64 = [Convert]::ToBase64String($Payload)
            $Line = 'F|' + $EscapedObject + '|' + $EscapedField + '|' + $EscapedType + '|' + $Payload.Length + '|' + $Base64
            $SortKey = '2|' + $EscapedObject + '|' + $EscapedField
            $Records.Add((New-Record -Type F -Line $Line -SortKey $SortKey -Payload $Payload -DescriptorLine $Lines[$LineIndex]))
            continue
        }

        if ($RecordType -eq 'T') {
            if ($Parts.Length -ne 3) {
                Exit-WithCode -Code 2
            }

            $TextName = $Parts[1]
            $PayloadName = $Parts[2]

            if (-not (Test-DottedIdentifier -Value $TextName) -or $PayloadName -notmatch '^P[0-9]{6}\.bin$') {
                Exit-WithCode -Code 2
            }

            $DuplicateKey = ('T|' + $TextName).ToUpperInvariant()

            if ($DuplicateKeys.ContainsKey($DuplicateKey)) {
                Exit-WithCode -Code 9
            }

            $DuplicateKeys[$DuplicateKey] = $true
            $PayloadPath = Join-Path $StoreRoot $PayloadName
            $Payload = Read-LimitedBytes -Path $PayloadPath -Maximum $MaximumPayloadBytes
            $EscapedName = Escape-Metadata -Value $TextName
            $Base64 = [Convert]::ToBase64String($Payload)
            $Line = 'T|' + $EscapedName + '|' + $Payload.Length + '|' + $Base64
            $SortKey = '3|' + $EscapedName
            $Records.Add((New-Record -Type T -Line $Line -SortKey $SortKey -Payload $Payload -DescriptorLine $Lines[$LineIndex]))
            continue
        }

        Exit-WithCode -Code 2
    }

    foreach ($FieldObject in $FieldObjects) {
        if (-not $ObjectNames.ContainsKey($FieldObject)) {
            Exit-WithCode -Code 2
        }
    }

    $RecordArray = $Records.ToArray()

    if ($RecordArray.Length -eq 0) {
        $SortedRecords = @()
    }
    else {
        $SortedRecords = @(Sort-RecordsOrdinal -Records $RecordArray)
    }

    return [pscustomobject]@{
        Kind = $Kind
        Version = $Version
        Records = @($SortedRecords)
    }
}

function Encode-Package {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DescriptorPath,

        [Parameter(Mandatory = $true)]
        [string]$StoreRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $Document = Read-DescriptorRecords -DescriptorPath $DescriptorPath -StoreRoot $StoreRoot
    $BodyLines = New-Object 'System.Collections.Generic.List[string]'
    $BodyLines.Add('BATCHCODEC|' + $Document.Version + '|' + $Document.Kind)

    foreach ($Record in $Document.Records) {
        $BodyLines.Add($Record.Line)
    }

    $BodyLineArray = $BodyLines.ToArray()
    $BodyText = [string]::Join("`r`n", $BodyLineArray) + "`r`n"
    $BodyBytes = $Ascii.GetBytes($BodyText)
    $Hash = Get-Sha256Hex -Bytes $BodyBytes
    $FinalText = $BodyText + 'END|' + $Document.Records.Count + '|' + $Hash + "`r`n"
    $FinalBytes = $Ascii.GetBytes($FinalText)

    if ($FinalBytes.Length -gt $MaximumPackageBytes) {
        Exit-WithCode -Code 10
    }

    Write-BytesAtomically -Path $TargetPath -Bytes $FinalBytes
}

function Parse-Payload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LengthText,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Base64Text
    )

    $ExpectedLength = Parse-NonNegativeInt64 -Value $LengthText -FailureCode 4

    if ($ExpectedLength -gt $MaximumPayloadBytes) {
        Exit-WithCode -Code 10
    }

    try {
        $Payload = [Convert]::FromBase64String($Base64Text)
    }
    catch {
        Exit-WithCode -Code 4
    }

    if ($Payload.Length -ne $ExpectedLength) {
        Exit-WithCode -Code 4
    }

    if ([Convert]::ToBase64String($Payload) -ne $Base64Text) {
        Exit-WithCode -Code 4
    }

    return ,$Payload
}

function Decode-Package {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DescriptorPath,

        [Parameter(Mandatory = $true)]
        [string]$StoreRoot
    )

    $PackageBytes = Read-LimitedBytes -Path $SourcePath -Maximum $MaximumPackageBytes

    foreach ($Byte in $PackageBytes) {
        if ($Byte -gt 127) {
            Exit-WithCode -Code 4
        }
    }

    $Lines = Get-StrictTextLines -Bytes $PackageBytes -Encoding $Ascii -FailureCode 4

    if ($Lines.Length -lt 2) {
        Exit-WithCode -Code 4
    }

    $Header = $Lines[0].Split([char]'|')

    if ($Header.Length -ne 3 -or $Header[0] -ne 'BATCHCODEC') {
        Exit-WithCode -Code 4
    }

    $Version = $Header[1]
    $Kind = $Header[2]

    if ($Version -ne '1') {
        Exit-WithCode -Code 5
    }

    if (-not (Test-DocumentKind -Value $Kind)) {
        Exit-WithCode -Code 4
    }

    $EndParts = $Lines[$Lines.Length - 1].Split([char]'|')

    if ($EndParts.Length -ne 3 -or $EndParts[0] -ne 'END') {
        Exit-WithCode -Code 4
    }

    $ExpectedCount = Parse-NonNegativeInt64 -Value $EndParts[1] -FailureCode 4

    if ($ExpectedCount -gt $MaximumRecords) {
        Exit-WithCode -Code 10
    }

    if ($EndParts[2] -notmatch '^[0-9A-F]{64}$') {
        Exit-WithCode -Code 4
    }

    $RecordCount = $Lines.Length - 2

    if ($ExpectedCount -ne $RecordCount) {
        Exit-WithCode -Code 4
    }

    $BodyLines = New-Object 'System.Collections.Generic.List[string]'

    for ($Index = 0; $Index -lt ($Lines.Length - 1); $Index++) {
        $BodyLines.Add($Lines[$Index])
    }

    $BodyLineArray = $BodyLines.ToArray()
    $BodyText = [string]::Join("`r`n", $BodyLineArray) + "`r`n"
    $BodyBytes = $Ascii.GetBytes($BodyText)
    $ActualHash = Get-Sha256Hex -Bytes $BodyBytes

    if ($ActualHash -ne $EndParts[2]) {
        Exit-WithCode -Code 6
    }

    $Records = New-Object 'System.Collections.Generic.List[object]'
    $DuplicateKeys = @{}
    $ObjectNames = @{}
    $FieldObjects = New-Object 'System.Collections.Generic.List[string]'
    $PreviousSortKey = $null

    for ($LineIndex = 1; $LineIndex -lt ($Lines.Length - 1); $LineIndex++) {
        $Parts = $Lines[$LineIndex].Split([char]'|')
        $RecordType = $Parts[0]

        if (-not (Test-RecordAllowed -Kind $Kind -RecordType $RecordType)) {
            Exit-WithCode -Code 7
        }

        $Record = $null
        $DuplicateKey = $null

        if ($RecordType -eq 'R') {
            if ($Parts.Length -ne 6) {
                Exit-WithCode -Code 4
            }

            $Registry = Unescape-Metadata -Value $Parts[1]
            $Key = Unescape-Metadata -Value $Parts[2]
            $ValueType = Unescape-Metadata -Value $Parts[3]

            if (
                -not (Test-Identifier -Value $Registry) -or
                -not (Test-DottedIdentifier -Value $Key) -or
                -not (Test-Identifier -Value $ValueType)
            ) {
                Exit-WithCode -Code 4
            }

            $Payload = Parse-Payload -LengthText $Parts[4] -Base64Text $Parts[5]
            $DuplicateKey = ('R|' + $Registry + '|' + $Key).ToUpperInvariant()
            $SortKey = '0|' + $Parts[1] + '|' + $Parts[2]
            $Record = New-Record -Type R -Line $Lines[$LineIndex] -SortKey $SortKey -Payload $Payload
        }
        elseif ($RecordType -eq 'O') {
            if ($Parts.Length -ne 3) {
                Exit-WithCode -Code 4
            }

            $ObjectName = Unescape-Metadata -Value $Parts[1]
            $TypeId = Unescape-Metadata -Value $Parts[2]

            if (-not (Test-Identifier -Value $ObjectName) -or -not (Test-DottedIdentifier -Value $TypeId)) {
                Exit-WithCode -Code 4
            }

            $DuplicateKey = ('O|' + $ObjectName).ToUpperInvariant()
            $ObjectNames[$ObjectName.ToUpperInvariant()] = $true
            $SortKey = '1|' + $Parts[1]
            $Record = New-Record -Type O -Line $Lines[$LineIndex] -SortKey $SortKey
            $Record | Add-Member -NotePropertyName ObjectName -NotePropertyValue $ObjectName
            $Record | Add-Member -NotePropertyName TypeId -NotePropertyValue $TypeId
        }
        elseif ($RecordType -eq 'F') {
            if ($Parts.Length -ne 6) {
                Exit-WithCode -Code 4
            }

            $ObjectName = Unescape-Metadata -Value $Parts[1]
            $FieldName = Unescape-Metadata -Value $Parts[2]
            $ValueType = Unescape-Metadata -Value $Parts[3]

            if (
                -not (Test-Identifier -Value $ObjectName) -or
                -not (Test-Identifier -Value $FieldName) -or
                -not (Test-Identifier -Value $ValueType)
            ) {
                Exit-WithCode -Code 4
            }

            $Payload = Parse-Payload -LengthText $Parts[4] -Base64Text $Parts[5]
            $DuplicateKey = ('F|' + $ObjectName + '|' + $FieldName).ToUpperInvariant()
            $FieldObjects.Add($ObjectName.ToUpperInvariant())
            $SortKey = '2|' + $Parts[1] + '|' + $Parts[2]
            $Record = New-Record -Type F -Line $Lines[$LineIndex] -SortKey $SortKey -Payload $Payload
            $Record | Add-Member -NotePropertyName ObjectName -NotePropertyValue $ObjectName
            $Record | Add-Member -NotePropertyName FieldName -NotePropertyValue $FieldName
            $Record | Add-Member -NotePropertyName ValueType -NotePropertyValue $ValueType
        }
        elseif ($RecordType -eq 'T') {
            if ($Parts.Length -ne 4) {
                Exit-WithCode -Code 4
            }

            $TextName = Unescape-Metadata -Value $Parts[1]

            if (-not (Test-DottedIdentifier -Value $TextName)) {
                Exit-WithCode -Code 4
            }

            $Payload = Parse-Payload -LengthText $Parts[2] -Base64Text $Parts[3]
            $DuplicateKey = ('T|' + $TextName).ToUpperInvariant()
            $SortKey = '3|' + $Parts[1]
            $Record = New-Record -Type T -Line $Lines[$LineIndex] -SortKey $SortKey -Payload $Payload
            $Record | Add-Member -NotePropertyName TextName -NotePropertyValue $TextName
        }
        else {
            Exit-WithCode -Code 4
        }

        if ($DuplicateKeys.ContainsKey($DuplicateKey)) {
            Exit-WithCode -Code 9
        }

        $DuplicateKeys[$DuplicateKey] = $true

        if ($null -ne $PreviousSortKey -and $Ordinal.Compare($PreviousSortKey, $Record.SortKey) -ge 0) {
            Exit-WithCode -Code 4
        }

        $PreviousSortKey = $Record.SortKey
        $Records.Add($Record)
    }

    foreach ($FieldObject in $FieldObjects) {
        if (-not $ObjectNames.ContainsKey($FieldObject)) {
            Exit-WithCode -Code 4
        }
    }

    [System.IO.Directory]::CreateDirectory($StoreRoot) | Out-Null
    $DescriptorLines = New-Object 'System.Collections.Generic.List[string]'
    $DescriptorLines.Add('K|' + $Kind + '|1')
    $PayloadSequence = 0

    foreach ($Record in $Records) {
        if ($Record.Type -eq 'R') {
            $Parts = $Record.Line.Split([char]'|')
            $Registry = Unescape-Metadata -Value $Parts[1]
            $Key = Unescape-Metadata -Value $Parts[2]
            $ValueType = Unescape-Metadata -Value $Parts[3]
            $PayloadSequence++
            $PayloadName = 'P' + $PayloadSequence.ToString('D6', $Invariant) + '.bin'
            [System.IO.File]::WriteAllBytes((Join-Path $StoreRoot $PayloadName), $Record.Payload)
            $DescriptorLines.Add('R|' + $Registry + '|' + $Key + '|' + $ValueType + '|' + $PayloadName)
            continue
        }

        if ($Record.Type -eq 'O') {
            $DescriptorLines.Add('O|' + $Record.ObjectName + '|' + $Record.TypeId)
            continue
        }

        if ($Record.Type -eq 'F') {
            $PayloadSequence++
            $PayloadName = 'P' + $PayloadSequence.ToString('D6', $Invariant) + '.bin'
            [System.IO.File]::WriteAllBytes((Join-Path $StoreRoot $PayloadName), $Record.Payload)
            $DescriptorLines.Add('F|' + $Record.ObjectName + '|' + $Record.FieldName + '|' + $Record.ValueType + '|' + $PayloadName)
            continue
        }

        if ($Record.Type -eq 'T') {
            $PayloadSequence++
            $PayloadName = 'P' + $PayloadSequence.ToString('D6', $Invariant) + '.bin'
            [System.IO.File]::WriteAllBytes((Join-Path $StoreRoot $PayloadName), $Record.Payload)
            $DescriptorLines.Add('T|' + $Record.TextName + '|' + $PayloadName)
        }
    }

    $DescriptorLineArray = $DescriptorLines.ToArray()
    $DescriptorText = [string]::Join("`r`n", $DescriptorLineArray) + "`r`n"
    [System.IO.File]::WriteAllText($DescriptorPath, $DescriptorText, $Utf8NoBom)
}

function Escape-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $Bytes = Read-LimitedBytes -Path $SourcePath -Maximum $MaximumPayloadBytes
    $Escaped = ConvertTo-EscapedAscii -Bytes $Bytes
    $EscapedBytes = $Ascii.GetBytes($Escaped)
    Write-BytesAtomically -Path $TargetPath -Bytes $EscapedBytes
}

function Unescape-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $EscapedBytes = Read-LimitedBytes -Path $SourcePath -Maximum $MaximumPackageBytes

    foreach ($Byte in $EscapedBytes) {
        if ($Byte -gt 127) {
            Exit-WithCode -Code 8
        }
    }

    $Bytes = ConvertFrom-EscapedAsciiBytes -Bytes $EscapedBytes

    if ($Bytes.Length -gt $MaximumPayloadBytes) {
        Exit-WithCode -Code 10
    }

    Write-BytesAtomically -Path $TargetPath -Bytes $Bytes
}

function Write-RawPackageFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Header,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$RecordLines,

        [string]$HashOverride,

        [string]$CountOverride
    )

    $BodyLines = New-Object 'System.Collections.Generic.List[string]'
    $BodyLines.Add($Header)

    foreach ($RecordLine in $RecordLines) {
        $BodyLines.Add($RecordLine)
    }

    $BodyLineArray = $BodyLines.ToArray()
    $BodyText = [string]::Join("`r`n", $BodyLineArray) + "`r`n"
    $BodyBytes = $Ascii.GetBytes($BodyText)
    $Hash = Get-Sha256Hex -Bytes $BodyBytes

    if (-not [string]::IsNullOrEmpty($HashOverride)) {
        $Hash = $HashOverride
    }

    $Count = [string]$RecordLines.Length

    if (-not [string]::IsNullOrEmpty($CountOverride)) {
        $Count = $CountOverride
    }

    $Text = $BodyText + 'END|' + $Count + '|' + $Hash + "`r`n"
    [System.IO.File]::WriteAllBytes($Path, $Ascii.GetBytes($Text))
}

function Create-Fixtures {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    [System.IO.Directory]::CreateDirectory($Root) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'health.bin'), $Ascii.GetBytes('42'))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'enabled.bin'), $Ascii.GetBytes('1'))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'level.bin'), $Ascii.GetBytes('7'))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'name.bin'), $Ascii.GetBytes('Ada'))

    $Special = New-Object 'System.Collections.Generic.List[byte]'
    $Prefix = $Ascii.GetBytes('Percent% Bang! Amp& Pipe| Less< Greater> Caret^ Parens() Quote" CRLF')

    foreach ($Byte in $Prefix) {
        $Special.Add($Byte)
    }

    $Special.Add(13)
    $Special.Add(10)

    for ($Value = 0; $Value -le 255; $Value++) {
        $Special.Add([byte]$Value)
    }

    foreach ($Byte in @([byte]0xC3, [byte]0xA9, [byte]0xE9, [byte]0x9B, [byte]0xAA)) {
        $Special.Add($Byte)
    }

    $SpecialBytes = $Special.ToArray()
    $SpecialPath = Join-Path $Root 'special.bin'
    [System.IO.File]::WriteAllBytes($SpecialPath, $SpecialBytes)
    $Escaped = ConvertTo-EscapedAscii -Bytes $SpecialBytes
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'special-escaped.bin'), $Ascii.GetBytes($Escaped))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'malformed-escape.bin'), $Ascii.GetBytes('%4G'))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'lowercase-escape.bin'), $Ascii.GetBytes('%2f'))
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'overescaped.bin'), $Ascii.GetBytes('%41'))

    Write-RawPackageFixture -Path (Join-Path $Root 'bad-magic.btc') -Header 'NOTCODEC|1|SaveData' -RecordLines @()
    Write-RawPackageFixture -Path (Join-Path $Root 'version-2.btc') -Header 'BATCHCODEC|2|SaveData' -RecordLines @()
    Write-RawPackageFixture -Path (Join-Path $Root 'bad-integrity.btc') -Header 'BATCHCODEC|1|SaveData' -RecordLines @() -HashOverride ('0' * 64)
    Write-RawPackageFixture -Path (Join-Path $Root 'bad-escape.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|Bad%GG|0|')
    Write-RawPackageFixture -Path (Join-Path $Root 'lowercase-escape.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|Bad%2fName|0|')
    Write-RawPackageFixture -Path (Join-Path $Root 'overescaped.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|%41lpha|0|')
    Write-RawPackageFixture -Path (Join-Path $Root 'bad-base64.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|Bad|1|%%%')
    Write-RawPackageFixture -Path (Join-Path $Root 'duplicate.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|Same|0|', 'T|Same|0|')
    Write-RawPackageFixture -Path (Join-Path $Root 'incompatible.btc') -Header 'BATCHCODEC|1|Registry' -RecordLines @('T|Notes|0|')
    Write-RawPackageFixture -Path (Join-Path $Root 'bad-count.btc') -Header 'BATCHCODEC|1|SaveData' -RecordLines @() -CountOverride '1'
    Write-RawPackageFixture -Path (Join-Path $Root 'noncanonical.btc') -Header 'BATCHCODEC|1|TextBundle' -RecordLines @('T|Zulu|0|', 'T|Alpha|0|')
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'truncated.btc'), $Ascii.GetBytes("BATCHCODEC|1|SaveData`r`n"))
}

try {
    if ($Operation -eq 'Escape') {
        Escape-File -SourcePath $Argument1 -TargetPath $Argument2
        exit 0
    }

    if ($Operation -eq 'Unescape') {
        Unescape-File -SourcePath $Argument1 -TargetPath $Argument2
        exit 0
    }

    if ($Operation -eq 'Encode') {
        Encode-Package -DescriptorPath $Argument1 -StoreRoot $Argument2 -TargetPath $Argument3
        exit 0
    }

    if ($Operation -eq 'Decode') {
        Decode-Package -SourcePath $Argument1 -DescriptorPath $Argument2 -StoreRoot $Argument3
        exit 0
    }

    if ($Operation -eq 'CreateFixtures') {
        Create-Fixtures -Root $Argument1
        exit 0
    }

    exit 2
}
catch {
    exit 50
}
