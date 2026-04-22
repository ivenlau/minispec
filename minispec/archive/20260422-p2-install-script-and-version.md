---
id: 20260422-p2-install-script-and-version
status: closed
owner: claude
---

# Why

当前要把 minispec 拉到自己的项目只有两种方式：clone 仓库 copy 文件，或手工调 `scripts/ms-init.sh`。缺一条"拿 URL 就能装"的入口。此外没有 VERSION 字面量与 `ms-doctor --version`，用户升级时说不清自己是哪个版本。

本卡加：

- `VERSION` 文件（0.1.0 作为首个可发布版本号）。
- `scripts/install.sh`：POSIX 通用安装脚本，从 tagged tarball 下载 scripts + 合同目录骨架到目标目录。支持 `--target` 与 `--version` 参数。
- `ms-doctor.sh` / `.ps1`：新增 `--version` / `-Version` 开关，输出 VERSION 内容并直接退出。

# Scope

- In:
  - `VERSION`：单行 `0.1.0`。
  - `scripts/install.sh`：POSIX sh，接受 `--version <tag>`、`--target <dir>`，调用 `curl` 或 `wget` 下载 tarball。
  - `scripts/ms-doctor.sh` / `.ps1`：解析 `--version` / `-Version`，打印 VERSION 内容并 exit 0。
  - `README.md` / `README.zh-CN.md`：Utility Scripts 段加 install.sh 用法示例。
- Out:
  - 不做实际 GitHub Release 工作流（需要仓库上云后单独做）。
  - 不做 Windows 原生 install.ps1 一件事——`install.sh` 在 PowerShell + git-bash 组合下即可运行，PS 等效物留给后续。

# Acceptance

- [x] Given `VERSION` 文件存在，Then 内容为 `0.1.0`（仅一行，尾部换行可选）。
- [x] Given 运行 `sh scripts/ms-doctor.sh --version` 或 `.ps1 -Version`，Then 输出 `0.1.0` 并 exit 0，不做结构检查。
- [x] Given 执行 `sh scripts/install.sh --help`，Then 打印出用法说明并 exit 0。
- [x] Given `README.md` 与 `README.zh-CN.md`，Then 都含一条 `scripts/install.sh` 的用法示例。

# Plan

- [x] T1 写 `VERSION`。
- [x] T2 `ms-doctor.sh` 加 `--version` 短路。
- [x] T3 `ms-doctor.ps1` 加 `-Version` switch 短路。
- [x] T4 写 `scripts/install.sh`（help、args 解析、下载、解压、落地）。
- [x] T5 README 中英两版同步一段用法。

# Risks and Rollback

- Risk: install.sh 依赖 `curl`/`wget` 之一；极端环境可能两者都没有。Rollback: 脚本在缺失时打印明确提示让用户手动下载 tarball。
- Risk: VERSION 与 CHANGELOG 的 [Unreleased] 头偶尔会脱节。Rollback: CI 后续可加检查；本卡先不引入。

# Notes

- 决策：首版选 0.1.0 而非 1.0.0——留出不稳定窗口；当前 P0-P2 改造未放出版本号。
- 决策：install.sh 从 `https://github.com/<org>/minispec/archive/refs/tags/v<version>.tar.gz` 拉取；`<org>` 作为环境变量 `MINISPEC_REPO` 暴露（默认 `unknown/minispec`，真正发布时由 release 流程提示设置）。
