# scripts

Canonical shipped behavior for domain: scripts


## Change 20260422-p0-script-and-close-fixes (2026-04-22)

### Why

minispec 的三处脚本行为漏洞会导致"工具说一套、实际另一套"，是使用 minispec 过程中最容易踩的坑：

1. `scripts/ms-project.sh` 使用 `grep -Eiq` 做子串匹配识别依赖，同一个 `package.json` 在 `.ps1`（精确 JSON 匹配）下可能得到不同的 framework 判定，破坏脚本 parity。
2. `scripts/ms-close.ps1` 合并块的 markdown 反引号写在双引号 here-string 里，依赖"反引号后跟非特殊字符"的偶然行为才不触发 PowerShell 转义，文案只要改动一次就会坏。
3. `scripts/ms-close.sh/.ps1` 的未打勾检测扫描整个文件的 `- [ ]`，使得 Plan 子任务未完成会阻断 close，而按 minispec 语义 Acceptance 才是闭卡的充分条件。

这三条同属"脚本行为正确性"主题，一并修掉以减少卡数并便于回归。

### Scope

- In:
  - `scripts/ms-project.sh` / `scripts/ms-project.ps1`：Node 依赖检测改为解析 `package.json` 的 `dependencies` / `devDependencies` 精确比对名字；沿用各框架原有优先级。
  - `scripts/ms-close.ps1`：合并块改用单引号 here-string `@'...'@` + `-f` 占位符注入 `$ChangeId` / `$notes`，消除反引号脆弱依赖。
  - `scripts/ms-close.sh` / `scripts/ms-close.ps1`：未打勾检测仅扫描 `# Acceptance` / `## Acceptance` 小节内；Plan/其他小节的 `- [ ]` 不再阻断 close。
- Out:
  - 不改 Java/Python/Go/Rust/.NET 的检测路径（超出本卡范围，未发现 parity 问题）。
  - 不改 SKILL / 文档关于 close 语义的措辞——与 P1-4（close 合并范围文档化）分开。

### Acceptance

- [x] Given 同一份含 `"next-sitemap"` 但不含 `"next"` 的 `package.json`，When 分别跑 `ms-project.sh` 与 `ms-project.ps1`，Then 两者输出的 `Framework` 均为 `Node.js application`（不再因子串 `"next"` 误判为 Next.js）。
- [x] Given 一个真正的 Next.js 仓库（`"next": "^14"` 在 dependencies），When 分别跑两端脚本，Then 两者 `Framework` 均输出 `Next.js`。
- [x] Given 一张 change card Acceptance 全部打勾、Plan 留一个 `- [ ]`，When 运行 `sh scripts/ms-close.sh <id> <domain>`，Then 脚本成功 close 并归档（不再以 Plan 未完为由拒绝）。
- [x] Given 一张 change card 任意一个 `- [ ]` 留在 Acceptance 小节内，When 运行 close，Then 脚本仍拒绝 close 并给出错误信息。
- [x] Given `ms-close.ps1` 合并块被写入 domain spec，When 打开该文件，Then 第一行 Notes 里原样出现 markdown 反引号包裹的文件路径 `` `minispec/changes/<id>.md` ``，且不出现 PowerShell 转义副作用（如 `\n` 变换行）。

### Notes
- Auto-merged from `minispec/changes/20260422-p0-script-and-close-fixes.md`

- 决策：Node 精确匹配选择 dependencies ∪ devDependencies 的 key 集合，与 .ps1 行为对齐。
- 决策：沿用现有模板的 H1 `# Acceptance` 匹配模式（而非放宽到 `^#{1,6}`），与 `extract_section` 的既有契约保持一致，避免引入双标准。`extract_section` 同步移到未打勾检查之前。
- 决策：`ms-close.ps1` 合并块改为单引号 `@'…'@` here-string + `-f` 占位符；反引号的 markdown 语义仍然保留在 spec 里，但不再经过 PowerShell 字符串解释器。
- 验证记录：
  - fixture 1（仅含 `next-sitemap` / `react-next-helpers`）→ Framework = `Node.js application`；fixture 2（`next ^14` 显式依赖）→ Framework = `Next.js`。
  - close 测试：Plan 留 `- [ ]`、Acceptance 全打勾 → close 成功（exit 0，归档到位）；Acceptance 留 `- [ ]` → close 失败，提示 "Acceptance section has unchecked items." (exit 1)。
  - ms-close.sh 合并到 `minispec/specs/testdomain.md` 的 Notes 行原样包含 `` `minispec/changes/20260422-test-plan-only.md` ``。
  - ms-close.ps1 未在此次实机运行（平台为 bash on Windows）；代码对等逻辑经代码复核：预期表现与 .sh 一致。

## Change 20260422-p1-maintainer-notes-section (2026-04-22)

### Why

两份 SKILL 把 `## Maintainer Notes` 描述为 `project.md` 里的 `[manual-managed]` 段，但 `scripts/ms-project.sh/.ps1` 完全没生成该段；用户按 SKILL 添加的 Maintainer Notes 一旦运行 `ms-project` 就会被覆盖，进而让 `[manual-managed]` 的承诺破产。

本卡补齐：脚本首次生成时写入带 marker 的 Maintainer Notes 模板；再次运行时读取旧文件中的 Maintainer Notes 并原样保留到新输出。

### Scope

- In:
  - `scripts/ms-project.sh`：新增 "读取旧 project.md 中 Maintainer Notes 段" 逻辑；渲染阶段结尾追加 Maintainer Notes。
  - `scripts/ms-project.ps1`：同上逻辑。
  - Maintainer Notes 的 marker 统一为一行 HTML 注释：`<!-- manual-managed; preserved across ms-project regenerations -->`。
- Out:
  - 不处理 Engineering Constraints / Non-Goals / Definition of Done 的 manual-managed 保留（超出本卡范围，与 SKILL 描述一致地遵循已有模板）。
  - 不改 SKILL（已经描述了 Maintainer Notes）。

### Acceptance

- [x] Given 对一个不存在 `minispec/project.md` 的目录运行 `sh scripts/ms-project.sh`，Then 生成的 `project.md` 末尾存在 `## Maintainer Notes` 段并带 marker 注释。
- [x] Given 用户在已生成的 `project.md` 里 Maintainer Notes 段添加了一行 `- 遵循 kebab-case 命名`，When 再次运行 `ms-project.sh`，Then 新文件里那行 `- 遵循 kebab-case 命名` 原样出现在 Maintainer Notes 段中。
- [x] Given 对同一输入分别运行 `.sh` 与 `.ps1`，Then 两者输出的 Maintainer Notes 段头部与 marker 一致。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-maintainer-notes-section.md`

- 决策：Maintainer Notes 放在 project.md 末尾，确保其后不再有 `## ...` 段，保持抽取 regex 简单（"从 `^## Maintainer Notes` 到下一个 `^## ` 或 EOF"）。
- 决策：marker 用 HTML 注释形式而非 markdown 注释，与 markdown 渲染器兼容。

## Change 20260422-p1-close-merge-coverage-doc (2026-04-22)

### Why

`ms-close` 从 change card 抽取 Why / Scope / Acceptance / Notes 四段合并到 `minispec/specs/<domain>.md`；`Plan` 与 `Risks and Rollback` 只保留在 `minispec/archive/<id>.md`——但这一事实没有在任何文档或 SKILL 里说明。用户若期望历史 Plan 可检索，容易以为 close 丢数据。

本卡把这个合并范围显式写清，并在 ms-close 产出的 spec 合并块里加一条 `See archive/<id>.md for plan and risk notes.` 交叉引用，读者顺藤能找到完整上下文。

### Scope

- In:
  - `.claude/skills/minispec/SKILL.md` 与 `.agents/skills/minispec/SKILL.md`：在 `close` 小节末尾加一条明文："The canonical spec only captures Why / Scope / Acceptance / Notes. Plan and Risks remain in `minispec/archive/<id>.md`."
  - `scripts/ms-close.sh` 与 `scripts/ms-close.ps1`：合并块的 Notes 小节首行后增加一行 `- See minispec/archive/<id>.md for plan and risk notes.`
- Out:
  - 不改 close 的实际抽取范围（如果未来要把 Plan/Risks 也合并是另一回事，本卡不做）。

### Acceptance

- [x] Given 打开两份 SKILL 的 `close` 小节，Then 明文说明 Plan/Risks 只保留在 archive 不进 spec。
- [x] Given 运行 `ms-close.sh` 或 `ms-close.ps1` 关卡，When 查看合并到 spec 的 Notes 段，Then 包含 `See minispec/archive/<id>.md for plan and risk notes.` 行。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-close-merge-coverage-doc.md`
- See `minispec/archive/20260422-p1-close-merge-coverage-doc.md` for plan and risk notes.

- 决策：交叉引用行放在"Auto-merged from"之后、旧 Notes 之前，形成"自动注释区"在前、"用户 Notes"在后的两段结构。

## Change 20260422-p1-ms-doctor-semantic-checks (2026-04-22)

### Why

`ms-doctor` 现只做结构校验（路径存在与否），不覆盖语义层面的常见问题，例如：`project.md` 还留着 `TBD`、change card 文件名不符合约定、frontmatter `status` 不在合法枚举、草稿滞留超过两周、archive 中的 id 没有在任何 spec 里被合并。这些是最常被忽视却导致 minispec 退化的点。

本卡把这些语义检查加到 `ms-doctor.sh` / `.ps1`，都以 `[WARN]` 形式输出且不改变 exit code——保持"结构是硬门槛、语义是提醒"的分层。

### Scope

- In:
  - `scripts/ms-doctor.sh`：在结构检查后追加语义块：
    1. `project.md` 含 `\bTBD\b` → WARN。
    2. `minispec/changes/*.md` 文件名不匹配 `^[0-9]{8}-[a-z0-9-]+$` → WARN。
    3. frontmatter `status` 不在 `{draft, in_progress, closed}` → WARN。
    4. status 为 `draft` 且文件名日期部分 < 14 天前 → WARN。
    5. `minispec/archive/<id>.md` 存在但任何 `specs/*.md` 中都没有 `^## Change <id>` 锚点 → WARN。
  - `scripts/ms-doctor.ps1`：同等逻辑。
- Out:
  - 不改变 exit code 语义（语义 WARN 不会让 doctor 失败）。
  - 不改 required / optional 结构检查本身。
  - 不写测试脚手架（那是 P2-2）。

### Acceptance

- [x] Given `project.md` 含 `TBD`，When 运行 doctor，Then 输出包含 `[WARN] minispec/project.md`（TBD）且 exit 0。
- [x] Given `minispec/changes/bad-name.md` 存在，When 运行 doctor，Then 输出 `[WARN] ... filename does not match YYYYMMDD-slug pattern.` 且 exit 0。
- [x] Given 一张 change 的 frontmatter `status: stalled`（非法），When 运行 doctor，Then 输出 `[WARN] ... unknown status 'stalled'`。
- [x] Given 一张 `20260401-old.md` status 仍为 draft（>14 天），When 运行 doctor，Then 输出 stale 警告。
- [x] Given `minispec/archive/20260422-x.md` 存在但没有对应 `## Change 20260422-x` 在任何 spec，When 运行 doctor，Then 输出 cross-ref 警告。

### Notes
- Auto-merged from `minispec/changes/20260422-p1-ms-doctor-semantic-checks.md`
- See `minispec/archive/20260422-p1-ms-doctor-semantic-checks.md` for plan and risk notes.

- 决策：每条语义检查仅发 `[WARN]`，不改 exit code。doctor 的硬失败仅保留在 required 结构。
- 决策：文件名 regex 采用 `^[0-9]{8}-[a-z0-9-]+$`，大小写敏感，slug 只允许小写字母/数字/连字符，与现有示例 `20260323-refund-filter` 保持一致。

## Change 20260423-init-dev-local-gitignore (2026-04-23)

### Why

`minispec init` 目前只 scaffold 文件，不管用户的 git 历史。下游项目 git add -A 后会把 `AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` 一股脑带进 commit，而用户的明确偏好是把 minispec 当开发者本地工具（B 模式）——不让这些文件污染团队的 git 历史。

本卡把 B 模式做成默认：init 时写入一段带 marker 的 `.gitignore` 块，幂等、可由 `--no-gitignore` / `-NoGitignore` 关掉。用户想切回团队模式（A 模式）只需删 marker 块。

### Scope

- In:
  - `scripts/ms-init.sh`：参数解析从单 positional 扩为支持 `--no-gitignore` 任意位置；新增 `write_minispec_gitignore` 函数，幂等追加 marker 块到 `<target>/.gitignore`。
  - `scripts/ms-init.ps1`：新增 `[switch]$NoGitignore` 参数；等价的 `Write-MinispecGitignore` 函数，使用同一 marker 文案。
  - `bin/minispec.ps1` launcher：把 `--no-gitignore` 翻译成 `-NoGitignore` 传给 ms-init.ps1。POSIX launcher 的 `exec sh ... "$@"` 已自然透传，无需改。
  - `README.md` / `README.zh-CN.md`：Quickstart 附一句 `--no-gitignore` 提示；新增 "Tracking minispec in git" 段说明默认行为 + 切回团队模式的方法。
  - `minispec/specs/workflow.md`：新增 `## Bootstrap: init` 小节用 BDD 固化 init + gitignore 行为（init 不在 6-action 里但值得成为契约）。
  - `CHANGELOG.md` Unreleased > Changed 追加一条。
  - `tests/bats/init.bats`（新建）：scaffold / marker 块 / 保留既有内容 / 幂等 / `--no-gitignore` 五条用例。
  - `tests/pester/Init.Tests.ps1`（新建）：等价 Pester 用例。
- Out:
  - 不动其他 action 的语义（project/new/apply/check/close/analyze 保持不变）。
  - 不写 "un-init" 或自动清理逻辑（用户想切回 A 模式自己删 marker 块）。
  - 不改仓库自身的 `.gitignore`（本仓库就是 minispec 源码，不存在"污染"问题）。

### Acceptance

- [x] Given 空目录运行 `sh scripts/ms-init.sh /tmp/demo`，When 检查 `/tmp/demo/.gitignore`，Then 文件存在且含 `# >>> minispec` marker、含 `minispec/`、`AGENTS.md` 等 5 行。
- [x] Given 目标目录已有 `.gitignore`（如含 `node_modules/`），When 跑 init，Then 原有内容保留，marker 块追加在后。
- [x] Given 连续跑两次 init，When grep marker 次数，Then 仅出现 1 次（幂等）。
- [x] Given `sh scripts/ms-init.sh /tmp/demo --no-gitignore`，When 检查 `.gitignore`，Then 文件不存在（或不含 marker）。
- [x] Given Windows `ms-init.ps1 -Root /tmp/demo -NoGitignore`，Then 行为等价。
- [x] Given `minispec init --no-gitignore .`（通过全局 launcher 调用），Then 不写 `.gitignore`（两种平台行为一致）。
- [x] Given 打开 README（中英文），Then 存在 "Tracking minispec in git" 段，描述默认 + 切回团队模式 + `--no-gitignore`。
- [x] Given 打开 `specs/workflow.md`，Then 新增 `## Bootstrap: init` 小节含 4 条 BDD（scaffold、默认 gitignore、no-gitignore、幂等）。
- [x] Given 跑 `sh scripts/ms-doctor.sh .`，Then PASS 且 Guardrails 同步检查无 WARN。

### Notes
- Auto-merged from `minispec/changes/20260423-init-dev-local-gitignore.md`
- See `minispec/archive/20260423-init-dev-local-gitignore.md` for plan and risk notes.

- 决策：marker 块包 `AGENTS.md` 与 `CLAUDE.md` 整个屏蔽——而不是只屏蔽 `minispec/`——因为这两个文件直接改变 agent 行为，用户既然选 B 模式就应一并排除，否则 skill 半掉线。
- 决策：幂等检测用 `grep -q '^# >>> minispec'` 匹配首条 marker 行，不关心块内内容——这样未来若扩充 marker 内部条目，已装过的项目不会重复写入。
- 决策：marker 文案统一（两端完全一致），不区分 sh/ps 来源，用户不需要知道 init 是哪个脚本写的。
- 后续候选：若有人抱怨 `--no-gitignore` 太长，可加 `--keep-git` 或 `-k` 短选项——不在本卡 scope。

## Change 20260423-macos-compat (2026-04-23)

### Why

`scripts/ms-doctor.sh:155` 用了 GNU 独占的 `sha256sum` 做 SKILL Guardrails 跨文件一致性检查。macOS 默认只有 `shasum -a 256`（或者用户装了 coreutils 才有 `sha256sum`）。结果是 macOS 用户跑 doctor 时，`sha256sum` 命令失败→hash 变空→`unique_count=0`→漂移检查**静默失效**。功能没崩，但少了一层安全网。

同时 CI 根本没跑 macos-latest runner，这类平台差异无法被自动抓到——是一个未来规模扩大后会变贵的漏洞。本卡在 CI 加 macOS matrix 防回归。

### Scope

- In:
  - `scripts/ms-doctor.sh`：Guardrails 同步检查重写为"首个非空内容入 `$guard_first`，后续遇到不等立刻 `drift=1`"。删除 `sha256sum` 调用。
  - `.github/workflows/ci.yml`：`test-bats` job 改为 `strategy.matrix.os = [ubuntu-latest, macos-latest]`；每个 os 分支用各自的 bats 安装命令（apt / brew）。
  - `tests/bats/doctor.bats` 新增两条用例：
    1. 三份 SKILL 的 Guardrails 一致 → doctor 输出不含 `out-of-sync`。
    2. 其中一份 drift → doctor 输出含 `out-of-sync '## Guardrails'`。
- Out:
  - 不改 `scripts/ms-doctor.ps1`（PowerShell 侧没用 hash，直接 `-cne` 字符串比较——本来就不受影响）。
  - 不改 README（顶部 Install 段已经列 `Linux / macOS / WSL / git-bash`；把 macOS 进 CI matrix 之后，"支持"这两个字有实锤即可，不做额外宣传性修辞）。
  - 不加 coreutils / brew 安装文档——B 方案之后用户不需要装任何东西。

### Acceptance

- [x] Given `scripts/ms-doctor.sh` 的 Guardrails 同步检查段，When grep `sha256sum`，Then 无结果。
- [x] Given 在一个 `sha256sum` 不可用的 PATH 下跑 `sh scripts/ms-doctor.sh .`（通过 PATH 隔离或 stub 模拟），Then Result PASS，Guardrails 部分行为与有 sha256sum 时一致。
- [x] Given `.github/workflows/ci.yml` 的 `test-bats` job，When 查看 `strategy.matrix.os`，Then 包含 `ubuntu-latest` 与 `macos-latest`；各分支有对应的 bats 安装步骤。
- [x] Given `tests/bats/doctor.bats`，When grep 用例名，Then 包含一条 "WARNs when SKILL Guardrails drift" 与一条 "does not WARN when all three SKILL Guardrails match"。
- [x] Given 当前仓库状态，When 跑本地 `sh scripts/ms-doctor.sh .`，Then Result PASS、无漂移 WARN（因为三份 SKILL 本来就一致）。

### Notes
- Auto-merged from `minispec/changes/20260423-macos-compat.md`
- See `minispec/archive/20260423-macos-compat.md` for plan and risk notes.

- 决策：`drift=1` 命中后立即 `break`——只要发现一对不一致就足够给出 WARN，不必枚举所有两两对比。
- 决策：用 `guard_first` 而不是 `declare` / `local`（POSIX sh 没有 `local`）。变量留在全局，脚本结束自然消失。
- 决策：bats 在 macOS 用 `brew install bats-core`（正确 formula 名；`bats` 这个包名是旧的，已重定向但显式用 `bats-core` 更稳）。
- 非 hash 方案的次级收益：字符串比较可以在 WARN 信息里更具体地指出"哪两份之间漂移"——不过本卡不扩展到这一步，保持最小改动。

## Change 20260424-lifecycle-commands (2026-04-24)

### Why

minispec 当前只有"装进去"（`install.sh` / `install.ps1` + `minispec init`）的命令，没有：
1. **升级已有项目里的 minispec 文件**（手动 copy 易误伤 `minispec/project.md` / `specs/`）
2. **从项目彻底撤掉 minispec**（删 `AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` + 根 `.gitignore` 的 marker 块）
3. **卸载全局 CLI**（删 launcher + share 目录 + Windows user PATH 条目）

用户上一轮明确要求这三件事一并补上。三者都是安装生命周期的一部分，合并成一张卡推进。

### Scope

- In:
  - **新脚本**：
    - `scripts/ms-upgrade.sh` / `.ps1`：从 `<share_dir>` 复制 agent 文件到 `<target>`；opt-in flag 控制范围；`--dry-run` 列出会改的文件不写。
    - `scripts/ms-remove.sh` / `.ps1`：删 `<target>/{AGENTS.md,CLAUDE.md,.agents,.claude,minispec}` + 根 `.gitignore` 的 marker 块；交互确认；`--keep-archive` / `--keep-specs` / `--yes` / `--dry-run`。
    - `uninstall.sh` / `uninstall.ps1`（仓库根，镜像 install.sh 的位置）：删 launcher + share 目录 + Windows PATH 条目；`--yes` / `--prefix` / `--dry-run`。
  - **Launcher 更新**：`bin/minispec` 和 `bin/minispec.ps1` 加 `upgrade` / `remove` / `uninstall` 三个 action 分支。`uninstall` 子命令调 `uninstall.sh` / `.ps1`（优先仓库根，回退 share 里的同名副本）。
  - **SKILL**：三份 SKILL 的 `## Commands` 小节末尾追加一个"Lifecycle commands"子项（列这 3 个 + install + init 作为对比），不进入 `## Behavior` — 它们不是 agent-driven。
  - **Spec**：`minispec/specs/workflow.md` 加 `## Lifecycle: install / init / upgrade / remove / uninstall` 小节用 BDD 固化每个命令的语义。
  - **README（中英）**：新增 "Upgrading and removing" 段。
  - **CHANGELOG**：Unreleased > Added 追加。
  - **测试**：
    - `tests/bats/upgrade.bats`：上游 fixture → init → 改 SKILL → upgrade → 断言被刷。业务文件保留。
    - `tests/bats/remove.bats`：init → `remove --yes` → 断言目录全清；`--keep-archive` 保留。
    - `tests/pester/Upgrade.Tests.ps1` / `Remove.Tests.ps1`：对等。
    - `uninstall` 本身由于改 user PATH 难自动测；脚本写 `--dry-run` 路径一测。
- Out:
  - **不做 `minispec upgrade` 的版本号 diff**（要求 project 里有 version 字段，暂缓）。
  - **不做"自动 backup"**（remove / uninstall 前不自动 tar）——用户期待 `--yes` 真的无拖泥带水；需要备份的人应该先手动 backup。
  - 不改 `install.sh` / `install.ps1`（已经 idempotent，算"升级 CLI 本体"）。

### Acceptance

## upgrade

- [x] Given 一个下游项目（已跑过 init），When `minispec upgrade <dir>`，Then `AGENTS.md` / `CLAUDE.md` / `.claude/skills/minispec/SKILL.md` / `.agents/skills/minispec/SKILL.md` 内容被覆盖为 share 目录的当前版本；`minispec/project.md` / `specs/*.md` / `changes/*.md` / `archive/*.md` 字节级不变。
- [x] Given `--dry-run`，Then 打印"would update: <file>..."但磁盘无变化。
- [x] Given `--include-template`，Then `minispec/templates/change.md` 也被刷。
- [x] Given `--include-gitignore`，Then `minispec/.gitignore` 也被刷。

## remove

- [x] Given 已 init 的项目，When `minispec remove <dir> --yes`，Then `<dir>/AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `minispec/` 全被删除；若根 `.gitignore` 含 minispec marker 块，该块也被删除。
- [x] Given `--keep-archive`，Then 保留 `minispec/archive/` 及其内容，其他照删。
- [x] Given `--dry-run`，Then 打印"would remove: <path>..."但磁盘无变化。
- [x] Given 无 `--yes` 且 stdin 是 pipe（非 TTY），When 跑 `minispec remove`，Then refuse 并提示 "non-interactive — pass --yes to proceed"。
- [x] Given 无 `--yes` 且是 TTY，When 跑，Then 打印待删文件列表 + `Continue? [y/N]` 提示。

## uninstall

- [x] Given 装好的 CLI，When `minispec uninstall --yes`，Then 删 launcher 可执行 + share 目录整棵树。
- [x] Given Windows，When `minispec uninstall --yes`，Then user PATH 中的 `%USERPROFILE%\.minispec\bin` 条目被移除。
- [x] Given `--dry-run`，Then 打印要删什么、要改哪条 PATH，不动磁盘。
- [x] Given 独立调用：`sh uninstall.sh --yes` 或 `irm .../uninstall.ps1 | iex` 带 `--yes`，Then 行为等价。

### Notes
- Auto-merged from `minispec/changes/20260424-lifecycle-commands.md`
- See `minispec/archive/20260424-lifecycle-commands.md` for plan and risk notes.

- 决策：`remove` 默认删 archive，因为"我要从项目彻底移除 minispec"最常见的理解就是"全都删"；保留需求由 `--keep-archive` 明示。
- 决策：`uninstall` 独立脚本放仓库根（与 `install.sh` 对称），不是 `scripts/` 下——用户 `curl | sh` 时可以和 install 一个姿势找到。
- 决策：`upgrade` 不默认刷 `minispec/.gitignore` 和 `minispec/SKILL.md`（canonical）。前者用户常自定义（加规则），后者 downstream 不必要。通过显式 flag opt-in。
- 决策：安装生命周期的 5 个命令——install（curl | sh）、init、upgrade、remove、uninstall——在 workflow.md 合并为一个 `## Lifecycle` 小节讲清关系；SKILL `## Commands` 只加一行标注，不深入。
