# dbatools-MorningChecks
A repo for a presentation about creating a morning checks report with dbatools

## Description
There’s often a few things we like to check on every morning with our first cup of coffee\tea\juice. Depending on your role this list might be different – but with this session I’ll teach you how to automate a list of checks, and have them auto-magically delivered to your inbox every day.

In this session I will show you my standard morning checks as a DBA, checking for the following with dbatools.

- Any databases missing backups?
- Any jobs (or job steps) that have failed overnight?
- Any worrying messages in the error log?
- Any disks about to run out of space?
- And many more…

I’ll then generate a beautiful HTML email and status page that shows you the results, and highlights any issues that you should work on first.

This session will give you the structure needed to check anything that you can write a script for, the possibilities are as wide as your imagination.

Join me as we automate our morning checklists.

We recommend downloading the repo and getting the local demo environment setup on your laptop. This way you can follow along with the demos.

## DevContainer

### Prerequisites:

- [Docker](https://www.docker.com/get-started)
- [git](https://git-scm.com/downloads)
- [VSCode](https://code.visualstudio.com/download)
- [`Remote Development` Extension for VSCode](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

### Setup

1. Download the repo from GitHub
    ```PowerShell
    # change directory to where you'd like the repo to go
    cd C:\GitHub\

    # clone the repo from GitHub
    git clone https://github.com/jpomfret/dbatools-MorningChecks

    # move into the folder
    cd .\dbatools-MorningChecks

    # open VSCode
    code .
    ```

1. Once code opens, there should be a toast in the bottom right that suggests you 'ReOpen in Container'.
1. The first time you do this it may take a little, and you'll need an internet connection, as it'll download the container images used in our demos
1. Open a pwsh console and start your adventure... (Note it is better in a vanilla pwsh session than in the Integrated Terminal)

### Rebuild

Only way to properly rebuild to ensure that all volumes etc are removed is to

cd to .devcontainer in a diff window

`docker-compose -f "docker-compose.yml" -p "dbatools-morningchecks_devcontainer" down`