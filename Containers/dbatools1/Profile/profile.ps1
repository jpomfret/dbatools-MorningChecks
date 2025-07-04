$containers = $SQLInstances = $dbatools1, $dbatools2 = 'dbatools1', 'dbatools2'

#region Set up connection
$securePassword = ('dbatools.IO' | ConvertTo-SecureString -AsPlainText -Force)
$containerCredential = New-Object System.Management.Automation.PSCredential('sqladmin', $securePassword)

$Global:PSDefaultParameterValues = @{
    "*dba*:SqlCredential"            = $containerCredential
    "*dba*:SourceSqlCredential"      = $containerCredential
    "*dba*:DestinationSqlCredential" = $containerCredential
    "*dba*:DestinationCredential"    = $containerCredential
    "*dba*:PrimarySqlCredential"     = $containerCredential
    "*dba*:SecondarySqlCredential"   = $containerCredential
}
#endregion

#region Clean up
Remove-Item '/var/opt/backups/dbatools1' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item '/shared' -Recurse -Force -ErrorAction SilentlyContinue
#endregion

Import-Module Pansies

#region POSH-GIT
# with props to https://bradwilson.io/blog/prompt/powershell
# ... Import-Module for posh-git here ...
Import-Module posh-git
Import-Module dbatools
Import-Module dbachecks
Import-Module ImportExcel

# first time it runs it warns about the libraries
$test | Export-Excel -Path .\export\test.xlsx -WarningVariable warn


$ShowError = $false
$ShowKube = $false
$ShowAzure = $false
$ShowAzureCli = $false
$ShowGit = $false
$ShowPath = $false
$ShowDate = $false
$ShowTime = $true
$ShowUser = $false

# Background colors

$GitPromptSettings.AfterStash.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.AfterStatus.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BeforeIndex.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BeforeStash.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BeforeStatus.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchAheadStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchBehindStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchColor.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchGoneStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.BranchIdenticalStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.DefaultColor.BackgroundColor = [ConsoleColor]::DarkCyan
$GitPromptSettings.DelimStatus.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.ErrorColor.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.IndexColor.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.LocalDefaultStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.LocalStagedStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.LocalWorkingStatusSymbol.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.StashColor.BackgroundColor = [ConsoleColor]::LightGray
$GitPromptSettings.WorkingColor.BackgroundColor = [ConsoleColor]::LightGray

# Foreground colors

$GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::White
$GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.DefaultColor.ForegroundColor = [ConsoleColor]::White
$GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.IndexColor.ForegroundColor = [ConsoleColor]::Cyan
$GitPromptSettings.WorkingColor.ForegroundColor = [ConsoleColor]::Yellow
$GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = [ConsoleColor]::Black
$GitPromptSettings.LocalWorkingStatusSymbol.ForegroundColor = [ConsoleColor]::Black
# Prompt shape

$GitPromptSettings.AfterStatus.Text = " "
$GitPromptSettings.BeforeStatus.Text = "  "
$GitPromptSettings.BranchAheadStatusSymbol.Text = " "
$GitPromptSettings.BranchBehindStatusSymbol.Text = " "
$GitPromptSettings.BranchGoneStatusSymbol.Text = ""
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.Text = ""
$GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
$GitPromptSettings.BranchUntrackedText = ""
$GitPromptSettings.DelimStatus.Text = " ॥"

$GitPromptSettings.EnableStashStatus = $false
$GitPromptSettings.ShowStatusWhenZero = $false

######## PROMPT
Set-Content Function:prompt {
    if ($ShowDate) {
        Write-Host " $(Get-Date -Format "ddd dd MMM HH:mm:ss")" -ForegroundColor Black -BackgroundColor LightGray -NoNewline
    }

    # Reset the foreground color to default
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultColor.ForegroundColor

    if ($ShowUser) {
        Write-Host " " -NoNewline
        Write-Host "  " -NoNewline -BackgroundColor DarkYellow -ForegroundColor Black
        Write-Host  (whoami)  -NoNewline -BackgroundColor DarkYellow -ForegroundColor Black
    }
    # Write ERR for any PowerShell errors
    if ($ShowError) {
        if ($Error.Count -ne 0) {
            Write-Host " " -NoNewline
            Write-Host " $($Error.Count) ERR " -NoNewline -BackgroundColor DarkRed -ForegroundColor Yellow
            # $Error.Clear()
        }
    }

    # Write non-zero exit code from last launched process
    if ($LASTEXITCODE -ne "") {
        Write-Host " " -NoNewline
        Write-Host " x $LASTEXITCODE " -NoNewline -BackgroundColor DarkRed -ForegroundColor Yellow
        $LASTEXITCODE = ""
    }

    if ($ShowKube) {
        # Write the current kubectl context
        if ((Get-Command "kubectl" -ErrorAction Ignore) -ne $null) {
            $currentContext = (& kubectl config current-context 2> $null)
            $nodes = kubectl get nodes -o json | ConvertFrom-Json

            $nodename = ($nodes.items.metadata | where labels  -Like '*master*').name
            Write-Host " " -NoNewline
            Write-Host "" -NoNewline -BackgroundColor LightGray -ForegroundColor Green
            #Write-Host " $currentContext " -NoNewLine -BackgroundColor DarkYellow -ForegroundColor Black
            Write-Host " $([char]27)[38;5;112;48;5;242m  $([char]27)[38;5;254m$currentContext - $nodename $([char]27)[0m" -NoNewline
        }
    }

    if ($ShowAzureCli) {
        # Write the current public cloud Azure CLI subscription
        # NOTE: You will need sed from somewhere (for example, from Git for Windows)
        if (Test-Path ~/.azure/clouds.config) {
            if ((Get-Command "sed" -ErrorAction Ignore) -ne $null) {
                $currentSub = & sed -nr "/^\[AzureCloud\]/ { :l /^subscription[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.azure/clouds.config
            } else {
                $file = Get-Content ~/.azure/clouds.config
                $currentSub = ([regex]::Matches($file, '^.*subscription\s=\s(.*)').Groups[1].Value).Trim()
            }
            if ($null -ne $currentSub) {
                $currentAccount = (Get-Content ~/.azure/azureProfile.json | ConvertFrom-Json).subscriptions | Where-Object { $_.id -eq $currentSub }
                if ($null -ne $currentAccount) {
                    Write-Host " " -NoNewline
                    Write-Host "" -NoNewline -BackgroundColor DarkCyan -ForegroundColor Yellow
                    $currentAccountName = ($currentAccount.Name.Split(' ') | foreach { $_[0..5] -join '' }) -join ' '
                    Write-Host "$([char]27)[38;5;227;48;5;30m  $([char]27)[38;5;254m$($currentAccount.name) $([char]27)[0m"  -NoNewline -BackgroundColor DarkBlue -ForegroundColor Yellow
                }
            }
        }
    }

    if ($ShowAzure) {
        $context = Get-AzContext
        Write-Host "$([char]27)[38;5;227;48;5;30m  $([char]27)[38;5;254m$($context.Account.Id) in $($context.subscription.name) $([char]27)[0m"  -NoNewline -BackgroundColor DarkBlue -ForegroundColor Yellow
    }
    if ($ShowGit) {
        # Write the current Git information
        if ((Get-Command "Get-GitDirectory" -ErrorAction Ignore) -ne $null) {
            if (Get-GitDirectory -ne $null) {
                Write-Host (Write-VcsStatus) -NoNewline
            }
        }
    }

    if ($ShowPath) {
        # Write the current directory, with home folder normalized to ~
        # $currentPath = (get-location).Path.replace($home, "~")
        # $idx = $currentPath.IndexOf("::")
        # if ($idx -gt -1) { $currentPath = $currentPath.Substring($idx + 2) }
        if ($IsLinux) {
            $currentPath = $($pwd.path.Split('/')[-2..-1] -join '/')
        } else {
            $currentPath = $($pwd.path.Split('\')[-2..-1] -join '\')
        }
        Write-Host " " -NoNewline
        Write-Host "$([char]27)[38;5;227;48;5;28m  $([char]27)[38;5;254m$currentPath $([char]27)[0m " -NoNewline -BackgroundColor DarkGreen -ForegroundColor LightGray

    }
    # Reset LASTEXITCODE so we don't show it over and over again
    $global:LASTEXITCODE = 0

    if ($ShowTime) {
        try {
            Write-Host " " -NoNewline
            $history = Get-History -ErrorAction Ignore
            if ($history) {
                if (([System.Management.Automation.PSTypeName]'Sqlcollaborative.Dbatools.Utility.DbaTimeSpanPretty').Type) {
                    $timemessage = " " + ( [Sqlcollaborative.Dbatools.Utility.DbaTimeSpanPretty]($history[-1].EndExecutionTime - $history[-1].StartExecutionTime))
                    Write-Host $timemessage -ForegroundColor DarkYellow -BackgroundColor LightGray -NoNewline
                } else {
                    Write-Host " $([Math]::Round(($history[-1].EndExecutionTime - $history[-1].StartExecutionTime).TotalMilliseconds,2))" -ForegroundColor DarkYellow -BackgroundColor LightGray  -NoNewline
                }
            }
            Write-Host " " -ForegroundColor DarkBlue -NoNewline
        } catch { }
    }
    # Write one + for each level of the pushd stack
    if ((Get-Location -Stack).Count -gt 0) {
        Write-Host " " -NoNewline
        Write-Host (("+" * ((Get-Location -Stack).Count))) -NoNewline -ForegroundColor Cyan
    }

    # Determine if the user is admin, so we color the prompt green or red
    $isAdmin = $false
    $isDesktop = ($PSVersionTable.PSEdition -eq "Desktop")

    if ($isDesktop -or $IsWindows) {
        $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $windowsPrincipal = New-Object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
        $isAdmin = $windowsPrincipal.IsInRole("Administrators") -eq 1
    } else {
        $isAdmin = ((& id -u) -eq 0)
    }

    if ($isAdmin) { $color = $color = "`e[38;5;9;48;5;237m"; }
    else { $color = "`e[38;5;231;48;5;27m "; }


    # Write PS> for desktop PowerShell, pwsh> for PowerShell Core
    if ($isDesktop) {
        Write-Host " PS5>" -NoNewline -ForegroundColor $color
    } else {
        $version = $PSVersionTable.PSVersion.ToString()
        #Write-Host " pwsh $Version>" -NoNewLine -ForegroundColor $color
        Write-Host "$($color)pwsh $Version>" -NoNewline
    }

    # Always have to return something or else we get the default prompt
    return " "
}
#endregion 

# clear out the export folder
Get-ChildItem ./Export/ | Remove-item -Recurse
