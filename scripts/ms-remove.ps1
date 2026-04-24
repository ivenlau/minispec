param(
  [string]$Target = ".",
  [switch]$Yes,
  [switch]$KeepArchive,
  [switch]$KeepSpecs,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$targetPath = (Resolve-Path $Target).Path

if (-not (Test-Path (Join-Path $targetPath "minispec")) -and
    -not (Test-Path (Join-Path $targetPath "AGENTS.md")) -and
    -not (Test-Path (Join-Path $targetPath "CLAUDE.md"))) {
  Write-Output "ms-remove: $targetPath has no minispec scaffolding to remove."
  exit 0
}

$pathsToDelete = New-Object System.Collections.Generic.List[string]
function Add-IfExists([string]$Rel) {
  if (Test-Path (Join-Path $targetPath $Rel)) {
    $pathsToDelete.Add($Rel)
  }
}

Add-IfExists "AGENTS.md"
Add-IfExists "CLAUDE.md"
Add-IfExists ".agents"
Add-IfExists ".claude"

if ($KeepArchive -or $KeepSpecs) {
  $minispecDir = Join-Path $targetPath "minispec"
  if (Test-Path $minispecDir) {
    Get-ChildItem -Path $minispecDir -Force | ForEach-Object {
      if ($KeepArchive -and $_.Name -eq "archive") { return }
      if ($KeepSpecs -and $_.Name -eq "specs") { return }
      $pathsToDelete.Add("minispec/$($_.Name)")
    }
  }
} else {
  Add-IfExists "minispec"
}

$stripMarker = $false
$gitignorePath = Join-Path $targetPath ".gitignore"
if (Test-Path $gitignorePath) {
  $giContent = Get-Content -Path $gitignorePath -Raw -Encoding UTF8
  if ($giContent -match "(?m)^# >>> minispec") { $stripMarker = $true }
}

Write-Output "Remove minispec scaffolding from $targetPath"
Write-Output ""
if ($pathsToDelete.Count -gt 0) {
  Write-Output "Would delete:"
  foreach ($p in $pathsToDelete) { Write-Output "  $p" }
}
if ($stripMarker) {
  Write-Output "Would strip:"
  Write-Output "  .gitignore block between '# >>> minispec' and '# <<< minispec'"
}
if ($KeepArchive -and (Test-Path (Join-Path $targetPath "minispec/archive"))) {
  Write-Output "Would keep: minispec/archive/ (-KeepArchive)"
}
if ($KeepSpecs -and (Test-Path (Join-Path $targetPath "minispec/specs"))) {
  Write-Output "Would keep: minispec/specs/ (-KeepSpecs)"
}
Write-Output ""

if ($DryRun) {
  Write-Output "Dry-run complete. Re-run without -DryRun (with -Yes or in a TTY) to apply."
  exit 0
}

if (-not $Yes) {
  if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
    Write-Error "ms-remove: running non-interactively — pass -Yes to proceed."
    exit 1
  }
  $answer = Read-Host "Continue? [y/N]"
  if ($answer -notmatch '^[yY]') {
    Write-Output "Aborted."
    exit 1
  }
}

foreach ($p in $pathsToDelete) {
  Remove-Item -Recurse -Force (Join-Path $targetPath $p)
  Write-Output "removed: $p"
}

if ($stripMarker) {
  $lines = Get-Content -Path $gitignorePath -Encoding UTF8
  $out = New-Object System.Collections.Generic.List[string]
  $inBlock = $false
  foreach ($line in $lines) {
    if ($line -match "^# >>> minispec") { $inBlock = $true; continue }
    if ($inBlock -and $line -match "^# <<< minispec") { $inBlock = $false; continue }
    if ($inBlock) { continue }
    $out.Add($line)
  }
  while ($out.Count -gt 0 -and [string]::IsNullOrWhiteSpace($out[$out.Count - 1])) {
    $out.RemoveAt($out.Count - 1)
  }
  Set-Content -Path $gitignorePath -Value $out -Encoding UTF8
  Write-Output "stripped: .gitignore minispec marker block"
}

Write-Output ""
Write-Output "minispec removed from $targetPath."
