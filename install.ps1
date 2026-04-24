# minispec system-wide installer for Windows (PowerShell 5.1+ / 7+).
#
# One-line install:
#   irm https://raw.githubusercontent.com/ivenlau/minispec/main/install.ps1 | iex
#
# Customise:
#   $env:MINISPEC_REPO = "myfork/minispec"; irm .../install.ps1 | iex
#   .\install.ps1 -Prefix "$env:USERPROFILE\.minispec" -Ref v0.1.0
[CmdletBinding()]
param(
  [string]$Repo   = $(if ($env:MINISPEC_REPO)   { $env:MINISPEC_REPO }   else { "ivenlau/minispec" }),
  [string]$Ref    = $(if ($env:MINISPEC_REF)    { $env:MINISPEC_REF }    else { "main" }),
  [string]$Prefix = $(if ($env:MINISPEC_PREFIX) { $env:MINISPEC_PREFIX } else { Join-Path $env:USERPROFILE ".minispec" })
)

$ErrorActionPreference = "Stop"

Write-Host "Installing minispec ($Repo@$Ref) to $Prefix ..." -ForegroundColor Cyan

$shareDir = $Prefix
$binDir   = Join-Path $Prefix "bin"

if ($Ref -match '^v|^\d') {
  $url = "https://github.com/$Repo/archive/refs/tags/$Ref.zip"
} else {
  $url = "https://github.com/$Repo/archive/refs/heads/$Ref.zip"
}

$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ("minispec-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
  $zipPath = Join-Path $tmpDir "minispec.zip"
  Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
  Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

  $extracted = Get-ChildItem $tmpDir -Directory | Select-Object -First 1
  if (-not $extracted) { throw "Downloaded archive has no top-level directory." }

  # Move aside any existing install, install fresh, drop aside.
  $aside = $null
  if (Test-Path $shareDir) {
    $aside = "$shareDir.old.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    Rename-Item -Path $shareDir -NewName (Split-Path -Leaf $aside) -Force
  }
  New-Item -ItemType Directory -Path $shareDir -Force | Out-Null

  $items = @(
    "scripts", "minispec", ".agents", ".claude", "bin",
    "AGENTS.md", "CLAUDE.md", "README.md", "README.zh-CN.md",
    "VERSION", "LICENSE",
    "uninstall.sh", "uninstall.ps1"
  )
  foreach ($item in $items) {
    $src = Join-Path $extracted.FullName $item
    if (Test-Path $src) {
      Copy-Item -Recurse -Force -Path $src -Destination (Join-Path $shareDir $item)
    }
  }

  if ($aside -and (Test-Path $aside)) {
    Remove-Item -Recurse -Force $aside
  }

  # Install launchers to <share>/bin is already done by the copy above.
  # If $binDir is *inside* the share (default), we're done. Otherwise copy the shims.
  if (-not ($binDir.StartsWith($shareDir, [System.StringComparison]::OrdinalIgnoreCase))) {
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir | Out-Null }
    Copy-Item -Force (Join-Path $shareDir "bin/minispec.cmd") $binDir
    Copy-Item -Force (Join-Path $shareDir "bin/minispec.ps1") $binDir
  }

  # PATH management (User scope).
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  $pathEntries = $userPath.Split(';') | Where-Object { $_ }
  if (-not ($pathEntries -contains $binDir)) {
    $newPath = if ($userPath.TrimEnd(';')) { ($userPath.TrimEnd(';') + ';' + $binDir) } else { $binDir }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $pathChanged = $true
  } else {
    $pathChanged = $false
  }

  $versionFile = Join-Path $shareDir "VERSION"
  $version = if (Test-Path $versionFile) { (Get-Content -Raw $versionFile).Trim() } else { "unknown" }

  Write-Host ""
  Write-Host "minispec $version installed." -ForegroundColor Green
  Write-Host "  share:    $shareDir"
  Write-Host "  launcher: $binDir\minispec.cmd"
  Write-Host ""

  if ($pathChanged) {
    Write-Host "Added $binDir to your user PATH." -ForegroundColor Yellow
    Write-Host "Restart your terminal (or run this one-liner to refresh the current session):" -ForegroundColor Yellow
    Write-Host "  `$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')" -ForegroundColor Yellow
    Write-Host ""
  }

  Write-Host "Next:"
  Write-Host "  minispec --version"
  Write-Host "  minispec init ."
}
finally {
  if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
}
