---
title: "S19 · 外部能力扩展 / MCP"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s19.md
---

## Summary
s19 是系列终章，引入 MCP（Model Context Protocol）把"工具来源"从本地硬编码升级为外部可插拔。核心心智：外部工具也能像本地工具一样接进 agent——一样注册、一样出现在工具池、一样过权限、一样返回 tool_result，最终汇入同一条控制面和执行面。Plugin 负责发现，Server 负责连接，Tool 负责调用，三层不要混。

## Key Claims
- MCP 是"让外部程序把工具接进来而不用改主程序"的统一协议
- MCP 工具必须走同一条权限管道，不能绕开 permission
- 进入方式不同，但进入后必须回到同一条控制面和执行面
- plugin / MCP server / MCP tool 是三层：发现 / 连接 / 调用，不要混

## Key Quotes
> "MCP 不是外挂，而是接回同一控制面的外部能力入口。"
> "进入方式不同，但进入后必须回到同一条控制面和执行面。"
> "plugin 负责发现，server 负责连接，tool 负责调用。"

## Key Data Structures
- **MCPClient**: `connect() / list_tools() / call_tool()`
- **Tool name prefix**: `mcp__{server}__{tool}`（避免命名冲突）
- **Server config**: `command / args / env`
- **Plugin manifest**: `.claude-plugin/plugin.json` → name / version / mcpServers

## Connections
- 继承自 [[ToolRouting]]（s02）— 把工具来源从本地 handler 扩展到外部 MCP server
- 继承自 [[Permissions]]（s07）— MCP 工具仍必须走权限管道
- 继承自 [[Worktree]]（s18）— 完成"把系统内部搭起来"，s19 教"如何把系统向外打开"
- resolves s02 的 forward-ref: "工具层最终会成长为控制平面"（含 MCP / 缓存 / 通知 / app state）
