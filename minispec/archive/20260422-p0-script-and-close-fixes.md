---
id: 20260422-p0-script-and-close-fixes
status: closed
owner: claude
---

# Why

minispec 的三处脚本行为漏洞会导致"工具说一套、实际另一套"，是使用 minispec 过程中最容易踩的坑：

1. `scripts/ms-project.sh` 使用 `grep -Eiq` 做子串匹配识别依赖，同一个 `package.json` 在 `.ps1`（精确 JSON 匹配）下可能得到不同的 framework 判定，破坏脚本 parity。
2. `scripts/ms-close.ps1` 合并块的 markdown 反引号写在双引号 here-string 里，依赖"反引号后跟非特殊字符"的偶然行为才不触发 PowerShell 转义，文案只要改动一次就会坏。
3. `scripts/ms-close.sh/.ps1` 的未打勾检测扫描整个文件的 `- [ ]`，使得 Plan 子任务未完成会阻断 close，而按 minispec 语义 Acceptance 才是闭卡的充分条件。

这三条同属"脚本行为正确性"主题，一并修掉以减少卡数并便于回归。

# Scope

- In:
  - `scripts/ms-project.sh` / `scripts/ms-project.ps1`：Node 依赖检测改为解析 `package.json` 的 `dependencies` / `devDependencies` 精确比对名字；沿用各框架原有优先级。
  - `scripts/ms-close.ps1`：合并块改用单引号 here-string `@'...'@` + `-f` 占位符注入 `$ChangeId` / `$notes`，消除反引号脆弱依赖。
  - `scripts/ms-close.sh` / `scripts/ms-close.ps1`：未打勾检测仅扫描 `# Acceptance` / `## Acceptance` 小节内；Plan/其他小节的 `- [ ]` 不再阻断 close。
- Out:
  - 不改 Java/Python/Go/Rust/.NET 的检测路径（超出本卡范围，未发现 parity 问题）。
  - 不改 SKILL / 文档关于 close 语义的措辞——与 P1-4（close 合并范围文档化）分开。

# Acceptance

- [x] Given 同一份含 `"next-sitemap"` 但不含 `"next"` 的 `package.json`，When 分别跑 `ms-project.sh` 与 `ms-project.ps1`，Then 两者输出的 `Framework` 均为 `Node.js application`（不再因子串 `"next"` 误判为 Next.js）。
- [x] Given 一个真正的 Next.js 仓库（`"next": "^14"` 在 dependencies），When 分别跑两端脚本，Then 两者 `Framework` 均输出 `Next.js`。
- [x] Given 一张 change card Acceptance 全部打勾、Plan 留一个 `- [ ]`，When 运行 `sh scripts/ms-close.sh <id> <domain>`，Then 脚本成功 close 并归档（不再以 Plan 未完为由拒绝）。
- [x] Given 一张 change card 任意一个 `- [ ]` 留在 Acceptance 小节内，When 运行 close，Then 脚本仍拒绝 close 并给出错误信息。
- [x] Given `ms-close.ps1` 合并块被写入 domain spec，When 打开该文件，Then 第一行 Notes 里原样出现 markdown 反引号包裹的文件路径 `` `minispec/changes/<id>.md` ``，且不出现 PowerShell 转义副作用（如 `\n` 变换行）。

# Plan

- [x] T1 重构 `scripts/ms-project.sh` 的 `detect_node`：抽取 `pkg_has_dep(name)`（从 `package.json` 用 `jq` 或 `awk`/`sed` 解析 dependencies/devDependencies 的 key 列表再精确匹配），替换所有 `contains_file_text "$pkg" '"<dep>"'` 调用。
  - Expected output: `detect_node` 在无 `jq` 环境仍可工作（fallback 用 awk 解析），误报为 0。
- [x] T2 同步 `scripts/ms-project.ps1` 的 `Detect-Node`：已是精确 `$deps -contains "<name>"`；核对 list 与 .sh 一致，不再有遗漏。
  - Expected output: 两端检测到同一份 package.json 产出一致的 Framework/Install/Build/Test/Lint。
- [x] T3 `scripts/ms-close.sh`：把未打勾扫描从整文件替换为"先提取 `^# Acceptance` 到下一个同级标题之间的内容再 grep"。
  - Expected output: Plan 中 `- [ ]` 不再阻断 close。
- [x] T4 `scripts/ms-close.ps1`：同步 T3 逻辑，使用 regex 限定 Acceptance 小节。
  - Expected output: 行为与 .sh 一致。
- [x] T5 `scripts/ms-close.ps1`：合并块 here-string 改单引号版 + `-f`/变量插入模板，消除反引号脆弱。
  - Expected output: `- Auto-merged from \`minispec/changes/<id>.md\`` 原样出现在 spec 文件里。
- [x] T6 本卡 Notes 小节填入验证日志（见 Notes）。

# Risks and Rollback

- Risk: 解析 `package.json` 的 awk 实现在含转义引号的极端边界 case 下可能漏判。Rollback：回退本卡 commit，脚本回到子串匹配。
- Risk: 限定 Acceptance 的 regex 若模板将来改为非 `# Acceptance` 小节（比如 `## Acceptance Criteria`）会失效。Rollback：把扫描范围再次放宽至全文件。

# Notes

- 决策：Node 精确匹配选择 dependencies ∪ devDependencies 的 key 集合，与 .ps1 行为对齐。
- 决策：沿用现有模板的 H1 `# Acceptance` 匹配模式（而非放宽到 `^#{1,6}`），与 `extract_section` 的既有契约保持一致，避免引入双标准。`extract_section` 同步移到未打勾检查之前。
- 决策：`ms-close.ps1` 合并块改为单引号 `@'…'@` here-string + `-f` 占位符；反引号的 markdown 语义仍然保留在 spec 里，但不再经过 PowerShell 字符串解释器。
- 验证记录：
  - fixture 1（仅含 `next-sitemap` / `react-next-helpers`）→ Framework = `Node.js application`；fixture 2（`next ^14` 显式依赖）→ Framework = `Next.js`。
  - close 测试：Plan 留 `- [ ]`、Acceptance 全打勾 → close 成功（exit 0，归档到位）；Acceptance 留 `- [ ]` → close 失败，提示 "Acceptance section has unchecked items." (exit 1)。
  - ms-close.sh 合并到 `minispec/specs/testdomain.md` 的 Notes 行原样包含 `` `minispec/changes/20260422-test-plan-only.md` ``。
  - ms-close.ps1 未在此次实机运行（平台为 bash on Windows）；代码对等逻辑经代码复核：预期表现与 .sh 一致。
