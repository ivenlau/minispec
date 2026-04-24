param(
  [string]$Root = ".",
  [string]$Reason = ""
)

$ErrorActionPreference = "Stop"

function Format-Duration {
  param([int]$Seconds)
  $hours = [math]::Floor($Seconds / 3600)
  $minutes = [math]::Floor(($Seconds % 3600) / 60)
  return ("{0}h {1}m" -f $hours, $minutes)
}

$rootPath = Resolve-Path $Root
$minispecDir = Join-Path $rootPath "minispec"
if (-not (Test-Path $minispecDir)) {
  Write-Error "ms-pause: no minispec/ directory at $rootPath (run 'minispec init' first)"
  exit 1
}

$marker = Join-Path $minispecDir ".paused"

if (Test-Path $marker) {
  $existing = Get-Content -Path $marker -Raw -Encoding UTF8
  $existingTs = $null
  if ($existing -match "(?m)^paused_at:\s*(\S+)") { $existingTs = $Matches[1] }

  if ($existingTs) {
    try {
      $prev = [DateTime]::Parse($existingTs).ToUniversalTime()
      $dur = Format-Duration ([int](([DateTime]::UtcNow - $prev).TotalSeconds))
      Write-Output "minispec already paused since $existingTs ($dur ago)."
    } catch {
      Write-Output "minispec already paused since $existingTs."
    }
  } else {
    Write-Output "minispec already paused (marker exists)."
  }
  exit 0
}

$pausedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("paused_at: $pausedAt")
if ($Reason) { $lines.Add("reason: $Reason") }

Set-Content -Path $marker -Value ($lines -join "`n") -Encoding UTF8

if ($Reason) {
  Write-Output "minispec paused at $pausedAt (reason: $Reason)."
} else {
  Write-Output "minispec paused at $pausedAt."
}
Write-Output "Run 'minispec resume' to re-enable the workflow."
