---
id: 20260424-pause-test-crlf-fix
status: closed
owner: claude
---

# Why

CI 的 Pester job 在 windows-latest runner 上跑 `Pause.Tests.ps1` 的 `ms-init drops minispec/.gitignore` 用例时失败——`(?m)^\.paused$` 在 `Get-Content -Raw` 读到的 CRLF 文本上匹配不到。原因和 P3-c 里 `Init.Tests.ps1` 的老坑一致：.NET regex 的 `(?m)$` 匹配 `\n` 之前的位置，但 `\r` 还在前面，导致锚点失效。本机通过是因为我的 PS 版本或行尾策略不同；CI runner 固定写 CRLF。

# Approach

单一合理路径：去掉 `$` 末尾锚点，留 `^` 首锚点即可（模式 `.paused` 足够唯一，不需 `$` 来防止更长匹配——`.paused` 下一字符本来就是行结束符）。其他相似断言（`^\.paused` 在 bats 里）不受影响因为 bats 的 grep 不走 .NET regex。

# Scope

- In:
  - `tests/pester/Pause.Tests.ps1` 第 ～95 行：去掉 `(?m)^\.paused$` 的 `$` 锚点。
- Out:
  - 不动 `ms-init.ps1` 的生成逻辑（内容正确，只是断言太严）。
  - 不改其他 Pester 文件。

# Acceptance

- [x] Given CI windows-latest runner，When 重跑 Pester 套件，Then `creates minispec/.gitignore excluding .paused` 用例通过。
- [x] Given 本机 Pester 跑，Then 26 个用例仍全绿。

# Plan

- [x] T1 改 `tests/pester/Pause.Tests.ps1` 一行。
- [x] T2 本机 Pester 跑一遍确认无回归。
- [x] T3 close → commit → push。

# Risks and Rollback

- Risk: 漏掉的其他 `(?m)^...$` 断言再爆同样的雷。Rollback: grep `(?m)^.*\$"` 在 tests/pester/ 下扫一遍。

# Notes

- 决策：保留 `^` 锚点而不是彻底换成 `Should -Contain` 行分割——因为这个断言目的是"以 `.paused` 开头的一整行"，`^\.paused` 已经达意；不追求全匹配。
- 教训记一笔：写 Pester `Should -Match` 的锚点时，涉及文件内容的都按 CRLF-safe 来写——`^` 留、`$` 去。`tests/pester/` 的 style-guide 可考虑写进 `tests/README.md`（另起小卡）。
