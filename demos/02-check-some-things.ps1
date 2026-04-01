########################
# 2. Check some things #
########################

# Are the databases in the expected state?
Get-DbaDatabase -SqlInstance sql1, sql2 |
Select-Object SqlInstance, Name, Status, ReadOnly | 
Format-Table -AutoSize

# Are there any databases that are not in the expected state?
# not normal
Get-DbaDatabase -SqlInstance sql1, sql2 | 
Where-Object { $_.status -ne 'Normal' } | 
Select-Object SqlInstance, Name, Status | 
Format-Table -AutoSize

# Are there any databases that are not in the expected state?
# not normal or read-only
Get-DbaDatabase -SqlInstance sql1, sql2 | 
Where-Object { $_.status -ne 'Normal' -or $_.ReadOnly } | 
Select-Object SqlInstance, Name, Status, ReadOnly | 
Format-Table -AutoSize

# are we doing backups?
Get-DbaDatabase -SqlInstance sql1, sql2 | 
Select-Object SqlInstance, Name, LastBackupDate, LastDiffBackup, LastLogBackup | 
Format-Table -AutoSize

# Well that was hard to see...
# I only care if
    # LastBackupDate is older than 7 days
    # LastDiffBackup is older than 1 day
    # LastLogBackup is older than 15 minutes - if database is in FULL recovery model
Get-DbaDatabase -SqlInstance sql1, sql2 -ExcludeDatabase tempdb | 
Where-Object { `
        $_.LastBackupDate -lt (Get-Date).AddDays(-7)  `
    -or $_.LastDiffBackup -lt (Get-Date).AddDays(-1)  `
    -or ( `
        $_.RecoveryModel -eq 'Full' `
        -and $_.LastLogBackup -lt (Get-Date).AddMinutes(-15) `
        ) `
} |
Select-Object SqlInstance, Name, RecoveryModel, LastBackupDate, LastDiffBackup, LastLogBackup | 
Format-Table -AutoSize

# Is Query Store enabled on all databases?
Get-DbaDbQueryStoreOption -SqlInstance sql1, sql2 -WarningAction Ignore | 
Select-Object SqlInstance, Database, ActualState, QueryCaptureMode

# There are test functions that can be useful too
Test-DbaDbQueryStore -SqlInstance sql1, sql2 | 
Select-Object SqlInstance, Database, Name, Value, IsBestPractice

# Test ownership of databases
Test-DbaDbOwner -SqlInstance sql1, sql2 | 
Select-Object SqlInstance, Database, CurrentOwner, TargetOwner, OwnerMatch |
Format-Table -AutoSize

# What about compatibility levels?
Test-DbaDbCompatibility -SqlInstance sql1, sql2 |
Where-Object { -not $_.IsEqual } |
Select-Object SqlInstance, Database, ServerLevel, DatabaseCompatibility, IsEqual

# There is so much more you can get and test with dbatools!
# go explore the new command website:
Start-Process "https://dbatools.io/commands"
