---
title: "数据结构总表"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-data-structures.md
---

## Summary
把整个系统最关键的数据结构按五层分类集中呈现：查询与对话控制状态（Message/NormalizedMessage/CompactSummary/SystemPromptBlock/PromptParts/QueryParams/QueryState/TransitionReason）、工具与权限状态（ToolSpec/ToolDispatchMap/ToolUseContext/PermissionRule/PermissionDecision/HookContext/RecoveryState）、持久化工作状态（TodoItem/MemoryEntry/TaskRecord/ScheduleRecord）、运行时执行状态（RuntimeTaskState/TeamMember/MessageEnvelope/RequestRecord/WorktreeRecord/WorktreeEvent）、外部平台与 MCP 状态（ScopedMcpServerConfig/MCPServerConnectionState/MCPToolSpec/ElicitationRequest）。

## Key Claims
- 两原则：区分"内容状态"和"流程状态"（messages 是内容，turn_count 是流程）；区分"持久状态"和"运行时状态"（task 落盘，runtime task 只在运行时活着）
- QueryState 是跨迭代真正变化的部分，包括 messages/turn_count/transition/continuation_count/has_attempted_compact 等
- RuntimeTaskState 和 TaskRecord 不是一回事：TaskRecord 管工作目标，RuntimeTaskState 管当前执行槽位
- MCPServerConnectionState 不是布尔值，而是多种状态：connected/pending/failed/needs-auth/disabled

## Key Quotes
> "messages / prompt / query state 管本轮输入和继续理由；tools / permissions / hooks 管动作怎么安全执行；memory / task / schedule 管跨轮、跨会话的持久工作；runtime task / team / worktree 管当前执行车道；mcp 管系统怎样向外接能力。" — data-structures

## Connections
- [[QueryControlPlane]] — QueryParams/QueryState/TransitionReason 是控制平面的核心数据结构
- [[ToolControlPlane]] — ToolUseContext/ToolSpec/ToolDispatchMap 是工具控制平面的核心数据结构
- [[TaskSystem]] — TaskRecord 是 s12 的核心结构
- [[MCPCapabilityLayers]] — ScopedMcpServerConfig/MCPServerConnectionState/MCPToolSpec 是 MCP 能力层数据结构

## Contradictions
（无）
