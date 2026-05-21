---
title: "S09 · 持久状态 / Memory"
type: source
tags: [agent-core, memory, persistence, cross-session, curriculum]
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s09.md
---

## Summary
S09 讲授 agent 的跨会话持久记忆系统。核心原则：memory 不是"什么都存"，而是只保存"跨会话仍有价值、且不能轻易从当前仓库状态直接推出来"的信息。定义 4 类 memory（user / feedback / project / reference），给出最小实现（单条文件 + MEMORY.md 索引 + save_memory 工具 + 会话启动重载），并澄清 memory 与 task / plan / CLAUDE.md 的边界。最后列出 6 条从教学版到高完成度版必须补全的边界（作用域分层、正负反馈、用户要求也不能直接存的东西、漂移核对、用户忽略指令、推荐前再验证）。

## Key Claims
- 如果 agent 每次新会话都从零开始，就会不断重复忘记用户长期偏好、纠正过的错误、项目约定、外部资源位置——显得"每次都像第一次合作"。
- memory 不是"把一切有用信息都记下来"；这样做会让 memory 变成垃圾堆，且 agent 会依赖过时记忆而非当前真实状态。
- 只有那些跨会话仍然有价值、且不能轻易从当前仓库状态直接推出来的信息，才适合进入 memory。
- 最适合先教的 4 类 memory：user（用户偏好）、feedback（用户纠正）、project（不易从代码看出的项目约定）、reference（外部资源指针）。
- 代码结构、当前任务进度、临时分支名、具体代码细节、密钥凭证——这些东西**不该**存进 memory。
- memory 用来提供方向，不用来替代当前观察；如果 memory 和当前代码状态冲突，优先相信真实状态。
- 更完整系统里 memory 至少分 `private`（个人）和 `team`（团队）两个作用域。
- feedback 不只来自负反馈，也要保存被验证有效的正反馈做法。
- 用户说"忽略 memory"时，系统应**按 memory 为空来工作**，而不是嘴上忽略、实际继续用。
- 推荐具体路径 / 函数 / URL 前，应先用 memory 指引方向，再核对当前状态，最后给用户结论。

## Key Quotes
> "只有那些跨会话仍然有价值，而且不能轻易从当前仓库状态直接推出来的信息，才适合进入 memory。"

> "memory 用来提供方向，不用来替代当前观察。"

> "feedback 不只来自负反馈，也来自被验证的正反馈。"

> "memory 保存的是'以后还可能有价值、但当前代码里不容易直接重新看出来'的信息。"

## Connections
- [[AgentLoop]] — memory 在会话开始时重新加载，拼成 memory section 注入系统输入
- [[ContextCompression]] — 边界邻居：压缩管"本会话太长怎么办"，memory 管"跨会话保留什么"
- [[SkillSystem]] — 边界邻居：skill 是"某类任务才需要的可选知识"，memory 是"跨会话记住的事实"
- [[PlanningState]] — 边界邻居：plan 是"这一轮怎么做"，task 是"当前工作进度"，memory 是"以后还有用"
- [[HookSystem]] — s08 的 hook 时机可用于 memory 保存/加载的触发点
- s10 的 message prompt pipeline — memory 真正重要的是它怎样重新进入下一轮输入
- s11 [[ErrorRecovery]] — memory 漂移和过时信息是错误恢复要处理的场景之一

## Contradictions
- （无；s09 与已 ingest 内容一致，边界关系已由 s06 预先声明）
