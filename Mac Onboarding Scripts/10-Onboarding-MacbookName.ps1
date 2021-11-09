#!/usr/local/bin/pwsh
#################################
# Onboarding - Set MacBook Name
# By : Brent Rabe (brent.rabe@stjschools.org)

# Get username from $3 of Jamf Args
$username = $args[2]

# this is a small problem... default to root
if ($null -eq $username) {
    $username = "root"
}

# Get the supplied user's displayname
$userDisplayName = id -F $username

# Get the current devices model name, examples: MacBook Air, Mac Pro, Mac Mini
$systemModel = $(system_profiler SPHardwareDataType | grep "Model Name").split(':')[1].trim()

# Generalize the MacBook name to the System Model
$macbookName = $systemModel

# Determine if the display name ends with an s.
# If it do... just an apostrophe
if ($userDisplayName[-1].ToString().ToLower() -eq "s") {
    $macbookName = $userDisplayName + "' " + $systemModel
}
# If it don't... apostrophe s
else {
    $macbookName = $userDisplayName + "'s " + $systemModel
}
# Write this to the host, this will appear in the Jamf Logs
Write-Host "Setting MacBook name to " $macbookName

# Have Jamf take the wheel for the final touchdown.
jamf -setComputerName -name "$($macbookName)"