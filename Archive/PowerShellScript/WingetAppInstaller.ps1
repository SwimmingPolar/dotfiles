# Lightweight Winget bulk installer
# Run in elevated PowerShell
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$apps = @(
    "Google.Chrome",
    # "Microsoft.Office",
    # "TeamViewer.TeamViewer",
    # "WatchGuard.MobileVPNWithSSLClient"
)

$log = "$PSScriptRoot\winget_run_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "u"
    "$time $msg" | Tee-Object -FilePath $log -Append
}

function Exists-In-Repo {
    param([string]$Id)
    $null = & winget search --accept-source-agreements --id $Id --exact 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Is-Installed {
    param([string]$Id)
    $null = & winget list --accept-source-agreements --id $Id --exact 2>$null
    return ($LASTEXITCODE -eq 0)
}

function No-Sleep {
	powercfg /change standby-timeout-ac 0
	powercfg /change standby-timeout-dc 0
	powercfg /change monitor-timeout-ac 0
	powercfg /change monitor-timeout-dc 0
	powercfg /change hibernate-timeout-ac 0
	powercfg /change hibernate-timeout-dc 0
}

Write-Log "Starting winget auto installation script..."

$validApps = @()
$installArgs = @(
    "--exact",
    "--accept-package-agreements",
    "--accept-source-agreements",
    "--silent",
    "--disable-interactivity"
)

foreach ($app in $apps) {
    if (-not (Exists-In-Repo $app)) {
        Write-Log "$app not found in Winget sources"
        continue
    }

    if (Is-Installed $app) {
        Write-Log "$app already installed"
        continue
    }

    Write-Log "Queued: $app"
    $validApps += $app
}

if ($validApps.Count -eq 0) {
    Write-Log "No apps to install. Exiting."
    exit
}

Write-Log "Installing $($validApps.Count) apps..."

Sleep 3

Write-Log "Overriding installer security hash check..."
winget settings --enable InstallerHashOverride

Write-Log "Changing power mode to no sleep mode..."
No-Sleep

foreach ($app in $validApps) {
    try {
        Write-Log "Installing $app..."
        & winget install --id $app @installArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Installed $app successfully"
        } else {
            Write-Log "Failed to install $app (exit code $LASTEXITCODE)"
        }
    }
    catch {
	    $err = $_.Exception.Message
	    Write-Log "Exception while installing $app`: $err"
	    continue
    }
}

Write-Log "Exiting winget auto installation script."
