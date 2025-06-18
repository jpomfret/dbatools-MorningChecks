# What if I care about other things?

Import-Module FabricTools

# Let's connect to Fabric
Connect-FabricAccount

# Let's get some workspaces
Get-FabricWorkspace | Format-Table

# Alright, I want to make sure we have descriptions
$fabWorkspaces = Get-FabricWorkspace | Where-Object {-not $_.description}

# lets build onto the body from the previous demo
if($fabWorkspaces) {
    $body += h2 { "Fabric Workspace Summary" }
    
    $table = @{
        Object = $FabWorkspaces | Select-Object DisplayName, Description, @{ Name = 'HasCapacity'; Expression = { $null -ne $_.CapacityId } }
        Properties = 'displayName', 'description', 'HasCapacity'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# refresh the summary
$summary = ul {
    li { ("Databases Not in Expected State: {0}" -f $dbState.Count) }
    li { ("Databases with Backup Issues: {0}" -f $backupIssues.Count) }
    li { ("Query Store Issues: {0}" -f $queryStoreStatus.Count) }
    li { ("Fabric Workspaces without Descriptions: {0}" -f $fabWorkspaces.Count) }
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
