---
title: "S00a · Query 控制平面"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00a-query-control-plane.md
---

## Summary
解释为什么完整 agent 系统不能只靠 `messages[] + while True`——需要一个显式的 query 控制平面来管理跨轮状态（turn_count、transition、continuation_count、has_attempted_compact 等），并给出 QueryParams、QueryState、TransitionReason 三个关键数据结构。

## Key Claims
- Query 是"完成一次用户请求而运行的一整段主循环过程"，不是单次 API 调用
- 控制平面负责"协调、调度、决定流程怎么往下走"，模型回复和工具执行是业务内容
- 更完整系统里"继续下一轮"的原因有很多（工具结果/截断续写/压缩重试/传输重试/hook 继续/预算允许），必须显式记录 transition
- 所有"继续原因"最终都要回到同一份 query 状态上

## Key Quotes
> "更完整的 query loop 不只是'循环'，而是'拿着一份跨轮状态不断推进的查询控制平面'。" — s00a

## Connections
- [[AgentLoop]] — s01 建立最小主循环，s00a 解释为什么需要控制平面抽象
- [[QueryTransitionModel]] — s00c 专门深入讲 transition 的分类体系
- [[OneRequestLifecycle]] — s00b 讲请求如何穿过控制平面

## Contradictions
（无）
