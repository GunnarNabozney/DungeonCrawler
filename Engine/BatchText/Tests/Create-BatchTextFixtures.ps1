[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [Parameter(Mandatory = $true)]
    [string]$MarkerPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Ascii = New-Object System.Text.ASCIIEncoding

if (Test-Path -LiteralPath $Root) {
    Remove-Item -LiteralPath $Root -Recurse -Force
}

[void](New-Item -ItemType Directory -Path $Root -Force)

function Write-Bytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $Path = Join-Path $Root $Name
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
}

function Write-Utf8 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    Write-Bytes -Name $Name -Bytes $Utf8.GetBytes($Text)
}

function Join-ByteArrays {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Left,

        [Parameter(Mandatory = $true)]
        [byte[]]$Right
    )

    $Result = New-Object byte[] ($Left.Length + $Right.Length)
    [System.Array]::Copy($Left, 0, $Result, 0, $Left.Length)
    [System.Array]::Copy(
        $Right,
        0,
        $Result,
        $Left.Length,
        $Right.Length
    )

    return $Result
}

Write-Bytes -Name 'empty.bin' -Bytes ([byte[]]@())

$Special = (
    'Percent % and bang !' +
    "`r`n" +
    'Ampersand & pipe | redirects < > caret ^ parentheses ( )' +
    "`n" +
    'Quotes "double" remain data' +
    "`r" +
    'Final line without newline'
)
$SpecialBytes = $Utf8.GetBytes($Special)
Write-Bytes -Name 'special.bin' -Bytes $SpecialBytes
[System.IO.File]::WriteAllText(
    (Join-Path $Root 'special.length.txt'),
    $SpecialBytes.Length.ToString(),
    $Ascii
)

$AllBytes = New-Object byte[] 256
for ($Index = 0; $Index -lt 256; $Index++) {
    $AllBytes[$Index] = [byte]$Index
}
Write-Bytes -Name 'allbytes.bin' -Bytes $AllBytes

Write-Utf8 -Name 'alpha.bin' -Text 'Alpha'
Write-Utf8 -Name 'beta.bin' -Text 'Beta'
Write-Utf8 -Name 'alphabeta.bin' -Text 'AlphaBeta'
Write-Utf8 -Name 'alphaalpha.bin' -Text 'AlphaAlpha'
Write-Utf8 -Name 'digits.bin' -Text '0123456789'
Write-Utf8 -Name 'slice.bin' -Text '3456'
Write-Utf8 -Name 'haystack.bin' -Text '00abc11abc'
Write-Utf8 -Name 'needle.bin' -Text 'abc'
Write-Utf8 -Name 'missing.bin' -Text 'xyz'
Write-Utf8 -Name 'replacement.bin' -Text 'X'
Write-Utf8 -Name 'replaced.bin' -Text '00X11X'
Write-Utf8 -Name 'deleted.bin' -Text '0011'
Write-Utf8 -Name 'overlap.bin' -Text 'aaaa'
Write-Utf8 -Name 'doublea.bin' -Text 'aa'
Write-Utf8 -Name 'lowerb.bin' -Text 'b'
Write-Utf8 -Name 'bb.bin' -Text 'bb'
Write-Utf8 -Name 'left.bin' -Text 'Left'
Write-Utf8 -Name 'right.bin' -Text 'Right'
Write-Utf8 -Name 'leftright.bin' -Text 'LeftRight'

$Multiline = "Line one`r`nLine two`nLine three`rLine four"
Write-Utf8 -Name 'multiline.bin' -Text $Multiline

$EAcute = [string][char]0x00E9
$Emoji = [char]::ConvertFromUtf32(0x1F642)
$Utf8Text = $EAcute + $Emoji
$Utf8Bytes = $Utf8.GetBytes($Utf8Text)
Write-Bytes -Name 'utf8.bin' -Bytes $Utf8Bytes
Write-Utf8 -Name 'utf8-first.bin' -Text $EAcute
Write-Utf8 -Name 'emoji.bin' -Text $Emoji
Write-Utf8 -Name 'utf8-replaced.bin' -Text ($EAcute + 'X')
[System.IO.File]::WriteAllText(
    (Join-Path $Root 'utf8.length.txt'),
    $Utf8Bytes.Length.ToString(),
    $Ascii
)

$Injection = (
    '& echo injected>"' +
    $MarkerPath +
    '" & %PATH% !BTX.Injection! | < > ^ ( ) "quoted"'
)
$InjectionBytes = $Utf8.GetBytes($Injection)
Write-Bytes -Name 'injection.bin' -Bytes $InjectionBytes
Write-Bytes `
    -Name 'injection-doubled.bin' `
    -Bytes (Join-ByteArrays -Left $InjectionBytes -Right $InjectionBytes)
