# Sigma (Wiki-grounded variant)

`/sigma-with-wiki` — same Bloom 2-Sigma tutor as `/sigma`, but the curriculum, the order, and the source of truth for every teaching turn all come from this repo's local LLM Wiki. The user never picks a topic.

`/sigma` already does Socratic questioning, mastery gating, misconception tracking, interleaving, spaced repetition, calibrated practice, and cross-topic learner profiling. This variant adds three structural changes on top:

1. **No user-supplied topic.** The wiki *is* the curriculum. On 开始学习 / start learning, the skill reads `wiki/overview.md` + `wiki/index.md` and builds the entire roadmap from what the wiki itself declares its scope to be.
2. **Wiki-driven roadmap with explicit page tracking.** Every concept row in `session.md` carries a `Wiki Pages` column listing the wiki `.md` files that define it.
3. **Wiki-grounded teaching.** At the start of each concept's tutor loop (Step 3.0), the tutor MUST re-read the listed wiki pages before asking any tutoring question. Drift from the source is treated as a violation of the skill, not a stylistic choice.

If `wiki/overview.md` or `wiki/index.md` is missing, the skill aborts with a clear message — fall back to plain `/sigma` for ungrounded tutoring.

## Why a separate skill instead of a flag on /sigma?

`/sigma` is portable and ships with no project assumptions. `/sigma-with-wiki` assumes a specific project structure (the LLM Wiki schema in this repo's root `CLAUDE.md`) AND a specific invocation model (no topic argument — the wiki defines scope). Splitting them keeps both honest.

## Usage

The skill is invoked with an **intent**, not a topic:

```bash
/sigma-with-wiki                 # auto: resume if a session exists, else start fresh
/sigma-with-wiki fresh           # explicitly start over (archives the existing session)
/sigma-with-wiki resume          # explicitly resume; errors if no session exists

# Natural-language triggers also work:
开始学习                          # start learning (auto)
继续学习                          # continue learning (resume)
start learning
continue learning
从 wiki 开始教我
resume the wiki tutor
```

### Arguments

| Argument | Description |
|----------|-------------|
| `<intent>` | Optional. `fresh` / `resume` / `auto` (default). **No topic argument** — the wiki defines scope. |
| `--level <level>` | Starting level: `beginner`, `intermediate`, `advanced` (default: diagnose) |
| `--lang <code>` | Language override (default: follow user's input language) |
| `--visual` | Force rich visual output every round |
| `--wiki-root <path>` | Override wiki root (default: `wiki/` relative to cwd) |

### Intent resolution

| Intent | Session exists? | Action |
|--------|-----------------|--------|
| `fresh` | yes | Confirm overwrite; archive current `session/` to `session.archived-{YYYYMMDD-HHMM}/`, then start new |
| `fresh` | no | Start new |
| `resume` | yes | Resume |
| `resume` | no | Tell user there is nothing to resume; offer to start fresh |
| `auto` | yes | Resume |
| `auto` | no | Start new |

## How It Works

```
Intent → Wiki Survey → Diagnose → Build Wiki-Driven Roadmap → Tutor Loop → Session End
            |                                                       |
   overview.md + index.md                                  [Wiki Read Gate]  ← runs at every concept entry
   → curriculum scope                                              |
   → narrative order                                  Question / Misconception / Mastery / Practice
   → per-concept wiki pages
```

### 1. Wiki Survey (replaces topic-parsing)

Before diagnosing or building the roadmap, the skill reads `wiki/overview.md` and `wiki/index.md` in full to extract:

- **Curriculum scope** — every atomic concept the wiki currently declares (from the `## Concepts` section of `index.md`, filtered by `overview.md`'s `Current Scope` block).
- **Narrative order** — the order the wiki itself uses (Threads in Progress, anchored quote sequence, chapter numbering).
- **Cross-links** — `[[WikiLinks]]` between concept pages, used as prerequisite hints on the roadmap.

The wiki *is* the curriculum. The skill does not narrow to a sub-topic and does not invent concepts the wiki does not list. If the wiki has no concept pages yet, the skill stops and asks the user to ingest more sources first — it does NOT fall back to general knowledge.

### 2. Build Wiki-Driven Roadmap

The roadmap is the survey output ordered by dependency. `session.md`'s Concept Map gains a required column:

| # | Concept | Wiki Pages | Prerequisites | Status | Score | Last Reviewed | Review Interval |
|---|---------|------------|---------------|--------|-------|---------------|-----------------|
| 1 | AgentLoop | concepts/AgentLoop.md, sources/learn.shareai.run-zh-s01.md | - | not-started | - | - | - |
| 2 | ToolRouting | concepts/ToolRouting.md, sources/learn.shareai.run-zh-s02.md | 1 | not-started | - | - | - |

If a candidate concept has no wiki page backing it, it does not belong on the roadmap.

### 3. Tutor Loop with Wiki Read Gate

For each concept, before any tutoring activity:

- **Step 3.0 (Wiki Read Gate)** — read every page in the concept's `Wiki Pages` list, in full, with the Read tool. Skim adjacent linked pages on demand. Log the read in `session.md`. Hard-fail if a listed page can't be read.
- **Step 3a–3h** — same as `/sigma`: introduce minimally, alternate question types, track misconceptions, calibrated mastery check, hands-on practice. The wiki pages you just read are the ground truth for every Q/A and counter-example.

The Read Gate is mandatory on every concept transition, even within the same session, even on resume. Quoting from prior memory of the wiki is not a substitute.

### 4. Session Output

```
sigma-with-wiki/
├── learner-profile.md              # Cross-topic learner model (shared with /sigma if it exists there)
└── session/                        # Single fixed directory — there is only ONE session per repo
    ├── session.md                  # Learning state + Wiki Pages column + Wiki Context block
    ├── roadmap.html                # Visual learning roadmap (updated every round)
    ├── concept-map/                # Excalidraw concept maps (mirroring wiki [[WikiLinks]])
    ├── visuals/                    # HTML explanations, diagrams, images
    └── summary.html                # Session summary (at milestones or end)
```

There is no `{topic-slug}/` subdirectory. One repo, one wiki, one session.

## Pedagogy

Same seven-principle foundation as `/sigma`:

| Principle | Research | Implementation |
|-----------|----------|----------------|
| **Bloom's 2-Sigma** | Bloom 1984 | 1-on-1 tutoring + mastery gating at 80% via calibrated rubric |
| **Socratic Method** | Classical | Questions only — never lecture, never hand-wave |
| **Spaced Repetition** | Ebbinghaus 1885, SM-2 | Review mastered concepts at increasing intervals on resume |
| **Interleaving** | Rohrer & Taylor 2007 | Mix old concepts into current question flow |
| **Misconception Dismantling** | Vosniadou 2013, Chi 2005 | Counter-example method to dislodge wrong mental models |
| **Deliberate Practice** | Ericsson 1993 | Hands-on practice phase before marking mastered |
| **Metacognition** | Bjork 1994 | Self-assessment calibration to detect fluency illusion |

Plus one principle this variant adds:

| Principle | Why | Implementation |
|-----------|-----|----------------|
| **Source Grounding** | LLM tutors drift from source material as sessions grow | Wiki Read Gate forces a re-read of the concept's wiki pages on every transition |

## Structure

```
sigma-with-wiki/
├── SKILL.md                    # Core skill definition (with Wiki Survey + Wiki Read Gate)
├── README.md                   # This file
└── references/
    ├── pedagogy.md             # Bloom's 2-Sigma theory, question design, mastery criteria
    ├── html-templates.md       # Roadmap, summary, and visual HTML templates
    └── excalidraw.md           # Excalidraw diagram guide, element format, color palette
```

## Relationship to /sigma

- The two skills coexist. `/sigma` writes to `sigma/`, `/sigma-with-wiki` writes to `sigma-with-wiki/`.
- The cross-topic `learner-profile.md` is shared in spirit — `/sigma-with-wiki` reads `sigma-with-wiki/learner-profile.md` first, falls back to `sigma/learner-profile.md` if only that exists, and writes back to its own directory.
- `/sigma` is the right choice when the topic isn't in this repo's wiki (e.g., personal learning of unrelated subjects). `/sigma-with-wiki` is the right choice for *this* repo's domain — Claude Code internals as captured in `wiki/`.

## License

MIT
