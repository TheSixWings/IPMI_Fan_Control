#Use Supermicro IPMICFG to check CPU temp every 10 sec.
#Log the temp
#Control fan speed accordingly
#Display the temp as an icon in the statusbar

#Create log, must restart to enable the log
# If ("IPMI" -in (Get-EventLog -List -AsString) -eq $false) {
#     New-Eventlog -LogName "IPMI" -Source "scripts"
#     Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName "IPMI"
# }

#TaskScheduler: Run with highest privileges

Add-Type -ReferencedAssemblies @("System.Windows.Forms"; "System.Drawing") -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;
public static class TextNotifyIcon
{
    // it's difficult to call DestroyIcon() with powershell only...
    [System.Runtime.InteropServices.DllImport("user32")]
    private static extern bool DestroyIcon(IntPtr hIcon);

    public static NotifyIcon CreateTrayIcon()
    {
        var notifyIcon = new NotifyIcon();
        notifyIcon.Visible = true;

        return notifyIcon;
    }

    public static void UpdateIcon(NotifyIcon notifyIcon, string text)
    {
        using (var b = new Bitmap(16, 16))
        using (var g = Graphics.FromImage(b))
        using (var font = new Font(FontFamily.GenericMonospace, 8))
        {
            g.DrawString(text, font, Brushes.White, 0, 0);

            var icon = b.GetHicon();
            try
            {
                notifyIcon.Icon = Icon.FromHandle(icon);
            } finally
            {
                DestroyIcon(icon);
            }
        }
    }
}
"@

function CPUTemp
{
    $IPMIResult =IPMICFG-Win -nm cpumemtemp | Select-String -Pattern "CPU#0 = " | Out-String
    $CPUTemp = [int]$IPMIResult.Substring(9,$IPMIResult.IndexOf("(")-9)
    return $CPUTemp
}

#Set to Full 
IPMICFG-Win -raw 30 45 1 1 
$icon = [TextNotifyIcon]::CreateTrayIcon()
#Setup temp and fan tier
$temp1 = 75
$temp2 = 80
$temp3 = 90
$temp4 = 95
$fan0 = 20
$fan1 = 28
$fan2 = 36
$fan3 = 44
$fan4 = 52
#Fan RPM Hashtable
$RPMTable = @{
    64 = 8800
    62 = 8700
    60 = 8500
    58 = 8000
    56 = 7900
    54 = 7700
    52 = 7600
    50 = 7500
    48 = 7000
    46 = 6800
    44 = 6700
    42 = 6600
    40 = 6400
    38 = 5900
    36 = 5800
    34 = 5600
    32 = 5500
    30 = 5300
    28 = 4800
    26 = 4700
    24 = 4500
    22 = 4400
    20 = 4300
    18 = 3700
    16 = 3500
    14 = 3400
    12 = 3200
    10 = 3000
    8 = 2400
    6 = 2300
    4 = 2100
    2 = 2000
    0 = 1800
}

while($true){    
    #Update Current Temp
    $currentTemp = Start-Job -ScriptBlock ${Function:CPUTemp} | Wait-Job -Timeout 3 | Receive-Job
    Get-Job | Stop-Job
    Get-Job | Remove-Job

    if ($null -ne $currentTemp) {
        Write-EventLog -LogName IPMI -Source scripts -Message "Current CPU temperature is $currentTemp Celsius." -EventId 0 -EntryType information
        if ($currentTemp -gt $temp4) {
            $setFan = $fan4
        } 
        elseif ($currentTemp -gt $temp3) {
            $setFan = $fan3
        } 
        elseif ($currentTemp -gt $temp2) {
            $setFan = $fan2
        }
        elseif ($currentTemp -gt $temp1) {
            $setFan = $fan1
        } 
        else {
            $setFan = $fan0
        }
        #Set Fan Speed
        IPMICFG-Win -raw 30 70 66 1 0 $setFan
        Write-EventLog -LogName IPMI -Source scripts -Message "Set FAN1, FAN2 to " + $RPMTable.$setFan + " rpm." -EventId 0 -EntryType information
        IPMICFG-Win -raw 30 70 66 1 1 $setFan
        Write-EventLog -LogName IPMI -Source scripts -Message "Set FANA to " + $RPMTable.$setFan + " rpm." -EventId 0 -EntryType information
        [TextNotifyIcon]::UpdateIcon($icon, $currentTemp)
    }
    else {
        Write-EventLog -LogName IPMI -Source scripts -Message "No reading." -EventId 0 -EntryType Warning
    }
    Start-Sleep 10
    $IPMI = Get-Process IPMICFG-Win -ErrorAction SilentlyContinue
    if ($IPMI) {
        Write-EventLog -LogName IPMI -Source scripts -Message "Reset IPMI." -EventId 0 -EntryType Warning        
        $IPMI.Kill()
    }
    Start-Sleep 3
    $IPMI = Get-Process IPMICFG-Win -ErrorAction SilentlyContinue
    if ($IPMI) {
        Write-EventLog -LogName IPMI -Source scripts -Message "IPMI Error." -EventId 0 -EntryType Error
        [TextNotifyIcon]::UpdateIcon($icon, "E")
    }        
    Remove-Variable IPMI
}