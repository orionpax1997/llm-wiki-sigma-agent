#!/usr/bin/env bash
#
# check_bilibili_patch.sh — Auto-apply PR #16578 to yt-dlp's bilibili.py.
#
# Why this exists:
#   Bilibili 412 challenge solver from PR #16578 lives in
#   assets/bilibili.py. Re-apply it whenever uv reinstalls yt-dlp, but
#   only when:
#     (a) the installed yt-dlp version matches the version we have a
#         patch for (assets/yt-dlp-version), AND
#     (b) the installed bilibili.py is byte-identical to either the
#         original (apply) or the patched (skip) — anything else means
#         the user has a different version or hand-edits, so we don't
#         clobber.
#
# Always exits 0 — never blocks the main transcribe pipeline. Errors
# are warnings, not failures.
#
# Called from transcribe.sh before the yt-dlp download step. Idempotent.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS="$SKILL_DIR/assets"
PATCHED="$ASSETS/bilibili.py"
ORIGINAL="$ASSETS/bilibili.py.original"
VERSION_FILE="$ASSETS/yt-dlp-version"

log() { echo "[bilibili-patch] $*" >&2; }

# --- Bail early if assets/ is missing or incomplete ----------------------
if [[ ! -f "$PATCHED" || ! -f "$ORIGINAL" || ! -f "$VERSION_FILE" ]]; then
  log "assets/ incomplete — skipping auto-patch"
  exit 0
fi

# --- Resolve installed version -------------------------------------------
if ! command -v yt-dlp >/dev/null 2>&1; then
  log "yt-dlp not in PATH — skipping"
  exit 0
fi
TARGET_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
INSTALLED_VERSION="$(yt-dlp --version 2>/dev/null | tr -d '[:space:]' || true)"
if [[ -z "$INSTALLED_VERSION" ]]; then
  log "yt-dlp --version failed — skipping"
  exit 0
fi

# --- Version gate --------------------------------------------------------
# The patched file is a full-file replacement of the original. yt-dlp
# minor releases often change bilibili.py — version drift would silently
# break unrelated things. Bail out so the user can refresh assets/ from
# a newer PR.
if [[ "$INSTALLED_VERSION" != "$TARGET_VERSION" ]]; then
  log "yt-dlp $INSTALLED_VERSION != target $TARGET_VERSION — skipping auto-patch"
  log "  Patch assets/ are pinned to $TARGET_VERSION. See references/bilibili-412-patch.md"
  exit 0
fi

# --- Locate the installed bilibili.py via the bundled Python ------------
# The shebang on the yt-dlp wrapper points to its own venv Python; ask
# that Python where yt_dlp.extractor.bilibili lives. This works for both
# the uv tool install and any venv with yt-dlp in it.
YT_SHEBANG_PY="$(head -1 "$(command -v yt-dlp)" 2>/dev/null | sed 's/^#!//' || true)"
if [[ -z "$YT_SHEBANG_PY" || ! -x "$YT_SHEBANG_PY" ]]; then
  log "Couldn't locate yt-dlp's Python interpreter — skipping"
  exit 0
fi
BILIBILI_PATH="$("$YT_SHEBANG_PY" -c \
  'import yt_dlp.extractor.bilibili, os; print(os.path.realpath(yt_dlp.extractor.bilibili.__file__))' \
  2>/dev/null || true)"
if [[ -z "$BILIBILI_PATH" || ! -f "$BILIBILI_PATH" ]]; then
  log "Couldn't resolve installed bilibili.py — skipping"
  exit 0
fi

# --- Hash compare --------------------------------------------------------
INSTALLED_HASH="$(sha256sum "$BILIBILI_PATH" | cut -d' ' -f1)"
PATCHED_HASH="$(sha256sum "$PATCHED" | cut -d' ' -f1)"
ORIGINAL_HASH="$(sha256sum "$ORIGINAL" | cut -d' ' -f1)"

if [[ "$INSTALLED_HASH" == "$PATCHED_HASH" ]]; then
  log "Already patched — $BILIBILI_PATH"
  exit 0
fi

if [[ "$INSTALLED_HASH" != "$ORIGINAL_HASH" ]]; then
  log "Installed file differs from both original and patched — skipping to avoid clobber"
  log "  installed: $INSTALLED_HASH"
  log "  original:  $ORIGINAL_HASH"
  log "  patched:   $PATCHED_HASH"
  log "  Path: $BILIBILI_PATH"
  exit 0
fi

# --- Apply ---------------------------------------------------------------
if ! cp "$PATCHED" "$BILIBILI_PATH" 2>/dev/null; then
  log "cp failed (permission denied?) — $BILIBILI_PATH"
  log "  Try: sudo cp $PATCHED $BILIBILI_PATH"
  exit 0
fi
log "Applied PR #16578 patch to $BILIBILI_PATH"
exit 0
