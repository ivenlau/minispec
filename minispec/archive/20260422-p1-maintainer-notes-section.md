---
id: 20260422-p1-maintainer-notes-section
status: closed
owner: claude
---

# Why

两份 SKILL 把 `## Maintainer Notes` 描述为 `project.md` 里的 `[manual-managed]` 段，但 `scripts/ms-project.sh/.ps1` 完全没生成该段；用户按 SKILL 添加的 Maintainer Notes 一旦运行 `ms-project` 就会被覆盖，进而让 `[manual-managed]` 的承诺破产。

本卡补齐：脚本首次生成时写入带 marker 的 Maintainer Notes 模板；再次运行时读取旧文件中的 Maintainer Notes 并原样保留到新输出。

# Scope

- In:
  - `scripts/ms-project.sh`：新增 "读取旧 project.md 中 Maintainer Notes 段" 逻辑；渲染阶段结尾追加 Maintainer Notes。
  - `scripts/ms-project.ps1`：同上逻辑。
  - Maintainer Notes 的 marker 统一为一行 HTML 注释：`<!-- manual-managed; preserved across ms-project regenerations -->`。
- Out:
  - 不处理 Engineering Constraints / Non-Goals / Definition of Done 的 manual-managed 保留（超出本卡范围，与 SKILL 描述一致地遵循已有模板）。
  - 不改 SKILL（已经描述了 Maintainer Notes）。

# Acceptance

- [x] Given 对一个不存在 `minispec/project.md` 的目录运行 `sh scripts/ms-project.sh`，Then 生成的 `project.md` 末尾存在 `## Maintainer Notes` 段并带 marker 注释。
- [x] Given 用户在已生成的 `project.md` 里 Maintainer Notes 段添加了一行 `- 遵循 kebab-case 命名`，When 再次运行 `ms-project.sh`，Then 新文件里那行 `- 遵循 kebab-case 命名` 原样出现在 Maintainer Notes 段中。
- [x] Given 对同一输入分别运行 `.sh` 与 `.ps1`，Then 两者输出的 Maintainer Notes 段头部与 marker 一致。

# Plan

- [x] T1 `ms-project.sh`：在备份块前加 `maintainer_notes` 抽取；在 Guided Inputs 块后追加 Maintainer Notes 输出（有旧内容则保留，否则默认模板）。
- [x] T2 `ms-project.ps1`：在 `Set-Content` 前读取旧文件的 Maintainer Notes 段；Render-ProjectContract 接受 `MaintainerNotes` 参数并在末尾输出。
- [x] T3 验证：构造 fixture，两轮运行后第二轮输出仍包含用户自定义条目。

# Risks and Rollback

- Risk: 旧用户升级后第一次运行会看到新增 Maintainer Notes 段，可能误以为是自己误操作。Rollback: 暂时把默认模板留空正文，仅保留 `<!-- marker -->`。

# Notes

- 决策：Maintainer Notes 放在 project.md 末尾，确保其后不再有 `## ...` 段，保持抽取 regex 简单（"从 `^## Maintainer Notes` 到下一个 `^## ` 或 EOF"）。
- 决策：marker 用 HTML 注释形式而非 markdown 注释，与 markdown 渲染器兼容。
