---
title: "QueryTransitionModel"
type: concept
tags: [reference, query-control, transition-reason]
sources: [learn.shareai.run-zh-s00c-query-transition-model]
last_updated: 2026-05-08
---

## Definition
6 种 transition reason 分类体系：每种"继续下一轮"的原因都有独立的状态修改和独立预算，不能混成同一种路径。

## Key Claims
- transition 不是"消息内容"而是"流程原因"，是给系统自己看的，不是给模型的消息
- continuation 不是无限制的，每种路径都需要独立 budget（最多续写几次/最多压缩重试几次）
- 不把这些"继续原因"从一开始拆开，会导致日志不清、测试难写、教学心智模糊
- 正常主线继续 vs 错误恢复继续 vs 压缩后重试，不应该被混成同一种路径

## Transition Reason Taxonomy
| Reason | Description | Typical State Update |
|--------|-------------|---------------------|
| `tool_result_continuation` | 正常主线：工具执行完，结果喂回模型 | messages append tool_result, turn_count++ |
| `max_tokens_recovery` | 输出截断：注入 CONTINUE_MESSAGE，重试 | continuation_count++, inject continue message |
| `compact_retry` | 上下文压缩后：重试本轮 | has_attempted_compact=True |
| `transport_retry` | 网络抖动：退避后重试 | transport_attempts++ |
| `stop_hook_continuation` | hook 阻止本轮结束 | stop_hook_active=True |
| `budget_continuation` | 系统主动利用预算继续 | budget check passed |

## Connections
- [[QueryControlPlane]] — transition 是 QueryState 的核心字段之一
- [[ErrorRecovery]] — s11 的三条恢复路径对应三种 transition
- [[ContextCompression]] — 压缩后重试对应 compact_retry
