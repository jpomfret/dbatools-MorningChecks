    
# Get the players data
$bootstrap = Invoke-WebRequest -Uri "https://fantasy.premierleague.com/api/bootstrap-static/" `
    -Method GET `
    -WebSession $session
$players = ($bootstrap.Content | ConvertFrom-Json).elements

$teams = ($bootstrap.Content | ConvertFrom-Json).teams


# get my team info
$response = Invoke-WebRequest -Uri "https://fantasy.premierleague.com/api/my-team/4156860/" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $FPLToken" }

$picks = $response.Content | ConvertFrom-Json | select -ExpandProperty picks

$JessTeam = @()
$picks.foreach{
    $p = $_
    $player = $players | Where-Object { $_.id -eq $p.element }
    $JessTeam += [PSCustomObject]@{
        Position = $p.position
        Name     = "$($player.first_name) $($player.second_name)"
        Team     = $teams | Where-Object { $_.id -eq $player.team } | Select-Object -ExpandProperty name
        Status   = Switch ($player.status) {
            "a" { "Available" }
            "i" { "Injured" }
            "d" { "Doubtful" }
            "s" { "Suspended" }
            "n" { "Not Available" }
            default { $player.status }
        }
        News     = $player.news
    }
}

# lets build onto the body from the previous demo
if($JessTeam) {
    $body += h2 { "Jess's Team Summary" }

    $table = @{
        Object = $JessTeam
        Properties = 'Position', 'Name', 'Team', 'Status', 'News'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# refresh the summary
$summary = ul {
    li { ("Databases Not in Expected State: {0}" -f $dbState.Count) }
    li { ("Databases with Backup Issues: {0}" -f $backupIssues.Count) }
    li { ("Query Store Issues: {0}" -f $queryStoreStatus.Count) }
    li { ("Jess's Team Issues: {0}" -f ($JessTeam | Where-Object { $_.Status -ne 'Available' } | Measure-Object).Count) }
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
