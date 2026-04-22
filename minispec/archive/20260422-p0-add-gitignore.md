---
id: 20260422-p0-add-gitignore
status: closed
owner: claude
---

# Why

`scripts/ms-project.sh` / `scripts/ms-project.ps1` 在覆盖 `minispec/project.md` 前会生成 `minispec/project.md.bak.<YYYYMMDDHHmmss>` 备份文件。当前仓库没有 `.gitignore`，这些备份以及常见 OS/编辑器临时文件（`.DS_Store`、`Thumbs.db`、`*.swp`、`.idea/`、`.vscode/`）都会被 `git add -A` 一并纳入暂存区。这既会污染提交历史，也会把用户本地编辑器配置带到上游仓库。

# Scope

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

# Acceptance

- [x] Given 仓库根不存在 `.gitignore`，When 执行完本卡，Then `.gitignore` 存在并覆盖上述分类。
- [x] Given 用户运行 `sh scripts/ms-project.sh .`，When 产生 `minispec/project.md.bak.<ts>`，Then `git status --porcelain` 不再把该文件列为 untracked。
- [x] Given 用户在仓库内使用 VS Code 或 JetBrains IDE，When 运行 `git status`，Then `.vscode/` 与 `.idea/` 不出现在 untracked 列表。

# Plan

- [x] T1 新建 `.gitignore` 并按分类注释分节。
  - Expected output: 文件存在且内容按 OS / editor / minispec backups / logs 分节。
- [x] T2 本地验证：构造一份 `minispec/project.md.bak.20260422120000`，运行 `git status` 应将其视为 ignored。
  - Expected output: untracked 列表不包含 `.bak.*` 文件。

# Risks and Rollback

- Risk: 过度忽略可能遮蔽用户真实想提交的临时文件。Rollback: 删除 `.gitignore` 或按行细化。
- Risk: `*.log` 模式可能与未来 `ms-analyze` 输出的 log 冲突。Rollback: 若冲突出现，将范围限定为 `npm-debug.log*` 等具体名。

# Notes

- 决策：忽略规则 minimal 起步，不预置 Node/Python 等语言规则——用户 init 后的项目可以再追加属于自己的规则。
- 决策：不使用 `*.bak`（过宽），仅忽略 `*.bak.*`（minispec 的备份格式是 `.bak.<timestamp>`）。
- 验证记录：
  - 命令：`touch minispec/project.md.bak.20260422120000 && git status --porcelain | grep project.md.bak`
  - 预期：无输出（被忽略）。
