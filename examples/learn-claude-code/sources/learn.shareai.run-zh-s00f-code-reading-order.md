---
title: "S00f · 代码阅读顺序"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00f-code-reading-order.md
---

## Summary
告诉读者本地 `agents/*.py` 该按什么顺序打开，每章先看状态结构/工具列表/主推进函数/CLI 入口，并给出四阶段读代码指南（s01-s06 核心骨架 / s07-s11 控制面 / s12-s14 任务系统 / s15-s19 平台边界），附带"初学者最容易犯的 6 个代码阅读错误"。

## Key Claims
- 读每个 agent 文件都先按"状态结构→工具列表→主推进函数→CLI 入口"模板
- 读代码前先读文档，文档顺着章节读，代码也顺着章节读
- s13 和 s12 的关键边界：task 是工作目标，runtime task 是正在跑的执行槽位，schedule 是何时触发，三层不能在代码里混掉
- 最稳学习动作是"读文档→读代码→跑 demo→从空目录重写最小版本"

## Key Quotes
> "代码阅读顺序也必须服从教学顺序：先看边界，再看状态，再看主线如何推进，而不是随机翻源码。" — s00f

## Connections
- [[ArchitectureOverview]] — s00f 提供代码层面的具体读法，配合课程总览使用
- [[TaskSystem]] — s12 代码读法：先看 TaskManager，再看任务创建/依赖/解锁→agent_loop()

## Contradictions
（无）
