# Simple Video Player — IPD Book Readings

A lightweight, dependency-free video player for "Builder Bob Story Time" book
readings. The story list is driven entirely by a JSON file, so adding or removing
videos never requires touching the code.

## Features

- 🔎 **Searchable playlist** with live filtering
- 🏷️ **Category chips** (Superpowers · Magic of Me · Stories) with group headings
- ▶️ **Click to play** — autoplays the selected story
- ⏮️ **Prev / Next** buttons and **← / →** keyboard shortcuts
- ↪️ **Auto-advance** to the next story when one ends
- ⬇️ **Download button** to save the current clip
- 💾 **Remembers your last video** via `localStorage`
- ⚠️ **Graceful errors** when a file is missing or can't load
- 📱 Responsive layout (two-panel on desktop, single column on mobile)

## Files

| File           | Purpose                                            |
| -------------- | -------------------------------------------------- |
| `index.html`   | Page markup                                        |
| `style.css`    | Styling / theme                                    |
| `scriptsv.js`  | Player logic (loads `videos.json`)                 |
| `videos.json`  | **The story list — edit this to manage videos**    |
| `generate-videos.ps1` | Auto-builds `videos.json` from a folder of clips |

The `.mp4` files and `poster.png` are **not** stored in this repo; they live on
the hosting server alongside these files.

## Adding or editing videos

Edit `videos.json`. Each entry has three fields:

```json
{ "name": "Kindness", "src": "KindnessSuperpower.mp4", "category": "Superpowers" }
```

- `name` — label shown in the playlist
- `src` — the video file name (must match the file on the server)
- `category` — used for grouping and the filter chips (any value works; new
  categories appear as chips automatically)

## Generating `videos.json` automatically

Instead of typing entries by hand, drop the script next to your clips and run it:

```powershell
# scan the current folder and write videos.json
.\generate-videos.ps1

# or point it at another project's clips
.\generate-videos.ps1 -Path "D:\Projects\NewClips"
```

It scans for `.mp4 / .webm / .mov / .m4v` files and, for each one:

- turns the file name into a friendly title (`my_cool_VideoFile.mp4` → "My Cool
  Video File", splitting `camelCase`, underscores, and dashes)
- guesses a category (`*superpower*` → Superpowers, `mofm_*` → Magic of Me,
  everything else → Stories)

**Re-running is safe.** Any entry whose `src` already exists in `videos.json`
keeps its current name and category, so your manual edits survive — only new
files get added. Review the new entries, tweak as needed, then commit.

## Running it

Browsers block `fetch()` on `file://` URLs, so `videos.json` won't load if you
just double-click `index.html`. Serve the folder over HTTP instead:

```bash
# from the project folder
python -m http.server 8000
# then open http://localhost:8000
```

When deployed to the web server, place the `.mp4` files and `poster.png` in the
same directory as `index.html`.

> Tip: after uploading new videos, do a hard refresh (Ctrl/Cmd + Shift + R) to
> clear the cached `videos.json`.
