---
title: "MCPServerConnectionState"
type: concept
tags: [reference, mcp, platform-architecture]
sources: [learn.shareai.run-zh-s19a-mcp-capability-layers]
last_updated: 2026-05-08
---

## Definition
MCP server 的连接状态枚举值，反映 MCP Connection State Layer 的当前阶段。

## Key Claims
- Connection State Layer 是 Transport Layer 和 Capability Layer 之间的桥梁
- 连接状态决定上层能力（tools/resources/prompts/elicitation）是否可用
- 六种状态：connected / pending / failed / needs-auth / disabled

## States

| State | Meaning |
|-------|---------|
| `connected` | transport 已建立，capability 可用 |
| `pending` | 连接进行中，能力尚未暴露 |
| `failed` | 连接失败，能力不可用 |
| `needs-auth` | 需要额外认证才能使用 |
| `disabled` | 用户主动禁用该 server |

## Connections
- [[MCPCapabilityLayers]] — Connection State Layer 的状态值
- [[MCPToolSpec]] — 连接状态决定 tool spec 是否可用
- [[MCP]] — MCP 是平台层
