---
title: "S05 · Skill 系统 / 按需加载知识包"
type: source
tags: [curriculum, skill, on-demand-loading, prompt-budget, chinese, learn.shareai.run, beginner]
date: 2026-05-07
source_file: raw/learn.shareai.run-zh-s05.md
---

## Summary
`learn.shareai.run` 中文教程 s00–s19 系列的第五章。在 s01 ([[AgentLoop]]) + s02 ([[ToolRouting]]) + s03 ([[PlanningState]]) + s04 ([[Subagent]]) 之上，引入 **Skill 系统**：把"长期可选知识"从 system prompt 主体里**拆出来，改成按需加载**。核心做法是把每类任务的说明书（如 code-review、git-workflow、mcp-builder）变成独立的 `SKILL.md`，system prompt 里只放**轻量目录**（名称 + 描述），真正需要时才通过 `load_skill` 工具把完整正文作为 `tool_result` 注入当前上下文。本章刻意只守住两层心智模型——**轻量发现 + 重内容按需加载**——把多源收集 / 条件激活 / skill 参数化 / fork 式执行 / 复杂 prompt 管道全部留给 s10 系统化展开。同时显式划清 `skill` / `memory` / `CLAUDE.md` 三者边界。

## Key Claims
- 不同任务需要的领域知识不一样；如果把所有领域知识全塞进 system prompt，token 会被大量浪费在当前用不到的说明上，主线规则也会被淹没。
- Skill 系统的本质：**把"长期可选知识"从常驻 prompt 里拆出来，改成按需加载**——不是"多一个工具"，而是 prompt 预算的结构性重构。
- 三个关键名词必须分开：(1) **skill** = 一份围绕某类任务的可复用说明书；(2) **discovery** = 发现有哪些 skill 可用（轻量，只需名称 + 一句描述）；(3) **loading** = 把某个 skill 完整正文真正读进当前上下文（昂贵，才注入）。
- 最小心智模型只有两层：**第 1 层轻量目录**（让模型知道"有哪些可用"）+ **第 2 层按需正文**（只在真正需要时加载）。
- 三个关键数据结构：`SkillManifest { name, description }`（轻元信息）→ `SkillDocument { manifest, body }`（完整内容）→ `SkillRegistry: { name → SkillDocument }`（统一注册表，回答"有哪些可用 / 某个 skill 完整内容是什么"）。
- 最小实现 5 步：(1) 每个 skill 一个目录 + `SKILL.md`；(2) 从 frontmatter 读 manifest，body 单独留着；(3) `SKILL_REGISTRY.describe_available()` 把目录信息塞进 system prompt（**只放目录，不放正文**）；(4) 提供 `load_skill` 工具，调用时返回完整正文作为 `tool_result`；(5) skill 正文只在当前需要时进入上下文。
- system prompt 从此长出新结构：**稳定层**（身份、规则、工具、skill 目录）+ **按需层**（当前真的加载进来的 skill 正文）——这是 prompt 预算从"扁平 + 全量"走向"分层 + 按需"的第一步。
- `skill` / `memory` / `CLAUDE.md` 三者边界要分清：某类任务才需要的做法 → `skill`；需要长期记住的事实或偏好 → `memory`；更稳定的全局规则 → `CLAUDE.md`。
- 5 条初学者常见坑：(1) 把所有 skill 正文永远塞进 system prompt；(2) skill 目录信息写得太弱（只有名字没有描述）模型不知道何时加载；(3) 把 skill 当成"绝对规则"（应是"可选工作手册"）；(4) skill 与 memory 混为一类；(5) 一上来就讲多源加载 / 条件激活等高级细节，淹没主线。
- **教学边界**：本章**只讲 "轻量发现 + 按需深加载" 两层**——多来源收集 / 条件激活 / skill 参数化 / fork 式执行 / 更复杂的 prompt 管道拼装全部不在本章；这些留给 s10 系统化展开。
- **章节关系明确**：s05 = prompt 预算的结构性重构起点；s10 = 同主题的系统化扩展（多来源、条件激活、参数化等）。

## Key Quotes
> "把'长期可选知识'从 system prompt 主体里拆出来，改成按需加载。" — 这一章真正要做的是

> "discovery 这一层只需要很轻量的信息，例如：skill 名字、一句描述。" — 名词解释

> "loading 这一层才是昂贵的，因为它会把完整内容放进当前上下文。" — 名词解释

> "平时只展示'有哪些知识包'，真正工作时才把那一包展开。" — 第五步

> "skill 更像'可选工作手册'，不是所有轮次都必须用。" — 初学者最容易犯的错

> "Skill 系统的核心，不是'多一个工具'，而是'把可选知识从常驻 prompt 里拆出来，改成按需加载'。" — 一句话记住

## Connections
- [[AgentLoop]] — Skill 系统不改主循环：`load_skill` 是一个普通工具，沿用 s01 的 tool_use → tool_result 回路。
- [[ToolRouting]] — `load_skill` 复用 s02 的 dispatch map：`TOOL_HANDLERS["load_skill"] = lambda **kw: SKILL_REGISTRY.load_full_text(kw["name"])`，零改动主循环。
- [[Subagent]] — s04 是"局部任务的上下文边界"，s05 是"长期可选知识的按需加载"；二者都在解决"上下文该放什么"的问题，但角度正交：Subagent 削减**过程性噪声**，Skill 削减**常驻知识开销**。
- [[SkillSystem]] — 本章的核心教学概念（Teaching Concept）。
- 序列前后：上一章 [[learn.shareai.run-zh-s04|S04]]；下一章 s06（尚未 ingest，预告引入 [[ContextCompression]]）。
- 远期对照：s10 将系统化扩展 skill（多来源、条件激活、参数化、fork 执行、prompt 管道拼装）。

## Contradictions
（与现有 wiki 内容无矛盾。s05 在 s01–s04 主循环不变的承诺上**新增一种 prompt 结构**——把常驻 system prompt 分成"稳定层 + 按需层"，并将其实现完全寄生在 s02 的 dispatch map 之上，无逻辑冲突。）

## Pedagogical Material Inventory
本源富含教学元素，已用于构建 [[SkillSystem]] 的 Teaching Concept：
- 名词解释：skill / discovery / loading / SkillManifest / SkillDocument / SkillRegistry
- 心智模型：两层 ASCII 图（轻量目录 → 按需正文 + load_skill 调用流）
- 最小实现 5 步：skill 目录结构、frontmatter parse、`describe_available()` 注入 system prompt、`load_skill` 工具、按需注入正文
- 关键数据结构：`SkillManifest`、`SkillDocument`、`SkillRegistry`
- 边界澄清表：`skill` vs `memory` vs `CLAUDE.md`（一种简单判断法：任务做法 → skill；长期事实 → memory；全局规则 → CLAUDE.md）
- 5 条初学者常见错误（永远塞 / 描述太弱 / 当绝对规则 / 混 memory / 上来讲多源）
- 显式教学边界（明确"这一章不讲什么"——多源收集 / 条件激活 / 参数化 / fork / 复杂管道）
- 显式章节边界（s05 vs s10 的递进关系）
- 一句话记住："Skill 系统的核心，不是'多一个工具'，而是'把可选知识从常驻 prompt 里拆出来，改成按需加载'。"
