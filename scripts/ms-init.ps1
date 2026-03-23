param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Root)) {
  New-Item -ItemType Directory -Path $Root | Out-Null
}

$rootPath = Resolve-Path $Root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

function Ensure-TextFile {
  param(
    [string]$RootPath,
    [string]$RelativePath,
    [string]$SourceRelativePath,
    [string]$DefaultContent
  )

  $targetPath = Join-Path $RootPath $RelativePath
  if (Test-Path $targetPath) { return }

  $parent = Split-Path -Parent $targetPath
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }

  $sourcePath = Join-Path $repoRoot $SourceRelativePath
  if (Test-Path $sourcePath -PathType Leaf) {
    Copy-Item -Path $sourcePath -Destination $targetPath -Force
    return
  }

  Set-Content -Path $targetPath -Value $DefaultContent -Encoding UTF8
}

$dirs = @(
  "minispec",
  "minispec/specs",
  "minispec/changes",
  "minispec/archive",
  "minispec/templates",
  ".agents/skills/minispec",
  ".claude/skills/minispec"
)

foreach ($d in $dirs) {
  $full = Join-Path $rootPath $d
  if (-not (Test-Path $full)) {
    New-Item -ItemType Directory -Path $full | Out-Null
  }
}

Ensure-TextFile -RootPath $rootPath -RelativePath "minispec/templates/change.md" -SourceRelativePath "minispec/templates/change.md" -DefaultContent @'
---
id: YYYYMMDD-short-slug
status: draft
owner: your-name
---

# Why

Describe the problem and business impact in one short paragraph.

# Scope

- In:
- Out:

# Acceptance

- [ ] Given ... When ... Then ...
- [ ] Given ... When ... Then ...

# Plan

- [ ] T1 Update files:
  - Expected output:
- [ ] T2 Add or adjust tests:
  - Expected output:
- [ ] T3 Update docs/spec:
  - Expected output:

# Risks and Rollback

- Risk:
- Rollback:

# Notes

- Optional implementation notes.
'@

Ensure-TextFile -RootPath $rootPath -RelativePath "minispec/specs/README.md" -SourceRelativePath "minispec/specs/README.md" -DefaultContent @'
# Canonical Specs

Store shipped behavior here by domain.
'@

Ensure-TextFile -RootPath $rootPath -RelativePath "minispec/changes/.gitkeep" -SourceRelativePath "minispec/changes/.gitkeep" -DefaultContent @'
'@

Ensure-TextFile -RootPath $rootPath -RelativePath "minispec/archive/.gitkeep" -SourceRelativePath "minispec/archive/.gitkeep" -DefaultContent @'
'@

Ensure-TextFile -RootPath $rootPath -RelativePath ".agents/skills/minispec/SKILL.md" -SourceRelativePath ".agents/skills/minispec/SKILL.md" -DefaultContent @'
# minispec

Lightweight spec-first workflow for code changes.
'@

Ensure-TextFile -RootPath $rootPath -RelativePath ".claude/skills/minispec/SKILL.md" -SourceRelativePath ".claude/skills/minispec/SKILL.md" -DefaultContent @'
# minispec

Lightweight spec-first workflow for code changes.
'@

Ensure-TextFile -RootPath $rootPath -RelativePath "AGENTS.md" -SourceRelativePath "AGENTS.md" -DefaultContent @'
# AGENTS
'@

Ensure-TextFile -RootPath $rootPath -RelativePath "CLAUDE.md" -SourceRelativePath "CLAUDE.md" -DefaultContent @'
# CLAUDE
'@

Write-Output "minispec directories and scaffold files ensured at: $rootPath"
