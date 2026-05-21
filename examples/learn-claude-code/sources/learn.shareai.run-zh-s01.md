---
title: "S01 · Agent Loop 核心闭环"
type: source
tags: [curriculum, agent-loop, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s01.md
---

## Summary
学习仓库 `learn.shareai.run` 中文教程 s00–s19 系列的第一章，目标是把"模型 + 工具"连接成一个能持续推进任务的主循环。本章刻意只讲最小回路：消息历史、tool_use、tool_result、轮次推进；显式不讲流式、并发、恢复、压缩、权限。是整个 agent 系统其余章节的奠基章。

## Key Claims
- LLM 本身只会"生成下一段内容"，必须由一层代码反复执行 `发请求 → 检测 tool_use → 执行工具 → 写回结果 → 继续下一轮`，模型才从"会说话的程序"变成"会干活的 agent"。
- **核心不变量**：工具结果必须重新进入消息历史，成为下一轮推理的输入；只打印不写回会让模型下一轮"看不见"现实。
- `messages` 不是聊天展示层，而是模型下一轮要读的工作上下文；assistant 回复也必须写回历史，否则上下文会断层。
- 每个 `tool_result` 必须带 `tool_use_id`，否则模型分不清结果对应哪次调用。
- 最小教学版用 `response.stop_reason != "tool_use"` 作为退出判据，是合理的第一层简化；更完整的系统会显式维护"续行原因 (transition_reason)"。
- 教学版只用一种 transition_reason: `"tool_result"`（"因为刚执行完工具，所以要继续"）；后续章节会扩展它。
- 后续所有章节本质上都在往这个循环里增加新状态、新分支、新执行能力（s02 工具路由、s03 规划状态、s06 上下文压缩、s07 权限、s11 错误恢复）。

## Key Quotes
> "Agent 之所以从'会说'变成'会做'，是因为模型输出能走到工具，工具结果又能回到下一轮模型输入。" — 教学边界小节

> "工具结果必须重新进入消息历史，成为下一轮推理的输入。" — 最小心智模型小节

> "agent 的核心不是'模型很聪明'，而是'系统持续把现实结果喂回模型'。" — 系统接入小节

> "messages 不是聊天记录展示层，而是模型下一轮要读的工作上下文。" — 关键数据结构小节

## Connections
- [[AgentLoop]] — 本章的核心教学概念；本源是它当前唯一的 source。
- 序列前后：`s00` (前置)、`s02 工具路由`、`s03 规划状态`、`s06 上下文压缩`、`s07 权限判断`、`s11 错误恢复`（均尚未 ingest）。
- 内部引用 `s00a-query-control-plane.md`（s00 的子章节，介绍更完整的控制面）。

## Contradictions
（本章是当前 wiki 第一份 source，暂无可对照的内容。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[AgentLoop]] 的 Teaching Concept：
- 名词解释：loop / turn / tool_result / state
- 心智模型：ASCII 图（user → LLM → tool → tool_result → next turn）
- 最小实现：~30 行 Python（Anthropic SDK）
- 5 条初学者常见错误
- 显式教学边界（"这一章不讲什么"）
- 一句话记住：本质是"把模型动作意图变成真实执行结果，再送回模型"
