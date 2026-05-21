---
title: "S00d · 章节顺序设计原理"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00d-chapter-order-rationale.md
---

## Summary
专门解释为什么课程要按 s01→s19 现在的顺序展开，按四条依赖线（让 agent 能跑 → 不乱跑 → 能长期跑 → 能分工/隔离/接外部跑）组织章节，并给出"防止变差的五种错误重排"清单，强调章节顺序服从"机制依赖顺序"而非"源码文件顺序"。

## Key Claims
- 章节顺序按"机制依赖顺序"排，不是按难度、文件出现顺序或功能酷炫程度排
- s03 必须放在 s04 前（先有本地计划，再有委派隔离）；s09 必须放在 s10 前（内容源先于组装管道）；s12 必须放在 s13 前（工作目标先于执行槽位）
- s07 权限必须早于 s08 hook（先 gate 再 extend）
- s15→s16→s17 的顺序正确（先有持久 actor，再有协议，再有自治）

## Key Quotes
> "好的章节顺序，不是把所有机制排成一列，而是让每一章都像前一章自然长出来的下一层。" — s00d

## Connections
- [[ArchitectureOverview]] — s00 总览建立四阶段路径，s00d 解释为什么这个顺序合理
- [[AgentLoop]] — s01 必须最先，建立系统最小入口

## Contradictions
（无）
