# PhotonFabric – VideoKit

A modular, ffmpeg-driven video toolkit with optional AI models – designed for **interactive use on the command line** _and_ for fully automated batch workflows.

PhotonFabric VideoKit wraps common video tasks into focused subcommands:

- converting & compressing
- trimming, scaling, cropping/padding
- merging clips, audio and subtitles
- metadata inspection & editing
- GIF / meme generation
- image-sequence → video
- frame interpolation
- classic filter enhancement
- **AI upscaling & enhancement** (Real-ESRGAN / RealCUGAN, etc.)
- stream extraction (audio, frames, subtitles, thumbnails)

All subcommands follow the same philosophy:

- **Interactive mode** (no file arguments): guided wizard, safe defaults, explanations.
- **CLI/batch mode** (with files & flags): fully scriptable, stable interface.
- Wherever possible, **streams, chapters, thumbnails, alpha & metadata** are preserved or sensibly re-created.

---

## 1. Overview

PhotonFabric – VideoKit is a **modular toolbox built around ffmpeg** (and optional AI models) that breaks typical video workflows into separate commands:

- `convert` – container/codec conversion with presets
- `compress` – simple “quality in %” interface for filesize reduction
- `trim` – fast or frame-accurate cutting
- `scale` – classic resolution scaling
- `croppad` – axis-wise crop or pad to a target resolution
- `merge` – concatenate clips + add audio/subtitle tracks
- `interpolate` – increase or normalize FPS (frame interpolation)
- `img2vid` – turn image sequences into videos
- `extract` – audio, subtitles, frames, video streams, thumbnails
- `enhance` – classic filter enhancement (stabilize, denoise, color)
- `aienhance` – AI upscaling/enhancement with Real-ESRGAN / RealCUGAN
- `gif` – animated GIF & meme creation
- `metadata` – detailed metadata inspection & editing

Every command lives in its own module and has a dedicated infofile under `infofiles/PhotonFabric.<subcommand>.en.info`.

---

## 2. Requirements

- **OS**: Primarily developed and tested on Linux.
- **Runtime**: Python 3.x
- **Core tools**:
  - `ffmpeg` and `ffprobe` (required)
- **Optional for AI features**:
  - CUDA-capable GPU (for PyTorch backends)
  - AI models (Real-ESRGAN / RealCUGAN, etc.) – handled by the project’s installer / model manager.

See the repository’s `install.sh` / documentation for the exact, up-to-date dependencies and model setup.

---

## 3. Installation

> The exact commands may differ depending on how you structure the repo; adapt names to your layout.

### 3.1 Clone the repository

```bash
git clone https://github.com/<your-account>/PhotonFabric-VideoKit.git
cd PhotonFabric-VideoKit
3.2 Using the installer (recommended)
If the project provides an install.sh:

chmod +x install.sh
./install.sh

Typical responsibilities of the installer:

create a Python virtual environment

install required Python packages

check/install ffmpeg & ffprobe (if possible)

download/prepare AI models for aienhance

create a convenient launcher (e.g. video)

3.3 Manual setup (generic)
If you prefer a manual setup:


python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# optionally create a convenience alias
echo 'alias video="python -m photonfabric"' >> ~/.bashrc
Adjust module/entry-point names to your actual package layout.

4. Basic Usage
All commands share the same pattern:

video <COMMAND> [FILES] [OPTIONS]
Interactive mode:
Call without FILES → a guided wizard starts.

CLI / batch mode:
Provide one or more files and the relevant flags.

Examples:


# Interactive conversion wizard
video convert

# Direct conversion, CLI-style
video convert input.mkv --format mp4 --codec h264 --preset web

# Batch pattern: file%.mkv → file001.mkv, file6.mkv, file030.mkv, …
video compress season1_ep%.mkv --quality 40
5. Global Behaviour & Concepts
5.1 Interactive vs. CLI mode
No files given → interactive mode:

step-by-step questions (format, codec, preset, resolution, etc.)

safe defaults, warnings & hints

Files + flags given → non-interactive CLI:

suitable for scripts, cron jobs, batch processing

stable flag semantics as documented in the infofiles

5.2 Streams, metadata & thumbnails
Across commands, PhotonFabric tries to:

preserve video/audio/subtitle streams whenever no re-encode is needed (-c copy where possible)

preserve or re-embed cover/thumbnail images

maintain metadata and chapters, mapping or re-creating them depending on target container/codec

use the Plan-API to perform container-aware stream mapping

5.3 Alpha & pixel format
The toolkit is alpha-aware:

detects alpha channels in sources

warns if the chosen container+codec cannot carry alpha (e.g. MP4 + h264)

suggests suitable alpha-capable combinations (e.g. MKV+FFV1, MOV+ProRes 4444, MKV/WebM+VP9/AV1 alpha, MKV/AVI+UtVideo/PNG/QTRLE/RGBA)

keeps track of pixel formats and corrects encoder alignment constraints (even widths/heights etc.) where necessary

5.4 Placeholders & batch patterns
For all commands, the percent sign % is a numbering placeholder:

file%.mkv → file001.mkv, file6.mkv, file030.mkv, …

This is used consistently across modules (convert, compress, trim, metadata, extract, …).

5.5 Return codes
0 → success

non-zero → ffmpeg/environment error (e.g. invalid flags, missing codecs, failed writes)

This makes PhotonFabric easy to integrate into shell scripts and CI pipelines.

6. Command Overview
Command Purpose
convert General container/codec conversion with presets, resolution & FPS control
compress Simple compression by “quality %” mapped to CRF
trim Fast (lossless/GOP-based) or precise (re-encode) cutting
scale Resolution scaling with aspect-ratio control
croppad Axis-wise crop/pad to target resolution
merge Concatenate clips, add audio/subtitle tracks, manage offsets & gaps
interpolate Raise or normalize FPS via motion interpolation
img2vid Create videos from still image sequences
extract Extract audio, subtitles, frames, video streams and thumbnails
enhance Classic ffmpeg filter enhancement (stabilize, denoise, color, levels, etc.)
aienhance AI upscaling/enhancement using Real-ESRGAN/RealCUGAN (+ optional TTA/blending)
gif Animated GIF & meme creation with text overlays
metadata Read/edit tags, list tag schema, JSON export, thumbnail control
￼
Below is a more detailed look at each command.
For full flag lists, see the corresponding infofiles/PhotonFabric.<command>.en.info files.

7. Commands in Detail
7.1 convert – general container/codec conversion
Infofile: infofiles/PhotonFabric.convert.en.info

Converts video files using ffmpeg. Supports both interactive and CLI mode:

choose target container (mp4, mkv, avi, mov, webm, mpeg)

choose video codec (h264, hevc, av1, vp9, vp8, mpeg4, prores, dnxhd, jpeg2000, mjpeg, ffv1, huffyuv, utvideo, theora, qtrle, hap, rawvideo, png, magicyuv, cineform, mpeg1video, mpeg2video, …)

presets (messenger360p, messenger720p, web, casual, cinema, studio, ultra, lossless)

optional resolution & framerate changes

preserves or re-embeds thumbnails, metadata and compatible streams

Example:

# Web-friendly MP4, AV1 codec, “web” preset
video convert movie.mkv --format mp4 --codec av1 --preset web

7.2 compress – filesize reduction by percentage
Infofile: infofiles/PhotonFabric.compress.en.info

Compresses videos via a simple visual quality percentage:

--quality (0–100) maps internally to ffmpeg’s CRF

higher values → better quality, larger files

lower values → stronger compression, smaller files

container/codec are chosen to stay as close as possible to the original (or a general default), including cover preservation

Example:

# Compress series to about 40% quality; good balance for many videos
video compress season1_ep%.mkv --quality 40

7.3 trim – cutting & segment extraction
Infofile: infofiles/PhotonFabric.trim.en.info

Two modes:

Fast (lossless/GOP-based):

copies video/audio/subtitles (-c copy)

cuts on keyframes → not perfectly frame-accurate

Precise (re-encode):

frame-accurate

uses quality presets (messenger360p, …, lossless)

Time formats: SS(.fff), MM:SS, HH:MM:SS(.fff), percentages (10% / 10p), negative offsets (-1:20 = back from end).

Examples:

bash
￼Code kopieren
# Simple lossless trim: 30s to 50s
video trim film.mp4 --start 0:30 --duration 20

# Precise trim with “cinema” quality
video trim input.mkv --start 01:00:00 --end 01:05:30 --precise --quality cinema

# Batch trim using patterns
video trim clip%.mp4 --start 10 --duration 30%
Thumbnails and metadata are preserved and re-embedded.

7.4 scale – resolution scaling
Infofile: infofiles/PhotonFabric.scale.en.info

Scales videos to preset or custom resolutions:

presets like 240p, 360p, 480p, 720p, 1080p, 1440p, QHD+, 4K, 4K-DCI, 8K, 8K-DCI

original keeps original resolution but fixes odd dimensions (encoder alignment)

custom with flexible separators (W:H, W×H, W H, …)

--preserve-ar controls aspect ratio (default: true → bounding box behaviour)

Examples:

# Scale to 1080p, preserving AR
video scale clip.mp4 --resolution 1080p

# Batch downscale
video scale film%.mkv --resolution 720p

# Custom target without AR preservation
video scale sample.mov --resolution 320x240 --preserve-ar false
Streams are re-mapped sensibly; thumbnails are preserved.

7.5 croppad – axis-wise crop/pad to target resolution
Infofile: infofiles/PhotonFabric.croppad.en.info

Crop or pad per axis:

choose target --resolution (same preset/custom scheme as scale)

use --offset / --offset-x / --offset-y to control crop origin

for sources with alpha, transparent padding is used

original can be used to only touch metadata/thumbnail (no actual crop/pad)

Example:

# Center-crop/pad to 1920x1080
video croppad input.mkv --resolution 1920x1080

# Crop starting from a specific offset
video croppad input.mkv --resolution 1920x800 --offset 0:100

7.6 merge – concatenate & add streams
Infofile: infofiles/PhotonFabric.merge.en.info

Combines:

multiple video clips (concat)

additional audio tracks

additional subtitle files

Key options:

--target-res strategy (match-first, no-scale, smallest, average, largest, fixed:WxH)

--offset, --pause between clips

--audio-offset, --subtitle-offset

--extend to length of longest extra track

--audio-name, --subtitle-name for unified track titles

standard --format, --codec, --preset, --output

Streams & metadata:

main video streams, metadata, chapters, thumbnails are mapped where possible

additional subtitles converted to mov_text for MP4/MOV; in MKV/MOV/AVI usually copied

automatic language/title heuristics from filenames/tags (ISO-639-2)

Examples:

# Seamless join with small pause
video merge a.mp4 b.mp4 --target-res match-first --pause 1.0s --format mkv --codec h264 --preset casual

# Concatenate MOVs without scaling, using ProRes
video merge part1.mov part2.mov part3.mov -tr no-scale -f mov -c prores -pr studio

# Video + audio + subtitles with offsets
video merge movie.mkv dub_de.aac subs_en.srt --audio-offset 1.5s --subtitle-offset 2s --format mkv

# Extend to longest external audio commentary
video merge base.mp4 commentary.wav --extend -f mp4 -c h264 -pr casual

7.7 interpolate – frame-rate upsampling
Infofile: infofiles/PhotonFabric.interpolate.en.info

Raises or normalizes FPS using ffmpeg’s minterpolate:

--factor accepts:

multiplicative: 2x, 1.5x, …

absolute FPS: 60, 59.94, 30000/1001, …

--quality profile:

std – balanced

hq – mild pre-denoise for more stable motion vectors

max – stronger pre-denoise + sharpening

Example:

# 25 → 50 FPS
video interpolate film.mkv --factor 2x

# Normalize to ~59.94 FPS using rational FPS
video interpolate clip.mp4 --factor 60000/1001 --quality hq
Streams and metadata are carried along where supported.

7.8 img2vid – image sequence → video
Infofile: infofiles/PhotonFabric.img2vid.en.info

Creates videos from:

numbered image sequences (frame_0001.png, frame_0002.png, …)

folders containing images

Options:

presets: messenger360p, messenger720p, web, casual, cinema, studio, ultra, lossless

--format, --codec (similar policy to convert)

--framerate or --duration for total video length

optional --scale

thumbnails & metadata are created/preserved where the container/codec allow it

Example:

# Simple slideshow, web preset
video img2vid frames/frame_%.png --preset web --framerate 30 --format mp4

7.9 extract – audio / subtitle / frame / video extraction
Infofile: infofiles/PhotonFabric.extract.en.info

Selective extraction:

--audio → extract all audio tracks as MP3 (-q:a 0), uniquely named (with index/language)

--subtitle → extract subtitles, optional filters by language etc.

--frame → extract a single still image (frame) at:

seconds: 10, 10s

MM:SS, HH:MM:SS(.ms)

percentage: 50%

special positions: middle, mid, center, centre

--video / --format for raw video streams / formats

defaults are safe; negative times are not allowed; times are clamped to duration if necessary

Examples:

# Single representative frame at 50%
video extract movie.mkv --frame 50%

# All audio tracks as MP3
video extract concert.mkv --audio

# All audio + English subtitles from multiple files
video extract film%.mkv --audio --subtitle en

7.10 enhance – classic filter enhancement
Infofile: infofiles/PhotonFabric.enhance.en.info

Filter-based enhancement with ffmpeg:

Presets combine stabilization, denoise and color tweaks:

soft, realistic, max, color_levels, cinematic, hist_eq, …

Individual controls:

stabilization toggles & strength (--stabilize, --stab-method, …)

denoise filters

brightness/contrast/saturation percentages

Audio is passed through or re-encoded appropriately; thumbnails are preserved.

Example:

# Light “realistic” enhancement
video enhance vacation.mp4 --preset realistic

# Custom color tweak
video enhance clip.mkv --brightness 10 --contrast 5 --saturation 15

7.11 aienhance / ai-enhance – AI upscaling & enhancement
Infofile: infofiles/PhotonFabric.aienhance.en.info
The command usually accepts both aienhance and ai-enhance spelling.

AI-based scaling / enhancement using models such as Real-ESRGAN and RealCUGAN:

--aimodel:

e.g. realesr-general-x4v3 (general-purpose 4×)

realesr-animevideov3, RealCUGAN variants, etc.

--scale:

factor (e.g. 2.0, 4.0) – often flexible between 1.0 and 4.0 depending on model

Denoise / noise level flags (model-dependent)

Optional TTA (--tta) for better quality (slower)

Blending:

--blend + --blend-opacity to mix original and AI result

Chunked processing, priorities, etc., to manage VRAM and runtime

Streams, metadata, chapters and thumbnails are preserved and remuxed back as far as possible.

Example:

# 1080p → ~4K using a general AI model
video aienhance ep%.mkv --aimodel realesr-general-x4v3 --scale 2 --priority medium

7.12 gif – GIF & meme creation
Infofile: infofiles/PhotonFabric.gif.en.info

Creates animated GIFs from:

video clips

existing GIFs

Key features:

meme text:

--text-top, --text-bottom

font size:

labels: thiny, small, medium, grande, large, huge

or explicit pixel sizes (min 8px)

separate --font-size-top / --font-size-bottom flags (if available)

keep quality: optional high-quality pipeline instead of aggressive GIF palette optimization

--no-auto-open to suppress automatic viewer launch

Example:

video gif clip.mp4 \
  --text-top "WHEN CODE WORKS" \
  --text-bottom "AND YOU DON’T KNOW WHY" \
  --font-size medium

7.13 metadata – inspect & edit metadata
Infofile: infofiles/PhotonFabric.metadata.en.info

Reads and writes container/stream metadata, with strong introspection and safety:

--list-tags:

formatted overview (file info, video block, color info, alpha, audio summary, chapter count, grouped tags)

--list-tags-json:

structured JSON of the same data

--list-tagnames:

full schema of known metadata keys:

editable, protected, and virtual read-only fields

Generic --tag interface:

--tag title → print title

--tag title="My Movie" → set title

multiple --tag options allowed

Tag-specific auto-flags for every editable key:

--title, --artist, --genre, --production_year, …

--set-tag-KEY, --delete-tag-KEY, --list-tag-KEY

Thumbnail control:

--set-thumbnail IMAGE

--delete-thumbnail

--show-thumbnail

Interactive mode:

shows technical video info (resolution, FPS, pixel format, color primaries, alpha, streams, chapters)

groups metadata into protected, editable, other

allows interactive edit/delete of editable tags

supports interactive thumbnail set/remove (if supported)

Writes are done in-place via an internal metadata_support layer, with:

AVI quirks handled (optionally via exiftool)

post-write verification of requested tag changes

Examples:

# Interactive view
video metadata film.mkv

# Tag schema
video metadata --list-tagnames

# Compact overview for multiple episodes
video metadata season1_ep%.mkv --list-tags

# Read specific tags
video metadata film.mkv --tag title --tag production_year

# Set tags in batch
video metadata ep%.mkv --title "My Series" --production_year 2024

# Delete tags
video metadata film.mkv --delete-tag-comment --delete-tag-keywords

# Full JSON export including streams & chapters
video metadata film.mkv --list-tags-json --all > meta_film.json
8. Further Documentation
Each command has a dedicated infofile under infofiles/:

infofiles/
  PhotonFabric.en.info                 # Global overview (EN)
  PhotonFabric.convert.en.info         # convert
  PhotonFabric.compress.en.info        # compress
  PhotonFabric.trim.en.info            # trim
  PhotonFabric.scale.en.info           # scale
  PhotonFabric.croppad.en.info         # croppad
  PhotonFabric.merge.en.info           # merge
  PhotonFabric.interpolate.en.info     # interpolate
  PhotonFabric.img2vid.en.info         # img2vid
  PhotonFabric.extract.en.info         # extract
  PhotonFabric.enhance.en.info         # enhance
  PhotonFabric.aienhance.en.info       # aienhance / ai-enhance
  PhotonFabric.gif.en.info             # gif
  PhotonFabric.metadata.en.info        # metadata
These infofiles serve as the single source of truth for all flags and behaviour. The README gives a high-level overview; always refer to the infofiles for full details and the most current options.

9. Contributing
Contributions, bug reports and ideas are welcome!

report issues with:

the CLI behaviour

ffmpeg compatibility quirks

AI model support / performance

propose new presets and defaults

help with documentation and translations

Please check the existing issues and infofiles before opening a new ticket to keep the discussion focused.

10. License
PhotonFabric – VideoKit is licensed under the [MIT License](./LICENSE).

Some optional components and dependencies are downloaded from their original
repositories and remain under their respective licenses, including but not
limited to:
- Real-ESRGAN (BSD 3-Clause)
- BasicSR, GFPGAN (Apache-2.0)
- facexlib (MIT)
- CodeFormer (S-Lab Non-Commercial License 1.0 – **non-commercial use only**)
- Microsoft Core Fonts – Impact (proprietary, Microsoft Core Fonts EULA)

See `THIRD_PARTY_LICENSES.md` for an overview and the upstream projects.
See the LICENSE file in this repository for licensing terms.
