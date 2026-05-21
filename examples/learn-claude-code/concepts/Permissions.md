---
title: "Permissions"
type: concept
tags: [curriculum, agent-core, security]
sources: [learn.shareai.run-zh-s07]
last_updated: 2026-05-07
---

## Core Thesis
> 任何工具调用，都不应该直接执行；中间必须先过一条权限管道。

## Problem Definition
当 agent 能读文件、改文件、跑命令之后，模型可能写错文件、执行危险命令、在不该动手的时候动手。权限系统解决的是“意图不能直接变成执行”的问题——让 agent 的行动先经过一道可靠的安全判断。

## Terminology
| Term | Definition |
|------|------------|
| PermissionRule | 针对某工具的匹配规则，决定命中后行为（allow / deny / ask） |
| PermissionMode | 系统当前总体风格：default / plan / auto |
| PermissionDecision | 决策结果，含 behavior（allow/ask/deny）和 reason |
| Deny Rules | 最高优先级规则，命中即拒绝（如 sudo、rm -rf） |
| Allow Rules | 安全操作白名单，命中即放行（如读文件、git status） |
| Rejection Count | 连续拒绝计数，用于诊断 agent 是否卡住 |

## Mental Model

```
tool_call
  |
  v
1. deny rules     -> 命中就拒绝
  |
  v
2. mode check     -> 根据当前模式决定
  |
  v
3. allow rules    -> 命中就放行
  |
  v
4. ask user       -> 灰区交给用户确认
```

## Minimal Implementation

```python
def check_permission(tool_name: str, tool_input: dict) -> dict:
    # 1. deny rules
    for rule in deny_rules:
        if matches(rule, tool_name, tool_input):
            return {"behavior": "deny", "reason": "matched deny rule"}

    # 2. mode
    if mode == "plan" and tool_name in WRITE_TOOLS:
        return {"behavior": "deny", "reason": "plan mode blocks writes"}
    if mode == "auto" and tool_name in READ_ONLY_TOOLS:
        return {"behavior": "allow", "reason": "auto mode allows reads"}

    # 3. allow rules
    for rule in allow_rules:
        if matches(rule, tool_name, tool_input):
            return {"behavior": "allow", "reason": "matched allow rule"}

    # 4. fallback
    return {"behavior": "ask", "reason": "needs confirmation"}
```

接入执行前：

```python
decision = perms.check(tool_name, tool_input)

if decision["behavior"] == "deny":
    return f"Permission denied: {decision['reason']}"
if decision["behavior"] == "ask":
    ok = ask_user(...)
    if not ok:
        return "Permission denied by user"

return handler(**tool_input)
```

## System Position
- Inherits from: [[AgentLoop]], [[ToolRouting]]
- Prepares for: [[PromptPipeline]]（s10，当前权限模式作为 dynamic_context 汇入系统输入）、[[ErrorRecovery]]（s11）
- Cross-links: [[ToolControlPlane]]（s02a 预告的完整控制平面）

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 把权限当布尔开关 | 系统只有“有/无权限”两种状态，无法表达灰区 | 问：如果操作不危险但也不常见，系统会怎么处理？ |
| allow 排在 deny 前面 | 危险命令被模式或白名单意外放行 | 问：sudo 在 plan 模式下还能执行吗？ |
| 不做 bash 特殊检查 | 模型通过 bash 绕过文件/路径限制 | 问：bash 和普通文件工具在权限上有什么区别？ |
| 模式过多过杂 | 初学者被 6+ 模式淹没，抓不住主线 | 问：最少需要几种模式就能覆盖 80% 场景？ |
| 忽略拒绝计数 | agent 连续被拒绝后原地循环，用户无感知 | 问：如果 agent 连续 5 次被拒绝，系统会做什么？ |

## Diagnostic Questions (Step 1)
1. 为什么权限系统不是“有没有权限”这样一个布尔值？
2. 为什么 deny 要先于 allow？
3. 为什么推荐先做 3 个模式，而不是一上来做很复杂？
4. 为什么 bash 要被特殊对待？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 如果模型想读一个文件，权限管道会走哪几步？
- plan 模式和 auto 模式的区别是什么？
### Advanced
- 如果 deny rule 和 allow rule 同时命中，结果是什么？为什么？
- 设计一个场景，让 auto 模式反而比 default 更安全。

## Hint Escalation Ladder (Step 3c)
| Level | Hint |
|-------|------|
| L1 Rephrase | 权限系统解决的是“意图”到“执行”之间的什么问题？ |
| L2 Guide | 先想哪些操作绝对不应该发生，再想哪些操作绝对安全，最后剩下的怎么办？ |
| L3 Analogy | 像机场安检：绝对违禁品直接没收（deny），常客快速通道（allow），其他人过安检门（ask）。 |
| L4 Deconstruct | 把 check_permission 的四步拆开，每一步只回答一个问题。 |
| L5 Worked Example | 走一遍 `bash rm -rf /` 在四步管道里的命运。 |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| “权限系统让 agent 更笨” | 加了权限后 agent 还能自动执行吗？ | auto 模式下读文件仍然自动过；权限是让行动更可靠，不是更慢 |
| “plan 模式完全不能做事” | plan 模式下能读文件吗？ | plan 只禁止写操作，读和分析仍然自由 |
| “bash 和普通工具一样检查就行” | bash 能做什么 read_file 做不到的事？ | bash 可以 `cat /etc/passwd` 然后 `curl` 发出去，跨越单一工具边界 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | 四步管道的顺序是什么？ | 能正确说出 deny → mode → allow → ask |
| Causal | 为什么 deny 必须优先？ | 能举出“模式/白名单意外放行危险操作”的例子 |
| Application | 给一个新工具，能写出合适的 PermissionRule | 规则包含 tool、匹配条件、behavior |
| Discrimination | default 和 auto 模式在什么场景下选择不同？ | 能根据“操作可预测性”和“用户在场与否”判断 |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 最小权限系统 [Required, Weight 100%]
**Prompt**: 实现 `check_permission(tool_name, tool_input)`，支持 default / plan / auto 三种模式，至少包含 deny_rules 和 allow_rules 两类规则，对 bash 做最小安全检查（sudo / rm -rf）。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | default 模式下未知操作 ask 用户 | functional | 返回 behavior="ask" |
| AC-2 | plan 模式下写操作 deny | functional | 返回 behavior="deny" |
| AC-3 | auto 模式下读操作 allow | functional | 返回 behavior="allow" |
| AC-4 | bash 含 sudo 时 deny | edge-case | 返回 behavior="deny" |
| AC-5 | deny rule 优先级高于 allow rule | mechanism | 同时命中时返回 deny |

**Scoring**
- PASS: all ACs pass
- NEEDS_WORK: core ACs pass, mechanism/edge missed (1 rework allowed)
- FAIL: any core AC fails

## Chapter-level Pass Criteria
Learner passes this concept iff:
1. Mastery Check (Step 3g) all dimensions ≥75%
2. Required Task(s) PASS
3. Total practice score ≥75%

**On FAIL**: return to Tutor Loop, do not advance.

## Memory Mnemonic
> 权限系统不是为了让 agent 更笨，而是为了让 agent 的行动先经过一道可靠的安全判断。

## Navigation
- Previous: [[ContextCompression]]
- Next: [[HookSystem]] (s08)
