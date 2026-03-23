param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Action,
  [Parameter(Position = 1)]
  [string]$Arg1,
  [Parameter(Position = 2)]
  [string]$Arg2,
  [Parameter(Position = 3)]
  [string]$Arg3,
  [Parameter(Position = 4, ValueFromRemainingArguments = $true)]
  [string[]]$ArgRest
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-RootArgument {
  param([string]$RootArg)
  if (-not $RootArg) {
    return (Get-Location).Path
  }
  return (Resolve-Path $RootArg).Path
}

function Invoke-MinispecScript {
  param(
    [string]$ScriptName,
    [string[]]$ScriptArgs
  )

  $scriptPath = Join-Path $scriptDir $ScriptName
  & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @ScriptArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

switch ($Action.ToLower()) {
  "init" {
    $root = Resolve-RootArgument -RootArg $Arg1
    Invoke-MinispecScript -ScriptName "ms-init.ps1" -ScriptArgs @("-Root", $root)
    break
  }
  "doctor" {
    $root = Resolve-RootArgument -RootArg $Arg1
    Invoke-MinispecScript -ScriptName "ms-doctor.ps1" -ScriptArgs @("-Root", $root)
    break
  }
  "project" {
    $root = Resolve-RootArgument -RootArg $Arg1
    $validModes = @("auto", "existing", "new")
    $mode = "auto"
    $contextParts = @()
    if ($Arg2) {
      if ($validModes -contains $Arg2.ToLowerInvariant()) {
        $mode = $Arg2
      } else {
        $contextParts += $Arg2
      }
    }
    if ($Arg3) { $contextParts += $Arg3 }
    if ($ArgRest) { $contextParts += $ArgRest }
    $context = ($contextParts -join " ")
    Invoke-MinispecScript -ScriptName "ms-project.ps1" -ScriptArgs @("-Root", $root, "-Mode", $mode, "-Context", $context)
    break
  }
  "close" {
    if (-not $Arg1 -or -not $Arg2) {
      throw "Usage: minispec.ps1 close <change-id> <domain> [root]"
    }
    $changeId = $Arg1
    $domain = $Arg2
    $root = Resolve-RootArgument -RootArg $Arg3
    Invoke-MinispecScript -ScriptName "ms-close.ps1" -ScriptArgs @("-ChangeId", $changeId, "-Domain", $domain, "-Root", $root)
    break
  }
  default {
    throw "Unknown action '$Action'. Use: init | doctor | project | close"
  }
}
