---
title: "S16 · 协作协议 / Protocol System"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s16.md
---

## Summary
s16 在 s15 邮箱基础上增加结构化协议：把某些关键消息（shutdown / plan_approval）从自由文本升级为带 request_id 和状态机的结构化请求。协议消息和普通消息不是一回事——普通消息解决"说了什么"，协议消息解决"这件事走到哪一步了"。

## Key Claims
- 协议 = 双方提前约定好"消息长什么样、收到以后怎么处理"
- 协议消息必须有 type / request_id / from / to / payload
- RequestRecord（请求状态表）跟踪 pending → approved / rejected / expired
- shutdown 和 plan_approval 本质上是同一个协议模板的两个实例

## Key Data Structures
- **ProtocolEnvelope**: `type / from / to / request_id / payload / timestamp`
- **RequestRecord**: `request_id / kind / from / to / status` → `.team/requests/{request_id}.json`
- 状态机：`pending → approved / rejected / expired`

## Four Object Distinction
| 对象 | 回答什么问题 | 典型字段 |
|---|---|---|
| MessageEnvelope | 谁跟谁说了什么 | from / to / content |
| ProtocolEnvelope | 这是不是结构化请求或响应 | type / request_id / payload |
| RequestRecord | 这件协作流程现在走到哪一步 | kind / status / from / to |
| TaskRecord | 真正的工作项是什么、谁在做、还卡着谁 | subject / status / blockedBy / owner |

## Connections
- 继承自 [[Teammate]]（s15）— 协议建立在队友邮箱系统之上
- 为 [[AutonomousAgent]]（s17）提供协议保底——自治队友仍需要结构化请求的可追踪性
- 与 [[TaskSystem]]（s12）区分：协议负责"协作流程"，任务系统负责"工作推进"
