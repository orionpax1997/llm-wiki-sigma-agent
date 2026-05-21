---
title: "团队-任务-车道模型"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-team-task-lane-model.md
---

## Summary
把 s15-s18 后半程最易混淆的五层边界拆开：teammate（长期参与者）→ protocol request（协调追踪）→ task（工作目标）→ runtime task（执行槽位）→ worktree（执行车道/隔离目录），并给出完整连接链和典型混淆例子（"alice 就是在做 login-page 这个 worktree 任务"）。

## Key Claims
- teammate 是"谁在长期参与协作"，不是任务本身
- protocol request 负责协调流程（有 request_id），task 负责表达目标（有 task_id），两者不是同一层
- runtime task 是"现在有什么在跑"，worktree 是"在哪做且不和别人互踩"
- 最典型混淆：把"alice 认领了 task#12 并在 login-page worktree 里推进"说成"alice 就是在做 login-page 任务"
- s17 的自治认领，认领的是 s12 的工作图任务，不是 s13 的运行时槽位

## Key Quotes
> "队友负责长期协作，请求负责协调流程，任务负责表达目标，运行时槽位负责承载执行，worktree 负责隔离执行目录。" — team-task-lane-model

## Connections
- [[Teammate]] — teammate 层定义
- [[Protocol]] — protocol request 层定义
- [[TaskSystem]] — task 层定义
- [[BackgroundTask]] — runtime task 层定义
- [[Worktree]] — worktree 层定义

## Contradictions
（无）
