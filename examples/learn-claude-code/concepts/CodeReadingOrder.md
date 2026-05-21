---
title: "CodeReadingOrder"
type: concept
tags: [reference, code-reading, developer-guide]
sources: [learn.shareai.run-zh-s00f-code-reading-order]
last_updated: 2026-05-08
---

## Definition
四阶段读代码指南：文档顺着章节读，代码也顺着章节读，每章按"状态结构→工具列表→主推进函数→CLI 入口"模板操作。

## Connections
- [[ReferenceModuleMap]] — 源码模块对照表，配合读代码顺序使用

## Key Claims
- 读代码前先读文档，文档顺着章节读，代码也顺着章节读
- 每个 agent 文件都先按"状态结构/管理器类→工具列表/注册表→主推进函数→CLI 入口"模板
- 四阶段读法：s01-s06 核心骨架 / s07-s11 控制面 / s12-s14 任务系统 / s15-s19 平台边界
- 最稳学习动作：读文档→读代码→跑 demo→从空目录重写最小版本

## Per-Chapter Code Reading Guide
| 阶段 | 章节 | 先看什么 | 再看什么 | 读完要确认 |
|------|------|----------|----------|-----------|
| 阶段 1 | s01 | LoopState | TOOLS→execute_tool_calls→run_one_turn→agent_loop | messages→model→tool_result→next turn |
| 阶段 1 | s02 | safe_path() | run_read/write/edit→TOOL_HANDLERS→agent_loop | 主循环不变，工具靠分发面增长 |
| 阶段 1 | s06 | CompactState | persist_large_output→micro_compact→compact_history→agent_loop | 压缩是转移细节，不是删历史 |
| 阶段 2 | s11 | estimate_tokens/auto_compact/backoff_delay | 各恢复分支→agent_loop | 恢复以后怎样继续下一轮 |
| 阶段 3 | s12 | TaskManager | 任务创建/依赖/解锁→agent_loop | task 是持久工作图，不是 todo |
| 阶段 4 | s19 | CapabilityPermissionGate/MCPClient/MCPToolRouter | build_tool_pool→handle_tool_call→normalize_tool_result→agent_loop | 外部能力如何接回同一控制面 |

## Connections
- [[ArchitectureOverview]] — s00f 提供代码层面的具体读法，配合课程总览使用
- [[TaskSystem]] — s12 代码读法：先看 TaskManager
