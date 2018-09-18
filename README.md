# cycli-examples

CyCLI Powershell module usage examples

## One-liner examples

# Add all hashes from an Excel file to Global Quarantine list

```powershell
(import-excel .\HashesFromExcel.xlsx).Hash | Add-CyHashToGlobalList -List GlobalQuarantineList -Category None -Reason "Test" -Verbose
```

# Safelist all Trusted-Local files

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