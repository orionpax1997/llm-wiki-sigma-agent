---
title: "Using Claude Code: Session Management and 1M Context"
type: source
tags: [claude-code, context-management, session]
date: 2025-05-08
source_file: raw/claude.com-blog-using-claude-code-session-management-and-1m-context.md
---

## Summary
关于 Claude Code 会话管理策略的实用指南，聚焦 1M token 上下文窗口下的上下文旋进（context rot）、compaction、rewind、session 拆分等工具的使用时机与原理。

## Key Claims
- 上下文窗口越大，上下文旋进（context rot）风险越高——注意力分散到更多 token 上，模型性能随上下文增长而下降
- 当 context window 快满时，Claude Code 会自动将当前任务摘要压缩，重新开始一个新 context window，这个过程叫 **compaction**
- 会话管理的五大分支点：**Continue / Rewind / Clear / Compact / Subagents**
- 新任务 → 新 session；相关但独立的任务 → 考虑 `/clear` + 把关键信息带过去
- Rewind 比"告诉它哪里错了"更好：回到失败之前，重新用学到的信息提示
- Bad autocompact 发生在：当 session 历史没有清晰的叙事方向时，摘要会遗漏相关内容
- Subagent 的判断标准：**"我只想要结论，还是也需要中间工具输出？"** —— 只需要结论 → subagent

## Context Management Decision Table

| Situation | Tool | Why |
|---|---|---|
| Same task, context still relevant | Continue | Don't pay to rebuild load-bearing context |
| Claude went down wrong path | Rewind (Esc Esc) | Keep useful file reads, drop failed attempt |
| Mid-task but bloated session | `/compact <hint>` | Low effort; Claude decides what mattered |
| Genuinely new task | `/clear` | Zero rot; you control what carries forward |
| Only need the conclusion | Subagent | Intermediate noise stays in child's context |

## Key Quotes
> "Context rot is the observation that model performance degrades as context grows because attention gets spread across more tokens." — Thariq Shihipar

> "The mental test we use at Anthropic: will I need this tool output again, or just the conclusion?" — Thariq Shihipar

## Connections
- [[ContextCompression]] — compaction 是上下文压缩的具体实现
- [[Subagent]] — subagent 是清理中间工具输出的主要手段
- [[AgentLoop]] — session 管理是主循环上下文预算的外层策略

## Contradictions
（暂无）
