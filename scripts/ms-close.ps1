param(
  [Parameter(Mandatory = $true)]
  [string]$ChangeId,
  [Parameter(Mandatory = $true)]
  [string]$Domain,
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Get-MarkdownSection {
  param(
    [string]$Text,
    [string]$Heading
  )
  $escaped = [Regex]::Escape($Heading)
  $pattern = "(?ms)^#\s+$escaped\s*\r?\n(.*?)(?=^#\s+|\z)"
  $m = [Regex]::Match($Text, $pattern)
  if ($m.Success) {
    return $m.Groups[1].Value.Trim()
  }
  return ""
}

function Set-ClosedStatus {
  param([string]$Text)
  if ($Text -match "(?ms)^---\s*\r?\n(.*?)\r?\n---") {
    $frontMatter = $Matches[0]
    $updated = $frontMatter
    if ($frontMatter -match "(?m)^status:\s*.+$") {
      $updated = [Regex]::Replace($frontMatter, "(?m)^status:\s*.+$", "status: closed")
    } else {
      $updated = [Regex]::Replace($frontMatter, "(?m)^---\s*$", "---`nstatus: closed", 1)
    }
    return $Text.Replace($frontMatter, $updated)
  }
  return "---`nstatus: closed`n---`n`n$Text"
}

$rootPath = Resolve-Path $Root
$changePath = Join-Path $rootPath ("minispec/changes/{0}.md" -f $ChangeId)
$archivePath = Join-Path $rootPath ("minispec/archive/{0}.md" -f $ChangeId)
$specPath = Join-Path $rootPath ("minispec/specs/{0}.md" -f $Domain)

if (-not (Test-Path $changePath)) {
  throw "Change file not found: $changePath"
}

$content = Get-Content -Path $changePath -Raw -Encoding UTF8

$why = Get-MarkdownSection -Text $content -Heading "Why"
$scope = Get-MarkdownSection -Text $content -Heading "Scope"
$acceptance = Get-MarkdownSection -Text $content -Heading "Acceptance"
$notes = Get-MarkdownSection -Text $content -Heading "Notes"

$uncheckedInAcceptance = [Regex]::Matches($acceptance, "(?m)^\s*-\s*\[\s\]\s+")
if ($uncheckedInAcceptance.Count -gt 0) {
  throw "Cannot close change. Acceptance section has unchecked items."
}

$dateText = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $specPath)) {
  @(
    "# $Domain",
    "",
    "Canonical shipped behavior for domain: $Domain",
    ""
  ) | Set-Content -Path $specPath -Encoding UTF8
}

$specContent = Get-Content -Path $specPath -Raw -Encoding UTF8
if ($specContent -match ("(?m)^##\s+Change\s+" + [Regex]::Escape($ChangeId) + "\b")) {
  throw "Change '$ChangeId' already merged in spec file: $specPath"
}

$notesSection = if ($notes) { $notes } else { "- No additional notes." }
$mergeTemplate = @'
## Change {0} ({1})

### Why
{2}

### Scope
{3}

### Acceptance
{4}

### Notes
- Auto-merged from `minispec/changes/{0}.md`
- See `minispec/archive/{0}.md` for plan and risk notes.
{5}
'@
$mergeBlock = $mergeTemplate -f $ChangeId, $dateText, $why, $scope, $acceptance, $notesSection

$specContent = $specContent.TrimEnd() + "`r`n`r`n" + $mergeBlock.TrimEnd() + "`r`n"
Set-Content -Path $specPath -Value $specContent -Encoding UTF8

$updated = Set-ClosedStatus -Text $content
Set-Content -Path $changePath -Value $updated -Encoding UTF8

if (Test-Path $archivePath) {
  throw "Archive target already exists: $archivePath"
}

Move-Item -Path $changePath -Destination $archivePath

Write-Output "Closed change: $ChangeId"
Write-Output "Merged spec: minispec/specs/$Domain.md"
Write-Output "Archived card: minispec/archive/$ChangeId.md"
