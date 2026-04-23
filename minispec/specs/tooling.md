# tooling

Canonical shipped behavior for domain: tooling


## Change 20260422-p0-add-gitignore (2026-04-22)

### Why

`scripts/ms-project.sh` / `scripts/ms-project.ps1` 在覆盖 `minispec/project.md` 前会生成 `minispec/project.md.bak.<YYYYMMDDHHmmss>` 备份文件。当前仓库没有 `.gitignore`，这些备份以及常见 OS/编辑器临时文件（`.DS_Store`、`Thumbs.db`、`*.swp`、`.idea/`、`.vscode/`）都会被 `git add -A` 一并纳入暂存区。这既会污染提交历史，也会把用户本地编辑器配置带到上游仓库。

### Scope

- In:
  - 新增仓库根 `.gitignore`，覆盖：
    - minispec 自身产物：`minispec/*.bak.*`、`minispec/**/*.bak.*`
    - 备份与临时：`*.bak.*`、`*.tmp`、`*.swp`、`*.swo`、`*~`
    - OS：`.DS_Store`、`Thumbs.db`、`desktop.ini`
    - 编辑器/IDE：`.idea/`、`.vscode/`、`*.iml`
    - 日志：`*.log`
- Out:
  - 不修改任何现有文件。
  - 不添加特定语言（Node/Python/Go 等）的忽略规则（本仓库不包含此类项目源码）。

### Acceptance

- [x] Given 仓库根不存在 `.gitignore`，When 执行完本卡，Then `.gitignore` 存在并覆盖上述分类。
- [x] Given 用户运行 `sh scripts/ms-project.sh .`，When 产生 `minispec/project.md.bak.<ts>`，Then `git status --porcelain` 不再把该文件列为 untracked。
- [x] Given 用户在仓库内使用 VS Code 或 JetBrains IDE，When 运行 `git status`，Then `.vscode/` 与 `.idea/` 不出现在 untracked 列表。

### Notes
- Auto-merged from `minispec/changes/20260422-p0-add-gitignore.md`

- 决策：忽略规则 minimal 起步，不预置 Node/Python 等语言规则——用户 init 后的项目可以再追加属于自己的规则。
- 决策：不使用 `*.bak`（过宽），仅忽略 `*.bak.*`（minispec 的备份格式是 `.bak.<timestamp>`）。
- 验证记录：
  - 命令：`touch minispec/project.md.bak.20260422120000 && git status --porcelain | grep project.md.bak`
  - 预期：无输出（被忽略）。

## Change 20260422-p2-script-parity-tests (2026-04-22)

### Why

P0-1 已经暴露出 `.sh` 与 `.ps1` 会悄悄漂移。手工每次回归既慢又不可靠，需要自动化：bats（覆盖 `.sh`）+ Pester（覆盖 `.ps1`）+ 共用 fixtures。CI（P2-c）会把它们串成门禁。

### Scope

- In:
  - `tests/fixtures/`：最小可用的 `package.json` / `pyproject.toml` / `go.mod` 样本，用来驱动 detection 检查。
  - `tests/bats/`：三个测试文件 `doctor.bats` / `project.bats` / `close.bats`；覆盖结构检查、语义 WARN、Acceptance-only 扫描、next vs next-sitemap 分辨、合并块形态。
  - `tests/pester/`：`Doctor.Tests.ps1` / `Project.Tests.ps1` / `Close.Tests.ps1` 作为 Pester v5 等价用例（至少覆盖 doctor 的核心路径，project 的 round-trip Maintainer Notes，close 的 Acceptance-only 检查）。
  - `tests/README.md`：说明如何本地跑（bats-core + Pester v5 安装指引）。
- Out:
  - 不跑 CI（由 P2-c 引入）。
  - 不强制 100% 覆盖率，初版覆盖关键路径即可。

### Acceptance

- [x] Given 安装 bats-core，When 执行 `bats tests/bats`，Then 全部测试通过。
- [x] Given 安装 Pester v5，When 执行 `Invoke-Pester tests/pester`，Then 全部测试通过。
- [x] Given 测试文件布局，Then `tests/README.md` 讲清安装、运行、新增用例的模板。
- [x] Given 有 `next-sitemap` fixture 与 `next-real` fixture，When 两端脚本跑过，Then 测试断言 Framework 字段分别为 `Node.js application` 与 `Next.js`。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-script-parity-tests.md`
- See `minispec/archive/20260422-p2-script-parity-tests.md` for plan and risk notes.

- 决策：bats 测试用 `setup()` 建临时目录、`teardown()` 清理；Pester 同理 `BeforeEach` / `AfterEach`。
- 决策：next fixture 的 framework 检查是两端 parity 的代表用例（P0-1 的 regression guard）。

## Change 20260422-p2-github-actions-ci (2026-04-22)

### Why

P2-b 写好了 bats + Pester 套件，但没有 CI 跑它们等于没门禁。新增 GitHub Actions workflow 把 lint + test 跑起来，双脚本漂移会在 PR 阶段就被拦住。

### Scope

- In:
  - `.github/workflows/ci.yml`：
    - `lint` job（ubuntu-latest）：
      - shellcheck 所有 `scripts/*.sh`
      - PSScriptAnalyzer 所有 `scripts/*.ps1`（pwsh 在 ubuntu 上可用）
    - `test-bats` job（ubuntu-latest）：安装 bats-core + 跑 `bats tests/bats`
    - `test-pester` job（windows-latest）：Install Pester v5 + 跑 `Invoke-Pester`
    - 触发：push 到任何分支 + PR 到 main
- Out:
  - 不做 release automation（留给 P2-f）。
  - 不做 coverage 或 fancy reporter——MVP 只是 pass/fail。

### Acceptance

- [x] Given `.github/workflows/ci.yml` 存在，Then 包含 lint / test-bats / test-pester 三个 job。
- [x] Given workflow 触发器，Then 同时覆盖 `push` 与 `pull_request`（默认分支 main）。
- [x] Given ubuntu job，Then 安装并调用 shellcheck 与 PSScriptAnalyzer。
- [x] Given windows job，Then 安装 Pester v5 且运行 tests/pester。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-github-actions-ci.md`
- See `minispec/archive/20260422-p2-github-actions-ci.md` for plan and risk notes.

- 决策：lint 与 test 分开 job，失败时定位更快；没开 matrix 因为 OS 间已经自然分工（lint + bats on ubuntu，Pester on windows）。
- 决策：PSScriptAnalyzer 阈值选 warning；error 才 fail-fast。

## Change 20260422-p2-install-script-and-version (2026-04-22)

### Why

当前要把 minispec 拉到自己的项目只有两种方式：clone 仓库 copy 文件，或手工调 `scripts/ms-init.sh`。缺一条"拿 URL 就能装"的入口。此外没有 VERSION 字面量与 `ms-doctor --version`，用户升级时说不清自己是哪个版本。

本卡加：

- `VERSION` 文件（0.1.0 作为首个可发布版本号）。
- `scripts/install.sh`：POSIX 通用安装脚本，从 tagged tarball 下载 scripts + 合同目录骨架到目标目录。支持 `--target` 与 `--version` 参数。
- `ms-doctor.sh` / `.ps1`：新增 `--version` / `-Version` 开关，输出 VERSION 内容并直接退出。

### Scope

- In:
  - `VERSION`：单行 `0.1.0`。
  - `scripts/install.sh`：POSIX sh，接受 `--version <tag>`、`--target <dir>`，调用 `curl` 或 `wget` 下载 tarball。
  - `scripts/ms-doctor.sh` / `.ps1`：解析 `--version` / `-Version`，打印 VERSION 内容并 exit 0。
  - `README.md` / `README.zh-CN.md`：Utility Scripts 段加 install.sh 用法示例。
- Out:
  - 不做实际 GitHub Release 工作流（需要仓库上云后单独做）。
  - 不做 Windows 原生 install.ps1 一件事——`install.sh` 在 PowerShell + git-bash 组合下即可运行，PS 等效物留给后续。

### Acceptance

- [x] Given `VERSION` 文件存在，Then 内容为 `0.1.0`（仅一行，尾部换行可选）。
- [x] Given 运行 `sh scripts/ms-doctor.sh --version` 或 `.ps1 -Version`，Then 输出 `0.1.0` 并 exit 0，不做结构检查。
- [x] Given 执行 `sh scripts/install.sh --help`，Then 打印出用法说明并 exit 0。
- [x] Given `README.md` 与 `README.zh-CN.md`，Then 都含一条 `scripts/install.sh` 的用法示例。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-install-script-and-version.md`
- See `minispec/archive/20260422-p2-install-script-and-version.md` for plan and risk notes.

- 决策：首版选 0.1.0 而非 1.0.0——留出不稳定窗口；当前 P0-P2 改造未放出版本号。
- 决策：install.sh 从 `https://github.com/<org>/minispec/archive/refs/tags/v<version>.tar.gz` 拉取；`<org>` 作为环境变量 `MINISPEC_REPO` 暴露（默认 `unknown/minispec`，真正发布时由 release 流程提示设置）。

## Change 20260422-p2-system-cli-installer (2026-04-22)

### Why

当前 minispec 只能通过 clone 仓库 + 调 `scripts/ms-*.sh` 的姿势用。面向发布，用户期望一行命令装好、然后 `minispec init .` 就能在任何目录初始化。本卡建立跨平台的系统级 CLI：

- Linux / macOS / git-bash：`curl -fsSL .../install.sh | sh`，装到 `~/.local/share/minispec`，launcher 放 `~/.local/bin/minispec`。
- Windows PowerShell：`irm .../install.ps1 | iex`，装到 `%USERPROFILE%\.minispec`，launcher 放 `%USERPROFILE%\.minispec\bin\`，自动加入 user PATH。
- 全局 `minispec` 命令分发到仓库原有 `scripts/ms-*`；`new / apply / check / analyze` 是 agent 驱动，CLI 只打印引导。

固定 repo slug 为 `ivenlau/minispec`，同时保留 `MINISPEC_REPO` / `MINISPEC_REF` / `MINISPEC_PREFIX` 环境变量供 override。

### Scope

- In:
  - `install.sh`（仓库根）：POSIX 安装器，下载 tag 或 branch tarball，展开到 `<prefix>/share/minispec`，安装 launcher 到 `<prefix>/bin/minispec`。
  - `install.ps1`（仓库根）：PowerShell 安装器，下载 zip、展开到 `$env:USERPROFILE\.minispec`，安装 launcher 并追加 user PATH。
  - `bin/minispec`（POSIX launcher）：解析 action，dispatch 到 `scripts/ms-*.sh`；未知/agent-only action 打印引导。
  - `bin/minispec.cmd`（Windows cmd shim）：转发到 `minispec.ps1`（优先 `pwsh`，退回 `powershell`）。
  - `bin/minispec.ps1`（Windows PowerShell launcher）：与 POSIX launcher 语义对等；dispatch 到 `scripts/ms-*.ps1`。
  - `README.md` / `README.zh-CN.md`：Quickstart 最上层重构为 "一行装 → `minispec init .` → 让 agent 接管" 三步。
  - `CHANGELOG.md`：追加本次改造条目。
  - 删除 `scripts/install.sh`（被根目录 `install.sh` + `minispec init <dir>` 取代）。
  - 删除 `scripts/minispec.sh` / `scripts/minispec.ps1`（被 `bin/minispec*` 取代）。
- Out:
  - 不做 GitHub Releases 自动化（CI 触发打 tarball/zip 留后续卡）。
  - 不做 `minispec uninstall` 子命令（手动删目录 + PATH 条目即可；后续卡再说）。
  - 不改 agent 驱动 action 的语义——CLI 仍然建议进 AI CLI 执行。

### Acceptance

- [x] Given Linux / macOS / git-bash shell，When 跑 `curl -fsSL .../install.sh | sh` 或在本仓库跑 `sh install.sh --prefix $HOME/.local`，Then `~/.local/share/minispec/scripts` 存在，`~/.local/bin/minispec` 可执行。
- [x] Given Windows PowerShell，When 跑 `irm .../install.ps1 | iex` 或本地 `.\install.ps1`，Then `%USERPROFILE%\.minispec\bin\minispec.cmd` 存在且该目录被追加到 user PATH。
- [x] Given `minispec` 在 PATH 中，When 在一个空目录跑 `minispec init .`，Then 该目录生成完整的 `minispec/`、`.agents/`、`.claude/`、`AGENTS.md`、`CLAUDE.md` 结构；`minispec doctor .` 结果 PASS。
- [x] Given `minispec --version`，Then 输出版本号（读取安装目录下的 VERSION）。
- [x] Given `minispec new add-foo` 或 `minispec apply 20260422-foo`，Then 打印 "agent-driven action — run inside your AI CLI" 引导而非报错。
- [x] Given `scripts/install.sh`、`scripts/minispec.sh`、`scripts/minispec.ps1`，Then 仓库中不再存在（已被替代）。
- [x] Given `README.md` 与 `README.zh-CN.md`，Then 顶部 Quickstart 第一段为一行安装，第二段为 `minispec init .`。

### Notes
- Auto-merged from `minispec/changes/20260422-p2-system-cli-installer.md`
- See `minispec/archive/20260422-p2-system-cli-installer.md` for plan and risk notes.

- 决策：安装落在 user scope（`$HOME/.local` / `%USERPROFILE%\.minispec`），不要 sudo，不改系统目录。
- 决策：`bin/minispec` 是真正的可执行 launcher；仓库也保留它，这样开发者在 repo 内加 `bin/` 到 PATH 也能用——install 流只是把它 cp 到 `<prefix>/bin`。
- 决策：`scripts/install.sh` 被删。"drop minispec into a project dir"的用例直接用 `minispec init <dir>`，不再需要单独安装器。
- 决策：agent-driven 动作（new/apply/check/analyze）不在 CLI 层实现，只打印指引——避免伪造 agent 行为。
- 验证方式：端到端本地模拟：(1) 在 `/tmp/msprefix/share` 放仓库副本，(2) 把 `bin/minispec` 加到 PATH，(3) `minispec init /tmp/demo`，(4) `minispec doctor /tmp/demo` Result PASS。

## Change 20260423-fix-ci-pester-and-shellcheck (2026-04-23)

### Why

`.github/workflows/ci.yml` 首次跑出来两条 red：

1. Pester v5 的 `test-pester` job 抛 `Each test setup is not supported in root (directly in the block container)`——4 份 `.Tests.ps1` 把 `BeforeEach` / `AfterEach` 放在 `Describe` 外层（Pester v5 只允许 `BeforeAll`/`AfterAll` 在根节点，每-测试级 setup 必须挨着 `It`）。
2. `lint` job 的 shellcheck 在 `scripts/ms-init.sh` 抛 SC1007：`CDPATH= cd -- …` 这种合法的前缀赋值被误报为"不小心留了空格的赋值"。

两条 red 都是工具使用姿势问题，不是真 bug。一并修掉让 CI 走绿。

### Scope

- In:
  - `tests/pester/Doctor.Tests.ps1`：保留根节点 `BeforeAll`；`BeforeEach`/`AfterEach` 挪进 `Describe "ms-doctor.ps1"`。
  - `tests/pester/Close.Tests.ps1`：同上。
  - `tests/pester/Init.Tests.ps1`：同上。
  - `tests/pester/Project.Tests.ps1`：合并两个 `Describe` 为单 `Describe "ms-project.ps1"` + 两个 `Context`（"detection" / "Maintainer Notes"），共享 BeforeEach/AfterEach。
  - `scripts/ms-init.sh`：`set -eu` 后追加 `unset CDPATH`；`SCRIPT_DIR` / `REPO_ROOT` 两行去掉 `CDPATH= ` 前缀。
  - `bin/minispec`：`set -eu` 后追加 `unset CDPATH`；`self_dir` / `share_dir` 三处去掉 `CDPATH= ` 前缀。
  - `CHANGELOG.md` Unreleased > Fixed 追加一条。
- Out:
  - 不动 `.github/workflows/ci.yml`（白名单保持现状，靠源码修正达到绿）。
  - 不动其他 `.sh` 脚本——它们没用 `CDPATH=` 前缀。
  - 不改 Pester 用例的断言语义，只动组织结构。

### Acceptance

- [x] Given 四份 Pester 文件，When 查找根节点 `BeforeEach` / `AfterEach`，Then 找不到（都挪进了 `Describe`/`Context`）。
- [x] Given `tests/pester/Project.Tests.ps1`，Then 只有一个 `Describe "ms-project.ps1"`，下辖两个 `Context`（"detection" 与 "Maintainer Notes"）。
- [x] Given 本地 `grep -rn 'CDPATH= ' scripts/ bin/`，Then 返回空（前缀赋值已清除）。
- [x] Given `scripts/ms-init.sh` 和 `bin/minispec` 顶部，Then 存在 `unset CDPATH` 一行。
- [x] Given `ms-doctor`、`ms-init`、`minispec --help`、`minispec init /tmp/demo` 本地跑，Then 行为一致（没回归）。
- [x] Given CI 下次触发（push 后），Then `lint` job 的 shellcheck 通过；`test-pester` job 的 Pester 不再抛 "root" 错（能跑进实际测试）。

### Notes
- Auto-merged from `minispec/changes/20260423-fix-ci-pester-and-shellcheck.md`
- See `minispec/archive/20260423-fix-ci-pester-and-shellcheck.md` for plan and risk notes.

- 决策：走 B 而非 "CI 全局 -e SC1007"，原则是"工具报警时优先改源、不优先改 silence"。
- 决策：`unset CDPATH` 放在 `set -eu` 之后，符合"先锁定严格模式、再清理环境"的常见习惯。
- 观察：其他三个 `.sh` 脚本（ms-close/ms-doctor/ms-project）没用 `CDPATH=` 前缀——它们 `cd "$ROOT" && pwd` 受 `CDPATH` 影响小，历史上作者没加防御；本卡不扩大 scope 去补。若未来出现 `cd` 因用户 CDPATH 误跳的问题，另起卡统一加。
