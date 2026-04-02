#####################
# 4. Morning Checks #
#####################

## Email details
$emailTo = 'me@jesspomfret.com','team@jesspomfret.com'
$emailFrom = 'reports@jesspomfret.com'
$emailSubject = ('Morning Checks: {0}' -f (get-date -f yyyy-MM-dd))
$smtpServer = 'smtp.server.address'

# Which instances to test?
$instances = 'sql1', 'sql2'
# $instances = Import-Csv .\instances.csv
# $instance = Get-DbaRegServer

#region CSS
$css = @"
table.paleBlueRows {
    border: 1px solid #FFFFFF;
    height: 200px;
    text-align: center;
    border-collapse: collapse;
}
table.paleBlueRows td, table.paleBlueRows th {
    border: 1px solid #FFFFFF;
    padding: 4px 10px;
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

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

.container {
    display: flex;
    gap: 20px;
    width: 50%;
    margin: 0;
    padding: 20px;
}

.bullet-section {
    flex: 1;
    min-width: 250px;
}

.chart-section {
    flex: 1;
    min-width: 300px;
    display: flex;
    justify-content: center;
    align-items: center;
}

.chart-section canvas {
    max-width: 100%;
    height: auto;
}

h1 {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #0B6FA4;
    font-size: 28px;
    margin-bottom: 10px;
}

h2 {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #0B6FA4;
    font-size: 24px;
    margin-bottom: 10px;
}

p {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    line-height: 1.6;
    color: #333;
}

ul {
    list-style-type: none;
    padding-left: 0;
    margin: 10px 0;
}

ul li {
    padding-left: 28px;
    position: relative;
    font-size: 13px;
    margin-bottom: 8px;
}

ul li::before {
    content: "▸";
    position: absolute;
    left: 0;
    color: #0B6FA4;
    font-size: 18px;
    font-weight: bold;
}

hr {
    border: none;
    height: 2px;
    background: linear-gradient(to right, #0B6FA4, #D0E4F5, transparent);
    margin: 30px 0;
}

/* Responsive design for smaller screens */
@media (max-width: 768px) {
    .container {
        flex-direction: column;
    }
    
    .bullet-section,
    .chart-section {
        width: 100%;
    }
}
"@
#endregion

# Get the data we want to report on

$body = $null
# Get databases that are not in the expected state
$dbState = Get-DbaDatabase -SqlInstance $instances | Where-Object { $_.status -ne 'Normal' } 
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
$backupIssues = Get-DbaDatabase -SqlInstance $instances -Database msdb,master,model |
Where-Object { $_.LastBackupDate -lt (Get-Date).AddDays(-1) }

$backupIssues += Get-DbaDatabase -SqlInstance $instances -ExcludeSystem |
Where-Object { $_.LastBackupDate -lt (Get-Date).AddDays(-7) -or $_.LastDiffBackup -lt (Get-Date).AddDays(-1) -or ($_.RecoveryModel -eq 'Full' -and $_.LastLogBackup -lt (Get-Date).AddMinutes(-15)) }

if($backupIssues) {
    $body += h2 { "Databases with Backup Issues" }

    $table = @{
        Object = $backupIssues
        Properties = 'SqlInstance', 'Name', 'LastBackupDate', 'LastDiffBackup', 'LastLogBackup'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# Error Log messages
$errorLogMsgs = Get-DbaErrorLog -SqlInstance $instances -LogNumber 0, 1 -After (get-date).AddDays(-1) | 
Where-object { 
        ($_.text  -like '*failed*') `
    -or ($_.text  -like '*unable*') `
    -or ($_.text  -like '*exception*') `
    -or ($_.text  -like '*dragon*')`
    -or ($_.text  -like '*critical*') 
    } | Select-Object SqlInstance, LogDate, text

if($errorLogMsgs) {
    $body += h2 { "Error Log Messages" }
    $table = @{
        Object = $errorLogMsgs
        Properties = 'SqlInstance', 'LogDate', 'text'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# Query Store status
$queryStoreStatus = Get-DbaDbQueryStoreOption -SqlInstance $instances | 
Where-Object { $_.ActualState -ne 'ReadWrite' } -WarningAction Ignore
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
    li { ("Error Log Messages: {0}" -f $errorLogMsgs.Count) }
    li { ("Query Store Issues: {0}" -f $queryStoreStatus.Count) }
}

# list of pshtml colours for us to play with
$colours = 'aliceblue','antiquewhite','aqua','aquamarine','azure','beige','bisque','black','blanchedalmond','blue','blueviolet','brown','burlywood','cadetblue','chartreuse','chocolate','coral','cornflowerblue','cornsilk','crimson','cyan','darkblue','darkcyan','darkgoldenrod','darkgray','darkgreen','darkgrey','darkkhaki','darkmagenta','darkolivegreen','darkorange','darkorchid','darkred','darksalmon','darkseagreen','darkslateblue','darkslategray','darkslategrey','darkturquoise','darkviolet','deeppink','deepskyblue','dimgray','dimgrey','dodgerblue','firebrick','floralwhite','forestgreen','fuchsia','gainsboro','ghostwhite','gold','goldenrod','gray','green','greenyellow','grey','honeydew','hotpink','indianred','indigo','ivory','khaki','lavender','lavenderblush','lawngreen','lemonchiffon','lightblue','lightcoral','lightcyan','lightgoldenrodyellow','lightgray','lightgreen','lightgrey','lightpink','lightsalmon','lightseagreen','lightskyblue','lightslategray','lightslategrey','lightsteelblue','lightyellow','lime','limegreen','linen','magenta','maroon','mediumaquamarine','mediumblue','mediumorchid','mediumpurple','mediumseagreen','mediumslateblue','mediumspringgreen','mediumturquoise','mediumvioletred','midnightblue','mintcream','mistyrose','moccasin','navajowhite','navy','oldlace','olive','olivedrab','orange','orangered','orchid','palegoldenrod','palegreen','paleturquoise','palevioletred','papayawhip','peachpuff','peru','pink','plum','powderblue','purple','red','rosybrown','royalblue','saddlebrown','salmon','sandybrown','seagreen','seashell','sienna','silver','skyblue','slateblue','slategray','slategrey','snow','springgreen','steelblue','tan','teal','thistle','tomato','turquoise','violet','wheat','white','whitesmoke','yellow','yellowgreen'

# Let's build the chart data dynamically
# Null-coalescing operator ??
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.5#null-coalescing-operator-

$labels = @('Db State','Backups','Logs', 'Query Store')
$dsb1 = @() 
$instances.foreach{
    $data = @(
        (($dbstate | Group-Object SqlInstance | Where-Object name -eq $_ | Select-Object -expand count) ?? 0),
        (($backupIssues | Group-Object SqlInstance | Where-Object name -eq $_ | Select-Object -expand count) ?? 0),
        (($errorLogMsgs | Group-Object SqlInstance | Where-Object name -eq $_ | Select-Object -expand count) ?? 0),
        (($queryStoreStatus  | Group-Object SqlInstance | Where-Object name -eq $_ | Select-Object -expand count) ?? 0)
        )
    $dsb1 += New-PSHTMLChartBarDataSet -Data $data -label $_ -BackgroundColor (get-pshtmlColor -color (Get-Random $colours))  
}

$graph = New-PSHTMLChart -type bar -DataSet $dsb1 -title "Morning Checks Summary" -Labels $Labels -CanvasID BarCanvasID

# Now you just build the html
$html = html {
    head {
        style {
            $css
        }
        script -src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min.js" -type "text/javascript"

    }
    body {
        h1 {("Morning Checks Report: {0}" -f (get-date -f 'yyyy-MM-dd'))}
        p {
            "This report contains the results of the morning checks performed on the SQL Server instances."
            ul {
                $instances.ForEach{
                    li { $_ }
                }
            }
        }
        hr
        h2 { "Summary" }
        div -class "container" {
            div -class "bullet-section" {
                $summary
            }
            div -class "chart-section" {
                canvas -Height 400px -Width 400px -Id BarCanvasID {
                }

                script -content {
                        $graph
                }
            }
        }
        hr
        $body
    }
}

$html  > ./web/morning-checks-report.html

Start-Process ./web/morning-checks-report.html
