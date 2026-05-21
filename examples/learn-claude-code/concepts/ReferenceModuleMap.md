---
title: "ReferenceModuleMap"
type: concept
tags: [reference, course-design, source-verification]
sources: [learn.shareai.run-zh-s00e-reference-module-map]
last_updated: 2026-05-08
---

## Definition
把参考仓库里真正重要的模块簇和课程章节一一对齐，验证章节顺序与真实系统设计主干一致。

## Key Claims
- 参考仓库真正决定系统骨架的是少数几簇：Tool.ts / AppStateStore.ts / memdir/* / services/SessionMemory/* / tasks/* / tools/AgentTool/* / tools/MCPTool/* / plugins/* / hooks/toolPermission/*
- `tasks/types.ts` 的运行时任务联合类型（LocalShellTask/LocalAgentTask/RemoteAgentTask/MonitorMcpTask）强烈证明 TaskRecord 和 RuntimeTaskState 必须分开教
- 参考仓库的 `AgentTool` 横跨一次性委派/后台 worker/持久 worker/worktree 隔离——正是教学仓库拆成 s04/s15/s17/s18 的证据
- CLI 命令/UI 细节/遥测/产品接线属于"参考仓库有但教学仓库不该占主线"的内容

## Key Module-to-Chapter Mappings
| 参考仓库模块簇 | 对应章节 |
|---|---|
| Tool.ts / AppStateStore / coordinator state | s00, s00a, s01, s11 |
| Tool.ts / native tools / tool context | s02, s02a, s02b |
| TodoWriteTool | s03 |
| AgentTool (最小子集) | s04 |
| DiscoverSkillsTool / skills/* | s05 |
| services/contextCollapse/* | s06 |
| hooks/toolPermission/* | s07 |
| types/hooks.ts / hook runner | s08 |
| memdir/* / services/SessionMemory/* | s09 |
| constants/prompts.ts / prompt sections | s10, s10a |
| query transition / retry branches | s11, s00c |
| 任务记录/任务板/依赖解锁 | s12 |
| Runtime task 联合类型 | s13, s13a |
| ScheduleCronTool/* | s14 |
| InProcessTeammateTask / team tools | s15 |
| send-message / request tracking | s16 |
| coordinator mode / autonomy | s17 |
| EnterWorktreeTool / ExitWorktreeTool | s18 |
| MCPTool / services/mcp/* / plugins/* | s19, s19a |

## Connections
- [[ArchitectureOverview]] — s00e 以真实源码为参照验证教学设计
- [[TaskSystem]] — 参考仓库 tasks/* 证明 s12 任务图设计
- [[BackgroundTask]] — 参考仓库 RuntimeTaskState 类型是 s13 原型
