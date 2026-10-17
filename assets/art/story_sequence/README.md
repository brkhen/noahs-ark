# Story Sequence art

The event pictures from the web prototype's Story Sequence (`docs/prototype/story-games.html`, `EV_ART`), rendered at 512×512 with a clear background by `tools/seqcap.js`, then cropped to the drawing. They are the prototype's own original drawings, no emoji.

| File | Event |
|---|---|
| `ev_build.png` | God tells Noah to build the ark (Noah with a hammer and timber) |
| `ev_board.png` | The animals board (Noah leading an elephant up the ramp) |
| `ev_shut.png` | The Lord shuts the door |
| `ev_rain.png` | The rain falls |
| `ev_land.png` | The ark rests on Mount Ararat |
| `ev_dove.png` | Noah sends out a dove |
| `ev_rainbow.png` | The rainbow, God's promise |

To render them again: `NODE_PATH=$(npm root -g) node tools/seqcap.js <output folder>` (needs Playwright).
