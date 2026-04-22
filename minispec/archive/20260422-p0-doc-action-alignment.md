---
id: 20260422-p0-doc-action-alignment
status: closed
owner: claude
---

# Why

minispec 的 workflow 在不同入口文件里口径不一致：

- `AGENTS.md` 列 5 个 action（project / new / apply / check / close），漏 `analyze`。
- `CLAUDE.md` 用 "Workflow Contract" 的自由四步语言描述（Create card / Implement / Validate / Update specs+archive），不提 action 名、也不提 analyze 和 archive。
- `README.md` 与两份 `SKILL.md` 用 6-action 权威口径。

这种口径漂移会让用户读不同入口看到的"minispec 有几个步骤"答案不同。本卡把 `AGENTS.md` 与 `CLAUDE.md` 统一到 SKILL 的 6-action 模型。

# Scope

- In:
  - `AGENTS.md`：Default Rule 扩到 6 个 action，顺序 project → new → apply → check → analyze → close。
  - `CLAUDE.md`：把 Workflow Contract 重写为 6-action 形式，保留 "Before first change, run project" 的首用约束与 Exception Rule，补 `minispec/archive/` 到 Context Files 列表。
- Out:
  - 不改 README（P0-e 负责示例命令一致性）。
  - 不改 SKILL（由 P0-d、P2-1 处理）。
  - 不改 action 语义本身——仅对齐文字口径。

# Acceptance

- [x] Given 打开 `AGENTS.md`，When 阅读 Default Rule 小节，Then 按序出现 project / new / apply / check / analyze / close 六条。
- [x] Given 打开 `CLAUDE.md`，When 阅读 Workflow Contract，Then 出现同顺序的六个 action 名称，并且 analyze 标注为按需。
- [x] Given 打开 `CLAUDE.md`，When 阅读 Context Files，Then 列表包含 `minispec/archive/`。
- [x] Given 任一读者按入口导航，Then 三份文档（README / AGENTS / CLAUDE）对 action 名称与顺序的声明完全一致。

# Plan

- [x] T1 改 `AGENTS.md`：Default Rule 从 5 条扩为 6 条，在 apply 与 check 之间插入 `analyze` 的说明行（按需）。
- [x] T2 改 `CLAUDE.md`：Workflow Contract 改为六条 action 列表；Context Files 补 archive；保留 Skill / Exception Rule。
- [x] T3 快速核对：`grep -cE '^(1\.|2\.|3\.|4\.|5\.|6\.)' AGENTS.md CLAUDE.md README.md` 中步骤行数符合预期。

# Risks and Rollback

- Risk: Codex 既有约定可能偏好更少步骤。Rollback: 在 AGENTS.md 注明"analyze 可选"而不扩步骤数。
- Risk: CLAUDE.md 改动过多会丢失原有措辞神韵。Rollback: 仅追加一句"六个 action 见 SKILL.md"。

# Notes

- 决策：analyze 被标注为"按需 / on demand"，在文档里显示为一条可选 action。保持与 SKILL 的相对语气一致。
- 决策：CLAUDE.md Context Files 列表补 `minispec/archive/`，避免读者忽视归档层。
