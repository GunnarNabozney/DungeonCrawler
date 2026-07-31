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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$MaximumTextLength = [int64]2147483647
$BufferSize = 65536
$Ascii = New-Object System.Text.ASCIIEncoding

function Exit-WithCode {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Code
    )

    exit $Code
}

function Assert-InputFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not [System.IO.File]::Exists($Path)) {
        Exit-WithCode -Code 3
    }
}

function Get-SafeLength {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Assert-InputFile -Path $Path
    $Length = (Get-Item -LiteralPath $Path -Force).Length

    if ($Length -gt $MaximumTextLength) {
        Exit-WithCode -Code 6
    }

    return [int64]$Length
}

function Parse-Offset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $Parsed = [int64]0

    if (-not [int64]::TryParse($Value, [ref]$Parsed)) {
        Exit-WithCode -Code 2
    }

    if ($Parsed -lt 0 -or $Parsed -gt $MaximumTextLength) {
        Exit-WithCode -Code 2
    }

    return $Parsed
}

function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    [System.IO.File]::WriteAllText($Path, $Value, $Ascii)
}

function Copy-Stream {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$InputStream,

        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$OutputStream,

        [int64]$Count = -1
    )

    $Buffer = New-Object byte[] $BufferSize
    $Remaining = $Count

    while ($Remaining -ne 0) {
        $Requested = $Buffer.Length

        if ($Remaining -gt 0 -and $Remaining -lt $Requested) {
            $Requested = [int]$Remaining
        }

        $Read = $InputStream.Read($Buffer, 0, $Requested)

        if ($Read -le 0) {
            break
        }

        $OutputStream.Write($Buffer, 0, $Read)

        if ($Remaining -gt 0) {
            $Remaining -= $Read
        }
    }

    if ($Count -ge 0 -and $Remaining -ne 0) {
        Exit-WithCode -Code 4
    }
}

function Compare-Files {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LeftPath,

        [Parameter(Mandatory = $true)]
        [string]$RightPath
    )

    $LeftLength = Get-SafeLength -Path $LeftPath
    $RightLength = Get-SafeLength -Path $RightPath

    if ($LeftLength -ne $RightLength) {
        return $false
    }

    $LeftStream = $null
    $RightStream = $null

    try {
        $LeftStream = [System.IO.File]::OpenRead($LeftPath)
        $RightStream = [System.IO.File]::OpenRead($RightPath)
        $LeftBuffer = New-Object byte[] $BufferSize
        $RightBuffer = New-Object byte[] $BufferSize

        while ($true) {
            $LeftRead = $LeftStream.Read($LeftBuffer, 0, $LeftBuffer.Length)
            $RightRead = $RightStream.Read($RightBuffer, 0, $RightBuffer.Length)

            if ($LeftRead -ne $RightRead) {
                return $false
            }

            if ($LeftRead -eq 0) {
                return $true
            }

            for ($Index = 0; $Index -lt $LeftRead; $Index++) {
                if ($LeftBuffer[$Index] -ne $RightBuffer[$Index]) {
                    return $false
                }
            }
        }
    }
    finally {
        if ($LeftStream) {
            $LeftStream.Dispose()
        }

        if ($RightStream) {
            $RightStream.Dispose()
        }
    }
}

function Concatenate-Files {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LeftPath,

        [Parameter(Mandatory = $true)]
        [string]$RightPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $LeftLength = Get-SafeLength -Path $LeftPath
    $RightLength = Get-SafeLength -Path $RightPath

    if (($LeftLength + $RightLength) -gt $MaximumTextLength) {
        Exit-WithCode -Code 6
    }

    $LeftStream = $null
    $RightStream = $null
    $TargetStream = $null

    try {
        $LeftStream = [System.IO.File]::OpenRead($LeftPath)
        $RightStream = [System.IO.File]::OpenRead($RightPath)
        $TargetStream = [System.IO.File]::Open(
            $TargetPath,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )

        Copy-Stream -InputStream $LeftStream -OutputStream $TargetStream
        Copy-Stream -InputStream $RightStream -OutputStream $TargetStream
    }
    finally {
        if ($LeftStream) {
            $LeftStream.Dispose()
        }

        if ($RightStream) {
            $RightStream.Dispose()
        }

        if ($TargetStream) {
            $TargetStream.Dispose()
        }
    }
}

function Slice-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [int64]$Start,

        [Parameter(Mandatory = $true)]
        [int64]$Length,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $SourceLength = Get-SafeLength -Path $SourcePath

    if ($Start -gt $SourceLength) {
        Exit-WithCode -Code 4
    }

    if ($Length -gt ($SourceLength - $Start)) {
        Exit-WithCode -Code 4
    }

    $SourceStream = $null
    $TargetStream = $null

    try {
        $SourceStream = [System.IO.File]::OpenRead($SourcePath)
        [void]$SourceStream.Seek($Start, [System.IO.SeekOrigin]::Begin)
        $TargetStream = [System.IO.File]::Open(
            $TargetPath,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )

        Copy-Stream `
            -InputStream $SourceStream `
            -OutputStream $TargetStream `
            -Count $Length
    }
    finally {
        if ($SourceStream) {
            $SourceStream.Dispose()
        }

        if ($TargetStream) {
            $TargetStream.Dispose()
        }
    }
}

function Get-PrefixTable {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Pattern
    )

    $Table = New-Object int[] $Pattern.Length
    $Matched = 0

    for ($Index = 1; $Index -lt $Pattern.Length; $Index++) {
        while (
            $Matched -gt 0 -and
            $Pattern[$Index] -ne $Pattern[$Matched]
        ) {
            $Matched = $Table[$Matched - 1]
        }

        if ($Pattern[$Index] -eq $Pattern[$Matched]) {
            $Matched++
        }

        $Table[$Index] = $Matched
    }

    return $Table
}

function Search-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TextPath,

        [Parameter(Mandatory = $true)]
        [string]$NeedlePath,

        [Parameter(Mandatory = $true)]
        [int64]$Start
    )

    $TextLength = Get-SafeLength -Path $TextPath
    $NeedleLength = Get-SafeLength -Path $NeedlePath

    if ($Start -gt $TextLength) {
        Exit-WithCode -Code 4
    }

    if ($NeedleLength -eq 0) {
        return $Start
    }

    if ($NeedleLength -gt ($TextLength - $Start)) {
        return [int64]-1
    }

    $Needle = [System.IO.File]::ReadAllBytes($NeedlePath)
    $Table = Get-PrefixTable -Pattern $Needle
    $Stream = $null

    try {
        $Stream = [System.IO.File]::OpenRead($TextPath)
        [void]$Stream.Seek($Start, [System.IO.SeekOrigin]::Begin)
        $Buffer = New-Object byte[] $BufferSize
        $Absolute = $Start
        $Matched = 0

        while (($Read = $Stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            for ($Index = 0; $Index -lt $Read; $Index++) {
                $Current = $Buffer[$Index]

                while (
                    $Matched -gt 0 -and
                    $Current -ne $Needle[$Matched]
                ) {
                    $Matched = $Table[$Matched - 1]
                }

                if ($Current -eq $Needle[$Matched]) {
                    $Matched++
                }

                if ($Matched -eq $Needle.Length) {
                    return (
                        $Absolute +
                        $Index -
                        $Needle.Length +
                        1
                    )
                }
            }

            $Absolute += $Read
        }

        return [int64]-1
    }
    finally {
        if ($Stream) {
            $Stream.Dispose()
        }
    }
}

function Pending-IsPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[byte]]$Pending,

        [Parameter(Mandatory = $true)]
        [byte[]]$Pattern
    )

    if ($Pending.Count -gt $Pattern.Length) {
        return $false
    }

    for ($Index = 0; $Index -lt $Pending.Count; $Index++) {
        if ($Pending[$Index] -ne $Pattern[$Index]) {
            return $false
        }
    }

    return $true
}

function Replace-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$SearchPath,

        [Parameter(Mandatory = $true)]
        [string]$ReplacementPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    [void](Get-SafeLength -Path $SourcePath)
    $SearchLength = Get-SafeLength -Path $SearchPath
    [void](Get-SafeLength -Path $ReplacementPath)

    if ($SearchLength -eq 0) {
        Exit-WithCode -Code 5
    }

    $Search = [System.IO.File]::ReadAllBytes($SearchPath)
    $Replacement = [System.IO.File]::ReadAllBytes($ReplacementPath)
    $Pending = New-Object 'System.Collections.Generic.List[byte]'
    $SourceStream = $null
    $TargetStream = $null
    $OutputLength = [int64]0

    try {
        $SourceStream = [System.IO.File]::OpenRead($SourcePath)
        $TargetStream = [System.IO.File]::Open(
            $TargetPath,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )

        $Buffer = New-Object byte[] $BufferSize

        while (($Read = $SourceStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            for ($Index = 0; $Index -lt $Read; $Index++) {
                $Pending.Add($Buffer[$Index])

                while (
                    $Pending.Count -gt 0 -and
                    -not (Pending-IsPrefix -Pending $Pending -Pattern $Search)
                ) {
                    $TargetStream.WriteByte($Pending[0])
                    $Pending.RemoveAt(0)
                    $OutputLength++

                    if ($OutputLength -gt $MaximumTextLength) {
                        Exit-WithCode -Code 6
                    }
                }

                if ($Pending.Count -eq $Search.Length) {
                    if ($Replacement.Length -gt 0) {
                        $TargetStream.Write(
                            $Replacement,
                            0,
                            $Replacement.Length
                        )
                    }

                    $OutputLength += $Replacement.Length

                    if ($OutputLength -gt $MaximumTextLength) {
                        Exit-WithCode -Code 6
                    }

                    $Pending.Clear()
                }
            }
        }

        for ($Index = 0; $Index -lt $Pending.Count; $Index++) {
            $TargetStream.WriteByte($Pending[$Index])
            $OutputLength++

            if ($OutputLength -gt $MaximumTextLength) {
                Exit-WithCode -Code 6
            }
        }
    }
    finally {
        if ($SourceStream) {
            $SourceStream.Dispose()
        }

        if ($TargetStream) {
            $TargetStream.Dispose()
        }
    }
}

try {
    switch -CaseSensitive ($Operation) {
        'Length' {
            if (-not $Argument1 -or -not $Argument2) {
                Exit-WithCode -Code 2
            }

            $Length = Get-SafeLength -Path $Argument1
            Write-Result -Path $Argument2 -Value $Length.ToString()
            exit 0
        }

        'Compare' {
            if (-not $Argument1 -or -not $Argument2 -or -not $Argument3) {
                Exit-WithCode -Code 2
            }

            $Equal = Compare-Files `
                -LeftPath $Argument1 `
                -RightPath $Argument2

            if ($Equal) {
                Write-Result -Path $Argument3 -Value '1'
            }
            else {
                Write-Result -Path $Argument3 -Value '0'
            }

            exit 0
        }

        'Concatenate' {
            if (-not $Argument1 -or -not $Argument2 -or -not $Argument3) {
                Exit-WithCode -Code 2
            }

            Concatenate-Files `
                -LeftPath $Argument1 `
                -RightPath $Argument2 `
                -TargetPath $Argument3

            exit 0
        }

        'Slice' {
            if (
                -not $Argument1 -or
                $null -eq $Argument2 -or
                $null -eq $Argument3 -or
                -not $Argument4
            ) {
                Exit-WithCode -Code 2
            }

            $Start = Parse-Offset -Value $Argument2
            $Length = Parse-Offset -Value $Argument3

            Slice-File `
                -SourcePath $Argument1 `
                -Start $Start `
                -Length $Length `
                -TargetPath $Argument4

            exit 0
        }

        'Search' {
            if (
                -not $Argument1 -or
                -not $Argument2 -or
                $null -eq $Argument3 -or
                -not $Argument4
            ) {
                Exit-WithCode -Code 2
            }

            $Start = Parse-Offset -Value $Argument3
            $Index = Search-File `
                -TextPath $Argument1 `
                -NeedlePath $Argument2 `
                -Start $Start

            Write-Result -Path $Argument4 -Value $Index.ToString()
            exit 0
        }

        'Replace' {
            if (
                -not $Argument1 -or
                -not $Argument2 -or
                -not $Argument3 -or
                -not $Argument4
            ) {
                Exit-WithCode -Code 2
            }

            Replace-File `
                -SourcePath $Argument1 `
                -SearchPath $Argument2 `
                -ReplacementPath $Argument3 `
                -TargetPath $Argument4

            exit 0
        }

        default {
            Exit-WithCode -Code 2
        }
    }
}
catch {
    [Console]::Error.WriteLine(
        'BatchText helper failed: ' + $_.Exception.Message
    )
    exit 70
}
