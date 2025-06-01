# What do we have?

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