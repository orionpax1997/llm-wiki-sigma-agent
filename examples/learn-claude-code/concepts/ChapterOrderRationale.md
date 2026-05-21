---
title: "ChapterOrderRationale"
type: concept
tags: [reference, curriculum-design, course-structure]
sources: [learn.shareai.run-zh-s00d-chapter-order-rationale]
last_updated: 2026-05-08
---

## Definition
课程章节顺序的设计原理：按"机制依赖顺序"而非"源码文件顺序/难度/功能酷炫程度"排列，强调每章像前一章自然长出来的下一层。

## Key Claims
- s03 必须放在 s04 前（先有本地计划，再有委派隔离）；s09 必须放在 s10 前（内容源先于组装管道）；s12 必须放在 s13 前（工作目标先于执行槽位）
- s07 权限必须早于 s08 hook（先 gate 再 extend）
- s15→s16→s17 的顺序正确（先有持久 actor，再有协议，再有自治）
- 错误重排：把 s04 提到 s03 前 / 把 s10 提到 s09 前 / 把 s13 提到 s12 前 / 把 s17 提到 s15 前 / 把 s19 提到 s18 前

## Four Learning Milestones
| 里程碑 | 学完你有了 |
|--------|-----------|
| 里程碑 A（做到 s06） | 能用的单 agent 原型 |
| 里程碑 B（做到 s11） | 高完成度单 agent 系统 |
| 里程碑 C（做到 s14） | 能长期推进工作的运行时 |
| 里程碑 D（做到 s19） | 接近完整的平台结构 |

## Connections
- [[ArchitectureOverview]] — s00 总览建立四阶段路径，s00d 解释为什么这个顺序合理
- [[AgentLoop]] — s01 必须最先
