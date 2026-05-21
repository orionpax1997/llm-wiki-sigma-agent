---
title: "TeachingScope"
type: concept
tags: [reference, curriculum-design, teaching-principles]
sources: [learn.shareai.run-zh-teaching-scope]
last_updated: 2026-05-08
---

## Definition
教学边界声明：界定这套教学仓库"追求什么分数"（主干高保真 vs 外围细节取舍），什么必须讲清楚，什么不该占主线篇幅。

## Key Claims
- 高保真指的是：核心运行模式、主要模块边界、关键数据结构、模块间协作方式、关键状态转换
- 每章推荐遵守"问题→名词→心智模型→数据结构→最小实现→接入主循环→常见错误→教学边界"八步顺序
- 逆向源码应只扮演"维护者校准参考"，不应成为读者理解正文的前提
- 追求什么分数：主线清楚 + 顺序合理 + 名词完整 + 机制边界准确 + 例子可运行 + 升级路径自然

## What Must Be in Main Chapters
- 核心模块有哪些、模块之间怎么协作、每个模块解决什么问题
- 关键状态存在哪里、关键数据结构长什么样、主循环如何把这些机制接进来

## What Should Not Occupy Main Chapter Space
- 打包/编译/发布流程、跨平台兼容胶水、遥测/企业策略/账号体系
- 与教学主线无关的历史兼容分支、某份上游源码里的函数名/文件名/行号级对照

## Connections
- [[ArchitectureOverview]] — 两者共同界定"这套仓库还原什么、不还原什么"
- [[CodeReadingOrder]] — teaching-scope 给出维护者检查清单，s00f 给出读者读代码时的具体操作
