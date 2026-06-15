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
