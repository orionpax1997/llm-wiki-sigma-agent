---
title: "S00e · 参考仓库模块对照"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s00e-reference-module-map.md
---

## Summary
把参考仓库里真正重要的模块簇和课程章节一一对齐，验证章节顺序与真实系统设计主干一致，并明确哪些内容（CLI 命令、UI 细节、遥测、兼容层）属于"参考仓库有但教学仓库不该占主线"的部分。

## Key Claims
- 参考仓库真正决定系统骨架的是少数几簇控制、状态、任务、团队、隔离执行和外部能力模块，与四阶段教学主线基本对齐
- 教学顺序不应改成"跟着源码树走"，应保持依赖顺序展开
- `tasks/types.ts` 这类运行时任务联合类型证明 TaskRecord 和 RuntimeTaskState 必须分开教，强烈支持 s12 先于 s13 的顺序
- 参考仓库的 `AgentTool` 横跨一次性委派/后台 worker/持久 worker/worktree 隔离——正是教学仓库拆成 s04/s15/s17/s18 的证据

## Key Quotes
> "最好的教学顺序，不是源码文件出现的顺序，而是一个初学实现者真正能顺着依赖关系把系统重建出来的顺序。" — s00e

## Connections
- [[ArchitectureOverview]] — s00e 以真实源码为参照验证教学设计
- [[TaskSystem]] — 参考仓库 `tasks/*` 证明 s12 任务图设计
- [[BackgroundTask]] — 参考仓库 `LocalShellTask`/`LocalAgentTask` 等类型是 s13 RuntimeTaskState 的原型
- [[Teammate]] — 参考仓库 `InProcessTeammateTask` 是 s15 的原型

## Contradictions
（无）
