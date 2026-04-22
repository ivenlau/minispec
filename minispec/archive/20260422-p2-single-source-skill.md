---
id: 20260422-p2-single-source-skill
status: closed
owner: claude
---

# Why

当前 `.agents/skills/minispec/SKILL.md` 与 `.claude/skills/minispec/SKILL.md` 是同内容的两份副本。P0-d 修过一次漂移（Guardrails + description），但结构上仍是两份；以后增平台（Gemini、Cursor、Cline…）会继续 N 倍复制。

本卡建立 `minispec/SKILL.md` 作为 **canonical source**，两份平台 SKILL 顶部加"以 minispec/SKILL.md 为权威"的指引，并由 `ms-doctor` 新增"三份 SKILL 内容同步"的语义检查——漂移出现时第一时间 WARN。

采用"权威文件 + mirror + 同步检查"的轻量方案（方案 A），不引入生成器脚本；若将来需要更强约束再升级为方案 B。

# Scope

- In:
  - 新建 `minispec/SKILL.md`，内容与当前 `.claude/skills/minispec/SKILL.md` 一致（已经包含 Guardrails、6 action、project 的 in-context 指引）。
  - 两份平台 SKILL 文件顶部 frontmatter 下加 HTML 注释：`<!-- canonical source: minispec/SKILL.md; keep mirrors in sync -->`；正文保留一致的完整内容（mirror）。
  - `scripts/ms-doctor.sh` / `.ps1` 新增 Semantic check：比较三份 SKILL 的 `## Commands` 到 EOF 的正文（SHA 或 diff 方式），不一致则 WARN。
- Out:
  - 不做生成器脚本（方案 B 留给后续）。
  - 不合并 `.agents` / `.claude` skill 目录——保持平台 skill 加载机制原生可用。

# Acceptance

- [x] Given 打开 `minispec/SKILL.md`，Then 文件存在，frontmatter 含 `name: minispec`、`description: Lightweight spec-first workflow for coding tasks.`。
- [x] Given 对三份 SKILL 正文（从 `## Commands` 到 EOF）求 SHA-256，Then 三者哈希相同。
- [x] Given 平台 SKILL 顶部，Then 有 canonical 指引注释。
- [x] Given 我故意把 `.agents/skills/minispec/SKILL.md` 的一处 guardrail 文字改掉，When 跑 `ms-doctor.sh`，Then Semantic checks 段输出 `[WARN] SKILL files are out of sync`。
- [x] Given 三份 SKILL 一致，When 跑 doctor，Then 不出现上述 WARN。

# Plan

- [x] T1 新建 `minispec/SKILL.md`。
- [x] T2 两份平台 SKILL 顶部 frontmatter 后、正文前加 canonical 注释。
- [x] T3 `ms-doctor.sh` 扩展：算三份 SKILL 从 `^## Commands` 到 EOF 的 sha256，不一致则 WARN。
- [x] T4 `ms-doctor.ps1` 同步等价检查。
- [x] T5 fixture 验证：修改一份后 doctor 报 WARN；改回后消失。

# Risks and Rollback

- Risk: `## Commands` 之前的内容（name、description、trigger 风格）可能因平台叙事差异刻意不同，粗放 diff 会误报。Rollback: 仅对 `## Guardrails` 小节做 diff，而不是整个正文。
- Risk: 哈希计算对换行敏感（CRLF vs LF），可能在 Windows 上 CI 误报。Rollback: diff 前 normalize 行尾。

# Notes

- 决策：同步检查范围选择"从 `## Commands` 到 EOF"。`## Commands` 是 Claude 版的首个 action 总览，`.agents` 版改叫 `## Inputs` + `## Action:` 系列——实际两版结构已经有差异。因此我选择对 **Guardrails 段**做严格对比，而非整文件。
- 修正方案：Semantic check 只 diff `## Guardrails` 小节。
- 决策：后续真要 deduplicate，单独起 P2-g 卡做生成器方案 B。
