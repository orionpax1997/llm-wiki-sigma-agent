---
title: "Protocol"
type: concept
tags: [curriculum, agent-topology]
sources: [learn.shareai.run-zh-s16]
last_updated: 2026-05-08
---

## Core Thesis
> 协议消息不是普通聊天，而是带 request_id + 状态机的结构化请求——它回答的不是"说了什么"，而是"这件事现在走到哪一步了"。

## Problem Definition
**之前的问题**：团队里所有消息都是自由文本，shutdown / plan_approval 等关键动作无法被系统可靠追踪，多个请求同时存在时无法确定"这条回复对应哪一件事"。

**之后的改进**：关键动作用 ProtocolEnvelope 包装 → 写入 RequestRecord → 追踪 pending → approved/rejected/expired。

## Terminology
| Term | Definition |
|------|------------|
| 协议 | 双方提前约定好"消息长什么样、收到以后怎么处理" |
| request_id | 请求编号，使多个请求可以精确匹配各自的响应 |
| 协议消息 | 带 type / request_id / from / to / payload 的结构化消息 |
| 普通消息 | 自由文本，只回答"说了什么" |

## Mental Model
```
发起请求
  -> 写入 RequestRecord (pending)
  -> 投递 ProtocolEnvelope 进对方 inbox
  -> 对方下一轮 drain inbox
  -> 按 request_id 更新请求状态 (approved/rejected)
  -> 必要时回一条 response
  -> 请求方根据 approved/rejected 继续后续动作
```

**普通消息 vs 协议消息**：
- 普通消息适合：讨论、提醒、补充说明
- 协议消息适合：审批、关机、交接、签收

## Minimal Implementation
```python
# 发起协议请求
def request_shutdown(target: str):
    request_id = new_id()
    requests[request_id] = {
        "kind": "shutdown",
        "target": target,
        "status": "pending",
    }
    bus.send(
        "lead", target,
        msg_type="shutdown_request",
        extra={"request_id": request_id},
        content="Please shut down gracefully.",
    )

# 处理协议响应
def handle_response(request_id: str, approve: bool):
    record = requests[request_id]
    record["status"] = "approved" if approve else "rejected"
```

## Four-Object Boundary
| 对象 | 回答什么问题 | 典型字段 |
|---|---|---|
| MessageEnvelope | 谁跟谁说了什么 | from / to / content |
| ProtocolEnvelope | 这是不是结构化请求 | type / request_id / payload |
| RequestRecord | 这件协作流程走到哪步 | kind / status / from / to |
| TaskRecord | 真正的工作项是什么 | subject / status / blockedBy / owner |

**协议请求不是任务本身，请求状态表也不是任务板。**

## System Position
- Inherits from: [[Teammate]]（协议建立在队友邮箱系统之上）
- Prepares for: [[AutonomousAgent]]（s17 自治队友仍需要协议的可追踪性）
- Cross-links: [[TaskSystem]]（协议≠任务；协议管协作流程，任务管工作推进）

## Common Errors
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 没有 request_id | 多个请求同时存在时无法匹配响应 | "收到回复后怎么知道它对应哪个请求？" → 说不清就是错 |
| 收到请求只回自然语言 | 系统无法稳定处理 | "机器怎么能可靠识别这是协议响应？" → 靠文本匹配就错了 |
| 没有请求状态表 | pending/approved/rejected 无法追踪 | "现在有哪些请求正在等待？" → 说不清就是错 |
| 把协议消息和普通消息混成一种结构 | 处理逻辑越来越混 | "普通 inbox 消息和协议消息是同一种数据结构吗？" → 是就错了 |

## Memory Mnemonic
"普通消息=说了什么，协议消息=走到哪一步" — 协议=结构化+request_id+状态机。

## Navigation
- Previous: [[Teammate]]
- Next: [[AutonomousAgent]]
