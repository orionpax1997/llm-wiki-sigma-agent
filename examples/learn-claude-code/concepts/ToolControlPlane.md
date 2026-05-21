---
title: "ToolControlPlane"
type: concept
tags: [curriculum, tool-layer, system-architecture, synthesis]
sources: [learn.shareai.run-zh-s02, learn.shareai.run-zh-s02a, learn.shareai.run-zh-s08, learn.shareai.run-zh-s19]
last_updated: 2026-05-08
---

## Expanded by S02a: ToolUseContext as the Core Upgrade
[[learn.shareai.run-zh-s02a-tool-control-plane|S02a]] adds the critical upgrade from dispatch map to **ToolUseContext** — the shared execution context bus passed to all tool handlers:
- `tools` — handler dispatch map
- `permission_context` — current permission mode and decisions
- `mcp_clients` — active MCP server connections
- `messages` — current message history
- `app_state` — shared application state
- `notifications` — outbound notification queue
- `cwd` — current working directory

The key insight: **more complete systems don't just have a tool table; they have a ToolUseContext bus.** All tool handlers receive this context explicitly rather than grabbing from global state.
---

## Core Thesis
> 工具层不只是"把工具列表传给模型"，而是一个需要权限、扩展点、和外部可插拔能力的完整控制平面。

## Problem Definition
s02 introduced the dispatch map as the minimal tool routing model. As the system grows, the tool layer accumulates responsibilities beyond routing:
- **Security** — should every tool call execute? Who decides?
- **Extensibility** — how do new behaviors attach to existing tool calls without modifying the loop?
- **Plugability** — how do tools discovered at runtime (MCP servers) integrate into the same control surface?

These three concerns are dimensions of a single concept: the **Tool Control Plane**.

- **学完前**：Adding a new tool means editing the dispatch map; security checks live in the handler; external tools are ad-hoc integrations.
- **学完后**：You understand the tool layer as a plane with three orthogonal dimensions — [[Permissions]] (security gate), [[HookSystem]] (extension points), and [[MCP]] (external pluggability) — all feeding into the same dispatch model from s02.

## Terminology
| Term | Definition |
|------|------------|
| ToolControlPlane | The tool layer's three-dimension structure: permission gate, hook extension, external pluggability |
| Permission Gate | [[Permissions]] — pre-execution security check before any tool runs |
| Extension Point | [[HookSystem]] — `PreToolUse` / `PostToolUse` hooks for injecting side behaviors |
| External Pluggability | [[MCP]] — external servers discovered via plugin, connected via server, called via tool |

## Mental Model
```
         ┌─ PreToolUse hook (HookSystem)
         │
         ▼
  Tool intent from model
         │
         ▼
  ┌──────────────┐
  │ Permissions  │  ← deny rules → mode check → allow rules → ask
  └──────────────┘
         │
         ▼
  Dispatch (ToolRouting)
         │
         ├─ local tool ──→ execute
         │
         └─ MCP tool  ──→ MCPClient → external server
         │
         ▼
  ┌──────────────┐
  │PostToolUse hook│
  └──────────────┘
```

## Three Dimensions

### 1. Permission Gate ([[Permissions]])
Every tool intent must pass through the permission pipe before execution. Modes: `default`, `plan`, `auto`. The key invariant: **no tool executes without passing through this gate**.

### 2. Extension Points ([[HookSystem]])
Fixed timing hooks (`SessionStart`, `PreToolUse`, `PostToolUse`) allow behaviors to attach without modifying the dispatch map. The loop exposes timing; hooks provide behavior.

### 3. External Pluggability ([[MCP]])
External tools are not hardcoded. A plugin discovers servers, a server establishes the connection, and tools are called through the same dispatch interface — **entering differently, but converging on the same control plane**.

## System Position
- **Inherits from**: [[ToolRouting]] (the dispatch map is the foundation)
- **Cross-links**: [[Permissions]] (security gate), [[HookSystem]] (extension points), [[MCP]] (external pluggability)
- **Series closure**: s19 (MCP) closes the control plane arc opened in s02

## Connections
- [[ToolRouting]] — ToolControlPlane is the mature form of the dispatch map introduced in s02
- [[Permissions]] — the security gate dimension of the control plane
- [[HookSystem]] — the extension point dimension of the control plane
- [[MCP]] — the external pluggability dimension of the control plane
- [[AgentLoop]] — the control plane sits inside the agent loop as the tool layer's structural maturity
