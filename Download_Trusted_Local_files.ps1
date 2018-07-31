
$threats = Get-CyDeviceList | Get-CyDeviceThreatList | Where-Object classification -eq Trusted
$downloads = $threats | Get-CyThreatDownloadLink
$wc = New-Object System.Net.WebClient
$downloads | ForEach-Object { if ($_.url -match "([^/]+\.zip)") { Write-Host "Downloading: $($_.url) => $($matches[0])" ; $wc.DownloadFile($_.url, $matches[0]) } }
