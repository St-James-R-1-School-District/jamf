#!/usr/local/bin/pwsh
#################################
# Offboarding - Snipe-IT Device Check-in
# By : Brent Rabe (brent.rabe@stjschools.org)

$depNotifyLog = "/var/tmp/depnotify.log"

# Setup Snipe-IT Management Information

# Reference to arg $4 in Jamf
$snipeManagementURL = $args[3]
# Reference to arg $5 in Jamf
$snipeManagementAPIKey = $args[4]
$snipeHeaders = @{
    "Accept"        = "application/json"
    "Authorization" = "Bearer $($snipeManagementAPIKey)"
}


# Get Device Serial Number
# Use System Profiler SPHardwareDataType
$deviceSerial = $(system_profiler SPHardwareDataType | grep "Serial Number").split(':')[1].trim()

# Get Device By Serial Number
$snipeDeviceBySerial = (Invoke-RestMethod -Uri "$($snipeManagementURL)/api/v1/hardware/byserial/$($deviceSerial)" -Method GET -Headers $snipeHeaders).rows[0]
# Extract Snipe Device ID
$snipeDeviceId = $snipeDeviceBySerial.id

# Perform Checkin with Device ID
$snipeDeviceCheckIn = Invoke-RestMethod -Uri "$($snipeManagementURL)/api/v1/hardware/$($snipeDeviceId)/checkin" -Method POST -Headers $snipeHeaders

# Assuming everything went great....
if ($null -ne $snipeDeviceCheckIn) {
    "Status: $($snipeDeviceCheckIn.messages)" | Add-Content $depNotifyLog -ErrorAction SilentlyContinue
}
else {
    "Command: Alert: There was a problem completing the check-in process." | Add-Content $depNotifyLog -ErrorAction SilentlyContinue
}