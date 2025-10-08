Import-Module dbatools, pester, pshtml, fabrictools

Install-DbaMaintenanceSolution -SqlInstance dbatools2 -BackupLocation /shared/ -InstallJobs -AutoScheduleJobs WeeklyFull -Confirm:$false

# offline some random dbs
(Get-Random (Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem) -count 5) | 
Set-DbaDbState -Offline -Confirm:$false

# some random dbs should be simple recovery model
(Get-Random (Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem -Status Normal) -count 5) | 
Set-DbaDbRecoveryModel -RecoveryModel Simple -Confirm:$false

# some random dbs should be read only
(Get-Random (Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem -Status Normal) -count 2) | 
Set-DbaDbState -ReadOnly -Confirm:$false

# some random dbs should have query store disabled
(Get-Random (Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem -Status Normal) -count 2) | 
Foreach-Object {
    Set-DbaDbQueryStoreOption -SqlInstance $_.SqlInstance -Database $_.Name -State Off -Confirm:$false
}

# run full backups
#TODO: figure out less backups
$null = Backup-DbaDatabase -SqlInstance dbatools1 -Type Full 
$null = Backup-DbaDatabase -SqlInstance dbatools1 -Type Diff 
$null = Backup-DbaDatabase -SqlInstance dbatools1 -Type Log
Get-DbaAgentJob -SqlInstance dbatools2 -Job 'DatabaseBackup - USER_DATABASES - FULL' | Start-DbaAgentJob -Confirm:$false
Get-DbaAgentJob -SqlInstance dbatools2 -Job 'DatabaseBackup - USER_DATABASES - LOG' | Start-DbaAgentJob -Confirm:$false
Get-DbaAgentJob -SqlInstance dbatools1,dbatools2 -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL' | Start-DbaAgentJob -Confirm:$false
# run diffs for all but 3 random databases
$total = (Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem -Status Normal | Measure-Object).Count
(Get-DbaDatabase -SqlInstance dbatools2 -ExcludeSystem -Status Normal | 
Get-Random -Count ($total-3)) |
Backup-DbaDatabase -Type Diff -Confirm:$false

# clear out web folder
Get-ChildItem -Path ./web/* | Remove-Item

# weird warning with query store
$warningPreference = 'silentlyContinue'

# add custom error log message
$null = New-DbaCustomError -SqlInstance dbatools1,dbatools2 -MessageID 70001 -Severity 16 -MessageText "Baby Dragons are called Draglets"
$null = Invoke-DbaQuery -SqlInstance dbatools1,dbatools2 -Query "RAISERROR(70001, 1, 1, 17) WITH LOG"

# we need a folder
if(-not (Test-Path web)) {
    New-Item -Path web -ItemType Directory | Out-Null
}

# FPL
# we need to figure this out...
$global:FPLToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlZmF1bHQifQ.eyJjbGllbnRfaWQiOiJiZmNiYWY2OS1hYWRlLTRjMWItOGYwMC1jMWNiOGExOTMwMzAiLCJpc3MiOiJodHRwczovL2FjY291bnQucHJlbWllcmxlYWd1ZS5jb20vYXMiLCJqdGkiOiJlNjZhOWI2OC1mNjk0LTQ1YzYtOTI5OC0zNDMyNWE1MzE3N2IiLCJpYXQiOjE3NTg1NTA5NjIsImV4cCI6MTc1ODU3OTc2MiwiYXVkIjpbImh0dHBzOi8vYXBpLnBpbmdvbmUuZXUiXSwic2NvcGUiOiJvcGVuaWQgcHJvZmlsZSBlbWFpbCIsInN1YiI6Ijc2NTA4ZmFjLWFmYmMtNDYzMC05MjZkLTc3YzJjNzYyOTM0MSIsInNpZCI6ImE2NmM1OTEwLTRiZWMtNDg2NC1iMzVhLWVhODA5ZGU3MjhiYSIsImF1dGhfdGltZSI6MTc1ODI5NTQ4MSwiYWNyIjoiMjYyY2U0YjAxZDE5ZGQ5ZDM4NWQyNmJkZGI0Mjk3YjYiLCJhdXRoZW50aWNhdG9yIjoicHdkIiwiZW52IjoiNjgzNDBkZTEtZGZiOS00MTJlLTkzN2MtMjAxNzI5ODZkMTI5Iiwib3JnIjoiM2E2ODUwMzItODMyNi00OTY5LWE3OGItY2MyOTc3NWIxM2Q2IiwicDEucmlkIjoiNzE5M2ZiOTgtM2U4Yi00NTUxLWFmMjYtMGI1YzNlNzhjOWEzIn0.fBgnCOLArDqoa0J4lID7jgtNGO0z7tltE7e67oUnEEl1ocxiSlp3vq_yt2NA6SFcNL1coPl34XFGi799hNpl_1BO0wi085aQc-qBe42_usjwnDwaOFWWHgIHYTXuzdb_WWQ7-Z1quKCk-qvWgjD0-yOkCPyZAr5msuEgS-5OSgzlpZ8Icl9PqT-d_hf15v4ykTTX4wmKOtSnZ_3G9nJ5D1hdTkrolq7CBH0Fs6uhsD0SRCSE0zBBLhHvnaqgH6QTeARi7m2Lul-hnMJZh-XCKWq0T5iAIGVs04wQsGeWXYtbTHvbEq20D9T2jD4qWjhXi3HmXWuyqUAcuo8NGVqpuQ'

<#
    # Set your credentials and team ID
    # $email = "jpomfret7@gmail.com"
    # $password = Read-Host -Prompt "Enter your password"
    # $teamId = "4156860"

    # # Create a session object
    # $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    # # Login payload
    # $payload = @{
    #     password     = $password
    #     login        = $email
    #     redirect_uri = "https://fantasy.premierleague.com/a/login"
    #     app          = "plfpl-web"
    # }

    # $body = @{
    #     password     = $password
    #     login        = $email
    # }

    # Invoke-WebRequest -Uri "https://fantasy.premierleague.com/api/v1/auth/login" `
    #     -Method POST `
    #     -Body $body

    # # Perform login (POST request)
    # Invoke-WebRequest -Uri "https://users.premierleague.com/accounts/login/" `
    #     -Method POST `
    #     -Body $payload `
    #     -WebSession $session `
    #     -AllowInsecureRedirect

#>

# This was for Azure or Fabric stuff
#Connect-AzAccount -UseDeviceAuthentication

Invoke-Pester ./demos/tests -Output Detailed
