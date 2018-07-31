<#
.NAME
	WaiveDeviceThreats

.SYNOPSIS
	Allows for automatic device-level waiving of files that match a classification.

.DESCRIPTION
    To automatically waive all Trusted-Local files on computers that have "JTIETZE" in their name:

    WaiveDeviceThreats -DeviceFilter ".*JTIETZE.*" -ClassificationFilter PUP-Other

.PARAMETER DeviceFilter
    Regular expression to only per form action on devices that match a regular expression. Defaults to ".*"

.PARAMETER WaiveScope
    The scope at which to waive the hashes (device or global)

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>
[CmdletBinding()]
Param (
    [parameter(Mandatory=$True)]
    [String]$Console,
    [parameter(Mandatory=$False)]
    [String]$DeviceFilter = ".*",
    [parameter(Mandatory=$False)]
    [ValidateSet ("Device", "Global")]
    [String]$WaiveScope = "Device"
)

Import-Module CyCLI

# this will become a configurable parameter later
$ClassificationFilter = "Trusted-Local"

Get-CyAPI -Console $Console
$Devices = Get-CyDeviceList | Where-Object name -Match $DeviceFilter | Get-CyDeviceDetail

switch ($WaiveScope) {
    "Device" {
        # waive at device level
        foreach ($Device in $Devices) {
            $DeviceThreats = $Device | 
                Get-CyDeviceThreatList |
                Where-Object file_status -ne Whitelisted |
                Where-Object classification -eq Trusted

            foreach ($Threat in $DeviceThreats) {
                Write-Host "Waiving threat on device $($Device.name) [$($Device.id)]: $($Threat.file_path), SHA: $($Threat.sha256)"
                Update-CyDeviceThreat -DeviceThreat $Threat -Device $Device -Action Waive
                }
            }
        }
    "Global" {
        # safelist globally
        $GloballySafelistedHashes = (Get-CyGlobalList -List GlobalSafeList).sha256

        $ActiveHashes = @( foreach ($Device in $Devices) {
            $DeviceThreats = $Device | 
                Get-CyDeviceThreatList |
                Where-Object file_status -ne Whitelisted |
                Where-Object classification -eq Trusted
                foreach ($Threat in $DeviceThreats) {
                    $Threat.sha256
                }
            } )
        # safelist each hash only ONCE
        $ActiveHashes = $ActiveHashes | Select -Unique

        foreach ($hash in $ActiveHashes) {
            Write-Host "Globally safelisting hash: $($hash)"
            Add-CyHashToGlobalList -List GlobalSafeList -Category None -Reason "Safelisted via API" -SHA256 $hash
        }
    }
}
