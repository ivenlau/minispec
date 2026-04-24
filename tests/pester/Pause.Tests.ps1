BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:PausePath  = Join-Path $RepoRoot "scripts/ms-pause.ps1"
  $script:ResumePath = Join-Path $RepoRoot "scripts/ms-resume.ps1"
  $script:DoctorPath = Join-Path $RepoRoot "scripts/ms-doctor.ps1"
  $script:InitPath   = Join-Path $RepoRoot "scripts/ms-init.ps1"
}

Describe "ms-pause.ps1 / ms-resume.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec") -Force | Out-Null
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "pause creates .paused with paused_at" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $PausePath -Root $TestRoot | Out-Null
    $marker = Join-Path $TestRoot "minispec/.paused"
    (Test-Path $marker) | Should -Be $true
    (Get-Content -Raw $marker) | Should -Match "(?m)^paused_at:\s"
  }

  It "pause -Reason writes reason into the marker" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $PausePath -Root $TestRoot -Reason "debug loop" | Out-Null
    $text = Get-Content -Raw (Join-Path $TestRoot "minispec/.paused")
    # Drop the `$` anchor: on Windows PowerShell Set-Content may write CRLF,
    # and .NET regex `(?m)$` matches before \n but leaves \r in front of the
    # anchor, so the match would fail on CRLF content.
    $text | Should -Match "(?m)^reason: debug loop"
  }

  It "pause is idempotent (already paused)" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $PausePath -Root $TestRoot | Out-Null
    $before = Get-Content -Raw (Join-Path $TestRoot "minispec/.paused")
    Start-Sleep -Seconds 1
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $PausePath -Root $TestRoot
    ($out -join "`n") | Should -Match "already paused"
    $after = Get-Content -Raw (Join-Path $TestRoot "minispec/.paused")
    $after | Should -Be $before
  }

  It "resume removes the marker and reports duration" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $PausePath -Root $TestRoot | Out-Null
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $ResumePath -Root $TestRoot
    ($out -join "`n") | Should -Match "resumed"
    (Test-Path (Join-Path $TestRoot "minispec/.paused")) | Should -Be $false
  }

  It "resume without existing marker reports 'not paused'" {
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $ResumePath -Root $TestRoot
    ($out -join "`n") | Should -Match "not paused"
  }
}

Describe "ms-doctor.ps1 pause staleness" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/specs") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/changes") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/archive") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/templates") -Force | Out-Null
    "# Project" | Set-Content -Path (Join-Path $TestRoot "minispec/project.md") -Encoding UTF8
    Copy-Item (Join-Path $RepoRoot "minispec/templates/change.md") (Join-Path $TestRoot "minispec/templates/change.md")
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "does NOT WARN about pause within 4 hours" {
    $ts = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    "paused_at: $ts" | Set-Content -Path (Join-Path $TestRoot "minispec/.paused") -Encoding UTF8
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    ($out -join "`n") | Should -Not -Match "has been paused for"
  }

  It "WARNs about pause older than 4 hours" {
    $ts = [DateTime]::UtcNow.AddHours(-5).ToString("yyyy-MM-ddTHH:mm:ssZ")
    "paused_at: $ts" | Set-Content -Path (Join-Path $TestRoot "minispec/.paused") -Encoding UTF8
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    ($out -join "`n") | Should -Match "has been paused for"
  }
}

Describe "ms-init.ps1 drops minispec/.gitignore" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "creates minispec/.gitignore excluding .paused" {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $InitPath -Root $TestRoot -NoGitignore | Out-Null
    $gi = Join-Path $TestRoot "minispec/.gitignore"
    (Test-Path $gi) | Should -Be $true
    (Get-Content -Raw $gi) | Should -Match "(?m)^\.paused$"
  }
}
