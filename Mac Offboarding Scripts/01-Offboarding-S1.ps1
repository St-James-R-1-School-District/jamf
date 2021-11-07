#!/usr/local/bin/pwsh
#################################
# Offboarding - S1 Agent
# By : Brent Rabe (brent.rabe@stjschools.org)

$depNotifyLog = "/var/tmp/depnotify.log"

# Setup S1 Management Information

# Reference to Jamf arg $4
$sentinelOneManagementURL = $args[3]
# Reference to Jamf arg $5
$sentinelOneAPIToken = $args[4]
$sentinelOneHeaders = @{
    "Authorization" = "ApiToken $($sentinelOneAPIToken)"
}

# Get Mac Address
$macAddress = $(networksetup -getmacaddress en0)
$macAddress = $macAddress.Split(' ')[2].Trim()

# Determine if the S1 Agent is running
$sentinelRunning = @(Get-Process -Name "SentinelAgent" -ErrorAction SilentlyContinue).Count

# If S1 Agent is not running, skip the uninstall process.
if ($sentinelRunning -gt 0) {

    # Determine if the agent is showing in the console based on the MacAddress found earlier
    $countDevicesResponse = Invoke-RestMethod -Uri "$($sentinelOneManagementURL)/web/api/v2.1/agents/count?networkInterfacePhysical__contains=$($macAddress)" -Headers $sentinelOneHeaders

    # Continue uninstall process if the S1 agent was found
    if ($countDevicesResponse.data.total -eq '1') {
        # Report to tech what's happening
        "Status: Found an S1 Agent available to uninstall" | Add-Content $depNotifyLog
        Start-Sleep -Seconds 1

        # Get the S1 Agent Information
        $s1AgentInformation = Invoke-RestMethod -Uri "$($sentinelOneManagementURL)/web/api/v2.1/agents?networkInterfacePhysical__contains=$($macAddress)" -Headers $sentinelOneHeaders
        # Get the S1 Agent ID
        $s1AgentId = $s1AgentInformation.data[0].id
        # Report the current status to the tech
        "Status: Collecting agent information from S1 Management Console" | Add-Content $depNotifyLog

        # Define request body, note... this must be plain text like this to get passed correctly
        $s1AgentUninstallBody = @'
    {
        "data":{}, 
        "filter":{
            "ids": ["$s1AgentId"]
        }
    }
'@.Replace('$s1AgentId', $s1AgentId)
        
        # Send request for uninstall to management console
        $s1AgentUninstallResponse = Invoke-RestMethod `
            -Uri "$($sentinelOneManagementURL)/web/api/v2.1/agents/actions/uninstall" `
            -Headers $sentinelOneHeaders `
            -Method Post `
            -Body $s1AgentUninstallBody `
            -ContentType "application/json" `
            -SkipHttpErrorCheck
    
        # Confirm that S1 Agent is affected
        if ($s1AgentUninstallResponse.data.affected -eq "1") {
            "Status: SentinelOne Agent queued for uninstall via SentinelOne Management Console" | Add-Content $depNotifyLog
            $sentinelProcess = @(Get-Process -Name "SentinelAgent" -ErrorAction SilentlyContinue)
            $i = 0
            while ($sentinelProcess.Count -ne 0) {
                Start-Sleep -Milliseconds 500
                $sentinelProcess = @(Get-Process -Name "SentinelAgent" -ErrorAction SilentlyContinue)
                switch ($i) {
                    0 {
                        "Status: Waiting for the S1 Agent to close" | Add-Content $depNotifyLog
                        $i++
                    }
                    1 { 
                        "Status: Waiting for the S1 Agent to close." | Add-Content $depNotifyLog 
                        $i++
                    } 
                    2 { 
                        "Status: Waiting for the S1 Agent to close.." | Add-Content $depNotifyLog
                        $i++
                    }
                    3 { 
                        "Status: Waiting for the S1 Agent to close..." | Add-Content $depNotifyLog
                        $i = 0
                    }
                }
            }
            "Status: S1 Agent has been successfully uninstalled" | Add-Content $depNotifyLog
            Start-Sleep -Seconds 3
        }
        else {
            "Command: Alert: There was a problem uninstalling the S1 Agent"
        }        
    }
    else {
        "Status: No S1 Agent found to uninstall" | Add-Content $depNotifyLog
    }
}