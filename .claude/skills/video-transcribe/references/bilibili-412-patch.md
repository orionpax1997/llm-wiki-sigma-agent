# Bilibili HTTP 412 — PR #16578 Challenge Solver Patch

If you hit `HTTP Error 412: Precondition Failed` on a Bilibili video (common on non-Chinese data center IPs), apply PR [#16578](https://github.com/yt-dlp/yt-dlp/pull/16578)'s challenge solver to your local yt-dlp. The PR adds SHA-256 proof-of-work solving for Bilibili's anti-bot captcha. Without the patch, the only fix is cookies + Chinese-region IP egress.

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
