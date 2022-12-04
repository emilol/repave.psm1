param(
 [string]$update = "false"
)
if ($update -eq "false") {
    Write-Warning "Have you Bitlocker encrypted the drive?`r`n"
    Read-Host
}

Import-Module "$(Split-Path $MyInvocation.MyCommand.Path)\repave.psm1" -Force
Invoke-Repave {
    # Timezone
    tzutil /s "E. Australia Standard Time_dstoff"

    # Dev directories
    mkdir C:\Code\Personal -ErrorAction SilentlyContinue | Out-Null
    mkdir C:\Code\Octopus -ErrorAction SilentlyContinue | Out-Null
    mkdir C:\Code\Libraries -ErrorAction SilentlyContinue | Out-Null
    mkdir C:\Code\Training -ErrorAction SilentlyContinue | Out-Null

    # Windows Explorer
    Set-AdvancedWindowsExplorerOptions
    Add-ExplorerFavourite "Code (Octopus)" "C:\Code\Octopus"
    Add-ExplorerFavourite "Code (Personal)" "C:\Code\Personal"
    
    # Git
    Install-Git "C:/Code/Octopus/"
    Copy-GitConfig

    Install-Wsl2

    # IDEs
    Install-ChocolateyPackage jetbrainstoolbox
    Install-ChocolateyPackage visualstudio2022professional
    Install-ChocolateyPackage vscode
    
    Install-ChocolateyPackage GitKraken
    Install-ChocolateyPackage git
    Install-ChocolateyPackage linqpad6 -RunIfInstalled { Add-Todo "Register linqpad via: LINQPad.exe -activate=PRODUCT_CODE" }
    Install-ChocolateyPackage fiddler4
    Install-ChocolateyPackage azure-data-studio
    Install-ChocolateyPackage ngrok

    # Containers
    Install-ChocolateyPackage docker-desktop
    Install-ChocolateyPackage kubernetes-cli
    Install-ChocolateyPackage kubernetes-helm
    Install-ChocolateyPackage lens

    # Utils
    Install-ChocolateyPackage greenshot
    Install-ChocolateyPackage sysinternals
    Install-ChocolateyPackage windirstat
    Install-ChocolateyPackage lockhunter
    Install-ChocolateyPackage paint.net
    Install-ChocolateyPackage synergy
    Install-ChocolateyPackage rdm
    
    # Internet
    Install-ChocolateyPackage googlechrome
    Install-ChocolateyPackage slack
    Install-ChocolateyPackage 1password
    Install-ChocolateyPackage lastpass

    # Other
    Install-ChocolateyPackage steam -RunIfInstalled { Add-Todo "Restore game backups and save games" }
    Install-ChocolateyPackage nodejs.install
    Install-ChocolateyPackage spotify
    
    # Pin to taskbar
    Set-TaskBarPinChrome
    Set-TaskBarPinVisualStudio2019
    Set-TaskBarPinVsCode
    Set-TaskBarPinSlack

    # Todo
    # Disable Shiftkey 5 times
    # Chrome Extensions
    # Default programs http://forum.xda-developers.com/showthread.php?p=29456442 vim: js, md, 7z
    # Local cache NuGet source / CI servers
    # Set VS pin as admin
    # linqpad activation
    
    # Final warnings
    if ($update -eq "false") {
        Add-Todo "Check device manager for missing drivers; check graphics drivers; check laptop special buttons work"
        Add-Todo "Install printers"
        Add-Todo "Configure power options"
        Add-Todo "Run Windows Update"
    }
}
