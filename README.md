# Simple Video Player

A lightweight, dependency-free web video player. The playlist is driven entirely
by a JSON file, so adding or removing videos never requires touching the code —
and this whole folder works as a **reusable starter kit** for new projects.

## Features

- 🔎 **Searchable playlist** with live filtering
- 🏷️ **Category chips** with group headings
- ▶️ **Click to play** — autoplays the selected video
- ⏮️ **Prev / Next** buttons and **← / →** keyboard shortcuts
- ↪️ **Auto-advance** to the next video when one ends
- ⬇️ **Download button** to save the current clip
- 💾 **Remembers your last video** via `localStorage`
- ⚠️ **Graceful errors** when a file is missing or can't load
- 📱 Responsive layout (two-panel on desktop, single column on mobile)

## Use it for a new project (the fast path)

1. **Copy this whole folder.**
2. **Drop your clips** into the `video/` subfolder (`.mp4 / .webm / .mov / .m4v`).
3. **Run the generator** — right-click `generate-videos.ps1` → *Run with
   PowerShell*, or from a terminal in the folder:
   ```powershell
   .\generate-videos.ps1
   ```
4. **Tweak** the new names/categories in `videos.json` if you like, set the
   `<h1>`/`<p>` title in `index.html`, then **upload the whole folder** to your
   server.

That's it — no hand-editing of file lists.

## Folder layout

| Path                  | Purpose                                              |
| --------------------- | ---------------------------------------------------- |
| `index.html`          | Page markup (edit the title here)                    |
| `style.css`           | Styling / theme                                      |
| `scriptsv.js`         | Player logic (loads `videos.json`)                   |
| `videos.json`         | The playlist (generated; safe to hand-edit too)      |
| `generate-videos.ps1` | Builds `videos.json` from the `video/` folder        |
| `video/`              | **Put your clips here**                              |
| `poster.png`          | Optional placeholder shown before a video loads      |

## How the generator works

For each clip in `video/`, it:

- turns the file name into a friendly title (`my_cool_VideoFile.mp4` → "My Cool
  Video File", splitting `camelCase`, underscores, and dashes)
- guesses a category (`*superpower*` → Superpowers, `mofm_*` → Magic of Me,
  everything else → Stories)
- stores the path web-style as `video/<file>`

**Re-running is safe.** Entries whose `src` already exists in `videos.json` keep
their current name and category, so manual tweaks survive. Files removed from the
folder are dropped; newly-added files are appended.

`videos.json` entries look like:

```json
{ "name": "Kindness", "src": "video/KindnessSuperpower.mp4", "category": "Superpowers" }
```

## Testing locally

Browsers block `fetch()` on `file://` URLs, so `videos.json` won't load if you
just double-click `index.html`. Serve the folder over HTTP instead:

```bash
# from the project folder
python -m http.server 8000
# then open http://localhost:8000
```

> Tip: after uploading new videos, do a hard refresh (Ctrl/Cmd + Shift + R) to
> clear the cached `videos.json`.
