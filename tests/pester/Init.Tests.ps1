BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:InitPath = Join-Path $RepoRoot "scripts/ms-init.ps1"
}

Describe "ms-init.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "scaffolds the contract tree" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    (Test-Path (Join-Path $TestRoot "minispec/specs")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "minispec/templates/change.md")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot ".claude/skills/minispec/SKILL.md")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "AGENTS.md")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "CLAUDE.md")) | Should -Be $true
  }

  It "appends the minispec marker block to .gitignore by default" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    $gi = Join-Path $TestRoot ".gitignore"
    (Test-Path $gi) | Should -Be $true
    # Split into trimmed lines so CRLF vs LF line endings don't break anchored regex.
    $lines = (Get-Content -Path $gi -Encoding UTF8) | ForEach-Object { $_.TrimEnd() }
    $lines | Should -Contain "minispec/"
    $lines | Should -Contain "AGENTS.md"
    $lines | Should -Contain ".claude/"
    ($lines -join "`n") | Should -Match "# >>> minispec"
  }

  It "preserves existing .gitignore content" {
    $gi = Join-Path $TestRoot ".gitignore"
    "node_modules/`n*.log`n" | Set-Content -Path $gi -NoNewline
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    $text = Get-Content -Raw -Path $gi
    $text | Should -Match "node_modules/"
    $text | Should -Match "# >>> minispec"
  }

  It "is idempotent across repeated runs" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    $text = Get-Content -Raw -Path (Join-Path $TestRoot ".gitignore")
    $opts = [System.Text.RegularExpressions.RegexOptions]::Multiline
    $count = ([regex]::Matches($text, "^# >>> minispec", $opts)).Count
    $count | Should -Be 1
  }

  It "-NoGitignore skips the .gitignore write" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot -NoGitignore | Out-Null
    (Test-Path (Join-Path $TestRoot ".gitignore")) | Should -Be $false
  }

  It "-NoGitignore leaves an existing .gitignore untouched" {
    $gi = Join-Path $TestRoot ".gitignore"
    "node_modules/`n" | Set-Content -Path $gi -NoNewline
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot -NoGitignore | Out-Null
    $text = Get-Content -Raw -Path $gi
    $text | Should -Not -Match "# >>> minispec"
    $text | Should -Match "node_modules/"
  }
}
