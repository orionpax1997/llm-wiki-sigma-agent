---
title: "Worktree"
type: concept
tags: [curriculum, agent-topology]
sources: [learn.shareai.run-zh-s18]
last_updated: 2026-05-08
---

## Core Thesis
> Worktree 不是"多开一个目录"，而是把任务和执行目录做显式绑定——让多 agent 并行工作时，每个任务有独立的文件系统空间，彼此互不干扰。

## Problem Definition
**之前的问题**：多 agent 并行时所有人共享主工作目录，两个任务同时改同一个文件、一个任务的改动污染另一个任务的目录、无法单独回看某个任务的改动范围。

**之后的改进**：每个被认领的任务绑定一个 git worktree → 任务记录写入 worktree 字段 → `cwd` 切到对应目录执行命令 → 收尾时显式 keep 或 remove worktree。

## Terminology
| Term | Definition |
|------|------------|
| worktree | 同一仓库的另一个独立检出目录（git worktree 或类比实现） |
| 隔离执行 | 任务 A 在自己的目录里跑，任务 B 在自己的目录里跑，默认不共享未提交改动 |
| 绑定 | 把 task_id 和 worktree 记录明确关联起来 |
| closeout | 收尾动作（keep / remove）和原因，跨任务、worktree、事件三表同时写入 |

## Mental Model
```
任务板（.tasks/）
  负责回答：做什么、谁在做、状态如何

.worktrees/index.json
  负责回答：在哪做、目录在哪、对应哪个任务

两者通过 task_id 连接：
  tasks/task_12.json["worktree"] = "auth-refactor"
  worktrees/index.json[...]["task_id"] = 12
  worktrees/auth-refactor/ ← git worktree 目录
```

**task status vs worktree_state**：
- `status`：这件工作现在是 pending / in_progress / completed
- `worktree_state`：这条执行车道现在是 active / kept / removed / unbound
- 两者可以独立变化：任务可以 completed 但 worktree 仍 kept（保留目录给 reviewer 看）

## Minimal Implementation
```python
# 创建：先 task，再 worktree，同时绑定
task = tasks.create("Refactor auth flow")
worktrees.create("auth-refactor", task_id=task["id"])
tasks.bind_worktree(task["id"], "auth-refactor")
# bind_worktree 同时回写：
#   task["worktree"] = name
#   task["last_worktree"] = name
#   task["worktree_state"] = "active"

# 执行：显式 enter，切 cwd
worktree_enter("auth-refactor")
subprocess.run(command, cwd=worktree_path)  # 隔离执行

# 收尾：显式 closeout
worktree_closeout(name="auth-refactor", action="keep", reason="Need review")
# 或 action="remove"（删除目录）
```

## System Position
- Inherits from: [[AutonomousAgent]]（s17）— 认领任务后才分配 worktree
- Inherits from: [[TaskSystem]]（s12）— task_id 来源
- Cross-links: [[Teammate]]（队友在不同 worktree 里执行不同任务）

## Common Errors
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 有 worktree 但任务记录里没写 worktree 字段 | 任务板无法一眼看出任务在哪个隔离目录 | "从任务板能看出任务在哪个 worktree 里跑吗？" → 不能就是错 |
| 有 task_id 但命令仍在主目录执行 | cwd 没切，worktree 形同虚设 | "pytest 在哪个目录里跑？" → 主目录就是错 |
| 把 worktree_state 和 task status 混成一个字段 | 任务 completed 但 worktree removed 后无法回看 | "任务做完了但想保留目录给 reviewer 看，能做到吗？" → 不能就是错 |
| 删除前不看未提交改动 | 丢失工作成果 | "删除 worktree 前应该检查什么？" → 脏改动就是错 |
| 把 worktree 当长期垃圾堆 | 目录越来越多，状态越来越乱 | "什么时候应该 remove worktree？" → 说不清就是错 |

## Memory Mnemonic
"task=做什么，worktree=在哪做且互不干扰" — 两者分开绑定，收尾显式选 keep/remove。

## Navigation
- Previous: [[AutonomousAgent]]
