---
title: "S13 · 后台任务 / Background Task"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s13.md
---

## Summary
s13 把"s12 任务系统"里的工作目标，落实为真正在跑的执行单元。核心改变：慢命令不阻塞主循环，改在后台执行线程跑，通过通知队列在下一轮把摘要结果带回模型。强调"主循环只有一条，并行的是等待，不是主循环本身"。

## Key Claims
- 后台执行 = 命令在另一条执行线跑，主循环先去做别的事
- `background_run` 应立刻返回 `task_id`，不卡住主循环
- 完整输出写磁盘，通知队列只放 `result_preview` 摘要
- 后台任务（运行时执行单元）与 s12 task（工作目标）是两个不同的概念

## Key Quotes
> "主循环仍然只有一条，并行的是等待，不是主循环本身。"
> "通知负责提醒，文件负责存原文。"
> "task 更像工作板，background task 更像运行中的作业。"

## Mental Model
```
主循环
  +-- background_run("pytest") -> 立刻返回 task_id
  +-- 继续别的工作
  +-- 下一轮 drain_notifications() -> 注入摘要

后台执行线
  +-- 真正执行 pytest
  +-- 完成后写入通知队列
```

## Key Data Structures
- **RuntimeTaskRecord**: `id / command / status / started_at / result_preview / output_file`
- **Notification**: `type / task_id / status / preview`
- **BackgroundManager**: `tasks{} + notifications[] + lock`

## Connections
- 继承自 [[TaskSystem]]（s12）— task 回答"做什么"，background task 回答"哪个命令正在跑"
- 与 [[ErrorRecovery]]（s11）相关 — 后台任务失败时走错误恢复路径
- 为 [[Teammate]]（s15）提供运行时执行槽位的基础
