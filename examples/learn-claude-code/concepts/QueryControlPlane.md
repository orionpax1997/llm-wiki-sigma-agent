---
title: "QueryControlPlane"
type: concept
tags: [reference, query-control, state-management]
sources: [learn.shareai.run-zh-s00a-query-control-plane]
last_updated: 2026-05-08
---

## Definition
显式的 query 控制平面：管理"为什么继续下一轮"的跨轮共享状态，与"消息内容"分离。

## Key Claims
- Query = "完成一次用户请求而运行的一整段主循环过程"，不是单次 API 调用
- 控制平面负责"协调、调度、决定流程怎么往下走"，模型回复和工具执行是业务内容
- 继续下一轮的原因有很多：工具结果/截断续写/压缩重试/传输重试/hook 继续/预算允许——必须显式记录 transition
- 所有"继续原因"最终都要回到同一份 query 状态上

## Key Data Structures
- **QueryParams**: 外部一次性传入的输入集合（messages/system_prompt/user_context/tool_use_context）
- **QueryState**: 跨迭代真正变化的部分（messages/turn_count/transition/continuation_count/has_attempted_compact）
- **TransitionReason**: 6 种续行原因枚举（tool_result_continuation/max_tokens_recovery/compact_retry/transport_retry/stop_hook_continuation/budget_continuation）

## Connections
- [[AgentLoop]] — s01 建立最小主循环，QueryControlPlane 解释为什么需要控制平面抽象
- [[QueryTransitionModel]] — s00c 专门深入讲 transition 的分类体系
- [[OneRequestLifecycle]] — s00b 讲请求如何穿过控制平面
