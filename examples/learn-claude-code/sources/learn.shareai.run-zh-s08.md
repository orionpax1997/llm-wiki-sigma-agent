---
title: "S08 · Hook 系统 / 固定时机扩展点"
type: source
tags: [learn-shareai-run, curriculum, agent-core, hook, s08]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s08.md
---

## Summary
S08 解决的是“在不改写主循环的前提下，在固定时机插入额外行为”。核心机制是 hook：主循环只暴露事件（SessionStart / PreToolUse / PostToolUse），真正的附加逻辑交给 hook runner 执行。教学版统一返回语义（0 继续 / 1 阻止 / 2 注入补充消息），让初学者先掌握“观察、拦截、补充”三种作用，再逐步扩展事件面。

## Key Claims
- Hook 不是主循环的替代品，而是主循环在固定时机对外发出的调用。
- 主循环只需要知道三件事：事件名、要交出去的上下文、收到结果后怎么处理。
- 教学版用统一 0/1/2 返回约定，先建立最小模型，再细化不同事件的语义。
- 3 个事件（SessionStart / PreToolUse / PostToolUse）已足够支撑最核心的扩展能力。
- 扩展方向：生命周期事件、工具事件、压缩事件、多 agent 事件。

## Key Quotes
> "主循环只负责暴露'时机'，真正的附加行为交给 hook。"
> "hook 让系统可扩展，但不要求主循环理解每个扩展需求。"
> "先学统一模型，再学事件细化。"

## Connections
- [[AgentLoop]] — hook 接入主循环的 PreToolUse / PostToolUse 时机
- [[ToolRouting]] — hook 在 dispatch 之前/之后运行，不改变 dispatch map 本身
- [[Permissions]] — s07 的权限判断可视为 PreToolUse hook 的一种具体实现
- [[ToolControlPlane]] — s02a 预告的完整控制平面含 hook / 权限 / 缓存 / 通知等
- [[ContextCompression]] — 压缩前后可扩展为 hook 事件（压缩前/压缩后）
- [[Subagent]] — 子 agent 启动/任务完成/队友空闲可扩展为多 agent hook 事件

## Contradictions
- None
