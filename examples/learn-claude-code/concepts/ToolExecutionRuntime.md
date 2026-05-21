---
title: "ToolExecutionRuntime"
type: concept
tags: [reference, tool-layer, execution-runtime]
sources: [learn.shareai.run-zh-s02b-tool-execution-runtime]
last_updated: 2026-05-08
---

## Definition
工具真正开始运行后系统的调度规则：并发分批/串行并行/进度消息/结果稳定顺序/ContextModifier 合并。

## Key Claims
- 并发不是默认全开，必须先按工具是否 concurrency safe 分批再执行
- 并发执行和稳定回写是两件事，不能混成一个动作
- ContextModifier 不要乱序落地，应该先暂存，最后按原始工具顺序统一合并
- progress message 不是可有可无的 UI 装饰，而是影响上层何时知道工具还活着
- 工具系统需要从"可调用"升级到"可调度"

## Mental Model
```
tool_use blocks
  → 按 concurrency safety 分批
  → safe batch → concurrent execution
  |              - progress updates
  |              - final results
  |              - queued context modifiers
  → exclusive batch → serial execution
  → 按原始工具顺序统一合并 context modifiers
```

## Key Data Structures
| Structure | Role |
|-----------|------|
| ToolExecutionBatch | 一批并发安全或互斥的工具调用 |
| TrackedTool | 显式跟踪每个工具的状态（queued/executing/completed/yielded） |
| MessageUpdate | 工具执行过程中产生的消息更新 |
| QueuedContextModifiers | 并发执行时暂存的 context modifier，按原始顺序合并 |

## Connections
- [[ToolControlPlane]] — s02a 讲为什么需要控制平面，s02b 讲工具执行时的调度规则
- [[ToolRouting]] — s02 的 dispatch map 是工具调用基础，s02b 在此之上增加执行运行时层
