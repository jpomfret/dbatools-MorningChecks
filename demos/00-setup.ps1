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

Connect-AzAccount -UseDeviceAuthentication

Invoke-Pester ./demos/tests -Output Detailed
