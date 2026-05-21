---
title: "AgentLoop"
type: concept
tags: [curriculum, agent-loop, beginner]
sources: [learn.shareai.run-zh-s01]
last_updated: 2026-05-07
---

## Core Thesis
> Agent Loop 把"模型的动作意图"变成"真实执行结果"，再把结果送回模型继续推理——这条回路就是 agent 从"会说"变成"会做"的根本原因。

## Problem Definition
LLM 本身只会"生成下一段内容"——它不会打开文件、运行命令、观察报错，也不会把工具结果接着用于下一步推理。

- **学完前**：你写一个 LLM 调用，它能"答"，但答完就停；不能基于真实执行结果继续工作。
- **学完后**：你能写一段代码，让模型的工具调用真的被执行，结果被写回消息历史，模型下一轮基于真实观察继续推进任务。

## Terminology
| Term | Definition |
|------|------------|
| loop | 任务未完成时，系统持续重复同一套步骤（不是程序死循环） |
| turn | 一轮 = 发请求 → 读回复 → 若有 tool_use 则执行工具 → 把 tool_result 写回 messages |
| tool_use | 模型在回复 content 中表达的"工具调用意图"，需要由外层代码真正执行 |
| tool_result | 工具执行结果，必须包成消息块写回 messages，让模型下一轮读到 |
| tool_use_id | 标识本条 tool_result 对应模型刚才哪一次工具调用 |
| messages | **不是**聊天展示层；是模型下一轮要读的工作上下文 |
| state | 主循环持续推进时需要带着走的数据（最小版：messages、turn_count、transition_reason） |
| transition_reason | 这一轮结束后为什么还要继续（教学版只用 `"tool_result"` 一种） |
| stop_reason | 模型本轮停止原因；教学版用 `!= "tool_use"` 作为循环退出判据 |

## Mental Model
```text
user message
   |
   v
  LLM
   |
   +-- 普通回答 ----------> 结束
   |
   +-- tool_use ----------> 执行工具
                              |
                              v
                         tool_result
                              |
                              v
                         写回 messages
                              |
                              v
                         下一轮继续
```

**最关键的不是 `while True`，而是**：工具结果必须重新进入消息历史，成为下一轮推理的输入。少了这一步，模型就无法基于真实观察继续工作。

## Minimal Implementation
最小教学版主循环（约 30 行 Python，Anthropic SDK）：

```python
def agent_loop(state):
    while True:
        response = client.messages.create(
            model=MODEL,
            system=SYSTEM,
            messages=state["messages"],
            tools=TOOLS,
            max_tokens=8000,
        )

        state["messages"].append({
            "role": "assistant",
            "content": response.content,
        })

        if response.stop_reason != "tool_use":
            state["transition_reason"] = None
            return

        results = []
        for block in response.content:
            if block.type == "tool_use":
                output = run_tool(block)
                results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": output,
                })

        state["messages"].append({"role": "user", "content": results})
        state["turn_count"] += 1
        state["transition_reason"] = "tool_result"
```

**显式不在本章覆盖**（保留给后续章节）：
- 流式输出 (streaming)
- 重试 / 预算 / 中断恢复
- 上下文压缩（→ s06）
- 权限判断 / Hook（→ s07）
- 多工具路由（→ s02）
- 规划状态（→ s03）
- 错误恢复（→ s11）

## System Position
- **Inherits from**: （无；这是奠基章节，s00 仅是序列总览）
- **Prepares for**: `[[ToolRouting]]` (s02), `[[PlanningState]]` (s03), `[[Subagent]]` (s04), `[[SkillSystem]]` (s05), `[[ContextCompression]]` (s06), `[[Permissions]]` (s07), `[[PromptPipeline]]` (s10), `[[ErrorRecovery]]` (s11) — 后续章节逐章把新能力加入主循环
- **Cross-links**: `s00a-query-control-plane` 描述了更完整的控制面（transition_reason 长成更多种原因的形态）；`[[SessionManagement]]` 补充主循环上下文预算的外层 session 管理策略

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 工具结果只打印不写回 messages | 模型下一轮重复同样的调用，或表现得像没执行过 | "你的 tool_result 真的进入 messages 了吗？" |
| 不保存 assistant 消息到历史 | 上下文断层，模型行为越来越不连贯 | "messages 里有 assistant.content 吗？还是只有 user？" |
| tool_result 没绑 tool_use_id | 模型分不清结果对应哪次调用，可能错配 | "每个 tool_result 是否带了 tool_use_id？" |
| 第一章就堆叠流式 / 并发 / 恢复 / 压缩 | 主线被淹没，学不会回路本身 | "你能只用最小回路把任务跑通吗？" |
| 把 messages 当聊天 UI 展示 | 设计时倾向于"漂亮"而非"完整作为下一轮输入" | "messages 是给用户看的，还是给模型看的？" |

## Diagnostic Questions (Step 1)
1. 为什么 LLM 本身不能被叫做 agent？缺了哪一层？
2. 一轮 (turn) 在最小版本里包含哪四个步骤？顺序如何？
3. tool_result 必须包含哪个字段才能让模型对上号？为什么需要它？
4. 如果只追加 user 消息却忘了 append assistant.content，会发生什么？
5. `stop_reason != "tool_use"` 作为退出判据有什么前提假设？

## Question Bank (Step 3b — Socratic)
### Entry-level
- "loop" 在这里指的是程序死循环吗？如果不是，是什么？
- messages 的角色和聊天 app 的消息列表，最大的区别是什么？
- 当模型回复里既没有文本也没有 tool_use（只是普通 stop），下一步应该做什么？

### Advanced
- 如果一次回复里同时包含 1 个 text block 和 3 个 tool_use block，messages 应该如何 append？results 数组顺序重要吗？
- 教学版仅用 `"tool_result"` 作为 transition_reason，更完整的控制面会扩展出哪些可能的值？（提示：错误、超预算、用户中断……）
- 如果工具执行很慢且需要异步，回路的"同步串行"假设会在哪里崩塌？该怎么改？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | Agent 的本质就一句话：模型 → 工具 → 结果 → 回模型，循环往复。 |
| L2 Guide | 想想：如果工具结果只 print 在终端，模型下一轮看得到吗？ |
| L3 Analogy | messages 是一块共享白板，每一轮所有参与者（模型、工具）都要在上面留下痕迹，下一轮才能接上。 |
| L4 Deconstruct | 一轮分四步：①发请求 ②读回复 ③如有 tool_use 就执行 ④把结果包成 tool_result（带 id）写回 messages。 |
| L5 Worked Example | 见上方"最小实现"30 行代码；逐行对照四步走。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "Agent = 模型很聪明" | "如果模型很聪明但拿不到工具结果，它能干活吗？" | 没有循环层，再强的模型也只能"说"，不能"做"。 |
| "messages 是聊天历史" | "messages 写出来是给谁读的？UI 还是下一轮模型？" | messages 是工作上下文，不是展示层；它的字段排布服务于模型，而非用户。 |
| "stop_reason 是充分判据" | "除了 stop_reason，还有什么会让循环继续或停止？" | 真实系统还要看：错误、预算、用户中断、外部事件——所以才需要显式 transition_reason。 |
| "只有 tool_use 时才需要写回 assistant 回复" | "如果模型只有文本回复，需要 append 到 messages 吗？" | 需要——否则下一轮上下文断层。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 一轮 (turn) 的四个步骤是什么？ | 完整列出 4 步且顺序正确 |
| Causal | 为什么 tool_result 必须写回 messages？只 print 不行吗？ | 答出"模型下一轮要从 messages 读，print 不进入上下文" |
| Application | 写出最小 agent loop 的伪代码（不看课件） | 含 4 步、tool_use_id 正确绑定、退出条件正确 |
| Discrimination | "Agent 的内部循环"和"程序里的死循环 (while True 没出口)"区别在哪？ | 答出"Agent loop 由 stop_reason / state 驱动停止，不是无终止条件" |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小 Agent Loop [Required, Weight 100%]
**Prompt**: 使用 Anthropic SDK 实现最小 agent loop。给定一个 user query 和一组 tools，循环调用模型直到 `stop_reason != "tool_use"`。要求：

- 每轮把 `response.content` 作为 assistant 消息追加到 messages
- 每个 `tool_use` 块都执行对应工具，并把结果包成 `{"type": "tool_result", "tool_use_id": ..., "content": ...}` 写回 messages
- 用一个显式 `state` dict 聚合 `messages` / `turn_count` / `transition_reason`
- 不要引入流式、并发、重试、压缩

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | assistant 回复写回 messages | functional | 每一轮都 append，且 content 是 list (block list) |
| AC-2 | tool_result 含 tool_use_id | functional | id 与对应 tool_use.id 严格一致 |
| AC-3 | 循环退出条件 | edge-case | `stop_reason != "tool_use"` 时立即 return，不再调用模型 |
| AC-4 | state 显式聚合 | mechanism | `messages` / `turn_count` / `transition_reason` 三个 key 都在同一 state dict |
| AC-5 | 同轮多工具 | edge-case | 一轮回复里有多个 tool_use 时，对应多个 tool_result 都 append 到同一条 user 消息 |

**Scoring**
- PASS: all 5 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4 或 AC-5 缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到 [[ToolRouting]]。

## Memory Mnemonic
> Agent 不是"会说"，是"会把现实喂回模型"。

## Navigation
- Previous: （无；本章是序列起点。s00 是课程总览，尚未 ingest）
- Next: [[ToolRouting]] (s02)
