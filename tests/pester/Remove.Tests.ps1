BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:RemovePath = Join-Path $RepoRoot "scripts/ms-remove.ps1"
  $script:InitPath   = Join-Path $RepoRoot "scripts/ms-init.ps1"
}

Describe "ms-remove.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot | Out-Null
    # Plant some cards so removal is observable.
    Set-Content -Path (Join-Path $TestRoot "minispec/archive/20260423-done.md") -Value "archived" -Encoding UTF8
    Set-Content -Path (Join-Path $TestRoot "minispec/specs/checkout.md") -Value "spec content" -Encoding UTF8
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "-Yes deletes everything and strips gitignore marker" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $RemovePath -Target $TestRoot -Yes | Out-Null
    (Test-Path (Join-Path $TestRoot "AGENTS.md")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot "CLAUDE.md")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot ".agents")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot ".claude")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot "minispec")) | Should -Be $false
    if (Test-Path (Join-Path $TestRoot ".gitignore")) {
      (Get-Content -Raw (Join-Path $TestRoot ".gitignore")) | Should -Not -Match "# >>> minispec"
    }
  }

  It "-KeepArchive preserves archive but deletes the rest" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $RemovePath -Target $TestRoot -Yes -KeepArchive | Out-Null
    (Test-Path (Join-Path $TestRoot "minispec/archive")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "minispec/archive/20260423-done.md")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "minispec/specs")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot "minispec/project.md")) | Should -Be $false
    (Test-Path (Join-Path $TestRoot "AGENTS.md")) | Should -Be $false
  }

  It "-DryRun does not delete anything" {
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $RemovePath -Target $TestRoot -DryRun
    ($out -join "`n") | Should -Match "Would delete"
    (Test-Path (Join-Path $TestRoot "minispec")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "AGENTS.md")) | Should -Be $true
  }
}
