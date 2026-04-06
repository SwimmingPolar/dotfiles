# Script root is the source folder to back up
$Source = $PSScriptRoot
$SourceDirName = Split-Path -Leaf $Source
$BackupRoot = Join-Path -Path $(Split-Path -Parent $Source) -ChildPath ("$SourceDirName" + "_backup")

$ErrorActionPreference = 'Stop'

# Create the backup folder if missing (idempotent)
[void][System.IO.Directory]::CreateDirectory($BackupRoot)

# Run Robocopy with fixed, safe defaults
$roboArgs = @(
  "`"$Source`"",
  "`"$BackupRoot`"",
  "*.*",
  "/MIR",
  "/COPY:DT",
  "/DCOPY:T",
  "/XJ",
  "/MT:16",
  "/R:2","/W:2",
  "/NFL","/NDL","/NP"
)

$proc = Start-Process -FilePath robocopy.exe -ArgumentList $roboArgs -Wait -PassThru
$code = $proc.ExitCode

# Robocopy exit codes 0..7 are success/minor issues
if ($code -le 7) {
  # Hide + mark system (best effort; ignore errors if not allowed)
  # try { attrib +h +s $BackupRoot 2>$null } catch {}

  Write-Host "Backup mirror complete. Exit code: $code"
} else {
  throw "Robocopy failed with exit code $code"
}

