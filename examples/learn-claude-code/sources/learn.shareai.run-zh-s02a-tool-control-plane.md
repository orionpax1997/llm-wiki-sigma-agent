---
title: "S02a · 工具控制平面详解"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s02a-tool-control-plane.md
---

## Summary
在 s02 dispatch map 基础上解释为什么工具层会成长为一个控制平面：ToolUseContext（工具运行时能访问的共享环境总线）作为核心升级点，tool call 进入统一调度入口、handler 不偷拿环境而是共享显式 context、本地工具/MCP 工具/平台工具来源不同但结果都回统一 ToolResultEnvelope。

## Key Claims
- 工具层不只是 `{tool_name: handler}` 字典，而是模型通过工具名发出动作意图后、系统决定这条意图在什么环境里执行的控制总线
- ToolUseContext 是核心升级：工具不再只拿到输入参数，还能拿到共享运行环境（permissions/messages/app_state/notifications/mcp_clients）
- 更完整系统的关键不是 tool table 而是 ToolUseContext
- 本地工具、插件工具、MCP 工具可以来源不同，但结果都应该回到统一控制面

## Key Quotes
> "最小工具系统靠 dispatch map，更完整的工具系统靠 ToolUseContext 这条控制总线。" — s02a

## Connections
- [[ToolRouting]] — s02 建立 dispatch map，s02a 解释为什么完整系统需要从 dispatch map 升级到 ToolUseContext 总线
- [[ToolExecutionRuntime]] — s02b 继续深入工具执行时的并发/串行/进度消息/结果顺序/ContextModifier 合并
- [[MCP]] — s19 把 MCP 作为外部能力来源接入 Tool Control Plane

## Contradictions
（无）
