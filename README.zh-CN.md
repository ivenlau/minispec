# minispec

语言: [English](README.md) | **简体中文**

minispec 是一套面向 AI 编码工具的轻量级 spec-first 工作流。它只搭建一份最小化的 markdown 契约（`project.md` + `specs/` + `changes/` + `archive/`），并教会你的 AI agent（Claude Code、Codex 等）如何用这份契约推进每一次变更。

本文为 `README.md` 的中文对应版；英文版为权威版本，两版不一致时以英文为准，可提 issue 反馈。

## 安装

### Linux / macOS / WSL / git-bash

```sh
curl -fsSL https://raw.githubusercontent.com/ivenlau/minispec/main/install.sh | sh
```

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/ivenlau/minispec/main/install.ps1 | iex
```

两个脚本都安装在用户目录下（不需要 sudo 或管理员权限），并在 PATH 里放好一个全局 `minispec` 命令。Linux/macOS 上如果 `~/.local/bin` 不在 PATH，安装器会明确提示该往哪个 shell rc 文件里加一行；Windows 上请在安装完成后重开终端，让 PATH 的更新生效。

验证：

```sh
minispec --version
```

## 快速开始

从空目录到第一次 AI 驱动的变更，只三步：

```sh
cd my-project
minispec init .                                         # 初始化契约与 AI skill 文件（同时把 minispec 从 git 屏蔽——见下文）
minispec project . auto "TypeScript Next.js app"        # 生成 minispec/project.md（自动检测 + 上下文提示）
```

如果你想自己管 `.gitignore`，给 `init` 加 `--no-gitignore`。

然后在 `my-project/` 里启动你的 AI CLI（Claude Code / Codex），让它跑：

```
minispec new add checkout rate-limit
minispec apply 20260422-checkout-rate-limit
minispec check 20260422-checkout-rate-limit
minispec close 20260422-checkout-rate-limit checkout
```

Agent 会读取 init 放进 `.agents/` 与 `.claude/` 的 SKILL 文件，创建 `minispec/changes/` 下的 change card、实现 Plan、校验 Acceptance，并最终把变更合并进 `minispec/specs/checkout.md`。

## 术语对照

| 英文 | 中文 | 说明 |
| --- | --- | --- |
| action | 动作 | 六个工作流动作之一（project/new/apply/check/analyze/close） |
| change card | 变更卡 | `minispec/changes/<id>.md` 中的单次变更文件 |
| spec | 规范 | `minispec/specs/<domain>.md` 中累积的领域行为契约 |
| domain | 领域 | close 时把变更合并进入的 spec 文件名（如 `scripts`、`docs`） |
| archive | 归档 | 关卡后 change card 的最终归属目录 `minispec/archive/` |
| guardrails | 底线 | SKILL 中定义的不可越界规则 |

## 将 minispec 纳入 / 排除在 git 之外

**默认：开发者本地模式。** `minispec init` 把 minispec 视为本地工具，会在目标项目的 `.gitignore` 里追加一段带 marker 的块，屏蔽 `AGENTS.md`、`CLAUDE.md`、`.agents/`、`.claude/`、`minispec/`。你的产品 git 历史只盯着产品代码，minispec 的契约文件在磁盘上存在但对 `git add` 隐形。

块的结构（任何时候都能手动编辑）：

```gitignore
# >>> minispec — dev-local scaffolding (added by `minispec init`) >>>
# Remove this block to commit minispec files and track change history in
# git alongside your code. See README for details.
AGENTS.md
CLAUDE.md
.agents/
.claude/
minispec/
# <<< minispec <<<
```

**单次跳过** — 只想这一次 init 不写 `.gitignore`，加 `--no-gitignore`：

```sh
minispec init --no-gitignore .
```

**切回团队模式**（把 minispec 和代码一起 commit，这样 clone 仓库的同事自动继承 workflow、AI skill、变更史）：删掉 `.gitignore` 里的 marker 块，然后 `git add AGENTS.md CLAUDE.md .agents .claude minispec`。

幂等：对同一目录再跑一次 `minispec init` 不会重复写入 marker 块。

## 工作流

1. `project`：生成或刷新 `project.md`。_(agent 首选；脚本 fallback：`scripts/ms-project.*`)_
2. `new`：由想法创建一张 change card。_(仅 agent 驱动)_
3. `apply`：按 change card 的 Plan 执行任务。_(仅 agent 驱动)_
4. `check`：校验 Acceptance 与测试命令。_(仅 agent 驱动)_
5. `analyze`：在 AI CLI 中分析仓库并同步 `minispec/specs/README.md` 及引用文档。_(仅 agent 驱动)_
6. `close`：把变更合并进 `specs/` 并归档。_(agent 首选；脚本 fallback：`scripts/ms-close.*`)_

### CLI 语法

所有 AI CLI（Codex、Claude 等）共用同一命令形态：

```text
minispec <action> [root] [mode] [context...]
```

- `<action>`：`project` / `new` / `apply` / `check` / `analyze` / `close` 之一。
- `[root]`：仓库根，默认 `.`。
- `[mode]`：动作相关模式（`project` 支持 `auto` | `existing` | `new`；`analyze` 支持 `quick` | `normal` | `deep`）。
- `[context...]`：其余空白分隔 token 作为上下文传入。

多数示例里 `root` 和 `mode` 都省略了。

## 工具脚本

脚本是**无 AI agent 场景的 fallback 路径**（CI、离线 bootstrap、手动使用）。有 agent 时优先让 agent 执行——agent 的判断更细。两条路径写入同一份磁盘契约。

- `scripts/ms-init.sh` / `scripts/ms-init.ps1`：创建 minispec 目录结构与基线文件。_(主路径——始终由脚本执行)_
- `scripts/ms-doctor.sh` / `scripts/ms-doctor.ps1`：结构 + 语义体检。_(主路径——始终由脚本执行)_
- `scripts/ms-project.sh` / `scripts/ms-project.ps1`：自动生成 `minispec/project.md`。_(fallback；有 agent 时优先 in-context 生成)_
- `scripts/ms-close.sh` / `scripts/ms-close.ps1`：关闭 change card 并自动合并到一份 domain spec。_(fallback；有 agent 时优先 in-context 关卡)_
安装好 `minispec` 后（见[安装](#安装)），推荐直接用全局命令而不是直调脚本：

| CLI 命令                                 | 背后的脚本                                    |
|------------------------------------------|-----------------------------------------------|
| `minispec init <dir>`                    | `scripts/ms-init.sh` / `scripts/ms-init.ps1`   |
| `minispec doctor [<dir>]`                | `scripts/ms-doctor.sh` / `scripts/ms-doctor.ps1` |
| `minispec project ...`                   | `scripts/ms-project.sh` / `scripts/ms-project.ps1` |
| `minispec close <id> <domain> [<dir>]`   | `scripts/ms-close.sh` / `scripts/ms-close.ps1` |
| `minispec --version`                     | 读取安装目录下的 `VERSION`                    |

脚本本身保留下来，用于 CI 或没有安装全局 CLI 的离线环境。

POSIX shell 示例：

```sh
sh scripts/ms-init.sh .
sh scripts/ms-doctor.sh .
sh scripts/ms-close.sh 20260323-refund-filter refunds .
```

PowerShell 示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-init.ps1' -Root ."
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-close.ps1' -ChangeId 20260323-refund-filter -Domain refunds -Root ."
```

## 快速开始

### A. 新项目

1. 初始化目录结构与基线文件。

```sh
sh scripts/ms-init.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-init.ps1' -Root ."
```

2. 直接生成 `project.md`（guided 或 context 驱动）。

在 `minispec/project.md` 中创建或刷新以下段落：

- `## Stack`（`Language`、`Framework`、`Runtime`）_[CLI 自动填充]_
- `## Commands`（`Install`、`Build`、`Test`、`Lint`）_[CLI 自动填充]_
- `## Engineering Constraints` _[手动维护]_
- `## Non-Goals` _[手动维护]_
- `## Definition of Done` _[手动维护]_
- `## Generation Metadata` _[CLI 自动填充]_
- `## Guided Inputs` _[未确定项自动填充]_
- 可选 `## Maintainer Notes` _[手动维护]_

栈检测无法确定时，保留显式 `TBD` 占位，不要瞎猜。

3. Review 并编辑 `minispec/project.md`。

生成的是草稿。把 Stack 与 Commands 改为你的真实值。

4. 建第一张 change card。

复制模板并按 change id 重命名：

```text
minispec/changes/20260323-your-change.md
```

填充：

- Why
- Scope（In/Out）
- Acceptance（Given/When/Then）
- Plan（任务 checklist）

### B. 已有项目

1. 跑 doctor。

```sh
sh scripts/ms-doctor.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
```

2. 直接从仓库上下文生成或刷新 `project.md`。

能检测到的栈与命令优先从项目文件识别；识别不到则用 guided 占位。

若 `minispec/project.md` 已存在：auto-filled 段刷新，manual-maintained 段保留；段边界不清楚时先写一份时间戳后缀的备份。

3. Review 并修正命令。

检测命令仅供参考。实施前请确认 `Install` / `Build` / `Test` / `Lint`。

### C. 在 AI CLI 中使用（Codex / Claude）

两个平台命令完全一致，仅入口文件与 skill 路径不同。

1. Codex 下运行。

确保仓库含 `AGENTS.md` 与 `.agents/skills/minispec/SKILL.md`。

2. Claude Code 下运行。

确保仓库含 `CLAUDE.md` 与 `.claude/skills/minispec/SKILL.md`。

两种环境都请 agent 运行同样的命令：

- `minispec project nextjs saas app`
- `minispec new add refund filter`
- `minispec apply 20260323-refund-filter`
- `minispec check 20260323-refund-filter`
- `minispec analyze deep`
- `minispec close 20260323-refund-filter`

若想显式指定 `root` 和 `mode`，用完整形式，例如 `minispec project . auto nextjs saas app` 或 `minispec analyze deep .`。

### D. 关卡条件

满足以下三点才可 close：

- Acceptance 全部打勾
- 测试通过
- `minispec/specs/` 里对应 domain 已更新

### E. Doctor 与自动 close

结构与语义体检：

```sh
sh scripts/ms-doctor.sh .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-doctor.ps1' -Root ."
```

关闭并自动合并一张已完成 change：

```sh
sh scripts/ms-close.sh 20260323-refund-filter refunds .
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'scripts/ms-close.ps1' -ChangeId 20260323-refund-filter -Domain refunds -Root ."
```

### F. 规范分析

在 AI CLI 中，`analyze` 是 agent 驱动动作，不要依赖本地分析脚本。

示例：

- `minispec analyze quick`
- `minispec analyze normal`
- `minispec analyze deep`

模式含义：

- `quick`：项目级概览。
- `normal`：项目 + 子项目/模块边界。
- `deep`：项目 + 子项目 + 关键逻辑热点。

## 仓库结构 vs 被引入项目的结构

本仓库的外层目录就叫 `minispec/`，里面再套一层 `minispec/` 作为合同目录（放 project.md、specs、changes、archive、templates）。下游项目通过 `scripts/ms-init.sh` 引入 minispec 时，只会在自己仓库里得到一层合同目录——不会出现 `minispec/minispec/` 嵌套。

本仓库（模板源）：

```text
minispec/                     # 仓库根（恰好也叫 minispec）
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── minispec/                 # 合同目录（ms-init 会把它复制过去）
│   ├── project.md
│   ├── specs/
│   ├── changes/
│   ├── archive/
│   └── templates/
├── .agents/ .claude/         # 平台 skill 入口
└── scripts/                  # fallback 脚本
```

被引入项目：

```text
my-app/                       # 任意下游仓库
├── AGENTS.md 和/或 CLAUDE.md
├── minispec/                 # 只有一层——合同目录直接住在这里
│   ├── project.md
│   ├── specs/
│   ├── changes/
│   └── archive/
└── src/ ...                  # 项目原有代码
```

## 目录结构

```text
minispec/
  project.md
  specs/
  changes/
  archive/
  templates/
```

## 文件规范

- `changes/` 每个活动变更单独一个文件。
- `specs/` 是已上线行为的唯一真源。
- 完成后移动到 `archive/`。

## 推荐的 Change ID

`YYYYMMDD-short-slug`，例如：`20260323-refund-filter`。
