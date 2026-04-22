---
id: 20260422-p2-nesting-docs
status: closed
owner: claude
---

# Why

仓库根叫 `minispec/`，里层还有一个 `minispec/`（合同目录）。对维护者是"仓库外壳 vs 合同目录"两层，对第一次读代码的人则是"路径里为什么连写两遍 minispec"——不讲清是一种低级门槛。同样地，`ms-init` 把合同目录安到用户仓库之后也会出现 `<user-repo>/minispec/...` 结构，用户也要理解这一点。

本卡在 README（中英文两版）靠前位置加一张极简结构图，把仓库内视角 vs 使用者视角都画出来，消除歧义。

# Scope

- In:
  - `README.md` 与 `README.zh-CN.md`：在 Directory Layout / 目录结构 段之前加 "Repo layout vs adopted-project layout" 子节（中文版对应 "仓库结构 vs 被引入项目的结构"），含两块 text 树。
- Out:
  - 不改目录本身（不重命名），不加 `MINISPEC_DIR` 环境变量。

# Acceptance

- [x] Given 打开 `README.md`，When 读 Directory Layout 之前，Then 能看到两块 text 树分别标注 "This repo" 与 "A project that adopted minispec via ms-init"。
- [x] Given 打开 `README.zh-CN.md`，Then 同等内容以中文呈现。

# Plan

- [x] T1 改 `README.md`，插入结构对照段。
- [x] T2 改 `README.zh-CN.md`，同步中文版。

# Risks and Rollback

- Risk: 结构图与真实目录哪天脱节。Rollback: 图尽量只列主要目录，不画子文件。

# Notes

- 决策：不做运行时 `MINISPEC_DIR` 配置，因为跨平台 skill / agent 约定的路径字面量用变量会破坏解析稳定性。
