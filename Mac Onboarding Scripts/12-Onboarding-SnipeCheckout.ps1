#!/usr/local/bin/pwsh
#################################
# Onboarding - Snipe-IT Device Check-out
# By : Brent Rabe (brent.rabe@stjschools.org)

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

$snipeUserQuery = @{
    "username" = $args[2]
}

# Get Device User by Username
$snipeUserByUsername = (Invoke-RestMethod -Uri "$($snipeManagementURL)/api/v1/users" -Method GET -Headers $snipeHeaders -Body $snipeUserQuery).rows[0]
# Extract Snipe User ID
$snipeUserId = $snipeUserByUsername.id

$snipeCheckoutQuery = @{
    "checkout_to_type" = "user"
    "assigned_user" = $snipeUserId
}

# Checkout Device to User
$snipeCheckout = Invoke-RestMethod -Uri "$($snipeManagementURL)/api/v1/hardware/$($snipeDeviceId)/checkout" -Method POST -Headers $snipeHeaders -Body $snipeCheckoutQuery
Write-Host "Status: "$snipeCheckout.messages
Write-Host "Asset Number: "$snipeCheckout.payload.asset