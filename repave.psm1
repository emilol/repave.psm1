function Invoke-Repave($script) {
    if (-not (Test-Administrator)) {
        Write-Error "Re-open in admin mode`r`n"
        exit 1
    }
    Start-Script
    try
    {
        mkdir Installers -ErrorAction SilentlyContinue | Out-Null
        $inTranscript = $Host.Name -ne "Windows PowerShell ISE Host"
        if ($inTranscript) {
            Start-Transcript -path "repave.log" -append
        } else {
            Write-Warning "This is being executed from PowerShell ISE so there is no transcript at install.log`r`n"
        }

        Install-Chocolatey

        &$script

        $temp = [IO.Path]::GetTempPath()
        Add-Todo "Clear out $temp"

        if ($InTranscript) {
            Stop-Transcript
        }
    } catch {
        $Host.UI.WriteErrorLine($_)
        Write-Output "`r`n"
        if ($InTranscript) {
            Stop-Transcript
        }
        exit 1
    }
}

function Start-Script() {
    # http://blogs.msdn.com/b/powershell/archive/2007/06/19/get-scriptdirectory.aspx
    $invocation = (Get-variable -Name MyInvocation -Scope 2).Value
    $scriptpath = Split-Path $invocation.MyCommand.Path;
    Set-Variable -Name scriptpath -Value $scriptpath -Scope Global
    Invoke-Expression "cd $scriptpath"

    # Stop on errors
    Set-Variable -Name ErrorActionPreference -Value "stop" -Scope Global
}

function Install-Chocolatey() {
    try {
        (iex "clist -lo") -Replace "^Reading environment variables.+$","" | Set-Variable -Name "installedPackages" -Scope Global
        Write-Output "choco install already installed with the following packages:`r`n"
        Write-Output $global:installedPackages
        Write-Output "`r`n"
    }
    catch {
        Write-Output "Installing Chocolatey`r`n"
        iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
        Add-ToPath "c:\chocolatey\bin"
        Write-Warning "If the next command fails then restart powershell and run the script again to update the path variables properly`r`n"
    }
}

function Get-SourcePath() {
    return (Get-variable -Name scriptpath -Scope Global).Value
}
function Test-Administrator() {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Test-VirtualMachine() {
    $objWMI = Get-WmiObject Win32_BaseBoard
    return ($objWMI.Manufacturer.Tolower() -match 'microsoft') -or ($objWMI.Manufacturer.Tolower() -match 'vmware')
}

function Set-AdvancedWindowsExplorerOptions() {
    Set-ShowHiddenFiles
    Set-FullContextMenus
    Set-DisableBingSearchResults
}

function Set-ShowHiddenFiles {
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    if (($key | Get-ItemProperty -Name "Hidden").Hidden -ne 1) {
        Set-ItemProperty $key Hidden 1
        Set-ItemProperty $key HideFileExt 0
        Set-ItemProperty $key ShowSuperHidden 1
        Stop-Process -processname explorer
    }
}

function Set-FullContextMenus {
    $key = "HKCU:\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (Test-Path $key) {
        write-host 'Context menus already set'
    } else {
        New-ItemProperty -Path $key -Value ””  -PropertyType "String"
    }
}

function Set-DisableBingSearchResults {
    $key = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    if (Test-Path $key) {
        if (($key | Get-ItemProperty -Name "DisableSearchBoxSuggestions").DisableSearchBoxSuggestions -ne 1) {
            Set-ItemProperty $key DisableSearchBoxSuggestions 1
        } else {
            write-host 'Bing search results already disabled'
        }
    } else {
        New-ItemProperty -Path $key -Name "DisableSearchBoxSuggestions" -Value 1  -PropertyType "DWORD"
    }
}

function Install-Git {
    Install-ChocolateyPackage git
    Add-ToPath "C:\Program Files (x86)\Git\bin"
    
    if ((Test-Path ".ssh") -and (-not (Test-Path "~\.ssh"))) {
        Write-Output "Copying .ssh to ~`r`n"
        cp .ssh $env:userprofile -Recurse
    }
}

function Copy-GitConfig($workFolder) {
    if ((Test-Path ".gitconfig") -and (-not (Test-Path "~\.gitconfig"))) {
        Write-Output "Copying .gitconfig to ~`r`n"
        cp .gitconfig $env:userprofile -Recurse
    }
    if ((Test-Path "Configurations/.gitconfig.work") -and (-not (Test-Path "$workFolder.gitconfig"))) {
        cp .gitconfig.work "$workFolder.gitconfig" -Recurse
    }
}

function Install-Wsl2() {
    if (-not (Check-WindowsFeature Microsoft-Windows-Subsystem-Linux)) {
        choco install Microsoft-Windows-Subsystem-Linux -Source WindowsFeatures | Out-Default
        choco install VirtualMachinePlatform  -Source WindowsFeatures | Out-Default
        wsl --set-default-version 2
    }
    Install-ChocolateyPackage wsl-ubuntu-2004
}

function Check-WindowsFeature {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)] [string]$FeatureName 
    )  
    return (Get-WindowsOptionalFeature -FeatureName $FeatureName -Online).State -eq "Enabled"
}

function Add-ToPath($path) {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    if ($env:PATH.indexOf($path) -eq -1) {
        Write-Output "Updating PATH to include $path`r`n"
        setx PATH "$env:PATH;$path" -m
    }
}

function Get-ComFolderItem() {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory=$true)] $Path
    )

    $ShellApp = New-Object -ComObject 'Shell.Application'
    $Item = Get-Item $Path -ErrorAction Stop

    if ($Item -is [System.IO.FileInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Directory.FullName).ParseName($Item.Name)
    } elseif ($Item -is [System.IO.DirectoryInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Parent.FullName).ParseName($Item.Name)
    } else {
        throw "Path is not a file nor a directory"
    }

    return $ComFolderItem
}
function Set-TaskBarPin() {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory=$true)] [System.IO.FileInfo] $Item
    )

    if (Test-Path $Item) {
        Write-Output "Pinning $Item to the taskbar`r`n"
        $Pinned = Get-ComFolderItem -Path $Item
    
        $Pinned.invokeverb('taskbarpin')
    }
}

function Set-TaskBarPinChrome() {
    Set-TaskBarPin "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}
function Set-TaskBarPinVisualStudio() {
    Set-TaskBarPin "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe"
}
function Set-TaskBarPinVsCode() {
    Set-TaskBarPin "$env:localappdata\Programs\Microsoft VS Code\Code.exe"
}
function Set-TaskBarPinSlack() {
    Set-TaskBarPin "$env:localappdata\slack\slack.exe"
}

function Install-ChocolateyPackage {
    [CmdletBinding()]
    Param (
        [String]$PackageName,
        [String]$InstallArgs,
        $RunIfInstalled
    )

    if ($global:installedPackages -match "^$PackageName \d") {
        Write-Output "$PackageName already installed`r`n"
    } else {
        if ($InstallArgs -ne $null -and $InstallArgs -ne "") {
            Write-Output "choco install $PackageName -InstallArguments ""$InstallArgs""`r`n"
            iex "choco install $PackageName -InstallArguments ""$InstallArgs""" | Out-Default
        } else {
            Write-Output "choco install $PackageName`r`n"
            iex "choco install $PackageName" | Out-Default
        }

        if ($null -ne $RunIfInstalled) {
            &$RunIfInstalled
        }
    }
}

function Add-Todo($message) {
    Write-Warning "$message`r`n"
    Add-Content "todo.txt" "$message`r`n"
}

function Add-ExplorerFavourite($name, $folder) {
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut("$env:USERPROFILE\Links\$name.lnk")
    $link.TargetPath = $folder
    $link.Save()
}

Export-ModuleMember -Function *
