---
title: "S00 · 架构总览"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00-architecture-overview.md
---

## Summary
全课程 19 章的鸟瞰地图，解释这套仓库"还原什么、不还原什么"，建立四阶段学习路径（单 agent 核心 → 生产加固 → 任务管理 → 多 agent 平台），并给出关键状态分类总表。

## Key Claims
- 这套仓库追求"设计主脉络高保真，而非所有外围实现细节 1:1"
- 四阶段顺序符合初学者心智：先建立稳定主线，再补安全/扩展/记忆/恢复，最后才进入多 agent、隔离执行和外部工具平台
- 整个系统的状态最终会长成一个带很多子模块的状态系统，不只是 `messages + tools`
- `s01` 到 `s19` 每章新增的核心结构各不相同，按"依赖关系"而非"难度"排序

## Key Quotes
> "先做出能工作的最小循环，再一层一层给它补上规划、隔离、安全、记忆、任务、协作和外部能力。" — s00 课程总览结语

## Connections
- [[AgentLoop]] — 主循环是系统心脏，s01 建立
- [[QueryControlPlane]] — s00a 解释完整系统的 query 控制面长什么样
- [[TaskSystem]] — s12 把持久任务图列为关键状态之一
- [[Teammate]] — s15 多角色协作列为第四阶段核心能力
- [[MCP]] — s19 外部能力总线列为最终平台边界

## Contradictions
（无）
