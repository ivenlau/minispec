BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:ClosePath = Join-Path $RepoRoot "scripts/ms-close.ps1"
}

BeforeEach {
  $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
  New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/specs") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/changes") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TestRoot "minispec/archive") -Force | Out-Null
}

AfterEach {
  if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
}

function New-TestCard {
  param([string]$Id, [string]$Body)
  $path = Join-Path $TestRoot "minispec/changes/$Id.md"
  $Body | Set-Content -Path $path -Encoding UTF8
  return $path
}

Describe "ms-close.ps1" {
  It "succeeds when Acceptance is ticked (Plan unchecked)" {
    New-TestCard -Id "20260422-case-a" -Body @"
---
id: 20260422-case-a
status: draft
---

# Why

plan unchecked but acceptance checked should close.

# Acceptance

- [x] Given X When Y Then Z

# Plan

- [ ] T1 pending
"@

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $ClosePath -ChangeId "20260422-case-a" -Domain "testdomain" -Root $TestRoot
    $LASTEXITCODE | Should -Be 0
    (Test-Path (Join-Path $TestRoot "minispec/archive/20260422-case-a.md")) | Should -Be $true
    (Test-Path (Join-Path $TestRoot "minispec/changes/20260422-case-a.md")) | Should -Be $false
  }

  It "fails when Acceptance has any unchecked item" {
    New-TestCard -Id "20260422-case-b" -Body @"
---
id: 20260422-case-b
status: draft
---

# Acceptance

- [ ] Given unchecked

# Plan

- [x] T1 done
"@

    { & pwsh -NoProfile -ExecutionPolicy Bypass -File $ClosePath -ChangeId "20260422-case-b" -Domain "testdomain" -Root $TestRoot 2>&1 | Out-Null } |
      Should -Not -Throw
    $LASTEXITCODE | Should -Not -Be 0
  }

  It "merged spec contains archive cross-reference line" {
    New-TestCard -Id "20260422-case-c" -Body @"
---
id: 20260422-case-c
status: draft
---

# Why

cross-ref test.

# Acceptance

- [x] Given ok Then ok

# Plan

- [x] T1 done
"@

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $ClosePath -ChangeId "20260422-case-c" -Domain "testdomain" -Root $TestRoot | Out-Null
    $spec = Get-Content -Raw (Join-Path $TestRoot "minispec/specs/testdomain.md")
    $spec | Should -Match "Auto-merged from ``minispec/changes/20260422-case-c\.md``"
    $spec | Should -Match "See ``minispec/archive/20260422-case-c\.md`` for plan and risk notes\."
  }
}
