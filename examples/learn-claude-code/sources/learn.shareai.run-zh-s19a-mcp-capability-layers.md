---
title: "S19a · MCP 能力层地图"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s19a-mcp-capability-layers.md
---

## Summary
在 s19 tools-first 主线基础上补清 MCP 平台层完整能力地图：Config Layer（server 配置）→ Transport Layer（stdio/http/sse/ws 连接通道）→ Connection State Layer（connected/pending/failed/needs-auth/disabled）→ Capability Layer（tools/resources/prompts/elicitation）→ Auth Layer → Router Integration Layer，并说明正文坚持 tools-first 是教学取舍、auth layer 不在主线里展开的原因。

## Key Claims
- tools 只是 Capability Layer 中的一层，不是全部（还有 resources/prompts/elicitation）
- elicitation 是外部 server 反过来向用户请求额外输入的能力，不只是 agent 主动调工具
- MCP 是外部能力平台，tools 只是它最先进入主线的那个切面
- Server 配置/连接状态/能力暴露三层不能混，否则平台层越学越乱
- 认证层虽然真实存在，但初学时不宜深入，应遵循"先做出类似系统，再补平台层高级能力"

## Key Quotes
> "MCP 是外部能力平台，而 tools 只是它最先进入主线的那个切面。" — s19a

## Connections
- [[MCP]] — s19 讲 tools-first 主线，s19a 补平台层完整能力地图
- [[ToolControlPlane]] — s02a ToolControlPlane 解释 MCP 如何接回统一工具总线
- [[MCPToolSpec]] — tools 在 MCP 层的数据结构
- [[MCPServerConnectionState]] — 连接状态的多种值

## Contradictions
（无）
