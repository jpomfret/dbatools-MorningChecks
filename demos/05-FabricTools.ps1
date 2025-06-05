# What if I care about other things?

Import-Module FabricTools

# Let's connect to Fabric
Connect-FabricAccount

Get-FabricWorkspace -OutVariable FabWorkspaces | Format-Table


# lets build onto the body from the previous demo
$body += h2 { "Fabric Workspace Summary" }

$table = @{
    Object = $FabWorkspaces | Select-Object DisplayName, Description, @{ Name = 'HasCapacity'; Expression = { $null -ne $_.CapacityId } }
    Properties = 'displayName', 'description', 'HasCapacity'
    TableClass = 'paleBlueRows'
}
$body += ConvertTo-PSHTMLTable @table


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
