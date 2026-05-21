---
title: "S10a · 消息与 Prompt 管道"
type: source
tags: []
date: 2026-05-08
source_file: raw/learn.shareai.run-zh-s10a-message-prompt-pipeline.md
---

## Summary
在 s10 system prompt builder 基础上解释为什么真正送给模型的输入不只是 system prompt：还包括规范化后的 messages、memory attachments、hook 注入消息、system reminder、当前轮动态上下文，所有来源先分清边界再统一整理成 final API payload，并给出"什么该进 prompt block、什么该进 message 流、什么该做 attachment"的判断法。

## Key Claims
- system prompt 不是全部输入，它只是输入管道中的一段
- normalized message 把不同来源/格式的消息整理成统一稳定格式
- system reminder 是当前轮或当前阶段临时追加的动态上下文，不是长期规则
- 真正送给模型的是"prompt blocks + normalized messages + attachments + reminders"组成的输入管道
- builder 是 prompt 的内部结构，pipeline 是模型输入的整体结构

## Key Quotes
> "真正送给模型的，不只是一个 prompt，而是'prompt blocks + normalized messages + attachments + reminders'组成的输入管道。" — s10a

## Connections
- [[PromptPipeline]] — s10a 扩展 s10 的 PromptPipeline 概念，增加 message normalization 和完整输入管道
- [[Memory]] — memory 作为 attachment 进入输入管道
- [[HookSystem]] — hook 注入消息作为管道的一个来源

## Contradictions
（无）
