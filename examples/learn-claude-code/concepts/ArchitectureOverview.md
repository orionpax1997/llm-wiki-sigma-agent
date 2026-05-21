---
title: "ArchitectureOverview"
type: concept
tags: [reference, system-architecture, course-overview]
sources: [learn.shareai.run-zh-s00-architecture-overview]
last_updated: 2026-05-08
---

## Definition
全课程 19 章的鸟瞰地图，界定这套仓库"还原什么、不还原什么"，建立四阶段学习路径（单 agent 核心 → 生产加固 → 任务管理 → 多 agent 平台）。

## Key Claims
- 追求"设计主脉络高保真，而非所有外围实现细节 1:1"
- 四阶段顺序符合初学者心智：先建立稳定主线，再补安全/扩展/记忆/恢复，最后才进入多 agent、隔离执行和外部工具平台
- 整个系统状态最终会长成带很多子模块的状态系统，不只是 `messages + tools`
- 每章新增的核心结构各不相同，按"依赖关系"而非"难度"排序

## Connections
- [[AgentLoop]] — s01 建立主循环，是系统心脏
- [[QueryControlPlane]] — s00a 解释完整系统的 query 控制面长什么样
- [[ReferenceModuleMap]] — s00e 与课程章节对应的源码模块对照表，验证教学顺序合理性
- [[ChapterOrderRationale]] — s00d 详细解释章节顺序设计原理
- [[TeachingScope]] — s00 teaching-scope 共同界定教学边界和设计原则
