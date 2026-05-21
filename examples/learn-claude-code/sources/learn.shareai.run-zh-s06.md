---
title: "S06 · 上下文压缩 / Context Compression"
type: source
tags: [curriculum, context-compression, prompt-budget, agent-loop, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s06.md
---

## Summary
`learn.shareai.run` 中文教程 s00–s19 系列的第六章。在 s01 ([[AgentLoop]]) + s02 ([[ToolRouting]]) + s03 ([[PlanningState]]) + s04 ([[Subagent]]) + s05 ([[SkillSystem]]) 之上，引入**上下文压缩 (Context Compression)**：当 agent 推进任务时，工具输出 / 旧消息 / 历史累积会持续膨胀，最终撞上下文上限。本章给出一个**三层最小心智模型**：(1) 大工具结果**不直接塞进上下文**——写到磁盘 + 留预览（`<persisted-output>`）；(2) 旧工具结果**不一直原样保留**——替换成简短占位（micro-compact）；(3) 整体历史过长时——生成一份**连续性摘要**（compact-history）。手动 `/compact` 与自动压缩**复用同一条机制**。本章刻意只守住三层，把更复杂的产品化压缩技巧留到后续章节，并显式划清 **压缩 vs memory** 边界（压缩 = 当前会话太长怎么办；memory = 跨会话仍值得保留什么）。从这一章起，agent 主循环开始**同时维护两件事：任务推进 + 上下文预算**。

## Key Claims
- 到 s05 为止 agent 会做的事情已经很多，上下文会越来越快膨胀（大文件读入、长命令输出、多轮旧结果堆积）；没有压缩机制必然撞三个问题：注意力被旧结果淹没、API 请求越来越重越来越贵、最终撞上下文上限任务中断。
- 本章真正要解决的是：**怎样在不丢掉主线连续性的前提下，把活跃上下文重新腾出空间**。
- 三个关键名词必须分清：(1) **上下文窗口** = 模型这一轮真正能一起看到的输入容量（不是无限）；(2) **活跃上下文** = 当前这几轮继续工作时最值得马上看到的那一部分（不是历史全部）；(3) **压缩** = 用更短的表示方式保留**继续工作真正需要**的信息（不是 ZIP 文件压缩）。
- **最小心智模型只有三层**：① 大结果不直接塞进上下文 → 写磁盘 + 留预览；② 旧结果不一直原样保留 → 替换成占位；③ 整体历史太长 → 生成连续性摘要。手动触发 `/compact` 或 `compact` 工具本质上走的是第 3 层。
- 三个关键数据结构：(1) **Persisted Output Marker** —— `<persisted-output>` 包住"全文路径 + 预览"，表达"全文没丢，只是搬去磁盘"；(2) **CompactState** —— `{has_compacted, last_summary, recent_files}`，显式维护一份压缩状态；(3) **Micro-Compact Boundary** —— 教学版简单规则："只保留最近 3 个工具结果的完整内容，更旧的改成占位提示"。
- 最小实现 5 步：(1) `persist_large_output` 大输出写磁盘 + 留 2000 字预览；(2) `micro_compact` 旧工具结果替换成占位文本；(3) `compact_history` 整体过长时调用 `summarize_conversation` 生成单条连续性摘要消息；(4) 主循环里每轮先 `micro_compact`，再判断 `estimate_context_size > CONTEXT_LIMIT`，是则 `compact_history` 并置 `has_compacted=True`；(5) 手动压缩和自动压缩**复用同一条机制**——`compact` 工具不需要重新发明逻辑，只是表达"用户/模型现在主动要求执行一次完整压缩"。
- **压缩后真正要保住的不是字数少**，而是连续性——必须保住至少 5 类信息：① 当前任务目标 ② 已完成的关键动作 ③ 已修改或重点查看过的文件 ④ 关键决定与约束 ⑤ 下一步应该做什么。如果这些没有保住，压缩腾出了空间但打断了工作连续性。
- **主循环责任扩展**：从这一章起 agent loop 不再只做"收消息 / 调模型 / 跑工具"，多了一个责任：**管理活跃上下文的预算**。也就是说 agent loop 现在同时维护"任务推进 + 上下文预算"两件事。
- **章节联动预告**：s09 memory 决定"什么信息值得长期保存"；s10 prompt pipeline 决定"哪些块应该重新注入"；s11 error recovery 处理"压缩不足时的恢复分支"——s06 是这串预算管理机制的起点。
- 5 条初学者常见坑：(1) 以为压缩 = 删除（其实是把"不必常驻活跃上下文"的内容换一种表示）；(2) 只在撞上限后才临时乱补（应从一开始就有三层思路）；(3) 摘要写成一句空话（没保住文件 / 决定 / 下一步就是没用）；(4) 把压缩和 memory 混成一类（前者解决"会话太长"，后者解决"跨会话保留"）；(5) 一上来给初学者讲过多产品化层级（教学主线先讲清最小正确模型）。
- **教学边界**：本章**只讲三件事**——什么该留在活跃上下文、什么该搬到磁盘 / 占位标记、完整压缩后哪些连续性信息一定不能丢；所有产品化压缩技巧大全不在本章。读者能用 `persisted output + micro compact + summary compact` 保住长会话连续性，本章就够深了。

## Key Quotes
> "怎样在不丢掉主线连续性的前提下，把活跃上下文重新腾出空间。" — 这一章要解决什么问题

> "活跃上下文更像：当前这几轮继续工作时，最值得模型马上看到的那一部分。" — 名词解释

> "压缩……用更短的表示方式，保留继续工作真正需要的信息。" — 名词解释

> "让模型知道'发生了什么'，但不强迫它一直背着整份原始大输出。" — 第一步

> "压缩不是'把历史缩短'这么简单。真正重要的是：让模型还能继续接着干活。" — 压缩后真正要保住什么

> "agent loop 现在开始同时维护两件事：任务推进 + 上下文预算。" — 它如何接到主循环里

> "上下文压缩的核心，不是尽量少字，而是让模型在更短的活跃上下文里，仍然保住继续工作的连续性。" — 一句话记住

## Connections
- [[AgentLoop]] — 本章给主循环新增第二个责任："任务推进 + 上下文预算"。`micro_compact` 在每轮调用前运行，`compact_history` 在 `estimate_context_size > CONTEXT_LIMIT` 时触发。**主循环结构本身不变**，只是多了上下文预算检查这一步。
- [[ToolRouting]] — 手动 `compact` 工具复用 s02 的 dispatch map：`TOOL_HANDLERS["compact"] = lambda **kw: compact_history(state["messages"])`，零改动循环；手动压缩 = 自动压缩同一条机制。
- [[SkillSystem]] — s05 削减**常驻知识开销**（system prompt 分稳定层 + 按需层），s06 削减**历史累积开销**（messages 分活跃 + 持久化 + 摘要）。两者正交，共同构成 prompt 预算管理。
- [[Subagent]] — s04 削减**过程性噪声**（局部任务用独立 messages 跑完只回摘要），s06 削减**历史累积开销**（同一 messages 内压缩旧内容）。Subagent 是"先不让它进主上下文"，Compression 是"已经进了再腾出空间"。
- [[ContextCompression]] — 本章的核心教学概念（Teaching Concept）。
- 序列前后：上一章 [[learn.shareai.run-zh-s05|S05]]；下一章 s07（尚未 ingest，预告引入 [[Permissions]]）。
- 远期对照：s09 memory（跨会话保留 / 与压缩边界邻居）、s10 prompt pipeline（哪些块重新注入）、s11 error recovery（压缩不足的恢复分支）。

## Contradictions
（与现有 wiki 内容无矛盾。s06 在 s01–s05 主循环 / 工具层 / 状态扩展不变的承诺上**新增一个责任维度**——上下文预算管理；与 [[Subagent]]、[[SkillSystem]] 的"prompt 预算管理"主线完全一致，并在 overview 已预告的位置上落位。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[ContextCompression]] 的 Teaching Concept：
- 名词解释：上下文窗口 / 活跃上下文 / 压缩 / Persisted Output Marker / CompactState / Micro-Compact Boundary
- 心智模型：三层 ASCII 图（持久化大输出 → micro-compact 旧结果 → summary-compact 整体历史）
- 最小实现 5 步：`persist_large_output`、`micro_compact`、`compact_history`、主循环接入、手动压缩复用机制
- 关键数据结构：`<persisted-output>` 标记、`CompactState` 字典、Micro-Compact "保留最近 3 个" 规则
- 压缩后必须保住的 5 类信息（任务目标 / 已完成动作 / 改过的文件 / 决定 / 下一步）
- 5 条初学者常见错误（压缩=删除 / 撞上限才补 / 摘要空话 / 与 memory 混淆 / 上来讲产品化）
- 显式教学边界（"这一章不讲什么"——所有产品化压缩技巧大全推到后续）
- 显式章节联动（s09 memory / s10 pipeline / s11 error recovery）
- 一句话记住："上下文压缩的核心，不是尽量少字，而是让模型在更短的活跃上下文里，仍然保住继续工作的连续性。"
