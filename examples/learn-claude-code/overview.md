---
title: "Wiki Overview"
type: overview
tags: []
last_updated: 2026-05-08
---

## Current Scope
本 wiki 当前聚焦 `learn.shareai.run` 中文 agent 教程系列 (s00–s19 + s00 系列桥接文档)。已 ingest: **s01–s19（全部完成）+ s00 系列 17 份桥接/参考文档（全部完成）**。整个 19 章序列的核心叙事是：

> 从最小 agent 主循环 (s01) 出发，逐章往里加新的状态、分支和能力（工具路由、规划、上下文压缩、权限、错误恢复……），最终拼成一个完整的 agent 系统。

## Threads in Progress
- **Claude Code 官方博客系列（新增）** — 开始 ingest claude.com 官方博客文章，丰富 Claude Code 产品级使用视角，与 learn.shareai.run 的"自己写 agent"形成互补。
- **s00 桥接文档体系** — s00/s00a/s00b/s00c/s00d/s00e/s00f 全部 ingest 完成（7 份参考/桥接文档 + 6 份领域参考文档 + s02a/s02b/s10a/s13a/s19a）。新增概念：[[ArchitectureOverview]]（课程总览地图）、[[QueryControlPlane]]（显式控制平面）、[[OneRequestLifecycle]]（请求纵向流程）、[[QueryTransitionModel]]（6 种 transition reason）、[[ChapterOrderRationale]]（章节顺序原理）、[[ReferenceModuleMap]]（源码对照）、[[CodeReadingOrder]]（读代码指南）、[[TeachingScope]]（教学边界）、[[Glossary]]（术语表）、[[DataStructures]]（数据结构总表）、[[EntityMap]]（实体分层地图）、[[ToolExecutionRuntime]]（工具执行运行时）、[[MCPCapabilityLayers]]（MCP 6 层能力地图）、[[TeamTaskLaneModel]]（团队/任务/车道五层边界）。
- **Agent 内核构建（curriculum）** — `learn.shareai.run` s00–s19 系列。已 ingest: s01 (主循环)、s02 (工具路由)、s03 (规划状态)、s04 (子智能体)、s05 (skill 系统)、s06 (上下文压缩)、s07 (权限系统)、s08 (hook 系统)、s09 (持久状态)、s10 (prompt pipeline)。后续章节将逐步把以下能力补进 [[AgentLoop]]：
  - ~~s02 工具路由~~ → [[ToolRouting]] ✅
  - ~~s03 规划状态~~ → [[PlanningState]] ✅
  - ~~s04 子智能体~~ → [[Subagent]] ✅
  - ~~s05 skill 系统~~ → [[SkillSystem]] ✅
  - ~~s06 上下文压缩~~ → [[ContextCompression]] ✅
  - ~~s07 权限判断~~ → [[Permissions]] ✅
  - ~~s08 执行前后插入额外逻辑~~ → [[HookSystem]] ✅
  - ~~s09 持久状态~~ → [[Memory]] ✅
  - ~~s10 prompt pipeline~~ → [[PromptPipeline]] ✅
  - ~~s11 错误恢复~~ → [[ErrorRecovery]] ✅
  - ~~s12 任务系统~~ → [[TaskSystem]] ✅
  - ~~s13 后台任务~~ → [[BackgroundTask]] ✅
  - ~~s14 定时调度~~ → [[Scheduler]] ✅
  - ~~s15 多角色协作~~ → [[Teammate]] ✅
  - ~~s16 协议请求~~ → [[Protocol]] ✅
  - ~~s17 自治认领~~ → [[AutonomousAgent]] ✅
  - ~~s18 文件系统隔离~~ → [[Worktree]] ✅
  - ~~s19 MCP 外部能力~~ → [[MCP]] ✅（全部完成）
- **工具层结构演进** — s02 已显式预告"工具层最终会成长为控制平面"（含权限、app state、MCP、缓存、通知），目前由 [[ToolRouting]] / [[PathSandbox]] / [[MessageNormalization]] 三个概念承接最小分发模型。s05 进一步证明：**新能力（skill 系统）可以零改动主循环、纯靠 dispatch map + 一个 `load_skill` 工具就实现**——这是工具层"控制平面化"的早期证据。
- **主循环状态扩展** — s03 起，agent loop 维护的状态从单一 `messages` 扩展为 `messages + PlanningState`。后续章节会继续往主循环加新状态（压缩游标、权限上下文、错误计数等），形成"过程性状态簇"。
- **执行结构扩展（agent 拓扑）** — s04 起，agent 不再是"单一全局 messages"的单体；通过 [[Subagent]] 引入"局部任务的上下文边界"。后续 s15–s17 将扩展为多角色长期协作，s18 进一步把隔离扩展到文件系统层（worktree）。三层递进：上下文隔离 → 角色协作 → 文件系统隔离。
- **Prompt 预算管理** — s05 起出现新主线：**system prompt 不再是一段扁平的固定身份说明**，而是分成"稳定层（身份 + 规则 + 工具 + skill 目录）+ 按需层（当前真的加载进来的 skill 正文）"。[[SkillSystem]] 处理"常驻知识开销"，[[Subagent]] 处理"过程性噪声"，[[ContextCompression]] (s06) 处理"历史累积开销"——三者共同构成 prompt 预算的三种压力来源。s10 将其系统化为 [[PromptPipeline]]：6 段组装流水线（core + tools + skills + memory + CLAUDE.md + dynamic），明确稳定层与动态层分离。

## Anchoring Theses (across sources)
- _"Agent 的核心不是模型很聪明，而是系统持续把现实结果喂回模型。"_ — [[learn.shareai.run-zh-s01|S01]]
- _"加工具 = 加 handler + 加 schema。循环永远不变。"_ — [[learn.shareai.run-zh-s02|S02]]
- _"`messages` 列表是系统的内部表示, API 看到的是规范化后的副本。两者不是同一个东西。"_ — [[learn.shareai.run-zh-s02|S02]]
- _"把'当前要做什么'从模型脑内，移到系统可观察的状态里。"_ — [[learn.shareai.run-zh-s03|S03]]
- _"s03 的 todo，不是任务平台，而是当前会话里的'外显计划状态'。"_ — [[learn.shareai.run-zh-s03|S03]]
- _"子智能体的核心，不是多一个角色，而是多一个干净上下文。"_ — [[learn.shareai.run-zh-s04|S04]]
- _"先做隔离，再做高级化。"_ — [[learn.shareai.run-zh-s04|S04]]
- _"Skill 系统的核心，不是'多一个工具'，而是'把可选知识从常驻 prompt 里拆出来，改成按需加载'。"_ — [[learn.shareai.run-zh-s05|S05]]
- _"平时只展示'有哪些知识包'，真正工作时才把那一包展开。"_ — [[learn.shareai.run-zh-s05|S05]]
- _"上下文压缩的核心，不是尽量少字，而是让模型在更短的活跃上下文里，仍然保住继续工作的连续性。"_ — [[learn.shareai.run-zh-s06|S06]]
- _"agent loop 现在开始同时维护两件事：任务推进 + 上下文预算。"_ — [[learn.shareai.run-zh-s06|S06]]
- _"任何工具调用，都不应该直接执行；中间必须先过一条权限管道。"_ — [[learn.shareai.run-zh-s07|S07]]
- _"权限系统不是为了让 agent 更笨，而是为了让 agent 的行动先经过一道可靠的安全判断。"_ — [[learn.shareai.run-zh-s07|S07]]
- _"主循环只负责暴露'时机'，真正的附加行为交给 hook。"_ — [[learn.shareai.run-zh-s08|S08]]
- _"hook 让系统可扩展，但不要求主循环理解每个扩展需求。"_ — [[learn.shareai.run-zh-s08|S08]]
- _"memory 不是'什么都记'，而是只记跨会话仍有价值、且不能轻易从当前状态重新推导出来的信息。"_ — [[learn.shareai.run-zh-s09|S09]]
- _"memory 用来提供方向，不用来替代当前观察。"_ — [[learn.shareai.run-zh-s09|S09]]
- _"system prompt 的关键不是'写一段很长的话'，而是'把不同来源的信息按清晰边界组装起来'。"_ — [[learn.shareai.run-zh-s10|S10]]
- _"错误先分类，恢复再执行，失败最后才暴露给用户。"_ — [[learn.shareai.run-zh-s11|S11]]
- _"任务系统的核心不是'保存清单'，而是'判断什么时候能开工'。"_ — [[learn.shareai.run-zh-s12|S12]]
- _"任务系统不是静态记录表，而是会随着完成事件自动推进的工作图。"_ — [[learn.shareai.run-zh-s12|S12]]
- _"todo 更像本轮计划，task 更像长期工作板。"_ — [[learn.shareai.run-zh-s12|S12]]
- _"主循环仍然只有一条，并行的是等待，不是主循环本身。"_ — [[learn.shareai.run-zh-s13|S13]]
- _"通知负责提醒，文件负责存原文。"_ — [[learn.shareai.run-zh-s13|S13]]
- _"调度器做的是'记住未来'，不是'取代主循环'。"_ — [[learn.shareai.run-zh-s14|S14]]
- _"后台任务是在'等结果'，定时调度是在'等开始'。"_ — [[learn.shareai.run-zh-s14|S14]]
- _"teammate 的核心不是'多一个模型调用'，而是'多一个长期存在的执行者'。"_ — [[learn.shareai.run-zh-s15|S15]]
- _"协议消息和普通聊天消息不是一回事；普通消息解决'说了什么'，协议消息解决'这件事走到哪一步了'。"_ — [[learn.shareai.run-zh-s16|S16]]
- _"自治不是让 agent 乱跑，而是让它在清晰规则下自己接住下一份工作。"_ — [[learn.shareai.run-zh-s17|S17]]
- _"任务系统管'做什么'，worktree 系统管'在哪做且互不干扰'。"_ — [[learn.shareai.run-zh-s18|S18]]
- _"进入方式不同，但进入后必须回到同一条控制面和执行面。"_ — [[learn.shareai.run-zh-s19|S19]]
- _"MCP 的本质，不是协议名词堆砌，而是把外部工具安全、统一地接进 agent。"_ — [[learn.shareai.run-zh-s19|S19]]
- _"先做出能工作的最小循环，再一层一层给它补上规划、隔离、安全、记忆、任务、协作和外部能力。"_ — [[learn.shareai.run-zh-s00-architecture-overview|S00]]
- _"更完整的 query loop 不只是'循环'，而是'拿着一份跨轮状态不断推进的查询控制平面'。"_ — [[learn.shareai.run-zh-s00a-query-control-plane|S00a]]
- _"一次请求的完整生命周期，本质上就是：系统围绕同一条主循环，把不同模块按阶段接进来，最终持续把真实执行结果送回模型继续推理。"_ — [[learn.shareai.run-zh-s00b-one-request-lifecycle|S00b]]
- _"一条 query 不是简单 while loop，而是一串显式 continuation reason 驱动的状态转移。"_ — [[learn.shareai.run-zh-s00c-query-transition-model|S00c]]
- _"好的章节顺序，不是把所有机制排成一列，而是让每一章都像前一章自然长出来的下一层。"_ — [[learn.shareai.run-zh-s00d-chapter-order-rationale|S00d]]
- _"最好的教学顺序，不是源码文件出现的顺序，而是一个初学实现者真正能顺着依赖关系把系统重建出来的顺序。"_ — [[learn.shareai.run-zh-s00e-reference-module-map|S00e]]
- _"代码阅读顺序也必须服从教学顺序：先看边界，再看状态，再看主线如何推进，而不是随机翻源码。"_ — [[learn.shareai.run-zh-s00f-code-reading-order|S00f]]
- _"一个结构完整的系统最怕的不是功能多，而是实体边界不清；边界一清，很多复杂度会自动塌下来。"_ — [[learn.shareai.run-zh-entity-map|EntityMap]]
- _"队友负责长期协作，请求负责协调流程，任务负责表达目标，运行时槽位负责承载执行，worktree 负责隔离执行目录。"_ — [[learn.shareai.run-zh-team-task-lane-model|TeamTaskLaneModel]]
- _"MCP 是外部能力平台，而 tools 只是它最先进入主线的那个切面。"_ — [[learn.shareai.run-zh-s19a-mcp-capability-layers|S19a]]
- _"Context rot is the observation that model performance degrades as context grows because attention gets spread across more tokens."_ — [[claude.com-blog-using-claude-code-session-management-and-1m-context|Session Management]]
- _"The mental test we use at Anthropic: will I need this tool output again, or just the conclusion?"_ — [[claude.com-blog-using-claude-code-session-management-and-1m-context|Session Management]]
- _"Subagents are self-contained agents that operate with their own context windows... When it completes its task, the subagent returns only the relevant results to the main conversation."_ — [[claude.com-blog-subagents-in-claude-code|Subagents in Claude Code]]
- _"Start conversational, automate later."_ — [[claude.com-blog-subagents-in-claude-code|Subagents in Claude Code]]
- transition_reason 在更完整系统中会扩展出哪些状态值
- s08 的 HookSystem 与 s02a 描述的完整 ToolControlPlane 之间还需要哪些维度才能闭合（权限 ✅ / hook ✅ / 缓存 / MCP ✅ / 通知 / app state 注入）→ 见 [[ToolControlPlane]] 合成页
- s00 课程总览 → ✅ ingested：四阶段路径 + 关键状态分类（见 [[ArchitectureOverview]]）
- s00a-query-control-plane → ✅ ingested：显式 QueryState + TransitionReason + 6 种续行原因（见 [[QueryControlPlane]]）
- s02a-tool-control-plane → ✅ ingested：ToolUseContext 总线升级 dispatch map（见 [[ToolControlPlane]]）
- s13a-runtime-task-model → ✅ ingested：TaskRecord vs RuntimeTaskState 边界（见 [[TaskSystem]]）
- team-task-lane-model → ✅ ingested：teammate/protocol/task/runtime task/worktree 五层边界（见 [[TeamTaskLaneModel]]）
- s19a-mcp-capability-layers → ✅ ingested：MCP 6 层能力地图（见 [[MCPCapabilityLayers]]）
- **Session 管理与上下文策略** — session management + 1M context 博客补充了 context rot 概念和 session 决策表（Continue / Rewind / Compact / Clear / Subagent）；subagents 博客补充了 subagent 的 5 种调用方式和 5 大使用模式，形成"上下文预算管理"的完整外层策略
