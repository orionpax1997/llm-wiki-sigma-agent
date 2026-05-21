---
title: "S02 · 工具路由 / Tool Use"
type: source
tags: [curriculum, tool-routing, dispatch-map, path-sandbox, message-normalization, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s02.md
---

## Summary
`learn.shareai.run` 中文教程 s00–s19 系列的第二章。在 s01 的最小 agent loop 之上，把"只有 bash"扩展为"多工具 + 分发表"。核心做法是用 `TOOL_HANDLERS` 字典把工具名映射到处理函数，新增 `read_file` / `write_file` / `edit_file` 并通过 `safe_path()` 做路径沙箱。关键洞察：**加工具不需要改循环**——主循环和 s01 完全一致，新增能力只增加 handler + schema。本章也补充了"消息规范化 (normalize_messages)"作为系统变复杂后的协议层硬约束工具。

## Key Claims
- 只有 `bash` 时所有操作都走 shell，`cat` 截断不可预测、`sed` 遇特殊字符崩溃，且每次 bash 调用都是不受约束的安全面；专用工具可以在工具层面做路径沙箱。
- **加工具不需要改循环**：dispatch map (`{tool_name: handler_function}` 字典) 一次查找替换任何 if/elif 链，agent loop 与 s01 完全一致。
- 路径沙箱通过 `safe_path()` 把相对路径 resolve 到 `WORKDIR`，并用 `is_relative_to(WORKDIR)` 阻止逃逸。
- 工具层最终会生长为"工具控制平面"（权限环境、app state、MCP client、文件读取缓存、通知与 query 跟踪），但教学主线必须先把工具讲成"schema + handler + tool_result"三个稳定点。
- 当系统变复杂（工具超时、用户取消、压缩替换）后，内部 `messages` 列表会出现 API 不接受的格式问题，需要在发送前做一次 `normalize_messages()` 规范化。
- API 协议三条硬约束：(1) 每个 `tool_use` 必须有匹配的 `tool_result`；(2) `user`/`assistant` 必须严格交替；(3) 只接受协议定义字段（内部元数据会导致 400）。
- **`messages` 列表是系统的内部表示，API 看到的是规范化后的副本**——两者不是同一个东西。
- 教学边界：本章只稳住 schema/handler/tool_result 三点，权限、hook、并发、流式、外部工具来源等都建立在这层最小分发模型之后。

## Key Quotes
> "加工具不需要改循环。" — 问题小节关键洞察

> "The dispatch map is a dict: `{tool_name: handler_function}`. One lookup replaces any if/elif chain." — 解决方案小节

> "在一个结构更完整的系统里，工具层最后会更像一条'工具控制平面'，而不只是一张分发表。" — 工具控制平面前瞻小节

> "`messages` 列表是系统的内部表示, API 看到的是规范化后的副本。两者不是同一个东西。" — 消息规范化小节

> "tool schema 是给模型看的说明，handler map 是代码里的分发入口，`tool_result` 是结果回流到主循环的统一出口。" — 教学边界小节

## Connections
- [[AgentLoop]] — s02 在 s01 主循环上扩展；明确指出循环本身不变。
- [[ToolRouting]] — 本章核心教学概念（Teaching Concept）。
- [[MessageNormalization]] — 本章次要概念，处理 API 协议硬约束。
- [[PathSandbox]] — `safe_path()` 是 `read_file`/`write_file`/`edit_file` 的共享前置。
- 序列前后：上一章 [[learn.shareai.run-zh-s01|S01]]；下一章 s03 规划状态（尚未 ingest）。
- 内部引用 `s02a-tool-control-plane.md`（介绍工具层在更完整系统中的"控制平面"形态）。

## Contradictions
（与现有 wiki 内容无矛盾。s01 的"循环不变"原则在本章被明确延续与强化。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[ToolRouting]] 的 Teaching Concept：
- ASCII 心智模型：User → LLM → Tool Dispatch → handlers
- 最小实现：`safe_path()`、`TOOL_HANDLERS` dict、循环中按名称查找
- 显式对照表（s01 vs s02 的组件变化）
- "试一试" 4 个递进 prompt（read / create / edit / verify）
- 显式教学边界（"如果你开始觉得'工具不只是 handler map'……"）
- 一句话记住："加工具 = 加 handler + 加 schema。循环永远不变。"
- 次要概念 [[MessageNormalization]] 含三步 normalize 算法（剥离内部字段 / 配对补齐 / 合并连续同角色）
