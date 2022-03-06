$now = Get-Date
$startdate = $now.AddDays(-2)
$export = Get-EventLog -LogName "IPMI" -After $startdate
$export | Export-Csv "$PSScriptRoot\IPMILog.csv"