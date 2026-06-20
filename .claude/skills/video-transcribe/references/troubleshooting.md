# Troubleshooting

**Only consult this file when `transcribe.sh` reports an error.** Do not pre-check anything in here before running the script.

The script fails fast with explicit messages. Match the error to a section below.

---

## "WHISPER_CPP_MAIN must point to the whisper-cli binary"

The `WHISPER_CPP_MAIN` env var is unset or wrong. The default location depends on how whisper.cpp was installed:

| Install method | Typical path |
|---|---|
| `brew install whisper-cpp` | `/opt/homebrew/bin/whisper-cli` (Apple Silicon) or `/usr/local/bin/whisper-cli` |
| Built from source | `$HOME/whisper.cpp/build/bin/whisper-cli` |
| `uv tool install whisper-cpp` | `$(uv tool dir)/whisper-cpp/bin/whisper-cli` |
| Manual install | wherever the user put it |

Older whisper.cpp builds name the binary `main` instead of `whisper-cli` — that name is deprecated; rebuild from a recent commit.

Set both env vars and retry:

```bash
export WHISPER_CPP_MAIN="<path above>"
export WHISPER_MODELS="<dir with ggml-*.bin>"  # usually next to the binary
```

## "WHISPER_MODELS must point to the directory with ggml-*.bin files"

`WHISPER_MODELS` is unset or the directory doesn't contain model files. Point it at the directory that holds `ggml-base.bin` (or whichever size you're using).

## "model file not found: <path>"

`ggml-<model>.bin` is missing at the resolved path. The script tries in this order: `ggml-base.bin` → `ggml-small.bin` → fail.

To download the default:

```bash
# inside a whisper.cpp source checkout
./models/download-ggml-model.sh base   # ~140 MB
```

Or fetch directly from https://huggingface.co/ggerganov/whisper.cpp. Once downloaded, the file lives in `WHISPER_MODELS/` (or wherever you point it).

If you need a different size, pass `--model tiny|small|medium|large`.

## "yt-dlp: command not found" / "ffmpeg: command not found"

These are bare-binary failures — the script can't even start. Install the missing one:

| Tool | Install |
|---|---|
| `yt-dlp` | `uv tool install yt-dlp` or `brew install yt-dlp` |
| `ffmpeg` | `brew install ffmpeg` / `apt install ffmpeg` |

The script does not check these upfront — only the OS shell does. If you see this error, install and retry.

## "HTTP 412" or "Sign verification failed" on Bilibili

yt-dlp's Bilibili extractor hits a server-side anti-bot challenge. Apply the patch in [bilibili-412-patch.md](bilibili-412-patch.md) (PR #16578) to your local yt-dlp install and retry.

## whisper returns empty / suspiciously short transcript

Don't retry blindly with a different model. Check in order:

1. **Audio length** — was it > 0? `yt-dlp` may have downloaded a stub.
2. **Sample rate** — the script normalizes to 16 kHz via ffmpeg, so this should always be correct, but if you bypassed the script, double-check.
3. **Model file integrity** — re-download `ggml-base.bin`; truncated files silently produce garbage.

If all three look fine, try `--model small` for better accuracy on noisy audio.

## "set -euo pipefail" aborted mid-pipeline

Read the last few lines of stderr — the error is one of the categories above. Common causes in practice:

- Network drop during `yt-dlp` (re-run; it'll resume)
- Disk full in `/tmp/` (clean up old `video-transcribe-XXXXXX/` dirs)
- whisper.cpp OOM on very long audio (try `--model tiny` or split the file)

---

## When in doubt

Re-run the script with the same flags. `transcribe.sh` is idempotent — it creates a fresh `/tmp/video-transcribe-XXXXXX/` per invocation.
