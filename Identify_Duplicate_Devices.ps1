<#
.SYNOPSIS
    Identifies duplicate devices in a console.

.DESCRIPTION
    Under certain circumstances, the same physical or virtual device can self-register in the console
    with a new fingerprint. This orphans the old device entry, and creates a new, mostly identical
    (except for the fingerprint, and 'last connected' etc. dates) device entry. This scripts helps to
    identify duplicates, to identify which devices to keep, and which devices have policy deviations
    between the "original" and "duplicate" agents.

    This script will put candidates for deletion as duplicates into a custom zone.

    Candidates are identified by having the same name; the single surviving candidate is the one with
    the latest registration timestamp. Only devices that are currently offline will be added to the
    potential duplicates.

.PARAMETER Console
    The console ID
.PARAMETER ZoneName
    The zone to add the identified duplicate devices to
.PARAMETER MinimumAgeInDays
    Only ever consider a device as duplicate if it registered more than this many days ago.
.PARAMETER IncludeFilter
    A regular expression that filters for systems to include. Default value is ".*", which means all devices.
.PARAMETER ExcludeFilter
    A regular expression that filters for systems to exclude. Default value is to exclude no devices.
.PARAMETER PerformChanges
    This parameter guarantees you have read the docs before you make any changes to your environment...

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Console,
    [Parameter(Mandatory=$false)]
    [String]$ZoneName = "DUPLICATES",
    [Parameter(Mandatory=$false)]
    [int]$MinimumAgeInDays = 30,
    [Parameter(Mandatory=$false)]
    [String]$IncludeFilter = ".*",
    [Parameter(Mandatory=$false)]
    [String]$ExcludeFilter = "MAGICSTRINGTHATISEXCLUDEDBYDEFAULT",
    [Parameter(Mandatory=$false)]
    [Switch]$PerformChanges
    )

Import-Module CyCLI

Get-CyAPI -Console $Console

$DoNotDeleteIfYoungerThanDate = (Get-Date).AddDays(-$MinimumAgeInDays)

$Zone = (Get-CyZoneList | Where-Object Name -eq $ZoneName)
if ($null -eq $Zone) {
    $Zone = New-CyZone -Name $ZoneName -Criticality Low
}

if ($null -eq $Zone) {
    Throw ("Zone could not be found or created; this can be API caching related; try again in a minute.")
}

$duplicateNames = Get-CyDeviceList | Where-Object name -Match $IncludeFilter | Where-Object name -NotMatch $ExcludeFilter | Group -Property name | Where-Object { $_.Count -gt 1 }

$duplicateNames | ForEach-Object {
    Write-Verbose "Processing $($_.Group.name) (= $($_.Group.Count) devices)"

    # sort descending by offline date - most recent first
    $candidates = @( ($_.Group) | 
        ForEach-Object {
            Get-CyDeviceDetail -Device $_
        } ) |
        Sort-Object -Property date_first_registered -Descending

    $keep = $candidates[0]
    $remove = @( $candidates[1..$candidates.Count] )

    if ($keep.state -eq "Offline") {
        Write-Verbose " - Designated survivor: $($keep.id), reg. $($keep.date_first_registered), went OFFLINE on : $($keep.date_offline). Potentially removing $($remove.Count) duplicates."
    } else {
        Write-Verbose " - Designated survivor: $($keep.id), reg. $($keep.date_first_registered), device is ONLINE: Potentially removing $($remove.Count) duplicates."
    }

    foreach ($r in $remove) {
        # delete device
        # should have a check whether the device has any threats

        if ($r.state -ne "Offline") {
            # removee must be OFFLINE to remove; any device that is ONLINE definitely exists.
            Write-Verbose "   - would NOT delete: $($r.name) ($($r.date_first_registered)), because device is ONLINE. Check manually!"
        } elseif ($r.date_first_registered -gt $DoNotDeleteIfYoungerThanDate) {
            # removee was registered earlier than "minimum age" days
            Write-Verbose "   - would NOT delete: $($r.name) ($($r.date_first_registered)), because device is younger than $($MinimumAgeInDays) days $($DoNotDeleteIfYoungerThanDate). Check manually!"
        } elseif ($r.date_first_registered -gt $keep.date_first_registered) {
            # keeper must have been registered AFTER removee
            Write-Verbose "   - would NOT delete: $($r.name) ($($r.date_first_registered))), because device was registered AFTER device to keep?! Check manually!"
        } elseif (($keep.date_offline -ne $null) -and ($r.date_offline -gt $keep.date_offline)) {
            # keeper must be either online, or offline, but offline date must be after removee
            Write-Verbose "   - would NOT delete: $($r.name) ($($r.date_first_registered))), because device went offline AFTER device to keep?! Check manually!"
        } else {
            # Add to zone of to be deleted devices!
            Write-Verbose "   - WOULD delete: $($r.name) ($($r.date_first_registered))), which went offline $($r.date_offline)"
            if ($PerformChanges) {
                Write-Host    "   - ADDING device $($r.name) to zone $($ZoneName)"
                Add-CyDeviceToZone -Device $r -Zone $Zone -Verbose
            }
        }

        if ($r.date_first_registered -eq $r.date_offline) {
            Write-Verbose"   * OBSERVATION: $($r.name) (reg date  $($r.date_first_registered) equals last offline date $($r.date_offline)"
        }

        if ($keep.policy.id -ne $r.policy.id) {
            Write-Verbose "   * NOTE! Policy difference between keeper and removee: $($r.name) ($($r.date_first_registered)) has policy $($r.policy.name), keeper ($($keep.date_first_registered)) has policy $($keep.policy.name)"
        }
    }
}
