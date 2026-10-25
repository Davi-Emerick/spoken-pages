# Spoken Pages

Spoken Pages reads Witcher 3 books, letters, and notes aloud while you play.

This repository is the source for people who want to build their own version: another voice, another set of pages, or new behavior. It is free to use if you intend to. The player download, with the finished recordings, is the mod on Nexus. The game's own book text is not in this repo.

## License

[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

You can use this, change it, and ship it inside your own mod. Credit the voice and this project. Do not sell it. If you publish your changes, keep the same license. The non-commercial term comes with the Spike voice.

## How it was made

The mod was written with AI assistance and tested in the game. The voice was generated. It is not a new performance by an actor.

1. REDkit's English string database and the item definitions supply the text of each readable book and note. Recipes are skipped. Anything with no English text is skipped.
2. Piper reads each page as separate sentences, with short gaps, at an audiobook pace of about 1.3x. Each page becomes one wav. The event name is `sp_` plus the first 8 hex characters of the MD5 of the item name.
3. A Python script writes one Wwise sound, one play event, and one bank per page, plus stop, pause, and resume events for that sound. One shared volume parameter is on every sound.
4. REDkit cooks those banks into one `soundspc.cache`. The game loads a bank by name from that cache. One bank per book plays. One giant bank did not.
5. A Witcher script hooks the book screen. Opening an unread book can start it. Switching books in that screen does not. Play starts the page on screen and stops the previous reading. The reading can keep going after the page closes, including through menus. The real pause menu pauses it.

## What you can build with this

You can record your own voice, add pages from another mod or expansion, and change the features in the script. None of that is automatic. There is no drop-in folder and no API another mod can call.

A new page has to be in `books.json`, recorded, given a Wwise bank, and listed in `modSpokenPagesBooks.ws`. The game matches the item's definition name, or its text key, in lowercase.

A new voice is a second set of events and banks, and a menu option that chooses them. This repo ships the Spike path only.

## Tools

| Tool | What it is for |
| --- | --- |
| [The Witcher 3](https://store.steampowered.com/app/292030) next-gen | The game the mod runs in. |
| [REDkit](https://store.steampowered.com/app/2684660) | Extract the English text, and cook the sound bank. |
| [Wwise 2023.1](https://www.audiokinetic.com/en/wwise/) | Build the per-book banks. You need your own license. |
| [Piper](https://github.com/rhasspy/piper) | The open voice engine. `piper-tts` and `numpy` in Python. |
| [xVASynth](https://store.steampowered.com/app/1765720/xVASynth_v2) | Optional. A different way to make a voice. Not used by the files in this repo. |

## Wwise 2023.1 and the license key

Wwise is Audiokinetic's sound tool. The 2023.1 line is the one this project was built with. Opening the project and cooking banks both need a Wwise license key.

The key is yours. It is not in this repository, and it must not be added to it. In Wwise, add it in the project settings. Do not send the project file to anyone after the key is in it.

REDkit's cook tool looks for that key in the official Witcher audio project, `assets/w3_audio/w3_audio.wproj`, even when you pass a different project with `-wwiseProj`. Put your own key there too. Do not upload that official project.

## REDkit

REDkit is CD PROJEKT RED's free editor for the game. Two jobs use it.

**Text.** `voices/extract_books.py` reads item definitions and the English string database under REDkit's `r4data` folder. Set `W3_REDKIT` to that `r4data` folder before you run it. It writes `voices/books.json` on your machine. That file is the game's text, so it is not stored here.

**Cooking.** From REDkit's `bin/x64_RedKit` folder, this is the cook that produced a cache the game would play:

```
wcc_lite.exe cooksounds -outdir=<a new empty folder> -wwiseProj=<path to spokenpages.wproj> -platform=pc -r4remastersounds -outsplitfile=<a new file>.split
```

`-outsplitfile` has to be a new file. REDkit also needs `r4data/soundbanks/soundsplitseed.csv` with a header line of `soundbank`. The result is `soundspc.cache` in the output folder. Copy that into `mods/modSpokenPages/content`. Paths with spaces need a junction, because the Wwise command line breaks on them.

## The voice

Spike is [Piper](https://github.com/rhasspy/piper)'s `en_GB-semaine-medium` model, speaker 1. The speaker is Spike, from the SEMAINE project. The license is [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

Place these two files in `voices/spike/`:

- `en_GB-semaine-medium.onnx`
- `en_GB-semaine-medium.onnx.json`

The reading pace in `voices/render_books.py` is the 1.3x audiobook setting: `length_scale` `1.22 / 1.3`, `noise_scale` `0.45`, `noise_w_scale` `0.65`, a short gap between sentences, and a longer one between paragraphs. The model file is not in this repo. Download it from the Piper voices. Do not sell anything you make with it.

## Making your own voice

1. Install Python, `piper-tts`, and `numpy`.
2. Put your Piper model in `voices/spike/`, or change `MODEL` and `SPEAKER` in `render_books.py`.
3. Produce `voices/books.json` with `extract_books.py`, or write your own list in the same shape: item name, text key, and text.
4. Run `render_books.py`. Wavs land in the Wwise project's `Originals/SFX/books`.
5. Run `build_wwise_books.py` only when you mean to rebuild the Wwise work units. That rewrites them from the wavs.
6. Open the project in Wwise 2023.1 with your own license, then cook with REDkit.
7. Put `soundspc.cache` in the mod, next to the scripts.

## Using xVASynth

[xVASynth](https://store.steampowered.com/app/1765720/xVASynth_v2), by Dan Ruta, is a separate app for generating lines from trained game-character models. Voice models are downloaded on their own, from the Nexus page for that game. The Witcher voices are [here](https://www.nexusmods.com/witcher3/mods/5676).

This repository does not include xVASynth, those models, or any audio made with them. You can still use it. Generate wavs for your pages, give them their own event names and banks, and add a menu option that selects them. Keep that work separate from Spike, and follow Dan Ruta's terms for the model you use.

## Adding pages from another mod or expansion

If the new item is a readable book or note and you can get its English text, add it to `books.json` and run the same render and cook. Hearts of Stone and Blood and Wine pages that already have English text are picked up by `extract_books.py` from REDkit. A mod that only adds the item in the game will not be read until you record it and cook it into this project.

## In the game

The script is `mod/modSpokenPages`. The options file is `mod/bin/config/r4game/user_config_matrix/pc/modSpokenPages.xml`.

On a book, Space or Y plays and pauses, Left Ctrl or LB stops, and X starts the page again. In the world, F6, F7, and F8 do the same. F6, F7, and F8 do not take jump, call horse, or walk.

Options are under Options, Gameplay, Mods, Spoken Pages. Read aloud when opened, play once per book, and stop when the book closes start on. Volume starts at 50. Play once follows the read mark the game already saves.

## Credits

- Spike, Piper `en_GB-semaine-medium`, speaker 1, SEMAINE project. [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). [Piper](https://github.com/rhasspy/piper).
- [Wwise](https://www.audiokinetic.com/en/wwise/) by Audiokinetic.
- [REDkit](https://store.steampowered.com/app/2684660) and The Witcher 3 by CD PROJEKT RED.
- [xVASynth](https://github.com/DanRuta/xVA-Synth) by Dan Ruta, if you choose to use it.
