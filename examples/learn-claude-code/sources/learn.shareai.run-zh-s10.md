---
title: "S10 · Prompt Pipeline / 系统输入组装"
type: source
tags: [curriculum, prompt-pipeline, system-prompt, agent-core]
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s10.md
---

## Summary
S10 不是新增一个功能模块，而是把 s05（skills）、s09（memory）、s07（权限模式）、动态环境信息等多个来源**组织成一条清晰的系统输入组装流水线**。核心心智模型：system prompt 不是一整块硬编码文本，而是由 6 段（core + tools + skills + memory + CLAUDE.md + dynamic_context）按顺序拼接出来的构建产物。关键边界：稳定说明 vs 动态提醒、system prompt vs system reminder。

## Key Claims
- system prompt 应该升级成"由多个来源共同组装出来的一条流水线"，而不是一大段固定文本。
- 6 段最小模型：core（身份和行为说明）、tools（工具列表）、skills（skills 元信息）、memory（memory 内容）、CLAUDE.md（指令链）、dynamic_context（动态环境信息）。
- 三条反对硬编码的理由：不好维护、不好测试、不好做缓存和动态更新。
- 稳定层（core / tools / skills / memory / CLAUDE.md）与动态层（date / cwd / model / current mode）应分开思考；可加 `=== DYNAMIC_BOUNDARY ===` 标记作为视觉提醒。
- system prompt 适合放身份、规则、工具、长期约束；system reminder 适合放本轮临时需要的补充上下文和当前变动状态。
- CLAUDE.md 不是临时上下文，而是更稳定的长期说明；教学仓链条：用户全局级 → 项目根目录级 → 当前子目录级，全部拼进去而非互相覆盖。
- memory 最终一定要进入 prompt 组装链条；否则保存了 memory 却不在系统输入中重新呈现，等于没被真正用起来。
- s10 是"汇合点"：s05 skills、s09 memory、s07 当前模式都可能汇进来；s19 MCP 以后也可能给 prompt 增加说明。

## Key Quotes
> "system prompt 的关键不是'写一段很长的话'，而是'把不同来源的信息按清晰边界组装起来'。"
> "prompt 不是一整块静态文本，而是一条被逐段组装出来的输入流水线。"
> "上面更稳定，下面更容易变。" — 关于 `=== DYNAMIC_BOUNDARY ===`
> "memory 最终一定要进入 prompt 组装链条。"

## Connections
- [[SkillSystem]] — s05 的 skills 元信息是 system prompt 的第 3 段来源；s10 将其系统化接入组装流水线。
- [[Memory]] — s09 的 memory 内容是 system prompt 的第 4 段来源；s10 明确 memory 必须重新注入系统输入。
- [[Permissions]] — s07 的当前模式（default / plan / auto）是 dynamic_context 的一部分，可能汇入 system prompt 或 system reminder。
- [[AgentLoop]] — 主循环的 `SYSTEM` 参数从静态字符串变为 `SystemPromptBuilder.build()` 的输出。
- [[ContextCompression]] — 压缩管"本会话太长"，s10 管"系统输入怎么拼"；两者都在管理模型看到的上下文，但层面不同。
- [[HookSystem]] — hook 可在 PreToolUse / PostToolUse 时机动态追加或修改 prompt 片段。
- s00a-query-control-plane — 建议联读，重新确认模型输入在进模型前经历了哪些控制层。
- s10a-message-prompt-pipeline — 建议联读，本章最关键的桥接文档。
- data-structures.md — 建议联读，把输入片段的来源重新拆开。

## Contradictions
- （无；s10 与 s01–s09 一致，是组织/汇合章节而非引入新冲突）
