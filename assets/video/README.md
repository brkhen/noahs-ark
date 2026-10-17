# Rainbow scene video

`rainbow_finale.ogv` is the web prototype's own flood-and-rainbow scene (`docs/prototype/story-games.html`, `runRecedeToRainbow` then `runRainbowFinale`), recorded frame by frame by `tools/record_finale.js` and turned into a Theora video with ffmpeg. It's 1272×1020 at 24 frames a second and runs 25.9 seconds. `rainbow_finale_end.png` is its last frame, which stays on screen after the video ends.

The words and verses under the picture are drawn by the app (`scripts/ui/rainbow_finale.gd`), not baked into the video, so they stay sharp and get read aloud.

The art is the prototype's own original drawings. This video is a placeholder until the painted art (MILESTONE-1 C6) arrives.
