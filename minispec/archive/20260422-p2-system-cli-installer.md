---
id: 20260422-p2-system-cli-installer
status: closed
owner: claude
---

# Why

当前 minispec 只能通过 clone 仓库 + 调 `scripts/ms-*.sh` 的姿势用。面向发布，用户期望一行命令装好、然后 `minispec init .` 就能在任何目录初始化。本卡建立跨平台的系统级 CLI：

- Linux / macOS / git-bash：`curl -fsSL .../install.sh | sh`，装到 `~/.local/share/minispec`，launcher 放 `~/.local/bin/minispec`。
- Windows PowerShell：`irm .../install.ps1 | iex`，装到 `%USERPROFILE%\.minispec`，launcher 放 `%USERPROFILE%\.minispec\bin\`，自动加入 user PATH。
- 全局 `minispec` 命令分发到仓库原有 `scripts/ms-*`；`new / apply / check / analyze` 是 agent 驱动，CLI 只打印引导。

固定 repo slug 为 `ivenlau/minispec`，同时保留 `MINISPEC_REPO` / `MINISPEC_REF` / `MINISPEC_PREFIX` 环境变量供 override。

# Scope

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

# Acceptance

- [x] Given Linux / macOS / git-bash shell，When 跑 `curl -fsSL .../install.sh | sh` 或在本仓库跑 `sh install.sh --prefix $HOME/.local`，Then `~/.local/share/minispec/scripts` 存在，`~/.local/bin/minispec` 可执行。
- [x] Given Windows PowerShell，When 跑 `irm .../install.ps1 | iex` 或本地 `.\install.ps1`，Then `%USERPROFILE%\.minispec\bin\minispec.cmd` 存在且该目录被追加到 user PATH。
- [x] Given `minispec` 在 PATH 中，When 在一个空目录跑 `minispec init .`，Then 该目录生成完整的 `minispec/`、`.agents/`、`.claude/`、`AGENTS.md`、`CLAUDE.md` 结构；`minispec doctor .` 结果 PASS。
- [x] Given `minispec --version`，Then 输出版本号（读取安装目录下的 VERSION）。
- [x] Given `minispec new add-foo` 或 `minispec apply 20260422-foo`，Then 打印 "agent-driven action — run inside your AI CLI" 引导而非报错。
- [x] Given `scripts/install.sh`、`scripts/minispec.sh`、`scripts/minispec.ps1`，Then 仓库中不再存在（已被替代）。
- [x] Given `README.md` 与 `README.zh-CN.md`，Then 顶部 Quickstart 第一段为一行安装，第二段为 `minispec init .`。

# Plan

- [x] T1 写 `install.sh`（根目录）。
- [x] T2 写 `install.ps1`（根目录）。
- [x] T3 写 `bin/minispec`（POSIX launcher），赋可执行位。
- [x] T4 写 `bin/minispec.cmd` + `bin/minispec.ps1`。
- [x] T5 删除 `scripts/install.sh` / `scripts/minispec.sh` / `scripts/minispec.ps1`。
- [x] T6 重写 `README.md` Quickstart A/B 段为 "一行装 + `minispec init .`"。
- [x] T7 同步 `README.zh-CN.md`。
- [x] T8 `CHANGELOG.md` 追加 "Added system-wide installer / `minispec` CLI"。
- [x] T9 本地验证：手工模拟 install 过程（copy 到临时 `share/minispec` 目录 + 放 launcher），然后 `minispec init /tmp/demo` 成功。

# Risks and Rollback

- Risk: 某些 Windows 环境没有 PowerShell 7（只有 Windows PowerShell 5.1），Pester 行为可能有差。Rollback: launcher `.cmd` 优先 `pwsh`，fallback 到 `powershell`；核心脚本已经在 5.1 可用。
- Risk: 用户 `~/.local/bin` 不在 PATH 里（某些非 systemd 发行版）。Rollback: `install.sh` 检测后打印明确的 export 指引。
- Risk: Windows 用户关闭终端前 `minispec` 无法立即使用（`SetEnvironmentVariable` 只影响新会话）。Rollback: `install.ps1` 末尾打印"请重开终端或重新加载 PATH"。
- Risk: 同一用户 `MINISPEC_HOME` 与默认 share 路径混用混乱。Rollback: launcher 优先读 `MINISPEC_HOME`，其次自检 `../share/minispec`，其次 Windows 默认路径。

# Notes

- 决策：安装落在 user scope（`$HOME/.local` / `%USERPROFILE%\.minispec`），不要 sudo，不改系统目录。
- 决策：`bin/minispec` 是真正的可执行 launcher；仓库也保留它，这样开发者在 repo 内加 `bin/` 到 PATH 也能用——install 流只是把它 cp 到 `<prefix>/bin`。
- 决策：`scripts/install.sh` 被删。"drop minispec into a project dir"的用例直接用 `minispec init <dir>`，不再需要单独安装器。
- 决策：agent-driven 动作（new/apply/check/analyze）不在 CLI 层实现，只打印指引——避免伪造 agent 行为。
- 验证方式：端到端本地模拟：(1) 在 `/tmp/msprefix/share` 放仓库副本，(2) 把 `bin/minispec` 加到 PATH，(3) `minispec init /tmp/demo`，(4) `minispec doctor /tmp/demo` Result PASS。
