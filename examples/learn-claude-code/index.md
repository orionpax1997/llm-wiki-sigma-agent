# Wiki Index

## Overview
- [Overview](overview.md) — living synthesis across all sources

## Sources
- [S01 · Agent Loop 核心闭环](sources/learn.shareai.run-zh-s01.md) — `learn.shareai.run` 中文教程 s00–s19 系列第一章，最小 agent 主循环
- [S02 · 工具路由 / Tool Use](sources/learn.shareai.run-zh-s02.md) — 同系列第二章，dispatch map + 路径沙箱 + 消息规范化
- [S03 · 会话内规划状态 / Todo & Active Step](sources/learn.shareai.run-zh-s03.md) — 同系列第三章，把 PlanningState 引入主循环（todo / 单 in_progress / reminder）
- [S04 · 子智能体 / Subagent 上下文隔离](sources/learn.shareai.run-zh-s04.md) — 同系列第四章，用 `task` 工具把局部任务外包给独立 `messages` 的子智能体，只回摘要
- [S05 · Skill 系统 / 按需加载知识包](sources/learn.shareai.run-zh-s05.md) — 同系列第五章，把"长期可选知识"从 system prompt 拆出来，目录常驻 + 正文按需 load_skill
- [S06 · 上下文压缩 / Context Compression](sources/learn.shareai.run-zh-s06.md) — 同系列第六章，三层压缩心智模型（持久化大输出 / micro-compact 旧结果 / summary-compact 整体历史），主循环新增“上下文预算”责任
- [S07 · 权限系统 / Permissions](sources/learn.shareai.run-zh-s07.md) — 同系列第七章，在工具意图与真实执行之间插入权限管道（deny → mode → allow → ask），支持 default / plan / auto 三种模式
- [S08 · Hook 系统 / 固定时机扩展点](sources/learn.shareai.run-zh-s08.md) — 同系列第八章，主循环暴露事件时机，附加行为通过 hook 注册，不改循环核心
- [S09 · 持久状态 / Memory](sources/learn.shareai.run-zh-s09.md) — 同系列第九章，跨会话持久记忆：4 类 memory + 存储边界 + 最小实现 + 6 条高完成度边界
- [S10 · Prompt Pipeline / 系统输入组装](sources/learn.shareai.run-zh-s10.md) — 同系列第十章，system prompt 不是硬编码文本，而是 6 段组装流水线（core + tools + skills + memory + CLAUDE.md + dynamic），稳定层与动态层分离
- [S11 · 错误恢复 / Error Recovery](sources/learn.shareai.run-zh-s11.md) — 同系列第十一章，把“报错就崩”升级为“先分类错误，再选恢复路径”：续写 / 压缩再试 / 退避重试，每条路径独立预算
- [S12 · 任务系统 / Task System](sources/learn.shareai.run-zh-s12.md) — 同系列第十二章，把 s03 的会话内 todo 升级为持久化任务图：依赖关系 + ready 判断 + 落盘存储 + 完成自动解锁
- [S13 · 后台任务 / Background Task](sources/learn.shareai.run-zh-s13.md) — 同系列第十三章，慢命令移至后台线程执行，主循环立即获得 task_id 继续推进，通知队列只带回摘要而非全文
- [S14 · 定时调度 / Scheduler](sources/learn.shareai.run-zh-s14.md) — 同系列第十四章，把未来意图记为 ScheduleRecord 并持久化，cron 匹配时把 prompt 注入通知队列，触发后不由调度器默默执行而由主循环决定
- [S15 · 多角色协作 / Teammate System](sources/learn.shareai.run-zh-s15.md) — 同系列第十五章，引入长期队友（名字+角色+邮箱+独立循环），与 subagent 一次性委派的根本区别在于生命周期
- [S16 · 协作协议 / Protocol System](sources/learn.shareai.run-zh-s16.md) — 同系列第十六章，把 shutdown/plan_approval 等关键消息从自由文本升级为带 request_id 和状态机的结构化协议
- [S17 · 自治认领 / Autonomous Agent](sources/learn.shareai.run-zh-s17.md) — 同系列第十七章，长期队友空闲时自动扫描任务板、按角色过滤并原子认领，从"被动等派活"升级为"主动接活"
- [S18 · 文件系统隔离 / Worktree](sources/learn.shareai.run-zh-s18.md) — 同系列第十八章，为每个被认领任务绑定 git worktree 执行车道，task 记录做什么，worktree 记录在哪做且互不干扰
- [S19 · 外部能力扩展 / MCP](sources/learn.shareai.run-zh-s19.md) — 同系列第十九章终章，MCP 把工具来源从本地硬编码升级为外部可插拔，plugin=发现、server=连接、tool=调用，进入后必须汇入同一条控制面

## Concepts
- [AgentLoop](concepts/AgentLoop.md) — 把"模型 + 工具"连成持续推进任务的主循环（Teaching Concept）
- [ToolRouting](concepts/ToolRouting.md) — `{tool_name: handler}` 字典分发，加工具不改循环（Teaching Concept）
- [ToolControlPlane](concepts/ToolControlPlane.md) — 工具层三维度：权限闸门 + hook 扩展点 + MCP 外部可插拔（Synthesis Concept，s02/s08/s19 合成）
- [PlanningState](concepts/PlanningState.md) — 主循环的第二块状态：会话内 todo + 单 in_progress + 失活 reminder（Teaching Concept）
- [MessageNormalization](concepts/MessageNormalization.md) — API 调用前规范化内部消息列表（Standard Concept）
- [PathSandbox](concepts/PathSandbox.md) — `safe_path()` 阻止工具逃逸 WORKDIR（Standard Concept）
- [Subagent](concepts/Subagent.md) — 局部任务的上下文边界：独立 `messages` + 工具裁剪 + 摘要回流（Teaching Concept）
- [SessionManagement](concepts/SessionManagement.md) — 1M token 上下文窗口下的 session 管理策略：context rot、compaction、rewind、/clear 决策表（Standard Concept）
- [SkillSystem](concepts/SkillSystem.md) — 长期可选知识的按需加载：system prompt 只放目录，正文通过 `load_skill` 工具注入（Teaching Concept）
- [ContextCompression](concepts/ContextCompression.md) — 三层压缩机制保住活跃上下文连续性：持久化大输出 + micro-compact 旧结果 + summary-compact 整体历史（Teaching Concept）
- [Permissions](concepts/Permissions.md) — 工具意图与真实执行之间的权限管道：deny rules → mode check → allow rules → ask user，支持 default / plan / auto 三种模式（Teaching Concept）
- [HookSystem](concepts/HookSystem.md) — 主循环暴露固定时机，附加行为通过 hook 注册实现：SessionStart / PreToolUse / PostToolUse，统一 0/1/2 返回语义（Teaching Concept）
- [Memory](concepts/Memory.md) — 跨会话持久记忆系统：4 类 memory（user/feedback/project/reference），存储边界，最小 save_memory + MEMORY.md 索引实现（Teaching Concept）
- [PromptPipeline](concepts/PromptPipeline.md) — system prompt 的 6 段组装流水线：core + tools + skills + memory + CLAUDE.md + dynamic，稳定层与动态层分离（Teaching Concept）
- [ErrorRecovery](concepts/ErrorRecovery.md) — 主循环错误恢复机制：输出截断后续写、上下文过长先压缩再试、连接抖动后退避重试，每条路径独立预算（Teaching Concept）
- [TaskSystem](concepts/TaskSystem.md) — 持久化任务图：依赖关系 + ready 判断 + 落盘存储 + 完成自动解锁（Teaching Concept）
- [BackgroundTask](concepts/BackgroundTask.md) — 后台任务系统：慢命令在后台线程跑，主循环立即继续，通知队列只带摘要回模型（Teaching Concept）
- [Scheduler](concepts/Scheduler.md) — 定时调度系统：cron 表达式触发时把 prompt 注入通知队列，由主循环决定处理方式（Teaching Concept）
- [Teammate](concepts/Teammate.md) — 长期队友系统：名册+邮箱+独立循环，与 subagent 的根本区别在生命周期而非名字（Teaching Concept）
- [Protocol](concepts/Protocol.md) — 协作协议系统：结构化请求+request_id+状态机，解决"这件事走到哪一步"而非"说了什么"（Teaching Concept）
- [AutonomousAgent](concepts/AutonomousAgent.md) — 自治认领系统：空闲队友按规则扫描任务板、原子认领、重注入身份上下文（Teaching Concept）
- [Worktree](concepts/Worktree.md) — 文件系统隔离：task 记录做什么，worktree 记录在哪做且互不干扰，task_status 和 worktree_state 分开维护（Teaching Concept）
- [MCP](concepts/MCP.md) — 外部能力扩展：把外部工具通过 MCP 协议接进 agent，plugin=发现、server=连接、tool=调用，必须汇入同一控制面（Teaching Concept）
- [ArchitectureOverview](concepts/ArchitectureOverview.md) — 全课程鸟瞰地图：四阶段学习路径、关键状态分类、系统大图、设计原则（Standard Concept，s00 配套）
- [QueryControlPlane](concepts/QueryControlPlane.md) — 显式 query 控制平面：QueryParams/QueryState/TransitionReason 三层结构，跨轮共享状态管理（Standard Concept，s00a 配套）
- [OneRequestLifecycle](concepts/OneRequestLifecycle.md) — 单次请求完整生命周期纵向流程图：9 段模块依次介入，tool_result→messages 唯一闭环（Standard Concept，s00b 配套）
- [QueryTransitionModel](concepts/QueryTransitionModel.md) — 6 种 transition reason 分类体系：tool_result/max_tokens/compact/transport/stop_hook/budget continuation（Standard Concept，s00c 配套）
- [ChapterOrderRationale](concepts/ChapterOrderRationale.md) — 章节顺序按依赖关系排的设计原理，五种错误重排警告（Standard Concept，s00d 配套）
- [ReferenceModuleMap](concepts/ReferenceModuleMap.md) — 参考仓库模块簇与课程章节一一对齐，验证教学顺序合理性（Standard Concept，s00e 配套）
- [CodeReadingOrder](concepts/CodeReadingOrder.md) — 四阶段读代码指南："状态→工具→主推进函数→CLI 入口"模板（Standard Concept，s00f 配套）
- [TeachingScope](concepts/TeachingScope.md) — 教学边界声明：追求什么分数、哪些必须讲、哪些不占主线（Standard Concept，teaching-scope 配套）
- [Glossary](concepts/Glossary.md) — 全课程 30+ 核心术语统一边界说明，最易混淆词对照表（Standard Concept，glossary 配套）
- [DataStructures](concepts/DataStructures.md) — 全系统关键数据结构按五层分类：查询控制/工具权限/持久工作/运行时执行/外部平台（Standard Concept，data-structures 配套）
- [EntityMap](concepts/EntityMap.md) — 全系统实体按五层分层（对话/动作/工作/执行/平台），8 对最易混淆概念对照（Standard Concept，entity-map 配套）
- [ToolExecutionRuntime](concepts/ToolExecutionRuntime.md) — 工具执行运行时：并发分批/串行并行/进度消息/结果稳定顺序/ContextModifier 合并（Standard Concept，s02b 配套）
- [MCPCapabilityLayers](concepts/MCPCapabilityLayers.md) — MCP 6 层能力地图：Config/Transport/ConnectionState/Capability/Auth/Router Integration（Standard Concept，s19a 配套）
- [TeamTaskLaneModel](concepts/TeamTaskLaneModel.md) — teammate/protocol/task/runtime task/worktree 五层边界，完整连接链与典型混淆例子（Standard Concept，team-task-lane-model 配套）

## Syntheses
（暂无）

## Entities
- [Anthropic](entities/Anthropic.md) — 开发 Claude 模型和 Claude Code 的 AI 公司
- [Claude Code](entities/ClaudeCode.md) — Anthropic 开发的 AI 编程工具

## External Sources (claude.com blog)
- [Using Claude Code: Session Management and 1M Context](sources/claude.com-blog-using-claude-code-session-management-and-1m-context.md) — 1M token 上下文窗口下的 session 管理策略：context rot、compaction、rewind、/clear 决策表
- [Subagents in Claude Code](sources/claude.com-blog-subagents-in-claude-code.md) — subagent 完整使用指南：何时用、5 种调用方式（conversational / custom / CLAUDE.md / skills / hooks）、实战模式

## Reference / Bridge Documents (s00 Series)
- [S00 · 架构总览](sources/learn.shareai.run-zh-s00-architecture-overview.md) — 全课程鸟瞰地图：四阶段学习路径 + 关键状态分类总表
- [S00a · Query 控制平面](sources/learn.shareai.run-zh-s00a-query-control-plane.md) — 为什么完整系统不能只靠 `messages[] + while True`，需要显式 QueryState + TransitionReason
- [S00b · 单次请求生命周期](sources/learn.shareai.run-zh-s00b-one-request-lifecycle.md) — 请求纵向流程图：QueryState→组装→模型→工具路由→权限→Hook→执行→结果写回
- [S00c · Query 转移模型](sources/learn.shareai.run-zh-s00c-query-transition-model.md) — 6 种 transition reason 分类体系：tool_result/max_tokens/compact/transport/stop_hook/budget continuation
- [S00d · 章节顺序设计原理](sources/learn.shareai.run-zh-s00d-chapter-order-rationale.md) — 为什么 s01→s19 顺序按依赖关系排而非源码顺序，五种错误重排警告
- [S00e · 参考仓库模块对照](sources/learn.shareai.run-zh-s00e-reference-module-map.md) — 参考仓库重要模块簇与课程章节一一对齐
- [S00f · 代码阅读顺序](sources/learn.shareai.run-zh-s00f-code-reading-order.md) — 四阶段读代码指南 + "状态→工具→主推进函数→CLI 入口"模板
- [教学边界声明](sources/learn.shareai.run-zh-teaching-scope.md) — 追求什么分数/哪些必须讲/哪些不占主线/维护者检查清单
- [术语表](sources/learn.shareai.run-zh-glossary.md) — 全课程 30+ 核心术语统一边界 + 6 对最易混淆词对照
- [数据结构总表](sources/learn.shareai.run-zh-data-structures.md) — 全系统关键数据结构按五层分类（查询控制/工具权限/持久工作/运行时执行/外部平台）
- [实体分层地图](sources/learn.shareai.run-zh-entity-map.md) — 全系统实体按对话/动作/工作/执行/平台五层分层 + 8 对最易混淆概念对照
- [S02a · 工具控制平面详解](sources/learn.shareai.run-zh-s02a-tool-control-plane.md) — ToolUseContext 总线作为核心升级，从 dispatch map 到统一控制面
- [S02b · 工具执行运行时](sources/learn.shareai.run-zh-s02b-tool-execution-runtime.md) — 并发分批/串并行/进度消息/结果顺序/ContextModifier 合并
- [S10a · 消息与 Prompt 管道](sources/learn.shareai.run-zh-s10a-message-prompt-pipeline.md) — prompt blocks + normalized messages + attachments + reminders 完整输入管道
- [S13a · 运行时任务模型](sources/learn.shareai.run-zh-s13a-runtime-task-model.md) — 工作图任务 vs 运行时任务的五层边界澄清
- [团队-任务-车道模型](sources/learn.shareai.run-zh-team-task-lane-model.md) — teammate/protocol/task/runtime task/worktree 五层边界澄清
- [S19a · MCP 能力层地图](sources/learn.shareai.run-zh-s19a-mcp-capability-layers.md) — MCP 6 层能力地图：Config/Transport/ConnectionState/Capability/Auth/Router
