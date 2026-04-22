---
id: 20260422-p1-skill-script-positioning
status: closed
owner: claude
---

# Why

两处不一致影响用户理解"在什么场景下该走脚本、什么场景下该让 agent 执行"：

1. 两份 SKILL 的 `project` 小节里都写着 "Always execute `project` directly (no script dependency)"，但 `scripts/ms-project.sh/.ps1` 被显式保留并在 README Utility Scripts 段占核心位置。措辞"no script dependency"与"脚本存在且可用"互相矛盾。
2. README 的 `Workflow` 小节没有标清哪些 action 走脚本、哪些是纯 agent 驱动，读者得看 `scripts/` 目录才推断出 `new` / `apply` / `check` / `analyze` 没脚本。

本卡把角色定位清楚：**SKILL 是 agent 首选路径；脚本是 CI / 无 AI 环境的 fallback**。

# Scope

- In:
  - `README.md`：
    - Utility Scripts 小节开头加一段定位说明。
    - 每个脚本条目末尾加 `(fallback; agents should prefer in-context generation)` 类标注。
    - Workflow 小节每 action 加 `(script: scripts/ms-*.sh/.ps1)` 或 `(agent-driven only)` 标签。
  - `.claude/skills/minispec/SKILL.md` 与 `.agents/skills/minispec/SKILL.md`：
    - `project` 小节里 "Always execute `project` directly (no script dependency)" 改为 "Prefer in-context generation over `ms-project.*`; fall back to the script only when running without an AI agent."
- Out:
  - 不改变脚本功能或 SKILL 其他 action 的规则。
  - 不处理 P2-1 的单源 SKILL 重构。

# Acceptance

- [x] Given 打开 README Workflow 段，Then 每个 action 后附标签说明脚本支持状态。
- [x] Given 打开 README Utility Scripts 段，Then 开头说明"脚本为 fallback"，每个脚本条目末尾带该标签。
- [x] Given 打开两份 SKILL 的 `project` 小节，Then 措辞一致且不再出现 "no script dependency"。
- [x] Given 读者阅读 SKILL 与 README，Then 对同一问题（"project 这个动作谁执行？"）得到一致的答案："agent 首选，脚本 fallback"。

# Plan

- [x] T1 README Workflow 段改写 6 条 action 标签。
- [x] T2 README Utility Scripts 段加定位说明 + 每条脚本标注。
- [x] T3 两份 SKILL 的 `project` 第 5 步改写。
- [x] T4 grep 核对两份 SKILL 对应位置逐字相同。

# Risks and Rollback

- Risk: 标签可能让 Workflow 段视觉拥挤。Rollback: 把标签合并为一句脚注，统一放 Workflow 段末尾。

# Notes

- 决策：脚本职责限定为"无 agent 时可用"，而非"agent 的备份"。语义上脚本与 SKILL 是互补路径，不是主备。
