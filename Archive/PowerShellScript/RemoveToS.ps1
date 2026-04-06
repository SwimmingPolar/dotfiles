# Close all winget or App Installer processes first
Stop-Process -Name "AppInstallerCLI" -ErrorAction SilentlyContinue

# Delete winget’s local state so it forgets previous ToS acceptance
Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState" -Recurse -Force -ErrorAction SilentlyContinue

# Optionally clear settings as well
Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\Settings" -Recurse -Force -ErrorAction SilentlyContinue

