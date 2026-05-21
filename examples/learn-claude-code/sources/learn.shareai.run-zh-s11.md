---
title: "S11 · 错误恢复 / Error Recovery"
type: source
tags: [curriculum, agent-core, error-recovery, retry-budget, state-machine]
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s11.md
---

## Summary
S11 把 agent 从“报错就崩”升级为“先判断错误类型，再选择恢复路径”。核心模型是：LLM 调用后先分类（输出截断 / 上下文过长 / 临时连接失败），再选动作（续写 / 压缩再试 / 退避重试），每条路径有独立预算。恢复不是 try/except，而是系统知道该怎么续下去。

## Key Claims
- 很多失败不是“任务真的失败了”，而是“这一轮需要换一种继续方式”。
- 恢复 = 先判断是不是临时问题 → 尝试有限次数补救 → 补救失败再明确暴露给用户。
- 三条最小恢复路径：输出截断后续写（`max_tokens` → 注入 `CONTINUE_MESSAGE`）、上下文过长先压缩再重试（`auto_compact`）、连接抖动后退避重试（指数退避 + jitter）。
- 恢复状态 `recovery_state` 给每条路径独立计数，防止无限重试。
- 错误恢复不是外围小功能，而是把 agent 从“能跑”推进到“遇到问题也能继续跑”。

## Key Quotes
> "把‘报错就崩’升级成‘先判断错误类型，再选择恢复路径’。"

> "恢复不是简单 try/except，而是系统知道该怎么续下去。"

> "错误先分类，恢复再执行，失败最后才暴露给用户。"

> "续写提示必须明确告诉模型：不要重复、不要重新总结、直接从中断点接着写。"

> "压缩不是把历史删掉，而是把旧对话从原文变成一份仍然可继续工作的摘要。"

## Connections
- [[AgentLoop]] — 恢复逻辑接在主循环的两个位置：模型调用外层（API/网络错误）和拿到 response 以后（`stop_reason == "max_tokens"`）
- [[ContextCompression]] — s11 的 compact 恢复路径直接复用 s06 的三层压缩机制；s06 讲“什么时候该压缩”，s11 讲“因为失败而恢复”
- [[PromptPipeline]] — s10 的 system prompt 组装为恢复提示（如 `CONTINUE_MESSAGE`）提供了注入点
- [[HookSystem]] — hook 的 `PreToolUse` / `PostToolUse` 可作为恢复日志和恢复动作的统一扩展点
- [[ErrorRecovery]] — s11 的核心概念页（Teaching Concept）

## Contradictions
- （无；s11 与 s01–s10 一致，是能力叠加而非修正）
