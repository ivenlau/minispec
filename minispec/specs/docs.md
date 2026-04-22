# docs

Canonical shipped behavior for domain: docs


## Change 20260422-p0-doc-action-alignment (2026-04-22)

### Why

minispec 的 workflow 在不同入口文件里口径不一致：

- `AGENTS.md` 列 5 个 action（project / new / apply / check / close），漏 `analyze`。
- `CLAUDE.md` 用 "Workflow Contract" 的自由四步语言描述（Create card / Implement / Validate / Update specs+archive），不提 action 名、也不提 analyze 和 archive。
- `README.md` 与两份 `SKILL.md` 用 6-action 权威口径。

这种口径漂移会让用户读不同入口看到的"minispec 有几个步骤"答案不同。本卡把 `AGENTS.md` 与 `CLAUDE.md` 统一到 SKILL 的 6-action 模型。

### Scope

- In:
  - `AGENTS.md`：Default Rule 扩到 6 个 action，顺序 project → new → apply → check → analyze → close。
  - `CLAUDE.md`：把 Workflow Contract 重写为 6-action 形式，保留 "Before first change, run project" 的首用约束与 Exception Rule，补 `minispec/archive/` 到 Context Files 列表。
- Out:
  - 不改 README（P0-e 负责示例命令一致性）。
  - 不改 SKILL（由 P0-d、P2-1 处理）。
  - 不改 action 语义本身——仅对齐文字口径。

### Acceptance

- [x] Given 打开 `AGENTS.md`，When 阅读 Default Rule 小节，Then 按序出现 project / new / apply / check / analyze / close 六条。
- [x] Given 打开 `CLAUDE.md`，When 阅读 Workflow Contract，Then 出现同顺序的六个 action 名称，并且 analyze 标注为按需。
- [x] Given 打开 `CLAUDE.md`，When 阅读 Context Files，Then 列表包含 `minispec/archive/`。
- [x] Given 任一读者按入口导航，Then 三份文档（README / AGENTS / CLAUDE）对 action 名称与顺序的声明完全一致。

### Notes
- Auto-merged from `minispec/changes/20260422-p0-doc-action-alignment.md`

- 决策：analyze 被标注为"按需 / on demand"，在文档里显示为一条可选 action。保持与 SKILL 的相对语气一致。
- 决策：CLAUDE.md Context Files 列表补 `minispec/archive/`，避免读者忽视归档层。

## Change 20260422-p0-readme-cli-consistency (2026-04-22)

### Why

`README.md` 的 "Use In AI CLI (Codex/Claude)" 小节为两种环境给出的示例命令不等价：

- Codex：`minispec project . auto nextjs saas app`（4 个位置参数：root、mode、context...）
- Claude：`minispec project nextjs saas app`（仅 context）
- Codex：`minispec analyze deep .`
- Claude：`minispec analyze deep`

这让读者以为两个平台的调用约定不同，进而要记两套姿势。实际上 action 的位置参数契约是通用的，CLI 环境差异只在入口文件名（AGENTS.md vs CLAUDE.md）与 skill 位置，不在命令语法。

### Scope

- In:
  - `README.md`：
    - 在 Workflow 小节后加一条 "CLI Syntax" 子节，声明统一语法 `minispec <action> [root] [mode] [context...]`，说明 `root` 默认 `.`、`mode` 默认 `auto`。
    - 把 "Use In AI CLI (Codex/Claude)" 下两段示例命令写成完全一致的形式（省略 `root`/`mode` 保持简洁），只在上下文说明环境差异。
- Out:
  - 不修改实际脚本参数解析逻辑（脚本已支持两种姿势）。
  - 不改 `Utility Scripts` 小节的命令演示。

### Acceptance

- [x] Given 阅读 README 的 Workflow 段，When 看到一条 "CLI Syntax" 或等价描述，Then 明确给出 `minispec <action> [root] [mode] [context...]`。
- [x] Given 对比 README 中 Codex 与 Claude 两个示例列表，Then `minispec project …`、`minispec analyze …` 等命令的写法逐字一致。
- [x] Given 读者按任一示例操作，When agent 读取同样的参数，Then 行为与 Codex/Claude 一致（脚本端不区分环境）。

### Notes
- Auto-merged from `minispec/changes/20260422-p0-readme-cli-consistency.md`

- 决策：示例以 agent 视角的"简短命令"为默认形态；脚本形态保留在 Utility Scripts 段作为 fallback 演示。

## Change 20260422-p1-skill-script-positioning (2026-04-22)

### Why

两处不一致影响用户理解"在什么场景下该走脚本、什么场景下该让 agent 执行"：

1. 两份 SKILL 的 `project` 小节里都写着 "Always execute `project` directly (no script dependency)"，但 `scripts/ms-project.sh/.ps1` 被显式保留并在 README Utility Scripts 段占核心位置。措辞"no script dependency"与"脚本存在且可用"互相矛盾。
2. README 的 `Workflow` 小节没有标清哪些 action 走脚本、哪些是纯 agent 驱动，读者得看 `scripts/` 目录才推断出 `new` / `apply` / `check` / `analyze` 没脚本。

本卡把角色定位清楚：**SKILL 是 agent 首选路径；脚本是 CI / 无 AI 环境的 fallback**。

### Scope

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

### Acceptance

- [x] Given 打开 README Workflow 段，Then 每个 action 后附标签说明脚本支持状态。
- [x] Given 打开 README Utility Scripts 段，Then 开头说明"脚本为 fallback"，每个脚本条目末尾带该标签。
- [x] Given 打开两份 SKILL 的 `project` 小节，Then 措辞一致且不再出现 "no script dependency"。
- [x] Given 读者阅读 SKILL 与 README，Then 对同一问题（"project 这个动作谁执行？"）得到一致的答案："agent 首选，脚本 fallback"。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-skill-script-positioning.md`

- 决策：脚本职责限定为"无 agent 时可用"，而非"agent 的备份"。语义上脚本与 SKILL 是互补路径，不是主备。

## Change 20260422-p1-readme-zh-cn (2026-04-22)

### Why

minispec 的潜在使用者大量在中文语境，但所有文档都是英文，阅读门槛较高。本卡新增 `README.zh-CN.md` 与英文 README 章节对齐，并在英文版顶部加语言切换。SKILL.md / AGENTS.md / CLAUDE.md 仍保留英文——它们是 agent 解析的契约，换语言会带来非必要的解析漂移风险。

### Scope

- In:
  - 新建 `README.zh-CN.md`：与英文 README 章节完全一致，示例命令完全相同。
  - `README.md` 顶部加一行 `Language: English | [简体中文](README.zh-CN.md)`。
  - `README.zh-CN.md` 顶部同样放置语言切换回跳。
  - 术语对照表：action=动作、change card=变更卡、spec=规范、domain=领域、archive=归档。
- Out:
  - 不翻译 SKILL / AGENTS.md / CLAUDE.md / scripts 的注释与错误信息（保持 agent 解析稳定性）。
  - 不翻译 `minispec/specs/*.md` 与 `minispec/project.md`。

### Acceptance

- [x] Given 打开 `README.md`，Then 顶部出现语言切换链接指向 `README.zh-CN.md`。
- [x] Given 打开 `README.zh-CN.md`，Then 顶部出现语言切换链接指向 `README.md`。
- [x] Given `README.zh-CN.md` 存在，When 与英文 README 对比，Then 章节数量、示例命令逐字一致。
- [x] Given 阅读 `README.zh-CN.md`，Then 开头能看到术语对照表。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-readme-zh-cn.md`
- See `minispec/archive/20260422-p1-readme-zh-cn.md` for plan and risk notes.

- 决策：只保留一份中文入口（README），其他规范文件维持英文，降低双语维护成本。

## Change 20260422-p2-nesting-docs (2026-04-22)

### Why

仓库根叫 `minispec/`，里层还有一个 `minispec/`（合同目录）。对维护者是"仓库外壳 vs 合同目录"两层，对第一次读代码的人则是"路径里为什么连写两遍 minispec"——不讲清是一种低级门槛。同样地，`ms-init` 把合同目录安到用户仓库之后也会出现 `<user-repo>/minispec/...` 结构，用户也要理解这一点。

本卡在 README（中英文两版）靠前位置加一张极简结构图，把仓库内视角 vs 使用者视角都画出来，消除歧义。

### Scope

- In:
  - `README.md` 与 `README.zh-CN.md`：在 Directory Layout / 目录结构 段之前加 "Repo layout vs adopted-project layout" 子节（中文版对应 "仓库结构 vs 被引入项目的结构"），含两块 text 树。
- Out:
  - 不改目录本身（不重命名），不加 `MINISPEC_DIR` 环境变量。

### Acceptance

- [x] Given 打开 `README.md`，When 读 Directory Layout 之前，Then 能看到两块 text 树分别标注 "This repo" 与 "A project that adopted minispec via ms-init"。
- [x] Given 打开 `README.zh-CN.md`，Then 同等内容以中文呈现。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-nesting-docs.md`
- See `minispec/archive/20260422-p2-nesting-docs.md` for plan and risk notes.

- 决策：不做运行时 `MINISPEC_DIR` 配置，因为跨平台 skill / agent 约定的路径字面量用变量会破坏解析稳定性。
