---
title: "PromptPipeline"
type: concept
tags: [curriculum, prompt-pipeline, system-prompt, prompt-budget, agent-core, beginner]
sources: [learn.shareai.run-zh-s10, learn.shareai.run-zh-s10a]
last_updated: 2026-05-08
---

## Expanded by S10a: Message + Prompt Full Pipeline
[[learn.shareai.run-zh-s10a-message-prompt-pipeline|S10a]] extends the prompt builder into a full **input pipeline**. The key insight: what the model actually receives is not just the system prompt, but a composition of:
- **SystemPromptBlocks** (core / tools / skills / memory / CLAUDE.md / dynamic)
- **NormalizedMessages** (different formats unified into a stable API-ready form)
- **Attachments** (memory attachments, hook injection results)
- **Reminders** (per-turn temporary context)

The pipeline rule: **all sources first establish their boundaries, then get normalized into the final API payload.** System prompt is one segment of the pipeline, not the entirety.

Boundary decision: prefer prompt blocks for long-term stable rules; prefer message flow for tool results, hook outputs, and current-turn reminders; prefer attachments for large optional supplements.
---

## Core Thesis
> system prompt 的关键不是"写一段很长的话"，而是"把不同来源的信息按清晰边界组装起来"。

## Problem Definition
到了 s09，agent 已经拥有 [[AgentLoop]]、[[ToolRouting]]、[[PlanningState]]、[[Subagent]]、[[SkillSystem]]、[[ContextCompression]]、[[Permissions]]、[[HookSystem]]、[[Memory]]。每一章都给系统增加了一种新信息来源：工具列表会变、skills 会变、memory 会变、当前目录/日期/模式会变、某些提醒只在这一轮有效。如果 system prompt 仍是一大段硬编码文本，会出现三个问题：

- **不好维护**：你很难知道哪一段来自哪里、该修改哪一部分、哪一段是固定说明、哪一段是临时上下文。
- **不好测试**：很难分别测试工具说明生成得对不对、memory 是否被正确拼进去、CLAUDE.md 是否被正确读取。
- **不好做缓存和动态更新**：稳定内容不需要每轮大变，临时内容只该活一轮；混在一起就无法分别处理。

**学完前**：你把 prompt 看成"神秘大段文本"，所有信息硬塞进 system prompt。
**学完后**：你能把不同来源拆成独立 section，按稳定层 + 动态层 + 边界标记清晰组装，让系统输入可维护、可测试、可缓存。

## Terminology
| Term | Definition |
|------|------------|
| system prompt | 给模型的系统级说明：你是谁、你能做什么、你应该遵守什么规则、你现在处在什么环境里 |
| system prompt builder | 把多段来源按顺序拼接成最终 system prompt 的构建器 |
| 稳定层 (stable layer) | 每轮变化很小的部分：core 身份说明、工具 schema、skills 目录、memory 内容、CLAUDE.md 指令链 |
| 动态层 (dynamic layer) | 每轮可能变化的部分：当前日期、当前工作目录、当前模型名、当前权限模式、本轮临时提醒 |
| system reminder | 每轮额外追加的临时补充上下文，与主 system prompt 分离，只在本轮生效 |
| dynamic boundary | 可选的 `=== DYNAMIC_BOUNDARY ===` 标记，视觉上区分稳定层与动态层 |
| core section | builder 的第 1 段：核心身份和行为说明 |
| tools section | builder 的第 2 段：工具列表与 schema 说明 |
| skills section | builder 的第 3 段：skills 元信息（目录，不是正文） |
| memory section | builder 的第 4 段：memory 内容（跨会话有价值的信息） |
| claude_md section | builder 的第 5 段：CLAUDE.md 指令链（用户级 → 项目级 → 子目录级） |
| dynamic_context section | builder 的第 6 段：动态环境信息（date / cwd / model / mode） |

## Mental Model
```text
SystemPromptBuilder
  |
  +-- _build_core()          → 身份 + 行为规则
  +-- _build_tools()         → 工具列表 + schema
  +-- _build_skills()        → skills 目录（轻量元信息）
  +-- _build_memory()        → memory 内容
  +-- _build_claude_md()     → 指令链（分层叠加，不互相覆盖）
  +-- _build_dynamic()       → date / cwd / model / mode
  |
  v
  "\n\n".join(parts)  →  final system prompt
```

**关键洞察**：
- 每一段只负责一种来源，职责单一。
- 稳定层与动态层分开思考，便于缓存（稳定层可预计算）和动态更新（动态层每轮重新生成）。
- CLAUDE.md 不是临时上下文，而是长期规则；多层 CLAUDE.md 全部拼进去，不是互相覆盖。
- memory 必须进入 prompt 组装链条，否则保存了等于没使用。

## Minimal Implementation
最小教学版围绕 2 步：

```python
class SystemPromptBuilder:
    def build(self) -> str:
        parts = []
        parts.append(self._build_core())
        parts.append(self._build_tools())
        parts.append(self._build_skills())
        parts.append(self._build_memory())
        parts.append(self._build_claude_md())
        parts.append(self._build_dynamic())
        return "\n\n".join(p for p in parts if p)
```

**显式不在本章覆盖**（保留给 s10a / 后续章节 / 高完成度版）：
- 复杂的 section 注册系统（插件式扩展 prompt 段）
- 缓存与预算管理（稳定层预计算、动态层增量更新）
- 所有外部能力如何追加 prompt 说明（MCP、通知、query 跟踪等）
- 条件激活 / 参数化 skill 的 prompt 注入细节
- system reminder 与 system prompt 的完整协议区分

## System Position
- **Inherits from**: [[AgentLoop]]（`system=` 参数从静态字符串变为 builder 输出）、[[SkillSystem]]（skills 目录作为第 3 段来源）、[[Memory]]（memory 内容作为第 4 段来源）、[[Permissions]]（当前模式作为 dynamic_context 的一部分）、[[HookSystem]]（hook 可在固定时机动态修改 prompt 片段）
- **Prepares for**: [[ErrorRecovery]]（s11，错误信息如何作为临时 reminder 注入）、s19 MCP（外部能力给 prompt 增加说明）
- **Cross-links**: [[ContextCompression]]（压缩管"本会话太长"，prompt pipeline 管"系统输入怎么拼"——两者都在管理模型看到的上下文，但层面不同：pipeline 是"输入结构"，compression 是"历史长度"）

## 边界澄清：system prompt vs system reminder
| 维度 | system prompt | system reminder |
|------|---------------|-----------------|
| 内容 | 身份、规则、工具、长期约束 | 本轮临时需要的补充上下文、当前变动状态 |
| 变化频率 | 相对稳定（跨多轮） | 每轮可能不同 |
| 例子 | "你是一个 coding agent"、工具 schema | "当前日期是 2026-05-08"、"本轮用户要求只读模式" |
| 一句话判断 | 不轮询也成立的信息 | 只在这一轮才需要的信息 |

## 边界澄清：skill vs memory vs CLAUDE.md（s10 强化版）
| 维度 | skill | memory | CLAUDE.md |
|------|-------|--------|-----------|
| 是什么 | 可选知识包 | 跨会话仍有价值的信息 | 更稳定、更长期的全局规则 |
| 在 builder 中的段 | skills section | memory section | claude_md section |
| 触发 | 某类任务才需要时加载 | 系统记住的事实或偏好 | 始终生效 |
| 例子 | "代码审查清单" | "用户偏好用 pytest" | "永远用 uv，不要用 pip" |

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把 system prompt 讲成一个固定字符串 | 读者看不到系统是如何长大的 | "你的 system prompt 是写死的，还是每轮重新组装的？" |
| 把所有变化信息都塞进 system prompt | 稳定说明和临时提醒搅在一起，缓存失效 | "哪些信息每轮都变？哪些可以预计算？" |
| 把 CLAUDE.md、memory、skills 写成同一种东西 | 来源和职责混淆，维护困难 | "这三者在 builder 里是同一个 section 吗？" |
| 多层 CLAUDE.md 互相覆盖 | 只读到了最近一层，丢失全局规则 | "用户级、项目级、子目录级的规则是叠加还是覆盖？" |
| 保存了 memory 但从不注入 prompt | memory 文件存在，但模型永远看不到 | "memory section 在 builder 里被调用吗？" |
| 一上来就讲 section 注册系统 / 缓存 / 预算 | v1 还没跑通 6 段 builder，已经在搞插件架构 | "你能先把 6 段独立 builder 跑通吗？" |

## Diagnostic Questions (Step 1)
1. 为什么 system prompt 不能只是一整块硬编码文本？
2. 6 段模型中，哪些属于稳定层？哪些属于动态层？
3. system prompt 和 system reminder 的边界是什么？
4. 为什么 CLAUDE.md 要全部拼进去，而不是互相覆盖？
5. memory 如果不进入 prompt 组装链条，会出现什么问题？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 6 段模型分别是什么？按顺序说出名称。
- `_build_tools()` 和 `_build_skills()` 的职责区别是什么？
- dynamic boundary 标记的作用是什么？它是魔法吗？
- 为什么 builder 返回的是 `\n\n`.join(parts)，而不是一个大 f-string？

### Advanced
- 如果 skills 目录有 100 个 skill，`_build_skills()` 的输出会不会太长？这暴露了什么问题？（提示：s05 的 discovery vs loading）
- 多层 CLAUDE.md 如果冲突（用户级说"用 tabs"，项目级说"用 spaces"），系统该怎么处理？
- memory 内容如果很多，会不会把 system prompt 撑爆？这和 [[ContextCompression]] 有什么关系？
- 权限模式（default / plan / auto）应该放进 system prompt 还是 system reminder？为什么？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | system prompt = 把不同来源按顺序拼成一份输入，不是一块死字符串。 |
| L2 Guide | 先分 6 段：core / tools / skills / memory / CLAUDE.md / dynamic。再想哪些稳定、哪些每轮变。 |
| L3 Analogy | 像做三明治：底层面包（core）、生菜（tools）、火腿（skills）、芝士（memory）、酱料（CLAUDE.md）、顶层面包（dynamic）——每层独立准备，最后叠起来。 |
| L4 Deconstruct | 两步：①写一个 `SystemPromptBuilder` 类，6 个 `_build_*` 方法 ②`build()` 按顺序 join。 |
| L5 Worked Example | 见上方最小实现——逐行对照，注意 `_build_skills()` 只拼目录、不拼正文。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "system prompt 就是一大段固定文本" | "你的 system prompt 是写死的，还是每轮重新组装的？" | s10 的核心论点是"流水线"，不是"长文本"。 |
| "所有信息都该塞进 system prompt" | "哪些信息只在这一轮有效？" | 当前日期、本轮临时提醒只该活一轮，不该和长期规则混在一起。 |
| "CLAUDE.md、memory、skills 是同一种东西" | "代码审查清单、用户偏好、全局规则是同一类信息吗？" | 三者来源、触发方式、寿命都不同；s10 用不同 builder 段区分。 |
| "多层 CLAUDE.md 应该互相覆盖" | "用户级规则和项目级规则冲突时，应该丢哪一个？" | 教学版全部拼进去，让读者理解"规则来源可以分层叠加"；覆盖策略是高级话题。 |
| "dynamic boundary 是魔法标记" | "没有这个标记，系统还能工作吗？" | 它只是视觉提醒，不是协议；没有它 builder 仍然正确运行。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 6 段模型分别是什么？稳定层和动态层各包含哪些？ | 答出 6 段名称，并正确分类稳定/动态 |
| Causal | 为什么 system prompt 不能是硬编码文本？ | 答出"维护困难 + 测试困难 + 缓存/动态更新困难" |
| Application | 写出最小 `SystemPromptBuilder`，含 6 个 `_build_*` 方法 | 含 builder 类、`build()` 按顺序 join、每段职责单一 |
| Discrimination | system prompt vs system reminder 的边界是什么？给 3 个例子分类 | 答出"长期约束 vs 本轮临时"，例子分类正确 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小 SystemPromptBuilder [Required, Weight 70%]
**Prompt**: 在 [[AgentLoop]] 基础上，把静态 `SYSTEM` 字符串替换为 `SystemPromptBuilder`：

- 实现 `SystemPromptBuilder` 类，含 6 个 `_build_*` 方法（core / tools / skills / memory / claude_md / dynamic）
- `build()` 按顺序拼接，过滤空段
- `_build_tools()` 从 `TOOLS` 列表生成工具说明
- `_build_skills()` 从 `SkillRegistry` 只拼目录（名称 + 描述），不拼正文
- `_build_memory()` 从 `memory_dir` 读取所有 `.memory/*.md`，拼成 memory section
- `_build_claude_md()` 读取用户级 + 项目级 + 子目录级 CLAUDE.md，全部拼进去
- `_build_dynamic()` 拼入当前日期、cwd、模型名、当前权限模式
- 写一段示例调用，展示最终 system prompt 的完整输出

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 6 段 builder 完整 | functional | 6 个 `_build_*` 方法都存在且被 `build()` 调用 |
| AC-2 | skills 只拼目录 | functional | system prompt 中不出现任何 skill 正文 |
| AC-3 | memory 注入 | functional | memory 文件内容出现在 system prompt 的 memory section |
| AC-4 | CLAUDE.md 分层叠加 | mechanism | 用户级 + 项目级 + 子目录级内容都出现，不是只保留最后一层 |
| AC-5 | 动态段可识别 | edge-case | 输出中含 date / cwd / model / mode 至少两项 |
| AC-6 | 空段过滤 | mechanism | 某段返回空字符串时，build() 不生成多余换行 |

**Scoring**
- PASS: all 6 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4/5/6 部分缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

### Task 2: 边界判断练习 [Optional, Weight 30%]
**Prompt**: 给定 8 条信息，判断每条应该进入 system prompt 的哪一段（core / tools / skills / memory / claude_md / dynamic / reminder / 都不进），并说明依据。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 分类准确率 | functional | ≥6/8 正确 |
| AC-2 | 判断依据 | mechanism | 每条说明触及"来源"或"变化频率" |

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%（Task 2 可加分但不必须）

**On FAIL**: 回到 Tutor Loop，不晋级到 s11。

## Memory Mnemonic
> system prompt 不是写一段很长的话，而是把不同来源按清晰边界组装起来。

## Navigation
- Previous: [[Memory]] (s09)
- Next: [[ErrorRecovery]] (s11)
