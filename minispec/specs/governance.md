# governance

Canonical shipped behavior for domain: governance


## Change 20260422-p2-governance-files (2026-04-22)

### Why

仓库作为公开项目模板缺三件基本治理文件：LICENSE、CONTRIBUTING.md、CHANGELOG.md。没有 LICENSE 意味着法律上对下游使用者是完全封闭的（默认保留所有权利）；没有 CONTRIBUTING 意味着贡献者不知道该走什么流程；没有 CHANGELOG 意味着升级者看不到 breaking change。

本卡一次补齐，并且 CONTRIBUTING 直接示范 "用 minispec 开发 minispec"（dogfood），降低上手门槛。

### Scope

- In:
  - `LICENSE`：MIT License（minispec 是工作流模板，MIT 最大化采纳面）。
  - `CONTRIBUTING.md`：简介 → 分支策略 → "每个变更先开 change card" 自举 → 本地跑 doctor + bats + Pester → 提 PR 的 checklist。
  - `CHANGELOG.md`：采用 Keep a Changelog 格式；首条 `[Unreleased]` 记录 P0+P1+P2 改造。
- Out:
  - 不改作者署名（要用户本地 git config 来定）。
  - 不加 CODE_OF_CONDUCT（可选，后续卡）。

### Acceptance

- [x] Given 打开 `LICENSE`，Then 是 MIT 全文，`Copyright (c) 2026 minispec contributors`。
- [x] Given 打开 `CONTRIBUTING.md`，Then 明确写"贡献者在本仓库的变更也走 minispec 六 action 流程"，并列出本地测试命令。
- [x] Given 打开 `CHANGELOG.md`，Then 首条 `[Unreleased]` 小节按 Added / Changed / Fixed 三类分组，覆盖 P0-a..P2-f 关键动作。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-governance-files.md`
- See `minispec/archive/20260422-p2-governance-files.md` for plan and risk notes.

- 决策：CHANGELOG 仅标 `[Unreleased]`，不立即打版本号——版本号留给 P2-f 引入 VERSION 文件与 tag 策略时一起落地。
