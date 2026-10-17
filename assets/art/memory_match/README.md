# Memory Match art

The card pictures from the web prototype's Memory Match (`docs/prototype/story-games.html`), rendered at 512×512 by `tools/mmcap.js`. They are the prototype's own original drawings, no emoji.

| File | Picture |
|---|---|
| `card_back.png` | The back of every card (the ark) |
| `animal_dove.png` | Dove |
| `animal_lion.png` | Lion |
| `animal_giraffe.png` | Giraffe |
| `animal_elephant.png` | Elephant |
| `animal_zebra.png` | Zebra |
| `animal_monkey.png` | Monkey |

To render them again: `NODE_PATH=$(npm root -g) node tools/mmcap.js <output folder>` (needs Playwright).
