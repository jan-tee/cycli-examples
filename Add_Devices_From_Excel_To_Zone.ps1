<#
.DESCRIPTION
    This tool will take an Excel file, look at its "Machine Name" column, and add all of the hosts in it that already exist
    in the console to a specific zone.

    This is useful in situations where you need to add arbitrary groups not based on some criteria that can be expressed via zone rules.

    The Excel file needs to have a column "Machine Name" on the active worksheet, and this has to contain the device names to add to the zone.

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Console,
    [Parameter(Mandatory=$false)]
    [String]$ZoneName = "Imported from Excel",
    [Parameter(Mandatory=$false)]
    [String]$ExcelFile = "Add_Devices_From_Excel_To_Zone.xlsx"
)

Import-Module CyCLI
Import-Module ImportExcel

Get-CyAPI -Console $Console

# Creates zone if it does not exist
$Zone = Get-CyZone -Name $ZoneName
if ($Zone -eq $null) {
    $Zone = New-CyZone -Name $ZoneName -Criticality Normal
}

# Get list of devices to add to zone
$DevicesToAdd = @( Import-Excel -Path $ExcelFile | Select-Object "Machine Name")

# Identify devices that already exist in tenant 
Write-Host -NoNewline "There were $($DevicesToAdd.Count) devices in the Excel file, of which "
$ExistingDevices = @( Get-CyDeviceList | Where-Object { $DevicesToAdd."Machine Name" -Contains $_.name } )
Write-Host "$($ExistingDevices.Count) devices exist in the tenant."

# Add those devices to zone
Write-Host -NoNewline "Adding devices to the zone $($Zone.name)..."
$ExistingDevices | Add-CyDeviceToZone -Zone $Zone
Write-Host "done."
