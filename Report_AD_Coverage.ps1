<#
.SYNOPSIS
    Reports coverage of devices (agents installed vs. not installed) for AD joined devices

.DESCRIPTION
    This script will take a list of all devices that are AD joined, and compare it to devices in the Cylance
    console, based on NetBIOS name of the device.

    Results are presented as raw data as well as a Pivot table/chart in Excel.

    Also, any devices that has not checked in with the console in 30 days will be reported.

.PARAMETER Path
    Excel file to write results to.

.PARAMETER Console
    The console ID

.PARAMETER MinimumAgeInDays
    Only ever consider a device if it has been offline at least this many days

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String]$Console,
    [Parameter(Mandatory=$false)]
    [int]$MinimumAgeInDays = 30,
    [Parameter(Mandatory=$true)]
    [ValidateScript({ 
        if (Test-Path -Path $_) {
            Throw "The output file $($_) exists."
        } else { return $true }
    })]
    [String]$Path,
    [Switch]$Show
    )

Get-CyAPI -Console $Console

$OutFile = $Path
$CutoffDate= (Get-Date).AddDays(-$MinimumAgeInDays)

$devicesAD = `
    Get-ADComputer -Filter * -Property name,DistinguishedName

$devicesCylance = `
    Get-CyDeviceList | Get-CyDeviceDetail | ForEach-Object {
        # NetBIOS names are 15 characters or less
        $hostname = $_.host_name
        if ($hostname -match "\.") {
            $hostname = $hostname.split(".")[0]
        }
        $_ | Add-Member NetBIOSName $hostname
        $_
    }

$devicesInstallStatus = $devicesAD |
    ForEach-Object {
        $netbios_name = $_.name
        $cylanceStatus = if ($netbios_name -in $devicesCylance.NetBIOSName) { "Installed" } else { "Not installed" }
        $cylanceRecord = $devicesCylance | Where-Object { $netbios_name -eq $_.NetBIOSName }
        $DNpath = $_.distinguishedname -split ',' 
        $Container = $DNpath[1..($DN.count -1)] -join ','
        [pscustomobject]@{
            Name = $_.name
            DNSHostName = $_.DNSHostName
            Container = $Container
            DistinguishedName = $_.DistinguishedName
            CylanceInstallStatus = $cylanceStatus
            CylanceRegistration = $cylanceRecord.date_first_registered
            CylanceVersion = $cylanceRecord.agent_version
            CylanceState = $cylanceRecord.state
            CylanceOS = $cylanceRecord.os_version
        }
    }

$devicesOfflineOverThreshold = $devicesCylance | 
    Where { $_.date_offline -ne $null -and $_.date_offline -lt $CutoffDate }

$pivot= @{
    AutoSize = $true
    AutoFilter = $true
    IncludePivotTable = $true
    PivotRows = @('CylanceInstallStatus', 'Container')
    PivotData = 'Name'
    IncludePivotChart = $true
    ChartType = "Pie"
    ShowPercent = $true
}

$pivot2 = @{
    PivotTableName = "DevicesTable"
    PivotData = @{"Name" = "Count"}
    SourceWorkSheet = "Devices"
    PivotRows = "CylanceInstallStatus"
    IncludePivotChart = $true
    ChartType = "ColumnClustered"
    NoLegend = $true
}


$xl = $devicesInstallStatus | Export-Excel -WorkSheetname "Devices" -AutoSize -TableName "DevicesTable" -Path $OutFile -PassThru
$xl = $devicesOfflineOverThreshold | Export-Excel -ExcelPackage $xl -WorkSheetname "Offline Devices" -AutoSize -TableName "OfflineDevicesTable"

if ($Show) {
    Export-Excel -Path $OutFile -Show
}