---
title: "BackgroundTask"
type: concept
tags: [curriculum, agent-kernel]
sources: [learn.shareai.run-zh-s13]
last_updated: 2026-05-08
---

## Core Thesis
> 后台任务不是另一条主循环，而是主循环"派出去等结果"的执行单元——它跑完以后，结果通过通知队列回到主循环，而不是主循环主动去追。

## Problem Definition
**之前的问题**：慢命令（npm install / pytest / docker build）同步等待会阻塞主循环，模型在等待期间无法继续工作，用户被整轮流程堵住。

**之后的改进**：慢命令在后台线程跑，主循环立刻拿到 `task_id` 继续推进别的事，下一轮模型调用前统一把通知摘要注入 messages。

**Before vs After**：
- Before：发起 → 同步等待 → 返回结果 → 才能做下一件事
- After：发起 → 立刻拿到 task_id → 继续推进 → 下一轮收到通知摘要

## Terminology
| Term | Definition |
|------|------------|
| 前台 | 主循环发起后必须立刻等待结果的执行路径 |
| 后台 | 命令先在另一条执行线跑，主循环先做别的事 |
| 通知队列 | "稍后再告诉主循环"的收件箱，只存摘要不存全文 |
| RuntimeTaskRecord | 后台任务的元数据：`id / command / status / result_preview / output_file` |
| Notification | 通知对象：`type / task_id / status / preview` |

## Mental Model
```
主循环
  +-- background_run("pytest") -> 立刻返回 task_id
  +-- 继续别的工作（调用模型、处理其他工具）
  +-- 下一轮模型调用前
         -> drain_notifications()
         -> 把摘要注入 messages

后台执行线程
  +-- 真正执行 pytest
  +-- 完成后写入通知队列（不只是硬塞全文）
```

**牢记**：并行的是"等待与执行"，不是主循环本身。主循环永远只有一条。

## Minimal Implementation
```python
class BackgroundManager:
    def __init__(self):
        self.tasks = {}          # task_id -> RuntimeTaskRecord
        self.notifications = []  # 待注入主循环的通知
        self.lock = threading.Lock()

    def run(self, command: str) -> str:
        task_id = new_id()
        self.tasks[task_id] = {
            "id": task_id,
            "command": command,
            "status": "running",
        }
        thread = threading.Thread(
            target=self._execute,
            args=(task_id, command),
            daemon=True,
        )
        thread.start()
        return task_id  # 立刻返回，不卡住

    def _execute(self, task_id: str, command: str):
        result = subprocess.run(..., timeout=300)
        status = "completed" if result.returncode == 0 else "failed"
        preview = (result.stdout + result.stderr)[:500]
        with self.lock:
            self.tasks[task_id]["status"] = status
            self.notifications.append({
                "type": "background_completed",
                "task_id": task_id,
                "status": status,
                "preview": preview,
            })

    def drain_notifications(self) -> list:
        with self.lock:
            drained = self.notifications
            self.notifications = []
            return drained

    def before_model_call(self, messages: list):
        notifications = self.drain_notifications()
        if not notifications:
            return
        text = "\n".join(
            f"[bg:{n['task_id']}] {n['status']} - {n['preview']}"
            for n in notifications
        )
        messages.append({"role": "user", "content": text})
```

**deliberately not covered here**：
- 线程池（复用线程管理多任务）
- 任务取消（`task_id` 撤销机制）
- 实时输出流（streaming stdout）
- 任务优先级

## System Position
- Inherits from: [[TaskSystem]]（s12 回答"做什么"，s13 回答"哪个命令正在跑"）
- Prepares for: [[Teammate]]（s15 中长期队友的运行时执行槽位）
- Cross-links: [[ErrorRecovery]]（后台任务失败走错误恢复路径）

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把后台当成另一条主循环 | 以为需要为后台任务再建一套调度/通知/状态管理 | "你的后台任务有自己独立的模型调用吗？" → 是就错了 |
| 只开线程，不登记状态 | 任务一多就不知道谁还在跑、谁已完成、谁失败 | "现在有多少后台任务在跑？" → 答不上来就是错 |
| 把长日志全文塞进上下文 | 上下文很快被撑爆，模型无法继续工作 | "你的通知消息有多长？" → 超过 1KB 就是危险信号 |
| 把 s12 task 和 s13 background task 混为一谈 | 后面多 agent 和调度章节全部打结 | "这个 task 是工作目标还是正在跑的执行单元？" → 分不清就是错 |

## Diagnostic Questions (Step 1)
1. 用户说"后台运行 pytest"，主循环会立刻返回什么？
2. pytest 跑完后，完整结果存哪里？通知里放什么？
3. 如果同时有 3 个后台任务在跑，主循环需要创建几个 agent loop？
4. 后台任务失败时，系统会怎么做？走哪个已有机制处理？

## Question Bank (Step 3b — Socratic)
### Entry-level
- "主循环在 `background_run` 返回后，是继续等待还是继续推进？"（推进）
- "通知队列里的内容，是完整日志还是摘要？"（摘要，完整输出存文件）
- "task_id 是干什么用的？"（唯一标识，用于追踪和 drain）

### Advanced
- "如果后台任务跑了 2 小时才结束，主循环在此期间调用了 50 轮模型，这些轮次里都怎么处理通知？"（每轮前先 drain，注入新通知）
- "BackgroundManager 里的 lock 是什么场景下需要的？"（多线程写 shared state 时保护 notifications list 和 tasks dict）
- "为什么 `before_model_call` 里注入的 role 是 `user` 而不是 `system`？"（它是把外部事件注入为用户消息，模型看到后自然理解为"有新情况需要处理"）

## Hint Escalation Ladder
| Level | Hint |
|-------|------|
| L1 Rephrase | "后台任务的意思是：主循环发起这个命令后，不等它跑完就继续做别的事。" |
| L2 Guide | "主循环拿到 `task_id` 后应该立刻返回，而不是调用 `subprocess.run()` 并 `wait()`。" |
| L3 Analogy | "就像叫外卖：你下单后（发起命令）可以继续做别的事，外卖到了（通知回来）你再处理。" |
| L4 Deconstruct | "拆成两步：1) 后台线程跑命令 2) 通知队列存摘要。你现在卡在哪一步？" |
| L5 Worked Example | "看这个流程：`run('pytest')` → 返回 `task_id='a1b2'` → 继续调用模型 → 下一轮前 `drain_notifications()` → 注入 `[bg:a1b2] completed - 50 tests passed` → 模型决定是否读完整输出" |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "后台就是开一条新的主循环" | "你的后台任务里有自己的 agent loop 吗？" | 后台只有一条执行线程（跑命令），主循环还是一条 |
| "通知应该存完整结果" | "你的通知字典里，preview 字段存的是什么？" | 通知只存摘要（≤500 字符），全文写磁盘 |
| "后台任务和 s12 的 task 是一个东西" | "s12 task 和 s13 background task 回答的是什么问题？" | task 回答"做什么"，background task 回答"哪个命令正在跑" |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 能正确区分"工作目标（s12 task）"和"运行时执行单元（s13 background task）" | 描述不混淆 |
| Causal | 能画出"发起 → 后台执行 → 通知回来 → 模型处理"的完整链路 | 链路完整，顺序正确 |
| Application | 给一个慢命令场景，能设计出合适的 BackgroundManager 接口 | 有 `run(command) -> task_id` 和 `drain_notifications()` |
| Discrimination | 能区分后台任务和 subagent 的使用场景 | 后台任务=慢命令不阻塞；subagent=局部探索性上下文 |

## Practice Tasks (Step 3h)
### Task 1: 实现最小 BackgroundManager [Required, Weight 100%]
**Prompt**: 实现一个 `BackgroundManager` 类，支持：
1. `run(command: str) -> str`：启动后台命令，立刻返回 task_id，不阻塞
2. `drain_notifications() -> list`：取出并清空所有待处理通知
3. `before_model_call(messages: list)`：在模型调用前把通知摘要注入 messages

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | `run()` 立即返回 task_id | functional | 调用后立刻继续执行下一行代码，不等待命令完成 |
| AC-2 | 通知包含 status 和 preview | functional | 通知 dict 包含 `status` 和 `preview` 字段 |
| AC-3 | 完整输出写磁盘 | edge-case | output_file 字段指向一个实际存在的文件 |
| AC-4 | 多线程写入无竞态 | mechanism | 多线程同时 `run()` 后 `drain_notifications()` 结果正确 |

**Scoring**
- PASS: all ACs pass
- NEEDS_WORK: AC-1/AC-2 pass，AC-3/AC-4 边缘问题（1 rework allowed）
- FAIL: AC-1 或 AC-2 失败

## Memory Mnemonic
"后台任务 = 派出去等结果，结果到了通知主循环" — 主循环永远一条，通知队列只存摘要。

## Navigation
- Previous: [[TaskSystem]]
- Next: [[Scheduler]]（s14 定时调度）

---

## Chapter-level Pass Criteria
Learner passes this concept iff:
1. Mastery Check (Step 3g) all dimensions ≥75%
2. Required Task(s) PASS
3. Total practice score ≥75%

**On FAIL**: return to Tutor Loop, do not advance.
