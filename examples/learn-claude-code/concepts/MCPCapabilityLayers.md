---
title: "MCPCapabilityLayers"
type: concept
tags: [reference, mcp, platform-architecture]
sources: [learn.shareai.run-zh-s19a-mcp-capability-layers]
last_updated: 2026-05-08
---

## Definition
MCP 平台层完整能力地图：Config Layer → Transport Layer → Connection State Layer → Capability Layer → Auth Layer → Router Integration Layer。tools 只是 Capability Layer 中的一层，不是全部。

## Six-Layer Architecture
```
1. Config Layer — server 配置长什么样（name/type/command/args/scope）
2. Transport Layer — 连接通道（stdio/http/sse/websocket）
3. Connection State Layer — connected/pending/failed/needs-auth/disabled
4. Capability Layer — tools / resources / prompts / elicitation
5. Auth Layer — 认证状态
6. Router Integration Layer — 接回 tool router / permission / notifications
```

## Key Claims
- tools 只是 Capability Layer 中的一层，resources/prompts/elicitation 同样属于 MCP 能力
- elicitation 是外部 server 反过来向用户请求额外输入，不是 agent 主动调工具
- MCP 是外部能力平台，tools 只是它最先进入主线的那个切面
- Server 配置/连接状态/能力暴露三层不能混

## Why Auth Layer Is Not in Main Text
认证层虽然真实存在，但初学时不宜深入——应遵循"先做出类似系统，再补平台层高级能力"。主线保持 tools-first 入口是正确的教学取舍。

## Connections
- [[MCP]] — s19 讲 tools-first 主线，s19a 补平台层完整能力地图
- [[ToolControlPlane]] — s02a ToolControlPlane 解释 MCP 如何接回统一工具总线
- [[MCPServerConnectionState]] — connection state 的多种值
- [[MCPToolSpec]] — tools 在 MCP 层的数据结构
