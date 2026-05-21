---
title: "ToolRouting"
type: concept
tags: [curriculum, tool-routing, dispatch-map, beginner]
sources: [learn.shareai.run-zh-s02]
last_updated: 2026-05-07
---

## Core Thesis
> 工具路由的本质是一张 `{tool_name: handler_function}` 字典——加新工具只需要加 handler 和 schema，主循环（[[AgentLoop]]）永远不变。

## Problem Definition
s01 的 [[AgentLoop]] 只接了一个 `bash` 工具，所有文件操作都走 shell。这带来两个真实问题：

- `cat` 截断不可预测、`sed` 遇特殊字符就崩——shell 命令对结构化操作很脆。
- 每次 bash 调用都是**不受约束的安全面**：模型可以 `rm -rf /`，可以 `cd ..` 越出工作区。

- **学完前**：你只会把所有工具塞进 `bash`，要么用 if/elif 在循环里硬编码分支。
- **学完后**：你能在不改循环一行的前提下，新增 `read_file` / `write_file` / `edit_file` 等任意专用工具，且每个工具都能独立做路径沙箱、参数校验、权限检查。

## Terminology
| Term | Definition |
|------|------------|
| dispatch map | 形如 `{tool_name: handler_function}` 的字典，是工具路由的唯一查找入口 |
| handler | 单个工具的处理函数，签名 `(**kwargs) -> str`（或返回 tool_result content） |
| tool schema | 给**模型**看的工具说明（JSON Schema 形式），描述 name / description / input_schema |
| safe_path | 把相对路径 resolve 到 `WORKDIR`，并验证不逃逸的辅助函数 |
| WORKDIR | agent 被限制操作的根目录；所有路径必须 relative to 它 |
| tool control plane | 工具层成熟形态：除 dispatch 外还含权限、app state、MCP、缓存、通知；本章不展开 |

## Mental Model
```text
+--------+      +-------+      +------------------+
|  User  | ---> |  LLM  | ---> | Tool Dispatch    |
| prompt |      |       |      | {                |
+--------+      +---+---+      |   bash: run_bash |
                    ^          |   read: run_read |
                    |          |   write: run_wr  |
                    +----------+   edit: run_edit |
                    tool_result| }                |
                               +------------------+
```

**关键：dispatch map 是 dict——一次查找替换任何 if/elif 链。**

## Minimal Implementation
"130 LOC 边界"：路径沙箱 + dispatch map + 循环按名查找。

```python
# 1) 路径沙箱（read/write/edit 共用前置）
def safe_path(p: str) -> Path:
    path = (WORKDIR / p).resolve()
    if not path.is_relative_to(WORKDIR):
        raise ValueError(f"Path escapes workspace: {p}")
    return path

def run_read(path: str, limit: int = None) -> str:
    text = safe_path(path).read_text()
    lines = text.splitlines()
    if limit and limit < len(lines):
        lines = lines[:limit]
    return "\n".join(lines)[:50000]

# 2) dispatch map：加工具 = 加这一行
TOOL_HANDLERS = {
    "bash":       lambda **kw: run_bash(kw["command"]),
    "read_file":  lambda **kw: run_read(kw["path"], kw.get("limit")),
    "write_file": lambda **kw: run_write(kw["path"], kw["content"]),
    "edit_file":  lambda **kw: run_edit(kw["path"], kw["old_text"],
                                        kw["new_text"]),
}

# 3) 循环中按名称查找（与 s01 主循环完全一致）
for block in response.content:
    if block.type == "tool_use":
        handler = TOOL_HANDLERS.get(block.name)
        output = handler(**block.input) if handler \
            else f"Unknown tool: {block.name}"
        results.append({
            "type": "tool_result",
            "tool_use_id": block.id,
            "content": output,
        })
```

**显式不在本章覆盖**（保留给后续章节 / [[ToolControlPlane]]）：
- 工具权限环境（→ s07 [[Permissions]]）
- 当前消息和 app state 注入
- MCP client 接入
- 文件读取缓存
- 通知与 query 跟踪
- 流式 / 并发执行

## System Position
- **Inherits from**: [[AgentLoop]] (s01) — 主循环在本章原封不动复用
- **Prepares for**: [[PlanningState]] (s03), [[ContextCompression]] (s06), [[Permissions]] (s07), [[ErrorRecovery]] (s11) — 都在 dispatch 之外或之上扩展
- **Cross-links**: [[MessageNormalization]] (本章次要概念，处理 API 协议硬约束)、[[PathSandbox]] (本章引入的安全机制)、`s02a-tool-control-plane` 描述工具层的完整形态

## Common Errors (Behavioral)
| Error | Symptom | Detection Prompt |
|-------|---------|-----------------|
| 用 if/elif 链在循环里分发工具 | 加一个工具就要改主循环；多人协作易冲突 | "你的循环代码里有几条 `if block.name == ...`？" |
| 不做路径沙箱 | 模型可以读写工作区外文件，甚至越权 | "如果模型说 `read_file('../../etc/passwd')`，会发生什么？" |
| `safe_path` 用字符串拼接而不是 `resolve()` | `..` 等符号链接绕过校验 | "你的安全路径函数会跟随 symlink 吗？" |
| handler 抛异常未捕获 | 整个 agent loop 崩溃，而不是只让本工具失败 | "工具失败时，下一轮模型还有机会读到错误信息吗？" |
| 加工具时同时改主循环 | 主线被污染；s01 的"循环不变"被打破 | "你这次提交动了循环代码吗？" |
| 把多工具塞回一个 bash | 又退回 s01 状态；失去了路径沙箱与参数校验 | "你为什么不给 read 单独建 handler？" |

## Diagnostic Questions (Step 1)
1. 为什么从 s01 (单 bash 工具) 走到 s02 (多工具)？bash 不够吗？
2. dispatch map 相比 if/elif 链的关键优势是什么（提示：不只是"代码更短"）？
3. `safe_path()` 里 `is_relative_to(WORKDIR)` 这一步在防什么具体攻击？
4. 主循环代码在 s02 中相对 s01 改了什么？没改什么？
5. 如果一个 tool_use 调用了不在 dispatch map 里的工具名，应该如何处理？

## Question Bank (Step 3b — Socratic)
### Entry-level
- 把 dispatch map 写成 `dict` 而不是 `match-case`，意味着什么？（提示：运行时可变 vs 编译期写死）
- `read_file` / `write_file` / `edit_file` 三个 handler 共享什么前置？
- 工具结果（return 值）最后会出现在哪里？被谁读到？

### Advanced
- 如果你想给某个工具加"在执行前要求用户确认"的能力，是改循环还是改 handler？为什么本章不在这里讲？
- dispatch map 为什么要传 `**kw`，而不是固定签名？（提示：每个工具的 input_schema 不同）
- "工具控制平面"在结构上是 dispatch 的超集还是替代？为什么文档说"先稳住 dispatch 再上控制平面"？
- 一个工具可以"动态注册"吗？比如运行时从 MCP server 拉取工具列表？dispatch map 这个数据结构支持吗？

## Hint Escalation Ladder (Step 3c)
| Level             | Hint                                                                          |
| ----------------- | ----------------------------------------------------------------------------- |
| L1 Rephrase       | 工具路由 = 一张 `{name: function}` 字典。                                              |
| L2 Guide          | 想想：if/elif 链有什么不爽？dict 怎么解决？                                                  |
| L3 Analogy        | dispatch map 像电话总机：来电按号码接到对应分机，加新分机不用重接所有线。                                   |
| L4 Deconstruct    | 三块：①sandbox 函数（可选）②handler 字典 ③循环里 `handler = TOOL_HANDLERS.get(block.name)`。 |
| L5 Worked Example | 见上方"最小实现"代码块；逐行对照 s01，确认主循环未变。                                                |

## Misconceptions (Step 3d — Cognitive)
| Misconception | Detection Question | Counter-example |
|---------------|-------------------|-----------------|
| "加工具就要改循环" | "本章主循环代码相对 s01 改了什么？" | 主循环完全不变；只新增 handler + schema。 |
| "工具路由就是 if/elif 重写为 switch" | "为什么要用 dict 而不是 `match`？" | dict 可在运行时增删（动态工具注册），且天然支持权限/缓存装饰。 |
| "`safe_path` 检查文件存不存在就够了" | "如果路径是 `../../../etc/passwd`，存不存在不重要——重要的是它在哪？" | 关键是 `is_relative_to(WORKDIR)`，存在性是另一回事。 |
| "工具层只是分发表" | "权限、缓存、通知应该放在循环里还是工具层？" | 工具层最终会成长为"控制平面"，但教学主线先稳住分发即可。 |

## Mastery Check (Step 3g)
| Dimension | Check Question | Pass Criterion |
|-----------|---------------|----------------|
| Accurate | dispatch map 的数据结构和签名是什么？ | 答出 `{tool_name: callable(**kwargs) -> str}` 或等价描述 |
| Causal | 为什么"加工具不改循环"是有价值的不变量？ | 答出"分支不污染主线 / 多工具贡献者互不干扰 / 主循环逻辑稳定" |
| Application | 给定一个新工具 `list_dir(path)`，写出它的 handler 注册和 input_schema | handler 加进 `TOOL_HANDLERS`、复用 `safe_path`、循环零改动 |
| Discrimination | 工具路由 vs 工具控制平面，区别是什么？ | 答出"路由只管 name → handler；控制平面还含权限/状态/缓存/外部源" |

**Session mastery threshold**: all dimensions ≥75%, overall ≥80%.

## Practice Tasks (Step 3h)
### Task 1: 在 s01 主循环上加 `read_file` 工具 [Required, Weight 60%]
**Prompt**: 复用 [[AgentLoop]] s01 的 30 行主循环，**不改循环代码**，新增一个 `read_file(path, limit=None)` 工具。要求：

- 实现 `safe_path(p)` 沙箱函数，阻止逃逸 `WORKDIR`
- 把 handler 注册进 `TOOL_HANDLERS` 字典
- 写出 `read_file` 的 tool schema (JSON Schema)
- 用 prompt `Read the file requirements.txt` 验证

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 主循环未改 | functional | `git diff` 显示循环代码 0 改动 |
| AC-2 | dispatch map 注册 | functional | `TOOL_HANDLERS["read_file"]` 存在且可调用 |
| AC-3 | 路径沙箱有效 | edge-case | `read_file("../../etc/passwd")` 抛 `ValueError` |
| AC-4 | tool_result 回流 | mechanism | 工具输出包成 `{type: "tool_result", tool_use_id, content}` 写回 messages |

### Task 2: 加第二个工具，验证"循环不变" [Required, Weight 40%]
**Prompt**: 在 Task 1 基础上加 `write_file(path, content)`。再次确认：(a) 循环代码 0 改动；(b) 两个工具共享 `safe_path`；(c) 模型可以连续调用 read → write。

**Acceptance Criteria**
| ID | Item | Type | Pass Rule |
|----|------|------|-----------|
| AC-1 | 循环再次未改 | functional | 与 Task 1 相同的循环代码 |
| AC-2 | 共享 sandbox | mechanism | write 和 read 都通过同一个 `safe_path` |
| AC-3 | 多工具同轮 | edge-case | 模型可以一次 tool_use list 里返回 read+write，全部成功 |

**Scoring**
- PASS: 两个 task 所有 AC 通过
- NEEDS_WORK: Task 1 PASS，Task 2 部分 AC 缺失（允许 1 次返工）
- FAIL: Task 1 任何 AC 不通过

## Chapter-level Pass Criteria
学习者通过本概念 iff:
1. Mastery Check (Step 3g) 各维度 ≥75%
2. Required Tasks PASS
3. 总练习分数 ≥75%

**On FAIL**: 回到 Tutor Loop，不晋级到 [[PlanningState]] (s03)。

## Memory Mnemonic
> 加工具 = 加 handler + 加 schema。循环永远不变。

## Navigation
- Previous: [[AgentLoop]] (s01)
- Next: [[PlanningState]] (s03，尚未 ingest)
