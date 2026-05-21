---
title: "S15 · 多角色协作 / Teammate System"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s15.md
---

## Summary
s15 在 s04 subagent 基础上引入"长期队友"——拥有名字、角色、消息邮箱和独立 agent loop 的持久 agent。核心区别：subagent 是一次性委派（创建→执行→消失），teammate 是长期成员（spawn→收 inbox→循环工作）。系统通过 TeamConfig（名册）和 MessageEnvelope（信封）管理团队协作。

## Key Claims
- Teammate 和 subagent 的根本区别在生命周期，不在名字
- Teammate 和 s13 runtime task 的区别：teammate 有名字/邮箱/独立循环，runtime task 只是正在跑的执行槽位
- 团队系统最小需要：名册（config）+ 邮箱（inbox）+ 独立循环
- 每个队友应有自己的 messages 和 inbox，不共享上下文

## Key Quotes
> "subagent 是一次性执行单元，teammate 是长期存在的协作成员。"
> "队友不是靠'被重新创建'来获得新任务，而是靠'下一轮先检查邮箱'来接收新工作。"
> "teammate 的核心不是'多一个模型调用'，而是'多一个长期存在的执行者'。"

## Key Data Structures
- **TeamMember**: `name / role / status`
- **TeamConfig**: `team_name / members[]` → `.team/config.json`
- **MessageEnvelope**: `type / from / content / timestamp`

## Distinction Table
| 机制 | 更像什么 | 生命周期 | 关键边界 |
|---|---|---|---|
| subagent | 一次性外包助手 | 干完就结束 | 隔离探索性上下文 |
| runtime task | 正在跑的执行槽位 | 任务跑完就结束 | 慢命令稍后回来 |
| teammate | 长期在线队友 | 可以反复接任务 | 有名字、有邮箱、有独立循环 |

## Connections
- 继承自 [[Subagent]]（s04）— 共享上下文隔离思想，但升级为持久生命周期
- 继承自 [[BackgroundTask]]（s13）— 共享通知/消息队列机制
- 与 [[TaskSystem]]（s12）相关 — 队友可认领任务板上的任务
- 为 [[Protocol]]（s16）和 [[AutonomousAgent]]（s17）奠定基础
