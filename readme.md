repave.psm1
==========

A PowerShell module that allows you to easily create a terse re-pave script for a Windows Machine making heavy use of Chocolatey.

Forked from https://github.com/MRCollective/repave.psm1

Minimum example
---------------

To get started all you need is this in a `.ps1` file:

```powershell
Import-Module "$(Split-Path $MyInvocation.MyCommand.Path)\repave.psm1" -Force
Invoke-Repave {
    # Stuff to install
}
```

When you run it you must be in admin mode and after running there will be an `repave.log` file with the output and a `todo.txt` file with items for further action (unless you ran the script from PowerShell ISE, in which case there is no `repave.log`).

Functions
---------

### Invoke-Repave $script

Invokes `$script` as a code block after setting up and shutting down the repave environment before and after it respectively.

Setting up the environment involves:

1. Writing an error and exiting with non-zero exit code if the script is not executed with admin privileges
2. Invoking `Start-Script` (see below)
3. Creating a try block
    1. Creating an `Installers` directory if it doesn't already exist (used as a cache for installers that are downloaded)
    2. If the user is running in PowerShell ISE then outputting a warning that there will be no transcript
    3. If the user is not running in PowerShell ISE then starting a transcript for `repave.log` in append mode (i.e. subsequent runs will append to the log)
    4. Invoking `Install-Chocolatey` (see below)
    5. Invoking `Install-WebPI` (see below)

Shutting down the environment involves:

1. Write a warning to remind the user to clear the temp path
2. If a transcript is running then stop it
3. Catch any exceptions and:
    1. Write an error
    2. If a transcript is running then stop it
    3. Exit with non-zero exit code

### Start-Script

1. Gets the path of the `.ps1` script being executed and saves it to a global variable called `$scriptpath`; you can use this variable from your scripts
2. Changes directory to `$scriptpath` so any local file references will be local to the script no matter what the working directory was when the script was first executed
3. Sets `$ErrorActionPreference` to `stop` so any errors will cause an exception to throw and the repave script to early exit
    * There is currently a bug where problems in programs that are executed (e.g. `cinst`) don't propagate out

### Install-Chocolatey

Install Chocolatey if not already installed (and record which Chocolatey packages were installed when the script was first run so it can detect if it should invoke `cinst` when installing packages - this is a huge speed boost on subsequent script runs).

### Get-SourcePath

Returns the value of the global `$scriptpath` variable setup by `Start-Script` / `Invoke-Repave`.

### Test-Administrator

Returns `$true` if running with admin priviliges.

### Test-VirtualMachine

Returns `$true` if running in a Virtual Machine.

### Set-AdvancedWindowsExplorerOptions

Sets "Show Hidden Files", "Show File Extensions" and "Show System Files" in Windows Explorer.

### Install-Git

Install of:

* `C:\Program Files (x86)\Git\bin` in `%PATH%`
* Copying the `.ssh` folder (if present relative to the script) to `~` if not already there
    * If it is present then TortoiseGit is configured to use `ssh.exe` rather than `PLink.exe`

### Copy-GitConfig($workFolder)

* Copies the `.gitconfig` file (if present relative to the script) to `~` if not already there
* Copies the `.gitconfig.work` file (if present relative to the script) to `$workFolder` if not already there

### Install-VisualStudio

Installs Visual Studio.

### Add-ToPath($path)

Reloads the `%PATH%` and appends the given path to the end of it if it's not already in there.

### Set-TaskBarPin($path, $exe)

Pins the given `$exe` inside of the given `$path` to the taskbar.

### Set-TaskBarPinChrome

Pins Chrome to the taskbar.

### Set-TaskBarPinVisualStudio

Pins Visual Studio to the taskbar.

### `Install-ChocolateyPackage $PackageName [-InstallArgs <InstallArgs>] [-RunIfInstalled { <code> }]`

Installs the given Chocolatey package if it's not already installed. Optionally pass `-InstallArgs` to add extra Chocolatey installation arguments or `-RunIfInstalled` to run some code if the given package is being installed.

### Add-Todo $message

Writes a warning of $message and appends that message to `todo.txt`.

### Add-ExplorerFavourite $name, $folder

Adds a favourite link in Windows Explorer with the given name pointing to the given folder location.
