BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:DoctorPath = Join-Path $RepoRoot "scripts/ms-doctor.ps1"
}

Describe "ms-doctor.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/specs") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/changes") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/archive") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/templates") -Force | Out-Null
    "# Project Contract`n`n## Stack`n- Language: TBD`n" | Set-Content -Path (Join-Path $TestRoot "minispec/project.md") -Encoding UTF8
    Copy-Item (Join-Path $RepoRoot "minispec/templates/change.md") (Join-Path $TestRoot "minispec/templates/change.md")
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  It "fails fast when minispec root is missing" {
    Remove-Item -Recurse -Force (Join-Path $TestRoot "minispec")
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    $LASTEXITCODE | Should -Be 2
    ($output -join "`n") | Should -Match "MISSING"
  }

  It "PASS (exit 0) but WARNs on TBD placeholders" {
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    $LASTEXITCODE | Should -Be 0
    ($output -join "`n") | Should -Match "still contains TBD"
  }

  It "WARNs on unknown status in frontmatter" {
    @"
---
id: 20260421-weird
status: stalled
---
"@ | Set-Content -Path (Join-Path $TestRoot "minispec/changes/20260421-weird.md") -Encoding UTF8

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    ($output -join "`n") | Should -Match "unknown status 'stalled'"
  }

  It "WARNs on orphan archive without matching spec" {
    @"
---
id: 20260422-orphan
status: closed
---
"@ | Set-Content -Path (Join-Path $TestRoot "minispec/archive/20260422-orphan.md") -Encoding UTF8

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $DoctorPath -Root $TestRoot
    ($output -join "`n") | Should -Match "no matching '## Change 20260422-orphan'"
  }
}
