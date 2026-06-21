# Bilibili HTTP 412 — PR #16578 Challenge Solver Patch

If you hit `HTTP Error 412: Precondition Failed` on a Bilibili video (common on non-Chinese data center IPs), apply PR [#16578](https://github.com/yt-dlp/yt-dlp/pull/16578)'s challenge solver to your local yt-dlp. The PR adds SHA-256 proof-of-work solving for Bilibili's anti-bot captcha. Without the patch, the only fix is cookies + Chinese-region IP egress.

## Auto-applied on demand (after a 412 error)

`scripts/transcribe.sh` only invokes `scripts/check_bilibili_patch.sh` when
yt-dlp actually fails with a 412. The flow:

1. yt-dlp download fails with 412.
2. Script runs `check_bilibili_patch.sh`. The check:
   1. Reads target version from `assets/yt-dlp-version` (currently `2026.06.09`).
   2. Compares to `yt-dlp --version` — skip if mismatch.
   3. Hashes the installed `bilibili.py` (resolved via the yt-dlp shebang Python).
   4. If hash matches `assets/bilibili.py.original` → copies `assets/bilibili.py` over.
   5. If hash matches `assets/bilibili.py` → no-op.
   6. If hash matches neither → warn (avoids clobbering manual edits / different versions).
   7. Permission denied → warn (system Python install needs `sudo`; or `apt remove yt-dlp` to drop the system copy).
3. If the check applied the patch, the script re-execs itself with the same
   args (guarded by `BILIBILI_PATCH_ATTEMPTED=1` env var, so it gives up
   instead of looping if the patched yt-dlp still hits 412).
4. If the check no-op'd or warned, the script exits with the original error.

No overhead on non-Bilibili calls — the check only runs when needed. To
pre-emptively apply (e.g., before transcribing a B-station URL you know
will hit 412), run the check directly:

```bash
./scripts/check_bilibili_patch.sh
```

If the check warns (version drift or hash mismatch), fall back to manual:

```bash
SITE=$(head -1 "$(command -v yt-dlp)" | sed 's/^#!//')
SITE="$("$SITE" -c 'import yt_dlp.extractor.bilibili, os; print(os.path.dirname(yt_dlp.extractor.bilibili.__file__))')"
SKILL=~/.claude/skills/video-transcribe
cp "$SKILL/assets/bilibili.py" "$SITE/bilibili.py"
```

If the version has drifted upstream, refresh `assets/`:

```bash
curl -sSL -o assets/bilibili.py \
  "https://raw.githubusercontent.com/yt-dlp/yt-dlp/refs/pull/16578/head/yt_dlp/extractor/bilibili.py"
# Update assets/yt-dlp-version, then re-run transcribe.sh.
```

The rest of this file is reference material for the patch contents — read it
only if you want to understand or review the change.

## Symptom

```
ERROR: [BiliBili] 1m2n3o4p5q: HTTP Error 412: Precondition Failed
```

The video metadata is reachable but `playurl`/`playview` endpoints reject the request without a valid `X-BILI-SEC-TOKEN` cookie, which itself requires solving a SHA-256 proof-of-work challenge.

## Apply the patch (one-time, against your installed yt-dlp)

```bash
# Find your yt-dlp install path
python3 -c "import yt_dlp, os; print(os.path.dirname(yt_dlp.__file__))"
# Example: /usr/lib/python3/dist-packages/yt_dlp
# or:    ~/.local/share/uv/tools/yt-dlp/lib/python3.13/site-packages/yt_dlp

# Back up the original
cp $YTDLP/yt_dlp/extractor/bilibili.py /tmp/bilibili.py.original
```

Apply four edits to `bilibili.py`:

1. Add `jwt_decode_hs256` to the `from ..utils import (...)` block (after `join_nonempty`).
2. Add three class attributes after `_wbi_key_cache = {}`:
   ```python
   _CHALLENGE_COOKIE = 'X-BILI-SEC-TOKEN'
   _CACHE_NAME = 'bilibili_data'
   _CACHE_KEY  = 'bili_sec_token'
   ```
3. After `_sign_wbi` (line ~171), insert these four methods (see PR #16578):
   - `bili_challenge_result` — SHA-256 brute-force POW solver (up to 5M iterations)
   - `_is_jwt_expired` — check JWT expiry
   - `_get_and_set_bili_sec_token` — read/write the `X-BILI-SEC-TOKEN` cookie + cache
   - `_download_webpage_handle` override that catches HTTPError 412:
     - extracts `X-BILI-SEC-TOKEN` from the 412 response's `Set-Cookie` header
       (PR was written assuming the cookie was already in jar — but on the
       first 412 it comes only on the response, so this step is essential)
     - if cached token exists, retries with it
     - else decodes the JWT challenge data (`q`, `r`, `type=1`), brute-forces the
       POW result, POSTs to `https://security.bilibili.com/th/captcha/cc/check`,
       stores the new token, and retries the original request
4. In `_real_extract` (around line 837 / 855), add `'avid': aid` to the two
   `_download_playinfo(...)` query dicts (per PR + issue #14830 comment 17).

## Reference patch

<https://github.com/yt-dlp/yt-dlp/pull/16578.patch>. The full diff is
8 commits / ~110 lines against `yt_dlp/extractor/bilibili.py`.

## Result after patching

412 errors get caught and auto-solved. Download succeeds on the retry. Without login, resolution is capped (~480p / format 30280) — fine for audio-only transcription. With `--cookies`, max resolution goes up to 1080p.

## Verify the patch is active

```bash
yt-dlp --version                           # should be the installed version
yt-dlp -F "https://www.bilibili.com/video/BV1xxxxxxxxxx"  # should NOT 412
grep -n "bili_challenge_result" $YTDLP/yt_dlp/extractor/bilibili.py
```

If the grep returns nothing, the patch didn't take — re-apply or check for conflicts with a newer yt-dlp version that may have merged the PR (in which case you don't need the patch at all).

## Roll back

```bash
cp /tmp/bilibili.py.original $YTDLP/yt_dlp/extractor/bilibili.py
```
