---
title: "HookSystem"
type: concept
tags: [curriculum, agent-core, extensibility, hook]
sources: [learn.shareai.run-zh-s08, claude.com-blog-subagents-in-claude-code]
last_updated: 2026-05-08
---

## Core Thesis
> 主循环只负责暴露“时机”，真正的附加行为交给 hook。

## Problem Definition
到了 s07，agent 已能在工具执行前做权限判断。但很多真实需求不属于“允许/拒绝”这条线，而是：

- 会话开始时打印欢迎信息
- 工具执行前做一次额外检查
- 工具执行后补一条审计日志

如果每增加一个需求都去修改主循环，主循环会越来越重，最终谁都不敢动。

- **学完前**：你只能通过在主循环里塞 if/else 来扩展行为，主循环不断膨胀。
- **学完后**：你能在不改主循环的前提下，通过注册 hook 在固定时机插入观察、拦截、补充三种行为。

## Terminology
| Term | Definition |
|------|------------|
| HookEvent | 描述“现在发生了什么事 + 上下文是什么”的数据结构，含 `name` 和 `payload` |
| HookResult | hook 处理后的返回结果，含 `exit_code`（0/1/2）和 `message` |
| HookRunner | 统一运行 hook 的入口，主循环只调用它，不关心每个 hook 的具体实现 |
| SessionStart | 会话开始时的 hook 事件 |
| PreToolUse | 工具执行前的 hook 事件 |
| PostToolUse | 工具执行后的 hook 事件 |

## Mental Model
```text
主循环继续往前跑
  |
  +-- 到了某个预留时机
  |
  +-- 调用 hook runner
  |
  +-- 收到 hook 返回结果
  |
  +-- 决定继续、阻止、还是补充说明
```

**关键边界**：主循环知道事件名，hook runner 知道怎么调扩展逻辑。

## Minimal Implementation

### 1. 事件到处理器的映射
```python
HOOKS = {
    "SessionStart": [on_session_start],
    "PreToolUse": [pre_tool_guard],
    "PostToolUse": [post_tool_log],
}
```

### 2. 统一运行 hook
```python
def run_hooks(event_name: str, payload: dict) -> dict:
    for handler in HOOKS.get(event_name, []):
        result = handler(payload)
        if result["exit_code"] in (1, 2):
            return result
    return {"exit_code": 0, "message": ""}
```

### 3. 接入主循环
```python
pre = run_hooks("PreToolUse", {
    "tool_name": block.name,
    "input": block.input,
})

if pre["exit_code"] == 1:
    results.append(blocked_tool_result(pre["message"]))
    continue

if pre["exit_code"] == 2:
    messages.append({"role": "user", "content": pre["message"]})

output = run_tool(...)

post = run_hooks("PostToolUse", {
    "tool_name": block.name,
    "input": block.input,
    "output": output,
})
```

**显式不在本章覆盖**（保留给后续章节）：
- 不同事件采用不同返回语义的细化
- 生命周期事件扩展（结束、配置变化）
- 压缩事件扩展（压缩前、压缩后）
- 多 agent 事件扩展（子 agent 启动、任务完成、队友空闲）
- Hook 优先级/排序机制
- 异步 hook

## System Position
- **Inherits from**: [[AgentLoop]] (s01), [[ToolRouting]] (s02), [[Permissions]] (s07)
- **Prepares for**: [[PromptPipeline]] (s10，hook 可在固定时机动态修改 prompt 片段), [[ErrorRecovery]] (s11，hook 可介入恢复日志与恢复动作), [[ToolControlPlane]] (s02a 完整控制平面)
- **Cross-links**: [[ContextCompression]] (压缩前后可扩展为 hook 事件), [[Subagent]] (子 agent 生命周期可扩展为多 agent hook 事件)

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把 hook 当成“到处插 if” | 条件分支散落在主循环里，不是真正的 hook 设计 | “你的扩展逻辑是在主循环里写 if，还是在 HOOKS 映射里注册 handler？” |
| 没有统一的返回结构 | 今天返回字符串，明天返回布尔值，主循环变乱 | “你的 hook handler 返回什么类型？主循环怎么判断？” |
| 一上来就把所有事件做全 | 初学者被几十种事件淹没，抓不住核心模型 | “你能先用 3 个事件跑通一个完整场景吗？” |
| 忘了说明“教学版统一语义”和“高完成度细化语义”的区别 | 读者看到复杂实现时以为前面学错了 | “教学版的 0/1/2 和高完成度系统的多语义是什么关系？” |

## Diagnostic Questions (Step 1)
1. 为什么 hook 比“在主循环里加 if/else”更好？
2. 教学版统一返回约定的 0/1/2 分别代表什么？
3. 主循环需要知道 hook 的具体实现吗？
4. PreToolUse 和 PostToolUse 分别能在什么场景下使用？

## Question Bank (Step 3b — Socratic)
### Entry-level
- hook 和主循环的关系是什么？是替代还是补充？
- 如果 PreToolUse 返回 exit_code=1，主循环应该做什么？
- 为什么教学版只讲 3 个事件，而不是把所有可能的事件都列出来？

### Advanced
- 权限系统（s07）可以看作 PreToolUse hook 的一种实现吗？为什么？
- 如果不同事件需要不同的返回语义，如何在不破坏主循环的前提下扩展？
- 上下文压缩（s06）的压缩前/压缩后，适合做成 hook 事件吗？为什么？

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | Hook = 主循环在固定时机对外发出的调用。 |
| L2 Guide | 想想：如果每个新需求都改主循环，主循环会变成什么样？ |
| L3 Analogy | 主循环像一条流水线，hook 是流水线上的检测站——可以加站，但不用改流水线本身。 |
| L4 Deconstruct | 四步：①定义事件 ②写 handler ③注册到 HOOKS ④主循环在时机点调用 run_hooks。 |
| L5 Worked Example | 见上方“最小实现”代码块；对照 s01 主循环，确认循环代码未变。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| “hook 就是回调函数” | “回调和 hook 在主循环中的角色有什么区别？” | hook 是系统级扩展点，有统一协议（event + payload + result）；回调通常是业务级异步通知。 |
| “加 hook 就要改主循环” | “本章主循环代码相对 s01 改了什么？” | 主循环只增加 `run_hooks` 调用点，核心结构不变。 |
| “0/1/2 返回约定是唯一正确的做法” | “真实系统里不同事件会有不同语义吗？” | 教学版先统一，后续再细化；0/1/2 是教学模型，不是终极规范。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | hook 的三要素是什么？ | 答出“事件名 + payload + 返回结果” |
| Causal | 为什么 hook 能让主循环不变而系统可扩展？ | 答出“主循环只暴露时机，具体行为在 HOOKS 映射中注册” |
| Application | 给一个新场景（如“工具执行后记录审计日志”），写出 hook 注册和 handler | handler 返回正确 exit_code，注册到 PostToolUse |
| Discrimination | hook 和“在主循环里加 if/else”的本质区别是什么？ | 答出“hook 是声明式注册，if/else 是侵入式修改” |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 实现最小 Hook 系统 [Required, Weight 100%]
**Prompt**: 在 s01 主循环基础上，不改循环核心结构，增加 hook 机制。要求：

- 实现 `run_hooks(event_name, payload)`，支持从 `HOOKS` 映射查找 handler
- 支持 SessionStart、PreToolUse、PostToolUse 三个事件
- 统一返回 `{"exit_code": 0|1|2, "message": ""}`
- PreToolUse exit=1 时阻止工具执行并返回 blocked result
- PreToolUse exit=2 时先向 messages 注入补充消息，再继续执行工具
- PostToolUse exit=2 时追加补充说明

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | HOOKS 映射注册 | functional | `HOOKS["PreToolUse"]` 存在且可调用 |
| AC-2 | 统一返回结构 | functional | handler 返回 dict 含 `exit_code` 和 `message` |
| AC-3 | PreToolUse 阻止 | edge-case | exit=1 时工具不执行，返回 blocked result |
| AC-4 | PreToolUse 注入 | mechanism | exit=2 时先 append 消息到 messages，再执行工具 |
| AC-5 | PostToolUse 追加 | mechanism | exit=2 时追加补充说明 |
| AC-6 | 主循环核心未改 | functional | while 循环结构、tool 执行逻辑与 s01 一致 |

**Scoring**
- PASS: all ACs pass
- NEEDS_WORK: AC-1/2/3 pass，AC-4/5/6 部分缺失（允许 1 次返工）
- FAIL: AC-1/2/3 任何一条不通过

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Task PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到 s09。

## Memory Mnemonic
> Hook 不是改写主循环，而是在固定时机插入行为。

## Navigation
- Previous: [[Permissions]] (s07)
- Next: [[Memory]] (s09)
