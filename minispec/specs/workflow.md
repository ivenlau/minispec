# workflow

Canonical shipped behavior for minispec's own 6-action workflow. This spec describes what each action must do from the perspective of an agent or script executing it. Both `SKILL.md` files and the `scripts/ms-*` implementations must satisfy this spec.

## Actions Overview

The workflow consists of six ordered actions: `project`, `new`, `apply`, `check`, `analyze`, `close`. `project` runs once per repository and whenever stack/commands change. Change-cards flow through `new` → `apply` → `check` → `close`; `analyze` is on-demand. A `init` bootstrap step (see below) runs once per repository before `project`.

## Bootstrap: init

`init` is not one of the six workflow actions; it is the bootstrap script (`ms-init.sh` / `ms-init.ps1`) that scaffolds the contract directory into a target project and wires minispec into that project's `.gitignore` by default.

- Given `ms-init` runs with target `<dir>`, Then `<dir>/minispec/{specs,changes,archive,templates}`, `<dir>/.agents/skills/minispec/SKILL.md`, `<dir>/.claude/skills/minispec/SKILL.md`, `<dir>/AGENTS.md`, and `<dir>/CLAUDE.md` are created (files copied from the install share directory when present, minimal defaults otherwise).
- Given `ms-init` runs without `--no-gitignore` / `-NoGitignore`, Then a marker-wrapped block is appended to `<dir>/.gitignore` (file created if missing) hiding `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, and `minispec/` from git.
- Given `ms-init` runs with `--no-gitignore` / `-NoGitignore`, Then `<dir>/.gitignore` is not created or modified.
- Given a previous `ms-init` already installed the marker (the line `# >>> minispec` exists in `<dir>/.gitignore`), When `ms-init` runs again on the same target, Then the marker block is NOT appended a second time.
- Given the user wants to commit minispec alongside their code (team mode), Then they remove the marker block from `<dir>/.gitignore` manually; `ms-init` does not undo its own ignore write.

### project

Inputs: optional `[root]`, optional mode (`auto` | `existing` | `new`), optional free-form context string.

- Given `minispec/project.md` does not exist, When `project` runs, Then a new file is generated with sections `Stack`, `Commands`, `Engineering Constraints`, `Non-Goals`, `Definition of Done`, `Generation Metadata`, optional `Detection Notes`, optional `Guided Inputs`, and a trailing `Maintainer Notes` with the manual-managed marker.
- Given `minispec/project.md` exists, When `project` runs, Then auto-managed sections are refreshed, `Maintainer Notes` content is preserved verbatim, and a `.bak.<YYYYMMDDHHmmss>` copy is written.
- Given stack detection is uncertain, When `project` runs, Then fields fall back to `TBD` placeholders instead of guessing.

### new

Inputs: a free-form `<idea>` or scope description.

- Given the workspace has `minispec/project.md` and `minispec/templates/change.md`, When `new` runs, Then exactly one file is created at `minispec/changes/<YYYYMMDD-slug>.md` based on the template.
- Given the user's intent is ambiguous (purpose / constraints / success criteria not fully knowable from the request), When `new` runs, Then the agent asks ONE clarifying question at a time and waits for an answer before proceeding — no multi-question paragraphs, no guessing.
- Given the problem admits more than one reasonable implementation, When `new` runs, Then the agent proposes 2–3 named approaches with per-approach trade-offs and a recommendation, and waits for the user's pick (or explicit delegation) before writing the card.
- Given only one approach is reasonable, When `new` runs, Then the agent names it in the card's `Approach` section and moves on without fabricating alternatives.
- Given the change card is populated, When reviewed, Then `Why`, `Approach`, `Scope`, `Acceptance`, and an initial `Plan` are all filled; `status` in frontmatter is `draft`.

### apply

Inputs: `<change-id>`.

- Given an active card `minispec/changes/<id>.md`, When `apply` runs, Then only tasks listed in the card's `Plan` are executed; completed tasks are ticked `- [x]`.
- Given scope shifts mid-flight, When continuing `apply`, Then `Scope` is updated and one matching `Acceptance` item is added before new code is written.
- Given any task in `Plan` is incomplete, When `apply` finishes, Then the card is NOT moved to archive; closing happens in a separate `close` action.

### check

Inputs: `<change-id>`.

- Given `minispec/project.md` defines `Test` and `Lint`, When `check` runs, Then those commands are executed and their results are appended under the card's `Notes` section.
- Given every `Acceptance` item has evidence of passing, When `check` finishes, Then status may advance toward `closed`; otherwise status stays at `draft` or `in_progress`.

### analyze

Inputs: mode (`quick` | `normal` | `deep`), optional `[root]`.

- Given mode is `quick`, When `analyze` runs, Then `minispec/specs/project-map.md` is refreshed and `minispec/specs/README.md` is updated with an analysis snapshot.
- Given mode is `normal`, When `analyze` runs, Then additionally `minispec/specs/subprojects.md` is produced.
- Given mode is `deep`, When `analyze` runs, Then additionally `minispec/specs/logic-deep-dive.md` is produced with hotspot analysis flagged as heuristic.
- Given `minispec/specs/README.md` has a `## Maintainer Notes` section, When `analyze` rewrites the file, Then that section's content is preserved.

### close

Inputs: `<change-id>`, `<domain>`.

- Given the card's `Acceptance` section has any `- [ ]` line, When `close` is invoked, Then it fails with an error message pointing to Acceptance, and the card stays in `minispec/changes/`. `Plan` unchecked items MUST NOT block close.
- Given Acceptance is fully ticked, When `close` runs, Then `Why`, `Scope`, `Acceptance`, and `Notes` are appended to `minispec/specs/<domain>.md` under a new `## Change <id> (<date>)` heading; `Plan` and `Risks and Rollback` are not copied into the spec.
- Given the merged spec block is written, When inspected, Then the first Notes lines include `Auto-merged from \`minispec/changes/<id>.md\`` and `See \`minispec/archive/<id>.md\` for plan and risk notes.`.
- Given merge succeeds, When close continues, Then frontmatter `status` in the change file becomes `closed` and the file is moved to `minispec/archive/<id>.md`.
- Given the target archive path already exists OR the spec already contains `## Change <id>`, When `close` is invoked, Then it fails before any move or append happens.

## Pause / Resume

`pause` and `resume` are ceremony-control commands, not workflow actions. They let the user temporarily disable the `new` → `apply` → `check` → `close` flow for quick edits, exploration, or debugging.

- Given `minispec pause` runs at `<root>`, Then `<root>/minispec/.paused` is created with `paused_at: <UTC ISO8601>` and optional `reason: <text>`. If the marker already exists, `ms-pause` does NOT overwrite it and reports how long it has been paused.
- Given `minispec resume` runs at `<root>`, Then `<root>/minispec/.paused` is removed and the duration of the pause is reported. If the marker does not exist, the command prints "minispec is not paused." and exits successfully.
- Given `minispec/.paused` exists, When the user's next request does NOT explicitly invoke `minispec <action>` or reference a change id, Then agents skip `new` / `apply` / `check` / `close` ceremony and make edits directly; Guardrails still apply.
- Given `minispec/.paused` exists, When the user explicitly invokes `minispec <action>` (e.g., `minispec new add-refund-filter`), Then agents honor the invocation — pause affects the default, not explicit intent.
- Given `minispec/.paused` exists and `paused_at` is more than 4 hours in the past, When `ms-doctor` runs, Then a `[WARN] minispec has been paused for <duration>` line is emitted (Result still PASS; pause is advisory, not error).
- Given `minispec/.paused` is within 4 hours of `paused_at`, When `ms-doctor` runs, Then no pause-related WARN is emitted.

The marker file is always excluded from git via `<root>/minispec/.gitignore` (dropped by `ms-init`), so pause state stays per-developer regardless of whether the project uses dev-local or team-mode git tracking.

## Parity Invariants

- `scripts/ms-close.sh` and `scripts/ms-close.ps1` MUST produce byte-equivalent Notes merge blocks (modulo line-ending conventions) for the same input card.
- `scripts/ms-project.sh` and `scripts/ms-project.ps1` MUST emit the same Stack/Commands/Framework detection for a given repository, given identical package/lockfile layouts.
- `scripts/ms-doctor.sh` and `scripts/ms-doctor.ps1` MUST emit the same set of `[WARN]` and `[OK]` lines (modulo ordering) for the same repository state.

## Maintainer Notes

<!-- manual-managed; preserved when this file is regenerated by analyze -->

- This spec is the single source of truth for action semantics; when SKILL rules or script behavior changes, update this file in the same card.

## Change 20260422-p1-dogfood-project-and-workflow-spec (2026-04-22)

### Why

仓库自带的 `minispec/project.md` 仍是全 `TBD` 的初始模板，且 `minispec/specs/` 里只有 `README.md` 的占位，没有任何 domain spec。这让"这个工具怎么用自己"的回答缺失——`ms-doctor` 会一直因 `TBD` 报 WARN（P1-d 新增的语义检查）；潜在贡献者也看不到 minispec 如何描述自身约束。

本卡把 project.md 改写成描述 minispec 自身（POSIX sh + PowerShell 7 + Markdown，约束是双实现 parity、零 runtime 依赖），并新增 `minispec/specs/workflow.md` 作为 6-action workflow 的自描述 spec。

### Scope

- In:
  - 改写 `minispec/project.md`：
    - Stack 填真实栈（POSIX sh、PowerShell 7+、Markdown）。
    - Commands 填真实命令（Install = 无；Build = 无；Test = `sh scripts/ms-doctor.sh .`；Lint = `shellcheck scripts/*.sh` + `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path scripts/*.ps1"`）。
    - Engineering Constraints / Non-Goals / Definition of Done 按 minispec 自身场景写。
    - 保留（或补写）Maintainer Notes 段用 P1-b 的 marker。
  - 新建 `minispec/specs/workflow.md`：
    - 用 Given/When/Then 形式描述 6 个 action 的行为契约（Inputs、关键判定、失败条件）。
    - 结构与其他 domain spec 对齐（close 之后会在文件末尾 append `## Change ...` 块）。
- Out:
  - 不修改脚本（本卡只是用它）。
  - 不补历史 archive 卡。

### Acceptance

- [x] Given 运行 `sh scripts/ms-doctor.sh .`，When 读取 Semantic checks 输出，Then 不再出现 `still contains TBD placeholders`。
- [x] Given 打开 `minispec/project.md`，Then `## Stack` 与 `## Commands` 所有字段都有具体值（无 `TBD`）。
- [x] Given 打开 `minispec/project.md`，Then 末尾存在 `## Maintainer Notes` 段与 manual-managed marker 注释。
- [x] Given 打开 `minispec/specs/workflow.md`，Then 存在 6 个 `### <action>` 子段，每段包含至少一个 `Given/When/Then` 三元组。
- [x] Given 对本卡执行 `ms-close.sh <id> workflow .`，Then 合并块 append 到 `minispec/specs/workflow.md`，且原有 workflow 规则段保留。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-dogfood-project-and-workflow-spec.md`
- See `minispec/archive/20260422-p1-dogfood-project-and-workflow-spec.md` for plan and risk notes.

- 决策：`Test` 命令选 `ms-doctor` 而不是"跑一组 bats/Pester 测试"——后者在 P2-2 引入；当前 minispec 的"测试"只是结构 + 语义检查。
- 决策：workflow.md 的 BDD 三元组面向 agent 与人类共读，先于实现的细节——脚本与 SKILL 都应该符合这些契约。

## Change 20260424-pause-resume (2026-04-24)

### Why

minispec 的完整流程（`new` → clarify → propose → `apply` → `check` → `close`）对小改动是摩擦——一个 typo、一行 log 调整、调试期间的反复试错都被 ceremony 拖慢。用户需要一个显式"暂停"开关：临时关闭 ceremony，把控制器交还给自己；需要时再 resume，回到 spec-first 纪律。

选型已讨论：B（显式标记文件）+ 两条子决策：
- 默认无 TTL，由 `ms-doctor` 在超 4 小时后 WARN。
- `resume` 默认不主动问"要不要补卡"，减少二次 ceremony。

### Scope

- In:
  - 新增脚本：`scripts/ms-pause.sh` / `.ps1` 创建 `minispec/.paused`（两行 key:value：`paused_at: ISO8601Z` + 可选 `reason: …`）；已存在不覆盖，打印 "already paused since X (Yh Ym ago)"。
  - 新增脚本：`scripts/ms-resume.sh` / `.ps1` 删 `minispec/.paused`，打印 "resumed (was paused for Xh Ym)"；未暂停时友好报 "not paused"，exit 0。
  - `bin/minispec` / `bin/minispec.ps1` launcher：加 `pause` / `resume` 两个 action 分支。
  - 三份 SKILL 在 `## Commands` 之后、`## Behavior` 之前插入 `## Pause Awareness` 小节，定义规则："若 `minispec/.paused` 存在且用户请求未显式调用 `minispec <action>`，按普通编码任务处理，不走 ceremony；每个 session 仅提示一次。"
  - `minispec/specs/workflow.md` 加 `## Pause / Resume` BDD 小节，把上述行为固化成契约（含 doctor 4h WARN 规则）。
  - `scripts/ms-doctor.sh` / `.ps1`：语义检查新增——若 `.paused` 存在且 `paused_at` 距今 > 4 小时，WARN；存在但 < 4 小时，只 `[OK] minispec paused (Xh Ym)` 信息行（不 WARN）。
  - `scripts/ms-init.sh` / `.ps1`：在 scaffold 末尾追加 `minispec/.gitignore` 内容（`.paused` + `*.bak.*`）——确保 "team 模式"（用户移除了根 `.gitignore` marker 块）下，pause 状态仍不污染 git。
  - `README.md` / `README.zh-CN.md` 新增 "Pausing minispec" 段：典型场景 / 命令 / 4h WARN 约定。
  - `CHANGELOG.md` Unreleased > Added 追加。
  - `tests/bats/pause.bats`（新）+ `tests/pester/Pause.Tests.ps1`（新）：pause 幂等、resume 幂等、pause 后 doctor 超 4h 触发 WARN、`minispec/.gitignore` 生成。
- Out:
  - 不在 `resume` 里主动问补卡（用户子决策 2）。
  - 不做自动 TTL / 自动 resume（用户子决策 1）。
  - 不把 pause 标记同步到全局（每仓独立）。
  - 不在 SKILL 规则里实现 "每 session 仅提示一次" 的状态机——agent 侧软约定即可；约束到具体次数是 agent 难以严格保证的事情。

### Acceptance

- [x] Given 干净目录，When 跑 `minispec pause --reason "debug loop"`，Then `minispec/.paused` 存在，内容含 `paused_at:` 和 `reason: debug loop`。
- [x] Given 已经 paused，When 再次跑 `minispec pause`，Then 不覆盖，输出含 "already paused since"。
- [x] Given `.paused` 存在，When 跑 `minispec resume`，Then 文件被删，输出含 "resumed (was paused for"。
- [x] Given `.paused` 不存在，When 跑 `minispec resume`，Then 输出 "minispec is not paused."，exit 0。
- [x] Given `.paused` 的 `paused_at` 是 5 小时前，When 跑 `ms-doctor`，Then Semantic checks 含 "paused for 5h" 的 WARN 行。
- [x] Given `.paused` 的 `paused_at` 是 1 小时前，When 跑 `ms-doctor`，Then 不 WARN（可能有 info 行）。
- [x] Given `ms-init` 新建目录，When 查看 `minispec/.gitignore`，Then 至少含 `.paused` 一行。
- [x] Given 三份 SKILL，When grep `Pause Awareness`，Then 三份都命中且 Guardrails 同步检查无 WARN。
- [x] Given `specs/workflow.md`，When grep `## Pause / Resume`，Then 命中并含 4 小时阈值的 BDD。

### Notes
- Auto-merged from `minispec/changes/20260424-pause-resume.md`
- See `minispec/archive/20260424-pause-resume.md` for plan and risk notes.

- 决策：`.paused` 文件放 `minispec/.paused`，跟合同目录同级便于 `ls minispec/` 肉眼识别；`minispec/.gitignore` 里一并屏蔽，保证 team 模式下不污染 git。
- 决策：Pause Awareness 规则放在 SKILL 的 `## Commands` 之后、`## Behavior` 之前——逻辑上是 "执行任何 action 之前先检查"。
- 决策：4 小时阈值是建议值，不是科学推导——假设"半天调试 cap"。用户反馈后可调。
- 决策：显式调用 `minispec <action>` 可以绕过 pause（例如用户就是要在 paused 时主动 new 一张卡）。pause 影响的是默认行为，不是显式意图。
