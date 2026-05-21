---
title: "MCP"
type: concept
tags: [curriculum, agent-kernel]
sources: [learn.shareai.run-zh-s19]
last_updated: 2026-05-08
---

## Core Thesis
> MCP 不是"远程 tools"，而是一套让外部程序把工具接进 agent 的统一协议——外部工具进入后必须和本地工具一样：注册进工具池、过权限管道、返回标准化 tool_result，最终汇入同一条控制面和执行面。

## Problem Definition
**之前的问题**：所有工具都写在本地的 Python 代码里，添加或更换工具需要修改主程序，无法让外部程序动态接入。

**之后的改进**：通过 MCPClient 连接外部 MCP server → list_tools 标准化名字加前缀 → 和本地工具一起进工具池 → 统一路由和权限 → 标准化结果回流主循环。

## Terminology
| Term | Definition |
|------|------------|
| MCP | Model Context Protocol，让 agent 和外部工具程序对话的统一协议 |
| MCP client | 负责启动外部进程、发送请求、接收响应的连接对象 |
| MCP server | 外部进程，对外暴露一组工具能力 |
| MCP tool | server 暴露的一项具体调用能力 |
| plugin manifest | `.claude-plugin/plugin.json`，告诉系统发现和启动哪些 server |

## Three-Layer Distinction
| 层级 | 它是什么 | 它负责什么 |
|---|---|---|
| plugin manifest | 配置声明 | 发现和启动哪些 server |
| MCP server | 外部进程 / 连接对象 | 对外暴露一组能力 |
| MCP tool | server 暴露的一项具体调用 | 真正被模型点名调用 |

**plugin = 发现，server = 连接，tool = 调用。**

## Mental Model
```
启动时
  PluginLoader 找到 manifest
    -> 得到 server 配置
    -> MCP client 连接 server
    -> list_tools 并标准化名字（加 mcp__ 前缀）
    -> 和 native tools 合并进同一个工具池

运行时
  LLM 产出 tool_use
    -> 统一权限闸门
    -> native route 或 mcp route
    -> 结果标准化
    -> tool_result 回到同一条主循环
```

## Minimal Implementation
```python
# 1. MCPClient
class MCPClient:
    def connect(self, config): ...
    def list_tools(self): ...
    def call_tool(self, name, args): ...

# 2. 统一路由器
if tool_name.startswith("mcp__"):
    return mcp_router.call(tool_name, arguments)
else:
    return native_handler(arguments)

# 3. 标准化结果
{
    "source": "mcp",
    "server": "postgres",
    "tool": "query",
    "status": "ok",
    "preview": "...",
}
```

## System Position
- Inherits from: [[ToolRouting]]（s02 把工具来源从本地 handler 扩展到外部 MCP server）
- Inherits from: [[Permissions]]（s07 MCP 工具仍必须走权限管道，不开安全后门）
- Cross-links: [[AgentLoop]]（MCP 是 agent 扩展到外部能力的最终形态）
- resolves: s02 forward-ref "工具层最终会成长为控制平面"（含 MCP / 缓存 / 通知 / app state 注入）

## Common Errors
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把 MCP 当成"远程 tools" | 以为它是一套完全不同的工具系统 | "MCP 工具进入后，要过权限吗？" → 不过就是错 |
| 忽略命名与路由前缀 | 多个 server 有同名工具时冲突 | "mcp__postgres__query 和 mcp__mysql__query 是同一个工具吗？" → 分不清就是错 |
| 把 plugin / server / tool 混成一层 | 不知道配置该写在哪里 | "server 启动命令应该写在哪里？" → plugin manifest 里答不清就是错 |
| MCP 工具绕开 permission | 在系统边上开了安全后门 | "MCP 工具调用是否仍需权限判断？" → 不需要就是错 |

## Memory Mnemonic
"MCP = 把外部工具安全、统一地接进 agent" — plugin=发现，server=连接，tool=调用，进入后汇入同一控制面。

## Navigation
- Previous: [[Worktree]]
