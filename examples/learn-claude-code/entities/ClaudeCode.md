---
title: "Claude Code"
type: entity
tags: [product, tool, claude]
sources: [claude.com-blog-subagents-in-claude-code, claaude.com-blog-using-claude-code-session-management-and-1m-context]
last_updated: 2026-05-08
---

## Definition
Claude Code 是 Anthropic 开发的 AI 编程工具，以 CLI 形式运行，支持终端、VS Code、JetBrains、Web 和桌面应用。

## Key Facts
- 1M token 上下文窗口
- 内置 subagent 支持（general-purpose / plan / Explore 三种类型）
- 支持自定义 subagent（`.claude/agents/` 或 `~/.claude/agents/`）
- 支持 skills（`.claude/skills/`）按需加载
- 支持 hooks 自动化工作流
- 支持 CLAUDE.md 项目级指令
- 内置上下文旋进（context rot）管理：compaction、rewind、/clear、subagent 等工具

## Connections
- [[Anthropic]] — Claude Code 由 Anthropic 开发
- [[Subagent]] — Claude Code 的核心功能之一
- [[SessionManagement]] — Claude Code 的上下文管理策略
- [[SkillSystem]] — Claude Code 支持 skills
- [[HookSystem]] — Claude Code 支持 hooks
- [[MCP]] — Claude Code 通过 MCP 协议扩展外部工具
