---
title: "Teammate"
type: concept
tags: [curriculum, agent-topology]
sources: [learn.shareai.run-zh-s15]
last_updated: 2026-05-08
---

## Core Thesis
> Teammate 不是"多一个模型调用"，而是"多一个长期存在的执行者"——有名字、有邮箱、有独立循环，下一轮工作时先 drain inbox 接收新任务，而不是被重新创建。

## Problem Definition
**之前的问题**：subagent 只能一次性委派（创建→执行→返回摘要→消失），无法支持"长期待命、反复接任务"的场景。

**之后的改进**：系统 spawn 持久队友 → 写入名册 `.team/config.json` → 每轮 loop 前先读 inbox → 接收消息后继续工作。

## Terminology
| Term | Definition |
|------|------------|
| teammate | 拥有名字、角色、消息入口和独立生命周期的持久 agent |
| 名册 | 团队成员列表 `TeamConfig`，记录 name / role / status，支持持久化 |
| 邮箱 inbox | 每个队友的收件箱（`.team/inbox/{name}.jsonl`），发消息时追加，收消息时 drain |

## Mental Model
```
lead
  +-- spawn alice (coder) → 写入 config.json
  +-- spawn bob (tester) → 写入 config.json
  +-- send message → alice inbox (追加 JSONL)
  +-- send message → bob inbox (追加 JSONL)

alice 的循环
  while True:
    inbox = bus.read_inbox("alice")  # 读 + 清空
    messages += inbox
    response = client.messages.create(...)
    # 执行工具、写结果

bob 的循环
  （同上，独立 messages，独立 inbox）
```

**与 subagent 的根本区别**：
- subagent：`spawn() → 跑 → 返回摘要 → 销毁`
- teammate：`spawn() → 写入名册 → 长期轮询 inbox → 反复接任务 → 不销毁`

## Minimal Implementation
```python
class TeammateManager:
    def __init__(self, team_dir: Path):
        self.team_dir = team_dir
        self.config_path = team_dir / "config.json"
        self.config = self._load_config()

    def spawn(self, name: str, role: str, prompt: str):
        member = {"name": name, "role": role, "status": "working"}
        self.config["members"].append(member)
        self._save_config()
        thread = threading.Thread(
            target=self._teammate_loop,
            args=(name, role, prompt),
            daemon=True,
        )
        thread.start()

    def _teammate_loop(self, name: str, role: str, prompt: str):
        messages = [{"role": "user", "content": prompt}]
        while True:
            inbox = bus.read_inbox(name)
            for item in inbox:
                messages.append({"role": "user", "content": json.dumps(item)})
            response = client.messages.create(messages=messages, ...)
            # 执行 tools ...
```

**deliberately not covered here**：
- 角色策略（哪些任务适合哪些角色）
- 结构化协议请求（shutdown / plan_approval → s16）
- 自治认领空闲任务（→ s17）
- worktree 隔离（→ s18）

## System Position
- Inherits from: [[Subagent]]（上下文隔离思想升级为持久生命周期）
- Prepares for: [[Protocol]]（s16 添加结构化协议请求）
- Prepares for: [[AutonomousAgent]]（s17 添加空闲自治认领）
- Cross-links: [[TaskSystem]]（队友可认领任务板上任务）

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把 teammate 当成"名字不同的 subagent" | 生命周期仍是"执行完就销毁" | "队友被创建后，下次接收任务需要重新 spawn 吗？" → 需要就错了 |
| 队友之间共用同一份 messages | 上下文互相污染 | "alice 的 messages 和 bob 的 messages 是同一个对象吗？" → 是就错了 |
| 没有持久名册 | 系统重启后不知道团队有谁 | "重启后还能找到 alice 的角色信息吗？" → 不能就错 |
| 没有邮箱靠共享变量直接喊话 | 队友通信和进程内部细节耦合 | "消息发送后对方什么时候能读到？" → 说不清就是错 |

## Diagnostic Questions
1. "Alice 现在要接一个新任务，需要重新 spawn 吗？"
2. "Bob 和 Carol 同时在跑，它们各自的 messages 列表是同一个对象吗？"
3. "系统重启后，alice 的邮箱里还有未处理的消息吗？"
4. "teammate 和 subagent 最根本的区别是什么？"

## Memory Mnemonic
"teammate = 有名字+有邮箱+有独立循环+长期存在"；subagent 用完就消失，teammate 长期轮询 inbox。

## Navigation
- Previous: [[Scheduler]]
- Next: [[Protocol]]
