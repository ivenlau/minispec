---
id: 20260422-p1-close-merge-coverage-doc
status: closed
owner: claude
---

# Why

`ms-close` 从 change card 抽取 Why / Scope / Acceptance / Notes 四段合并到 `minispec/specs/<domain>.md`；`Plan` 与 `Risks and Rollback` 只保留在 `minispec/archive/<id>.md`——但这一事实没有在任何文档或 SKILL 里说明。用户若期望历史 Plan 可检索，容易以为 close 丢数据。

本卡把这个合并范围显式写清，并在 ms-close 产出的 spec 合并块里加一条 `See archive/<id>.md for plan and risk notes.` 交叉引用，读者顺藤能找到完整上下文。

# Scope

- In:
  - `.claude/skills/minispec/SKILL.md` 与 `.agents/skills/minispec/SKILL.md`：在 `close` 小节末尾加一条明文："The canonical spec only captures Why / Scope / Acceptance / Notes. Plan and Risks remain in `minispec/archive/<id>.md`."
  - `scripts/ms-close.sh` 与 `scripts/ms-close.ps1`：合并块的 Notes 小节首行后增加一行 `- See minispec/archive/<id>.md for plan and risk notes.`
- Out:
  - 不改 close 的实际抽取范围（如果未来要把 Plan/Risks 也合并是另一回事，本卡不做）。

# Acceptance

- [x] Given 打开两份 SKILL 的 `close` 小节，Then 明文说明 Plan/Risks 只保留在 archive 不进 spec。
- [x] Given 运行 `ms-close.sh` 或 `ms-close.ps1` 关卡，When 查看合并到 spec 的 Notes 段，Then 包含 `See minispec/archive/<id>.md for plan and risk notes.` 行。

# Plan

- [x] T1 两份 SKILL `close` 小节追加说明。
- [x] T2 ms-close.sh 合并 here-doc 调整 Notes 段，增加交叉引用行。
- [x] T3 ms-close.ps1 合并模板同步。
- [x] T4 本卡自我验证：close 本卡时，`specs/scripts.md` 末尾的 Notes 段应包含新增行（本卡 domain = scripts）。

# Risks and Rollback

- Risk: 已有工具若按行数解析合并块会被这行打破。Rollback: 移除该行或把它放到合并块末尾而非 Notes 段开头。

# Notes

- 决策：交叉引用行放在"Auto-merged from"之后、旧 Notes 之前，形成"自动注释区"在前、"用户 Notes"在后的两段结构。
