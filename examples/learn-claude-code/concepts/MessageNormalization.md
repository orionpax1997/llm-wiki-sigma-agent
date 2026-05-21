---
title: "MessageNormalization"
type: concept
tags: [agent-internals, api-protocol, messages]
sources: [learn.shareai.run-zh-s02]
last_updated: 2026-05-07
---

## Definition
当 agent 内部 `messages` 列表因为工具超时、用户取消、压缩替换等原因偏离了 API 协议要求，需要在每次发送前做一次 `normalize_messages()` 规范化——剥离内部字段、补齐 tool_use/tool_result 配对、合并连续同角色消息——然后把规范化后的副本发给 API。**内部表示和 API 视图是两个东西。**

## Key Claims
- API 协议三条硬约束：
  1. 每个 `tool_use` 块 **必须** 有匹配的 `tool_result`（通过 `tool_use_id` 关联）
  2. `user` / `assistant` 消息必须 **严格交替**（不能连续两条同角色）
  3. 只接受协议定义字段（内部元数据 `_internal` / `_source` / `_timestamp` 会导致 400）
- 三步规范化算法：
  - **Step 1**：剥离内部字段（保留 `role` + `content`，过滤下划线前缀的 meta）
  - **Step 2**：tool_result 配对补齐——找出缺失配对的 `tool_use`，插入 `"(cancelled)"` 占位 result
  - **Step 3**：合并连续同角色消息（前后 content 拼接为 list）
- **关键洞察**：`messages` 是系统的内部表示，API 看到的是规范化后的副本——两者不是同一个东西。
- 在 agent loop 中，规范化在每次 `client.messages.create(...)` 之前执行，对内部 `messages` 不做破坏性修改。

## Connections
- [[AgentLoop]] — 在主循环内 API 调用前作为前置变换。
- [[ToolRouting]] — 本章 (s02) 引入，工具变多后 tool_use/tool_result 配对问题更显性。
- 后续相关章节：s06 [[ContextCompression]]（"压缩替换"是 normalize 要修复的真实场景之一）、s11 [[ErrorRecovery]]（工具超时与用户取消同样是来源）。
