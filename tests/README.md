# minispec tests

Parallel test suites for the two script flavours. `bats` covers `scripts/*.sh`; Pester v5 covers `scripts/*.ps1`. Both suites read the same fixtures under `tests/fixtures/`.

## Install

### bats-core (POSIX shell)

```sh
# ubuntu / debian
sudo apt-get install -y bats

# macOS
brew install bats-core

# from source (all platforms)
git clone https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local
```

### Pester v5 (PowerShell 7+)

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

## Run

### bats

```sh
bats tests/bats
```

### Pester

```powershell
Invoke-Pester tests/pester -Output Detailed
```

## Add a new test

1. **Decide the surface**: script behavior goes into the matching `tests/bats/<script>.bats` and `tests/pester/<Script>.Tests.ps1`. Keep assertions mirrored — when adding a bats test, add the Pester equivalent in the same change card.
2. **Use fixtures over inline JSON**: when a test needs a `package.json`, `pyproject.toml`, etc., add a minimal sample under `tests/fixtures/<name>/` and reference it from both suites.
3. **Keep each test self-contained**: `setup`/`BeforeEach` creates a fresh temp dir, tests operate on it, `teardown`/`AfterEach` removes it. Do NOT mutate the repo itself during tests.
4. **Pattern for parity regressions**: when fixing a bug that affected only one side (e.g. P0-1 detection drift), add the exact failing scenario to both suites before fixing code — the test is the regression guard.

## What's covered today

- `doctor.bats` / `Doctor.Tests.ps1`: structural FAIL, TBD WARN, filename / status / cross-ref WARNs.
- `project.bats` / `Project.Tests.ps1`: Next.js vs `next-sitemap` parity, FastAPI detection, Maintainer Notes preservation round-trip.
- `close.bats` / `Close.Tests.ps1`: Acceptance-only gate, merged-spec cross-reference line, archive collision guard.

Roadmap (not yet covered): `ms-init` scaffolding, `analyze` output (agent-driven, may stay out of scope), SKILL Guardrails parity end-to-end via doctor.
