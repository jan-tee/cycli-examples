<#
    Sample Migration script

    These are elements that must be transferred manually:

    * any OPTICS configuration (detection rules; detection rulesets; exception rules)
    * any certificate configuration (certificate whitelist)
    * any safelisted hashes for scripts

    ...
#>

$Source = Get-CyAPI SOURCE -Scope None
$Dest = Get-CyAPI DEST -Scope None
$User = "actual.console.user.id.that.exists@in.dest.tenant"

<#
    Legacy consoles sometimes contain strings that cannot be written with current console releases
#>
function ToSafeString() {
    Param(
        [parameter(Mandatory=$true,Position=1)]
        [string]$String
    )

    $String -replace "[&<>]","_"
}

# Migrate Global List
Write-Host "Migrating global quarantine list"
$DestList = Get-CyGlobalList -List GlobalQuarantineList -API $Dest
Get-CyGlobalList -API $Source -List GlobalQuarantineList | ForEach-Object { 
    if (! ($DestList.sha256 -contains $_.sha256)) {
        Write-Host "Adding hash $($_.sha256) to global quarantine list in destination"
        Add-CyHashToGlobalList -List GlobalQuarantineList -SHA256 $_.sha256 -Reason "M:$($_.reason)" -API $Dest
    }
}

Write-Host "Migrating global safe list"
$DestList = Get-CyGlobalList -List GlobalSafeList -API $Dest
Get-CyGlobalList -API $Source -List GlobalSafeList | ForEach-Object { 
    if (! ($DestList.sha256 -contains $_.sha256)) {
        Write-Host "Adding hash $($_.sha256) to global safe list in destination"
        $Reason = "M:$(ToSafeString $_.reason)"
        Add-CyHashToGlobalList -List GlobalSafeList -SHA256 $_.sha256 -Reason $Reason -Category None -API $Dest 
    }
}

Write-Host "Migrating policies"
$DestPolicies = Get-CyPolicyList -API $Dest
Get-CyPolicyList -API $Source | ForEach-Object {
    $DestPolicyName = "M:$(ToSafeString $_.name)"
    if (! ($DestPolicies.name -contains $DestPolicyName)) {
        Write-Host "Migrating policy $($_.name)"
        Write-Host " - reading original policy settings"
        $SourcePolicy = Get-CyPolicy -API $Source -Policy $_
        Write-Host " - creating new policy"
        $DestPolicy = New-CyPolicy -API $Dest -Policy $SourcePolicy -Name $DestPolicyName -User $User
    }
}

Write-Host "Migrating zones"
$SourcePolicies = Get-CyPolicyList -API $Source
$DestZones = Get-CyZoneList -API $Dest
$DestPolicies = Get-CyPolicyList -API $Dest
Get-CyZoneList -API $Source | ForEach-Object {
    $DestZoneName = "M:$(ToSafeString $_.name)"
    if (! ($DestZones.name -contains $DestZoneName)) {
        Write-Host "Migrating zone '$($_.name)'"
        Write-Host " - reading original zone settings"
        $SourceZone = $_ | Get-CyZone -API $Source
        Write-Host " -- getting source policy name"
        $SourcePolicy = $SourcePolicies | Where-Object id -eq $SourceZone.policy_id
        Write-Host "    source policy name: $($SourcePolicy.name)"
        Write-Host " - creating new zone $($DestZoneName)"
        $DestPolicyName = "M:$($SourcePolicy.name)"
        Write-Host "SEARCHING FOR $DestPolicyName in $($DestPolicies.name)"
        $DestPolicy = $DestPolicies | Where-Object name -eq $DestPolicyName
        Write-Host " -- assigning policy $($DestPolicy.name) with id $($DestPolicy.id)"
        $NewDestZone = New-CyZone -Name $DestZoneName -Policy $DestPolicy -API $Dest
    }
}