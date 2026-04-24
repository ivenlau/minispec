# minispec system-wide uninstaller for Windows.
#
# Removes:
#   - The minispec launcher at <prefix>\bin\
#   - The install directory at <prefix>\
#   - The PATH entry for <prefix>\bin from user PATH
#
# One-line uninstall:
#   irm https://raw.githubusercontent.com/ivenlau/minispec/main/uninstall.ps1 | iex
#   (It will prompt for confirmation. To auto-confirm: set $env:MINISPEC_YES = "1" first.)
[CmdletBinding()]
param(
  [string]$Prefix = $(if ($env:MINISPEC_PREFIX) { $env:MINISPEC_PREFIX } else { Join-Path $env:USERPROFILE ".minispec" }),
  [switch]$Yes,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $Yes -and $env:MINISPEC_YES -eq "1") { $Yes = [switch]$true }

$shareDir = $Prefix
$binDir = Join-Path $Prefix "bin"

$hasShare = Test-Path $shareDir
$hasBin = Test-Path $binDir

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$pathEntries = $userPath.Split(';') | Where-Object { $_ }
$hasPathEntry = $pathEntries -contains $binDir

if (-not $hasShare -and -not $hasBin -and -not $hasPathEntry) {
  Write-Output "uninstall.ps1: nothing to remove at prefix $Prefix"
  exit 0
}

Write-Output "Uninstall minispec from $Prefix"
Write-Output ""
Write-Output "Would remove:"
if ($hasBin) { Write-Output "  $binDir\ (launcher directory)" }
if ($hasShare) { Write-Output "  $shareDir\ (install directory)" }
if ($hasPathEntry) { Write-Output "  PATH entry: $binDir" }
Write-Output ""

if ($DryRun) {
  Write-Output "Dry-run complete. Re-run without -DryRun (with -Yes or in an interactive PowerShell) to apply."
  exit 0
}

if (-not $Yes) {
  if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
    Write-Error "uninstall.ps1: running non-interactively — pass -Yes (or set `$env:MINISPEC_YES='1') to proceed."
    exit 1
  }
  $answer = Read-Host "Continue? [y/N]"
  if ($answer -notmatch '^[yY]') {
    Write-Output "Aborted."
    exit 1
  }
}

# Backup current user PATH before mutating.
if ($hasPathEntry) {
  $backupFile = Join-Path $env:USERPROFILE ".minispec-path-backup.txt"
  $userPath | Set-Content -Path $backupFile -Encoding UTF8
  Write-Output "backed up current user PATH to: $backupFile"
}

# Remove the share/install directory (which contains bin/ on Windows default layout).
if ($hasShare) {
  Remove-Item -Recurse -Force $shareDir
  Write-Output "removed: $shareDir"
}

# On custom prefix, bin might be separate.
if ($hasBin -and (Test-Path $binDir)) {
  Remove-Item -Recurse -Force $binDir
  Write-Output "removed: $binDir"
}

# Strip PATH entry.
if ($hasPathEntry) {
  $newEntries = $pathEntries | Where-Object { $_ -ne $binDir }
  $newPath = $newEntries -join ';'
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  Write-Output "removed from user PATH: $binDir"
}

Write-Output ""
Write-Output "minispec uninstalled."
Write-Output "Tip: projects that used minispec still contain their minispec/ directory and"
Write-Output "agent files. Run 'minispec remove <dir>' (before uninstalling) if you want"
Write-Output "to clean those up too."
Write-Output ""
if ($hasPathEntry) {
  Write-Output "Restart your terminal to drop the stale PATH entry from the current session."
}
