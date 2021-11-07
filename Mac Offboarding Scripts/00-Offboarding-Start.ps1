#!/usr/local/bin/pwsh
#################################
# Offboarding - Start DEPNotify
# By : Brent Rabe (brent.rabe@stjschools.org)

$testMode = $false
$fullScreen = $true
$noSleep = $true
$shutdown = $true

### Branding ###
$bannerImagePath = "/Library/Application Support/St. James R-1 School District/Branding/DEP/dep-header.png" 
$bannerTitle = "Device Offboarding"

$mainText = "Please wait while this device is offboarded."

$initialStatus = "Gathering information..."
$completeStatus = "Offboarding complete!"

$policyArray = @(
    "Uninstalling SentinelOne,uninstallSentinelOne",
    "Checking device into Inventory,offboardCheckIn",
    "Removing device from Jamf,offboardRemoveFromJamf"
)

### Core Script Logic ###

# Variables for File Paths
$depNotifyApp = "/Applications/Utilities/DEPNotify.app"
$depNotifyLog = "/var/tmp/depnotify.log"
$depNotifyDebug = "/var/tmp/depnotifyDebug.log"
$depNotifyDone = "/var/tmp/com.depnotify.offboarding.done"


# Cleanup previous runs
Remove-Item $depNotifyLog -Force -ErrorAction SilentlyContinue
Remove-Item $depNotifyDebug -Force -ErrorAction SilentlyContinue
Remove-Item $depNotifyDone -Force -ErrorAction SilentlyContinue

# Wait for Setup Assistant to exit
do {
    $setupAssistantProcesses = @(Get-Process "Setup Assistant" -ErrorAction SilentlyContinue)
    "Setup assistant still running... waiting 1 second... " | Add-Content $depNotifyDebug
    Start-Sleep -Seconds 1
} until ($setupAssistantProcesses.Count -eq 0 )

# Wait for finder
do {
    $finderProcesses = @(Get-Process "Finder" -ErrorAction SilentlyContinue)
    "Waiting for finder to continue... waiting 1 second..." | Add-Content $depNotifyDebug
    Start-Sleep -Seconds 1
} until ($finderProcesses.Count -ne 0 )

# Current User Information
$currentUser = $(Get-Item "/dev/console").User
$currentUserId = id -u $currentUser

"Current user set to $($currentUser) (id: $($currentUserId))" | Add-Content $depNotifyDebug

# Set banner image
"Command: Image: $($bannerImagePath)" | Add-Content $depNotifyLog
# Set banner title
"Command: MainTitle: $($bannerTitle)" | Add-Content $depNotifyLog
# Set main text
"Command: MainText: $($mainText)" | Add-Content $depNotifyLog
# Set determinate
"Command: DeterminateManual: $($policyArray.Count)" | Add-Content $depNotifyLog
# Set starting text 
"Status: $($initialStatus)" | Add-Content $depNotifyLog
# Set exit key
"Command: QuitKey: x" | Add-Content $depNotifyLog

# Launch DEP Notify
if ($fullScreen -eq $true) {
    # Launch with Fullscreen enabled
    launchctl asuser $currentUserId open -a "$($depNotifyApp)" --args -path "$($depNotifyLog)" -fullScreen
}
else {
    # Launch without Fullscreen
    launchctl asuser $currentUserId open -a "$($depNotifyApp)" --args -path "$($depNotifyLog)"
}

# Grabbing the DEP Notify Process ID for use later
do {
    $depNotifyProcess = @(Get-Process "DEPNotify")
    Start-Sleep -Seconds 1
} until ($depNotifyProcess.Count -eq 1)
$depNotifyProcessId = $depNotifyProcess[0].Id


# Using Caffeinate binary to keep the computer awake if enabled
if ($noSleep -eq $true) {
    "noSleep specified... caffeinating DEPNotify Process (id: $($depNotifyProcessId))" | Add-Content $depNotifyLog
    Start-Process nohup "/usr/bin/caffeinate -disu -w '$($depNotifyProcessId)'"
}

# Loop through the process
foreach ($policy in $policyArray) {
    "Status: $($policy.Split(',')[0])" | Add-Content $depNotifyLog    
    if ($testMode -eq $true) {
        Start-Sleep -Seconds 7
    } else {
        /usr/local/bin/jamf policy -event "$($policy.Split(',')[1])"
    }
    "Command: DeterminateManualStep: 1" | Add-Content $depNotifyLog
}

# Completion Text
"Status: $($completeStatus)" | Add-Content $depNotifyLog
"Command: ContinueButton: Shutdown" | Add-Content $depNotifyLog 

if ($testMode -eq $false)
{
    do {
        $depNotifyProcess = @(Get-Process "DEPNotify" -ErrorAction SilentlyContinue)
        Start-Sleep -Seconds 1
    } until ($depNotifyProcess.Count -eq 0)
    
    if ($shutdown -eq $true)
    {
        # shutdown, halt, now
    	shutdown -h now
    }
}