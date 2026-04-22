---
id: 20260422-p0-skill-guardrails-parity
status: closed
owner: claude
---

# Why

`.claude/skills/minispec/SKILL.md` 有明确的 `## Guardrails` 小节（禁止新增依赖、禁止越权清理、acceptance 未完不得 close），但 `.agents/skills/minispec/SKILL.md` 缺失；且两份 `description` 一个写 "code changes"、一个写 "coding tasks"。

agent 会把 SKILL frontmatter 的 `description` 用于召回判断，措辞差异会让不同 CLI 对同一技能的触发语义产生分化；而 Guardrails 缺失等于把同样的底线只告诉其中一个平台。

# Scope

- In:
  - `.agents/skills/minispec/SKILL.md`：把 `description` 改为 `Lightweight spec-first workflow for coding tasks.`；在文件末尾追加 `## Guardrails` 小节，内容与 Claude 版一致。
  - `.claude/skills/minispec/SKILL.md`：保留现有 `## Guardrails`；description 已是 "coding tasks"，无需改动。
- Out:
  - 不做 P2-1 的"单源 SKILL"重构——那是独立卡。
  - 不改 action 级规则本身。

# Acceptance

- [x] Given 读取 `.agents/skills/minispec/SKILL.md` 的 frontmatter，When 取出 `description` 字段，Then 值为 `Lightweight spec-first workflow for coding tasks.`。
- [x] Given 对比两份 SKILL 的 `description`，Then 完全一致。
- [x] Given 两份 SKILL 都包含 `## Guardrails`，Then 三条规则内容按行对比完全一致。

# Plan

- [x] T1 改 `.agents/skills/minispec/SKILL.md` 的 frontmatter description。
- [x] T2 在 `.agents` SKILL 末尾追加 `## Guardrails` 小节。
- [x] T3 `diff` 两份 `## Guardrails` 小节内容确认一致。

# Risks and Rollback

- Risk: Codex 旧召回策略可能依赖旧 description。Rollback: 还原 description 并只保留 Guardrails 新增。

# Notes

- 决策：Guardrails 暂时保留在两端副本，等 P2-1（单源 SKILL + 平台 stub）上线后再消除重复。
- 验证：diff 命令与输出见本卡 Acceptance T3。
