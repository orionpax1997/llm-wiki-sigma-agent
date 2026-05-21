---
title: "S17 · 自治认领 / Autonomous Agent"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s17.md
---

## Summary
s17 在 s16 协议系统基础上增加"自治认领"能力：长期队友在空闲时自己扫描任务板，按角色过滤找到可认领任务并自动认领。核心升级：从"被动等 lead 派活"升级为"空闲时主动找活"。必须原子认领（防止两队友同时抢同一任务），且认领后要重注入身份上下文。

## Key Claims
- 自治 = 在提前给定规则的前提下，队友自己决定接哪份工作
- 认领条件：pending + 无 owner + 无 blockedBy + 角色匹配
- 认领必须是原子动作（加锁），防止重复抢任务
- 自治只针对长期队友，不针对一次性 subagent
- 认领的是 s12 的工作图任务，不是 s13 的后台执行槽位

## Key Quotes
> "自治不是让 agent 乱跑，而是让它在清晰规则下自己接住下一份工作。"
> "空闲时，按规则检查两类新输入：邮箱和任务板。"
> "s17 不是推翻 s16，而是在 s16 上继续加一条新能力。"

## Key Data Structures
- **Claimable Predicate**: `status==pending AND no owner AND no blockedBy AND role matches`
- **Claim Event Log**: `.tasks/claim_events.jsonl` → `event / task_id / owner / role / source / ts`
- **Identity Re-injection**: 压缩后重注入 `identity block` + 确认语，防止队友忘记自己是谁

## Connections
- 继承自 [[Teammate]]（s15）— 长期队友才需要自治
- 继承自 [[Protocol]]（s16）— 协议系统继续存在，不因自治而退回到"内存协议"
- 继承自 [[TaskSystem]]（s12）— 认领的是任务板上的工作图任务
- 为 s18 worktree 隔离奠定基础（认领后 worktree 绑定）
