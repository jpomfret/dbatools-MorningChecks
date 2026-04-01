############################
# 2. PowerShell 💜 Fabric #
############################

Import-Module MicrosoftFabricMgmt

# Auth
Set-FabricApiHeaders -TenantId ***

# Get Workspaces
Get-FabricWorkspace

# Get Workspaces that are missing a capacity
Get-FabricWorkspace | Where-Object {-not $_.capacityId }

# What about trial capacities
Get-FabricCapacity | Where-Object {$_.SKU -eq 'FT1' -and $_.DisplayName -like 'Trial*' }

# Get Pipelines
Get-FabricDataPipeline -WorkspaceId f751f926-1ef6-4cd2-bcbd-75f42250b353

# or ... because no-one likes guids ... WE HAVE PIPING!
Get-FabricWorkspace -WorkspaceName 'Beta' | Get-FabricDataPipeline

# We could also look for pipelines with missing descriptions
Get-FabricWorkspace | Get-FabricDataPipeline | Where-Object {-not $_.description }

# We could also look for any items with missing descriptions
Get-FabricWorkspace | Get-FabricItem | Where-Object {-not $_.description } | 
Select-Object WorkspaceId, DisplayName, Type

## If there are things you want to check - add them to your morning checks report!

# Fabric Workspaces without Capacity
$fabWs = Get-FabricWorkspace | Where-Object {-not $_.capacityId }
if($fabWs) {
    $body += h2 { "Fabric Workspaces without Capacity" }

    $table = @{
        Object = $fabWs
        Properties = 'WorkspaceId', 'DisplayName', 'Type'
        TableClass = 'paleBlueRows'
    }
    $body += ConvertTo-PSHTMLTable @table
}

# Fabric items without descriptions
$fabItems = Get-FabricWorkspace | Get-FabricItem | Where-Object {-not
    $_.description } | Select-Object WorkspaceId, DisplayName, Type
if($fabItems) {
    $body += h2 { "Fabric Items without Descriptions" }

    $table = @{
        Object = $fabItems
        Properties = 'WorkspaceId', 'DisplayName', 'Type'
        TableClass = 'paleBlueRows'
    }   
    $body += ConvertTo-PSHTMLTable @table
}

$summary = ul {
    li { ("Databases Not in Expected State: {0}" -f $dbState.Count) }
    li { ("Databases with Backup Issues: {0}" -f $backupIssues.Count) }
    li { ("Error Log Messages: {0}" -f $errorLogMsgs.Count) }
    li { ("Query Store Issues: {0}" -f $queryStoreStatus.Count) }
    li { ("Fabric Workspaces without Capacity: {0}" -f $fabWs.Count) }
    li { ("Fabric Items without Descriptions: {0}" -f $fabItems.Count) }
}

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
                    li { $_.DomainInstanceName }
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