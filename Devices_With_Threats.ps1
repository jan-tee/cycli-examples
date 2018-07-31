<#
.DESCRIPTION
    Obtains a list of devices that have >0 threats and creates an Excel file overview.

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

Get-CyAPI -Console $Console

$Devices = Get-CyDeviceList | Get-CyDeviceDetail | Where-Object is_safe -eq $False
$Devices | Export-Excel -Path $OutFile -WorkSheetname "Devices with threats" -AutoSize -TableName "DevicesWithThreats" -Show

Foreach ($Device in $Devices) {
    Write-Host "Getting threats for $($Device.name) ($($Device.id))"
    $DeviceThreats = Get-CyDeviceThreatList -Device $Device
    $DeviceThreats | Export-Excel -Path $OutFile -WorkSheetname "Dev: $($Device.name)" -AutoSize -TableName "Dev$($Device.name)"
}
