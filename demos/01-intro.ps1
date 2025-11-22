#######################
# 1. What do we have? #
#######################

# We have dbatools!
Get-Command -Name *backup* -Module dbatools
Find-DbaCommand -Pattern backup

# help
Get-Help Get-DbaDatabase
Get-Help Get-DbaDatabase -Full
Get-Help Get-DbaDatabase -ShowWindow # <-- not in the devcontainer!

# two instances
Connect-DbaInstance -SqlInstance dbatools1, dbatools2

# some databases
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 -ExcludeSystem | 
Select-Object SqlInstance, Name, Status, RecoveryModel, SizeMB | 
Format-Table -AutoSize

# some backups
Get-DbaDbBackupHistory -SqlInstance dbatools1, dbatools2 |
Select-Object SqlInstance, Database, Type, Start, Duration, End|
Format-Table -AutoSize

# some jobs
Get-DbaAgentJob -SqlInstance dbatools1, dbatools2 |
Select-Object SqlInstance, Name, Enabled, LastRunOutcome, LastRunDate |
Format-Table -AutoSize