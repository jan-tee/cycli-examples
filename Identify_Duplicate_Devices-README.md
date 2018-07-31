# IdentifyDuplicateDevices.ps1

## What it does

This script will

* Identify "duplicate" device records in the console (which can be caused by a variety of conditions; most commonly, this is caused when certain attributes of a device change that are used to build its unique fingerprint; the unique fingerprint then changes, which cause the device to register under a new record with the same hostname)
* Identify whether there was any policy deviation as a result (e.g. after registration of the device under a new fingerprint, an automatic zone rule could have assigned a different policy than the one assigned to the original device)

## How to use it

```powershell
get-help .\IdentifyDuplicateDevices.ps1 -detailed
```

