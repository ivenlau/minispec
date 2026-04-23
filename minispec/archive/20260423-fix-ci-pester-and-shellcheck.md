---
id: 20260423-fix-ci-pester-and-shellcheck
status: closed
owner: claude
---

# Why

`.github/workflows/ci.yml` 首次跑出来两条 red：

1. Pester v5 的 `test-pester` job 抛 `Each test setup is not supported in root (directly in the block container)`——4 份 `.Tests.ps1` 把 `BeforeEach` / `AfterEach` 放在 `Describe` 外层（Pester v5 只允许 `BeforeAll`/`AfterAll` 在根节点，每-测试级 setup 必须挨着 `It`）。
2. `lint` job 的 shellcheck 在 `scripts/ms-init.sh` 抛 SC1007：`CDPATH= cd -- …` 这种合法的前缀赋值被误报为"不小心留了空格的赋值"。

两条 red 都是工具使用姿势问题，不是真 bug。一并修掉让 CI 走绿。

# Approach

- Considered:
  - **A. 只抑制警告**：Pester 用 `#Requires -Version` 之类做兼容？实际 Pester v5 的限制没法用 pragma 绕过；SC1007 可以用 `# shellcheck disable=SC1007` 每行抑制或 CI 全局 `-e`。
  - **B. 重构到工具推荐形态**（推荐）：Pester 侧把 BeforeEach/AfterEach 挪进 Describe（`Project.Tests.ps1` 有双 Describe，顺带用 Describe+Context 合并一下）；shellcheck 侧脚本顶 `unset CDPATH` 一次，下方 `cd` 去掉前缀赋值——消除歧义根源而不是消声。
  - **C. CI 全局 `-e SC1007`**：一行改动但全局屏蔽，将来真误写 `var= value` 就捕获不到，降低工具价值。
- Chosen: **B**。Pester 没得选（v5 的硬性结构），shellcheck 走重构比 silence 更稳；同时保持 CI 白名单的最小必要原则。

# Scope

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

# Acceptance

- [x] Given 四份 Pester 文件，When 查找根节点 `BeforeEach` / `AfterEach`，Then 找不到（都挪进了 `Describe`/`Context`）。
- [x] Given `tests/pester/Project.Tests.ps1`，Then 只有一个 `Describe "ms-project.ps1"`，下辖两个 `Context`（"detection" 与 "Maintainer Notes"）。
- [x] Given 本地 `grep -rn 'CDPATH= ' scripts/ bin/`，Then 返回空（前缀赋值已清除）。
- [x] Given `scripts/ms-init.sh` 和 `bin/minispec` 顶部，Then 存在 `unset CDPATH` 一行。
- [x] Given `ms-doctor`、`ms-init`、`minispec --help`、`minispec init /tmp/demo` 本地跑，Then 行为一致（没回归）。
- [x] Given CI 下次触发（push 后），Then `lint` job 的 shellcheck 通过；`test-pester` job 的 Pester 不再抛 "root" 错（能跑进实际测试）。

# Plan

- [x] T1 `scripts/ms-init.sh`：顶部 `unset CDPATH`，两行去前缀。
- [x] T2 `bin/minispec`：顶部 `unset CDPATH`，三处去前缀。
- [x] T3 `tests/pester/Doctor.Tests.ps1`：BeforeEach/AfterEach 挪进 Describe。
- [x] T4 `tests/pester/Close.Tests.ps1`：同 T3。
- [x] T5 `tests/pester/Init.Tests.ps1`：同 T3。
- [x] T6 `tests/pester/Project.Tests.ps1`：合并为 Describe + 两 Context，BeforeEach/AfterEach 放 Describe 内共享。
- [x] T7 本地回归：跑 `ms-doctor`、模拟 install + `minispec init` 验证 `unset CDPATH` 后的路径解析正确。
- [x] T8 CHANGELOG 追加。
- [x] T9 close → commit → push。

# Risks and Rollback

- Risk: 某个下游用户手工 `export CDPATH=...` 到 shell config，脚本 `unset CDPATH` 后他后续 cd 行为也变了。实际上 `unset CDPATH` 只影响当前脚本进程，不会改用户交互 shell——脚本结束，env 不传回父进程。Rollback：无需。
- Risk: Pester `Context` 和 `Describe` 共享 BeforeEach 时变量作用域略有差别。`$script:` 作用域跨 Context 仍然可用，应该没事。Rollback：若真出问题，把 BeforeEach 下放到每个 Context 里各自一份。
- Risk: Windows-only 的 Pester 我在本机跑不了，错误要等下次 CI 验证。Rollback：若 CI 仍 red 就再起一张小卡。

# Notes

- 决策：走 B 而非 "CI 全局 -e SC1007"，原则是"工具报警时优先改源、不优先改 silence"。
- 决策：`unset CDPATH` 放在 `set -eu` 之后，符合"先锁定严格模式、再清理环境"的常见习惯。
- 观察：其他三个 `.sh` 脚本（ms-close/ms-doctor/ms-project）没用 `CDPATH=` 前缀——它们 `cd "$ROOT" && pwd` 受 `CDPATH` 影响小，历史上作者没加防御；本卡不扩大 scope 去补。若未来出现 `cd` 因用户 CDPATH 误跳的问题，另起卡统一加。
