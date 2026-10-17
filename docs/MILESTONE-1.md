# Milestone 1: "The ark is on your Mac"

**Goal:** the Noah's Ark Godot project runs on Brian's Mac and in the iPhone Simulator, with the hub screen and its three game buttons. Then each game moves over from the web prototype, one at a time.

**How to use this:** tick each box as you go. One step at a time.

---

## Part A: Done by Bezalel (2026-10-17)

- [x] **A1. Godot project created**, set up like Backyard Dominoes: Godot 4.7, Mobile renderer, the same 1080 base canvas, iOS and Web export presets. See [PROJECT-SETTINGS.md](PROJECT-SETTINGS.md).
- [x] **A2. Folders:** `scenes/`, `scripts/ui/`, `scripts/game/`, `assets/art/`, `assets/audio/`, `data/`, `tests/`, `docs/`, `web/`.
- [x] **A3. The hub screen** (`scenes/main.tscn`), laid out like the Story Games artifact: the painted ark scene with the gold "Noah's Ark: Story Games" title, Noah's welcome bubble, and a card for each game (Word Search, Memory Match, Story Sequence) with its little picture and a Play button. A tap anywhere on a card opens the game, and each game screen has a large Back button. It uses the artifact's own art, colors and fonts (Cinzel and Quicksand). Everything stays clear of the notch and home bar.
- [x] **A4. Automated tests:** 4 of 4 pass in Godot 4.7.2 (hub, open and go back, iPhone 18 Pro Max layout inside the safe area).
- [x] **A5. A placeholder app icon** (`icon.svg`). The real icon gets made in Claude's Design canvas.

Screenshots: [hub](screenshots/hub.png), [game screen](screenshots/game_screen.png).

## Part B: On your Mac (Brian)

- [ ] **B1. Put the project on your Mac** in a folder called `NoahsArk` in your home folder (next to `BackyardDominoes`). Open **Terminal** and run:
  ```
  git clone https://github.com/brkhen/noahs-ark ~/NoahsArk
  ```
  *Why:* the same way Backyard Dominoes lives in `~/BackyardDominoes`, with GitHub as the backup.
- [ ] **B2. Open it in Godot.** Open Godot, click **Import**, choose `~/NoahsArk/project.godot`, then **Import & Edit**.
  *Why:* Godot sets up its own cache files the first time.
- [ ] **B3. Press Play** (the ▶ button, top right). An upright phone-shaped window shows the hub. Tap each game and Back.
- [ ] **B4. Export the Xcode project.** In Godot: **Project → Export**, choose **iOS Simulator**, click **Export Project**, keep `builds/ios/NoahsArk.xcodeproj`, and click **Save**. Untick "Export With Debug" only if Godot asks.
  *Why:* this is the step that turns the Godot game into an Xcode project, exactly like Backyard Dominoes.
- [ ] **B5. Run it in the iPhone Simulator.** Double-click `~/NoahsArk/builds/ios/NoahsArk.xcodeproj` to open Xcode. At the top, choose an iPhone simulator (the largest Pro Max), then press **Run** (▶).

**Not needed yet:** the Apple Developer Program ($99/year). It's only needed to put the app on your real iPhone and to publish.

## Part C: Move the games over, one at a time

Each step ends with something you can play on the Mac and in the Simulator.

- [ ] **C1. Story Sequence** (the simplest game): tap the events in order, with the timeline filling in and a "Round Complete!" screen.
- [ ] **C2. Memory Match:** the flip cards and animal pairs.
- [ ] **C3. Word Search:** the letter grid, tap first and last letter or drag.
- [ ] **C4. "Who's playing today?"** and saved settings: profiles, your name, text size (the Aa button), read-aloud.
- [ ] **C5. Noah's voice and congratulations** (tap Noah to hear him).
- [ ] **C5b. The rest of the hub:** the locked rainbow promise, Settings, Hall of the Ark, Start over, and For Parents & Teachers.
- [ ] **C6. Painted art** from the Illustration Art Direction Brief, replacing the placeholder scenery.
- [ ] **C7. Check on your iPhone 18 Pro Max** (needs the Apple Developer account).
