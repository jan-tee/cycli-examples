# Safelist via API

This script allows to waive automatically based on classification "Trusted Local", either with device-local or global scope.

Filtering by device and filtering by classification is supported. Filtering by zone is not yet available.

To automatically globally-safelist all "Trusted-Local" hashes in the "TEST" console:

```powershell
Waive_Device_Threats.ps1 -Console TEST -WaiveScope Global
```

To waive locally all "Trusted-Local" hashes in the TEST console devices matching a regular expression for all devices starting with "JTIETZE" for classifications starting with "PUP":

```powershell
Waive_Device_Threats.ps1 -Console TEST -DeviceFilter "JTIETZE.*" 
```

*Note: When you re-run the script shortly after you safelisted, errors may occur because the hash has already been safelisted or waived by your last run. The API has a server-side cache that will not serve the latest data, and presents device threat records that can be a minute or so out of date. Wait a few minutes before you re-run the script.*

# TODO

- add filtering by zone
- add filtering based on classification