Set-StrictMode -Version Latest

function Invoke-LoadGameScreen {
    [CmdletBinding()]
    param()

    [Console]::CursorVisible = $false
    ConsoleUI\Clear-ConsoleScreen

    ConsoleUI\Draw-Frame

    ConsoleUI\Write-Centered `
        -Y 3 `
        -Text 'THE HALL OF ECHOES' `
        -Color Yellow

    ConsoleUI\Write-Centered `
        -Y 9 `
        -Text 'No forgotten adventurers have been recorded yet.' `
        -Color Gray

    ConsoleUI\Write-Centered `
        -Y 12 `
        -Text 'Saved characters will eventually appear here.' `
        -Color DarkGray

    ConsoleUI\Write-Centered `
        -Y 22 `
        -Text 'Press any key to return...' `
        -Color DarkYellow

    ConsoleInput\Wait-ForAnyKey

    return 'MAIN_MENU'
}

Export-ModuleMember -Function @(
    'Invoke-LoadGameScreen'
)
