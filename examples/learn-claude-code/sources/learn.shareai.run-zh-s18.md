---
title: "S18 · 文件系统隔离 / Worktree"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s18.md
---

## Summary
s18 在 s17 自治认领基础上增加文件系统层隔离：为每个被认领的任务绑定一个 git worktree 执行车道，实现任务之间文件修改的物理隔离。核心区分：task 记录"做什么"，worktree 记录"在哪做"。两者通过 task_id 关联，但状态分开维护（task status 和 worktree_state 是不同维度）。

## Key Claims
- worktree 回答的不是"目录在哪"，而是"在哪做且互不干扰"
- task status（pending/in_progress/completed）和 worktree_state（active/kept/removed/unbound）是两个不同维度
- 先有 task，再有 worktree；创建时同时回写任务记录和 worktree 注册表
- 收尾（closeout）显式记录：keep 或 remove，以及原因

## Key Data Structures
- **WorktreeRecord**: `name / path / branch / task_id / status / last_entered_at / last_command_at / closeout`
- **CloseoutRecord**: `action(keep|remove) / reason / at`
- **EventRecord**: `event / task_id / worktree / reason / ts`

## Connections
- 继承自 [[AutonomousAgent]]（s17）— 认领后的任务需要独立执行车道
- 继承自 [[TaskSystem]]（s12）— task_id 来源
- 与 [[Teammate]] 相关 — 队友在不同 worktree 里执行不同任务
