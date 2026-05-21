---
title: "DataStructures"
type: concept
tags: [reference, data-structures, state-management]
sources: [learn.shareai.run-zh-data-structures]
last_updated: 2026-05-08
---

## Definition
全系统关键数据结构按五层分类集中呈现：查询与对话控制状态 / 工具与权限状态 / 持久化工作状态 / 运行时执行状态 / 外部平台与 MCP 状态。

## Two Organizing Principles
1. **区分"内容状态"和"流程状态"**：`messages` 是内容，`turn_count/transition` 是流程
2. **区分"持久状态"和"运行时状态"**：task 落盘跨会话，runtime task 只在系统运行时活着

## Five-Layer Taxonomy
### Layer 1: 查询与对话控制
| Structure | Role |
|-----------|------|
| Message | 当前对话历史 |
| NormalizedMessage | 准备发给模型 API 的统一格式 |
| CompactSummary | 上下文太长时压缩的摘要 |
| SystemPromptBlock | system prompt 内部的结构化片段 |
| PromptParts | system prompt 组装前的各部分拆分 |
| QueryParams | query 入口时的外部输入 |
| QueryState | 跨轮迭代真正变化的状态 |
| TransitionReason | 上一轮为什么继续 |

### Layer 2: 工具与权限
| Structure | Role |
|-----------|------|
| ToolSpec | 工具的名字/描述/输入 schema |
| ToolDispatchMap | 工具名到 handler 的映射 |
| ToolUseContext | 工具运行时的共享环境总线 |
| PermissionRule | 工具调用的权限决策规则 |
| PermissionDecision | 一次工具调用的允许/拒绝/询问决策 |
| HookContext | hook 事件发生时的上下文 |
| RecoveryState | 恢复流程已尝试到哪里的记录 |

### Layer 3: 持久化工作
| Structure | Role |
|-----------|------|
| TodoItem | 会话内轻量计划项 |
| MemoryEntry | 跨会话有价值的信息 |
| TaskRecord | 磁盘上的工作图任务节点 |
| ScheduleRecord | 未来要触发的调度任务 |

### Layer 4: 运行时执行
| Structure | Role |
|-----------|------|
| RuntimeTaskState | 正在运行的执行单元槽位 |
| TeamMember | 持久队友记录 |
| MessageEnvelope | 队友间结构化消息 |
| RequestRecord | 协议请求追踪记录 |
| WorktreeRecord | 任务绑定的隔离工作目录 |

### Layer 5: 外部平台与 MCP
| Structure | Role |
|-----------|------|
| ScopedMcpServerConfig | MCP server 配置（带 scope） |
| MCPServerConnectionState | server 当前连接状态 |
| MCPToolSpec | MCP 工具的内部统一定义 |
| ElicitationRequest | server 向用户请求额外输入 |

## Connections
- [[QueryControlPlane]] — QueryParams/QueryState/TransitionReason 是控制平面核心结构
- [[ToolControlPlane]] — ToolUseContext/ToolSpec/ToolDispatchMap 是工具控制平面核心结构
- [[TaskSystem]] — TaskRecord 是 s12 核心结构
- [[MCPCapabilityLayers]] — ScopedMcpServerConfig/MCPServerConnectionState/MCPToolSpec 是 MCP 能力层结构
