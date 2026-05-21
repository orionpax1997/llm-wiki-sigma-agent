---
title: "TeamTaskLaneModel"
type: concept
tags: [reference, multi-agent, platform-architecture, entity-boundaries]
sources: [learn.shareai.run-zh-team-task-lane-model]
last_updated: 2026-05-08
---

## Definition
s15-s18 后半程五层边界澄清：teammate（长期参与者）→ protocol request（协调追踪）→ task（工作目标）→ runtime task（执行槽位）→ worktree（执行车道/隔离目录），强调每个词各司其职，不能混用"任务"一词。

## Five-Layer Breakdown
| Layer | What It Answers | Example |
|-------|----------------|---------|
| teammate | 谁在长期参与协作 | `alice (frontend)` |
| protocol request | 谁向谁发起需要追踪的协调请求 | `request_id=a1b2c3, kind=plan_approval, status=pending` |
| task | 要做什么（工作目标） | `task_id=12, subject="Implement login page"` |
| runtime task | 现在有什么执行单元正在跑 | `runtime_id=rt_01, type=in_process_teammate, status=running` |
| worktree | 在哪做且不和别人互踩 | `worktree=login-page, path=.worktrees/login-page, status=active` |

## Key Claims
- teammate 不是任务，request_id 不是任务，runtime_id 也不是任务，worktree 更不是任务——真正表达"这件工作本身"的只有 task 层
- 最典型混淆：把"alice 认领了 task#12 并在 login-page worktree 里推进"说成"alice 就是在做 login-page 任务"
- s17 的自治认领，认领的是 s12 的工作图任务，不是 s13 的运行时槽位

## Mental Model
```
alice (teammate)
  收到或发起一个 request_id
    认领 task #12
      作为执行单元推进工作
        进入 worktree "login-page"
          在 .worktrees/login-page 里运行命令和改文件
```

## Connections
- [[Teammate]] — teammate 层定义
- [[Protocol]] — protocol request 层定义
- [[TaskSystem]] — task 层定义
- [[BackgroundTask]] — runtime task 层定义
- [[Worktree]] — worktree 层定义
