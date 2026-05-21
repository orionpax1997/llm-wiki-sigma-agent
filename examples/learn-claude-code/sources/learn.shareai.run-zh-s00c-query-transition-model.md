---
title: "S00c · Query 转移模型"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00c-query-transition-model.md
---

## Summary
专门讲解一条 query 为什么继续下一轮的分类体系：transition 不是"消息内容"而是"流程原因"，并给出 6 种 transition reason（tool_result_continuation / max_tokens_recovery / compact_retry / transport_retry / stop_hook_continuation / budget_continuation），每种都配独立状态修改，强调 continuation 需要预算而非无限重来。

## Key Claims
- 继续下一轮的原因有很多，而且这些原因不是一回事，必须从一开始拆开
- `transition` 是给系统自己看的，不是给模型的消息内容
- continuation 不是无限制的，每种路径都需要独立 budget（最多续写几次/最多压缩重试几次）
- 不把这些"继续原因"从一开始拆开，会导致日志不清、测试难写、教学心智模糊

## Key Quotes
> "一条 query 不是简单 while loop，而是一串显式 continuation reason 驱动的状态转移。" — s00c

## Connections
- [[QueryControlPlane]] — transition 是 QueryState 的核心字段之一
- [[ErrorRecovery]] — s11 的三条恢复路径对应三种 transition（compact_retry / max_tokens_recovery / transport_retry）
- [[ContextCompression]] — 压缩后重试对应 compact_retry

## Contradictions
（无）
