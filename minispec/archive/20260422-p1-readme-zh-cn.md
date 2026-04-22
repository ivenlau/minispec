---
id: 20260422-p1-readme-zh-cn
status: closed
owner: claude
---

# Why

minispec 的潜在使用者大量在中文语境，但所有文档都是英文，阅读门槛较高。本卡新增 `README.zh-CN.md` 与英文 README 章节对齐，并在英文版顶部加语言切换。SKILL.md / AGENTS.md / CLAUDE.md 仍保留英文——它们是 agent 解析的契约，换语言会带来非必要的解析漂移风险。

# Scope

- In:
  - 新建 `README.zh-CN.md`：与英文 README 章节完全一致，示例命令完全相同。
  - `README.md` 顶部加一行 `Language: English | [简体中文](README.zh-CN.md)`。
  - `README.zh-CN.md` 顶部同样放置语言切换回跳。
  - 术语对照表：action=动作、change card=变更卡、spec=规范、domain=领域、archive=归档。
- Out:
  - 不翻译 SKILL / AGENTS.md / CLAUDE.md / scripts 的注释与错误信息（保持 agent 解析稳定性）。
  - 不翻译 `minispec/specs/*.md` 与 `minispec/project.md`。

# Acceptance

- [x] Given 打开 `README.md`，Then 顶部出现语言切换链接指向 `README.zh-CN.md`。
- [x] Given 打开 `README.zh-CN.md`，Then 顶部出现语言切换链接指向 `README.md`。
- [x] Given `README.zh-CN.md` 存在，When 与英文 README 对比，Then 章节数量、示例命令逐字一致。
- [x] Given 阅读 `README.zh-CN.md`，Then 开头能看到术语对照表。

# Plan

- [x] T1 英文 README 顶部加语言切换。
- [x] T2 新建 `README.zh-CN.md`，内容与英文 README 对齐 + 术语表。
- [x] T3 核对章节数量与示例命令。

# Risks and Rollback

- Risk: 中文版维护滞后导致两版不一致。Rollback: `README.zh-CN.md` 顶部注明"以英文版为权威；若此处陈旧请提 issue"。

# Notes

- 决策：只保留一份中文入口（README），其他规范文件维持英文，降低双语维护成本。
