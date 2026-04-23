---
id: 20260423-init-dev-local-gitignore
status: closed
owner: claude
---

# Why

`minispec init` 目前只 scaffold 文件，不管用户的 git 历史。下游项目 git add -A 后会把 `AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` 一股脑带进 commit，而用户的明确偏好是把 minispec 当开发者本地工具（B 模式）——不让这些文件污染团队的 git 历史。

本卡把 B 模式做成默认：init 时写入一段带 marker 的 `.gitignore` 块，幂等、可由 `--no-gitignore` / `-NoGitignore` 关掉。用户想切回团队模式（A 模式）只需删 marker 块。

# Approach

- Considered:
  - **B1 最小**：只在 README 写说明，让用户自己复制 ignore 行进 `.gitignore`。侵入性最低，但摩擦最高，忘记是常态。
  - **B2 auto-default + opt-out**（推荐）：ms-init 默认写 marker 块；`--no-gitignore` 旗标关掉；再跑一次不重复（幂等）。
  - **B3 交互式**：init 时问 "Track in git? [y/N]"。交互式破坏 CI / 管道场景，不符合 minispec 零交互初衷。
- Chosen: **B2**。默认即"不污染"，opt-out 给想自行管理的用户；幂等 + marker 切换让 A 模式的切换成本只是"删一段块"。

# Scope

- In:
  - `scripts/ms-init.sh`：参数解析从单 positional 扩为支持 `--no-gitignore` 任意位置；新增 `write_minispec_gitignore` 函数，幂等追加 marker 块到 `<target>/.gitignore`。
  - `scripts/ms-init.ps1`：新增 `[switch]$NoGitignore` 参数；等价的 `Write-MinispecGitignore` 函数，使用同一 marker 文案。
  - `bin/minispec.ps1` launcher：把 `--no-gitignore` 翻译成 `-NoGitignore` 传给 ms-init.ps1。POSIX launcher 的 `exec sh ... "$@"` 已自然透传，无需改。
  - `README.md` / `README.zh-CN.md`：Quickstart 附一句 `--no-gitignore` 提示；新增 "Tracking minispec in git" 段说明默认行为 + 切回团队模式的方法。
  - `minispec/specs/workflow.md`：新增 `## Bootstrap: init` 小节用 BDD 固化 init + gitignore 行为（init 不在 6-action 里但值得成为契约）。
  - `CHANGELOG.md` Unreleased > Changed 追加一条。
  - `tests/bats/init.bats`（新建）：scaffold / marker 块 / 保留既有内容 / 幂等 / `--no-gitignore` 五条用例。
  - `tests/pester/Init.Tests.ps1`（新建）：等价 Pester 用例。
- Out:
  - 不动其他 action 的语义（project/new/apply/check/close/analyze 保持不变）。
  - 不写 "un-init" 或自动清理逻辑（用户想切回 A 模式自己删 marker 块）。
  - 不改仓库自身的 `.gitignore`（本仓库就是 minispec 源码，不存在"污染"问题）。

# Acceptance

- [x] Given 空目录运行 `sh scripts/ms-init.sh /tmp/demo`，When 检查 `/tmp/demo/.gitignore`，Then 文件存在且含 `# >>> minispec` marker、含 `minispec/`、`AGENTS.md` 等 5 行。
- [x] Given 目标目录已有 `.gitignore`（如含 `node_modules/`），When 跑 init，Then 原有内容保留，marker 块追加在后。
- [x] Given 连续跑两次 init，When grep marker 次数，Then 仅出现 1 次（幂等）。
- [x] Given `sh scripts/ms-init.sh /tmp/demo --no-gitignore`，When 检查 `.gitignore`，Then 文件不存在（或不含 marker）。
- [x] Given Windows `ms-init.ps1 -Root /tmp/demo -NoGitignore`，Then 行为等价。
- [x] Given `minispec init --no-gitignore .`（通过全局 launcher 调用），Then 不写 `.gitignore`（两种平台行为一致）。
- [x] Given 打开 README（中英文），Then 存在 "Tracking minispec in git" 段，描述默认 + 切回团队模式 + `--no-gitignore`。
- [x] Given 打开 `specs/workflow.md`，Then 新增 `## Bootstrap: init` 小节含 4 条 BDD（scaffold、默认 gitignore、no-gitignore、幂等）。
- [x] Given 跑 `sh scripts/ms-doctor.sh .`，Then PASS 且 Guardrails 同步检查无 WARN。

# Plan

- [x] T1 改 `scripts/ms-init.sh`：参数解析 + write_minispec_gitignore。
- [x] T2 改 `scripts/ms-init.ps1`：`-NoGitignore` switch + Write-MinispecGitignore。
- [x] T3 改 `bin/minispec.ps1`：init 分支翻译 `--no-gitignore` → `-NoGitignore`。
- [x] T4 改 `README.md`：Quickstart 注、Tracking in git 段。
- [x] T5 改 `README.zh-CN.md`：同步。
- [x] T6 改 `minispec/specs/workflow.md`：加 `## Bootstrap: init` 小节。
- [x] T7 写 `tests/bats/init.bats`。
- [x] T8 写 `tests/pester/Init.Tests.ps1`。
- [x] T9 CHANGELOG 追加。
- [x] T10 端到端本地验证：模拟 install → `minispec init /tmp/demo` → 确认 `.gitignore` 正确；再 `minispec init /tmp/demo` 验证幂等；再加 `--no-gitignore` 验证跳过。
- [x] T11 close → commit → push。

# Risks and Rollback

- Risk: 用户 `.gitignore` 已有 `minispec/` 但使用了不同的语义（例如指 node_modules 下某个 minispec 包）。Rollback: marker 块独立于已有条目；不合并、不去重，原有条目不会被改。用户看到 `.gitignore` 里重复可以自行清理。
- Risk: heredoc / here-string 的行尾在 Windows 上被 Git 转换成 CRLF，marker 检测用 grep `^# >>> minispec` 仍能匹配（行首锚），不影响幂等判断。Rollback: 若出现 CRLF 相关解析问题，在 marker 检查前 `tr -d '\r'`。
- Risk: 用户某天想把 minispec 切回 A 模式，忘了"删 marker 块"的做法。Rollback: README 明确写切换方法；workflow.md BDD 固化行为；后续可考虑 `minispec init --track` 反向旗标（不在本卡 scope）。

# Notes

- 决策：marker 块包 `AGENTS.md` 与 `CLAUDE.md` 整个屏蔽——而不是只屏蔽 `minispec/`——因为这两个文件直接改变 agent 行为，用户既然选 B 模式就应一并排除，否则 skill 半掉线。
- 决策：幂等检测用 `grep -q '^# >>> minispec'` 匹配首条 marker 行，不关心块内内容——这样未来若扩充 marker 内部条目，已装过的项目不会重复写入。
- 决策：marker 文案统一（两端完全一致），不区分 sh/ps 来源，用户不需要知道 init 是哪个脚本写的。
- 后续候选：若有人抱怨 `--no-gitignore` 太长，可加 `--keep-git` 或 `-k` 短选项——不在本卡 scope。
