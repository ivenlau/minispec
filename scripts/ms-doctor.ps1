param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

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

