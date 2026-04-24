---
id: 20260424-lifecycle-commands
status: closed
owner: claude
---

# Why

minispec 当前只有"装进去"（`install.sh` / `install.ps1` + `minispec init`）的命令，没有：
1. **升级已有项目里的 minispec 文件**（手动 copy 易误伤 `minispec/project.md` / `specs/`）
2. **从项目彻底撤掉 minispec**（删 `AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` + 根 `.gitignore` 的 marker 块）
3. **卸载全局 CLI**（删 launcher + share 目录 + Windows user PATH 条目）

用户上一轮明确要求这三件事一并补上。三者都是安装生命周期的一部分，合并成一张卡推进。

# Approach

- Considered:
  - **A. 三张独立卡**：每个命令一张，scope 最细。但三者在脚本结构、flag 设计、交互确认上高度相似——三张卡会重复铺垫。
  - **B. 一张大卡，统一 lifecycle 命令**（选中）：共享交互确认模式、共享 `--yes` / `--dry-run` 语义、共享跨平台 shell+ps1 parity。
  - **C. 先做 upgrade，remove/uninstall 后续跟进**：upgrade 价值最高（升级后没 upgrade 等于靠 `cp` 猜），但用户明确要求 3 件事。
- Chosen: **B**。一张卡统一设计，保证三个命令的 UX 一致。

关键默认：
- `upgrade` 默认只刷 4 个 agent 文件（最不会误伤）；业务相关内容由 opt-in flag 打开。
- `remove` / `uninstall` 默认**交互确认**（非 TTY 环境时要求 `--yes`）；destructive 命令不该突然吞一切。
- `uninstall` 同时提供**独立 bootstrap 脚本** `uninstall.sh` / `uninstall.ps1`（镜像 `install.sh` 的 curl-pipe 姿势），因为"CLI 已坏/已升坏"的场景下还能用。

# Scope

- In:
  - **新脚本**：
    - `scripts/ms-upgrade.sh` / `.ps1`：从 `<share_dir>` 复制 agent 文件到 `<target>`；opt-in flag 控制范围；`--dry-run` 列出会改的文件不写。
    - `scripts/ms-remove.sh` / `.ps1`：删 `<target>/{AGENTS.md,CLAUDE.md,.agents,.claude,minispec}` + 根 `.gitignore` 的 marker 块；交互确认；`--keep-archive` / `--keep-specs` / `--yes` / `--dry-run`。
    - `uninstall.sh` / `uninstall.ps1`（仓库根，镜像 install.sh 的位置）：删 launcher + share 目录 + Windows PATH 条目；`--yes` / `--prefix` / `--dry-run`。
  - **Launcher 更新**：`bin/minispec` 和 `bin/minispec.ps1` 加 `upgrade` / `remove` / `uninstall` 三个 action 分支。`uninstall` 子命令调 `uninstall.sh` / `.ps1`（优先仓库根，回退 share 里的同名副本）。
  - **SKILL**：三份 SKILL 的 `## Commands` 小节末尾追加一个"Lifecycle commands"子项（列这 3 个 + install + init 作为对比），不进入 `## Behavior` — 它们不是 agent-driven。
  - **Spec**：`minispec/specs/workflow.md` 加 `## Lifecycle: install / init / upgrade / remove / uninstall` 小节用 BDD 固化每个命令的语义。
  - **README（中英）**：新增 "Upgrading and removing" 段。
  - **CHANGELOG**：Unreleased > Added 追加。
  - **测试**：
    - `tests/bats/upgrade.bats`：上游 fixture → init → 改 SKILL → upgrade → 断言被刷。业务文件保留。
    - `tests/bats/remove.bats`：init → `remove --yes` → 断言目录全清；`--keep-archive` 保留。
    - `tests/pester/Upgrade.Tests.ps1` / `Remove.Tests.ps1`：对等。
    - `uninstall` 本身由于改 user PATH 难自动测；脚本写 `--dry-run` 路径一测。
- Out:
  - **不做 `minispec upgrade` 的版本号 diff**（要求 project 里有 version 字段，暂缓）。
  - **不做"自动 backup"**（remove / uninstall 前不自动 tar）——用户期待 `--yes` 真的无拖泥带水；需要备份的人应该先手动 backup。
  - 不改 `install.sh` / `install.ps1`（已经 idempotent，算"升级 CLI 本体"）。

# Acceptance

## upgrade

- [x] Given 一个下游项目（已跑过 init），When `minispec upgrade <dir>`，Then `AGENTS.md` / `CLAUDE.md` / `.claude/skills/minispec/SKILL.md` / `.agents/skills/minispec/SKILL.md` 内容被覆盖为 share 目录的当前版本；`minispec/project.md` / `specs/*.md` / `changes/*.md` / `archive/*.md` 字节级不变。
- [x] Given `--dry-run`，Then 打印"would update: <file>..."但磁盘无变化。
- [x] Given `--include-template`，Then `minispec/templates/change.md` 也被刷。
- [x] Given `--include-gitignore`，Then `minispec/.gitignore` 也被刷。

## remove

- [x] Given 已 init 的项目，When `minispec remove <dir> --yes`，Then `<dir>/AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` 全被删除；若根 `.gitignore` 含 minispec marker 块，该块也被删除。
- [x] Given `--keep-archive`，Then 保留 `minispec/archive/` 及其内容，其他照删。
- [x] Given `--dry-run`，Then 打印"would remove: <path>..."但磁盘无变化。
- [x] Given 无 `--yes` 且 stdin 是 pipe（非 TTY），When 跑 `minispec remove`，Then refuse 并提示 "non-interactive — pass --yes to proceed"。
- [x] Given 无 `--yes` 且是 TTY，When 跑，Then 打印待删文件列表 + `Continue? [y/N]` 提示。

## uninstall

- [x] Given 装好的 CLI，When `minispec uninstall --yes`，Then 删 launcher 可执行 + share 目录整棵树。
- [x] Given Windows，When `minispec uninstall --yes`，Then user PATH 中的 `%USERPROFILE%\.minispec\bin` 条目被移除。
- [x] Given `--dry-run`，Then 打印要删什么、要改哪条 PATH，不动磁盘。
- [x] Given 独立调用：`sh uninstall.sh --yes` 或 `irm .../uninstall.ps1 | iex` 带 `--yes`，Then 行为等价。

# Plan

- [x] T1 `scripts/ms-upgrade.sh`（POSIX）
- [x] T2 `scripts/ms-upgrade.ps1`
- [x] T3 `scripts/ms-remove.sh`
- [x] T4 `scripts/ms-remove.ps1`
- [x] T5 `uninstall.sh`（仓库根）
- [x] T6 `uninstall.ps1`（仓库根）
- [x] T7 `bin/minispec` 添加 upgrade/remove/uninstall dispatch
- [x] T8 `bin/minispec.ps1` 同步
- [x] T9 三份 SKILL 的 `## Commands` 加 Lifecycle commands
- [x] T10 `minispec/specs/workflow.md` 新增 `## Lifecycle` 小节 BDD
- [x] T11 README / README.zh-CN 加 "Upgrading and removing"
- [x] T12 CHANGELOG Unreleased > Added
- [x] T13 `tests/bats/upgrade.bats` + `remove.bats`
- [x] T14 `tests/pester/Upgrade.Tests.ps1` + `Remove.Tests.ps1`
- [x] T15 本机端到端：模拟 install + init 下游项目 → upgrade（验证业务文件不动）→ remove（含 marker 块清理）→ uninstall（dry-run，避免真卸载本机 CLI）
- [x] T16 close → commit → push

# Risks and Rollback

- Risk: `remove` 误删用户真的想保留的 archive。Rollback: 默认行为保留 archive？不——"remove"就应该 remove，用户想留由 `--keep-archive` 表达意图。若反馈不好再调。
- Risk: `uninstall` 改 user PATH 失败（权限 / registry corruption）。Rollback: 脚本先备份当前 PATH 到 `%USERPROFILE%\.minispec-path-backup.txt` 再写，出问题有参考。
- Risk: `upgrade` 在用户把 `AGENTS.md` 改成 codex 自定义版的情况下被覆盖。Rollback: 此时提示用户"改了"并让其 `--force`，或加 `--check` 只报告不改；本卡只做 MVP（直接覆盖，用户 git 里有历史）。
- Risk: 独立 `uninstall.sh` 通过 `curl | sh` 在 Pipe 模式下仍需 `--yes`。Rollback: 已在 Acceptance 要求了 non-TTY refuse 行为。

# Notes

- 决策：`remove` 默认删 archive，因为"我要从项目彻底移除 minispec"最常见的理解就是"全都删"；保留需求由 `--keep-archive` 明示。
- 决策：`uninstall` 独立脚本放仓库根（与 `install.sh` 对称），不是 `scripts/` 下——用户 `curl | sh` 时可以和 install 一个姿势找到。
- 决策：`upgrade` 不默认刷 `minispec/.gitignore` 和 `minispec/SKILL.md`（canonical）。前者用户常自定义（加规则），后者 downstream 不必要。通过显式 flag opt-in。
- 决策：安装生命周期的 5 个命令——install（curl | sh）、init、upgrade、remove、uninstall——在 workflow.md 合并为一个 `## Lifecycle` 小节讲清关系；SKILL `## Commands` 只加一行标注，不深入。
