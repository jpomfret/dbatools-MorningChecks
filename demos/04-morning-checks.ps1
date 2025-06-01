## Email details
$emailTo = 'me@jesspomfret.com','team@jesspomfret.com'
$emailFrom = 'reports@jesspomfret.com'
$emailSubject = ('Morning Checks: {0}' -f (get-date -f yyyy-MM-dd))
$smtpServer = 'smtp.server.address'

#region CSS
$css = @"
table.paleBlueRows {
    font-family: "Times New Roman", Times, serif;
    border: 1px solid #FFFFFF;
    width: 350px;
    height: 200px;
    text-align: center;
    border-collapse: collapse;
}
table.paleBlueRows td, table.paleBlueRows th {
    border: 1px solid #FFFFFF;
    padding: 3px 2px;
}
table.paleBlueRows tbody td {
    font-size: 13px;
}
table.paleBlueRows tr:nth-child(even) {
    background: #D0E4F5;
}
table.paleBlueRows thead {
    background: #0B6FA4;
    border-bottom: 5px solid #FFFFFF;
}
table.paleBlueRows thead th {
    font-size: 17px;
    font-weight: bold;
    color: #FFFFFF;
    text-align: center;
    border-left: 2px solid #FFFFFF;
}
table.paleBlueRows thead th:first-child {
    border-left: none;
}
table.paleBlueRows tfoot {
    font-size: 14px;
    font-weight: bold;
    color: #333333;
    background: #D0E4F5;
    border-top: 3px solid #444444;
}
table.paleBlueRows tfoot td {
    font-size: 14px;
}
"@
#endregion

# Get the data we want to report on

$body = $null
# Get databases that are not in the expected state
$dbState = Get-DbaDatabase -SqlInstance dbatools1, dbatools2 | Where-Object { $_.status -ne 'Normal' } 
if($dbState) {
    $body += h2 { "Databases Not in Expected State" }

    $table = @{
        Object = $dbState
        Properties = 'SqlInstance', 'Name', 'Status'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# Databases without backups
$backupIssues = Get-DbaDatabase -SqlInstance dbatools1, dbatools2 | 
Where-Object { $_.LastBackupDate -lt (Get-Date).AddDays(-7) -or $_.LastDiffBackup -lt (Get-Date).AddDays(-1) -or $_.LastLogBackup -lt (Get-Date).AddMinutes(-15) }
if($backupIssues) {
    $body += h2 { "Databases with Backup Issues" }

    $table = @{
        Object = $backupIssues
        Properties = 'SqlInstance', 'Name', 'LastBackupDate', 'LastDiffBackup', 'LastLogBackup'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}
# Query Store status
$queryStoreStatus = Get-DbaDbQueryStoreOption -SqlInstance dbatools1, dbatools2 | Where-Object { $_.ActualState -ne 'ReadWrite' } -WarningAction Ignore
if($queryStoreStatus) {
    $body += h2 { "Query Store Status" }

    $table = @{
        Object = $queryStoreStatus
        Properties = 'SqlInstance', 'Database', 'ActualState'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

$summary = ul {
    li { ("Databases Not in Expected State: {0}" -f $dbState.Count) }
    li { ("Databases with Backup Issues: {0}" -f $backupIssues.Count) }
    li { ("Query Store Issues: {0}" -f $queryStoreStatus.Count) }
}

# Now you just build the html, adding the things you care about
$html = html {
    head {
            style {
                $css
            }
    }
    body {
        h1 {("Morning Checks Report: {0}" -f (get-date -f 'yyyy-MM-dd'))}
        p {
            "This report contains the results of the morning checks performed on the SQL Server instances."
        }
        h2 { "Summary" }
        $summary
        hr
        $body
    }
}

$html  > ./web/morning-checks-report.html