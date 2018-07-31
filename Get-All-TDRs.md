### Download TDRs

Fetch, store, and process TDR CSV a Cylance console's Threat Data Report (TDR) CSV files.

Example: To download the current TDRs to the directory `$HOME\TDRs\myconsole\`, store and timestamp the CSV files, and convert them into an XLSX file:

```powershell
Get-All-TDRs -Id myconsole -AccessToken 12983719283719283712973
```

Optionally, specify the TDR storage path and/or TDR URL (for non-EUC1 regions):
```powershell
Get-All-TDRs -TDRPath . -Id myconsole -AccessToken 12983719283719283712973 -TDRUrl https://protect-euc1.cylance.com/Reports/ThreatDataReportV1/
```

If you have configured your `Consoles.json` file, you can use auto-completion and refer to the console by name - this example would save to `$HOME\TDRs\myconsole`, and use the access token and (optionally, if it is configured) TDR Url from your `Consoles.json` file:
```powershell
Get-All-TDRs -Console myconsole
```