# skills

Canonical shipped behavior for domain: skills


## Change 20260422-p0-skill-guardrails-parity (2026-04-22)

### Why

`.claude/skills/minispec/SKILL.md` 有明确的 `## Guardrails` 小节（禁止新增依赖、禁止越权清理、acceptance 未完不得 close），但 `.agents/skills/minispec/SKILL.md` 缺失；且两份 `description` 一个写 "code changes"、一个写 "coding tasks"。

agent 会把 SKILL frontmatter 的 `description` 用于召回判断，措辞差异会让不同 CLI 对同一技能的触发语义产生分化；而 Guardrails 缺失等于把同样的底线只告诉其中一个平台。

### Scope

- In:
  - `.agents/skills/minispec/SKILL.md`：把 `description` 改为 `Lightweight spec-first workflow for coding tasks.`；在文件末尾追加 `## Guardrails` 小节，内容与 Claude 版一致。
  - `.claude/skills/minispec/SKILL.md`：保留现有 `## Guardrails`；description 已是 "coding tasks"，无需改动。
- Out:
  - 不做 P2-1 的"单源 SKILL"重构——那是独立卡。
  - 不改 action 级规则本身。

### Acceptance

- [x] Given 读取 `.agents/skills/minispec/SKILL.md` 的 frontmatter，When 取出 `description` 字段，Then 值为 `Lightweight spec-first workflow for coding tasks.`。
- [x] Given 对比两份 SKILL 的 `description`，Then 完全一致。
- [x] Given 两份 SKILL 都包含 `## Guardrails`，Then 三条规则内容按行对比完全一致。

### Notes
- Auto-merged from `minispec/changes/20260422-p0-skill-guardrails-parity.md`

- 决策：Guardrails 暂时保留在两端副本，等 P2-1（单源 SKILL + 平台 stub）上线后再消除重复。
- 验证：diff 命令与输出见本卡 Acceptance T3。

## Change 20260422-p2-single-source-skill (2026-04-22)

### Why

当前 `.agents/skills/minispec/SKILL.md` 与 `.claude/skills/minispec/SKILL.md` 是同内容的两份副本。P0-d 修过一次漂移（Guardrails + description），但结构上仍是两份；以后增平台（Gemini、Cursor、Cline…）会继续 N 倍复制。

本卡建立 `minispec/SKILL.md` 作为 **canonical source**，两份平台 SKILL 顶部加"以 minispec/SKILL.md 为权威"的指引，并由 `ms-doctor` 新增"三份 SKILL 内容同步"的语义检查——漂移出现时第一时间 WARN。

采用"权威文件 + mirror + 同步检查"的轻量方案（方案 A），不引入生成器脚本；若将来需要更强约束再升级为方案 B。

### Scope

- In:
  - 新建 `minispec/SKILL.md`，内容与当前 `.claude/skills/minispec/SKILL.md` 一致（已经包含 Guardrails、6 action、project 的 in-context 指引）。
  - 两份平台 SKILL 文件顶部 frontmatter 下加 HTML 注释：`<!-- canonical source: minispec/SKILL.md; keep mirrors in sync -->`；正文保留一致的完整内容（mirror）。
  - `scripts/ms-doctor.sh` / `.ps1` 新增 Semantic check：比较三份 SKILL 的 `## Commands` 到 EOF 的正文（SHA 或 diff 方式），不一致则 WARN。
- Out:
  - 不做生成器脚本（方案 B 留给后续）。
  - 不合并 `.agents` / `.claude` skill 目录——保持平台 skill 加载机制原生可用。

### Acceptance

- [x] Given 打开 `minispec/SKILL.md`，Then 文件存在，frontmatter 含 `name: minispec`、`description: Lightweight spec-first workflow for coding tasks.`。
- [x] Given 对三份 SKILL 正文（从 `## Commands` 到 EOF）求 SHA-256，Then 三者哈希相同。
- [x] Given 平台 SKILL 顶部，Then 有 canonical 指引注释。
- [x] Given 我故意把 `.agents/skills/minispec/SKILL.md` 的一处 guardrail 文字改掉，When 跑 `ms-doctor.sh`，Then Semantic checks 段输出 `[WARN] SKILL files are out of sync`。
- [x] Given 三份 SKILL 一致，When 跑 doctor，Then 不出现上述 WARN。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-single-source-skill.md`
- See `minispec/archive/20260422-p2-single-source-skill.md` for plan and risk notes.

- 决策：同步检查范围选择"从 `## Commands` 到 EOF"。`## Commands` 是 Claude 版的首个 action 总览，`.agents` 版改叫 `## Inputs` + `## Action:` 系列——实际两版结构已经有差异。因此我选择对 **Guardrails 段**做严格对比，而非整文件。
- 修正方案：Semantic check 只 diff `## Guardrails` 小节。
- 决策：后续真要 deduplicate，单独起 P2-g 卡做生成器方案 B。

## Change 20260423-clarify-and-propose-in-new (2026-04-23)

### Why

minispec 的 `new` 动作当前只要求 "Ask for missing critical details only when necessary"，这条规则太弱——agent 容易抓起模板直接填，导致 change card 建立在没澄清的假设上。用户需要把"动手前"的两条积极指令写入 `new`：

1. **Ask clarifying questions — one at a time**，覆盖 purpose / constraints / success criteria。
2. **Propose 2–3 approaches — 带 trade-offs + 推荐**。

两条规则的位置应在 `new` 动作里（`apply` 期间再问已晚、`project` 语境不合、Guardrails 是消极规则不同语域）。同时在 `change.md` 模板里加 `# Approach` 段固化讨论成果，让 archive 里的卡永久记录"为什么走这条路"。

### Scope

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

### Acceptance

- [x] Given 打开三份 SKILL 的 `new` 动作，Then 都有 7 步，其中第 3 步是 "Clarify ... one at a time"、第 4 步是 "Propose 2–3 approaches ... with trade-offs"。
- [x] Given 打开 `minispec/templates/change.md`，Then `# Approach` 段存在，位于 `# Why` 与 `# Scope` 之间，含 `Considered` / `Chosen` 骨架提示。
- [x] Given 打开 `minispec/specs/workflow.md`，Then `### new` 小节包含一条关于 clarify + propose 的 Given/When/Then。
- [x] Given 跑 `sh scripts/ms-doctor.sh .`，Then Result PASS 且 Guardrails 同步检查无 WARN（三份 SKILL 的 Guardrails 段不受本卡影响）。
- [x] Given 打开 `CHANGELOG.md`，Then Unreleased > Changed 段新增 "new action: require one-at-a-time clarifying questions and 2–3 approach proposals"。

### Notes
- Auto-merged from `minispec/changes/20260423-clarify-and-propose-in-new.md`
- See `minispec/archive/20260423-clarify-and-propose-in-new.md` for plan and risk notes.

- 决策：Approach 段只入 card/archive，不进 domain spec，与 Plan/Risks 的处理保持同一风格（P1-4 既有契约）。
- 决策：三份 SKILL 各改各的，不走 P2-a 的 "单源 + 同步检查" 机制——Guardrails 段未动，doctor 的同步检查继续有效。
- 后续卡候选：若发现 spec 读者需要看到 Approach，起一张新卡把它进入 ms-close 的合并范围。

## Change 20260609-karpathy-principles (2026-06-09)

### Why

andrej-karpathy-skills 的四条核心原则能有效减少 LLM 编码常见错误。minispec 的 `new`/`check` 已覆盖 Think Before Coding 和 Goal-Driven Execution，但 Simplicity First 和 Surgical Changes 在 `apply` 行为中缺乏显式约束。需要将这两条原则集成到 SKILL.md 的 Guardrails 和 apply 步骤中。

### Scope

- In:
  - `minispec/SKILL.md`（canonical）、`.claude/skills/minispec/SKILL.md`、`.agents/skills/minispec/SKILL.md`
  - `## Guardrails` 新增 Simplicity First 和 Surgical Changes 两条约束
  - `apply` 行为新增步骤：实现前评估方案最简性，实现时只改必要文件
- Out:
  - 不修改 CLAUDE.md / AGENTS.md
  - 不新增 Guiding Principles 章节

### Acceptance

- [x] Given agent 执行 apply, When 查看 SKILL.md 的 apply 步骤, Then 包含"评估方案是否最简"和"只改必要文件"的显式指引
- [x] Given agent 执行 apply, When 查看 SKILL.md 的 Guardrails, Then 包含 Simplicity First 和 Surgical Changes 的核心约束
- [x] Given 三个 SKILL.md 文件, When 对比 Guardrails 章节, Then 三者内容完全一致

### Notes

- 原则 1（Think Before Coding）和原则 4（Goal-Driven Execution）已被 minispec 覆盖，无需改动
- Guardrails 段保持三份一致，doctor 同步检查继续有效
- 来源：https://github.com/ivenlau/andrej-karpathy-skills
