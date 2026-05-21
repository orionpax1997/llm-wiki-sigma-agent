---
title: "S03 · 会话内规划状态 / Todo & Active Step"
type: source
tags: [curriculum, planning-state, todo, active-step, reminder, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s03.md
---

## Summary
`learn.shareai.run` 中文教程 s00–s19 系列的第三章。在 s01 ([[AgentLoop]]) + s02 ([[ToolRouting]]) 之上，向主循环引入第二块显式状态——`PlanningState`：一份**当前会话内、轻量、可反复重写**的 todo 列表。核心数据结构是 `PlanItem {content, status, activeForm}`，加上"同一时间至多一个 `in_progress`" 的强约束、整份重写的更新方式，以及连续 N 轮未更新就触发的 `<reminder>` 机制。本章特别强调**边界**：这里的 todo **不是**持久任务板、依赖图、或多 agent 工作图——那些留给 s12–s14。

## Key Claims
- 有了文件 + bash 工具之后，agent 在多步任务中容易"漂"：走一步忘一步、重复已做的检查、即兴跳出原计划。模型并不蠢，但**当前注意力始终受上下文影响**——没有显式、稳定、可反复更新的计划状态，长任务必然失焦。
- 解决方案不是"更强的工具"，而是**让 agent 把当前会话里的计划外显出来，并持续更新**。
- "会话内规划"不是长期项目管理、不是磁盘任务系统——它只服务**当前这次请求**："先把接下来几步写出来，并在过程中不断更新"。
- 教学版关键约束：**同一时间最多一个 `in_progress`**。这不是宇宙真理，而是强制模型聚焦"先把一件事做完，再进入下一件"的教学边界。
- 教学版让模型**整份重写**当前计划（而非局部增删改），更容易理解、更容易让模型维护一致性。
- `rounds_since_update` 计数 + `<reminder>Refresh your plan before continuing.</reminder>` 注入，是把"计划是否失活"也纳入主循环可观测状态的关键一步——reminder 不是装饰，而是表明**主循环开始维护"过程性状态"，而不仅仅是"对话状态"**。
- 主循环升级：从只维护 `messages` → 同时维护 `messages` + `PlanningState`。"当前要做什么"从模型脑内移到系统可观察的状态里。
- **本章显式不讲**：任务依赖、长期持久化、多人协作任务板、后台运行槽位——这些会在 s12–s14 系统展开；混淆"当前一步"与"系统长期工作项"是初学者最容易犯的错。

## Key Quotes
> "让 agent 把当前会话里的计划外显出来，并且持续更新。" — 这一章要解决什么问题

> "同一时间，最多一个 in_progress。这不是宇宙真理。它只是一个非常适合初学者的教学约束：强制模型聚焦当前一步。" — 状态约束

> "系统开始把'计划状态是否失活'也看成主循环的一部分。" — 提醒机制

> "把'当前要做什么'从模型脑内，移到系统可观察的状态里。" — 它如何接到主循环里

> "s03 的 todo，不是任务平台，而是当前会话里的'外显计划状态'。" — 一句话记住

## Connections
- [[AgentLoop]] — 本章把 `PlanningState` 加进主循环，让循环维护的状态从单一 `messages` 扩展为 `messages + planning state`。
- [[ToolRouting]] — `todo` 工具复用 s02 的 dispatch map：`TOOL_HANDLERS["todo"] = lambda **kw: TODO.update(kw["items"])`，零改动循环。
- [[PlanningState]] — 本章的核心教学概念（Teaching Concept）。
- 序列前后：上一章 [[learn.shareai.run-zh-s02|S02]]；下一章 s04（尚未 ingest）。
- 远期对照：s12–s14 描述的"完整任务系统"（持久化、依赖图、多 agent 工作图）。

## Contradictions
（与现有 wiki 内容无矛盾。本章在 s01 / s02 主循环不变的承诺上**新增一块状态**，并明确划定与未来"任务系统"章节的边界，无逻辑冲突。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[PlanningState]] 的 Teaching Concept：
- 名词解释：会话内规划 / todo / active step / reminder
- 心智模型：ASCII 流程图（用户大任务 → 写计划 → 三态推进 → 每步更新）
- 最小数据结构：`PlanItem {content, status, activeForm}` + `PlanningState {items, rounds_since_update}`
- 强教学约束：单 `in_progress` 不变量
- 最小实现：`TodoManager` 类（`update` / `render`）+ dispatch 接入 + reminder 注入
- 5 条初学者常见错误（计划过长 / 多 in_progress / 当成长期任务系统 / 只写一次不更新 / 把 reminder 当装饰）
- 显式教学边界（"这一章不是任务系统"——明确划清与 s12–s14 的区别）
- 一句话记住：todo 是当前会话里的"外显计划状态"，不是任务平台
