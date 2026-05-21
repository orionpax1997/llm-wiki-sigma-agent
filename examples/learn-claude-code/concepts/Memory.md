---
title: "Memory"
type: concept
tags: [curriculum, memory, persistence, cross-session, agent-core, beginner]
sources: [learn.shareai.run-zh-s09]
last_updated: 2026-05-08
---

## Core Thesis
> Memory 保存的是"以后还可能有价值、但当前代码里不容易直接重新看出来"的信息——用来提供方向，不用来替代当前观察。

## Problem Definition
有了 [[AgentLoop]] + [[ToolRouting]] + [[PlanningState]] + [[Subagent]] + [[SkillSystem]] + [[ContextCompression]] + [[Permissions]] + [[HookSystem]]，agent 已经能在单会话内高效推进任务、管理上下文预算、做权限判断、通过 hook 扩展行为。但每次新会话都从零开始时，系统会不断重复忘记：

- 用户长期偏好（代码风格、回答详细程度、工具链偏好）
- 用户多次纠正过的错误
- 不容易从代码直接看出来的项目约定
- 外部资源在哪里找

**学完前**：agent "每次都像第一次合作"，重复犯同样的错、重复问同样的问题。
**学完后**：你能让系统把跨会话仍有价值的信息持久化到磁盘，在新会话开始时重新加载，让 agent 的长期表现越来越贴合用户和项目。

## Terminology
| Term | Definition |
|------|------------|
| memory | 跨会话仍有价值、且不能轻易从当前状态重新推导的信息 |
| user memory | 用户偏好：代码风格、回答长度、工具链偏好 |
| feedback memory | 用户明确纠正过的地方，以及被验证有效的做法 |
| project memory | 不容易从代码直接看出的项目约定或背景（如合规驱动的设计决定） |
| reference memory | 外部资源指针（看板、监控面板、资料库 URL） |
| MEMORY.md | 最小实现里的索引文件，只列有哪些 memory 可用，不重复保存内容 |
| save_memory | 工具：把一条 memory 写入独立文件并重建索引 |
| memory section | 会话启动时把 memory 文件内容拼成的一段文本，注入系统输入 |
| private scope | 只属于当前用户或当前 agent 的记忆 |
| team scope | 整个项目团队共享的记忆 |
| memory drift | memory 记录的是"曾经成立过的事实"，会随时间过时 |

## Mental Model
```text
conversation
   |
   | 用户提到一个长期重要信息
   v
save_memory
   |
   v
.memory/
  ├── MEMORY.md        # 索引
  ├── prefer_tabs.md
  ├── feedback_tests.md
  └── incident_board.md
   |
   v
下次新会话开始时重新加载 → 拼成 memory section → 注入系统输入
```

**关键洞察**：
- memory 和压缩是两套机制：压缩管"本会话太长怎么办"，memory 管"跨会话保留什么"。
- memory 不是绝对真相——它提供方向，最终结论要基于当前观察验证。
- 用户说"忽略 memory"时，系统应**按 memory 为空来工作**。

## Minimal Implementation
最小教学版围绕 5 步：

```python
# Step 1: 定义 memory 类型
MEMORY_TYPES = ("user", "feedback", "project", "reference")

# Step 2: save_memory 工具
def save_memory(name, description, mem_type, content):
    path = memory_dir / f"{safe_name}.md"
    path.write_text(frontmatter + content)
    rebuild_index()

# Step 3: 单条 memory 文件格式
"""
---
name: prefer_tabs
description: User prefers tabs for indentation
type: user
---
The user explicitly prefers tabs over spaces when editing source files.
"""

# Step 4: 索引文件 MEMORY.md
"""
# Memory Index
- prefer_tabs: User prefers tabs for indentation [user]
- avoid_mock_heavy_tests: User dislikes mock-heavy tests [feedback]
"""

# Step 5: 会话开始时重新加载并注入
memory_section = build_memory_section(memory_dir)
# 在 s10 的 prompt 组装里系统化接入
```

**显式不在本章覆盖**（保留给后续章节 / 高完成度版）：
- 自动抽取 / 自动整合（何时该自动存 memory）
- 作用域分层完整实现（private / team / org）
- memory 的优先级 / 冲突解决策略
- memory 的过期 / 自动清理机制
- 向量检索 / 语义搜索（memory 量大时）
- 与 s10 prompt pipeline 的完整集成细节

## System Position
- **Inherits from**: [[AgentLoop]]（memory 在会话启动时加载，作为系统输入的一部分注入）、[[ContextCompression]]（边界邻居：压缩管会话内，memory 管跨会话）
- **Prepares for**: [[PromptPipeline]]（s10，memory 作为 system prompt 第 4 段来源系统化接入组装流水线）、s11 [[ErrorRecovery]]（memory 漂移和过时信息的恢复）
- **Cross-links**: [[SkillSystem]]（skill 是"某类任务才需要的可选知识"，memory 是"跨会话记住的事实"；两者都在管理 prompt 内容，但寿命和触发方式不同）、[[PlanningState]]（plan 是过程性安排，memory 是长期沉淀）

## 边界澄清：memory vs task vs plan vs CLAUDE.md
| 维度 | memory | task | plan | CLAUDE.md |
|------|--------|------|------|-----------|
| 解决什么 | 跨会话仍有价值的信息 | 当前工作要做什么、依赖、进度 | 这一轮怎么做 | 更稳定的全局规则 |
| 作用范围 | 跨会话 / 跨任务 | 当前任务 | 当前请求的过程性安排 | 始终生效 |
| 例子 | "用户偏好用 pytest" | "认证模块还有 2 项没做" | "先读配置，再改模型" | "永远用 uv，不要用 pip" |
| 一句话判断 | 以后很多会话可能还有用 | 只对这次任务有用 | 这一轮的过程性安排 | 长期系统级固定说明 |

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把代码结构也存进 memory | "这个项目有 src/ 和 tests/"、"这个函数在 app.py" | "系统能不能重新读代码得到这个信息？能就不该存。" |
| 把当前任务状态存进 memory | "我正在改认证模块"、"这个 PR 还有两项没做" | "这条信息明天还准确吗？这是 task/plan 不是 memory。" |
| 把 memory 当成绝对真相 | memory 和当前代码冲突时，盲目相信 memory | "memory 和当前状态冲突时，优先相信哪个？" |
| 用户说忽略 memory 但系统继续用 | 嘴上忽略、实际行为仍受 memory 影响 | "用户明确说忽略时，系统是按空 memory 工作吗？" |
| 推荐前不核对当前状态 | 直接复述 memory 里的路径 / 函数名 / URL，但已过时 | "在给出具体推荐前，有没有先验证当前状态？" |
| 一上来就搞自动抽取 / 向量检索 | v1 还没跑通 4 类边界 + save_memory 工具，已经在搞语义搜索 | "你能先把'该存什么/不该存什么'跑通吗？" |

## Diagnostic Questions (Step 1)
1. 为什么 memory 不是"什么都记"？
2. 什么样的信息适合跨会话保存？什么样的不适合？
3. 为什么代码结构和当前任务状态不应该进 memory？
4. memory 和 task / plan / CLAUDE.md 的边界是什么？
5. 用户说"忽略 memory"时，系统合理的处理方式是什么？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 4 类 memory 各举一个例子。
- 为什么"文件结构"不该存进 memory？
- MEMORY.md 索引的作用是什么？它重复保存内容吗？
- memory 和上下文压缩（[[ContextCompression]]）解决的是同一个问题吗？

### Advanced
- 如果 memory 和当前代码状态冲突，应该优先相信哪个？为什么？
- feedback memory 为什么也要保存"被验证有效的正反馈"？只存纠错有什么问题？
- private scope 和 team scope 的分层价值是什么？哪些类型天然偏向哪一边？
- 推荐具体路径 / URL 前"再验证一次"的机制，在代码层面怎么实现？
- 如果用户说"记住我最近在改认证模块"，系统应该怎么回应？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | memory = 跨会话仍有价值、但当前代码里不容易直接看出来的信息。 |
| L2 Guide | 先想"这条信息明天还准确吗？"→ 不准 = 不该存；再想"系统能不能重新读出来？"→ 能 = 不该存。 |
| L3 Analogy | 像搬家时打包的"重要文件盒"——不是什么都塞，只放以后还需要的、且现场找不到的。 |
| L4 Deconstruct | 5 步：①定义 4 类 ②save_memory 工具 ③单条文件格式 ④MEMORY.md 索引 ⑤会话启动重载。 |
| L5 Worked Example | 用户说"我讨厌 mock-heavy 的测试"→ 类型=feedback，name=avoid_mock_heavy_tests，content=用户明确偏好。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "memory = 更长的上下文窗口" | "memory 和 context compression 是同一套机制吗？" | 压缩管本会话太长（s06），memory 管跨会话保留（s09）；混淆会让 memory 被会话噪声淹没。 |
| "有用的信息都该记住" | "这条信息明天还准确吗？系统能重新读出来吗？" | 文件结构、当前任务进度、临时分支名都有用，但不该进 memory——它们要么会过时，要么可重新推导。 |
| "memory 是已经查证过的答案" | "memory 和当前代码冲突时优先相信谁？" | memory 会漂移；它只是方向提示，最终结论必须基于当前观察。 |
| "用户说记住就该直接存" | "用户让记住本周 PR 列表，该直接写进 memory 吗？" | 不该——要追问"真正值得长期留下的非显然信息是什么"。 |
| "忽略 memory = 嘴上说说" | "用户说忽略时，系统行为有什么实际变化？" | 合理的处理是按 memory 为空工作，不是继续用但假装不用。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 4 类 memory 是什么？各举一个例子。 | 答出 user / feedback / project / reference 且例子准确 |
| Causal | 为什么 memory 不是"什么都记"？ | 答出"垃圾堆问题 + 过时依赖问题 + 可重新推导的信息不该存" |
| Application | 给定 5 条信息，判断哪些该进 memory、哪些不该，并说明理由 | ≥4/5 正确，理由触及"跨会话价值"和"可推导性" |
| Discrimination | memory vs task vs plan vs CLAUDE.md 的边界是什么？ | 答出四者的作用范围差异，并给出分类例子 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小 Memory 系统 [Required, Weight 70%]
**Prompt**: 在 [[AgentLoop]] 基础上实现最小 memory 系统：

- 定义 `MEMORY_TYPES = ("user", "feedback", "project", "reference")`
- 实现 `save_memory(name, description, mem_type, content)`：写入 `.memory/{safe_name}.md`，含 frontmatter（name / description / type）+ content
- 实现 `rebuild_index()`：扫描 `.memory/` 生成 `MEMORY.md` 索引
- 实现 `load_memories()`：会话启动时读取所有 `.memory/*.md`，拼成一段 memory section
- 写 3 条示例 memory（分别覆盖 user / feedback / project 类型），验证 save → index → load 流程

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 单条文件格式正确 | functional | 含 frontmatter（name / description / type）+ markdown body |
| AC-2 | 索引自动重建 | functional | 调用 save_memory 后 MEMORY.md 自动更新 |
| AC-3 | 4 类类型校验 | edge-case | 传入非法 type 时拒绝或报错 |
| AC-4 | 加载流程完整 | mechanism | 会话启动能正确读出所有 memory 并拼成 section |
| AC-5 | 不存不该存的东西 | mechanism | 给定"当前分支名"或"文件结构"，系统拒绝写入并给出理由 |

**Scoring**
- PASS: all 5 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4 或 AC-5 缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

### Task 2: 边界判断练习 [Optional, Weight 30%]
**Prompt**: 给定 10 条混合信息，逐条判断该进 memory / task / plan / CLAUDE.md / 都不进，并说明依据。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 分类准确率 | functional | ≥8/10 正确 |
| AC-2 | 判断依据 | mechanism | 每条说明触及"跨会话价值"或"可推导性" |

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%（Task 2 可加分但不必须）

**On FAIL**: 回到 Tutor Loop，不晋级到 s10。

## Memory Mnemonic
> Memory 不是什么都记，是记下"以后还有用、但现场找不到"的信息。

## Navigation
- Previous: [[HookSystem]] (s08)
- Next: [[PromptPipeline]] (s10)
