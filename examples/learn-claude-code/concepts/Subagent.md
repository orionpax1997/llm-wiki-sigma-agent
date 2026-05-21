---
title: "Subagent"
type: concept
tags: [curriculum, subagent, context-isolation, beginner]
sources: [learn.shareai.run-zh-s04, claude.com-blog-subagents-in-claude-code, claude.com-blog-using-claude-code-session-management-and-1m-context]
last_updated: 2026-05-08
---

## Core Thesis
> 子智能体的核心，不是"多一个角色"或"多一个模型实例"，而是**多一个干净上下文**——它首先是一条上下文边界，让局部任务的中间噪声不污染父对话。

## Problem Definition
有了 [[AgentLoop]] + [[ToolRouting]] + [[PlanningState]]，agent 已经能在主循环里维护 `messages` 和计划状态、调用多种工具完成多步任务。但当用户的一句话（"这个项目用什么测试框架？"）触发了一连串中间动作（列目录、grep、读多个文件、跑命令…），所有这些中间过程都会**永久堆在父 `messages` 里**。最终对用户有价值的可能只有一句话（"这个项目主要用 pytest"），但中间噪声会让后续问题越来越难答。

- **学完前**：你只有一个全局 `messages`，每个局部任务的中间过程都污染父对话；你想靠"更长的 system prompt"或"更聪明的模型"硬扛。
- **学完后**：你能让父智能体把局部任务**外包**给一个**拥有独立 `messages`** 的子智能体，子智能体在自己的上下文里干活，做完只把摘要带回；父对话保持干净。

## Terminology
| Term | Definition |
|------|------------|
| 父智能体 (parent agent) | 当前正在和用户对话、持有主 `messages` 的 agent |
| 子智能体 (subagent) | 父智能体临时派生出来、专门处理某个子任务的 agent |
| 上下文隔离 (context isolation) | 父子各有自己的 `messages`，子智能体的中间过程不会自动写回父智能体 |
| task 工具 | 父智能体侧的入口，让模型可以主动说"这个子任务我想交给独立上下文做" |
| 摘要返回 (summary return) | 子智能体做完后，**不**把全部内部历史写回父对话，只返回一段总结作为 `tool_result` |
| fork | 子智能体的进阶模式：不从空白 `messages` 开始，而是先复制父智能体的已有上下文，再追加子任务 prompt |
| max_turns | 子智能体的硬停止条件，防止子智能体无限转 |

## Mental Model
```text
Parent agent
   |
   | 1. 决定把一个局部任务外包出去 (调用 task 工具)
   v
 Subagent (独立 messages、独立工具集、独立 max_turns)
   |
   | 2. 在自己的上下文里读文件 / 搜索 / 执行工具
   v
 Summary (一段简洁结果)
   |
   | 3. 包成 tool_result 回流父智能体
   v
Parent agent continues (父 messages 干净，没被中间过程污染)
```

**关键洞察**：子智能体本质上是一个**独立运行的 [[AgentLoop]] 实例**——只是它的 `messages` 与父智能体隔离。父智能体看不到子智能体的中间步骤，只看到最终的 `tool_result`。

## Minimal Implementation
最小教学版围绕 4 步：

```python
# Step 1: 给父智能体一个 task 工具
TASK_TOOL = {
    "name": "task",
    "description": "Run a subtask in a clean context and return a summary.",
    "input_schema": {
        "type": "object",
        "properties": {"prompt": {"type": "string"}},
        "required": ["prompt"],
    },
}

# Step 2 & 3: 子智能体使用自己的消息列表 + 只拿必要工具
def run_subagent(prompt: str) -> str:
    sub_messages = [{"role": "user", "content": prompt}]
    sub_tools    = [READ_FILE, GREP, BASH_READONLY]   # 不给 task，防递归
    sub_handlers = {...}                              # 与 sub_tools 对应
    max_turns    = 20

    # ——这里就是 s01 的最小 agent loop，喂的是 sub_messages——
    summary = inner_agent_loop(sub_messages, sub_tools, sub_handlers, max_turns)
    return summary

# Step 4: 父智能体侧的 task handler 只把摘要包成 tool_result
TOOL_HANDLERS["task"] = lambda **kw: run_subagent(kw["prompt"])
# 父循环里：
# return {"type": "tool_result", "tool_use_id": block.id, "content": summary_text}
```

关键数据结构（**只记这一个**）：

```python
class SubagentContext:
    messages:  list   # 子智能体自己的上下文
    tools:     list   # 子智能体可以调用哪些工具
    handlers:  dict   # 这些工具到底对应哪些 Python 函数
    max_turns: int    # 防止子智能体无限跑
```

**显式不在本章覆盖**（保留给后续章节或版本 4+）：
- `fork`（继承父上下文起步） — 本章版本 4 提及，仅示意
- 子智能体后台运行 / 异步槽位
- transcript 持久化、worktree 绑定（→ s18）
- 复杂角色系统（explorer / reviewer / planner / tester / implementer，→ s15–s17）
- 多 agent 长期协作协议（→ s15–s17）

## System Position
- **Inherits from**: [[AgentLoop]]（子智能体是独立运行的 agent loop 实例）、[[ToolRouting]]（`task` 复用 dispatch map）
- **Prepares for**: s15–s17 多角色长期协作 / teammate / 任务认领（尚未 ingest）、s18 worktree / 文件系统级隔离（尚未 ingest）
- **Cross-links**: [[PlanningState]] — 父子各自可独立维护过程性状态，互不影响

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把子智能体当成"为了炫技的并发" | 还没有上下文压力时就预先派生多个子智能体；架构复杂但没解决任何问题 | "如果父对话已经很干净，你为什么需要子智能体？" |
| 把父历史全部原样灌回去 | 子智能体跑完，又把它内部历史粘回父 `messages`，隔离价值归零 | "父智能体最终看到的是摘要，还是子智能体的全部历史？" |
| 一上来就做复杂角色系统 | v1 还没跑通，已经在加 explorer/reviewer/planner/tester/implementer | "你能用一个干净上下文 + 一个 prompt 跑通最小子任务吗？" |
| 忘记给子智能体设置停止条件 | 子智能体在工具循环里无限转、烧 token | "你的子智能体有 `max_turns` 吗？工具出错时怎么退出？" |
| 第一个版本就上 fork | 还没跑通空白上下文版，就让子智能体继承父全部 messages | "fork 是 v4，不是 v1。你 v1 跑通了吗？" |

## Diagnostic Questions (Step 1)
1. 子智能体相对于"在父对话里直接做"，唯一的核心好处是什么？
2. `SubagentContext` 的四个字段分别对应什么？少了哪一个会出什么问题？
3. fork 在 4 步实现顺序里是第几步？为什么不能是第一步？
4. 父智能体最终从子智能体那里**不该**收到什么？应该收到什么？
5. 为什么子智能体通常不应该拥有 `task` 工具？

## Question Bank (Step 3b — Socratic)
### Entry-level
- "上下文隔离"具体在代码里体现为哪一行？
- 如果父智能体只问一个简单问题，需要派生子智能体吗？
- 子智能体最后返回的是什么类型的对象？它如何被包进父对话？

### Advanced
- 如果一个子任务必须知道父智能体刚才已经讨论过什么方案（"基于刚才的方案补测试"），空白上下文版本会出什么问题？fork 如何解决？
- 子智能体内部是否也是一个 [[AgentLoop]]？它和父智能体的循环代码是同一段还是两段？
- 如果允许子智能体也持有 `task` 工具，会发生什么？哪些保护机制可以缓解？
- 父智能体的 [[PlanningState]] 应该被复制给子智能体吗？为什么？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 子智能体 = 一个干净的 `messages` + 一个聚焦的 prompt + 摘要回流。 |
| L2 Guide | 想想：如果你在父对话里直接 grep 50 个文件，父 messages 会变成什么样？ |
| L3 Analogy | 子智能体是"装修临时搭的脚手架"——干完活拆掉，只把成品交给业主，工地灰尘不带进客厅。 |
| L4 Deconstruct | 4 步：①父加 `task` 工具 ②子智能体自己的 `messages` ③只给必要工具 ④只回摘要。 |
| L5 Worked Example | 见上方"最小实现"——逐行对照 4 步走，注意 `sub_messages` 是新 list，不是父 messages 的引用。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "子智能体 = 多 agent 系统" | "子智能体的第一价值是多角色协作，还是上下文隔离？" | s04 的子智能体是上下文边界；多角色协作要等到 s15–s17。 |
| "fork 是默认起步方式" | "v1 应该用 fork 还是空白 `messages`？" | fork 是 v4；v1–v3 全部使用空白上下文。 |
| "子智能体应该把过程也告诉父智能体" | "父最终读到的是摘要，还是完整步骤？" | 只读摘要——否则隔离价值归零，父 messages 仍被噪声塞满。 |
| "子智能体必须有完整工具集" | "子智能体需要 `task` 工具吗？" | 通常不给，防止无限递归；只给完成本子任务必需的工具即可。 |
| "子智能体不会无限循环" | "你的子智能体在哪一行决定停下？" | 必须有 `max_turns` 等显式停止条件；模型自己不会主动停。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | `SubagentContext` 的四个字段是什么？ | 完整列出 `messages` / `tools` / `handlers` / `max_turns` |
| Causal | 为什么子智能体不应把内部历史粘回父 `messages`？ | 答出"会让上下文隔离失效，父对话仍被局部任务噪声污染" |
| Application | 写出最小子智能体伪代码：父 `task` 工具 + `run_subagent` 函数 + 摘要回流 | 含 4 步且 `sub_messages` 是新 list、不给 `task` 工具、有 `max_turns` |
| Discrimination | 子智能体（s04）vs 多角色协作（s15–s17）vs 文件系统隔离（s18）三者区别 | 答出"上下文边界 vs 长期角色协作 vs 文件系统层隔离" |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小空白上下文子智能体 [Required, Weight 70%]
**Prompt**: 在 [[AgentLoop]] + [[ToolRouting]] 基础上，给父智能体添加 `task` 工具。父智能体收到 `task` 调用时，启动一个子智能体，子智能体使用**全新的 `messages` 列表**和**裁剪过的工具集**（含 `read_file` / `grep` / 只读 bash，不含 `task`），完成后将摘要作为 `tool_result` 返回。要求：

- 子智能体的 `messages` 必须是新 list，不能是父 `messages` 的引用或副本
- 子智能体的工具集中**不**包含 `task`（防递归）
- 子智能体有显式 `max_turns`，超过则终止并返回当前部分结果
- 父智能体最终的 `messages` 中只看到 `tool_use(task) + tool_result(summary)` 一对，不含子智能体内部历史

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 子智能体使用独立 `messages` | functional | 验证 `id(sub_messages) != id(parent_messages)` 且 sub 不出现 parent 任何条目 |
| AC-2 | 工具集裁剪 | functional | 子智能体的 tools 中无 `task`；尝试调用会被拒绝/忽略 |
| AC-3 | 摘要回流 | functional | 父 messages 末尾仅追加一个 `tool_result`，content 是字符串摘要 |
| AC-4 | `max_turns` 保护 | edge-case | 设置极小 max_turns（如 2）跑可触发上限的 prompt，子智能体应安全终止并返回部分摘要而非崩溃 |
| AC-5 | 父对话不被污染 | mechanism | 任务结束后，父 `messages` 中**不**含子智能体的中间 tool_use / tool_result 块 |

**Scoring**
- PASS: all 5 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4 或 AC-5 缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

### Task 2: fork 模式扩展 [Optional, Weight 30%]
**Prompt**: 在 Task 1 通过后，新增一个 `task_with_context` 工具或参数 `inherit=true`，使子智能体从 `list(parent_messages)` 起步并追加新 prompt。展示一个**必须用 fork 才能正确完成**的子任务（如"基于我们刚才讨论出的方案补测试"），对比空白上下文版的回答差异。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | fork 实现 | functional | `sub_messages = list(parent_messages); sub_messages.append({...prompt...})` |
| AC-2 | 与空白版对比 | mechanism | 同一子任务在两种模式下答案有显著区别，且 fork 版能引用父对话内容 |

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%（Task 2 可加分但不必须）

**On FAIL**: 回到 Tutor Loop，不晋级到 s05。

## Memory Mnemonic
> 子智能体不是多一个角色，是多一个干净上下文。

## Navigation
- Previous: [[PlanningState]] (s03)
- Next: [[SkillSystem]] (s05)
