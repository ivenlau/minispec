param(
  [string]$Target = ".",
  [switch]$DryRun,
  [switch]$IncludeTemplate,
  [switch]$IncludeGitignore,
  [switch]$IncludeCanonicalSkill,
  [string]$Source = ""
)

$ErrorActionPreference = "Stop"

if (-not $Source) {
  $scriptDir = Split-Path -Parent $PSCommandPath
  $Source = if ($env:MINISPEC_HOME) { $env:MINISPEC_HOME } else { (Resolve-Path (Join-Path $scriptDir "..")).Path }
}

if (-not (Test-Path $Source) -or -not (Test-Path (Join-Path $Source ".claude/skills/minispec"))) {
  Write-Error "ms-upgrade: source directory does not look like a minispec install: $Source"
  exit 1
}

$targetPath = (Resolve-Path $Target).Path
if (-not (Test-Path (Join-Path $targetPath "minispec"))) {
  Write-Error "ms-upgrade: $targetPath is not a minispec project (no minispec/ directory). Run 'minispec init' first."
  exit 1
}

function Copy-File {
  param([string]$Rel)
  $src = Join-Path $Source $Rel
  $dst = Join-Path $targetPath $Rel
  if (-not (Test-Path $src)) {
    Write-Output "  skip: source missing: $Rel"
    return
  }
  if ($DryRun) {
    if ((Test-Path $dst) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash)) {
      Write-Output "  unchanged: $Rel"
    } else {
      Write-Output "  would update: $Rel"
    }
    return
  }
  $dstParent = Split-Path -Parent $dst
  if (-not (Test-Path $dstParent)) { New-Item -ItemType Directory -Path $dstParent -Force | Out-Null }
  Copy-Item -Path $src -Destination $dst -Force
  Write-Output "  updated: $Rel"
}

Write-Output "Upgrading minispec in $targetPath"
Write-Output "Source: $Source"
if ($DryRun) { Write-Output "(dry run)" }
Write-Output ""

Write-Output "Agent files:"
Copy-File "AGENTS.md"
Copy-File "CLAUDE.md"
Copy-File ".agents/skills/minispec/SKILL.md"
Copy-File ".claude/skills/minispec/SKILL.md"

if ($IncludeTemplate) {
  Write-Output ""
  Write-Output "Template:"
  Copy-File "minispec/templates/change.md"
}

if ($IncludeGitignore) {
  Write-Output ""
  Write-Output "minispec/.gitignore:"
  Copy-File "minispec/.gitignore"
}

if ($IncludeCanonicalSkill) {
  Write-Output ""
  Write-Output "Canonical skill:"
  Copy-File "minispec/SKILL.md"
}

Write-Output ""
if ($DryRun) {
  Write-Output "Dry-run complete. Re-run without -DryRun to apply."
} else {
  Write-Output "Upgrade complete. Business data in minispec/project.md, specs/, changes/, archive/ was not touched."
}
