---
title: "SkillSystem"
type: concept
tags: [curriculum, skill, on-demand-loading, prompt-budget, beginner]
sources: [learn.shareai.run-zh-s05]
last_updated: 2026-05-07
---

## Core Thesis
> Skill 系统的核心，不是"多一个工具"，而是把"长期可选知识"从常驻 system prompt 里拆出来，改成**按需加载**——system prompt 只列轻量目录，真正需要时才把完整正文注入当前上下文。

## Problem Definition
有了 [[AgentLoop]] + [[ToolRouting]] + [[PlanningState]] + [[Subagent]]，agent 已经会跑主循环、路由工具、维护规划、隔离子任务。但不同任务需要的领域知识不一样：代码审查需要审查清单，Git 操作需要提交约定，MCP 集成需要专门步骤。如果把这些知识包**全部塞进 system prompt**，会出现两个问题：

- **学完前**：你只有一个 system prompt，要么每个任务都背着所有领域知识 (token 浪费 + 主线规则被淹没)，要么干脆把领域知识抽掉 (模型做不动专业任务)。
- **学完后**：你能让 system prompt 只放**轻量目录**（"有哪些 skill 可用"），完整正文通过 `load_skill` 工具按需注入——prompt 预算从"扁平 + 全量"走向"分层 + 按需"。

## Terminology
| Term | Definition |
|------|------------|
| skill | 一份围绕某类任务的可复用说明书（何时用、有哪些步骤、有哪些注意事项） |
| discovery | 发现"有哪些 skill 可用"——这一层只需要很轻量的信息（名称 + 一句描述） |
| loading | 把某个 skill 的完整正文真正读进当前上下文——这一层才是昂贵的 |
| SkillManifest | 轻元信息 `{name, description}`，用于 discovery 阶段 |
| SkillDocument | `{manifest, body}`，loading 阶段才需要完整 body |
| SkillRegistry | 统一注册表 `{name → SkillDocument}`，回答"有哪些 / 完整内容是什么"两个问题 |
| 稳定层 | system prompt 中常驻的部分：身份、规则、工具、**skill 目录**（不是正文） |
| 按需层 | 当前轮次真的加载进来的 skill 正文，作为 `tool_result` 注入 messages |

## Mental Model
```text
system prompt
  |
  +-- 身份 + 规则 + 工具 schema
  |
  +-- Skills available:                  <-- 第 1 层：轻量目录（只放名称 + 描述）
        - code-review: review checklist
        - git-workflow: branch and commit guidance
        - mcp-builder: build an MCP server

模型判断"我现在需要 code-review 的完整内容"
  |
  v
load_skill("code-review")               <-- 第 2 层：按需正文（昂贵，才注入）
  |
  v
tool_result
  |
  v
<skill name="code-review">
完整审查说明...
</skill>
  |
  v
进入当前上下文，模型读到后继续推理
```

**关键洞察**：`load_skill` 只是一个普通工具——它复用 [[ToolRouting]] 的 dispatch map，沿用 [[AgentLoop]] 的 tool_use → tool_result 回路。**主循环零改动**；变的是 prompt 的结构（多了"稳定层 vs 按需层"这一分层）。

## Minimal Implementation
最小教学版围绕 5 步：

```python
# Step 1: 每个 skill 一个目录，含一份 SKILL.md
# skills/
#   code-review/SKILL.md
#   git-workflow/SKILL.md

# Step 2: 从 SKILL.md frontmatter 读 manifest，body 留作按需 load
class SkillRegistry:
    def __init__(self, skills_dir):
        self.skills = {}
        for path in skills_dir.rglob("SKILL.md"):
            meta, body = parse_frontmatter(path.read_text())
            name = meta.get("name", path.parent.name)
            self.skills[name] = {
                "manifest": {"name": name, "description": meta.get("description", "")},
                "body": body,
            }

    def describe_available(self) -> str:
        return "\n".join(f"- {n}: {s['manifest']['description']}" for n, s in self.skills.items())

    def load_full_text(self, name: str) -> str:
        s = self.skills[name]
        return f"<skill name=\"{name}\">\n{s['body']}\n</skill>"

# Step 3: system prompt 只放目录，不放正文
SYSTEM = f"""You are a coding agent.
Skills available:
{SKILL_REGISTRY.describe_available()}
"""

# Step 4: load_skill 工具复用 s02 的 dispatch map
TOOL_HANDLERS["load_skill"] = lambda **kw: SKILL_REGISTRY.load_full_text(kw["name"])

# Step 5: 主循环不变 —— skill 正文通过 tool_result 自动进入 messages
# 没有需要时，prompt 里看不到任何 skill 正文
```

关键数据结构（**记这三个**）：

```python
SkillManifest = {"name": str, "description": str}                     # 轻 (discovery)
SkillDocument = {"manifest": SkillManifest, "body": str}              # 重 (loading)
SkillRegistry = {name: SkillDocument, ...}                            # 注册表
```

**显式不在本章覆盖**（保留给 s10 系统化展开）：
- 多来源收集（多目录 / 远程 skill 仓库）
- 条件激活（按 task 类型 / 用户角色自动加载）
- skill 参数化（同一 skill + 不同参数）
- fork 式执行（skill 触发独立上下文跑）
- 更复杂的 prompt 管道拼装

## System Position
- **Inherits from**: [[AgentLoop]]（`load_skill` 是普通工具，走 tool_use → tool_result 回路）、[[ToolRouting]]（`load_skill` 复用 dispatch map，零改动主循环）
- **Prepares for**: [[PromptPipeline]]（s10，skills 目录作为 system prompt 第 3 段来源系统化接入组装流水线）；与 [[ContextCompression]]（s06）共同构成"prompt 预算管理"的两个方向——**Skill 削减常驻知识开销**，ContextCompression 削减历史累积开销
- **Cross-links**: [[Subagent]]（s04 削减**过程性噪声**，s05 削减**常驻知识开销**——两者都在管理上下文预算，但作用面不同）；`memory` / `CLAUDE.md`（边界邻居，见下方"边界澄清"）

## 边界澄清：skill vs memory vs CLAUDE.md
| 维度 | skill | memory | CLAUDE.md |
|------|-------|--------|-----------|
| 是什么 | 可选知识包 | 跨会话仍有价值的信息 | 更稳定、更长期的全局规则 |
| 触发 | 某类任务才需要时加载 | 系统记住的事实或偏好 | 始终生效 |
| 例子 | "代码审查清单"、"MCP 构建步骤" | "用户偏好用 pytest"、"昨天讨论的方案 X" | "永远用 uv，不要用 pip" |
| 一句话判断 | 这是某类任务才需要的做法 | 这是需要长期记住的事实 | 这是更稳定的全局规则 |

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把所有 skill 正文永远塞进 system prompt | system prompt 越来越长，主线规则被淹没；token 大量浪费在当前用不到的说明上 | "你 system prompt 当前一共多少 token？其中有多少是当前任务真正用到的？" |
| skill 目录信息写得太弱 | 只有名字没有描述（或描述含糊），模型不知道什么时候该加载它 | "看着你的 skill 目录，模型怎么判断'这次要不要 load 它'？" |
| 把 skill 当成"绝对规则" | 每一轮都强制 load 某个 skill，或写成"模型必须始终遵守 skill 内容" | "skill 是工作手册还是法律？所有任务都用得到吗？" |
| skill 和 memory 混为一类 | 把"用户偏好"塞进 skill，或把"任务做法"塞进 memory | "这条信息是'某类任务才用'还是'长期记住的事实'？" |
| 一上来就讲多源加载 / 条件激活 | v1 还没跑通最小注册表 + load_skill，已经在搞远程仓库 / 自动激活策略 | "你能先把 1 个本地 skill + 手动 load 跑通吗？" |

## Diagnostic Questions (Step 1)
1. discovery 和 loading 各放什么信息？为什么 loading 比 discovery 昂贵？
2. `SkillManifest` / `SkillDocument` / `SkillRegistry` 三者依次解决什么问题？
3. system prompt 的"稳定层"和"按需层"各放什么？为什么 skill 正文不能放进稳定层？
4. `load_skill` 是一个新工具——它需要修改 [[AgentLoop]] 的主循环吗？为什么？
5. 同一条信息何时该放 skill、何时该放 memory、何时该放 CLAUDE.md？

## Question Bank (Step 3b — Socratic)
### Entry-level
- system prompt 里放的是 skill 的"目录"还是"正文"？
- skill 完整正文是怎么进入当前上下文的？通过哪个消息类型？
- 如果 skill 描述写成空字符串，会发生什么？
- 一个普通任务（不需要任何专业知识）会不会触发 `load_skill`？应不应该？

### Advanced
- 如果 system prompt 的目录太长（100 个 skill），还能算"轻量发现"吗？这暴露了什么问题？该怎么治？
- 多个 skill 同时被 load 进当前上下文时，token 又会膨胀——这与本章"按需加载"是否矛盾？为什么这种短期膨胀仍然优于"永远塞 system prompt"？
- 子智能体（[[Subagent]]）应该看到父智能体的 skill 目录吗？还是应该有自己的精简目录？
- 如果让模型**自动**决定 load 哪些 skill（条件激活），会引入哪些新的失败模式？为什么 s05 把这个推到 s10？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | system prompt 只放"目录"，正文按需通过工具调用注入。 |
| L2 Guide | 把 prompt 想成两层：稳定层（身份 + 规则 + 目录） + 按需层（这一轮真正需要的 skill 正文）。 |
| L3 Analogy | 像图书馆——书架上贴的是书名 + 一句简介（discovery），书架上不预先把所有书摊开（loading）；要看时才借出来翻（按需）。 |
| L4 Deconstruct | 5 步：①每个 skill 一个目录 ②frontmatter 拆 manifest 和 body ③`describe_available()` 进 system prompt ④`load_skill` 工具 ⑤正文按需进 messages。 |
| L5 Worked Example | 见上方"最小实现"——逐行对照 5 步走，注意 system prompt 拼接的是 `describe_available()` 而不是 body。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "Skill 系统就是多一个工具" | "本章动了主循环吗？动了 prompt 结构吗？" | 主循环没动，动的是 prompt 结构（稳定层 vs 按需层）；工具只是按需加载的入口。 |
| "skill 要尽可能完整、详细，越长越好" | "skill 越长，对 prompt 预算的影响是？" | 过长 skill 一旦 load，立即把上下文撑爆——长正文反而抵消按需加载的收益。 |
| "skill 的目录信息越简短越好（节省 token）" | "目录太弱时模型怎么知道何时加载？" | 描述太弱 → 模型从不调用 → skill 等于不存在；目录是 discovery，必须能让模型判断是否相关。 |
| "skill 应该每轮强制 load 一次" | "这和'永远塞 system prompt'的区别是什么？" | 强制 load 等于回到全量塞——失去按需加载的全部价值。 |
| "skill 和 memory 是同一类东西" | "代码审查清单和'用户偏好用 pytest'是同一类信息吗？" | 前者是任务做法（skill），后者是长期事实（memory）；两者寿命、触发方式都不同。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | discovery 和 loading 各包含什么信息？三个数据结构是什么？ | 答出 discovery=name+description；loading=完整 body；三结构 = SkillManifest / SkillDocument / SkillRegistry |
| Causal | 为什么 skill 正文不能放在 system prompt 稳定层？ | 答出"token 浪费 + 主线规则被淹没 + 大部分轮次用不到" |
| Application | 写出最小 SkillRegistry：load 目录 + describe_available + load_skill 工具 | 含 5 步且 system prompt 拼的是目录而非正文，`load_skill` 走 dispatch map |
| Discrimination | skill / memory / CLAUDE.md 三者各装什么？给三个例子分类 | 任务做法 → skill；长期事实/偏好 → memory；稳定全局规则 → CLAUDE.md |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小 SkillRegistry + load_skill 工具 [Required, Weight 70%]
**Prompt**: 在 [[AgentLoop]] + [[ToolRouting]] 基础上，实现最小 Skill 系统：

- 在 `skills/` 目录下放至少 2 个 skill（如 `code-review/SKILL.md`、`git-workflow/SKILL.md`），每个 SKILL.md 含 frontmatter（`name`、`description`）和 body
- 实现 `SkillRegistry`，从目录加载所有 skill 进内存，分别保存 manifest 与 body
- 在 system prompt 里只拼接 `describe_available()`（目录），**不**拼接任何 body
- 在 `TOOL_HANDLERS` 注册 `load_skill`，调用时返回完整 body 包成 `<skill name="...">...</skill>` 字符串
- 跑一个示例对话：用户问"帮我审查这段代码"，观察模型先调用 `load_skill("code-review")` 再继续工作

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | system prompt 只含目录 | functional | 启动时 print system prompt，**不**应出现任何 skill 的完整 body |
| AC-2 | `load_skill` 走 dispatch map | functional | `load_skill` 在 `TOOL_HANDLERS` 中，主循环代码无改动 |
| AC-3 | 正文按需注入 messages | mechanism | 调用 `load_skill` 后，对应 `tool_result` 中含完整 body；下一轮模型可基于 body 推理 |
| AC-4 | discovery 信息够用 | edge-case | 故意把某个 skill 的 description 设为空，模型不再调用它（暴露"目录太弱"问题） |
| AC-5 | 不强制每轮加载 | mechanism | 一个不需要任何 skill 的简单问候，模型不应调用 `load_skill` |

**Scoring**
- PASS: all 5 ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4 或 AC-5 缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

### Task 2: 边界判断练习 [Optional, Weight 30%]
**Prompt**: 给定 10 条信息（混合"任务做法 / 长期事实 / 全局规则"），把每条分类到 `skill` / `memory` / `CLAUDE.md`，并解释判断依据。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 分类准确率 | functional | ≥8/10 正确 |
| AC-2 | 判断依据 | mechanism | 对每条说明"是任务做法 / 长期事实 / 全局规则"中的哪一类，且自洽 |

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task 1 PASS
3. 总练习分数 ≥75%（Task 2 可加分但不必须）

**On FAIL**: 回到 Tutor Loop，不晋级到 s06。

## Memory Mnemonic
> Skill 不是多一个工具，是把可选知识从常驻 prompt 里拆出来、按需加载。

## Navigation
- Previous: [[Subagent]] (s04)
- Next: [[ContextCompression]] (s06)
