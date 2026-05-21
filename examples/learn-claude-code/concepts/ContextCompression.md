---
title: "ContextCompression"
type: concept
tags: [curriculum, context-compression, prompt-budget, agent-loop, beginner]
sources: [learn.shareai.run-zh-s06, claude.com-blog-using-claude-code-session-management-and-1m-context]
last_updated: 2026-05-08
---

## Core Thesis
> 上下文压缩的核心，不是尽量少字，而是让模型在更短的活跃上下文里，仍然保住继续工作的连续性。

## Problem Definition
有了 [[AgentLoop]] + [[ToolRouting]] + [[PlanningState]] + [[Subagent]] + [[SkillSystem]]，agent 已经会跑主循环、路由工具、维护规划、隔离子任务、按需加载 skill。但随着任务推进，**上下文必然膨胀**：

- 读一个大文件 → 塞进很多文本
- 跑一条长命令 → 得到大段输出
- 多轮任务推进 → 旧结果越堆越多

如果没有压缩机制，会撞上三个问题：

1. 模型注意力被旧结果淹没
2. API 请求越来越重、越来越贵
3. 最终直接撞上上下文上限，任务中断

**学完前**：messages 只能"全量保留"或"硬截断"，前者必撞上限，后者直接砍掉关键决定。
**学完后**：你能用三层机制——持久化大输出 / 微压缩旧结果 / 摘要式完整压缩——在不丢主线连续性的前提下腾出活跃上下文。

## Terminology
| Term | Definition |
|------|------------|
| 上下文窗口 (context window) | 模型这一轮真正能一起看到的输入容量。不是无限。 |
| 活跃上下文 (active context) | 当前这几轮继续工作时最值得模型马上看到的那一部分。**不是历史全部**。 |
| 压缩 (compression) | 用更短的表示方式保留继续工作真正需要的信息。**不是 ZIP 文件压缩**。 |
| Persisted Output Marker | `<persisted-output>` 包住"全文路径 + 预览"，表达"全文没丢，只是搬去磁盘"。 |
| CompactState | 显式压缩状态 `{has_compacted, last_summary, recent_files}`。 |
| Micro-Compact | 把更早的工具结果替换成简短占位（教学版规则："只保留最近 3 个工具结果的完整内容"）。 |
| Summary-Compact | 整体历史过长时，调 LLM 把所有 messages 浓缩成一条连续性摘要消息。 |
| 连续性 (continuity) | 压缩后必须保住的 5 类信息：任务目标 / 已完成动作 / 改过的文件 / 决定 / 下一步。 |

## Mental Model
```text
tool output
   |
   +-- 太大 -----------------> 保存到磁盘 + 留预览       (第 1 层：持久化)
   |
   v
messages
   |
   +-- 太旧 -----------------> 替换成占位提示             (第 2 层：micro-compact)
   |
   v
if whole context still too large:
   |
   v
compact history -> summary                              (第 3 层：summary-compact)
```

**关键洞察**：
- 三层是**预防 / 缓冲 / 兜底**的关系，不是平行选项——能在第 1 层处理就别落到第 3 层。
- 手动触发 `/compact` 或 `compact` 工具，本质上**走的就是第 3 层**。手动压缩与自动压缩**复用同一条机制**。
- 主循环从此长出第二个责任："任务推进 + 上下文预算"。

## Minimal Implementation
最小教学版围绕 5 步：

```python
# Step 1: 大工具结果先写磁盘 + 留预览（第 1 层：持久化）
def persist_large_output(tool_use_id: str, output: str) -> str:
    if len(output) <= PERSIST_THRESHOLD:
        return output
    stored_path = save_to_disk(tool_use_id, output)
    preview = output[:2000]
    return (
        "<persisted-output>\n"
        f"Full output saved to: {stored_path}\n"
        f"Preview:\n{preview}\n"
        "</persisted-output>"
    )

# Step 2: 旧工具结果做微压缩（第 2 层：micro-compact）
def micro_compact(messages: list) -> list:
    tool_results = collect_tool_results(messages)
    for result in tool_results[:-3]:                          # 只保留最近 3 个
        result["content"] = "[Earlier tool result omitted for brevity]"
    return messages

# Step 3: 整体历史过长时做完整压缩（第 3 层：summary-compact）
def compact_history(messages: list) -> list:
    summary = summarize_conversation(messages)
    return [{
        "role": "user",
        "content": (
            "This conversation was compacted for continuity.\n\n"
            + summary
        ),
    }]

# Step 4: 在主循环里接入压缩
def agent_loop(state):
    while True:
        state["messages"] = micro_compact(state["messages"])              # 每轮
        if estimate_context_size(state["messages"]) > CONTEXT_LIMIT:      # 超限
            state["messages"] = compact_history(state["messages"])
            state["has_compacted"] = True
        response = call_model(...)
        ...

# Step 5: 手动压缩复用同一条机制（不要发明第二套）
TOOL_HANDLERS["compact"] = lambda **kw: compact_history(state["messages"])
```

关键数据结构（**记这三个**）：

```python
# Persisted Output Marker —— 全文搬磁盘，上下文里只留预览
"<persisted-output>\nFull output saved to: ...\nPreview: ...\n</persisted-output>"

# CompactState —— 显式压缩状态
{"has_compacted": False, "last_summary": "", "recent_files": []}

# Micro-Compact Boundary —— 教学版简单规则
"只保留最近 3 个工具结果的完整内容；更旧的改成占位提示"
```

**压缩后必须保住的 5 类信息**（这是 `summarize_conversation` 的真正考核点）：
1. 当前任务目标
2. 已完成的关键动作
3. 已修改或重点查看过的文件
4. 关键决定与约束
5. 下一步应该做什么

**显式不在本章覆盖**（保留给后续 / 产品化）：
- 所有产品化压缩技巧大全
- 复杂的优先级 / 重要性评分
- 把 memory（跨会话保留）混进来——s09 才讲
- prompt pipeline 重新注入 / fork 式块管理——s10 才讲
- 压缩不足时的恢复分支——s11 error recovery 才讲

## System Position
- **Inherits from**: [[AgentLoop]]（在主循环里加上下文预算检查；主循环结构本身不变）、[[ToolRouting]]（手动 `compact` 工具复用 dispatch map）
- **Prepares for**: [[Memory]]（s09，"什么信息值得长期保存"——边界邻居：压缩管"会话太长怎么办"，memory 管"跨会话保留什么"）、[[PromptPipeline]]（s10，"哪些块应该重新注入系统输入"）、[[ErrorRecovery]]（s11，"压缩不足时的恢复分支"）
- **Cross-links**: [[Subagent]]（s04 削减**过程性噪声**——先不让它进主上下文；s06 削减**历史累积开销**——已经进了再腾出空间）、[[SkillSystem]]（s05 削减**常驻知识开销** = system prompt 层；s06 削减**历史累积开销** = messages 层；两者正交，共同构成 prompt 预算管理）、[[Memory]]（s09，压缩管本会话太长，memory 管跨会话保留；两者是边界邻居而非同一机制）、[[SessionManagement]]（compaction 是上下文压缩的具体实现，session 管理是压缩决策的外层策略）

## 边界澄清：压缩 vs Memory
| 维度 | 压缩 (Context Compression) | Memory (s09，尚未 ingest) |
|------|---------------------------|--------------------------|
| 解决什么 | 当前会话太长了怎么办 | 哪些信息跨会话仍值得保留 |
| 作用范围 | 单次会话内 | 跨会话 / 跨任务 |
| 关注点 | 活跃上下文预算 | 长期记住的事实 / 偏好 |
| 一句话判断 | "这条信息这一轮还要不要带着？" | "这条信息明天那次会话还想要吗？" |

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 以为压缩 = 删除 | 把旧消息直接 `del`，连决定 / 文件路径都丢了 | "压缩后还能继续干活吗？任务目标 / 改过的文件 / 下一步还在不在？" |
| 只在撞上限后才临时乱补 | 没有第 1 / 第 2 层，每次都等到撞墙才 summary-compact，每次都丢一大块 | "你的三层是同时存在还是只剩第 3 层？大输出有没有先持久化？" |
| 摘要写成一句空话 | `summary = "讨论了代码问题"`——既没文件也没决定也没下一步 | "把这个摘要喂回模型，它能从下一步继续干吗？还是要重新问一遍？" |
| 把压缩和 memory 混成一类 | 把"用户偏好用 pytest"塞进 `compact_history`，或把"刚才命令的输出"塞进 memory | "这条信息是'本会话太长'问题还是'跨会话保留'问题？" |
| 一上来讲过多产品化层级 | v1 还没跑通三层最小机制，已经在搞优先级评分 / 块标签 / 多目标压缩 | "你能先把 persist + micro + summary 三层跑通再加吗？" |

## Diagnostic Questions (Step 1)
1. 上下文窗口、活跃上下文、压缩三个概念各指什么？三者关系是什么？
2. 三层心智模型（持久化 / micro-compact / summary-compact）各处理什么场景？为什么要分三层而不是只用最后一层？
3. 压缩后必须保住的 5 类信息是哪些？少了哪一类，下一轮就接不上了？
4. 手动 `/compact` 和自动压缩为什么能复用同一条机制？这暗示了什么设计取舍？
5. 压缩和 memory 各解决什么问题？同一条信息可不可能既该压缩又该写 memory？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 一段 50KB 的命令输出，第 1 层会怎么处理？模型还能看见它吗？
- `micro_compact` 教学版的规则是什么？为什么是 3 而不是 100？
- `compact_history` 之后 messages 列表里只剩什么？为什么是单条 user 消息？
- `has_compacted=True` 之后，后续轮次还需要再 micro-compact 吗？
- 一个不大的对话（10 条短消息），主循环会触发任何一层压缩吗？应不应该？

### Advanced
- 第 1 层（persist）让模型看到的是 preview，但下一轮如果模型需要原文该怎么办？这暴露了什么后续机制需求？（暗示：read 工具读 stored_path）
- summary-compact 之后，[[PlanningState]] 的 todo / in_progress 如何保住？要不要绕过 LLM 摘要，直接结构化保留？
- 如果 `summarize_conversation` 自身的 LLM 调用又把上下文撑爆，会陷入什么循环？怎么破？
- 子智能体（[[Subagent]]）的局部 messages 是否也需要压缩？如果它生命短，可以省略哪一层？
- 把"压缩历史"和"持久化大输出"放进同一个抽象层是否合理？为什么 s06 把它们拆成"第 1 层 vs 第 3 层"？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 压缩 = 用更短的表示保留继续工作真正需要的信息，不是删除。 |
| L2 Guide | 想三层：大输出别进活跃上下文（持久化）→ 旧结果别一直留（micro-compact）→ 整体太长再总结（summary-compact）。 |
| L3 Analogy | 像办公桌：大文件归档进文件柜 + 桌上贴便签（持久化）→ 一周前的草稿移到抽屉（micro-compact）→ 桌面太乱时整理出一份"近期工作清单"（summary）。 |
| L4 Deconstruct | 5 步：① `persist_large_output` ② `micro_compact` ③ `compact_history` ④ 主循环接入（每轮 micro，超限 summary）⑤ 手动 `compact` 工具复用 step 3。 |
| L5 Worked Example | 见上方"最小实现"——逐行对照，注意 summary 必须保住"任务目标 / 已完成 / 改过的文件 / 决定 / 下一步" 5 类信息。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "压缩就是把字数变少" | "如果摘要只剩一句话但保不住下一步，下一轮模型还能干活吗？" | 字数最少的极端是 `[]`——但 agent 当场失忆。压缩的尺度是连续性，不是字数。 |
| "压缩就是删除旧消息" | "删除和'换一种表示'有什么区别？" | 旧大输出可以变成 `<persisted-output>` 标记 + 磁盘路径——信息没丢，只是搬走了。 |
| "撞上下文上限再补就行" | "撞上限那一刻你还有 token 调 LLM 做摘要吗？" | 撞上限时连 summary 调用都可能塞不下。三层是预防，不是急救。 |
| "压缩和 memory 是一回事" | "本会话太长 vs 跨会话保留——是同一个问题吗？" | 前者是**腾活跃空间**（s06），后者是**长期沉淀**（s09）；混淆会让 memory 被会话噪声淹没。 |
| "手动 `compact` 工具应该有自己一套优雅压缩算法" | "手动和自动到底是不是同一件事？" | 手动只是"用户/模型主动触发同一条机制"；发明第二套立即出现两份会发散的逻辑。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 三层心智模型分别是什么？三个关键数据结构是什么？ | 答出 persist / micro-compact / summary 三层；答出 `<persisted-output>` 标记 / `CompactState` 字典 / "保留最近 3 个" 规则 |
| Causal | 为什么三层不能简化成"撞上限再 summary"一层？ | 答出"撞上限才补会丢一大块 + summary 调用本身也要 token + 大输出本来就不该进活跃上下文" |
| Application | 写出最小实现：`persist_large_output` + `micro_compact` + `compact_history` + 主循环接入 + 手动 `compact` 工具 | 含 5 步，主循环结构不变，手动与自动复用同一条机制 |
| Discrimination | 给 5 条信息（含会话级 / 跨会话），分类到压缩 vs memory；并指出压缩内三层各处理哪种 | 会话内 → 压缩；跨会话 → memory；持久化处理大输出，micro 处理旧结果，summary 处理整体过长 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现三层最小压缩 + 主循环接入 [Required, Weight 70%]
**Prompt**: 在 [[AgentLoop]] + [[ToolRouting]] 基础上，实现最小上下文压缩：

- 实现 `persist_large_output(tool_use_id, output)`：超过 `PERSIST_THRESHOLD`（教学版可设 8000 字符）的输出写到 `.task_outputs/tool-results/{tool_use_id}.txt`，返回 `<persisted-output>` 标记 + 前 2000 字预览。
- 实现 `micro_compact(messages)`：扫描 `tool_result` 消息，把更早于"最近 3 个"的 content 替换成 `"[Earlier tool result omitted for brevity]"`。
- 实现 `compact_history(messages)`：调 LLM 生成连续性摘要（必须含 5 类信息），返回单条 user 消息。
- 主循环里：每轮先 `micro_compact`；`estimate_context_size > CONTEXT_LIMIT` 时调 `compact_history` 并置 `has_compacted=True`。
- 注册 `compact` 工具，handler 直接调 `compact_history`，复用同一机制。
- 跑一个示例：给 agent 一个会读大文件 + 多轮工具调用的任务，观察持久化标记 / 占位 / summary 是否按预期触发。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 持久化生效 | functional | 超阈值输出写入磁盘文件，messages 中只剩 `<persisted-output>` 标记 + 预览 |
| AC-2 | micro-compact 生效 | functional | 4 个以上 tool_result 时，最早的几个被替换成占位文本，最近 3 个原样保留 |
| AC-3 | summary-compact 保住 5 类信息 | mechanism | 触发后 messages 长度=1，且摘要中可识别"任务目标 / 已完成 / 改过的文件 / 决定 / 下一步" |
| AC-4 | 手动 / 自动复用同一机制 | mechanism | 手动 `compact` 工具与自动触发执行的是**同一个** `compact_history` 函数，无重复实现 |
| AC-5 | 主循环结构未被破坏 | edge-case | `agent_loop` 仍是"micro → 调模型 → 跑工具"主线，只多了一行 `if size > LIMIT: compact_history` |

**Scoring**
- PASS: all 5 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4 或 AC-5 缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

### Task 2: 摘要连续性诊断练习 [Optional, Weight 30%]
**Prompt**: 给定 3 份"压缩后摘要"样本（含好 / 差 / 中等），逐条判断是否保住了 5 类连续性信息；对失败的，写出最小补丁。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 5 类信息检查 | functional | 每份摘要逐条标注 5 类信息是否保住 |
| AC-2 | 修复建议 | mechanism | 对缺失项给出最小补丁（哪类信息从哪条原始消息可以提取） |

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%（Task 2 可加分但不必须）

**On FAIL**: 回到 Tutor Loop，不晋级到 s07。

## Memory Mnemonic
> 压缩不是删历史，是把细节搬走，好让系统继续工作。

## Navigation
- Previous: [[SkillSystem]] (s05)
- Next: [[Permissions]] (s07)
