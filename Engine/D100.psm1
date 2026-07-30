Set-StrictMode -Version Latest

$script:D100Minimum = 1
$script:D100MaximumExclusive = 101

function Invoke-D100Roll {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    return [int](
        Get-Random `
            -Minimum $script:D100Minimum `
            -Maximum $script:D100MaximumExclusive
    )
}

Export-ModuleMember -Function @(
    'Invoke-D100Roll'
)
