---
title: "S00b · 单次请求生命周期"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00b-one-request-lifecycle.md
---

## Summary
把一次请求从用户输入到最终响应走完纵向流程图：QueryState 初始化 → 组装 prompt/messages → 调用模型 → 工具路由 → 权限判断 → Hook 拦截 → 执行并影响各层状态 → tool_result 写回 messages → 继续下一轮，并区分哪些状态会随请求结束而消失。

## Key Claims
- 所有模块不是在请求里平铺摆着，而是在不同阶段依次介入
- tool_result → messages 是唯一闭环，无论工具背后多复杂都要回到这里
- 很多高级机制本质上只是围绕这条闭环加的保护层（权限=执行前保护、hook=扩展层、compact=上下文预算保护、recovery=出错恢复层）
- 要逐渐学会区分 query-scope/session-scope/project-scope/platform-scope 状态

## Key Quotes
> "一次请求的完整生命周期，本质上就是：系统围绕同一条主循环，把不同模块按阶段接进来，最终持续把真实执行结果送回模型继续推理。" — s00b

## Connections
- [[AgentLoop]] — 唯一闭环始终是 tool_result 回到 messages
- [[QueryControlPlane]] — 请求进入时先建立 QueryState
- [[ToolControlPlane]] — 工具路由层接管 tool_use 后的全流程

## Contradictions
（无）
