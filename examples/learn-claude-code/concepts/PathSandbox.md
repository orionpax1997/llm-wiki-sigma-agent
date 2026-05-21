---
title: "PathSandbox"
type: concept
tags: [security, tool-routing, path-sandbox]
sources: [learn.shareai.run-zh-s02]
last_updated: 2026-05-07
---

## Definition
`safe_path()` 模式：把工具收到的相对路径 resolve 到 `WORKDIR` 之下，并用 `is_relative_to(WORKDIR)` 验证不逃逸。这是 [[ToolRouting]] 中所有文件类工具 (`read_file` / `write_file` / `edit_file`) 共享的安全前置。

## Key Claims
- 路径沙箱的关键不是检查文件是否存在，而是验证 resolve 后的绝对路径仍在 `WORKDIR` 之下。
- 用 `Path.resolve()` 而不是字符串拼接——`resolve()` 会展开 `..` 与 symlink，避免被绕过。
- `is_relative_to(WORKDIR)` 是 Python 3.9+ 的标准做法；之前需用 `str(path).startswith(str(WORKDIR))`（更脆弱）。
- 没有路径沙箱时，模型可以 `read_file("../../etc/passwd")` 等越权读写。
- 沙箱属于"工具层"职责，不在主循环里做——这是 [[ToolRouting]] "循环不变"原则的具体例证之一。

## Minimal Implementation
```python
def safe_path(p: str) -> Path:
    path = (WORKDIR / p).resolve()
    if not path.is_relative_to(WORKDIR):
        raise ValueError(f"Path escapes workspace: {p}")
    return path
```

## Connections
- [[ToolRouting]] — 文件类工具的共享前置。
- [[AgentLoop]] — 沙箱失败抛出的 `ValueError` 应被 handler 捕获，包成 tool_result 回流（不让循环崩）。
- 后续 s07 [[Permissions]] 会在沙箱之上叠加更细的权限模型。
