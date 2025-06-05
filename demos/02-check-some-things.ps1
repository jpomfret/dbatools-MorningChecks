# Are the databases in the expected date?
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 |
Select-Object SqlInstance, Name, Status, ReadOnly | 
Format-Table -AutoSize

# Are there any databases that are not in the expected state?
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 | Where-Object { $_.status -ne 'Normal' } | 
Select-Object SqlInstance, Name, Status | Format-Table -AutoSize

# are we doing backups?
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 | 
Select-Object SqlInstance, Name, LastBackupDate, LastDiffBackup, LastLogBackup | 
Format-Table -AutoSize

# Well that was hard to see...
# I only care if
    # LastBackupDate is older than 7 days
    # LastDiffBackup is older than 1 day
    # LastLogBackup is older than 15 minutes
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 | 
Where-Object { $_.LastBackupDate -lt (Get-Date).AddDays(-7) -or $_.LastDiffBackup -lt (Get-Date).AddDays(-1) -or $_.LastLogBackup -lt (Get-Date).AddMinutes(-15) } |
Select-Object SqlInstance, Name, LastBackupDate, LastDiffBackup, LastLogBackup | 
Format-Table -AutoSize

# Is Query Store enabled on all databases?
Get-DbaDbQueryStoreOption -SqlInstance dbatools1, dbatools2 -WarningAction Ignore | 
Select-Object SqlInstance, Database, ActualState, QueryCaptureMode

# There are test functions that can be useful too
Test-DbaDbQueryStore -SqlInstance dbatools1, dbatools2 | 
Select-Object SqlInstance, Database, Name, Value, IsBestPractice

# Test ownership of databases
Test-DbaDbOwner -SqlInstance dbatools1, dbatools2 | 
Select-Object SqlInstance, Database, TargetOwner, OwnerMatch

# What about compatibility levels?
Test-DbaDbCompatibility -SqlInstance dbatools1, dbatools2 |
Where-Object { -not $_.IsEqual } |
Select-Object SqlInstance, Database, ServerLevel, DatabaseCompatibility, IsEqual
