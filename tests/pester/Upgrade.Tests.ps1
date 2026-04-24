BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:UpgradePath = Join-Path $RepoRoot "scripts/ms-upgrade.ps1"
  $script:InitPath    = Join-Path $RepoRoot "scripts/ms-init.ps1"
}

Describe "ms-upgrade.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot -NoGitignore | Out-Null
    # Plant business content.
    Set-Content -Path (Join-Path $TestRoot "minispec/project.md") -Value "MY REAL PROJECT CONTRACT" -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/specs") -Force | Out-Null
    Set-Content -Path (Join-Path $TestRoot "minispec/specs/checkout.md") -Value "my canonical spec" -Encoding UTF8
    Set-Content -Path (Join-Path $TestRoot "minispec/changes/20260424-active.md") -Value "draft card" -Encoding UTF8
    Set-Content -Path (Join-Path $TestRoot "minispec/archive/20260423-done.md") -Value "archived card" -Encoding UTF8
    Set-Content -Path (Join-Path $TestRoot "AGENTS.md") -Value "OUTDATED AGENT FILE" -Encoding UTF8
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "refreshes AGENTS.md from source" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $UpgradePath -Target $TestRoot -Source $RepoRoot | Out-Null
    $text = Get-Content -Raw (Join-Path $TestRoot "AGENTS.md")
    $text | Should -Not -Match "OUTDATED AGENT FILE"
  }

  It "leaves project.md untouched" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $UpgradePath -Target $TestRoot -Source $RepoRoot | Out-Null
    (Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")).Trim() | Should -Be "MY REAL PROJECT CONTRACT"
  }

  It "leaves specs/changes/archive untouched" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $UpgradePath -Target $TestRoot -Source $RepoRoot | Out-Null
    (Get-Content -Raw (Join-Path $TestRoot "minispec/specs/checkout.md")).Trim() | Should -Be "my canonical spec"
    (Get-Content -Raw (Join-Path $TestRoot "minispec/changes/20260424-active.md")).Trim() | Should -Be "draft card"
    (Get-Content -Raw (Join-Path $TestRoot "minispec/archive/20260423-done.md")).Trim() | Should -Be "archived card"
  }

  It "-DryRun does not modify files" {
    Set-Content -Path (Join-Path $TestRoot "AGENTS.md") -Value "OUTDATED AGENT FILE" -Encoding UTF8
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $UpgradePath -Target $TestRoot -Source $RepoRoot -DryRun
    ($out -join "`n") | Should -Match "would update"
    (Get-Content -Raw (Join-Path $TestRoot "AGENTS.md")).Trim() | Should -Be "OUTDATED AGENT FILE"
  }
}
