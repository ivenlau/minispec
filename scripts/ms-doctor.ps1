param(
  [string]$Root = ".",
  [switch]$Version
)

$ErrorActionPreference = "Stop"

if ($Version) {
  $versionFile = Join-Path $PSScriptRoot "../VERSION"
  if (Test-Path $versionFile) {
    Write-Output ((Get-Content -Path $versionFile -Raw).Trim())
  } else {
    Write-Output "unknown"
  }
  exit 0
}

function Test-PathType {
  param(
    [string]$Path,
    [string]$Type
  )
  if (-not (Test-Path $Path)) { return $false }
  $item = Get-Item $Path
  if ($Type -eq "File") { return -not $item.PSIsContainer }
  if ($Type -eq "Directory") { return $item.PSIsContainer }
  return $false
}

$rootPath = Resolve-Path $Root
$failures = @()
$warnings = @()

$required = @(
  @{ Path = "minispec"; Type = "Directory"; Label = "minispec root" },
  @{ Path = "minispec/project.md"; Type = "File"; Label = "project contract" },
  @{ Path = "minispec/specs"; Type = "Directory"; Label = "canonical specs directory" },
  @{ Path = "minispec/changes"; Type = "Directory"; Label = "active changes directory" },
  @{ Path = "minispec/archive"; Type = "Directory"; Label = "archive directory" },
  @{ Path = "minispec/templates/change.md"; Type = "File"; Label = "change template" }
)

$optional = @(
  @{ Path = "AGENTS.md"; Type = "File"; Label = "Codex workflow entry" },
  @{ Path = "CLAUDE.md"; Type = "File"; Label = "Claude workflow entry" },
  @{ Path = ".agents/skills/minispec/SKILL.md"; Type = "File"; Label = "Codex minispec skill" },
  @{ Path = ".claude/skills/minispec/SKILL.md"; Type = "File"; Label = "Claude minispec skill" }
)

Write-Output "minispec doctor"
Write-Output "root: $rootPath"

foreach ($item in $required) {
  $full = Join-Path $rootPath $item.Path
  if (Test-PathType -Path $full -Type $item.Type) {
    Write-Output "[OK] $($item.Path) ($($item.Label))"
  } else {
    $failures += "$($item.Path) ($($item.Label))"
    Write-Output "[MISSING] $($item.Path) ($($item.Label))"
  }
}

foreach ($item in $optional) {
  $full = Join-Path $rootPath $item.Path
  if (Test-PathType -Path $full -Type $item.Type) {
    Write-Output "[OK] $($item.Path) ($($item.Label))"
  } else {
    $warnings += "$($item.Path) ($($item.Label))"
    Write-Output "[WARN] $($item.Path) ($($item.Label))"
  }
}

Write-Output ""
Write-Output "Semantic checks:"

function Write-SemWarn { param([string]$Msg) Write-Output "[WARN] $Msg" }

# 1. TBD placeholders in project.md
$projPath = Join-Path $rootPath "minispec/project.md"
if (Test-Path $projPath) {
  $projText = Get-Content -Path $projPath -Raw -Encoding UTF8
  if ($projText -match '\bTBD\b') {
    Write-SemWarn "minispec/project.md: still contains TBD placeholders."
  }
}

$cutoffDate = (Get-Date).AddDays(-14).ToString("yyyyMMdd")

$changesDir = Join-Path $rootPath "minispec/changes"
if (Test-Path $changesDir) {
  Get-ChildItem -Path $changesDir -Filter *.md -File -ErrorAction SilentlyContinue | ForEach-Object {
    $bn = $_.BaseName
    $rel = "minispec/changes/$($_.Name)"

    if ($bn -notmatch '^\d{8}-[a-z0-9-]+$') {
      Write-SemWarn "${rel}: filename does not match YYYYMMDD-slug pattern."
    }

    $fileText = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    $status = ""
    if ($fileText -match "(?ms)^---\s*\r?\n(.*?)^---") {
      $fm = $Matches[1]
      if ($fm -match "(?m)^status:\s*(\S+)") {
        $status = $Matches[1]
      }
    }

    if (-not $status) {
      Write-SemWarn "${rel}: frontmatter has no status field."
    } elseif ($status -notin @('draft','in_progress','closed')) {
      Write-SemWarn "${rel}: unknown status '$status' (expected draft|in_progress|closed)."
    }

    if ($status -eq 'draft' -and $bn -match '^(\d{8})-') {
      $datePart = $Matches[1]
      if ($datePart -lt $cutoffDate) {
        Write-SemWarn "${rel}: draft since $datePart (>14 days); consider closing or updating."
      }
    }
  }
}

function Get-GuardrailsSection {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return "__missing__" }
  $text = Get-Content -Path $Path -Raw -Encoding UTF8
  if ($text -match "(?ms)^## Guardrails[ \t]*\r?\n(.*?)(?=^## |\z)") {
    return ($Matches[1] -replace "\r\n", "`n").TrimEnd()
  }
  return "__absent__"
}

$skillPaths = @(
  (Join-Path $rootPath "minispec/SKILL.md"),
  (Join-Path $rootPath ".claude/skills/minispec/SKILL.md"),
  (Join-Path $rootPath ".agents/skills/minispec/SKILL.md")
)
$guardSections = @()
foreach ($sp in $skillPaths) {
  if (Test-Path $sp) {
    $guardSections += (Get-GuardrailsSection -Path $sp)
  }
}
if ($guardSections.Count -gt 1) {
  $first = $guardSections[0]
  $drift = $false
  foreach ($g in $guardSections) {
    if ($g -cne $first) { $drift = $true; break }
  }
  if ($drift) {
    Write-SemWarn "SKILL files have out-of-sync '## Guardrails' sections (canonical: minispec/SKILL.md)."
  }
}

$specsDir = Join-Path $rootPath "minispec/specs"
$archiveDir = Join-Path $rootPath "minispec/archive"
if (Test-Path $archiveDir) {
  $specFiles = @()
  if (Test-Path $specsDir) {
    $specFiles = Get-ChildItem -Path $specsDir -Filter *.md -File -ErrorAction SilentlyContinue
  }
  Get-ChildItem -Path $archiveDir -Filter *.md -File -ErrorAction SilentlyContinue | ForEach-Object {
    $bn = $_.BaseName
    $found = $false
    foreach ($sf in $specFiles) {
      $specText = Get-Content -Path $sf.FullName -Raw -Encoding UTF8
      if ($specText -match ("(?m)^##\s+Change\s+" + [Regex]::Escape($bn) + '(\s|$)')) {
        $found = $true
        break
      }
    }
    if (-not $found) {
      Write-SemWarn "minispec/archive/$($_.Name): no matching '## Change $bn' in any minispec/specs/*.md."
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Output ""
  Write-Output "Result: FAIL"
  Write-Output "Missing required items:"
  foreach ($f in $failures) { Write-Output "- $f" }
  exit 2
}

Write-Output ""
Write-Output "Result: PASS"
if ($warnings.Count -gt 0) {
  Write-Output "Optional items missing:"
  foreach ($w in $warnings) { Write-Output "- $w" }
}

exit 0

