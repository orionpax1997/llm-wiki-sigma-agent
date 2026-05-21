---
title: "TaskSystem"
type: concept
tags: [curriculum, task-system, dependency-graph, persistence, beginner]
sources: [learn.shareai.run-zh-s12, learn.shareai.run-zh-s13a]
last_updated: 2026-05-08
---

## Expanded by S13a: Task vs. RuntimeTaskState Boundary
[[learn.shareai.run-zh-s13a-runtime-task-model|S13a]] clarifies the critical distinction between:
- **Work-graph task** (`TaskRecord`, s12) — durable work node on the task board: what to do, who depends on whom, who owns it, current progress
- **Runtime task** (`RuntimeTaskState`, s13) — currently alive execution slot: what is running, what type, where is the output, has it been notified

A single work-graph task can spawn multiple runtime tasks (e.g., one task simultaneously running a pytest background job, a coder teammate worker, and a monitor task).

The three-part chain: **teammate → protocol request → task (goal) → runtime task (execution slot) → worktree (execution lane)**. See [[TeamTaskLaneModel]] for the full five-layer breakdown.
---

## Core Thesis
> 任务系统的核心不是"保存清单"，而是"判断什么时候能开工"。

## Problem Definition
有了 [[PlanningState]]，agent 能在会话内列步骤，但面临三个限制：
- 前置工作没做完，就贸然开始后面的任务
- 某个任务完成后，不知道解锁了谁
- 多个 agent 协作时，没有统一任务板可读

- **学完前**：你的 agent 用 todo 列步骤，但跨多轮、多角色、有依赖时计划漂移或重复。
- **学完后**：你能手写一个持久化任务图，用 `blockedBy` / `blocks` 维护依赖，并在完成时自动解锁后续任务。

## Terminology
| Term | Definition |
|------|------------|
| TaskRecord | 一条任务的最小结构：`{id, subject, description, status, blockedBy, blocks, owner}` |
| TaskStatus | 四态枚举：`pending` / `in_progress` / `completed` / `deleted` |
| blockedBy | 这条任务还在等谁完成 |
| blocks | 这条任务完成后会解锁谁 |
| ready | `status == pending` 且 `blockedBy` 为空，即满足开工条件 |
| 任务图 | 任务节点 + 依赖连线的有向图 |

## Mental Model
```text
用户提出复杂目标
      |
      v
模型拆成 TaskRecord 列表
      |
      v
任务图（节点 + 依赖连线）
      |
      v
is_ready() 判断谁可以开工
      |
      v
任务完成 -> 自动从下游 blockedBy 移除 -> 解锁新 ready 任务
```

**关键升级：主循环第一次拥有会话外状态**
```text
messages         -> 模型看到的历史
planning state   -> 当前计划的显式外部状态（s03）
tasks/           -> 持久化任务图（s12）
```

## Minimal Implementation
"130 LOC 边界"：`TaskManager` + 4 个工具接入 + 自动解锁。**显式不覆盖**：运行时执行层（s13）、任务编排（s14）、多角色协作（s15）。

```python
class TaskManager:
    def create(self, subject: str, description: str = "") -> dict:
        task = {
            "id": self._next_id(),
            "subject": subject,
            "description": description,
            "status": "pending",
            "blockedBy": [],
            "blocks": [],
            "owner": "",
        }
        self._save(task)
        return task

    def add_dependency(self, task_id: int, blocks_id: int):
        task = self._load(task_id)
        blocked = self._load(blocks_id)
        if blocks_id not in task["blocks"]:
            task["blocks"].append(blocks_id)
        if task_id not in blocked["blockedBy"]:
            blocked["blockedBy"].append(task_id)
        self._save(task)
        self._save(blocked)

    def complete(self, task_id: int):
        task = self._load(task_id)
        task["status"] = "completed"
        self._save(task)
        for other in self._all_tasks():
            if task_id in other["blockedBy"]:
                other["blockedBy"].remove(task_id)
                self._save(other)

def is_ready(task: dict) -> bool:
    return task["status"] == "pending" and not task["blockedBy"]
```

## System Position
- **Inherits from**: [[PlanningState]] (s03)、[[AgentLoop]] (s01)、[[ToolRouting]] (s02)
- **Prepares for**: s13 运行时执行层、s14 任务编排、s15 多角色协作
- **Cross-links**: [[Subagent]] 多 agent 时需要统一任务板；[[Memory]] 持久化存储边界

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 只会创建任务，不会维护依赖 | 最后得到的是普通清单，不是任务图 | "这些任务之间有连线吗？谁阻塞谁？" |
| 任务只放内存，不落盘 | 系统一重启，整个工作结构就没了 | "任务存在哪里？重启后还在吗？" |
| 完成任务后不自动解锁后续任务 | 系统永远不知道下一步谁可以开工 | "complete() 里除了改 status 还做了什么？" |
| 把工作目标和运行中的执行混成一层 | 后面 s13 的后台任务系统很难讲清 | "这条 task 是一个'工作目标'，还是一个'正在跑的 pytest 进程'？" |

## Diagnostic Questions (Step 1)
1. 任务系统比 todo 多出来的核心能力是什么？
2. `TaskRecord` 7 个字段分别承担什么职责？
3. 为什么 `blockedBy` 和 `blocks` 要双向维护？
4. `is_ready()` 为什么只检查 `pending` 和 `blockedBy`？
5. s12 的 task 和 s03 的 todo、s13 的运行时执行分别是什么边界？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 你觉得"任务图"跟"todo 列表"最大的区别是什么？
- 如果只有 `blocks` 没有 `blockedBy`，查询"谁还卡着"会多慢？
- `deleted` 状态为什么需要存在？直接删文件不行吗？

### Advanced
- 双向依赖维护 vs 单向前向索引：哪种对 `is_ready()` 更友好？哪种对存储更友好？
- 如果任务图出现环，会发生什么？教学版为什么先不处理？
- 一任务一文件 vs 单 JSON 文件：在 1000 条任务时各有什么优劣？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 把 todo 升级成"带依赖、能落盘、会解锁"的工作图。 |
| L2 Guide | 关键数据结构是 `TaskRecord`，关键判断是 `is_ready()`，关键动作是 `complete()` 后清理下游 `blockedBy`。 |
| L3 Analogy | 像厨房里的备菜板——每道菜是一个任务，"先切菜再炒菜"是依赖，切完把"待炒"标签撕掉。 |
| L4 Deconstruct | `TaskRecord` 7 字段 + 双向依赖 + ready 规则 + 完成解锁——四个点凑齐。 |
| L5 Worked Example | 见上方 Minimal Implementation：`TaskManager` 40 行，4 个工具接入，循环零改动。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "task 就是 todo 换个名字" | "task 能表达'谁先谁后'吗？todo 能吗？" | todo 是平面列表；task 是依赖图 |
| "任务系统越复杂越好" | "教学版为什么只保留 4 个状态？" | 先守住最小主干，再扩展管理功能 |
| "complete() 只改 status 就够了" | "下游任务怎么知道可以开工了？" | 必须同时清理 `blockedBy`，否则 `is_ready()` 永远为 False |
| "s12 已经覆盖后台执行" | "task 是一个工作目标，还是一个正在跑的 worker？" | 后者是 s13；s12 只解决"工作目标如何被长期组织" |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | `TaskRecord` 7 个字段是什么？`TaskStatus` 4 个状态是什么？ | 字段全列出且释义正确；状态全列出 |
| Causal | 为什么 `complete()` 里要遍历所有任务清理 `blockedBy`？ | 答出"任务图是动态推进的，完成事件会改变其他任务的 ready 状态" |
| Application | 写出 `add_dependency()` 的伪代码，包含双向维护 | 含双向 append、去重、save 两边 |
| Discrimination | s12 的 task 跟 s03 的 todo、s13 的运行时执行有什么本质差别？ | 答出"持久化 vs 会话级 / 依赖图 vs 平面列表 / 工作目标 vs 运行进程" 至少两点 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现 TaskManager + 4 个工具接入 [Required, Weight 70%]
**Prompt**: 在 s02 的 agent loop 上新增任务系统。要求：

- 实现 `TaskManager.create()`、`add_dependency()`、`complete()`、`is_ready()`
- 一任务一文件，存 `.tasks/task_{id}.json`
- 双向维护 `blockedBy` / `blocks`
- `complete()` 完成后自动清理下游 `blockedBy`
- 在 `TOOL_HANDLERS` 里挂 `task_create`、`task_update`、`task_get`、`task_list`，**不修改主循环一行**
- 测试：创建 A→B 依赖，完成 A，验证 B 变为 ready

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | TaskRecord 字段完整 | functional | 7 字段都被持久化 |
| AC-2 | 双向依赖维护 | mechanism | A.blocks 含 B，且 B.blockedBy 含 A |
| AC-3 | 完成自动解锁 | mechanism | A.complete() 后 B.blockedBy 为空 |
| AC-4 | `is_ready()` 正确 | functional | pending + blockedBy 为空 → True；其余 → False |
| AC-5 | 主循环零改动 | mechanism | s02 的 agent loop 代码 diff 为空，仅 `TOOL_HANDLERS` 多四行 |

**Scoring**
- PASS: AC-1/2/3/4 全过 + AC-5 正确
- NEEDS_WORK: 核心 AC 过，AC-5 工具接入有误（允许 1 次返工）
- FAIL: 任何核心 AC 失败

### Task 2: 边界辨析 [Required, Weight 30%]
**Prompt**: 用表格对比 s03 todo、s12 task、s13 runtime task 的 3 个维度：生命周期、数据结构、适用场景。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 生命周期区分正确 | functional | todo=会话内 / task=持久化 / runtime=进程存活期 |
| AC-2 | 数据结构区分正确 | functional | todo=平面列表 / task=依赖图 / runtime=进程句柄+状态 |
| AC-3 | 适用场景各举一例 | functional | 每个维度给出一个具体场景 |

**Scoring**: 三条 AC 都过即 PASS。

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Tasks 都 PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到下一章 (s13)。

## Memory Mnemonic
> 任务不是清单，是图——pending 等依赖，完成就解锁，落盘才持久。

## Navigation
- Previous: [[ErrorRecovery]] (s11)
- Next: [[BackgroundTask]] (s13)
