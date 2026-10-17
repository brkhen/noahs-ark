# Noah's Ark: vision

**What it is:** an interactive story game about Noah's Ark, for the iPhone App Store (a tablet version comes later).

**Who it's for:** young kids and older adults, alone or playing together. The goal is gentle fun while learning the story, and exercise for memory and attention.

## What matters most

1. **Easy to get around on a phone.** Big buttons, a Back button always in the same place, no tiny targets, no rush.
2. **Easy to read and hear.** Large text by default, and everything can be read aloud.
3. **Original art.** Every picture is made for this game, never copied from someone else's photo or image. The look is rich, detailed alpine scenery (see the Illustration Art Direction Brief in [prototype/](prototype/README.md)).

## The games (from the Story Games prototype)

| Game | How it plays |
|---|---|
| **Word Search** | Find words from the story in a letter grid. Tap the first and last letter, or drag across the word. |
| **Memory Match** | Flip cards to find pairs of animals (dove, lion, giraffe, elephant, zebra, monkey). |
| **Story Sequence** | Tap the events of the story in the order they happened. |

Also in the prototype, to bring over later: **"Who's playing today?"** (Little one, Grown-up, Together), which sets text size, read-aloud, voice speed, and timers; a text-size button; Noah congratulating the player; and saved progress.

Separate prototypes exist for an older **Memory Match** and **Seek & Find**.

## Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Built with **Godot 4.7.2**, exported to **Xcode** for iOS, same as Backyard Dominoes. | Brian asked for this on 2026-10-17. |
| 2 | **Portrait only**, because the prototype is designed upright. | Bezalel's default. Brian to confirm. |
| 3 | Bundle ID **com.brianhennington.noahsark**. | Bezalel's default, following Backyard Dominoes. Must be final before the first App Store upload. |
| 4 | No timers by default (every profile in the prototype is untimed). | From the prototype. |
