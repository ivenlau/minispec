---
id: 20260422-p1-dogfood-project-and-workflow-spec
status: closed
owner: claude
---

# Why

仓库自带的 `minispec/project.md` 仍是全 `TBD` 的初始模板，且 `minispec/specs/` 里只有 `README.md` 的占位，没有任何 domain spec。这让"这个工具怎么用自己"的回答缺失——`ms-doctor` 会一直因 `TBD` 报 WARN（P1-d 新增的语义检查）；潜在贡献者也看不到 minispec 如何描述自身约束。

本卡把 project.md 改写成描述 minispec 自身（POSIX sh + PowerShell 7 + Markdown，约束是双实现 parity、零 runtime 依赖），并新增 `minispec/specs/workflow.md` 作为 6-action workflow 的自描述 spec。

# Scope

- In:
  - 改写 `minispec/project.md`：
    - Stack 填真实栈（POSIX sh、PowerShell 7+、Markdown）。
    - Commands 填真实命令（Install = 无；Build = 无；Test = `sh scripts/ms-doctor.sh .`；Lint = `shellcheck scripts/*.sh` + `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path scripts/*.ps1"`）。
    - Engineering Constraints / Non-Goals / Definition of Done 按 minispec 自身场景写。
    - 保留（或补写）Maintainer Notes 段用 P1-b 的 marker。
  - 新建 `minispec/specs/workflow.md`：
    - 用 Given/When/Then 形式描述 6 个 action 的行为契约（Inputs、关键判定、失败条件）。
    - 结构与其他 domain spec 对齐（close 之后会在文件末尾 append `## Change ...` 块）。
- Out:
  - 不修改脚本（本卡只是用它）。
  - 不补历史 archive 卡。

# Acceptance

- [x] Given 运行 `sh scripts/ms-doctor.sh .`，When 读取 Semantic checks 输出，Then 不再出现 `still contains TBD placeholders`。
- [x] Given 打开 `minispec/project.md`，Then `## Stack` 与 `## Commands` 所有字段都有具体值（无 `TBD`）。
- [x] Given 打开 `minispec/project.md`，Then 末尾存在 `## Maintainer Notes` 段与 manual-managed marker 注释。
- [x] Given 打开 `minispec/specs/workflow.md`，Then 存在 6 个 `### <action>` 子段，每段包含至少一个 `Given/When/Then` 三元组。
- [x] Given 对本卡执行 `ms-close.sh <id> workflow .`，Then 合并块 append 到 `minispec/specs/workflow.md`，且原有 workflow 规则段保留。

# Plan

- [x] T1 重写 `minispec/project.md`。
- [x] T2 新建 `minispec/specs/workflow.md`。
- [x] T3 运行 `ms-doctor` 确认 TBD WARN 消失。
- [x] T4 本卡 close 到 domain = workflow。

# Risks and Rollback

- Risk: Commands 中 shellcheck / PSScriptAnalyzer 并非所有用户机器可用，check 阶段的 lint 可能空跑。Rollback: 在 Commands 备注 "requires shellcheck + PSScriptAnalyzer installed"。
- Risk: workflow.md 与 SKILL.md 描述漂移的新风险。后续 P2-1（单源 SKILL）应把两者关系再理顺。

# Notes

- 决策：`Test` 命令选 `ms-doctor` 而不是"跑一组 bats/Pester 测试"——后者在 P2-2 引入；当前 minispec 的"测试"只是结构 + 语义检查。
- 决策：workflow.md 的 BDD 三元组面向 agent 与人类共读，先于实现的细节——脚本与 SKILL 都应该符合这些契约。
