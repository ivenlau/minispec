---
id: 20260423-clarify-and-propose-in-new
status: closed
owner: claude
---

# Why

minispec 的 `new` 动作当前只要求 "Ask for missing critical details only when necessary"，这条规则太弱——agent 容易抓起模板直接填，导致 change card 建立在没澄清的假设上。用户需要把"动手前"的两条积极指令写入 `new`：

1. **Ask clarifying questions — one at a time**，覆盖 purpose / constraints / success criteria。
2. **Propose 2–3 approaches — 带 trade-offs + 推荐**。

两条规则的位置应在 `new` 动作里（`apply` 期间再问已晚、`project` 语境不合、Guardrails 是消极规则不同语域）。同时在 `change.md` 模板里加 `# Approach` 段固化讨论成果，让 archive 里的卡永久记录"为什么走这条路"。

# Approach

- Considered:
  - **A. 只改 SKILL，模板不动**。最小改动；但"提了 2–3 个选项但没落地文件"意味着讨论会随对话丢失。
  - **B. SKILL + 模板 + workflow.md BDD，不改 ms-close 合并逻辑**（推荐）。Approach 段进 card/archive，不进 domain spec；与 P1-4"Plan/Risks 留 archive"的既有分工一致。
  - **C. B 的基础上 + 让 ms-close 把 Approach 也合并进 spec**。读者在 spec 层就能看到 approach 决策；但要动两份 close 脚本 + tests，范围扩散到 scripts domain。
- Chosen: **B**。把 "为什么选这条路" 记入 card + archive 已经够用，后续真有需要再单起一张卡把 Approach 推进 spec（跟 P1-4 保持同一风格）。

# Scope

- In:
  - `minispec/SKILL.md`（canonical）：`### new` 从 5 步扩到 7 步。
  - `.claude/skills/minispec/SKILL.md`：同步。
  - `.agents/skills/minispec/SKILL.md`：同步（结构为 `## Action: new`）。
  - `minispec/templates/change.md`：在 `# Why` 和 `# Scope` 之间插入 `# Approach` 段，带"Considered / Chosen"骨架。
  - `minispec/specs/workflow.md`：`### new` BDD 增加一条 clarify+propose 的 Given/When/Then。
  - `CHANGELOG.md`：Unreleased > Changed 追加一条。
- Out:
  - 不改 `ms-close.sh` / `.ps1`（Approach 段保留在 card/archive，不合并进 domain spec）。
  - 不改 `apply` / `check` / `close` / `analyze` / `project` 的行为。
  - 不改 `AGENTS.md` / `CLAUDE.md`（两者是极简入口，规则详情归 SKILL）。

# Acceptance

- [x] Given 打开三份 SKILL 的 `new` 动作，Then 都有 7 步，其中第 3 步是 "Clarify ... one at a time"、第 4 步是 "Propose 2–3 approaches ... with trade-offs"。
- [x] Given 打开 `minispec/templates/change.md`，Then `# Approach` 段存在，位于 `# Why` 与 `# Scope` 之间，含 `Considered` / `Chosen` 骨架提示。
- [x] Given 打开 `minispec/specs/workflow.md`，Then `### new` 小节包含一条关于 clarify + propose 的 Given/When/Then。
- [x] Given 跑 `sh scripts/ms-doctor.sh .`，Then Result PASS 且 Guardrails 同步检查无 WARN（三份 SKILL 的 Guardrails 段不受本卡影响）。
- [x] Given 打开 `CHANGELOG.md`，Then Unreleased > Changed 段新增 "new action: require one-at-a-time clarifying questions and 2–3 approach proposals"。

# Plan

- [x] T1 改 `minispec/SKILL.md` 的 `### new`（canonical 先改，后面两份对齐这个）。
- [x] T2 改 `.claude/skills/minispec/SKILL.md` 的 `### new`。
- [x] T3 改 `.agents/skills/minispec/SKILL.md` 的 `## Action: new`。
- [x] T4 改 `minispec/templates/change.md`：插入 `# Approach`。
- [x] T5 改 `minispec/specs/workflow.md`：`### new` 加 BDD。
- [x] T6 改 `CHANGELOG.md` 追加 Changed 条目。
- [x] T7 跑 `ms-doctor` 做 Guardrails 漂移 smoke。
- [x] T8 close 到 domain=skills。

# Risks and Rollback

- Risk: agent 把 "propose 2–3 approaches" 执行成每次都强加选择负担，即便问题只有一条明显路径。Rollback: 在 SKILL 步骤 4 加一条 "If the problem has a single reasonable path, call it out explicitly and skip to step 5." 留给后续 iteration。
- Risk: `# Approach` 段用户嫌写起来重，只写一行应付。Rollback: 不强制执行；模板是引导不是 lint。后续可让 `ms-doctor` 检查 Approach 是否空（属于 P1-5 风格的 WARN，不阻断）。

# Notes

- 决策：Approach 段只入 card/archive，不进 domain spec，与 Plan/Risks 的处理保持同一风格（P1-4 既有契约）。
- 决策：三份 SKILL 各改各的，不走 P2-a 的 "单源 + 同步检查" 机制——Guardrails 段未动，doctor 的同步检查继续有效。
- 后续卡候选：若发现 spec 读者需要看到 Approach，起一张新卡把它进入 ms-close 的合并范围。
