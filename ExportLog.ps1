$now=Get-Date
$startdate=$now.AddDays(-7)
$export=Get-EventLog -LogName "IPMI" -After $startdate -EntryType Information
$export | Export-Csv "IPMILog.csv"
