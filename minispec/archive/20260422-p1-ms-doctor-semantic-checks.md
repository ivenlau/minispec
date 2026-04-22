---
id: 20260422-p1-ms-doctor-semantic-checks
status: closed
owner: claude
---

# Why

`ms-doctor` 现只做结构校验（路径存在与否），不覆盖语义层面的常见问题，例如：`project.md` 还留着 `TBD`、change card 文件名不符合约定、frontmatter `status` 不在合法枚举、草稿滞留超过两周、archive 中的 id 没有在任何 spec 里被合并。这些是最常被忽视却导致 minispec 退化的点。

本卡把这些语义检查加到 `ms-doctor.sh` / `.ps1`，都以 `[WARN]` 形式输出且不改变 exit code——保持"结构是硬门槛、语义是提醒"的分层。

# Scope

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

# Acceptance

- [x] Given `project.md` 含 `TBD`，When 运行 doctor，Then 输出包含 `[WARN] minispec/project.md`（TBD）且 exit 0。
- [x] Given `minispec/changes/bad-name.md` 存在，When 运行 doctor，Then 输出 `[WARN] ... filename does not match YYYYMMDD-slug pattern.` 且 exit 0。
- [x] Given 一张 change 的 frontmatter `status: stalled`（非法），When 运行 doctor，Then 输出 `[WARN] ... unknown status 'stalled'`。
- [x] Given 一张 `20260401-old.md` status 仍为 draft（>14 天），When 运行 doctor，Then 输出 stale 警告。
- [x] Given `minispec/archive/20260422-x.md` 存在但没有对应 `## Change 20260422-x` 在任何 spec，When 运行 doctor，Then 输出 cross-ref 警告。

# Plan

- [x] T1 在 `ms-doctor.sh` 结构检查后加 `## Semantic checks` 段，依次实现 5 条语义检查。
- [x] T2 在 `ms-doctor.ps1` 同步等价检查。
- [x] T3 构造 fixture（含以上 5 种触发场景）实机验证两份脚本输出。

# Risks and Rollback

- Risk: BSD/macOS 缺 `date -d`，staleness 检查可能静默跳过。Rollback: 在 SH 版提供 `-d` / `-v -14d` 双分支，若两者都不存在则跳过该项检查。
- Risk: WARN 噪声可能让用户忽略真正的 FAIL 信号。Rollback: 加一个 `--quiet` 开关让用户只看 FAIL。

# Notes

- 决策：每条语义检查仅发 `[WARN]`，不改 exit code。doctor 的硬失败仅保留在 required 结构。
- 决策：文件名 regex 采用 `^[0-9]{8}-[a-z0-9-]+$`，大小写敏感，slug 只允许小写字母/数字/连字符，与现有示例 `20260323-refund-filter` 保持一致。
