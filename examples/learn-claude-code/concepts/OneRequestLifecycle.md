---
title: "OneRequestLifecycle"
type: concept
tags: [reference, request-lifecycle, system-architecture]
sources: [learn.shareai.run-zh-s00b-one-request-lifecycle]
last_updated: 2026-05-08
---

## Definition
单次请求的完整纵向生命周期：从 QueryState 初始化 → 组装 prompt/messages → 调用模型 → 工具路由 → 权限判断 → Hook 拦截 → 执行并影响各层状态 → tool_result 写回 messages → 继续下一轮。

## Key Claims
- 所有模块不是在请求里平铺摆着，而是在不同阶段依次介入
- tool_result → messages 是唯一闭环，无论工具背后多复杂都要回到这里
- 很多高级机制本质上只是围绕这条闭环加的保护层（权限=执行前保护、hook=扩展层、compact=上下文预算保护、recovery=出错恢复层）
- 要学会区分 query-scope/session-scope/project-scope/platform-scope 状态

## Mental Model
```
用户请求
  → QueryState 初始化
  → 组装 system prompt / messages / reminders
  → 调用模型
  → 普通回答 → 结束
  → tool_use → Tool Router → 权限判断 → Hook 拦截 → 执行
  → 影响各层状态（todo/task/runtime task/memory/worktree）
  → tool_result 写回 messages
  → QueryState 更新
  → 下一轮继续
```

## Connections
- [[AgentLoop]] — 唯一闭环始终是 tool_result 回到 messages
- [[QueryControlPlane]] — 请求进入时先建立 QueryState
- [[ToolControlPlane]] — 工具路由层接管 tool_use 后的全流程
