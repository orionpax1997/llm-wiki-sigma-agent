---
title: "PlanningState"
type: concept
tags: [curriculum, planning-state, todo, active-step, beginner]
sources: [learn.shareai.run-zh-s03]
last_updated: 2026-05-07
---

## Core Thesis
> `PlanningState` 是 agent 主循环里**第二块显式状态**——把"当前要做什么"从模型脑内搬到系统可观察的状态里，让长任务不再漂。

## Problem Definition
有了 [[AgentLoop]] + [[ToolRouting]]，agent 已经会读文件、写文件、跑命令。但跑多步任务时，立刻冒出三类问题：

- 走一步忘一步
- 重复已做过的检查
- 一口气列十几步，几轮后又回到即兴发挥

根因不是模型笨，而是**模型当前的注意力始终受上下文影响**。如果没有一块**显式、稳定、可反复更新**的计划状态，长任务必然失焦。

- **学完前**：你的 agent 在多步任务中频繁漂移；你想靠"写更长 system prompt"来管住它。
- **学完后**：你能在主循环里维护一块外显的、随任务推进不断重写的计划状态，并通过单 `in_progress` 约束 + reminder 让模型持续聚焦下一步。

## Terminology
| Term | Definition |
|------|------------|
| 会话内规划 (in-session planning) | 只服务**当前这次请求**的轻量计划；不是长期项目管理，不是磁盘任务系统 |
| todo | 模型用来写入当前计划的一条入口；本章教学版里就是一个工具名 |
| PlanItem | 一条计划项的最小结构：`{content, status, activeForm}` |
| status | 三态枚举：`pending` / `in_progress` / `completed` |
| activeForm | 进行时描述，例如 "Reading the failing test"；展示更自然 |
| active step | 当前正在做的那一步（即唯一 `in_progress` 的 PlanItem） |
| PlanningState | 整体规划状态：`{items, rounds_since_update}` |
| rounds_since_update | 自上次计划更新以来连续过去了多少轮 |
| reminder | 当 `rounds_since_update` 超阈值时，主循环注入的 `<reminder>` 文本 |

## Mental Model
```text
用户提出大任务
      |
      v
模型先写一份当前计划 (todo update)
      |
      v
PlanningState
  [ ] pending      还没做
  [>] in_progress  正在做  (同时最多一个)
  [x] completed    已完成
      |
      v
每做完一步 -> 整份重写计划 (status 推进)
      |
      v
若连续 N 轮没更新 -> 主循环注入 <reminder>
```

**关键升级：主循环现在维护两块状态，不只是对话——**
```text
messages         -> 模型看到的历史
planning state   -> 当前计划的显式外部状态
```

## Minimal Implementation
"130 LOC 边界"：`TodoManager` + dispatch 接入 + reminder 注入。**显式不覆盖**：任务依赖图、跨会话持久化、多 agent 协作板、后台运行槽位（→ s12–s14）。

```python
# 1) 计划管理器：单 in_progress 不变量 + 整份重写
class TodoManager:
    def __init__(self):
        self.items = []

    def update(self, items: list) -> str:
        validated = []
        in_progress_count = 0

        for item in items:
            status = item.get("status", "pending")
            if status == "in_progress":
                in_progress_count += 1
            validated.append({
                "content": item["content"],
                "status": status,
                "activeForm": item.get("activeForm", ""),
            })

        if in_progress_count > 1:
            raise ValueError("Only one item can be in_progress")

        self.items = validated
        return self.render()

    def render(self) -> str:
        marker = {"pending": "[ ]", "in_progress": "[>]", "completed": "[x]"}
        return "\n".join(f"{marker[i['status']]} {i['content']}" for i in self.items)

# 2) 接入 s02 dispatch map（循环零改动）
TOOL_HANDLERS = {
    "read_file": run_read,
    "write_file": run_write,
    "edit_file": run_edit,
    "bash": run_bash,
    "todo": lambda **kw: TODO.update(kw["items"]),
}

# 3) 失活提醒：把"计划是否新鲜"纳入主循环可观察状态
if rounds_since_update >= 3:
    results.insert(0, {
        "type": "text",
        "text": "<reminder>Refresh your plan before continuing.</reminder>",
    })
```

## System Position
- **Inherits from**: [[AgentLoop]] (s01)、[[ToolRouting]] (s02)
- **Prepares for**: [[ContextCompression]] (s06)、[[Permissions]] (s07)、[[ErrorRecovery]] (s11)、[[TaskSystem]] (s12)、s13–s14 运行时执行与编排
- **Cross-links**: [[ToolRouting]] 的 dispatch map 决定了 `todo` 工具的接入方式；[[AgentLoop]] 的 transition_reason 在更完整系统里会扩展出 `"plan_stale"` 之类的状态值

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 计划写得过长 | 一上来列 10+ 步，几轮后模型放弃维护 | "你计划里有几条？是不是远超当前真正下一步要做的事？" |
| 多个 `in_progress` 并存 | 焦点散，模型反复在不同任务间切换 | "现在有几条 in_progress？教学约束允许几条？" |
| 把会话计划当长期任务系统 | 想给 todo 加 due_date / assignee / 优先级 / 依赖 | "这条信息是这次请求需要的，还是下次会话还要用？" |
| 只在开始时写一次，后面从不更新 | render 出来还是初始版本，状态从未推进 | "render 里有 `[x]` 吗？过了几轮了？" |
| 把 reminder 当成可有可无的装饰 | 计划失活时主循环什么都不做 | "如果模型 5 轮没更新计划，循环还在维护什么状态？" |

## Diagnostic Questions (Step 1)
1. 为什么 s03 要在 messages 之外再引入一块 `PlanningState`？光靠 system prompt + 上下文不够吗？
2. `PlanItem` 三个字段分别承担什么职责？`activeForm` 为什么不省掉？
3. "同一时间最多一个 `in_progress`" 是不变量还是约定？教学版为什么强行加这条？
4. 为什么教学版选"整份重写"而不是局部增删改？
5. `rounds_since_update` 计数到底纳入了主循环什么新职责？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 你觉得"会话内规划"跟"项目管理软件里的任务"最大的区别是什么？
- 如果一份计划只有 `pending` / `completed` 两态，会丢掉什么信息？
- reminder 注入到 user 消息里，会改变 messages 长什么样？

### Advanced
- 如果允许多 `in_progress`，会牺牲什么？换来什么？什么场景下值得？
- 整份重写 vs 局部 patch：哪种对模型更友好？哪种对系统更易实现幂等？
- `rounds_since_update` 阈值设 3 vs 设 10，会怎样改变 agent 行为？
- 如果一个任务跨会话（用户中途关电脑、第二天继续），s03 的 PlanningState 该不该保留？为什么这是 s12 的问题而不是 s03 的？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 把"接下来几步"从模型脑里写到系统状态里。 |
| L2 Guide | 主循环现在维护两块东西：messages 和 PlanningState。 |
| L3 Analogy | 像极限编程里的便签墙——只贴当前 sprint 要做的几张卡，做完撕掉、随时改。 |
| L4 Deconstruct | 数据结构 `PlanItem {content, status, activeForm}` + 不变量"单 in_progress" + 整份重写 + 失活 reminder——四个点凑齐。 |
| L5 Worked Example | 见上方 Minimal Implementation：`TodoManager` 30 行，dispatch 一行，reminder 一段。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "todo 是任务管理产品里的工具" | "这里的 todo 服务跨会话还是只服务当前请求？" | 它只是模型写入当前计划的入口；不是 Linear / Jira 的迁移版 |
| "计划越细越好" | "10 条 todo 跟 3 条 todo，模型维护意愿哪个高？" | 列太多会失去维护意愿；先列 3–5 步即可 |
| "多个 in_progress 等于'并行做事'" | "你能同时聚焦两件事吗？模型呢？" | 单 in_progress 是教学不变量，目的是强制聚焦 |
| "reminder 是 UX 装饰" | "reminder 改变了主循环的什么职责？" | 它表明主循环开始维护"过程性状态"，不只是"对话状态" |
| "s03 = 完整任务系统" | "持久化、依赖图、多 agent 协作——这一章覆盖吗？" | 不覆盖；那是 s12–s14 的事 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | `PlanItem` 三个字段 + `PlanningState` 两个字段是什么？ | 5 个字段全列出且释义正确 |
| Causal | 为什么主循环要维护 `rounds_since_update`？只维护 messages 不行吗？ | 答出"messages 是对话状态，PlanningState 是过程性状态；计划失活需要被显式观测才能干预" |
| Application | 写出 `TodoManager.update()` 的伪代码，包含单 in_progress 校验和整份替换 | 含 validation loop、`in_progress_count > 1` 报错、`self.items = validated`、render 返回字符串 |
| Discrimination | s03 的 todo 跟 s12–s14 的任务系统有什么本质差别？ | 答出"会话级 vs 持久化 / 平面列表 vs 依赖图 / 单 agent vs 多 agent" 至少两点 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现 TodoManager + 接入 s02 dispatch [Required, Weight 70%]
**Prompt**: 在 s02 的 agent loop 上新增 `todo` 工具。要求：

- 实现 `TodoManager.update(items)`，强制单 `in_progress` 不变量，整份重写，返回渲染后的字符串
- 实现 `TodoManager.render()`：`pending → [ ]`，`in_progress → [>]`，`completed → [x]`
- 在 `TOOL_HANDLERS` 里挂 `"todo"` handler，**不修改主循环一行**
- 测试：让模型完成一个 3 步任务，验证它会在过程中调用 `todo` 至少 3 次（初始 + 推进）

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | PlanItem 字段完整 | functional | `content` / `status` / `activeForm` 三字段都被持久化 |
| AC-2 | 单 in_progress 校验 | edge-case | 传入 2 个 `in_progress` 时 raise ValueError |
| AC-3 | 整份重写 | mechanism | `update()` 后 `self.items` 与传入完全一致，旧条目不残留 |
| AC-4 | 主循环零改动 | mechanism | s02 的 agent loop 代码 diff 为空，仅 `TOOL_HANDLERS` 多一行 |
| AC-5 | render 三态符号正确 | functional | 输出含 `[ ]` / `[>]` / `[x]`，且与 status 一一对应 |

**Scoring**
- PASS: AC-1/2/3/4 全过 + AC-5 正确
- NEEDS_WORK: 核心 AC 过，AC-5 渲染符号有误（允许 1 次返工）
- FAIL: 任何核心 AC 失败

### Task 2: Reminder 注入 [Required, Weight 30%]
**Prompt**: 在主循环里维护 `rounds_since_update`。当连续 ≥3 轮未调用 `todo` 时，在下一轮的 `tool_result` 列表前插入：

```python
{"type": "text", "text": "<reminder>Refresh your plan before continuing.</reminder>"}
```

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 计数器正确推进 | functional | 每轮 +1；调用 todo 后归零 |
| AC-2 | 阈值触发 | edge-case | `rounds_since_update == 3` 时注入 reminder |
| AC-3 | 注入位置 | mechanism | reminder 是 results 列表的第一个元素，类型为 text |

**Scoring**: 三条 AC 都过即 PASS。

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Tasks 都 PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到下一章 (s04)。

## Memory Mnemonic
> 把"接下来几步"从模型脑里搬到系统状态里——单 in_progress 聚焦，失活就 reminder。

## Navigation
- Previous: [[ToolRouting]] (s02)
- Next: s04（尚未 ingest）
