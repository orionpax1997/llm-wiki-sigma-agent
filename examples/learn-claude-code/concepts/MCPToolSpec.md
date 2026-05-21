---
title: "MCPToolSpec"
type: concept
tags: [reference, mcp, platform-architecture]
sources: [learn.shareai.run-zh-s19a-mcp-capability-layers]
last_updated: 2026-05-08
---

## Definition
MCP 协议中工具（tool）在 Capability Layer 的具体数据结构定义。

## Key Claims
- tool 是 MCP Capability Layer 的一个子类型，不是唯一类型
- MCP tool spec 包含 name、description、input_schema 等标准字段
- tool 规格由 MCP 外部 server 定义，agent 只是消费者

## Connections
- [[MCPCapabilityLayers]] — tool 是 Capability Layer 的一种
- [[MCP]] — MCP 是接工具进 agent 的外部平台
- [[MCPServerConnectionState]] — server 连接状态决定 tool 是否可用
