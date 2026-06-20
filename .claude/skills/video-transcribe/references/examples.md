# Video Transcribe — Examples

Real-world usage patterns. Pick the one closest to the user's request.

> **Output convention.** Each pipeline below produces intermediate `tmp_title.txt` + `tmp_transcript.txt` files, then combines them into a single `tmp_output.txt` (format: `# <title>` + blank line + raw transcript body). The bundled `scripts/transcribe.sh` does this combination internally — the model only ever reads `tmp_output.txt`. If running the steps by hand, add the combination step below between the transcribe and format steps:
>
> ```bash
> { printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt
> ```

## 1. YouTube video (default)

```text
User: "把这段视频转成文字: https://www.youtube.com/watch?v=abc123"
```

Pipeline (defaults — model `base`, auto-detect language, no timestamps):

```bash
# 1. download
yt-dlp -x --audio-format wav --audio-quality 0 \
  -o "tmp_video.%(ext)s" "https://www.youtube.com/watch?v=abc123"
yt-dlp --get-title "https://www.youtube.com/watch?v=abc123" > tmp_title.txt

# 2. normalize
ffmpeg -y -i tmp_video.wav -ar 16000 -ac 1 -c:a pcm_s16le tmp_audio.wav

# 3. transcribe
"$WHISPER_CPP_MAIN" \
  -m "$WHISPER_MODELS/ggml-base.bin" \
  -f tmp_audio.wav -l auto --no-timestamps \
  -otxt -of tmp_transcript

# 4. combine → tmp_output.txt
TITLE=$(cat tmp_title.txt)
{ printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt

# 5. format → ./transcripts/<title-slug>.md  (read tmp_output.txt)
```

## 2. Bilibili tech talk (force Chinese + small model)

```text
User: "用 small 模型转录这个 B 站视频 https://www.bilibili.com/video/BV1xx411c7mD,要中文"
```

```bash
# 1. download (Bilibili audio extraction sometimes fails — fall back to best)
yt-dlp -x --audio-format wav --audio-quality 0 \
  -o "tmp_video.%(ext)s" "https://www.bilibili.com/video/BV1xx411c7mD" \
  || yt-dlp -f "bestaudio/best" \
       -o "tmp_video.%(ext)s" "https://www.bilibili.com/video/BV1xx411c7mD"
yt-dlp --get-title "https://www.bilibili.com/video/BV1xx411c7mD" > tmp_title.txt

# 2. normalize
ffmpeg -y -i tmp_video.m4a -ar 16000 -ac 1 -c:a pcm_s16le tmp_audio.wav

# 3. transcribe with small model + forced Chinese
"$WHISPER_CPP_MAIN" \
  -m "$WHISPER_MODELS/ggml-small.bin" \
  -f tmp_audio.wav -l zh --no-timestamps \
  -otxt -of tmp_transcript

# 4. combine → tmp_output.txt  (see header note)
TITLE=$(cat tmp_title.txt)
{ printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt
```

## 3. Local file (skip download)

```text
User: "把 ~/Downloads/keynote.mp4 转成 markdown"
```

```bash
SRC="$HOME/Downloads/keynote.mp4"
TITLE=$(basename "$SRC" .mp4)
echo "$TITLE" > tmp_title.txt

# 1. download — skipped
# 2. normalize
ffmpeg -y -i "$SRC" -ar 16000 -ac 1 -c:a pcm_s16le tmp_audio.wav

# 3. transcribe (no -l → auto)
"$WHISPER_CPP_MAIN" \
  -m "$WHISPER_MODELS/ggml-base.bin" \
  -f tmp_audio.wav --no-timestamps \
  -otxt -of tmp_transcript

# 4. combine → tmp_output.txt  (see header note)
{ printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt
```

## 4. Douyin (抖音) — short share link with copy noise

```text
User: "复制打开抖音,看看【晴天AI实战的作品】AI Agent 的大脑,大模型入门指南
# ai... https://v.douyin.com/Yq2rPQ2MDg0/ :4pm RKJ:/ 09/18 Z@z.GI"
```

**URL extraction first.** The share text contains a short URL (`https://v.douyin.com/...`) plus trailing emoji/copy noise. Strip everything outside `https?://` and use only the URL.

```bash
# Extract URL from share text — Douyin links need the redirect resolved
URL="https://v.douyin.com/Yq2rPQ2MDg0/"

# Step 1: download
yt-dlp -x --audio-format wav --audio-quality 0 \
  -o "tmp_video.%(ext)s" "$URL" 2>&1 | tail -20

# Common Douyin issue: "Sign challenge" or region block. Fallbacks:
#  (a) update yt-dlp
yt-dlp -U
#  (b) use a recent build (Douyin breaks older extractors frequently)
#  (c) login cookies — only if user explicitly provides them
yt-dlp --cookies-from-browser chrome \
  -x --audio-format wav --audio-quality 0 \
  -o "tmp_video.%(ext)s" "$URL"

yt-dlp --get-title "$URL" > tmp_title.txt
```

Then steps 2–5 as usual (transcribe → combine → format). Force `-l zh` if whisper auto-detect gets it wrong on short clips.

## 5. Twitter / X video

```text
User: "transcribe this: https://x.com/user/status/1234567890"
```

Twitter videos need a referer header; yt-dlp handles this automatically in recent versions. If it fails, install a current yt-dlp:

```bash
yt-dlp -U  # update first
yt-dlp -x --audio-format wav -o "tmp_video.%(ext)s" "<X-URL>"
```

If still failing, the user may need to log in:
```bash
yt-dlp --cookies-from-browser chrome -x --audio-format wav -o "tmp_video.%(ext)s" "<X-URL>"
```

## 6. Subtitle-style output (with timestamps) — opt-in

> **Not the default.** Only do this if the user explicitly asks for "subtitles", "SRT", "with timestamps", "时间戳", "字幕".

Replace step 3:

```bash
"$WHISPER_CPP_MAIN" \
  -m "$WHISPER_MODELS/ggml-base.bin" \
  -f tmp_audio.wav -l auto \
  -osrt -of tmp_transcript
# → tmp_transcript.srt with [hh:mm:ss,mmm --> hh:mm:ss,mmm] blocks
```

> SRT mode **skips the combine step** — `tmp_transcript.srt` is the standalone deliverable. Keep it as-is or convert to a timestamped markdown table. The default `clean prose` flow is the right call for "transcribe to article"-type requests.

## 7. Switch model

Just change `-m`:

| Flag | Use when |
|---|---|
| `ggml-tiny.bin` | preview / draft only, low accuracy, ~1 GB RAM, very fast |
| `ggml-base.bin` | **default** — best speed/accuracy tradeoff for short clips |
| `ggml-small.bin` | better accuracy, ~2 GB RAM, ~1× realtime on M-series |
| `ggml-medium.bin` | professional quality, ~5 GB RAM, ~3× realtime |
| `ggml-large-v3.bin` | state-of-the-art, ~10 GB RAM, ~6× realtime |

Download any model once:
```bash
"$WHISPER_CPP_DIR/models/download-ggml-model.sh" small
```

## 8. Batch / playlist

```text
User: "把整个播放列表都转录: https://www.youtube.com/playlist?list=PLxxxx"
```

```bash
yt-dlp --get-url -i --flat-playlist \
  "https://www.youtube.com/playlist?list=PLxxxx" > urls.txt

while IFS= read -r URL; do
  [ -z "$URL" ] && continue
  echo "=== $URL ==="
  # full pipeline (download → normalize → transcribe → combine → format), per URL
done < urls.txt
```

Each video gets its own `.md` in `./transcripts/`. Warn the user about the total time before kicking this off — a 20-video playlist on `base` can take a full day.

## 9. Long video (>1 hour) — split chunks

Whisper.cpp on a 3-hour video at `base` can OOM on small machines. Split the wav first:

```bash
# split into 30-min chunks
ffmpeg -i tmp_audio.wav -f segment -segment_time 1800 -c copy chunk_%03d.wav

for f in chunk_*.wav; do
  "$WHISPER_CPP_MAIN" -m "$WHISPER_MODELS/ggml-base.bin" \
    -f "$f" --no-timestamps -otxt -of "${f%.wav}"
done

cat chunk_*.txt > tmp_transcript.txt

# 4. combine → tmp_output.txt  (see header note)
TITLE=$(cat tmp_title.txt)
{ printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt
```

## 10. No `whisper.cpp` installed — use faster-whisper

If the user has `faster-whisper` (Python) instead, the equivalent step 3 is:

```bash
uv run --with faster-whisper python -c "
from faster_whisper import WhisperModel
m = WhisperModel('base', compute_type='int8')
segments, _ = m.transcribe('tmp_audio.wav', language=None)
with open('tmp_transcript.txt', 'w') as f:
    for s in segments:
        f.write(s.text)
"

# 4. combine → tmp_output.txt  (see header note)
TITLE=$(cat tmp_title.txt)
{ printf '# %s\n\n' "$TITLE"; cat tmp_transcript.txt; } > tmp_output.txt
```

`faster-whisper` runs on CPU 4–8× faster than whisper.cpp `base` and is a good drop-in. The rest of the pipeline (download → ffmpeg → format) is unchanged.

## 11. Common errors

| Symptom | Cause | Fix |
|---|---|---|
| `ERROR: no suitable extractor` | yt-dlp too old, or private/region-locked video | `yt-dlp -U`, then retry; if still failing, ask user for cookies |
| whisper returns empty | audio is silent or sample rate wrong | re-run step 2, check `ffprobe` reports 16 kHz mono |
| `model file not found` | env var not set | `export WHISPER_MODELS=$HOME/whisper.cpp/models` |
| `libomp` / `dylib` error on macOS | `brew install libomp` | reinstall whisper.cpp after |
| Chinese characters mangled in markdown | encoding — ffmpeg wrote GBK | add `-c:a pcm_s16le` (already in recipe) and ensure locale is UTF-8 |
