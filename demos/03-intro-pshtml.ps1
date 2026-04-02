######################
# 3. Intro to PSHTML #
######################

Import-Module PSHTML

# Commands available
Get-Command -Module PSHTML

# DSL - Domain Specific Language
# Functions that don't look like PowerShell named commands
# PowerShell functions are normally Verb-Noun
# PSHTML uses just nouns for HTML elements

# Let's create a simple heading
h1 -Content 'Hi Birmingham UG Friends!'

# We can also create a simple paragraph
p -Content 'This is a simple paragraph'

# Let's combine these and create a simple HTML page

# Create a new HTML page
$html = html {
    head {
            title 'My First PSHTML Page'
    }
    body {
            h1 -Content 'Hi Birmingham UG Friends!'
            p -Content 'This is a simple paragraph'
    }
}
$html | Out-File -FilePath .\web\simplePage.html

code ./web/simplePage.html
# open, format, preview

Start-Process ./web/simplePage.html

##########
# Tables #
##########

# we can also use PSHTML to easily create tables

# I wrote '$data =' ... copilot did the rest and is 100% correct
$data = @(
    [PSCustomObject]@{
            Name = 'Jess'
            Age = 30
            Location = 'UK'
    }
    [PSCustomObject]@{
            Name = 'Rob'
            Age = 31
            Location = 'UK'
    }
    [PSCustomObject]@{
            Name = 'Chrissy'
            Age = 29
            Location = 'UK'
    }
)
$data

ConvertTo-PSHTMLTable -Object $data | Out-File ./web/table.html

code ./web/table.html
# open, format, preview

Start-Process ./web/table.html

# but it's still not really beautiful - add some CSS
# but I don't know CSS, and I have no style... - https://divtable.com/table-styler/
# you can also talk to our AI friends and create a prompt for the CSS you want
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

$html = html {
    head {
        style {
            $css
            }
        }
    body {
        h1 {"Beautiful Table Report: {0}" -f (Get-Date -f 'yyyy-MM-dd')}
        ConvertTo-PSHTMLTable -Object $data -TableClass paleBlueRows
    }
}
$html | Out-File .\web\table.html

code ./web/table.html
# open, format, preview

Start-Process ./web/table.html

# and you can get data from anywhere - any PSObject

$sqlInstance = 'sql1'
$database = 'AdventureWorks2022'
$query = @"
SELECT TOP (10) [ProductID]
      ,[Name]
      ,[ProductNumber]
      ,[MakeFlag]
  FROM [Production].[Product]
"@

$querySplat = @{
    SqlInstance     = $sqlInstance
    Database        = $database
    Query           = $query
    EnableException = $true
}
$results = Invoke-DbaQuery @querySplat

# view the results:

$results

# lets edit our html from before

$html = html {
    head {
        style {
            $css
        }
    }
    body {
    h1 {"Beautiful Table Report: {0}" -f (Get-Date -f 'yyyy-MM-dd')}}
    h2 {"Data from CoPilot's PSObject"}
    ConvertTo-PSHTMLTable -Object $data -TableClass paleBlueRows

    h2 {"Data from SQL Server"}
    ConvertTo-PSHTMLTable -Object $results -TableClass paleBlueRows
}
$html | Out-File .\web\table.html

code ./web/table.html
# open, format, preview

Start-Process ./web/table.html

##########
# Charts #
##########

# And finally, we can also create charts!
# Pulling in Chart.js library

$html = html {
    head {
        # pull in Chart.js library
        script -src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min.js" -type "text/javascript"
    }
    body {
        h1 {"Pie Chart!"}
        p { "Who doesn't love pie charts?" }
        canvas -Height 400px -Width 400px -Id "PieCanvas" {
        }
        
        script -content {
            $data = @(34,7,11,19)
            $labels = @("Closed","Unresolved","Pending","Open")
            $colours = @("LightGreen","red","Blue","Yellow")

            $dsb1 = New-PSHTMLChartPieDataSet -Data $data  -BackgroundColor $colours
            New-PSHTMLChart -type Pie -DataSet $dsb1 -title "Ticket Statistics" -Labels $labels -CanvasID PieCanvas
        }
    }
}


$html | Out-File .\web\pie.html
code ./web/pie.html
# open, format, preview
# preview doesn't work in the devcontainer - open in browser

Start-Process ./web/pie.html

# PSHTML is super powerful - go explore the docs!
# https://pshtml.readthedocs.io/en/latest/