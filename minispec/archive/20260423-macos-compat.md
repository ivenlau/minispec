---
id: 20260423-macos-compat
status: closed
owner: claude
---

# Why

`scripts/ms-doctor.sh:155` 用了 GNU 独占的 `sha256sum` 做 SKILL Guardrails 跨文件一致性检查。macOS 默认只有 `shasum -a 256`（或者用户装了 coreutils 才有 `sha256sum`）。结果是 macOS 用户跑 doctor 时，`sha256sum` 命令失败→hash 变空→`unique_count=0`→漂移检查**静默失效**。功能没崩，但少了一层安全网。

同时 CI 根本没跑 macos-latest runner，这类平台差异无法被自动抓到——是一个未来规模扩大后会变贵的漏洞。本卡在 CI 加 macOS matrix 防回归。

# Approach

- Considered:
  - **A. `sha256sum` + fallback 到 `shasum -a 256`**：保留 hash 思路，用 `command -v` 做运行时 dispatch。能用但引入分支。
  - **B. 直接内容字符串比较**（推荐）：Guardrails 只有 3 行，压根不用 hash。移除对 hash 工具的任何依赖，代码更短。
  - **C. 文档要求用户装 coreutils**：把负担甩给用户，显然不合适。
- Chosen: **B**。Guardrails 段体量极小（三四行），用 shell 原生字符串比较 `[ "$a" != "$b" ]` 比引入条件分支调 hash 工具更简洁；对跨平台的隐性假设数量降到零。

# Scope

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

# Acceptance

- [x] Given `scripts/ms-doctor.sh` 的 Guardrails 同步检查段，When grep `sha256sum`，Then 无结果。
- [x] Given 在一个 `sha256sum` 不可用的 PATH 下跑 `sh scripts/ms-doctor.sh .`（通过 PATH 隔离或 stub 模拟），Then Result PASS，Guardrails 部分行为与有 sha256sum 时一致。
- [x] Given `.github/workflows/ci.yml` 的 `test-bats` job，When 查看 `strategy.matrix.os`，Then 包含 `ubuntu-latest` 与 `macos-latest`；各分支有对应的 bats 安装步骤。
- [x] Given `tests/bats/doctor.bats`，When grep 用例名，Then 包含一条 "WARNs when SKILL Guardrails drift" 与一条 "does not WARN when all three SKILL Guardrails match"。
- [x] Given 当前仓库状态，When 跑本地 `sh scripts/ms-doctor.sh .`，Then Result PASS、无漂移 WARN（因为三份 SKILL 本来就一致）。

# Plan

- [x] T1 `scripts/ms-doctor.sh`：Guardrails 同步检查段改写，移除 hash 依赖。
- [x] T2 `.github/workflows/ci.yml`：`test-bats` → matrix；分开 apt/brew 安装步骤。
- [x] T3 `tests/bats/doctor.bats`：补两条 SKILL Guardrails 测试。
- [x] T4 本地回归：ms-doctor 跑一遍（确认 PASS），再模拟漂移（改一份 Guardrails 一行）确认触发 WARN，然后还原。
- [x] T5 close → commit → push。

# Risks and Rollback

- Risk: matrix fan-out 后 `test-bats` 的 CI 时间翻倍。Rollback: 如果未来嫌慢，可以 `fail-fast: false` 配合 ubuntu 作为必过、macOS 作为允许失败的"observation" runner。当前不做，先让两条都必过。
- Risk: `brew install bats-core` 在极端 brew 网络问题时失败，拖 macOS 线红。Rollback: 加 cache step 或换用 bats 的 checkout + install 脚本。
- Risk: 字符串直接比较对 CRLF 敏感。Rollback: 保留 `tr -d '\r'` 预处理（已在新代码里）。

# Notes

- 决策：`drift=1` 命中后立即 `break`——只要发现一对不一致就足够给出 WARN，不必枚举所有两两对比。
- 决策：用 `guard_first` 而不是 `declare` / `local`（POSIX sh 没有 `local`）。变量留在全局，脚本结束自然消失。
- 决策：bats 在 macOS 用 `brew install bats-core`（正确 formula 名；`bats` 这个包名是旧的，已重定向但显式用 `bats-core` 更稳）。
- 非 hash 方案的次级收益：字符串比较可以在 WARN 信息里更具体地指出"哪两份之间漂移"——不过本卡不扩展到这一步，保持最小改动。
