#Use Supermicro IPMICFG to check CPU temp every 8 sec.
#Log the temp
#Control fan speed accordingly
#Display the temp as an icon in the statusbar

#Create log, must restart to enable the log
# If ("IPMI" -in (Get-EventLog -List -AsString) -eq $false) {
#     New-Eventlog -LogName "IPMI" -Source "scripts"
#     Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName "IPMI"
# }

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
    $IPMIResult = IPMICFG-WIN -nm cpumemtemp | Select-String -Pattern "CPU#0 = " | Out-String
    $CPUTemp = [int]$IPMIResult.Substring(9,$IPMIResult.IndexOf("(")-9)
    Return $CPUTemp
}
#Set to Full 
#IPMICFG-WIN -raw 30 45 1 1 
$icon = [TextNotifyIcon]::CreateTrayIcon()
While($true){    
    $currentTemp = CPUTemp
    If ($currentTemp -ne $null) {
        Write-EventLog -LogName IPMI -Source scripts -Message "Current CPU temperature is $currentTemp degrees C" -EventId 0 -EntryType information
        if ($currentTemp -gt 95) {
            IPMICFG-WIN -raw 30 70 66 1 0 55
            IPMICFG-WIN -raw 30 70 66 1 1 55
        }
        elseif ($currentTemp -gt 90) {
            IPMICFG-WIN -raw 30 70 66 1 0 44
            IPMICFG-WIN -raw 30 70 66 1 1 44
        }
        elseif ($currentTemp -gt 88) {
            IPMICFG-WIN -raw 30 70 66 1 0 39
            IPMICFG-WIN -raw 30 70 66 1 1 39
        }
        elseif ($currentTemp -gt 85) {
            IPMICFG-WIN -raw 30 70 66 1 0 30
            IPMICFG-WIN -raw 30 70 66 1 1 30
        }
        else {
            IPMICFG-WIN -raw 30 70 66 1 0 24
            IPMICFG-WIN -raw 30 70 66 1 1 24
        }
        [TextNotifyIcon]::UpdateIcon($icon, $currentTemp)
    }
   [Threading.Thread]::Sleep(8000)
}