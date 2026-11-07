# Nepali Shorts — agent skill

An agent skill for building vertical **9:16 Nepali short videos** from a topic or a script, locally and without an API key.

It wraps the `swar-studio` pipeline: **Swar TTS → measured caption timings → optional b-roll → ffmpeg 1080×1920 MP4**, with burned-in Devanagari captions.

```
topic or script
   └─ Swar voiceover (one WAV per sentence, measured timings)
        └─ ASS captions (Devanagari-safe)
             └─ optional Perchance / local Ken Burns images
                  └─ ffmpeg: 1080×1920, H.264 + AAC, no watermark
```

## What the skill teaches an agent

- when to use `make_short.py`, `topic.py`, and `batch.py`
- how to pick a template (`dark` / `paper`) and an image provider (`none` / `local` / `perchance`)
- how to switch **voice**, **caption font**, **sizes**, and **colours**
- quality gates: speech `sim`/`CER`, duration match, frame checks
- the Perchance failure playbook (Turnstile, relay session, real keystrokes)
- output contract: every file a run leaves behind
- voice-cloning consent and copyright rules

## Requirements

This repo is the **skill only**. It expects a `swar-studio` checkout and a working Swar install:

| Thing | Needed for |
| --- | --- |
| [Swar](https://github.com/Naamche-Labs/swar) + a Python env with `soundfile`, `numpy` | voiceover |
| `ffmpeg` / `ffprobe` on `PATH` (with libass) | render |
| `fontTools` (optional) | reading a font's family name |
| `browse` relay + Chrome (optional) | only for Perchance text/images |

On Windows the reference paths are:

```
C:\...\swar-studio
C:\...\swar-lab\.venv\Scripts\python.exe
```

Edit the “Locate the project” table in `SKILL.md` if yours differ.

## Install

**OpenCode** (global):

```powershell
git clone https://github.com/dannybyarun/nepali-shorts "$env:USERPROFILE\.config\opencode\skills\nepali-shorts"
```

or with the installer:

```powershell
.\install.ps1
```

```sh
./install.sh
```

Project-local instead: clone into `.opencode/skills/nepali-shorts`.

The skill ID is the directory name, `nepali-shorts`.

## Quickstart

```powershell
cd C:\...\swar-studio
Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY -ErrorAction SilentlyContinue
$env:PYTHONUTF8="1"; $env:PYTHONIOENCODING="utf-8"; $env:WANDB_MODE="disabled"

# topic -> script -> voice -> images -> MP4
python make_short.py --topic "काठमाडौंको सानो चिया पसल" --lines 5 `
  --voice maya --takes 2 --template templates\dark.json `
  --hook "चिया पसलको कथा" `
  --images perchance --max-images 5 `
  --out out\chiya.mp4
```

Voices: `maya` (female) and `aarav` (male) ship locally. Swar offers nine ready voices on its playground; only those two are in the open release. Clone your own from 20–30 s of speech, with consent.

Typography:

```powershell
--font-file assets\fonts\NotoSansDevanagari.ttf
--caption-size 66 --hook-size 104
--text-color 0xF2E9DA --accent 0xE6B34D
```

## Outputs

`<out>.mp4` plus `.wav`, `.timing.json`, `.ass`, optional `.script.txt`, `.images.json`, `.images/`, and `fonts/`.

## Cost

A 5-line short with 5 generated images is about **3 minutes** end to end on CPU. No API key, no per-render fee.

## Rights

- Clone only your own voice or one with written permission.
- Write original scripts; do not re-upload someone else's clip.
- Perchance permits commercial use and claims no copyright on output, but offers no SLA or indemnity.

## License

MIT — see [LICENSE](LICENSE). The skill text is original; Swar itself is MIT (code) and CC BY-SA 4.0 (weights).
