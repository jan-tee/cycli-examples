# cycli-examples

CyCLI Powershell module usage examples

## One-liner example: Add all hashes from an Excel file to Global Quarantine list

```(import-excel .\HashesFromExcel.xlsx).Hash | Add-CyHashToGlobalList -List GlobalQuarantineList -Category None -Reason "Test" -Verbose```

