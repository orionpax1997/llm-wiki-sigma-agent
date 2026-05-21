---
title: "S04 · 子智能体 / Subagent 上下文隔离"
type: source
tags: [curriculum, subagent, context-isolation, task-tool, fork, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s04.md
---

## Summary
`learn.shareai.run` 中文教程 s00–s19 系列的第四章。在 s01 ([[AgentLoop]]) + s02 ([[ToolRouting]]) + s03 ([[PlanningState]]) 之上，引入**子智能体 (Subagent)** 作为"局部任务的上下文边界"。核心做法：父智能体通过新增的 `task` 工具把局部任务外包给一个**拥有独立 `messages` 的子智能体**，子智能体在自己的上下文里读文件 / 搜索 / 调工具，做完只把摘要带回父智能体，中间过程不污染父对话。本章刻意**先停在最朴素子智能体**（空白上下文 + 工具集裁剪 + max_turns 保护），把 fork（继承父上下文）作为版本 4 才考虑的进阶；并明确划清与 s15–s17（多角色长期协作）和 s18（文件系统层隔离）的边界。

## Key Claims
- 当 agent 连续做多步任务时，`messages` 会被大量局部中间噪声塞满；最终对用户有价值的可能只有一句话，但中间过程把父上下文"撑爆"会让后续问题越来越难答。
- 子智能体的真正价值**不是"多一个模型实例"，而是"多一个干净上下文"**——它首先是一个**上下文边界**，不是炫技的并发或多角色。
- 最小心智模型只有三步：父智能体决定外包 → 子智能体在独立上下文里干活 → 只把摘要带回父智能体。
- 最小实现 4 件套：(1) 给父智能体加 `task` 工具；(2) 子智能体使用**自己的 `messages` 列表**（这是隔离的关键）；(3) 子智能体只拿必要工具（通常不给它继续派生 `task` 的能力，防无限递归）；(4) 只把摘要包成 `tool_result` 回流，不把内部历史粘回去。
- 关键数据结构 `SubagentContext { messages, tools, handlers, max_turns }`——子智能体的骨架就这四个字段，对应"上下文 / 能力声明 / 能力实现 / 停止保护"。
- 实现顺序必须分层：v1 空白上下文子智能体 → v2 限制工具集 → v3 加 max_turns + 失败保护 → v4 才考虑 fork。**fork 是下一步，不是起步**。
- fork 的本质：`sub_messages = list(parent_messages); sub_messages.append(prompt)`——继承上下文而非空白起步。只在子任务必须知道父智能体之前在聊什么时才需要。
- 子智能体的三大用处：(1) 给父上下文减负；(2) 让任务描述更聚焦（"读这几个文件给我一句总结"）；(3) 为多 agent 协作提供最小起点。
- 4 条初学者常见坑：把子智能体当并发炫技、把父历史全量灌回去（隔离价值归零）、一上来就做复杂角色系统（explorer/reviewer/planner……）、忘记停止条件（子智能体无限转）。
- **教学边界**：本章**只讲一次性子任务 + 摘要返回 + 新 messages + 工具过滤**——`fork` / 后台运行 / transcript 持久化 / worktree 绑定都不在本章；先做隔离，再做高级化。
- **章节关系明确**：s04 = 局部任务的上下文隔离；s15–s17 = 多个长期角色如何协作；s18 = 多个执行者如何在文件系统层面隔离。三者递进而非重复。

## Key Quotes
> "把局部任务放进独立上下文里做，做完只把必要结果带回来。" — 这一章到底要解决什么问题

> "子智能体的价值，不是'多一个模型实例'本身，而是'多一个干净上下文'。" — 最小心智模型

> "继承上下文，而不是重头开始。" — fork 的本质

> "子智能体首先是一个上下文边界。" — 教学边界

> "先做隔离，再做高级化。" — 实现顺序原则

> "子智能体的核心，不是多一个角色，而是多一个干净上下文。" — 一句话记住

## Connections
- [[AgentLoop]] — 子智能体本身就是一个独立运行的 agent loop 实例，只是它的 `messages` 与父智能体隔离。
- [[ToolRouting]] — `task` 工具复用 s02 的 dispatch map 机制：父智能体的 `TOOL_HANDLERS["task"] = run_subagent`，零改动主循环。子智能体内部又有自己的 (通常更小的) handler map。
- [[PlanningState]] — s03 的"会话内规划"是**单 agent 的过程性状态**；s04 引入的子智能体是**局部任务的上下文边界**。两者正交：父智能体可以维护自己的 PlanningState，子智能体可独立维护或不维护。
- [[Subagent]] — 本章的核心教学概念（Teaching Concept）。
- 序列前后：上一章 [[learn.shareai.run-zh-s03|S03]]；下一章 s05（尚未 ingest）。
- 远期对照：s15–s17（多个长期角色如何协作 / teammate / 任务认领 / 团队协议）、s18（多个执行者在文件系统层面如何隔离，如 worktree）。

## Contradictions
（与现有 wiki 内容无矛盾。s04 在 s01–s03 主循环不变的承诺上**新增一种执行模式**——把局部任务外包给独立上下文，并明确划定与未来"多 agent 协作"和"文件系统隔离"章节的边界，无逻辑冲突。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[Subagent]] 的 Teaching Concept：
- 名词解释：父智能体 / 子智能体 / 上下文隔离 / fork
- 心智模型：ASCII 流程图（Parent → Subagent → Summary → Parent continues）
- 最小实现 4 步：`task` 工具 schema、`run_subagent(prompt)` 函数、独立 `sub_messages`、摘要 `tool_result` 回流
- 关键数据结构：`SubagentContext {messages, tools, handlers, max_turns}`
- 4 个版本的实现顺序：v1 空白上下文 → v2 工具集裁剪 → v3 max_turns + 失败保护 → v4 fork
- 4 条初学者常见错误（炫技并发 / 全量历史灌回 / 一上来角色系统 / 忘记停止条件）
- 显式教学边界（明确"这一章不讲什么"——fork、后台、持久化、worktree）
- 显式章节边界（s04 vs s15–s17 vs s18 的递进关系）
- 一句话记住："子智能体的核心，不是多一个角色，而是多一个干净上下文。"
