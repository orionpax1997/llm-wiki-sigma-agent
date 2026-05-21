---
title: "实体分层地图"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-entity-map.md
---

## Summary
按对象和模块关系对全系统实体分层：对话层（message/prompt block/reminder）、动作层（tool call/tool result/hook event）、工作层（work-graph task/runtime task/protocol request）、执行层（subagent/teammate/worktree lane）、平台层（mcp server/mcp capability/memory record），给出 8 对最易混淆概念对照表和"是什么/存在哪里"速查表。

## Key Claims
- 最常见的心智打结是把"任务"这个词用在所有层——建议直接写全"工作图任务"或"运行时任务"
- message/prompt block 不是一类：message 更像对话内容，prompt block 更像系统说明
- work-graph task 和 runtime task 是后半程最关键区分之一
- MCP server 和 MCP tool 不是一类：server 是外部能力提供者，tool 是某个 server 暴露出来的具体能力
- 实体边界一清楚，很多复杂度会自动塌下来

## Key Quotes
> "一个结构完整的系统最怕的不是功能多，而是实体边界不清；边界一清，很多复杂度会自动塌下来。" — entity-map

## Connections
- [[Glossary]] — entity-map 回答"词属于哪一层"，glossary 回答"词是什么意思"
- [[DataStructures]] — entity-map 回答"词属于哪层"，data-structures 回答"词落到代码里状态长什么样"
- [[RuntimeTaskModel]] — 专门补"工作图任务"和"运行时任务"的分层
- [[MCPCapabilityLayers]] — 专门补 MCP server 和 MCP tool 的层级区别

## Contradictions
（无）
