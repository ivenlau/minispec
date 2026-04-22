---
id: 20260422-p2-github-actions-ci
status: closed
owner: claude
---

# Why

P2-b 写好了 bats + Pester 套件，但没有 CI 跑它们等于没门禁。新增 GitHub Actions workflow 把 lint + test 跑起来，双脚本漂移会在 PR 阶段就被拦住。

# Scope

- In:
  - `.github/workflows/ci.yml`：
    - `lint` job（ubuntu-latest）：
      - shellcheck 所有 `scripts/*.sh`
      - PSScriptAnalyzer 所有 `scripts/*.ps1`（pwsh 在 ubuntu 上可用）
    - `test-bats` job（ubuntu-latest）：安装 bats-core + 跑 `bats tests/bats`
    - `test-pester` job（windows-latest）：Install Pester v5 + 跑 `Invoke-Pester`
    - 触发：push 到任何分支 + PR 到 main
- Out:
  - 不做 release automation（留给 P2-f）。
  - 不做 coverage 或 fancy reporter——MVP 只是 pass/fail。

# Acceptance

- [x] Given `.github/workflows/ci.yml` 存在，Then 包含 lint / test-bats / test-pester 三个 job。
- [x] Given workflow 触发器，Then 同时覆盖 `push` 与 `pull_request`（默认分支 main）。
- [x] Given ubuntu job，Then 安装并调用 shellcheck 与 PSScriptAnalyzer。
- [x] Given windows job，Then 安装 Pester v5 且运行 tests/pester。

# Plan

- [x] T1 起草 `.github/workflows/ci.yml` 三 job 结构。
- [x] T2 shellcheck + PSScriptAnalyzer 命令写入 lint job。
- [x] T3 bats 安装脚本和 invoke 写入 test-bats。
- [x] T4 Pester v5 安装与 Invoke-Pester 写入 test-pester。

# Risks and Rollback

- Risk: Windows runner 上 Pester v5 与老版本并存时路径解析异常。Rollback: 显式 `Import-Module Pester -MinimumVersion 5.5.0`。
- Risk: shellcheck 对 `[[:space:]]` 等 POSIX 字符类有 false positive。Rollback: 加 `-e SC2076 -e SC2081` 白名单。

# Notes

- 决策：lint 与 test 分开 job，失败时定位更快；没开 matrix 因为 OS 间已经自然分工（lint + bats on ubuntu，Pester on windows）。
- 决策：PSScriptAnalyzer 阈值选 warning；error 才 fail-fast。
