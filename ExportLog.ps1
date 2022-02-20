$now=Get-Date
$startdate=$now.AddDays(-7)
$export=Get-EventLog -LogName "IPMI" -After $startdate -EntryType Warning,Error
$export | Export-Csv "~\Documents\IPMILog.csv"
