<#
.DESCRIPTION
    Obtains a list of devices that are most likely NOT domain joined in a tenant.

    Outputs an Excel file with details.

    Requires "ImportExcel" module (can be installed using "Import-Module ImportExcel").

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Console,
    [Parameter(Mandatory=$false)]
    [String]$OutFile = "$([System.IO.Path]::GetTempFileName()).xlsx"
    )

Import-Module CyCLI
Import-Module ImportExcel

Get-CyAPI -Console $Console

$Joined = @()
$NonJoined = @()

Get-CyDeviceList | 
    Get-CyDeviceDetail | 
    ForEach-Object {
        Write-Verbose "Processing $($_.name) ($($_.id))"
        if (($_.last_logged_in_user -like "*\*") -and ($_.last_logged_in_user -notlike "$($_.name)\*")) {
            # this computer is likely domain joined
            Write-Verbose "Probably IS  domain joined: $($_.name))"
            $_ | Add-Member DomainJoined YES
        } else {
            Write-Verbose "Probably NOT domain joined: $($_.name))"
            $_ | Add-Member DomainJoined NO
        }
        $_
    } | Export-Excel -Path $OutFile -TableName "Devices" -WorkSheetname "Devices with domain join status" -AutoSize -Show
