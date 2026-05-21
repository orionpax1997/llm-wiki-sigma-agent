---
title: "Subagents in Claude Code"
type: source
tags: [claude-code, subagents, delegation, parallel-execution]
date: 2025-05-08
source_file: raw/claude.com-blog-subagents-in-claude-code.md
---

## Summary
关于 Claude Code 中 subagent 的完整使用指南：何时使用、如何调用（对话式 / 自定义 agent / CLAUDE.md / skills / hooks）、实战模式，以及何时不应该用 subagent。

## Key Claims
- Subagent 是有独立 context window 的隔离 Claude 实例，执行完只返回结论，不返回中间工具输出
- Subagent 有三种内置类型：general-purpose、plan、Explore（快速只读搜索）
- **何时使用 subagent**：研究密集型任务 / 多个独立任务 / 需要无偏视角 / 提交前验证 / pipeline 流水线工作
- **信号**：需要读 10+ 文件，或有 3+ 个独立 piece 的工作
- 提示词结构要好：明确作用域、要求并行执行、指定输出格式
- 自定义 subagent：写在 `.claude/agents/`（项目级）或 `~/.claude/agents/`（用户级），由 description 字段决定何时自动路由
- CLAUDE.md 可嵌入 subagent 触发规则，实现全团队一致的委托策略
- Skills 是比 CLAUDE.md 更轻量、按需加载的工作流，subagent 可以在 skills 里并行执行
- Hook 可以自动化 subagent 工作流（如每次 commit 前自动 review）
- **何时不用**：顺序依赖的工作 / 同一文件并行编辑 / 小任务 / 需要 subagent 之间互相协调（用 Agent Teams）

## Subagent Types
- **General-purpose** — 复杂多步任务
- **Plan** — 研究代码库后提出实现策略
- **Explore** — 快速只读代码搜索

## When to Use Subagents

| Pattern | Signal | Benefit |
|---|---|---|
| Research-heavy | Need to read dozens of files | Synthesized findings, not raw context |
| Multiple independent tasks | Sub-tasks have no dependencies | Parallel work → faster |
| Fresh perspective | Need unbiased review | Clean slate without history |
| Verification before commit | Second opinion warranted | Catch blind spots |
| Pipeline workflows | Sequential stages with handoffs | Focused attention per phase |

## Invocation Methods (by increasing sophistication)
1. **Conversational** — 自然语言提示触发，最灵活
2. **Custom subagents** — 定义一次，自动路由
3. **CLAUDE.md** — 嵌入规则，全团队一致
4. **Skills** — 按需加载的可复用工作流
5. **Hooks** — 事件驱动自动化

## Custom Subagent YAML Frontmatter

```yaml
---
name: security-reviewer
description: Reviews code changes for security vulnerabilities...
tools: Read, Grep, Glob
model: sonnet
---
```

## Hook Example: Stop Hook for Tests

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-tests.sh"
      }]
    }]
  }
}
```

## Connections
- [[ContextCompression]] — subagent 通过只返回结论来减少主会话的上下文压力
- [[AgentLoop]] — subagent 是主循环外的独立执行单元
- [[Subagent]] — 深化 s04 中 subagent 概念的具体用法和最佳实践
- [[HookSystem]] — hooks 可驱动 subagent 工作流自动化
- [[SkillSystem]] — skills 可在内部并行调用多个 subagent

## Contradictions
- [[Subagent]] 教学章节描述 subagent "只回摘要"——本文补充说明 subagent 可以返回结构化报告（通过指定输出格式），本质上仍是摘要而非全文
