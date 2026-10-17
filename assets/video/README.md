# Story scene videos

Both are the web prototype's own scenes (`docs/prototype/story-games.html`), recorded frame by frame by `tools/record_finale.js` and turned into Theora videos with ffmpeg, 1060×850 at 24 frames a second. Each `_end.png` is the video's last frame, which stays on screen after it ends.

| File | Plays after | Prototype scene | Length |
|---|---|---|---|
| `rainbow_finale.ogv` | Story Sequence | `runRecedeToRainbow` then `runRainbowFinale`: the flood goes down, the dove, the rainbow | 26.8 s |
| `stampede.ogv` | Memory Match | `runFinale`: the animals board two by two, the family goes in, the door shuts, the rain | 44.9 s |

The words and verses under the picture are drawn by the app (`scripts/ui/story_scene.gd`), not baked into the video, so they stay sharp and get read aloud.

The art is the prototype's own original drawings. These videos are placeholders until the painted art (MILESTONE-1 C6) arrives.
