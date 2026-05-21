---
title: "SessionManagement"
type: concept
tags: [claude-code, context-management, session]
sources: [claude.com-blog-using-claude-code-session-management-and-1m-context]
last_updated: 2026-05-08
---

## Definition
Claude Code 会话管理策略：如何在 1M token 上下文窗口下控制上下文增长、何时拆分 session、如何使用 compaction/rewind/clear 等工具。

## Key Claims
- 1M context window 意味着可以做更长的任务，但也意味着 context rot 风险更高
- Context rot：模型性能随上下文增长而下降，因为注意力分散到更多 token 上
- Compaction：context window 快满时自动将任务摘要压缩，重新开一个新 window
- Bad autocompact 发生在：session 历史没有清晰叙事方向时，摘要会遗漏相关内容
- `/compact <hint>` 可以主动引导摘要方向
- Rewind 比"告诉它哪里错了"更好：回到失败之前重新提示
- 新任务 → 新 session；相关任务 → 考虑 `/clear` + 带关键信息过去

## Session Decision Table

| Situation | Tool | Why |
|---|---|---|
| Same task, context still relevant | Continue | Don't pay to rebuild load-bearing context |
| Claude went down wrong path | Rewind (Esc Esc) | Keep useful file reads, drop failed attempt |
| Mid-task but bloated session | `/compact <hint>` | Low effort; Claude decides what mattered |
| Genuinely new task | `/clear` | Zero rot; you control what carries forward |
| Only need the conclusion | Subagent | Intermediate noise stays in child's context |

## Connections
- [[ContextCompression]] — compaction 是上下文压缩的具体实现
- [[Subagent]] — subagent 是清理中间工具输出的主要手段
- [[AgentLoop]] — session 管理是主循环上下文预算的外层策略
