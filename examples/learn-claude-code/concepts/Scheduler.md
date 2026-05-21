---
title: "Scheduler"
type: concept
tags: [curriculum, agent-kernel]
sources: [learn.shareai.run-zh-s14]
last_updated: 2026-05-08
---

## Core Thesis
> 调度器不是另一套 agent，而是一个"记住未来意图、等时间到了注入通知队列"的定时触发器——最终仍回到同一条主循环。

## Problem Definition
**之前的问题**：如果用户说"每天早上 9 点跑报告"，系统只能当下立刻执行，无法安排未来工作。

**之后的改进**：系统把这条意图记为 ScheduleRecord，定时检查器每分钟扫描一次，匹配时把 prompt 注入通知队列，主循环下一轮处理。

## Terminology
| Term | Definition |
|------|------------|
| 调度器 | 专门负责"看时间、查任务、决定是否触发"的代码 |
| ScheduleRecord | 调度记录：`id / cron / prompt / recurring / durable / last_fired_at` |
| cron 表达式 | 5 字段定时规则：`分 时 日 月 周`（例：`0 9 * * 1` = 每周一 9 点） |
| 持久化调度 | 重启后调度记录仍在，不依赖内存 |

## Mental Model
```
schedule_create("0 9 * * 1", "Run weekly report")
  -> 写入文件或列表
  -> 定时检查器每分钟遍历
  -> 匹配时发通知到队列
  -> 主循环 drain 队列
  -> 注入 [scheduled:job_001] Run weekly report
  -> 模型决定怎么处理
```

## Minimal Implementation
```python
class Scheduler:
    def __init__(self, jobs: list = None):
        self.jobs = jobs or []  # 持久化存储
        self.queue = queue.Queue()

    def create(self, cron_expr: str, prompt: str, recurring: bool = True):
        job = {
            "id": new_id(),
            "cron": cron_expr,
            "prompt": prompt,
            "recurring": recurring,
            "created_at": time.time(),
            "last_fired_at": None,
        }
        self.jobs.append(job)
        return job

    def check_loop(self):
        while True:
            now = datetime.now()
            self.check_jobs(now)
            time.sleep(60)

    def check_jobs(self, now):
        for job in self.jobs:
            if cron_matches(job["cron"], now):
                self.queue.put({
                    "type": "scheduled_prompt",
                    "schedule_id": job["id"],
                    "prompt": job["prompt"],
                })
                job["last_fired_at"] = now.timestamp()

    def drain(self) -> list:
        items = []
        while not self.queue.empty():
            items.append(self.queue.get())
        return items
```

## System Position
- Inherits from: [[BackgroundTask]]（共享通知队列，主循环结构不变）
- Prepares for: [[Teammate]]（定时触发队友行为）
- Cross-links: [[TaskSystem]]（调度记录和任务记录不是同一张表）

## Common Errors
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 沉迷 cron 语法细节 | 记住了很多表达式规则，但不理解触发后的流程 | "cron 匹配后下一步是什么？" → 答不上来就是理解偏了 |
| 没有 last_fired_at | 短时间内重复触发同一任务 | "同一调度任务在一分钟内会触发几次？" → 大于 1 就是错 |
| 只放内存不放盘 | 程序重启后调度记录丢失 | "关掉程序再打开，之前创建的调度还在吗？" → 不在就是错 |
| 触发后直接后台默默执行 | 用户不知道系统什么时候做了什么 | "时间到了以后，用户怎么知道有事情发生了？" → 没有显式通知就是错 |

## Mastery Check
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 能区分"调度记录"和"任务记录"不是同一张表 | 描述不混淆两者 |
| Causal | 能画出"创建 → 定时检查 → 通知注入 → 主循环处理"完整链路 | 链路完整 |
| Application | 能为一个定时场景设计 ScheduleRecord | 有 id/cron/prompt/recurring/durable/last_fired_at |
| Discrimination | 能区分调度触发和后台任务的使用场景 | 调度=等开始，后台=等结果 |

## Memory Mnemonic
"调度 = 记住未来等开始，后台 = 派出去等结果" — 两者都走通知队列回主循环。

## Navigation
- Previous: [[BackgroundTask]]
- Next: [[Teammate]]
