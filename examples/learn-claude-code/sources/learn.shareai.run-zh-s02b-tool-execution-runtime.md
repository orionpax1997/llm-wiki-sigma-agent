---
title: "S02b · 工具执行运行时"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s02b-tool-execution-runtime.md
---

## Summary
讲解工具真正开始运行后系统的调度规则：按 concurrency safe 分批、决定串行还是并行执行、progress message 在工具未结束时提前告知、结果按稳定顺序回写而非完成顺序、ContextModifier 暂存后按原始工具顺序统一合并而非谁先完成谁先写。

## Key Claims
- 并发不是默认全开，必须先按工具是否 concurrency safe 分批再执行
- 并发执行和稳定回写是两件事，不能混成一个动作
- ContextModifier 不要乱序落地，应该先暂存，最后按原始工具顺序统一合并
- progress message 不是可有可无的 UI 装饰，而是影响"上层何时知道工具还活着"
- 工具系统需要从"可调用"升级到"可调度"

## Key Quotes
> "工具系统不只是 `tool_name -> handler`，它还需要一层执行运行时来决定哪些工具并发、哪些串行、结果如何回写、共享上下文如何稳定合并。" — s02b

## Connections
- [[ToolControlPlane]] — s02a 讲工具层为什么会长成控制平面，s02b 讲工具真正开始运行时的调度规则
- [[ToolRouting]] — s02 的 dispatch map 是工具调用的基础，s02b 在此之上增加执行运行时层

## Contradictions
（无）
