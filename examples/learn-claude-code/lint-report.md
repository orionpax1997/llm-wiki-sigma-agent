# Lint Report — 2026-05-08
**Status: FIXED** (all items resolved 2026-05-08)

---

## 1. Orphan Pages

**2 concept orphans** (no inbound `[[wikilinks]]` from any other page):

| Page | Why orphaned |
|------|-------------|
| `concepts/ReferenceModuleMap.md` | Linked from index but no concept/source page links to it |
| `concepts/SessionManagement.md` | Linked from index but no concept/source page links to it |

**33 source orphans** (expected — sources are source material, linked only from `index.md` and `overview.md`, not from other wiki pages): all `learn.shareai.run-zh-*` and both `claude.com-blog-*` source pages.

**Action**: These 2 concept pages need inbound links from related concepts:
- `ReferenceModuleMap` → should be linked from `ArchitectureOverview`, `CodeReadingOrder`, or `learn.shareai.run-zh-s00e`
- `SessionManagement` → should be linked from `Subagent`, `ContextCompression`, or `AgentLoop`

---

## 2. Broken Links (8 found)

| Source File | Line | Broken Link | Fix |
|-------------|------|-------------|-----|
| `sources/learn.shareai.run-zh-s19a-mcp-capability-layers.md` | 25 | `[[MCPToolSpec]]` | Create `concepts/MCPToolSpec.md` |
| `sources/learn.shareai.run-zh-s19a-mcp-capability-layers.md` | 26 | `[[MCPServerConnectionState]]` | Create `concepts/MCPServerConnectionState.md` |
| `sources/learn.shareai.run-zh-entity-map.md` | 25 | `[[RuntimeTaskModel]]` | Create `concepts/RuntimeTaskModel.md` |
| `concepts/MCPCapabilityLayers.md` | 34 | `[[MCPServerConnectionState]]` | Create `concepts/MCPServerConnectionState.md` |
| `concepts/TaskSystem.md` | 10 | `[[learn.shareai.run-zh-s13a]]` | Change to `[[learn.shareai.run-zh-s13a-runtime-task-model]]` |
| `concepts/PromptPipeline.md` | 10 | `[[learn.shareai.run-zh-s10a]]` | Change to `[[learn.shareai.run-zh-s10a-message-prompt-pipeline]]` |
| `concepts/EntityMap.md` | 55 | `[[RuntimeTaskModel]]` | Create `concepts/RuntimeTaskModel.md` |
| `concepts/ToolControlPlane.md` | 10 | `[[learn.shareai.run-zh-s02a]]` | Change to `[[learn.shareai.run-zh-s02a-tool-control-plane]]` |

**Root cause pattern**: 3 missing concept pages + 3 slug mismatches (wikilinks use short form `-s13a` but actual file is `-s13a-runtime-task-model.md`).

---

## 3. Log Coverage

**1 source missing from `wiki/log.md`**:

- `wiki/sources/learn.shareai.run-zh-s12.md` ("S12 · 任务系统 / Task System") — no `## [date] ingest | S12` entry in log. Fix: add missing entry.

---

## 4. Contradictions

### Genuine: HookSystem vs. subagents blog — subagent lifecycle hooks

| Page | Claim |
|------|-------|
| `concepts/HookSystem.md` | "多 agent 事件扩展（子 agent 启动、任务完成、队友空闲）" is **explicitly deferred** to future chapters |
| `sources/claude.com-blog-subagents-in-claude-code.md` | Hooks are presented as an **established feature** that automates subagent workflows |

**Analysis**: The blog describes production Claude Code hooks for subagent automation. The HookSystem teaching concept covers a minimal implementation (SessionStart/PreToolUse/PostToolUse only). Not logically contradictory — minimal defers to production. But the wiki should acknowledge the gap explicitly.

**Fix**: Add note to `concepts/HookSystem.md` System Position or Contradictions section.

### Framing tension (non-blocking): SessionManagement vs. ContextCompression — compaction trigger

Both descriptions are consistent at implementation level (both include automatic triggering). This is a framing/emphasis difference, not a factual contradiction.

---

## 5. Stale Summaries

No stale summaries detected. The 2 new blog sources are freshly ingested. `overview.md` last_updated = 2026-05-08.

---

## 6. Missing Entity Pages

| Entity | Mentions | Has Page? | Action |
|--------|----------|-----------|--------|
| `Anthropic` | ~5+ | No | Create `wiki/entities/Anthropic.md` |
| `Claude Code` | ~14+ | No | Create `wiki/entities/ClaudeCode.md` |

---

## 7. Data Gaps

The wiki cannot currently answer these questions:

| Gap | What to find | Suggested source |
|-----|-------------|-----------------|
| **MCP elicitation** | How does elicitation work? How is it different from a tool call? | MCP spec docs |
| **Agent Teams vs. subagents** | When is Agent Teams (heavier, multi-session) better than subagents (lighter, single session)? | [Claude Code agent teams docs](https://code.claude.com/docs/en/agent-teams) — referenced in subagents blog |
| **Skill in CLAUDE.md patterns** | How does CLAUDE.md embed subagent invocation rules? | Already in `claude.com-blog-subagents-in-claude-code.md` source, needs a concept extraction |

---

## Summary

| Category | Count | Severity |
|----------|-------|----------|
| Broken links | 8 | Medium (fix slugs + create 3 concept pages) |
| Orphan concepts | 2 | Low (add links from related concepts) |
| Missing entity pages | 2 | Low (Anthropic + Claude Code) |
| Log coverage gap | 1 | Low (add s12 log entry) |
| Contradictions | 1 | Low (framing, not factual) |
| Data gaps | 3 | Medium (suggested sources) |
| Stale content | 0 | — |

**Priority fixes before next ingest**:
1. Fix 3 slug-mismatch wikilinks (s02a/s10a/s13a)
2. Create `MCPServerConnectionState` concept page (referenced 2×)
3. Create `MCPToolSpec` concept page
4. Create `RuntimeTaskModel` concept page
5. Add s12 to `wiki/log.md`
6. Add inbound links to `ReferenceModuleMap` and `SessionManagement`
