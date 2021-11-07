#!/usr/local/bin/pwsh
#################################
# Offboarding - Jamf Device Delete
# By : Brent Rabe (brent.rabe@stjschools.org)

# Setup Jamf Management Information

# Reference to arg $4 in Jamf
$jamfManagementURL = $args[3] 
# Reference to arg $5 in Jamf
$jamfManagementAPIKey = $args[4]
$jamfHeaders = @{
    "accept"        = "application/json"
    "Authorization" = "Basic $($jamfManagementAPIKey)"
}

# Get Device Serial Number
# Use System Profiler SPHardwareDataType
$deviceSerial = $(system_profiler SPHardwareDataType | grep "Serial Number").split(':')[1].trim()

# Get Device Record from Jamf
$jamfDeviceRecord = Invoke-RestMethod -Uri "$($jamfManagementURL)/JSSResource/computers/serialnumber/$($deviceSerial)" -Headers $jamfHeaders -Body $jamfDeviceBody
$jamfDeviceId = $jamfDeviceRecord.computer.general.id
# Delete Jamf Record
Invoke-RestMethod -Uri "$($jamfManagementURL)/JSSResource/computers/id/$($jamfDeviceId)" -Headers $jamfHeaders -Body $jamfDeviceBody -Method DELETE