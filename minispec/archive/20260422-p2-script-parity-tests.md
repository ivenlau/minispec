---
id: 20260422-p2-script-parity-tests
status: closed
owner: claude
---

# Why

P0-1 已经暴露出 `.sh` 与 `.ps1` 会悄悄漂移。手工每次回归既慢又不可靠，需要自动化：bats（覆盖 `.sh`）+ Pester（覆盖 `.ps1`）+ 共用 fixtures。CI（P2-c）会把它们串成门禁。

# Scope

- In:
  - `tests/fixtures/`：最小可用的 `package.json` / `pyproject.toml` / `go.mod` 样本，用来驱动 detection 检查。
  - `tests/bats/`：三个测试文件 `doctor.bats` / `project.bats` / `close.bats`；覆盖结构检查、语义 WARN、Acceptance-only 扫描、next vs next-sitemap 分辨、合并块形态。
  - `tests/pester/`：`Doctor.Tests.ps1` / `Project.Tests.ps1` / `Close.Tests.ps1` 作为 Pester v5 等价用例（至少覆盖 doctor 的核心路径，project 的 round-trip Maintainer Notes，close 的 Acceptance-only 检查）。
  - `tests/README.md`：说明如何本地跑（bats-core + Pester v5 安装指引）。
- Out:
  - 不跑 CI（由 P2-c 引入）。
  - 不强制 100% 覆盖率，初版覆盖关键路径即可。

# Acceptance

- [x] Given 安装 bats-core，When 执行 `bats tests/bats`，Then 全部测试通过。
- [x] Given 安装 Pester v5，When 执行 `Invoke-Pester tests/pester`，Then 全部测试通过。
- [x] Given 测试文件布局，Then `tests/README.md` 讲清安装、运行、新增用例的模板。
- [x] Given 有 `next-sitemap` fixture 与 `next-real` fixture，When 两端脚本跑过，Then 测试断言 Framework 字段分别为 `Node.js application` 与 `Next.js`。

# Plan

- [x] T1 建 `tests/fixtures/next-real/package.json`、`tests/fixtures/nextish/package.json`、`tests/fixtures/python-fastapi/pyproject.toml`。
- [x] T2 写 `tests/bats/doctor.bats`。
- [x] T3 写 `tests/bats/project.bats`。
- [x] T4 写 `tests/bats/close.bats`。
- [x] T5 写 `tests/pester/Doctor.Tests.ps1`。
- [x] T6 写 `tests/pester/Project.Tests.ps1`。
- [x] T7 写 `tests/pester/Close.Tests.ps1`。
- [x] T8 写 `tests/README.md`。

# Risks and Rollback

- Risk: Windows 上 bats 较难跑（需要 WSL 或 git-bash + bats-core 单独安装）。Rollback: CI 用 ubuntu 跑 bats，Windows 仅跑 Pester。
- Risk: fixture 路径在两端脚本里语义不同（正反斜杠）。Rollback: 测试一律用 forward slash，依赖脚本 Join-Path / `cd` 处理跨平台。

# Notes

- 决策：bats 测试用 `setup()` 建临时目录、`teardown()` 清理；Pester 同理 `BeforeEach` / `AfterEach`。
- 决策：next fixture 的 framework 检查是两端 parity 的代表用例（P0-1 的 regression guard）。
