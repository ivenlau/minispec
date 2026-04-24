---
id: 20260424-pause-resume
status: closed
owner: claude
---

# Why

minispec 的完整流程（`new` → clarify → propose → `apply` → `check` → `close`）对小改动是摩擦——一个 typo、一行 log 调整、调试期间的反复试错都被 ceremony 拖慢。用户需要一个显式"暂停"开关：临时关闭 ceremony，把控制器交还给自己；需要时再 resume，回到 spec-first 纪律。

选型已讨论：B（显式标记文件）+ 两条子决策：
- 默认无 TTL，由 `ms-doctor` 在超 4 小时后 WARN。
- `resume` 默认不主动问"要不要补卡"，减少二次 ceremony。

# Approach

- Considered:
  - **A. 短语级逃生口**（在 SKILL 写"用户说 X 则跳过"）：零基础设施但状态隐式、识别模糊。
  - **B. 显式标记 + `pause`/`resume` 命令**（选中）：状态显式、persistent、用户自控。
  - **C. 事后补卡**：绕开前置摩擦但把 ceremony 移到后面；精度依赖 agent 的 session 记忆。
- Chosen: **B**。理由：状态显式是本质——用户需要的是"知道自己现在是不是在 bypass"，短语级做不到。

# Scope

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

# Acceptance

- [x] Given 干净目录，When 跑 `minispec pause --reason "debug loop"`，Then `minispec/.paused` 存在，内容含 `paused_at:` 和 `reason: debug loop`。
- [x] Given 已经 paused，When 再次跑 `minispec pause`，Then 不覆盖，输出含 "already paused since"。
- [x] Given `.paused` 存在，When 跑 `minispec resume`，Then 文件被删，输出含 "resumed (was paused for"。
- [x] Given `.paused` 不存在，When 跑 `minispec resume`，Then 输出 "minispec is not paused."，exit 0。
- [x] Given `.paused` 的 `paused_at` 是 5 小时前，When 跑 `ms-doctor`，Then Semantic checks 含 "paused for 5h" 的 WARN 行。
- [x] Given `.paused` 的 `paused_at` 是 1 小时前，When 跑 `ms-doctor`，Then 不 WARN（可能有 info 行）。
- [x] Given `ms-init` 新建目录，When 查看 `minispec/.gitignore`，Then 至少含 `.paused` 一行。
- [x] Given 三份 SKILL，When grep `Pause Awareness`，Then 三份都命中且 Guardrails 同步检查无 WARN。
- [x] Given `specs/workflow.md`，When grep `## Pause / Resume`，Then 命中并含 4 小时阈值的 BDD。

# Plan

- [x] T1 写 `scripts/ms-pause.sh` + `scripts/ms-resume.sh`。
- [x] T2 写 `scripts/ms-pause.ps1` + `scripts/ms-resume.ps1`。
- [x] T3 `bin/minispec` 和 `bin/minispec.ps1` 加 dispatch。
- [x] T4 三份 SKILL 追加 `## Pause Awareness`。
- [x] T5 `minispec/specs/workflow.md` 加 `## Pause / Resume` 小节。
- [x] T6 `scripts/ms-doctor.sh` / `.ps1` 加 pause 状态检查（4h 阈值）。
- [x] T7 `scripts/ms-init.sh` / `.ps1` 加 `minispec/.gitignore` 写入。
- [x] T8 README 中英双语加 "Pausing minispec" 段。
- [x] T9 CHANGELOG 追加。
- [x] T10 写 `tests/bats/pause.bats` + `tests/pester/Pause.Tests.ps1`。
- [x] T11 端到端本地验证：pause / resume 幂等、doctor 在 5h 之前/之后行为不同、ms-init 生成 minispec/.gitignore。
- [x] T12 close → commit → push。

# Risks and Rollback

- Risk: 用户 pause 后忘记 resume，长期静默 bypass。Rollback: doctor 4h WARN 是主防线；如还不够，后续加 `minispec doctor --strict` 把 paused 视为 FAIL。
- Risk: `.paused` 时间戳解析在极老 BSD `date` 上失败。Rollback: 脚本已经有 GNU/BSD 双分支模式（见 ms-doctor 的 staleness check）；沿用。
- Risk: Agent 在 paused 状态下仍想走 ceremony（SKILL 规则是软的）。Rollback: SKILL 再加一句"paused 时禁止主动创建 change card"更强硬；先按当前措辞观察。

# Notes

- 决策：`.paused` 文件放 `minispec/.paused`，跟合同目录同级便于 `ls minispec/` 肉眼识别；`minispec/.gitignore` 里一并屏蔽，保证 team 模式下不污染 git。
- 决策：Pause Awareness 规则放在 SKILL 的 `## Commands` 之后、`## Behavior` 之前——逻辑上是 "执行任何 action 之前先检查"。
- 决策：4 小时阈值是建议值，不是科学推导——假设"半天调试 cap"。用户反馈后可调。
- 决策：显式调用 `minispec <action>` 可以绕过 pause（例如用户就是要在 paused 时主动 new 一张卡）。pause 影响的是默认行为，不是显式意图。
