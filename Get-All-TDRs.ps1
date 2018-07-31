<#
.SYNOPSIS
    Downloads a number of Cylance console's TDR reports and converts them into Excel.

.DESCRIPTION
    Downloads a pre-configured list of of Cylance console's TDR reports and converts them into Excel.

    Configure "Consoles.json" in the TDR path with your console data; e.g. 

.PARAMETER TDRPath
    Optional, the base path to store the TDR data. Defaults to $HOME\TDRs (use symoblic links!)

.PARAMETER DefaultTDRUrl
    Optional. When no TDR URL is specified in the console profile, use this default TDR URL (default = EUC1 shard)

.PARAMETER ConsoleId
    Optional. Name of a particular console to retrieve.

.NOTES

.LINK
    Blog: http://tietze.io/
    Jan Tietze
#>
[CmdletBinding()]
Param (
    [parameter(Mandatory=$False)]
    [ValidateScript({Test-Path $_ -PathType Container })]
    [String]$TDRPath = "$($HOME)\TDRs",
    [parameter(Mandatory=$False)]
    [String]$DefaultTDRUrl = "https://protect-euc1.cylance.com/Reports/ThreatDataReportV1/",
    [parameter(Mandatory=$False)]
    [String]$ConsoleId = ""
)

Import-Module CyCLI

try {
    $Consoles = Get-CyConsoleConfig
} catch {
    Write-Error "There was an error parsing or accessing the console JSON file: $($TDRPath)\Consoles.json"
    break
}

if ([String]::Empty -eq $ConsoleId) {
    ForEach ($Console in ($Consoles | Where "AutoRetrieve" -ne $false)) {
        Write-Host "Retrieving console $($Console.ConsoleId)..."
        $TDRUrl = if (([String]::Empty -eq $Console.TDRUrl) -or ($Console.TDRUrl -eq $null)) { $DefaultTDRUrl } else { $Console.TDRUrl }
        Get-CyTDRs -TDRPath $TDRPath -Id $Console.ConsoleId -AccessToken $Console.Token -TDRUrl $TDRUrl
    }
} else {
    $Consoles |
        Where ConsoleId -eq $ConsoleId | ForEach-Object {
            Write-Host "Retrieving console $($_.ConsoleId)..."
            $TDRUrl = if (([String]::Empty -eq $_.TDRUrl) -or ($_.TDRUrl -eq $null)) { $DefaultTDRUrl } else { $_.TDRUrl }
            Get-CyTDRs -TDRPath $TDRPath -Id $_.ConsoleId -AccessToken $_.Token -TDRUrl $TDRUrl
        }
}