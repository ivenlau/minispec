---
id: 20260609-karpathy-principles
status: closed
owner: multica-helper
---

# Why

andrej-karpathy-skills 的四条核心原则（Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution）能有效减少 LLM 编码中的常见错误。minispec 的 `new`/`check` 流程已覆盖原则 1 和 4，但原则 2（Simplicity First）和原则 3（Surgical Changes）在 `apply` 行为中缺乏显式约束，仅有隐含的 guardrail。需要将这两条原则集成到 SKILL.md 中，使 agent 在执行 `apply` 时有明确的行为指引。

# Approach

- Considered:
  - Option A: 增强 Guardrails + apply 行为描述，将原则 2/3 融入现有结构（改动最小，架构一致）
  - Option B: 新增独立的 Guiding Principles 章节（更显眼，但增加文件长度）
  - Option C: 在 CLAUDE.md / AGENTS.md 中直接引用（与 minispec 工作流解耦）
- Chosen: Option A，因为改动最小且与现有 guardrail 结构一致，不需要新增章节或修改入口文件。

# Scope

- In:
  - `minispec/SKILL.md`（canonical source）
  - `.claude/skills/minispec/SKILL.md`（mirror）
  - `.agents/skills/minispec/SKILL.md`（mirror）
  - 在 `## Guardrails` 中新增 Simplicity First 和 Surgical Changes 约束
  - 在 `apply` 行为中增加步骤：实现前评估方案最简性，实现时只改必要文件
- Out:
  - 不修改 CLAUDE.md / AGENTS.md
  - 不新增 Guiding Principles 章节
  - 不修改 change template 或 project.md

# Acceptance

- [x] Given agent 执行 apply, When 查看 SKILL.md 的 apply 步骤, Then 包含"评估方案是否最简"和"只改必要文件"的显式指引
- [x] Given agent 执行 apply, When 查看 SKILL.md 的 Guardrails, Then 包含 Simplicity First 和 Surgical Changes 的核心约束
- [x] Given 三个 SKILL.md 文件, When 对比 Guardrails 章节, Then 三者内容完全一致

# Plan

- [x] T1 更新 canonical `minispec/SKILL.md`:
  - Expected output: Guardrails 新增 2 条约束，apply 新增 2 个步骤
- [x] T2 同步 `.claude/skills/minispec/SKILL.md`:
  - Expected output: Guardrails 与 canonical 一致，apply 步骤与 canonical 一致
- [x] T3 同步 `.agents/skills/minispec/SKILL.md`:
  - Expected output: Guardrails 与 canonical 一致，apply 步骤与 canonical 一致

# Risks and Rollback

- Risk: 新增约束可能让 agent 在简单任务上过于谨慎
- Rollback: 删除新增的 guardrail 条目和 apply 步骤

# Notes

- 原则 1（Think Before Coding）和原则 4（Goal-Driven Execution）已被 minispec 覆盖，无需改动
- 三个 SKILL.md 文件的 Guardrails 必须保持一致（doctor 会检查同步）
