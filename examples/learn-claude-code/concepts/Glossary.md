---
title: "Glossary"
type: concept
tags: [reference, terminology, nomenclature]
sources: [learn.shareai.run-zh-glossary]
last_updated: 2026-05-08
---

## Definition
全课程 30+ 核心术语的统一边界说明，避免不同章节里同一名词指代不同概念。

## Key Terminology
| Term | Definition |
|------|------------|
| dispatch map | `{tool_name: handler}` 映射表，模型说要调工具时代码去表里找对应函数 |
| subagent | 一次性委派的子任务执行者，干完就结束 |
| teammate | 长期存在、可重复接活的队友，与 subagent 的根本区别在生命周期 |
| task | 持久化的工作目标节点，带状态/描述/依赖/owner |
| runtime task | 系统当前正在运行的执行单元（后台 pytest/正在工作的 teammate/正在运行的 monitor） |
| worktree | git 提供的机制，同一仓库多目录工作副本，用于并行工作时互不踩目录 |
| capability | 在 MCP 语境下比 tool 更宽，包括 tools/resources/prompts/elicitation |
| elicitation | 外部 server 反过来向用户请求额外输入的能力 |
| state machine | 一张"状态可以怎么变化"的规则表 |
| control plane | 不直接干活，负责协调怎么干活的一层 |

## Most Confusable Pairs
| 词对 | 最简单区分方法 |
|------|---------------|
| subagent vs teammate | 一次性 vs 长期存在 |
| task vs runtime task | 工作目标 vs 正在跑的进程 |
| worktree vs task | 在哪做 vs 做什么 |
| tool vs resource | 动作 vs 内容 |
| permission vs hook | 能不能做 vs 要不要额外插入行为 |

## Connections
- [[EntityMap]] — glossary 回答"词是什么意思"，entity-map 回答"词属于哪一层"
- [[DataStructures]] — glossary 给出术语定义，data-structures 给出术语在代码里的具体结构
- [[ToolRouting]] — dispatch map 是 ToolRouting 的核心数据结构
