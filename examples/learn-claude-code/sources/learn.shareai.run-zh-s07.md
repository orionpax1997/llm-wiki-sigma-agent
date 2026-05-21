---
title: "S07 · 权限系统 / Permissions"
type: source
tags: [agent, permissions, curriculum]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s07.md
---

## Summary
Agent 教程 s07：在工具意图与真实执行之间插入一条权限管道。核心思想是“任何工具调用都不应该直接执行；中间必须先过一条权限管道”。系统通过 deny rules → mode check → allow rules → ask user 四步判断，输出 allow / ask / deny 三种决策结果，通过后才执行 handler。

## Key Claims
- 权限系统不是布尔开关，而是一条管道（deny → mode → allow → ask）。
- Deny 必须优先于 allow，因为有些东西不应交给模式决定（如 sudo、rm -rf）。
- 推荐先做稳三种模式：default（灰区问用户）、plan（只读不写）、auto（安全操作自动过）。
- Bash 不是普通文本，而是可执行动作描述，必须单独做最小安全检查（sudo、rm -rf、命令替换、可疑重定向、元字符拼接）。
- 连续拒绝计数可作为 agent 卡住时的诊断信号。

## Key Quotes
> “任何工具调用，都不应该直接执行；中间必须先过一条权限管道。” — 核心 thesis
> “权限系统不是为了让 agent 更笨，而是为了让 agent 的行动先经过一道可靠的安全判断。” — 记忆 mnemonic
> “bash 不是普通文本，而是可执行动作描述。” — 特殊对待 bash 的理由

## Connections
- [[AgentLoop]] — 权限检查在 loop 的工具执行阶段之前插入
- [[ToolRouting]] — 权限管道位于路由之后、handler 之前
- [[Permissions]] — 本章节对应的 teachable concept
- [[ToolControlPlane]] — s02a 预告的完整工具控制平面包含权限层
- s08 — 执行前后插入额外逻辑（下一章）
- s10 — 把当前模式和权限说明放进 prompt 组装

## Contradictions
- 无（与 s01–s06 的“loop 不变”原则一致，权限是新增的前置检查层，不破坏既有结构）
