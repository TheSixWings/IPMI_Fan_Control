IPMICFG-WIN -raw 30 45 1 1
Write-EventLog -LogName IPMI -Source scripts -Message "Server restarted, set all fan to full speed." -EventId 0 -EntryType information
IPMICFG-WIN -raw 30 70 66 1 0 32
Write-EventLog -LogName IPMI -Source scripts -Message "Initial set FAN1, FAN2 to 5500 rpm." -EventId 0 -EntryType information
IPMICFG-WIN -raw 30 70 66 1 1 32
Write-EventLog -LogName IPMI -Source scripts -Message "Initial set FANA to 5500 rpm." -EventId 0 -EntryType information