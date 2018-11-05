# cycli-examples

CyCLI Powershell module usage examples

## One-liner examples

# Add all hashes from an Excel file to Global Quarantine list

```powershell
(import-excel .\HashesFromExcel.xlsx).Hash | Add-CyHashToGlobalList -List GlobalQuarantineList -Category None -Reason "Test" -Verbose
```

# Safelist all Trusted-Local files

This will globally safelist all `Trusted-Local` classified detections that are currently quarantined.

```powershell
(get-cydevicelist | %{ Get-CyDeviceThreatList -Device $_  | where classification -eq "Trusted" | where status -eq "Quarantined" }).sha256 | Sort-Object -Unique | Add-CyHashToGlobalList -List GlobalSafeList -Category None -Reason "Trusted-Local"
```

# List devices that have been offline for longer than 5 days

```powershell
get-cydevicelist | Get-CyDeviceDetail | where date_offline -ne $null | where date_offline -lt (Get-Date).AddDays(-5)
```

# Get all script exclusions from  all policies

```powershell
Get-CyPolicyList | %{ (Get-CyPolicy -Policy $_) | script_control.global_settings.allowed_folders }
```

# Get all mem def exclusions from all policies
```powershell
Get-CyPolicyList | Get-CyPolicy | %{ $_.memoryviolation_actions.memory_exclusion_list }
```

# Export all policies and all settings to JSON
```powershell
get-cypolicylist | Get-CyPolicy | convertto-json | Out-File Policies.json
```

# Create a new policy
```powershell
$p = New-CyPolicy -Name "Blank Policy" -User myconsoleuser@company.com
$p | Update-CyPolicy -User myconsoleuser@company.com
```

# Assing policy
```powershell
$policy = get-cypolicylist | where name -eq "ALLOW (Files: Alert, Mem: Alert, Script: Alert)"
$device = get-cydevicelist | where name -eq "JTIETZE-OPTICS1"
Set-CyPolicyForDevice -Device $device -Policy $policy
```

# Add a memory and a scan exclusion to an existing policy, and commit policy to console
```powershell
$p = (Get-CyPolicyList)[0] | Get-CyPolicy
$p | Add-CyPolicyListSetting -Type MemDefExclusionPath -Value "\\some\app.exe"
$p | Add-CyPolicyListSetting -Type ScanExclusion -Value "c:\\somedir\\somewhere\\"
$p | Update-CyPolicy -User myconsoleuser@company.com
```

# Clone a policy
```powershell
Copy-CyPolicy -SourcePolicyName "SCADA (Files: Block, Mem: Terminate, Script: Block, App Control: On)" -TargetPolicyName "SCADA2" -User myconsoleuser@company.com
```
# Get detections with severity "low"

```powershell
Get-CyDetectionList | where severity -ne "Low" | ft
```

