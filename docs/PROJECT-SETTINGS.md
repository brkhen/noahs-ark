# Project settings explained

This explains why the settings in `project.godot` are set the way they are. Godot deletes comments whenever it saves that file, so the notes live here. They match Backyard Dominoes except where noted.

Change these settings in Godot under **Project → Project Settings**, not by editing `project.godot` by hand.

---

## Audio

| Setting | Value | Why |
|---|---|---|
| `general/text_to_speech` | `true` | Lets the game read words and stories aloud with the device's built-in voices, like the prototype's "Hear this" button. |

## Display

| Setting | Value | Why |
|---|---|---|
| `window/size/viewport_width` / `viewport_height` | `1080` × `1080` | Same square base as Backyard Dominoes. With `aspect="expand"`, a portrait phone gets a tall canvas (about 1080×2350 on the iPhone 18 Pro Max) and a tablet a shorter, wider one, at the same scale. |
| `window/size/window_width_override` / `window_height_override` | `472` × `1024` | On the Mac, opens a window with the shape of an upright phone. |
| `window/stretch/mode` | `"canvas_items"` | Scales everything to fit any phone. |
| `window/stretch/aspect` | `"expand"` | Adds extra space on taller or wider screens instead of black bars. |
| `window/handheld/orientation` | `1` | **Portrait only.** Different from Backyard Dominoes (landscape). The prototype is designed upright and asks people to "turn your phone upright for the best view". Brian can change this; see [VISION.md](VISION.md). |

## Rendering

| Setting | Value | Why |
|---|---|---|
| `renderer/rendering_method` | `"mobile"` | The Mobile renderer is built for phones. |
| `textures/vram_compression/import_etc2_astc` | `true` | Compresses textures in the formats phones need. |

## Export presets (`export_presets.cfg`)

| Preset | Output | Notes |
|---|---|---|
| **iOS Simulator** | `builds/ios/NoahsArk.xcodeproj` | Exports an **Xcode project** (not a finished app). Bundle ID `com.brianhennington.noahsark`. iPhone and iPad, iOS 15 or later. The Team ID is a placeholder (`0000000000`) until the Apple Developer account is set up. |
| **Web** | `builds/web/index.html` | For private browser testing, like Backyard Dominoes. Uses `web/shell.html` (a "Tap to start" screen that turns on sound and voices). |

There is no Android preset: the App Store is the goal.
