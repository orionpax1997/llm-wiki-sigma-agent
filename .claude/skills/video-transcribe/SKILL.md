---
name: video-transcribe
description: >
  Transcribe video or audio content from any platform (YouTube, Bilibili,
  Douyin/抖音, Vimeo, Twitter/X, TikTok, podcasts, local files) into clean
  Markdown. Use this skill whenever the user pastes a video URL and wants the
  spoken content turned into a written article — including requests like
  "transcribe this video", "convert this video to text", "把视频转成文字",
  "把视频转录成 markdown", "下载这个视频并转录", "复制打开抖音…",
  "extract the audio and transcribe it", or any variation involving download +
  speech-to-text. Pipeline: yt-dlp (audio-first with video fallback) → ffmpeg
  (normalize to 16 kHz mono PCM) → whisper.cpp (transcribe) → Markdown. Default
  model is `base`; the user may switch to tiny/small/medium/large. Default
  output is clean prose without timestamps.
---

# Video Transcribe

Turn video or audio into a clean Markdown transcript. Two-stage pipeline:
**run `scripts/transcribe.sh` → model cleans up & writes the .md**.

The script bundles the four deterministic steps (download, title capture,
normalize, transcribe). The model's job is the fifth step: read the raw
whisper output and turn it into a proper article.

## When to use this skill

Use it whenever the user wants the *spoken content* of a video turned into text:
- A video URL plus "transcribe" / "to text" / "to markdown"
- "把视频转成文字" / "下载并转录" / "提取这个视频的文稿"
- A local audio/video file with "转录" / "transcribe"
- Batch jobs like "transcribe all videos in this playlist"
- Wants only the transcript body (not timestamps) by default

## When NOT to use this skill

- User wants **subtitles with timestamps** (SRT/VTT) — see [examples.md §6](references/examples.md#6-subtitle-style-output-with-timestamps) for the SRT variant, but reach for it only if asked.
- User wants the **video itself** downloaded (no transcription) — use plain yt-dlp.
- User wants **summarization or analysis** of the content — that comes *after* transcription; transcribe first, then summarize.
- Live streams still in progress — yt-dlp can't grab a clean audio track.

## Defaults

| Setting | Default | Override |
|---|---|---|
| whisper model | `base` | `--model tiny\|base\|small\|medium\|large` |
| language | auto-detect | `--language zh\|en\|...` |
| output timestamps | none (clean prose) | `--timestamps` for the SRT variant |
| output dir | `/tmp/video-transcribe-XXXXXX/` (per-invocation subdir; OS cleans up) | n/a — the .md path is the model's choice |
| audio format after ffmpeg | 16 kHz mono PCM s16le WAV | n/a (whisper requires this) |

## Workflow

**Just run the script.** Do NOT pre-check the environment with `which`, `--version`, or `find` for binaries or model files — the script auto-detects everything. If anything is truly missing, the script fails with a clear error message; only consult [references/troubleshooting.md](references/troubleshooting.md) when that happens.

Always run step 1, then step 2. Step 1 is deterministic — let the script handle it. Step 2 needs human-style judgment, so the model does it.

### Step 1: Run the pipeline script

`scripts/transcribe.sh` runs a single piped pipeline — `yt-dlp` (audio stream) → `ffmpeg` (16 kHz mono PCM s16le) → `whisper.cpp` (transcribe) — so no intermediate audio files are ever written to disk. It writes a single `tmp_output.txt` (title + transcript combined) into a per-invocation subdir under `/tmp/` (e.g. `/tmp/video-transcribe-abc123/`), and prints its full path on stdout. The OS cleans up `/tmp/` on its own schedule — no manual rm needed.

**Zero env vars required.** The script auto-detects:
- `whisper-cli` binary via `command -v` (override with `WHISPER_CPP_MAIN=/path/to/whisper-cli`)
- model file by searching in order: `WHISPER_MODELS` if set → `<bin>/../../models` → `<bin>/../models` → `~/whisper.cpp/models`

Override the model by passing `--model /full/path/to/ggml-xxx.bin` directly, or set `WHISPER_MODELS=/dir/with/models`.

```bash
./scripts/transcribe.sh "URL|local-file" \
  [--model base|small|... | /full/path/to/ggml-xxx.bin] \
  [--language zh|en|auto] \
  [--timestamps]
```

**Examples**:
```bash
# YouTube, defaults (auto-detects model + language)
./scripts/transcribe.sh "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Bilibili, Chinese, defaults
./scripts/transcribe.sh "https://www.bilibili.com/video/BVxxxxxxxxxx" --language zh

# Override to a specific model or path
./scripts/transcribe.sh "URL" --model medium
./scripts/transcribe.sh "URL" --model /path/to/ggml-large.bin

# Local file with timestamps for subtitle-style output
./scripts/transcribe.sh ~/Downloads/keynote.mp4 --timestamps
```

The script's default model is `base`. If `base` isn't installed but `small` is, it falls back to `small` automatically — no need to specify a model unless you want something specific.

The script prints the combined-file path on stdout and logs progress (download %, ffmpeg line, whisper progress) to stderr. On success, the user's shell sees only the final tmp_output.txt path.

The script is intentionally minimal — no opencc, no transcript cleanup, no .md writing. Those belong to the model in step 2.

### Step 2: Clean & Format (→ Markdown)

Read the single `tmp_output.txt` path the script printed (in the `/tmp/video-transcribe-XXXXXX/` subdir from step 1). The file format is:

```
# <title>

<raw transcript body, one whisper segment per line>
```

The first line is the title (use it for the H1 and filename slug); everything after the blank line is the raw transcript body to clean up. Then write the final `.md` file to wherever the user asked for it (e.g. `raw/`). **Do not paste the raw whisper output verbatim** — it is one run-on line per segment and contains transcription noise. The model must clean it up.

```bash
MD_DIR="./raw"  # or wherever the user asked for the .md
mkdir -p "$MD_DIR"

# tmp_output.txt lives in the /tmp/video-transcribe-XXXXXX/ subdir the script
# printed; the model reads it via the Read tool. Pull title (first line) and
# build a filename-safe slug from it.
TITLE=$(head -1 "$TMP_OUTPUT" | sed 's/^# //')
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9一-龥]/-/g; s/-\+/-/g; s/^-//; s/-$//')
OUT_FILE="$MD_DIR/${SLUG}.md"
```

**Cleanup rules** (apply before writing the .md):

- **Traditional → Simplified Chinese.** Whisper often returns Traditional characters for Mandarin audio. Apply inline as you write — do NOT add an opencc dependency. Common substitutions to do without thinking: 顯示→显示, 參數→参数, 變/變→变, 個→个, 來→来, 會/會→会, 對→对, 時→时, 機→机, 構→构, 傳→传, 節→节, 萬/萬→万, 億→亿, 點→点, 選→选, 線→线, 複→复, 鍵→键, 腦→脑, 進→进, 過→过, 結→结, 帶→带, 觀→观, 無→无, 說→说, 實→实, 讓→让, 種→种, 現→现, 為→为, 與→与, 這→这, 們→们, 邊→边, 長→长, 當→当, 將→将, 應→应, 學→学, 寫→写, 從→从, 還→还, 連→连, 聲→声, 數→数, 斷→断. If you hit an unfamiliar Traditional char, fall back to its pinyin-shape Simplified counterpart (e.g., 機制/機制→机制, 複雜/複雜→复杂, 湧現/湧現→涌现).
- **Skip obvious noise at the start.** Whisper often hallucinates 5–10 characters before the speaker begins. Drop those.
- **Fix high-confidence transcription errors only.** If the context makes a word clearly wrong (e.g., "管中虧報" → "管中窥豹", "RLM" → "LLM", "拳劇" → "全局"), correct it. Do not invent content the speaker did not say.
- **Add paragraph breaks.** Whisper returns one line per segment (usually one sentence). Merge into natural paragraphs at topic shifts.
- **Add blank lines between paragraphs and section breaks.** Use `## H2` headings for major topic shifts when the speaker clearly transitions (e.g., "this lesson we'll talk about X", "next let's discuss Y").

**Output template** (always use this structure):

```markdown
# <video title>

**Source**: <URL>
**Date transcribed**: <YYYY-MM-DD>
**Model**: whisper <model-name>

---

<transcript body — cleaned, with paragraph breaks, ## section headings where the speaker transitions topics, no timestamps, no speaker labels unless detected>
```

The model writes the .md via the Write tool. Don't use a heredoc inside Bash for the body — the cleanup needs human-style judgment.

## Examples

### Example 1: YouTube lecture

**User says:** "Transcribe this to markdown: https://www.youtube.com/watch?v=dQw4w9WgXcQ"

**You do:** run `./scripts/transcribe.sh "URL"` with defaults, read the `tmp_output.txt` path the script printed (under `/tmp/video-transcribe-XXXXXX/`), write `./never-gonna-give-you-up.md` in the current directory, then tell the user the file is ready.

### Example 2: Bilibili tech talk in Chinese

**User says:** "把 B 站这个视频转成文字 https://www.bilibili.com/video/BVxxxxxxxxxx, 用 small 模型"

**You do:** same pipeline with `--model small --language zh`. The skill should detect Chinese from URL or context, but explicit is fine.

### Example 3: Local mp4 file

**User says:** "transcribe ~/Downloads/keynote.mp4"

**You do:** the script accepts a local path — pass it instead of a URL. Skip the download (handled internally).

See [references/examples.md](references/examples.md) for more variants:
- Douyin (抖音) short links with copy noise
- Twitter/X, Vimeo, podcast RSS feeds
- Subtitle-style output (with timestamps) — opt-in only
- [Bilibili 412 challenge solver](references/bilibili-412-patch.md) — patch PR #16578 into your local yt-dlp

## What this skill adds beyond raw whisper.cpp

Without this skill you could run `whisper-cli -f audio.wav -otxt` and get a file. The output is unusable for a written article:

- **One run-on line per segment** — no paragraph breaks, no headings.
- **Traditional Chinese characters** for Mandarin audio (顯示/參數/變 — must be normalized to 显示/参数/变 inline, since adding an `opencc` dependency is overkill for a one-shot tool).
- **Hallucinated noise** at the start of every clip (5–10 random characters before the speaker begins).
- **Noisy word-level errors** that need context-aware fixing (管中虧報→管中窥豹, RLM→LLM, 拳劇→全局).
- **No metadata header** (no source URL, no date, no model info).

This skill handles all of that: a 4-minute Douyin clip goes from raw whisper output (~3 KB of garbage) to a clean ~3.5 KB article with `##` section breaks, proper Simplified characters, and a structured header. The win is the cleanup, not the transcription.

## Notes for the model

- **Always pass audio through ffmpeg**, even if the source is already WAV. Different sample rates silently break whisper. The script handles this automatically — don't try to skip the normalize step.
- **If whisper fails or returns empty**, check: (1) audio length > 0, (2) sample rate 16 kHz, (3) model file isn't truncated (re-download). Don't retry blindly with a different model unless the user asks.
- **Long videos**: whisper.cpp on `base` can take 0.3–0.5× realtime. Warn the user before kicking off a 3-hour video.
- **CPU contention on parallel transcribes**: whisper.cpp uses all available cores. Running N transcripts in parallel does **not** get you N× speedup — in practice 4 parallel jobs on an 8-core box took ~5.8× as long per file (CPU oversubscription + memory bandwidth). For a batch, serialize them or set `-t <N>` to cap threads per job (e.g. `-t 2` for 4 parallel jobs). The script doesn't yet expose a `--threads` flag — pass it through `WHISPER_THREADS` env var if you patch it in, or post-process with `taskset`.
- **Privacy**: transcripts live in `./transcripts/` by default — remind the user to gitignore or move sensitive ones.
- **Bilibili 412 challenge**: yt-dlp often fails on Bilibili with HTTP 412. Apply the patch in [references/bilibili-412-patch.md](references/bilibili-412-patch.md) (PR #16578). Without the patch, the script will fail at the download step.
- **Subagent eval runs**: write the prompt as an **explicit step-by-step script** (one line per command). Vague prompts make the subagent improvise and hit permission boundaries. A single `./scripts/transcribe.sh "URL"` call usually beats an inline 4-step manual pipeline, because it reduces permission denials (one Bash call vs four) and keeps the prompt declarative.
