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
- [x] **B4. Run it on your iPhone** (done 2026-10-17). The iPhone Simulator can't run Godot games on this Mac (Godot's simulator files are Intel-only and the iOS 27 simulators are Apple-chip only), so we test on the real iPhone 18 Pro Max instead:
  1. In Godot: **Project → Export…**, pick **iOS Simulator**, **Export Project…**, and save as `builds/ios/NoahsArk.xcodeproj`.
  2. Open `builds/ios/NoahsArk.xcodeproj` in Xcode and choose **Brian's iPhone 18 Pro Max** at the top.
  3. In **Signing & Capabilities**, under **Signing (Debug)**, set **Team** to **Brian Hennington (Personal Team)**.
  4. Unlock the phone and press **▶ Run**.
  With the free Personal Team, the app stops opening after 7 days. Running it again from Xcode renews it.

**Not needed yet:** the Apple Developer Program ($99/year). It's only needed to put the app on your real iPhone and to publish.

## Part C: Move the games over, one at a time

Each step ends with something you can play on the Mac and in the Simulator.

- [x] **C1. Story Sequence** (the simplest game): tap the events in order, with the timeline filling in and a "Round Complete!" screen. Done 2026-10-17: three rounds (4, 5, 6 events), the prototype's own pictures, Noah's cheers and "Hmm, think again!", chimes, "Hear the choices" read aloud, and "Leave this round?" before Back loses progress. No timer ("No rush"). After the last round, "See the promise" plays the prototype's flood-and-rainbow scene (recorded into `assets/video/`), with its words and verses read aloud. Still to come: the prototype's timer setting. Screenshot: `docs/screenshots/story_sequence.png`.
- [x] **C2. Memory Match:** the flip cards and animal pairs. Done 2026-10-17: three rounds (4, 5, 6 pairs) of the prototype's own animal cards, four across, with a quick flip. A pair stays up and Noah says its name; two different animals turn back over. Noah's cheers, chimes, and "Leave this round?" before Back loses progress. No timer. After the last round, "See them run!" plays the prototype's animals-boarding-the-ark scene (recorded into `assets/video/`), with its words and verses read aloud. Screenshots: `docs/screenshots/memory_match.png`, `docs/screenshots/stampede_scene.png`.
- [x] **C3. Word Search:** the letter grid, tap first and last letter or drag. Done 2026-10-17: three rounds (7, 8, 9 letters across) of the prototype's words, hidden in all eight directions. Tap the first letter then the last, or slide across a word; a found word turns gold, is crossed off the list and read aloud, with Noah's cheers, chimes, "Hear the words", and "Leave this round?" before Back loses progress. No timer. After the last round, "See them build!" plays the prototype's ark-building scene with its sounds. Screenshots: `docs/screenshots/word_search.png`, `docs/screenshots/building_scene.png`.
- [x] **C4. "Who's playing today?"** and saved settings: profiles, your name, text size (the Aa button), read-aloud. Done 2026-10-17: a new player is first asked who's playing (Little one, Grown-up, Together, with "Hear this"), which sets text size and reading aloud as in the prototype. The hub has two name boxes (your name, and who's playing with you) that Noah's welcome uses, and Aa (Normal, Large, Extra large), Read to me (On/Off) and Who's playing buttons. All of it is kept on the phone (`user://settings.cfg`). Hear the choices and Hear the words always read. Screenshots: `docs/screenshots/whos_playing.png`, `docs/screenshots/hub.png`.
- [ ] **C5. Noah's voice and congratulations** (tap Noah to hear him).
- [ ] **C5b. The rest of the hub:** the locked rainbow promise, Settings, Hall of the Ark, Start over, and For Parents & Teachers.
- [ ] **C6. Painted art** from the Illustration Art Direction Brief, replacing the placeholder scenery.
- [ ] **C7. Check on your iPhone 18 Pro Max** (needs the Apple Developer account).
