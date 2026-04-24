# minispec launcher (Windows PowerShell) — dispatches actions to scripts/ms-*.ps1
#
# Resolution of the minispec install root:
#   1. $env:MINISPEC_HOME if set.
#   2. <this-script-dir>\..                 (when running inside the source repo, bin\ sibling to scripts\).
#   3. %USERPROFILE%\.minispec              (default Windows install location).
[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = "Stop"

function Resolve-ShareDir {
  if ($env:MINISPEC_HOME -and (Test-Path (Join-Path $env:MINISPEC_HOME "scripts"))) {
    return (Resolve-Path $env:MINISPEC_HOME).Path
  }
  $selfDir = Split-Path -Parent $PSCommandPath
  $repoLayout = Join-Path $selfDir ".."
  if ((Test-Path (Join-Path $repoLayout "scripts")) -and (Test-Path (Join-Path $repoLayout "minispec"))) {
    return (Resolve-Path $repoLayout).Path
  }
  $userDefault = Join-Path $env:USERPROFILE ".minispec"
  if (Test-Path (Join-Path $userDefault "scripts")) {
    return (Resolve-Path $userDefault).Path
  }
  throw "minispec: cannot locate install root. Set MINISPEC_HOME or reinstall."
}

function Show-Help {
@'
minispec - lightweight spec-first AI coding workflow

Usage: minispec <action> [args]

Script-backed actions:
  init <dir>                   Scaffold minispec/ contract in <dir>.
  doctor [<dir>]               Check structure and semantic health.
  project [<dir>] [mode] [ctx] Generate/refresh minispec/project.md (agent-preferred; this is the script fallback).
  close <id> <domain> [<dir>]  Close a change card and merge to specs/<domain>.md.
  pause [--reason "<text>"]    Temporarily disable the workflow (agents skip ceremony).
  resume                       Re-enable the workflow.

Lifecycle commands:
  upgrade [<dir>]              Refresh agent files in <dir> from the installed CLI share.
  remove [<dir>] [--yes]       Delete minispec scaffolding from <dir> (destructive; prompts by default).
  uninstall [--yes]            Remove the global minispec CLI (deletes launcher + install directory + PATH entry).

Agent-driven actions (CLI prints guidance only):
  new <idea>                   Create a change card from an idea.
  apply <change-id>            Implement the plan.
  check <change-id>            Validate acceptance + run test/lint.
  analyze <quick|normal|deep>  Refresh canonical analysis specs.

Meta:
  --version, -v                Print minispec version.
  --help, -h                   Print this help.

Environment:
  MINISPEC_HOME                Installation root (default: auto-detect).

Examples:
  minispec init .
  minispec doctor .
  minispec close 20260422-foo scripts .
'@
}

function Show-AgentHint($Action, $Rest) {
  $joined = ($Rest -join ' ')
@"
minispec: '$Action' is an agent-driven action.

Run it inside your AI CLI (Claude Code, Codex, or similar) so the agent can
read .claude/skills/minispec/SKILL.md or .agents/skills/minispec/SKILL.md and
execute the workflow correctly. For example, in your AI CLI:

  minispec $Action $joined

The CLI wrapper deliberately does not implement these actions so the agent
remains the source of truth for Why/Scope/Acceptance decisions.
"@
}

$shareDir = Resolve-ShareDir
$scriptsDir = Join-Path $shareDir "scripts"

if (-not $Args) { $Args = @() }
$action = if ($Args.Count -gt 0) { $Args[0] } else { "" }
$rest = if ($Args.Count -gt 1) { $Args[1..($Args.Count - 1)] } else { @() }

switch -Regex ($action) {
  '^$|^--help$|^-h$' {
    Show-Help
    exit 0
  }
  '^--version$|^-v$' {
    $vf = Join-Path $shareDir "VERSION"
    if (Test-Path $vf) {
      (Get-Content -Path $vf -Raw).Trim()
    } else {
      "unknown"
    }
    exit 0
  }
  '^init$' {
    $targetRoot = "."
    $noGit = $false
    foreach ($t in $rest) {
      if ($t -eq "--no-gitignore" -or $t -eq "-NoGitignore") {
        $noGit = $true
      } elseif (-not $t.StartsWith("-")) {
        $targetRoot = $t
      }
    }
    if ($noGit) {
      & (Join-Path $scriptsDir "ms-init.ps1") -Root $targetRoot -NoGitignore
    } else {
      & (Join-Path $scriptsDir "ms-init.ps1") -Root $targetRoot
    }
    exit $LASTEXITCODE
  }
  '^doctor$' {
    if ($rest -contains "--version" -or $rest -contains "-v") {
      & (Join-Path $scriptsDir "ms-doctor.ps1") -Version
    } else {
      $rootArg = if ($rest.Count -gt 0) { $rest[0] } else { "." }
      & (Join-Path $scriptsDir "ms-doctor.ps1") -Root $rootArg
    }
    exit $LASTEXITCODE
  }
  '^project$' {
    $rootArg = if ($rest.Count -gt 0) { $rest[0] } else { "." }
    $modeArg = if ($rest.Count -gt 1) { $rest[1] } else { "auto" }
    $ctxArg = if ($rest.Count -gt 2) { ($rest[2..($rest.Count - 1)] -join " ") } else { "" }
    & (Join-Path $scriptsDir "ms-project.ps1") -Root $rootArg -Mode $modeArg -Context $ctxArg
    exit $LASTEXITCODE
  }
  '^close$' {
    if ($rest.Count -lt 2) {
      Write-Error "Usage: minispec close <change-id> <domain> [<root>]"
      exit 1
    }
    $cid = $rest[0]
    $dom = $rest[1]
    $rt  = if ($rest.Count -gt 2) { $rest[2] } else { "." }
    & (Join-Path $scriptsDir "ms-close.ps1") -ChangeId $cid -Domain $dom -Root $rt
    exit $LASTEXITCODE
  }
  '^pause$' {
    $targetRoot = "."
    $reason = ""
    for ($i = 0; $i -lt $rest.Count; $i++) {
      $t = $rest[$i]
      if ($t -eq "--reason" -or $t -eq "-Reason") {
        if ($i + 1 -lt $rest.Count) { $reason = $rest[$i + 1]; $i++ }
      } elseif ($t -like "--reason=*") {
        $reason = $t.Substring("--reason=".Length)
      } elseif (-not $t.StartsWith("-")) {
        $targetRoot = $t
      }
    }
    if ($reason) {
      & (Join-Path $scriptsDir "ms-pause.ps1") -Root $targetRoot -Reason $reason
    } else {
      & (Join-Path $scriptsDir "ms-pause.ps1") -Root $targetRoot
    }
    exit $LASTEXITCODE
  }
  '^resume$' {
    $targetRoot = if ($rest.Count -gt 0) { $rest[0] } else { "." }
    & (Join-Path $scriptsDir "ms-resume.ps1") -Root $targetRoot
    exit $LASTEXITCODE
  }
  '^upgrade$' {
    $targetRoot = "."
    $extraArgs = @()
    for ($i = 0; $i -lt $rest.Count; $i++) {
      $t = $rest[$i]
      switch -Regex ($t) {
        '^--dry-run$|^-DryRun$'                 { $extraArgs += "-DryRun"; continue }
        '^--include-template$|^-IncludeTemplate$' { $extraArgs += "-IncludeTemplate"; continue }
        '^--include-gitignore$|^-IncludeGitignore$' { $extraArgs += "-IncludeGitignore"; continue }
        '^--include-canonical-skill$|^-IncludeCanonicalSkill$' { $extraArgs += "-IncludeCanonicalSkill"; continue }
        default {
          if (-not $t.StartsWith("-")) { $targetRoot = $t }
        }
      }
    }
    & (Join-Path $scriptsDir "ms-upgrade.ps1") -Target $targetRoot -Source $shareDir @extraArgs
    exit $LASTEXITCODE
  }
  '^remove$' {
    $targetRoot = "."
    $extraArgs = @()
    for ($i = 0; $i -lt $rest.Count; $i++) {
      $t = $rest[$i]
      switch -Regex ($t) {
        '^--yes$|^-y$|^-Yes$'               { $extraArgs += "-Yes"; continue }
        '^--keep-archive$|^-KeepArchive$'   { $extraArgs += "-KeepArchive"; continue }
        '^--keep-specs$|^-KeepSpecs$'       { $extraArgs += "-KeepSpecs"; continue }
        '^--dry-run$|^-DryRun$'             { $extraArgs += "-DryRun"; continue }
        default {
          if (-not $t.StartsWith("-")) { $targetRoot = $t }
        }
      }
    }
    & (Join-Path $scriptsDir "ms-remove.ps1") -Target $targetRoot @extraArgs
    exit $LASTEXITCODE
  }
  '^uninstall$' {
    $uninstallPath = Join-Path $shareDir "uninstall.ps1"
    if (-not (Test-Path $uninstallPath)) {
      Write-Error "minispec: uninstall.ps1 not found at $shareDir"
      exit 1
    }
    $extraArgs = @()
    for ($i = 0; $i -lt $rest.Count; $i++) {
      $t = $rest[$i]
      switch -Regex ($t) {
        '^--yes$|^-y$|^-Yes$'       { $extraArgs += "-Yes"; continue }
        '^--dry-run$|^-DryRun$'     { $extraArgs += "-DryRun"; continue }
        '^--prefix$|^-Prefix$' {
          if ($i + 1 -lt $rest.Count) { $extraArgs += @("-Prefix", $rest[$i + 1]); $i++ }
          continue
        }
      }
    }
    & $uninstallPath @extraArgs
    exit $LASTEXITCODE
  }
  '^(new|apply|check|analyze)$' {
    Show-AgentHint $action $rest
    exit 0
  }
  default {
    Write-Error "minispec: unknown action '$action'. Run 'minispec --help'."
    exit 1
  }
}
