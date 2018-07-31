<#
.DESCRIPTION
    This tool will identify duplicate devices in a CylancePROTECT tenant environment based on their MAC address.

    This is useful in situations when you encounter device duplication as a result of certain updates to the operating
    system, Windows edition changes or in-place upgrades affecting the serial number of the operating system, or changes
    to other components used for fingerprinting the device (all on Windows agents prior to version 1470).

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Console,
    [Parameter(Mandatory=$false)]
    [String]$ZoneName = "DUPLICATES"
)

Get-CyAPI -Console $Console

# "duplicate" entries must be at least 30 days offline in order to be removed
$MinimalAgeToRemove = [DateTime]::Now.AddDays(-30)

# create potential zone
$Zone = (Get-CyZoneList | Where-Object Name -eq $ZoneName)
if ($null -eq $Zone) {
    $Zone = New-CyZone -Name $ZoneName -Criticality Low
}

if ($null -eq $Zone) {
    Throw ("Zone could not be found or created; this can be API caching related; try again in a minute.")
}

# get list of devices
Write-Host "Getting device list"
$Devices = Get-CyDeviceList
# | Where-Object name -like DEFDHLT3181

# enrich device objects by adding field "mac0" with first MAC address
Write-Host "Enriching device list with MAC attributes"
$Devices | ForEach-Object { $_ | Add-Member mac0 $_.mac_addresses[0] }

# list of all device objects where the MAC address is registered more than once
Write-Host "Grouping device list by unique MAC address"
$DevicesGroupedByMAC = $Devices | Group-Object -Property mac0 | Where-Object Count -gt 1

# MAC addresses to ignore...
# These MAC addresses were observed in customer environments and were found to NOT be unique.
#
# 58-2C-80-13-92-63 = HUAWEI USB Ethernet adapter with default MAC address
$MACIgnoreList = @("58-2C-80-13-92-63")

# loop through each possible duplicate
$DevicesGroupedByMAC | ForEach-Object {
    $MAC = $_.Name
    if (![String]::IsNullOrEmpty($MAC) -and !($MACIgnoreList -contains $MAC)) {
        # expand device objects so that date_offline etc. become available
        $Elements = $_.Group | Get-CyDeviceDetail
        $NumberOfDistinctNames = ($Elements.Name | Select-Object -Unique).Count
        $ElementsOnline = $Elements | Where-Object state -eq Online
        if ($NumberOfDistinctNames -gt 1) 
        {
            # more than 1 distinct name - not a duplicate, but a strange occurence?
            Write-Host "ERROR: More than 1 distinct name for MAC: $($MAC); names: $($Elements.Name | Select-Object -Unique)"
        }
        elseif ($NumberOfDistinctNames -eq 1)
        {
            # multiple device records, but 1 MAC = same device. Youngest device should be kept, oldest devices will be added to "remove" Zone
            if ($ElementsOnline.Count -eq 1) {
                # remove all offline device records, because there is one that is online
                $Candidates = $Elements | Sort-Object -Descending -Property date_first_registered
                $Survivor = $ElementsOnline
                $CandidatesToRemove = $Candidates | Where-Object state -eq Offline | Where-Object date_offline -lt $MinimalAgeToRemove
                if ($CandidatesToRemove.Count -gt 0)
                {
                    Write-Host "DUPE1: Survivor $($Survivor.id), adding duplicate devices to zone: $($CandidatesToRemove.id)"
                    $CandidatesToRemove | Add-CyDeviceToZone -Zone $Zone
                }
            } elseif ($ElementsOnline.Count -eq 0) {
                # remove all but the device record that connected most recently
                $Candidates = $Elements | Sort-Object -Descending -Property date_offline
                $Survivor = $Candidates[0]
                $CandidatesToRemove = $Candidates[1..($Candidates.Count-1)] | Where-Object date_offline -lt $MinimalAgeToRemove
                if ($CandidatesToRemove.Count -gt 0) {
                    Write-Host "DUPE2: Survivor $($Survivor.id), adding duplicate devices to zone: $($CandidatesToRemove.id)"
                    $CandidatesToRemove | Add-CyDeviceToZone -Zone $Zone
                }
            }
        }
    }
}
