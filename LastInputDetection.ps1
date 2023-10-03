$MaxRunTime = (New-Timespan -minutes 718)
[int]$requiredIdleTime = 30
$NetworkSharePath = ""
Start-transcript -path C:\Temp\LastInput.log
if(test-path C:\temp\LastInput-Finished.log)
{
    remove-item C:\temp\LastInput-Finished.log
}


Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@




$timer = [Diagnostics.Stopwatch]::StartNew()

Do{
$Last = [PInvoke.Win32.UserInput]::LastInput
$Idle = [PInvoke.Win32.UserInput]::IdleTime
$LastStr = $Last.ToLocalTime().ToString("MM/dd/yyyy hh:mm tt")
Write-Host ("Last user keyboard/mouse input: " + $LastStr)
Write-Host ("Idle for " + $Idle.Days + " days, " + $Idle.Hours + " hours, " + $Idle.Minutes + " minutes, " + $Idle.Seconds + " seconds.")
$idletime = [int]$idle.minutes
start-sleep 60
#$timer.Elapsed.minutes #Elapsed Time for error checking in log
    if($timer.Elapsed.hours -eq $maxruntime.Hours -and $timer.Elapsed.minutes -ge $MaxRunTime.Minutes)
    {
        copy-item C:\temp\LastInput.log -Destination $NetworkSharePath\LastInput.log
        Return 1618
    }

} While ($idletime -lt $requiredIdleTime)


Stop-transcript

copy-item C:\temp\LastInput.log -Destination C:\Temp\LastInput-Finished.log


