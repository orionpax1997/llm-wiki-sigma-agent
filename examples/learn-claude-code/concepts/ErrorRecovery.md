---
title: "ErrorRecovery"
type: concept
tags: [curriculum, agent-core, error-recovery, retry-budget, state-machine, beginner]
sources: [learn.shareai.run-zh-s11]
last_updated: 2026-05-08
---

## Core Thesis
> 错误先分类，恢复再执行，失败最后才暴露给用户。

## Problem Definition
到了 s10，agent 已经拥有 [[AgentLoop]]、[[ToolRouting]]、[[PlanningState]]、[[Subagent]]、[[SkillSystem]]、[[ContextCompression]]、[[Permissions]]、[[HookSystem]]、[[Memory]]、[[PromptPipeline]]。系统不再是 demo，而是真的在做事的程序。问题随之出现：模型输出写到一半被截断、上下文太长请求直接失败、网络抖动导致 API 超时或限流。如果没有恢复机制，主循环会在第一个错误上直接停住。初学者会误以为"agent 不稳定是模型的问题"。

- **学完前**：你一遇到报错就 `try/except` 包一层，要么全部吞掉，要么全部暴露，agent 一遇问题就崩。
- **学完后**：你能先判断错误类型（输出截断 / 上下文过长 / 临时连接失败），再选择对应恢复路径（续写 / 压缩再试 / 退避重试），每条路径有独立预算，系统知道该怎么续下去。

## Terminology
| Term | Definition |
|------|------------|
| 恢复 (recovery) | 先判断是不是临时问题 → 尝试有限次数补救 → 补救失败再明确暴露给用户 |
| 重试预算 (retry budget) | "最多试几次"；防止无限循环。如续写最多 3 次、网络重连最多 3 次 |
| 状态机 (state machine) | 主循环从"普通执行"变成在多个明确状态（正常 / 续写恢复 / 压缩恢复 / 退避重试 / 最终失败）之间按规则切换 |
| 续写 (continuation) | 输出被 `max_tokens` 截断时，注入 `CONTINUE_MESSAGE` 让模型从中断点继续，不重复 |
| 压缩恢复 (compact recovery) | 上下文过长导致请求失败时，先 `auto_compact` 再重试 |
| 退避重试 (backoff retry) | 网络 / 超时 / 限流等临时错误时，等一会儿（指数退避 + jitter）再试 |
| `recovery_state` | 显式状态字典 `{continuation_attempts, compact_attempts, transport_attempts}`，各路径独立计数 |
| `choose_recovery` | 恢复决策函数：把"错误长什么样"和"接下来怎么做"分开 |
| `CONTINUE_MESSAGE` | 续写提示：明确告诉模型不要重来、不要重复、直接从中断点接着写 |

## Mental Model
```text
LLM call
  |
  +-- stop_reason == "max_tokens"
  |      -> 注入 CONTINUE_MESSAGE
  |      -> continuation_attempts += 1
  |      -> 再试一次（预算 ≤3）
  |
  +-- prompt too long / context too large
  |      -> auto_compact(messages)
  |      -> compact_attempts += 1
  |      -> 再试一次（预算 ≤3）
  |
  +-- timeout / rate limit / transient API error
         -> backoff_delay(attempt)
         -> transport_attempts += 1
         -> 再试一次（预算 ≤3）
         -> 仍失败 → 最终失败，暴露给用户
```

**关键洞察**：
- 恢复不是 try/except 包一层，而是**先分类、再选动作、每条动作有独立预算**。
- 三条路径各算各的次数，互不干扰。
- 续写提示必须明确约束模型行为（不要重复、不要重新总结），否则模型会从头再来。
- 压缩后必须告诉模型"这是续场"，否则模型可能重新向用户提问。

## Minimal Implementation
最小教学版围绕 3 步：

```python
# Step 1: 恢复选择器 —— 把错误分类和恢复动作分开
CONTINUE_MESSAGE = (
    "Output limit hit. Continue directly from where you stopped. "
    "Do not restart or repeat."
)

def choose_recovery(stop_reason: str | None, error_text: str | None) -> dict:
    if stop_reason == "max_tokens":
        return {"kind": "continue", "reason": "output truncated"}
    if error_text and "prompt" in error_text and "long" in error_text:
        return {"kind": "compact", "reason": "context too large"}
    if error_text and any(word in error_text for word in [
        "timeout", "rate", "unavailable", "connection"
    ]):
        return {"kind": "backoff", "reason": "transient transport failure"}
    return {"kind": "fail", "reason": "unknown or non-recoverable error"}

# Step 2: 退避延迟 —— 指数退避 + jitter
def backoff_delay(attempt: int) -> float:
    return min(1.0 * (2 ** attempt), 30.0) + random.uniform(0, 1)

# Step 3: 接入主循环 —— 两个位置（调用外层 + 拿到 response 后）
def agent_loop(state):
    recovery_state = {
        "continuation_attempts": 0,
        "compact_attempts": 0,
        "transport_attempts": 0,
    }
    while True:
        try:
            response = client.messages.create(...)
            decision = choose_recovery(response.stop_reason, None)
        except Exception as e:
            response = None
            decision = choose_recovery(None, str(e).lower())

        if decision["kind"] == "continue":
            if recovery_state["continuation_attempts"] >= 3:
                return "Error: output recovery exhausted"
            recovery_state["continuation_attempts"] += 1
            messages.append({"role": "user", "content": CONTINUE_MESSAGE})
            continue

        if decision["kind"] == "compact":
            if recovery_state["compact_attempts"] >= 3:
                return "Error: compact recovery exhausted"
            recovery_state["compact_attempts"] += 1
            messages = auto_compact(messages)
            continue

        if decision["kind"] == "backoff":
            if recovery_state["transport_attempts"] >= 3:
                return "Error: transport recovery exhausted"
            recovery_state["transport_attempts"] += 1
            time.sleep(backoff_delay(recovery_state["transport_attempts"]))
            continue

        if decision["kind"] == "fail":
            break

        # 正常工具处理
```

**显式不在本章覆盖**（保留给后续章节 / 控制平面桥接文档）：
- 更大的 query 续行模型（transition_reason 扩展为更多状态值）
- 预算续行（token 预算耗尽后的策略）
- hook 介入恢复流程（s08 的 HookSystem 可作为扩展点）
- 多 agent 场景下的分布式错误恢复
- 持久化恢复状态（跨会话记住"上次卡在哪"）

## System Position
- **Inherits from**: [[AgentLoop]]（恢复逻辑接在主循环的两个位置）、[[ContextCompression]]（compact 恢复路径复用 s06 的三层压缩）、[[PromptPipeline]]（`CONTINUE_MESSAGE` 作为临时 reminder 注入 system prompt / messages）
- **Prepares for**: [[TaskSystem]] (s12)、s13–s14 运行时执行与编排（恢复机制保护复杂任务流不被单次失败打断）
- **Cross-links**: [[HookSystem]]（hook 可在固定时机记录恢复日志或介入恢复动作）、[[Permissions]]（权限拒绝与不可恢复错误的区分——权限拒绝是"正常决策结果"，不是"错误"）

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把所有错误都当成一种错误 | 该续写的去压缩、该等待的去重试、该失败的却无限拖延 | "你的恢复逻辑有没有先分类？" |
| 没有重试预算 | 主循环永远卡在"继续""继续""继续" | "continuation_attempts 有上限吗？" |
| 续写提示写得太模糊 | 模型重新总结、重新开头、重复已输出内容 | "你的 CONTINUE_MESSAGE 明确说了'不要重复'吗？" |
| 压缩后没有告诉模型"这是续场" | 模型重新向用户提问，任务断掉 | "压缩后的摘要里有没有'This session was compacted'这类提示？" |
| 恢复过程完全没有日志 | 读者看不见主循环到底做了什么 | "你有没有打印 `[Recovery] continue/compact/backoff`？" |

## Diagnostic Questions (Step 1)
1. 恢复和 try/except 的本质区别是什么？
2. 三条恢复路径分别对应什么错误类型？为什么必须分三条而不是一条？
3. `recovery_state` 为什么要给每条路径独立计数？
4. `CONTINUE_MESSAGE` 为什么要明确说"不要重复"？
5. 退避重试为什么要"等一会儿"而不是立刻再打？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 什么叫"恢复"？是不是把所有错误都藏起来？
- 三条恢复路径分别是什么？各有什么预算？
- `choose_recovery` 的作用是什么？为什么要把"分类"和"动作"分开？
- 如果 `stop_reason == "max_tokens"`，主循环应该做什么？

### Advanced
- 如果 `auto_compact` 本身也失败（比如 summary 调用也超时），系统会进入什么状态？怎么破？
- 权限拒绝（s07）应该走恢复路径吗？为什么？
- hook 系统（s08）可以在恢复的哪些时机介入？能做什么？
- 如果把 `recovery_state` 持久化到磁盘，跨会话恢复会有什么新能力？有什么风险？
- [[TaskSystem]] 的持久化任务图与错误恢复如何协同？任务执行失败时，恢复路径应更新任务状态还是仅保护主循环？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 恢复 = 先分类错误，再选动作，每条动作有预算。 |
| L2 Guide | 想想：如果不分类，所有错误都用同一种方式处理，会出现什么问题？ |
| L3 Analogy | 像看病：先诊断（分类）→ 再开药（选动作）→ 药有疗程（预算）→ 治不好再转院（暴露给用户）。 |
| L4 Deconstruct | 三步：① `choose_recovery` 分类 ② 按 kind 选分支 ③ 每条分支检查预算、执行动作、继续循环。 |
| L5 Worked Example | 见上方"最小实现"代码块；逐行对照，注意 `recovery_state` 的独立计数和 `CONTINUE_MESSAGE` 的约束。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "恢复 = 把所有错误藏起来" | "如果补救 3 次都失败，系统会怎么做？" | 恢复明确暴露失败给用户，不是无限兜底。 |
| "try/except 包一层就够了" | "你的 except 里做了什么？是统一打印还是分类处理？" | 统一吞掉会导致该续写的去压缩、该等待的去重试。 |
| "续写提示写'continue'就够了" | "模型看到'continue'后会怎么做？" | 模型经常重新总结或重复；必须明确约束"不要重复、直接从中断点写"。 |
| "压缩恢复 = 删掉旧消息" | "压缩后模型还能继续工作吗？" | 压缩是"换一种更短的表示"，不是删除；必须保住任务目标 / 已完成 / 决定 / 下一步。 |
| "退避重试是浪费时间" | "如果立刻重打，成功率会更高吗？" | 临时拥堵时立刻重试只会加剧失败；等一会儿让服务器恢复。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 三条恢复路径分别是什么？对应什么错误类型？ | 答出 continue/compact/backoff 及对应场景 |
| Causal | 为什么恢复必须先分类再执行？统一 try/except 有什么问题？ | 答出"不同错误需要不同补救动作，统一处理会错配" |
| Application | 写出最小 `choose_recovery` + 主循环接入 + 预算检查 | 含 3 条分支、独立预算、明确失败暴露 |
| Discrimination | 权限拒绝（s07）应该走恢复路径吗？为什么？ | 答出"权限拒绝是正常决策结果，不是临时错误，不应重试" |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小错误恢复 + 主循环接入 [Required, Weight 100%]
**Prompt**: 在 [[AgentLoop]] + [[ContextCompression]] 基础上，实现错误恢复：

- 实现 `choose_recovery(stop_reason, error_text)`，返回 `{"kind": "continue"|"compact"|"backoff"|"fail", "reason": ...}`
- 实现 `CONTINUE_MESSAGE`，明确约束模型不要重复、直接从中断点继续
- 实现 `backoff_delay(attempt)`，指数退避 + jitter，上限 30 秒
- 主循环里：
  - 模型调用外层捕获 Exception，走 `backoff` 或 `fail`
  - 拿到 response 后检查 `stop_reason == "max_tokens"`，走 `continue`
  - 上下文过长错误走 `compact`（复用 s06 的 `auto_compact`）
- 每条路径独立预算（最多 3 次），超限后明确返回错误给用户
- 打印 `[Recovery] <kind>` 日志

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 恢复分类正确 | functional | 3 种错误类型分别映射到 continue/compact/backoff |
| AC-2 | 续写提示约束明确 | functional | `CONTINUE_MESSAGE` 含"不要重复"或"直接从中断点继续"等价语义 |
| AC-3 | 预算检查生效 | mechanism | 每条路径最多 3 次，第 4 次返回明确错误 |
| AC-4 | 退避延迟合理 | mechanism | 指数增长 + 随机 jitter，上限 ≤30 秒 |
| AC-5 | 恢复日志打印 | functional | 每次恢复动作打印 `[Recovery] <kind>` |
| AC-6 | 主循环结构未被破坏 | edge-case | 正常工具处理分支仍在恢复分支之后，循环结构不变 |

**Scoring**
- PASS: all 6 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4/5/6 部分缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到 [[TaskSystem]] (s12)。

## Memory Mnemonic
> 错误先分类，恢复再执行，失败最后才暴露给用户。

## Navigation
- Previous: [[PromptPipeline]] (s10)
- Next: （s12，尚未 ingest）
