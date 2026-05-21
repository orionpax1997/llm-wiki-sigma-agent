---
title: "S13a · 运行时任务模型"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s13a-runtime-task-model.md
---

## Summary
专门拆清两种"任务"：工作图任务（s12 的 task record，回答"要做什么/谁依赖谁/谁认领了/当前进度"）vs 运行时任务（s13 的 runtime task，回答"现在有什么执行单元正在跑/是什么类型/输出文件在哪/是否已通知"），强调一个工作图任务可以派生多个运行时任务，两者不是同一层。

## Key Claims
- 工作图任务管"长期目标和依赖"，运行时任务管"当前活着的执行单元和输出"
- RuntimeTaskState 和 TaskRecord 不是一回事：TaskRecord 是长期工作目标，RuntimeTaskState 是系统当前活着的一条执行槽位
- 一个工作图任务可以派生多个运行时任务（如：一个任务同时启动 pytest 后台任务、coder teammate 任务、monitor 任务）
- 不区分这两层会导致 s13 的后台任务和 s12 的任务板混淆，s15-s17 的 teammate/agent 不知道挂在哪

## Key Quotes
> "工作图任务管'长期目标和依赖'，运行时任务管'当前活着的执行单元和输出'。" — s13a

## Connections
- [[TaskSystem]] — s13a 补充 s12 TaskRecord 和 s13 RuntimeTaskState 的分层边界
- [[BackgroundTask]] — s13 后台任务系统对应 RuntimeTaskState 层
- [[Teammate]] — teammate 可以作为 runtime task 的一种（in_process_teammate）
- [[MCPCapabilityLayers]] — 某些外部监控或异步调用也可能落成 runtime task

## Contradictions
（无）
