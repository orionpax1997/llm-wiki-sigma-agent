#!/usr/bin/env bash
#
# transcribe.sh — Download + normalize + transcribe (audio) → clean text.
#
# Pipeline (fully piped, no intermediate audio files):
#   yt-dlp (audio stream) → ffmpeg (16 kHz mono PCM) → whisper.cpp
# Produces: tmp_output.txt (title + transcript combined) in a per-invocation
#   /tmp/video-transcribe-XXXXXX/ subdir. The OS cleans up /tmp/ on its
#   own schedule — no manual rm needed by the model.
# Does NOT write the final .md — that's the model's job.
#
# Usage:
#   transcribe.sh URL|local-file [--model base|small|...] [--language zh|en|auto]
#                            [--timestamps]
#
# Examples:
#   transcribe.sh "https://www.youtube.com/watch?v=..."
#   transcribe.sh ~/Downloads/keynote.mp4 --model medium --language en
#   transcribe.sh "https://b23.tv/tnbeKH2"
#
# Env (all optional — sensible defaults auto-detected from PATH and binary layout):
#   WHISPER_CPP_MAIN  path to whisper-cli binary (default: $(command -v whisper-cli))
#   WHISPER_MODELS    directory containing ggml-<model>.bin files
#                     (default: <repo-root>/models/, derived from binary path)
#   Or pass --model /full/path/to/ggml-xxx.bin to bypass WHISPER_MODELS entirely.

set -euo pipefail

# ---------- Defaults ----------
MODEL="base"
LANGUAGE="auto"
TIMESTAMPS=0
SOURCE=""

# ---------- Usage ----------
usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

# ---------- Arg parse (do first, so --help works without env) ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --language)   LANGUAGE="$2"; shift 2 ;;
    --timestamps) TIMESTAMPS=1; shift ;;
    -h|--help)    usage 0 ;;
    -*)           echo "Unknown flag: $1" >&2; usage 1 ;;
    *)            SOURCE="$1"; shift ;;
  esac
done

[[ -z "$SOURCE" ]] && { echo "Error: URL or local file required." >&2; usage 1; }

# Re-entry guard: BILIBILI_PATCH_ATTEMPTED is set when this script re-execs
# itself after auto-applying the 412 patch. Prevents infinite retry if the
# patch is in place but the challenge still fails.
[[ -n "${BILIBILI_PATCH_ATTEMPTED:-}" ]] && PATCH_ATTEMPTED=1 || PATCH_ATTEMPTED=0

# ---------- Required env (auto-detected with override) ----------
WHISPER_CPP_MAIN="${WHISPER_CPP_MAIN:-$(command -v whisper-cli || true)}"
[[ -z "$WHISPER_CPP_MAIN" ]] && { echo "Error: whisper-cli not found. Set WHISPER_CPP_MAIN or add it to PATH." >&2; exit 1; }

# Resolve model path: --model can be a full path to a .bin file (used as-is),
# or a name (resolved by searching WHISPER_MODELS + common install layouts).
if [[ "$MODEL" == *.bin ]]; then
  MODEL_FILE="$MODEL"
else
  BIN_DIR="$(dirname "$(readlink -f "$WHISPER_CPP_MAIN")")"
  CANDIDATES=()
  [[ -n "${WHISPER_MODELS:-}" ]] && CANDIDATES+=("$WHISPER_MODELS")
  # Two dirs above the binary: catches wrappers that nest whisper.cpp under another dir
  CANDIDATES+=("$(dirname "$(dirname "$(dirname "$BIN_DIR")")")/models")
  # One dir above the binary: matches the standard source-build layout
  # (binary at <repo>/build/bin/whisper-cli, models at <repo>/models)
  CANDIDATES+=("$(dirname "$(dirname "$BIN_DIR")")/models")
  # Conventional home-dir default for source builds
  CANDIDATES+=("$HOME/whisper.cpp/models")

  find_model() {
    local name="$1"
    for dir in "${CANDIDATES[@]}"; do
      [[ -f "$dir/ggml-${name}.bin" ]] && { echo "$dir/ggml-${name}.bin"; return 0; }
    done
    return 1
  }

  MODEL_FILE="$(find_model "$MODEL" || true)"
  # Fallback: if the default 'base' model isn't installed, try 'small' before erroring.
  if [[ -z "$MODEL_FILE" && "$MODEL" == "base" ]]; then
    if FALLBACK_FILE="$(find_model small)"; then
      MODEL_FILE="$FALLBACK_FILE"
      echo "[transcribe] 'base' not found, falling back to 'small'" >&2
      MODEL="small"
    fi
  fi
fi

if [[ -z "$MODEL_FILE" || ! -f "$MODEL_FILE" ]]; then
  echo "Error: model file not found for '$MODEL'." >&2
  echo "  Searched: ${CANDIDATES[*]:-none}" >&2
  echo "  Fix: download it (download-ggml-model.sh $MODEL), or pass --model /full/path/to/ggml-xxx.bin," >&2
  echo "       or set WHISPER_MODELS=/dir/with/ggml-${MODEL}.bin." >&2
  exit 1
fi

# Per-invocation temp dir; OS cleans up /tmp/ on its own schedule.
TMP_DIR="$(mktemp -d /tmp/video-transcribe-XXXXXX)"
TMP_OUTPUT="$TMP_DIR/tmp_output.txt"
TMP_TITLE_RAW="$TMP_DIR/tmp_title_raw.txt"

log() { echo "[transcribe] $*" >&2; }

# ---------- Resolve short URLs to canonical form ----------
# Some short/share URLs (e.g. v.douyin.com, iesdouyin.com) bounce through
# several 302s before reaching the canonical video page. yt-dlp's [generic]
# extractor can fail on the intermediate iesdouyin.com share URL with all
# its tracking params. Resolve once with curl, then hand the canonical URL
# to yt-dlp. Returns input unchanged for URLs that don't need resolution
# (or if the resolution attempt fails).
resolve_short_url() {
  case "$1" in
    *v.douyin.com/*|*iesdouyin.com/*)
      local r
      r="$(curl -sIL -o /dev/null -w '%{url_effective}' --max-time 30 "$1" 2>/dev/null \
          | grep -oE 'https://www\.douyin\.com/video/[0-9]+' | head -1)"
      printf '%s\n' "${r:-$1}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

# ---------- Platform-specific yt-dlp args ----------
# Some platforms (Douyin in particular) need extra flags beyond the defaults
# to bypass anti-bot protections. Emits args one-per-line, null-terminated,
# so quoted values with spaces (e.g. --user-agent) round-trip correctly.
# Returns nothing for platforms that work with the bare defaults.
platform_args() {
  case "$1" in
    *v.douyin.com*|*.douyin.com*|*iesdouyin.com*)
      printf '%s\0' \
        "--extractor-args" "douyin:player_client=android" \
        "--no-check-certificates" \
        "--user-agent" "com.ss.android.ugc.aweme/260100 (Linux; U; Android 13; zh_CN; Pixel 7; Build/TQ3A.230805.001; Cronet/TTNetVersion:b315fe9f)"
      ;;
  esac
}

# ---------- Step 1: Title (no audio download) ----------
log "Capturing title..."
RESOLVED_URL="$SOURCE"
if [[ -f "$SOURCE" ]]; then
  basename "$SOURCE" | sed 's/\.[^.]*$//' > "$TMP_TITLE_RAW"
else
  RESOLVED_URL="$(resolve_short_url "$SOURCE")"
  yt-dlp --get-title "$RESOLVED_URL" > "$TMP_TITLE_RAW" 2>/dev/null || echo "untitled" > "$TMP_TITLE_RAW"
fi
TITLE="$(head -1 "$TMP_TITLE_RAW" | tr -d '\n')"
rm -f "$TMP_TITLE_RAW"
log "Title: $TITLE"

# ---------- Step 2: Source → ffmpeg → whisper (single pipe, no temp audio) ----------
TS_FLAG="--no-timestamps"
[[ $TIMESTAMPS -eq 1 ]] && TS_FLAG="--print-progress"

log "Transcribing with whisper ($MODEL, lang=$LANGUAGE)..."

# ffmpeg reads source (file or pipe:0), writes 16kHz mono PCM WAV to stdout (pipe:1).
# whisper-cli reads WAV from stdin (-f -) and writes transcript to file (-otxt -of).
if [[ -f "$SOURCE" ]]; then
  log "Using local file: $SOURCE"
  ffmpeg -hide_banner -loglevel error -i "$SOURCE" \
    -ar 16000 -ac 1 -c:a pcm_s16le -f wav pipe:1 2>/dev/null \
    | "$WHISPER_CPP_MAIN" \
        -m "$MODEL_FILE" \
        -f - \
        -l "$LANGUAGE" \
        $TS_FLAG \
        -otxt -of "$TMP_DIR/tmp_transcript_raw" 2>&1 | tail -5 >&2 || true
else
  log "Streaming audio → ffmpeg → whisper (no intermediates written to disk)"
  YT_DLP_LOG="$TMP_DIR/yt_dlp.log"
  PLATFORM_ARGS=()
  while IFS= read -r -d '' arg; do
    PLATFORM_ARGS+=("$arg")
  done < <(platform_args "$RESOLVED_URL")
  yt-dlp -f "bestaudio/best" "${PLATFORM_ARGS[@]}" -o - "$RESOLVED_URL" 2>"$YT_DLP_LOG" \
    | ffmpeg -hide_banner -loglevel error -i pipe:0 \
        -ar 16000 -ac 1 -c:a pcm_s16le -f wav pipe:1 2>/dev/null \
    | "$WHISPER_CPP_MAIN" \
        -m "$MODEL_FILE" \
        -f - \
        -l "$LANGUAGE" \
        $TS_FLAG \
        -otxt -of "$TMP_DIR/tmp_transcript_raw" 2>&1 | tail -5 >&2 || true
fi

RAW_TEXT="$TMP_DIR/tmp_transcript_raw.txt"
if [[ ! -s "$RAW_TEXT" ]]; then
  echo "Error: whisper produced no transcript for '$SOURCE'." >&2
  if [[ -f "$SOURCE" ]]; then
    echo "  Local file may be invalid, corrupt, or in an unsupported format." >&2
  elif [[ -f "$YT_DLP_LOG" && -s "$YT_DLP_LOG" ]]; then
    if grep -qiE "412|precondition failed" "$YT_DLP_LOG"; then
      if [[ $PATCH_ATTEMPTED -eq 1 ]]; then
        echo "  → Bilibili 412 challenge. Patch already applied this run; giving up." >&2
        echo "    The patched yt-dlp still hit 412 — Bilibili may be blocking your IP" >&2
        echo "    or the challenge solver failed. See references/bilibili-412-patch.md." >&2
      else
        echo "  → Bilibili 412 challenge. Attempting on-demand patch from assets/..." >&2
        CHECK_OUT="$( "$(dirname "$0")/check_bilibili_patch.sh" 2>&1 )" || true
        if [[ -n "$CHECK_OUT" ]]; then
          echo "$CHECK_OUT" | sed 's/^/    /' >&2
        fi
        if echo "$CHECK_OUT" | grep -q "Applied PR #16578 patch"; then
          echo "  → Patch applied. Re-running pipeline..." >&2
          BILIBILI_PATCH_ATTEMPTED=1 exec "$0" "$@"
        fi
        echo "  → Patch not applied. See references/bilibili-412-patch.md." >&2
      fi
    elif grep -qiE "403|forbidden" "$YT_DLP_LOG"; then
      echo "  → HTTP 403. Video may be private or region-locked." >&2
    elif grep -qiE "404|not found|video (has been )?removed|unavailable" "$YT_DLP_LOG"; then
      echo "  → HTTP 404 or video removed. Check the URL." >&2
    elif grep -qiE "sign in|login|登录|需要登录" "$YT_DLP_LOG"; then
      echo "  → Login required for this video." >&2
    fi
    echo "  yt-dlp stderr (last 10 lines):" >&2
    tail -10 "$YT_DLP_LOG" | sed 's/^/    /' >&2
  else
    echo "  yt-dlp produced no output. Check the URL or network." >&2
  fi
  exit 1
fi

# Combine title + raw transcript into a single output file. Format:
#   # <title>
#   <blank>
#   <raw transcript body>
# The model reads this file and parses title from the first line.
{ printf '# %s\n\n' "$TITLE"; cat "$RAW_TEXT"; } > "$TMP_OUTPUT"
rm -f "$RAW_TEXT"

log "Done. Output: $TMP_OUTPUT"
echo "$TMP_OUTPUT"
