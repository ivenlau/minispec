BeforeAll {
  $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
  $script:ProjectPath = Join-Path $RepoRoot "scripts/ms-project.ps1"
  $script:Fixtures = Join-Path $RepoRoot "tests/fixtures"
}

Describe "ms-project.ps1" {
  BeforeEach {
    $script:TestRoot = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
  }

  AfterEach {
    if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
  }

  Context "detection" {
    It "detects Next.js for a real next package.json" {
      Copy-Item (Join-Path $Fixtures "next-real/package.json") (Join-Path $TestRoot "package.json")
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode existing | Out-Null
      $proj = Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")
      $proj | Should -Match "- Framework: Next\.js"
    }

    It "does NOT detect Next.js for next-sitemap only" {
      Copy-Item (Join-Path $Fixtures "nextish/package.json") (Join-Path $TestRoot "package.json")
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode existing | Out-Null
      $proj = Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")
      $proj | Should -Match "- Framework: Node\.js application"
    }

    It "detects FastAPI with ruff" {
      Copy-Item (Join-Path $Fixtures "python-fastapi/pyproject.toml") (Join-Path $TestRoot "pyproject.toml")
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode existing | Out-Null
      $proj = Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")
      $proj | Should -Match "- Framework: FastAPI"
      $proj | Should -Match "- Lint: ruff check \."
    }
  }

  Context "Maintainer Notes" {
    It "emits Maintainer Notes with marker on fresh generation" {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode new | Out-Null
      $proj = Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")
      $proj | Should -Match "## Maintainer Notes"
      $proj | Should -Match "manual-managed; preserved across ms-project regenerations"
    }

    It "preserves user-added Maintainer Notes on regeneration" {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode new | Out-Null
      Add-Content -Path (Join-Path $TestRoot "minispec/project.md") -Value "`n- custom maintainer rule"
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProjectPath -Root $TestRoot -Mode new | Out-Null
      $proj = Get-Content -Raw (Join-Path $TestRoot "minispec/project.md")
      $proj | Should -Match "- custom maintainer rule"
    }
  }
}
