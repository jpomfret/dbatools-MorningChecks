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

Get-DbaAgentJob -SqlInstance dbatools2 -Job 'DatabaseBackup - USER_DATABASES - FULL' | Start-DbaAgentJob -Confirm:$false

# clear out web folder
Get-ChildItem -Path ./web/* | Remove-Item

Connect-AzAccount -UseDeviceAuthentication

Invoke-Pester ./demos/tests -Output Detailed
