param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Format-Duration {
  param([int]$Seconds)
  $hours = [math]::Floor($Seconds / 3600)
  $minutes = [math]::Floor(($Seconds % 3600) / 60)
  return ("{0}h {1}m" -f $hours, $minutes)
}

$rootPath = Resolve-Path $Root
$marker = Join-Path $rootPath "minispec/.paused"

if (-not (Test-Path $marker)) {
  Write-Output "minispec is not paused."
  exit 0
}

$existing = Get-Content -Path $marker -Raw -Encoding UTF8
$pausedTs = $null
if ($existing -match "(?m)^paused_at:\s*(\S+)") { $pausedTs = $Matches[1] }

Remove-Item -Force $marker

if ($pausedTs) {
  try {
    $prev = [DateTime]::Parse($pausedTs).ToUniversalTime()
    $dur = Format-Duration ([int](([DateTime]::UtcNow - $prev).TotalSeconds))
    Write-Output "minispec resumed (was paused for $dur)."
    exit 0
  } catch { }
}

Write-Output "minispec resumed."
