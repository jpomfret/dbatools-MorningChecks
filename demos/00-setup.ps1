# run local containers
# # Check if containers already exist, only create if they don't
# if (-not (docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq 'dbatools1' })) {
#     docker run -p 2500:1433 --volume shared:/shared:z --name dbatools1 --hostname dbatools1 -d dbatools/sqlinstance
# } else {
#     Write-Host "Container dbatools1 already exists, ensuring it's running..."
#     docker start dbatools1 2>$null
# }

# if (-not (docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq 'dbatools2' })) {
#     docker run -p 2600:1433 --volume shared:/shared:z --name dbatools2 --hostname dbatools2 -d dbatools/sqlinstance2
# } else {
#     Write-Host "Container dbatools2 already exists, ensuring it's running..."
#     docker start dbatools2 2>$null
# }

# # let them start up
# Start-Sleep -Seconds 30

# $cred = New-Object System.Management.Automation.PSCredential ("sqladmin", (ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force))
# $global:mssql1 = Connect-DbaInstance -SqlInstance 'localhost,2500' -SqlCredential $cred
# $global:mssql2 = Connect-DbaInstance -SqlInstance 'localhost,2600' -SqlCredential $cred

Import-Module dbatools, pester, pshtml, MicrosoftFabricMgmt

# Set-DbaSpConfigure -SqlInstance sql1 -Name MaxServerMemory -Value 3072  # 3GB
# Set-DbaSpConfigure -SqlInstance sql2 -Name MaxServerMemory -Value 3072  # 3GB

Install-DbaMaintenanceSolution -SqlInstance sql2 -BackupLocation /shared/ -InstallJobs -AutoScheduleJobs WeeklyFull -Confirm:$false

#create 20 databases on sql2 that have taylor swift related names
$taylorSwiftDatabases = @(
    'FearlessDB',
    'RedDB',
    'Speak_Now',
    'Nineteen_Eighty_Nine',
    'Reputation',
    'LoverDB',
    'Folklore',
    'Evermore',
    'Midnights',
    'TTPD',
    'ShakeItOff',
    'BlankSpace',
    'LoveStory',
    'YouBelongWithMe',
    'AntiHero',
    'CruelSummer',
    'Wildest_Dreams',
    'Cardigan',
    'AllTooWell',
    'Enchanted'
)

foreach ($dbName in $taylorSwiftDatabases) {
    $null = New-DbaDatabase -SqlInstance sql2 -Name $dbName -Confirm:$false
}

# offline some random dbs
$null = (Get-Random (Get-DbaDatabase -SqlInstance sql2 -ExcludeSystem) -count 5) | 
Set-DbaDbState -Offline -Confirm:$false

# some random dbs should be simple recovery model
$null = (Get-Random (Get-DbaDatabase -SqlInstance sql2 -ExcludeSystem -Status Normal) -count 5) | 
Set-DbaDbRecoveryModel -RecoveryModel Simple -Confirm:$false

# some random dbs should be read only
$null = (Get-Random (Get-DbaDatabase -SqlInstance sql2 -ExcludeSystem -Status Normal) -count 2) | 
Set-DbaDbState -ReadOnly -Confirm:$false

# some random dbs should have query store disabled
$null = (Get-Random (Get-DbaDatabase -SqlInstance sql2 -ExcludeSystem -Status Normal) -count 2) | 
Foreach-Object {
    Set-DbaDbQueryStoreOption -SqlInstance $_.SqlInstance -Database $_.Name -State Off -Confirm:$false
}

# run full backups
#TODO: figure out less backups
$null = Backup-DbaDatabase -SqlInstance sql1 -Type Full 
$null = Backup-DbaDatabase -SqlInstance sql1 -Type Diff 
$null = Backup-DbaDatabase -SqlInstance sql1 -Type Log
Get-DbaAgentJob -SqlInstance sql2 -Job 'DatabaseBackup - USER_DATABASES - FULL' | Start-DbaAgentJob -Confirm:$false
Get-DbaAgentJob -SqlInstance sql2 -Job 'DatabaseBackup - USER_DATABASES - LOG' | Start-DbaAgentJob -Confirm:$false
Get-DbaAgentJob -SqlInstance sql1,sql2 -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL' | Start-DbaAgentJob -Confirm:$false
# run diffs for all but 3 random databases
$total = (Get-DbaDatabase -SqlInstance sql1 -ExcludeSystem -Status Normal | Measure-Object).Count

# (Get-DbaDatabase -SqlInstance sql1 -ExcludeSystem -Status Normal | 
# Get-Random -Count ($total-3)) |
# Backup-DbaDatabase -Type Diff -Confirm:$false

# clear out web folder
Get-ChildItem -Path ./web/* | Remove-Item

# weird warning with query store
$warningPreference = 'silentlyContinue'

# add custom error log message
$null = New-DbaCustomError -SqlInstance sql1,sql2 -MessageID 70001 -Severity 16 -MessageText "Baby Dragons are called Draglets"
$null = Invoke-DbaQuery -SqlInstance sql1,sql2 -Query "RAISERROR(70001, 1, 1, 17) WITH LOG"

# we need a folder
if(-not (Test-Path web)) {
    New-Item -Path web -ItemType Directory | Out-Null
}

# FPL
# we need to figure this out...
$global:FPLToken = '***'

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
