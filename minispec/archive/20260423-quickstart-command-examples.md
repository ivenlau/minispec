---
id: 20260423-quickstart-command-examples
status: closed
owner: claude
---

# Why

README 的 Quickstart A/B 两节有几步是纯文字描述（"Generate project.md (guided or context-driven) directly."、"Create first change." 等），没有可复制的命令。读者装完 CLI 后，看到步骤但不知道具体敲什么。用户明确要求在这些描述下方补上命令示例——以 AI CLI 形态为主（`minispec <action>`），脚本 fallback 为辅。

# Approach

单一合理路径：沿用 README 现有的"Utility Scripts"段落已经建立的"CLI 首选、脚本 fallback"规范，把每一步补上 3 种形态：

1. `minispec <action>` — 既是 AI CLI 里和 agent 说的话，也是装好 CLI 后命令行直接能跑的。
2. `sh scripts/ms-*.sh` — POSIX 脚本 fallback。
3. `powershell -File scripts/ms-*.ps1 …` — PowerShell fallback。

无替代方案可比——结构、顺序、命名都已定。不再 propose 多选。

# Scope

- In:
  - `README.md` Quickstart A.1 / A.2 / A.3 / A.4 / B.1 / B.2 / B.3 各补命令块。
  - `README.zh-CN.md` 同步等价段落。
  - 保留原有描述性文字不动（解释仍是主体，命令是补充）。
- Out:
  - 不改 C（AI CLI 环境说明）/ D（close criteria）/ E（doctor and auto close）/ F（analyze）段——它们本来就有命令或不需要。
  - 不改顶层 Install / Quickstart 三步总览——那里已有命令。
  - 不改 Workflow 段或 CLI Syntax 段——它们是契约说明，不是手把手教程。

# Acceptance

- [x] Given 打开 README.md 的 `### A. New Project` 小节，Then 每个数字步骤下方都至少有一个 fenced code block 命令示例；`minispec <action>` 形态在前、脚本 fallback 在后。
- [x] Given `### B. Existing Project` 小节同样满足上一条。
- [x] Given `minispec project` 的命令示例，Then 包含带 context 的形式（如 `minispec project . auto "TypeScript Next.js app"`）而不是只有无参数版。
- [x] Given `minispec new` 的命令示例，Then 清楚表明是 "在 AI CLI 里让 agent 跑" 这件事（不是 shell 里直接跑）。
- [x] Given README.zh-CN.md 对应小节，Then 中文版有等价的命令块（命令本身保持英文，说明文字中文）。
- [x] Given `sh scripts/ms-doctor.sh .`，Then Result PASS 且 Guardrails 无 WARN。

# Plan

- [x] T1 改 `README.md` A.1：`minispec init .` 作主命令、sh/ps 作 fallback 脚注。
- [x] T2 改 `README.md` A.2：`minispec project . auto "<context>"` 主，sh/ps fallback。
- [x] T3 改 `README.md` A.3：补 `$EDITOR minispec/project.md`。
- [x] T4 改 `README.md` A.4：`minispec new <idea>`（AI CLI 内调）+ 手动模板复制 fallback。
- [x] T5 改 `README.md` B.1：`minispec doctor .` 主，fallback。
- [x] T6 改 `README.md` B.2：同 A.2，强调带 context 的用法。
- [x] T7 改 `README.md` B.3：补编辑命令。
- [x] T8 README.zh-CN.md 同步上述所有改动（章节顺序对齐、命令块逐字一致）。
- [x] T9 close + commit + push。

# Risks and Rollback

- Risk: 中英文两版 Quickstart 将来可能不同步漂移。Rollback: 已在 CHANGELOG 明示了"英文是权威版本"，后续若不同步，以英文为准。
- Risk: `$EDITOR` 变量 Windows 用户不熟。Rollback: 加一行备注"Windows 可用 `notepad` / VS Code `code` 代替"。

# Notes

- 决策：主命令一律用 `minispec <action>` 形态，即使示例上下文是 AI CLI——这样"在 agent 里让他跑" 和 "你自己在 shell 里跑" 的语法 100% 一致，用户心智模型只需要记一套。
- 决策：脚本 fallback 用 `powershell -File` 而不是早先示例里的 `powershell -Command "& '...' -Root ."`——更简洁，Windows PowerShell 5.1 和 7.x 都支持。
