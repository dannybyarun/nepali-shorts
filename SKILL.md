---
name: Nepali Shorts (Swar Studio)
description: Build vertical 9:16 Nepali short videos from a topic or a script, locally and without an API key. Use when asked to make a Nepali short, reel, TikTok, or YouTube Short; to turn a topic into a narrated video with burned-in Devanagari captions; to regenerate voiceover, switch the voice, change caption font or colours; to add generated or local b-roll behind captions; or to batch-produce several shorts. Covers Swar TTS, exact captions, Perchance images, ffmpeg rendering, quality gates, and consent/copyright rules.
---

# Nepali Shorts — Swar Studio

A deterministic local pipeline: **topic or script → Swar voiceover → measured caption timings → optional b-roll → ffmpeg 1080×1920 MP4**.

No watermark, no API key, no cloud. The only network step is optional Perchance imagery/text and it degrades safely.

## Locate the project

This skill drives the **swar-studio** project. The paths below are the defaults on the machine it was built for; if your checkout differs, edit this table once — everything else in the skill is relative to the project directory.

| Thing | Default |
| --- | --- |
| Project | `C:\Users\Arun\Downloads\workspace\swar-studio` |
| Python | `C:\Users\Arun\Downloads\workspace\swar-lab\.venv\Scripts\python.exe` |
| Swar models | `C:\Users\Arun\Downloads\workspace\swar-lab\models` |

Run every command **from the project directory**. If the venv moved, set `SWAR_LAB` to the `swar-lab` checkout and use any Python that has `soundfile`, `numpy`, and Swar's own deps.

## Environment (do this first)

PowerShell, before any run:

```powershell
cd "C:\Users\Arun\Downloads\workspace\swar-studio"
Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY -ErrorAction SilentlyContinue   # a dead proxy breaks Perchance
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"
$env:WANDB_MODE = "disabled"
```

`ffmpeg` and `ffprobe` must be on PATH. `fontTools` is used to read a font's family name (already installed); without it, `--font-file` falls back to the filename, which usually breaks matching — prefer having it.

If a run needs Perchance (text or images), the `browse` relay session must exist and be connected:

```powershell
browse session new perchance-research --allow-origin "perchance.org,*.perchance.org,image-generation.perchance.org"
browse session list
```

## Recipes

### 1. Topic → finished short (most common)

```powershell
python make_short.py --topic "काठमाडौंको सानो चिया पसल" --lines 5 `
  --voice maya --takes 2 --template templates\dark.json `
  --hook "चिया पसलको कथा" `
  --images perchance --max-images 5 `
  --out out\chiya.mp4
```

Produces voice, timings, captions, images and the MP4 in one command. The generated script is saved to `out\chiya.script.txt` — **read it** before trusting the video, and reuse it with `--script` to reproduce the same short.

### 2. Script → short

```powershell
python make_short.py --script scripts\02-chiya.txt `
  --voice maya --takes 2 --template templates\dark.json `
  --hook "चिया पसलको कथा" `
  --images perchance --max-images 4 `
  --out out\02-chiya.mp4
```

Script format: one sentence per line, UTF-8, Devanagari or mixed. Blank lines separate paragraphs and add a longer pause.

### 3. Re-render without paying for TTS again

Always reuse the WAV + timing when changing only visuals:

```powershell
python make_short.py --script scripts\02-chiya.txt `
  --wav out\02-chiya.wav --timing out\02-chiya.timing.json `
  --template templates\paper.json --font-file assets\fonts\NotoSansDevanagari.ttf `
  --images local --images-dir out\02-chiya.images --max-images 4 `
  --hook "नयाँ शीर्षक" --out out\02-chiya-paper.mp4
```

### 4. Topic → script only (review before spending render time)

```powershell
python topic.py --topic "पहिलो जागिरको दिन" --lines 6 --tone "प्रेरणादायी" --out scripts\07-job.txt
```

### 5. Batch

```powershell
python batch.py --voice maya --takes 2 --images perchance --max-images 5
```

Reads every `scripts\*.txt`, writes `out\<date>\`, skips existing outputs unless `--force`. `--only 01,03` limits by filename prefix.

## Choosing the look

| Situation | Template | Images |
| --- | --- | --- |
| Hot takes, punchy text, no b-roll | `templates\dark.json` | `none` |
| Calm, story, quote, essay | `templates\paper.json` | `none` |
| Story with atmosphere | either | `perchance`, 4–5 slots |
| Product/demo with own footage | `dark` | `local --images-dir ...` |
| Max legibility over bright photos | `dark` | `perchance` + default white captions |

`dark` = gold on near-black. `paper` = rust on warm off-white. In image mode captions automatically become white with a dark outline and a vignette is added, whichever template is used.

## Voice

Swar officially ships **nine ready voices** on the Naamche playground:

| Gender | Voices |
| --- | --- |
| Female | Maya, Asha, Nisha, Sabina, Kanchan |
| Male | Aarav, Bibek, Kiran, Sujan |

**But only two are in the open release and in this checkout:** `maya` and `aarav`. The other seven are server-side on `naamchelabs.com/playground`; their public preview MP3s are ~3.4 s, too short to enroll locally. Use the playground for those voices, or enroll a voice of your own.

| Voice | Gender | Notes |
| --- | --- | --- |
| `maya` | female | default; strongest on the sample scripts |
| `aarav` | male | verified sim 0.82, CER 5–7 |
| a directory path | — | any enrolled voice dir; `resolve_voice` accepts a path |

```powershell
--voice maya
--voice aarav
--voice C:\path\to\enrolled-voice
```

Presets are model-made takes in `swar-lab\models\presets\<name>`. `--takes N` is candidates per sentence: **2 is the local default and the right trade-off**; 3+ buys little and costs time. One prompt piece is pinned per run, so the voice does not drift between lines.

Cloning is available through `swar-lab\pipeline\autoclone.py` (`enroll()`), but only with consent — see **Rights** below.

## Typography and colour

```powershell
--font "Nirmala UI"                          # family already installed
--font-file assets\fonts\NotoSansDevanagari.ttf   # portable: family read from the file
--caption-size 66 --hook-size 104
--text-color 0xF2E9DA --accent 0xE6B34D
```

Rules:

- `--font-file` copies the file into `out\fonts\` so the render is reproducible. Use it when handing the project to another machine; installed families are fragile.
- Any Devanagari font must actually cover the conjuncts. Nirmala UI and Noto Sans Devanagari are verified; do not use a Latin-only family.
- Colours are `0xRRGGBB` (or `#RRGGBB`). `--text-color` sets ASS colour directly; `--accent` updates both the ffmpeg hex and the ASS BGR value. Never hand-edit only one of the two in a template.
- Caption size 60–72 is readable on a phone; below 54 is a bug, above 80 wraps badly at `safe_chars` 28.
- Explicit flags override the template, including the image-mode white-caption override.

## Images

| Provider | Behaviour |
| --- | --- |
| `none` | typographic card only |
| `local` | reads `--images-dir` (or `<out>.images\`), filename order, cycled |
| `perchance` | one generated image per beat through the browse relay |

Art direction without an LLM: `src/imageprompt.py` maps Nepali words to English visual concepts plus a photographic suffix. Override with a sidecar next to the script:

```json
// scripts\02-chiya.images.json
["a clay cup of milk tea on a wooden bench, morning light",
 "two friends laughing at a tea stall"]
```

or `{"topic": "...", "prompts": [...]}`. You can also pass `--image-prompts path.json`. Fewer prompts than slots is fine; the rest are derived. `--max-images` should be **3–6**; more slots than ~6 s of speech each makes the video feel like a slideshow.

`--image-style` takes Perchance labels (`Casual Photo`, `Cinematic`, `Professional Photo`, ...). `--image-shape Portrait` is correct for 9:16.

Generation is cached in `<out>.images\` and recorded in `<out>.images.json` with start/end, text, prompt and file. Reuse the cache when re-rendering; `--refresh-images` regenerates.

## Quality gates — check every video

1. **Speech metrics** in the log / `<out>.timing.json`:
   - `sim` ≥ 0.75, `cer` ≤ 12 is normal. A line under `sim` 0.70 or over `cer` 18 was mispronounced — re-run that script line or the whole take.
   - Watch the `heard:` text: if a number, name or English loanword is mangled, rewrite the line more phonetically.
2. **Duration match**: `ffprobe` duration of the MP4 must equal `timing.json` `duration` within ~0.05 s. If not, the audio was trimmed and captions are drifting.
3. **Frame check**: extract frames at two points inside one image slot and confirm they differ (Ken Burns), and one at a caption boundary to confirm the text is not clipped:

   ```powershell
   ffmpeg -y -loglevel error -ss 3 -i out\x.mp4 -frames:v 1 out\f1.png
   ```

   Read the PNG. Devanagari must render, not boxes; captions must sit above the safe area.
4. **Loudness**: the renderer applies a limiter; if a line sounds hot, lower `--takes` noise by regenerating rather than post-processing.
5. **Exit code**: in PowerShell, `2>&1 | Select-String` can make a zero exit look like 1. Redirect with `*> out\run.log` and trust `$LASTEXITCODE`.

## Perchance failure playbook

Perchance is a browser UI, not an API. Failure modes and the fix:

| Symptom | Cause | Fix |
| --- | --- | --- |
| `no JSON` / frame did not load | session missing or disconnected | `browse session list`; re-pair the extension |
| Turnstile / "verify you are human" | challenge on the tab | open the tab, complete it manually, re-run; do not loop |
| Text generator produces nothing | the page ignores programmatic value sets | use `src/textgen.py` as-is: `pressSequentially` + `bringToFront`. Do not swap in `fill()` |
| Image slot becomes a card | that slot failed | acceptable; check `<out>.images.json`, re-run with `--refresh-images` |
| Slow, ~20 s/image | queued free tier | expected; budget ~3 min for a 5-line short |
| Blocked origin | session allowlist | `browse session allow perchance.org "*.perchance.org" image-generation.perchance.org` |

Never put credentials in a script. Secrets are only typed through the relay's secret facility, and only after the session allowlist is set.

## Output contract

Each run leaves, next to the MP4:

| File | Contents |
| --- | --- |
| `<out>.mp4` | 1080×1920, H.264 + AAC, no watermark |
| `<out>.wav` | joined master voiceover |
| `<out>.timing.json` | per-sentence text, start, end, sim, cer |
| `<out>.ass` | burned captions (editable with any ASS tool) |
| `<out>.script.txt` | generated script, only when `--topic` was used |
| `<out>.images.json` + `<out>.images\` | slot plan and cached images, only with images |
| `out\fonts\` | copied font files |

Deliver the MP4 path and the duration; mention the script path so the user can edit and re-render.

## Rights and consent

- **Voice**: only clone your own voice or a voice with written permission. Presets in the repo are model-made and safe. Never clone a public figure or a stranger from a downloaded clip.
- **Script**: write original scripts. Do not transcribe and re-upload someone else's viral Nepali clip — that is the copyright/ToS problem this pipeline exists to avoid.
- **Images**: Perchance permits commercial use and claims no copyright on output, but there is no SLA and no indemnity. For brand work, prefer `local` assets you own.
- **Music**: this pipeline adds none. If the user adds a track, they are responsible for its licence.

## Cost and time

| Step | Time |
| --- | --- |
| TTS, 4–5 lines, 2 takes | ~60–75 s, of which ~45 s is cold model load |
| Perchance image | ~12–23 s each |
| Perchance script | ~10–20 s |
| Render (4–6 clips, xfade, captions) | ~10–16 s |
| **5-line short with 5 images** | **~3 min** |

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| CUDA / cuDNN warnings in the log | harmless; Swar falls back to CPU |
| `HF_TOKEN` warning | harmless |
| Devanagari shows as boxes | wrong font family; use `--font-file` with a real Devanagari TTF |
| Captions drift | regenerated or trimmed WAV without regenerating `timing.json` |
| Prompt ignores the topic | add a sidecar `*.images.json`; the lexicon only knows common words |
| `--topic` returns empty | the text generator was blocked or slow; rerun `topic.py` with `--raw` to inspect, or write the script by hand |
| Batch re-renders everything | outputs exist; pass `--force` only when you mean it |
| Video longer than audio | expected only with the last image padded; check `timing.json` duration |

## Files worth knowing

| Path | What |
| --- | --- |
| `make_short.py` | main CLI |
| `topic.py` | topic → Nepali script |
| `batch.py` | all scripts → date folder |
| `src/tts.py` | per-sentence synthesis, `timing.json` |
| `src/render.py` | ffmpeg pipeline, `parse_color`, `font_family` |
| `src/images.py` | beat planning, providers, fallback cards |
| `src/imageprompt.py` | Nepali → English visual prompts |
| `src/perchance.py` | image driver (relay) |
| `src/textgen.py` | text driver (relay) |
| `templates\*.json` | palettes, sizes, margins |
