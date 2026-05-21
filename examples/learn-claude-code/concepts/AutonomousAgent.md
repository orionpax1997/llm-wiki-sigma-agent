---
title: "AutonomousAgent"
type: concept
tags: [curriculum, agent-topology]
sources: [learn.shareai.run-zh-s17]
last_updated: 2026-05-08
---

## Core Thesis
> 自治不是"让 agent 乱跑"，而是让长期队友在清晰规则下（空闲时检查邮箱和任务板 → 按角色过滤找可认领任务 → 原子加锁认领 → 重注入身份上下文恢复工作）。

## Problem Definition
**之前的问题**：即使有了队友系统，所有任务仍需 lead 手动点名分配，团队规模一大 lead 成为瓶颈。

**之后的改进**：长期队友在 idle 阶段自动扫描任务板 → 过滤可认领任务 → 加锁原子认领 → 重注入身份和任务上下文继续工作。

## Terminology
| Term | Definition |
|------|------------|
| 自治 | 在提前给定规则下，队友自己决定下一步接哪份工作 |
| 认领 | 把原本没人负责的任务标记为"现在由我负责" |
| 空闲阶段 | 队友手头没活但仍活着，随时准备接新任务 |
| claim_role / required_role | 任务角色条件，防止错误队友拿走错误任务 |

## Mental Model
```
WORK 阶段
  -> 执行当前任务
  -> 工作做完或主动 idle

IDLE 阶段
  -> 先看 inbox（有消息 → 回到 WORK）
  -> 再扫描任务板（有 ready task → 认领 → 回到 WORK）
  -> 长时间无事可做 → shutdown

认领条件（必须全部满足）：
  1. status == "pending"
  2. no owner
  3. no blockedBy
  4. 角色匹配 (claim_role / required_role)
```

## Minimal Implementation
```python
def is_claimable_task(task: dict, role: str = None) -> bool:
    return (
        task.get("status") == "pending"
        and not task.get("owner")
        and not task.get("blockedBy")
        and _task_allows_role(task, role)
    )

def idle_phase(name: str, role: str, messages: list) -> bool:
    inbox = bus.read_inbox(name)
    if inbox:
        messages += inbox
        return True  # 有消息，唤醒

    unclaimed = scan_unclaimed_tasks(role)
    if unclaimed:
        task = unclaimed[0]
        with claim_lock:
            # 原子认领
            result = claim_task(task["id"], name, role=role, source="auto")
        ensure_identity_context(messages, name, role, team_name)
        messages.append({"role": "user", "content": f"<auto-claimed>Task #{task['id']}: {task['subject']}</auto-claimed>"})
        return True  # 认领了新任务，唤醒

    return False  # 继续 idle 或 shutdown
```

## System Position
- Inherits from: [[Teammate]]（只有长期队友才能自治）+ [[Protocol]]（协议系统继续存在）
- Inherits from: [[TaskSystem]]（认领的是 s12 工作图任务）
- Prepares for: [[Worktree]]（s18 认领后绑定 worktree 执行车道）
- Cross-links: [[Subagent]]（自治是长期队友，subagent 是一次性委派）

## Common Errors
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 只看 pending，不看 blockedBy | 抢走还未就绪的任务 | "前置任务没完成，这个任务能认领吗？" → 能就错了 |
| 没有认领锁 | 两队友同时抢同一任务 | "两个队友同时扫到同一任务怎么办？" → 没有锁就错了 |
| 空闲阶段只看任务板不看邮箱 | 错过别人明确发给它的消息 | "有人发了消息给 idle 队友，队友会处理吗？" → 不会就是错 |
| 上下文压缩后不重注入身份 | 队友忘记自己是谁 | "alice 的上下文被压缩后，下一轮她还记得自己是谁吗？" → 不记得就是错 |

## Memory Mnemonic
"自治 = 空闲扫描+角色过滤+原子认领+身份重注入" — 不是乱抢，是按规则接活。

## Navigation
- Previous: [[Protocol]]
- Next: [[Worktree]]
