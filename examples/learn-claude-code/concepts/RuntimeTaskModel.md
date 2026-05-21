---
title: "RuntimeTaskModel"
type: concept
tags: [reference, task-system, runtime-model]
sources: [learn.shareai.run-zh-s13a-runtime-task-model]
last_updated: 2026-05-08
---

## Definition
运行时任务模型：与工作图任务（TaskRecord）相对，指系统当前活着的一条执行槽位。

## Key Claims
- RuntimeTaskState 和 TaskRecord 不是同一层：TaskRecord 是长期工作目标，RuntimeTaskState 是当前执行单元
- 一个 TaskRecord 可以派生多个 RuntimeTaskState（如：一个任务同时启动 pytest 后台任务、teammate worker、monitor）
- RuntimeTaskState 回答：现在有什么在跑、什么类型、输出在哪、是否已通知

## Connections
- [[TaskSystem]] — s12 TaskRecord 的下游
- [[BackgroundTask]] — s13 后台任务系统对应 RuntimeTaskState 层
- [[Teammate]] — teammate 可以作为 RuntimeTaskState 的一种
- [[EntityMap]] — 工作层中 work-graph task vs runtime task 是最关键区分之一
