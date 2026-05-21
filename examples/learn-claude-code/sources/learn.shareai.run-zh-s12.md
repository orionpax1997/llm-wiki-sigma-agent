---
title: "S12 · 任务系统 / Task System"
type: source
tags: [task-system, dependency-graph, persistence, curriculum, learn.shareai.run]
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s12.md
---

## Summary
把 s03 的会话内 todo 升级为持久化任务图。核心新增能力：依赖关系（blockedBy / blocks）、ready 判断（pending + 无依赖）、落盘存储（.tasks/ 一任务一文件）、完成时自动解锁后续任务。明确与 s03（会话级平面列表）和 s13（运行时执行层）的边界。

## Key Claims
- 任务系统的核心不是“保存清单”，而是“判断什么时候能开工”。
- `TaskRecord` 是本章最关键的数据结构；`blockedBy` / `blocks` 让系统能看懂前后关系。
- `is_ready()` 让系统能判断“谁现在可以开始”。
- 任务系统不是静态记录表，而是会随着完成事件自动推进的工作图。
- todo 更像本轮计划，task 更像长期工作板。

## Key Quotes
> "把'会话里的 todo'升级成'可持久化的任务图'。"

> "任务系统的核心不是'保存清单'，而是'判断什么时候能开工'。"

> "任务系统不是静态记录表，而是会随着完成事件自动推进的工作图。"

> "todo 更像本轮计划，task 更像长期工作板。"

## Connections
- [[PlanningState]] — s03 的会话内 todo；s12 将其升级为持久化任务图
- [[AgentLoop]] — 主循环首次拥有会话外状态（.tasks/ 落盘）
- [[ToolRouting]] — task_create / task_update / task_get / task_list 通过 dispatch map 接入，循环零改动
- [[Subagent]] — 多 agent 协作时需要统一任务板可读
- [[Memory]] — 任务持久化与跨会话 memory 的存储边界

## Contradictions
- 无。与 s03 的边界被显式划定（会话级 vs 持久化 / 平面列表 vs 依赖图），不冲突。
