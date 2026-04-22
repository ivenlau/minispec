---
id: 20260422-p0-readme-cli-consistency
status: closed
owner: claude
---

# Why

`README.md` 的 "Use In AI CLI (Codex/Claude)" 小节为两种环境给出的示例命令不等价：

- Codex：`minispec project . auto nextjs saas app`（4 个位置参数：root、mode、context...）
- Claude：`minispec project nextjs saas app`（仅 context）
- Codex：`minispec analyze deep .`
- Claude：`minispec analyze deep`

这让读者以为两个平台的调用约定不同，进而要记两套姿势。实际上 action 的位置参数契约是通用的，CLI 环境差异只在入口文件名（AGENTS.md vs CLAUDE.md）与 skill 位置，不在命令语法。

# Scope

- In:
  - `README.md`：
    - 在 Workflow 小节后加一条 "CLI Syntax" 子节，声明统一语法 `minispec <action> [root] [mode] [context...]`，说明 `root` 默认 `.`、`mode` 默认 `auto`。
    - 把 "Use In AI CLI (Codex/Claude)" 下两段示例命令写成完全一致的形式（省略 `root`/`mode` 保持简洁），只在上下文说明环境差异。
- Out:
  - 不修改实际脚本参数解析逻辑（脚本已支持两种姿势）。
  - 不改 `Utility Scripts` 小节的命令演示。

# Acceptance

- [x] Given 阅读 README 的 Workflow 段，When 看到一条 "CLI Syntax" 或等价描述，Then 明确给出 `minispec <action> [root] [mode] [context...]`。
- [x] Given 对比 README 中 Codex 与 Claude 两个示例列表，Then `minispec project …`、`minispec analyze …` 等命令的写法逐字一致。
- [x] Given 读者按任一示例操作，When agent 读取同样的参数，Then 行为与 Codex/Claude 一致（脚本端不区分环境）。

# Plan

- [x] T1 README Workflow 小节末追加 "CLI Syntax" 子节。
- [x] T2 改写 "Use In AI CLI (Codex/Claude)" 下两段示例为完全一致的命令列表。
- [x] T3 grep 核对两段命令逐字相等。

# Risks and Rollback

- Risk: 简化为 `minispec project nextjs saas app`（省略 root/mode）可能误导部分用户以为脚本不能传 root/mode。Rollback: 在 CLI Syntax 中明示可省略，并在示例下加一行 "or with explicit root and mode: `minispec project . auto nextjs saas app`"。

# Notes

- 决策：示例以 agent 视角的"简短命令"为默认形态；脚本形态保留在 Utility Scripts 段作为 fallback 演示。
