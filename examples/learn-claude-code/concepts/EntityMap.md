---
title: "EntityMap"
type: concept
tags: [reference, system-architecture, entity-boundaries]
sources: [learn.shareai.run-zh-entity-map]
last_updated: 2026-05-08
---

## Definition
全系统实体按五层分层（对话层/动作层/工作层/执行层/平台层），给出 8 对最易混淆概念对照和"是什么/存在哪里"速查表。

## Five-Layer Architecture
```
对话层
  - message
  - prompt block
  - reminder

动作层
  - tool call
  - tool result
  - hook event

工作层
  - work-graph task
  - runtime task
  - protocol request

执行层
  - subagent
  - teammate
  - worktree lane

平台层
  - mcp server
  - mcp capability
  - memory record
```

## Most Confusable Pairs
| 实体对 | 区分方法 |
|--------|--------|
| message vs prompt block | 对话内容 vs 系统说明 |
| todo vs task | 会话内临时步骤 vs 持久化工作节点 |
| work-graph task vs runtime task | 工作目标 vs 正在跑的进程 |
| subagent vs teammate | 一次性 vs 长期存在 |
| protocol request vs normal message | 可追踪的审批流程 vs 自由文本沟通 |
| worktree vs task | 在哪做 vs 做什么 |
| memory vs CLAUDE.md | 跨会话有价值信息 vs 长期规则 |
| MCP server vs MCP tool | 外部能力提供者 vs 具体工具定义 |

## Connections
- [[Glossary]] — entity-map 回答"词属于哪层"，glossary 回答"词是什么意思"
- [[DataStructures]] — entity-map 回答"词属于哪层"，data-structures 回答"词落到代码里状态长什么样"
- [[RuntimeTaskModel]] — 专门补"工作图任务"和"运行时任务"的分层
- [[MCPCapabilityLayers]] — 专门补 MCP server 和 MCP tool 的层级区别
