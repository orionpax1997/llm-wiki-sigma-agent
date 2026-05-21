---
title: "术语表"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-glossary.md
---

## Summary
全课程统一名词边界说明，涵盖 agent/harness/tool/dispatch map/context/compact/subagent/permission/hook/memory/task/dependency graph/worktree/MCP/runtime task/teammate/protocol/envelope/state machine/router/control plane/capability/resource/elicitation 等核心术语，并给出最容易混的 6 对词对照表。

## Key Claims
- dispatch map 是 `{tool_name: handler}` 映射表，模型说要调工具时代码去表里找对应函数
- subagent 是一次性委派，teammate 是长期存在可重复接活的队友，两者不是同一类实体
- task 是工作目标，runtime task 是正在运行的执行槽位，两者最容易被后半程读者混掉
- worktree 是 git 提供的机制（同一仓库多目录工作副本），用于并行工作时互不踩目录
- capability 在 MCP 语境下比 tool 更宽，包括 tools/resources/prompts/elicitation

## Key Quotes
> "如果读文档时又遇到新词卡住，优先回这里，不要硬顶着往后读。" — glossary

## Connections
- [[EntityMap]] — glossary 回答"词是什么意思"，entity-map 回答"词属于哪一层"，data-structures 回答"词落到代码里状态长什么样"
- [[ToolRouting]] — dispatch map 是 ToolRouting 的核心数据结构

## Contradictions
（无）
