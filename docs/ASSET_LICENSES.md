# Asset source and license register

## Art foundation freeze additions

- `tools/side_review/source/freeze/{ready,windup,swing,follow,recover}.png`: five project-original AI-assisted bat keys derived from this project's approved survivor, locally keyed into editable RGBA PNGs. Repacked in `review_survivor.png` with the V1.1 contact key; no new public asset license is granted.
- `court_dry.png` received only additional local rain-streak retouch using the existing project-owned source. Runtime rain and recorded/Foley audio files, source attribution and bus routing are unchanged from V1.1.

## Art Direction V1.1: runtime art and recorded audio

`review_survivor.png`, `review_walker.png`: project-original AI-assisted keys, with local keying, palette reduction and foot-pin registration. Ten new transparent editable PNGs are in `tools/side_review/source/v11/`. No outside image references or public license grant. `court_dry.png`: masked streak retouch of `tools/side_review/source/court_plate.png` at the approved gameplay crop, with wet reflections retained. `lamp.png`/`review_case.png`: original Gate 2 local graphics. `side_review_rain.gd` and `side_effects.gd` weather/impact/casing visuals use local procedural drawing. This register does not license the project's original art, code or rain. No Sonniss clips or other redistributable-library restrictions were used.

### Recorded cue provenance

All the sources in the table were individually licensed on the linked original page or part of the linked creator's own verified library release. Exact license on each row: **Creative Commons CC0 1.0 Universal** ([full legal text](https://creativecommons.org/publicdomain/zero/1.0/)); no legally required attribution. Voluntary credits are below. No Freesound originals were downloaded directly in the sandbox: the source filenames shown distinguish original download names from the actual imported copies. We reused only those published source-identified CC0 files, not audio extracted from proprietary software, video or game media. Library Foley is described as Foley, not a field recording.

Repacker paths below are relative to these pinned checkouts (aliases are the expected folder names under the `pack_v11_audio.py` argument). Use the separately credited original library wherever available; mirrors do not supersede its license.

| Alias | Actual acquisition location (pinned) | Path prefix in checkout |
| --- | --- | --- |
| `Dead-Hours` | [Angelopgit/Dead-Hours @ ee0e219](https://github.com/Angelopgit/Dead-Hours/tree/ee0e2190eab2770e1d1daf36869ebb183702483b) | `client/src/audio/recorded/` (mirrored re-edits plus source/cut script) |
| `tides-of-rlyeh` | [defaultuser233/tides-of-rlyeh @ 4e5e6ad](https://github.com/defaultuser233/tides-of-rlyeh/tree/4e5e6ad382079d910deb0376f12e946fc33f9040) | `assets/sounds/` (published source-identified crops) |
| `anim-sounds` | [S3Electronics/anim-sounds @ b581477](https://github.com/S3Electronics/anim-sounds/tree/b581477212acbead61dbd1258675f1c389c27733) | `sfx/` (normalized MP3 copies) |
| `air` | [yoozap/airgangs @ eabb29f](https://github.com/yoozap/airgangs/tree/eabb29f822427a78cd49ccbf20e21b2504a61d32) | `public/audio/guns/` (Freesound casings cut to individual takes) |
| `ada` | [Adafruit/Adafruit-Sound-Samples @ 7675c60](https://github.com/adafruit/Adafruit-Sound-Samples/tree/7675c60a47c025ab62f77b699d6460d22bb963b1/sounds%20of%20adafruit) | `sounds of adafruit/` (creator's release) |

Every runtime file below is `assets/side_review/recorded/<name>.wav`. All files were converted to mono 32 kHz / signed PCM16, DC-centered, peak trimmed to the gain targets in `pack_v11_audio.py`, and given short edge ramps (warehouse instead uses a loop crossfade). Exact additional seek/max-length values are in the script. Individual outputs or same-source variants are identified below. Bus/positional gains and character playback-rate differences are in `side_review_audio.gd`; no new frequencies are synthesized.

| Runtime WAV(s) | Original URL · creator · original filename | Acquired filename and modifications |
| --- | --- | --- |
| `report_0`, `report_1`, `report_2`, `report_3` | [9mm Pistol Gunshots](https://freesound.org/people/DledeSOUND/sounds/731942/) · DledeSOUND · `731942__dledesound__9mm-pistol-gunshots.wav` | `Dead-Hours` `pistol-0.mp3`, `pistol-1.mp3`, `pistol-2.mp3`, `pistol-3.mp3` respectively. Upstream HQ preview isolated takes with short tail, EQ and soft drive; capped to 0.92 s. |
| `mag_release` | [The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library) · Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney · `Master Tracks/Walther PPQ/X_3.wav` | `Dead-Hours` `pmagout-0.mp3`; window around 0.824 s from the [raw library mirror @ beb2f40](https://github.com/buddingmonkey/FreeFirearmsSFXLibrary/tree/beb2f4041f3d6740fa0aeaf0e71159bd65a78c1b), mirror trimmed/shaped transient. |
| `mag_insert` | [The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library) · Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney · `Master Tracks/Walther PPQ/X_2.wav` | `Dead-Hours` `pmagin-0.mp3`; window around 0.762 s from same pinned raw library, mirror trimmed/shaped transient. |
| `slide` | [The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library) · Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney · `Master Tracks/Walther PPQ/X_17.wav` | `Dead-Hours` `pslide-0.mp3`; window around 1.17 s from same pinned raw library, mirror trimmed/shaped transient. |
| `casing_0`, `casing_1` | [Brass bullet shell casing drop onto concrete, multiple takes](https://freesound.org/people/GrayJoy/sounds/210102/) · GrayJoy · `210102__grayjoy__brass-bullet-shell-casing-drop-onto-concrete-multiple-takes.mp3` | `air` `casing_210102_1.wav`, `casing_210102_2.wav` respectively; two selected actual brass takes cut by mirror. |
| `concrete` | [Impact Sounds](https://kenney.nl/assets/impact-sounds) · Kenney · `impactPlate_light_000.ogg` | `tides-of-rlyeh` `impact_concrete.ogg`; byte-identical to the same-named library file from [soundcn @ 7cbfbb3](https://github.com/kapishdima/soundcn/blob/7cbfbb3f56e8548b81fb26410bdcea657447d087/assets/kenney_impact-sounds/impactPlate_light_000.ogg); Foley proxy. |
| `metal` | [S31-15 Shooting gallery; hitting metal targets](https://freesound.org/people/craigsmith/sounds/675951/) · craigsmith · `675951__craigsmith__s31-15-shooting-gallery-hitting-metal-targets.wav` | `tides-of-rlyeh` `hit_world.ogg`; upstream crop, cleaned and leveled from archival recording. |
| `infected` | [Three Flesh Impacts](https://freesound.org/people/jawbutch/sounds/344409/) · jawbutch · `344409__jawbutch__three-flesh-impacts.wav` | `tides-of-rlyeh` `hit_flesh.ogg`; mirror trimmed and normalized selected Foley. |
| `melee` | [Major punch](https://freesound.org/people/janbezouska/sounds/399183/) · janbezouska · `399183__janbezouska__major-punch.wav` | `Dead-Hours` `punch-0.mp3`; upstream processed layered Foley/crop. |
| `step_stone` | [Hiking Boot Footsteps on Stone](https://freesound.org/people/Fission9/sounds/521590/) · Fission9 · `521590__fission9__hiking-boot-footsteps-on-stone.wav` | `tides-of-rlyeh` `footstep.ogg`; upstream isolated step, lead-in reduced another 21 ms. |
| `step_case` | [Sounds of Adafruit](https://github.com/adafruit/Adafruit-Sound-Samples/blob/7675c60a47c025ab62f77b699d6460d22bb963b1/README.md) · Adafruit · `Warehouse/wire_deck_1.wav` | `ada` `Warehouse/wire_deck_1.wav`; capped at 0.5 s, metal contact proxy, not a boot recording. |
| `breath` | [Heavy Breathing](https://freesound.org/people/Under7dude/sounds/163383/) · Under7dude · `163383__under7dude__heavy-breathing.wav` | `anim-sounds` `breathing_2.mp3`; opening 1.6 s. |
| `hurt` | [Grunt1 - Death Pain](https://freesound.org/people/tonsil5/sounds/416839/) · tonsil5 · `416839__tonsil5__grunt1-death-pain.wav` | `tides-of-rlyeh` `enemy_death.ogg`; selected grunt, trimmed 0.015–0.395 s for brief player pain. |
| `walker_breath` | [Zombie breathing](https://freesound.org/people/Huminaatio/sounds/189281/) · Huminaatio · `189281__huminaatio__zombie-breathing.flac` | `anim-sounds` `zombie_breath.mp3`; opening 1.35 s. |
| `walker_warn`, `walker_death` | [Zombie Groan](https://freesound.org/people/ChuckChuckGoof/sounds/559558/) · ChuckChuckGoof · `559558__chuckchuckgoof__zombie-groan.mp3` | `anim-sounds` `zombie_groan.mp3`; respective segments 0–1.10 s and 0.95–2.35 s. |
| `walker_attack`, `walker_damage` | [Zombie Attack](https://freesound.org/people/soykevin/sounds/213509/) · soykevin · `213509__soykevin__zombie-attack.wav` | `anim-sounds` `zombie_attack.mp3`; respective segments 0–1.25 s and 0.70–1.16 s. |
| `runner_breath` | [breathing](https://freesound.org/people/dragdark/sounds/202271/) · dragdark · `202271__dragdark__breathing.mp3` | `anim-sounds` `breathing_3.mp3`; 1.05–2.10 s of real post-run breathing. |
| `runner_warn` | [Zombie](https://freesound.org/people/nanity05/sounds/193759/) · nanity05 · `193759__nanity05__zombie.wav` | `anim-sounds` `zombie_2.mp3`; 0.15–0.90 s cue. |
| `runner_attack` | [Zombie 2](https://freesound.org/people/Under7dude/sounds/163439/) · Under7dude · `163439__under7dude__zombie-2.wav` | `anim-sounds` `zombie_1.mp3`; 0.18–1.03 s cue. |
| `runner_damage` | [Burp Monster Zombie groan moan](https://freesound.org/people/EricsSoundschmiede/sounds/463721/) · EricsSoundschmiede · `463721__ericssoundschmiede__burp-monster-zombie-groan-moan.wav` | `anim-sounds` `zombie_3.mp3`; 0.05–0.49 s vocal Foley cut. |
| `runner_death` | [Deep Monster Growl](https://freesound.org/people/uagadugu/sounds/222523/) · uagadugu · `222523__uagadugu__deep-monster-growl.wav` | `anim-sounds` `monster_growl.mp3`; 3.15–4.30 s cut of creator's layered recorded vocals. |
| `warehouse` | [Sounds of Adafruit](https://github.com/adafruit/Adafruit-Sound-Samples/blob/7675c60a47c025ab62f77b699d6460d22bb963b1/README.md) · Adafruit · `autobagger.wav` | `ada` `autobagger.wav`; cropped from 0.25 s, crossfaded to a short machine loop. |

The one synthetic cue on the active side-view path is the permitted original rain loop `assets/audio/proof/rain.wav`. The earlier synthetic pistol/steps/impacts/vocal/rack are not called by the side-view rooms. Older fixtures retain their own sounds for regression tests; old Gate 2 audition remains in `docs/review/` only. Missing slot recordings and verification limits are listed in [the review checklist](SIDE_VIEW_GATES.md).

## Historical Side-view Gate 2 samples (superseded in F5)

| Files | Provenance and status |
| --- | --- |
| `assets/side_review/review_survivor.png`, `review_walker.png` | AI-assisted concept keys generated in Arena for this project, with no third-party reference packs. Inputs are retained under `tools/side_review/source/`; [`pack_art.py`](../tools/side_review/pack_art.py) masks, limits colors, crops and places cels on the gameplay pin. The Walker contact sheet output is an unrequested source variant; only the far-right figure was extracted for the neutral cel. Not hand-drawn finished animation. |
| `assets/side_review/court.png` | AI-assisted exterior art-direction plate, authored for this project and fitted to the true side-on floor by `pack_art.py`. Source `tools/side_review/source/court_plate.png`. |
| `assets/side_review/lamp.png`, `review_case.png` | Original local mask/diagnostic prop drawn by `pack_art.py`; not third-party assets or character art. |
| `assets/side_review/gate_{pistol,step,walker,impact}_*.wav` plus the audition in `docs/review/` | Original synthetic direction cues/mix by [`pack_audio.py`](../tools/side_review/pack_audio.py); no samples or recordings. Rain and reload reuse the earlier proof files noted below. |
| Native-size review PNG and pose GIF | Offline compositions of the above with bundled Vazirmatn, by [`make_review.py`](../tools/side_review/make_review.py); not runtime captures. |

Gate 2 used no paid art or audio service, external stock pack, or new third-party runtime asset. These samples are historical and are not offered under a public license. Retain the Vazirmatn notice with distributions. Before using assisted references as final production art, review the provenance and replace or manually redraw any asset whose consistency or rights suitability do not meet the project's needs.

## Art & audio proof 01

The proof art and sound below were made for **Last Haven**. They contain no third-party textures, samples, recordings, or paid services. There are no per-copy fees or third-party asset licenses to clear for the owner’s project distribution. **This register does not grant a public license** for project-original files; any standalone reuse or public licensing is the owner's decision. No CC license was applied.

| Runtime asset | Source / provenance | Status |
| --- | --- | --- |
| `assets/art/survivor_side.png`, `survivor_front.png`, `survivor_back.png`, `survivor_aim.png` | Original hand-painted pixel cels in [`sprites.py`](../tools/art_proof/sprites.py), packed/reflected offline | Proof-quality; working civilian survivor, pistol and sling |
| `assets/art/walker.png` | Original hand-painted pixel cels in [`sprites.py`](../tools/art_proof/sprites.py) | Proof-quality; one infected worker design. The existing runner uses a tint of this design. |
| `assets/art/depot.png`, `depot_lamps.png`, `cargo.png` | Original pixel-painting recipe and palette in [`yard.py`](../tools/art_proof/yard.py) | Proof-quality; fixed lane, warehouse, lamp wash/reflections and cargo case |
| Contact shadows, rain/ripples, muzzle flash, tracer and HUD panels | Original procedural drawing in [`scripts/presentation`](../scripts/presentation/) and [`weapon.gd`](../scripts/combat/weapon.gd) | Proof-quality effect/UI pass; no imported art |
| `assets/audio/proof/rain.wav` | Original synthesized, seamless eight-second stereo loop; [`audio.py`](../tools/art_proof/audio.py) | Proof mix; **not a field recording** |
| `assets/audio/proof/step_1.wav`–`step_4.wav` | Original synthesized wet-asphalt footsteps; [`audio.py`](../tools/art_proof/audio.py) | Proof mix; four base variations |
| `assets/audio/proof/pistol_1.wav`–`pistol_3.wav` | Original synthesized pistol transient and yard tail; [`audio.py`](../tools/art_proof/audio.py) | Proof mix; three base variations |
| `assets/audio/proof/impact_1.wav`–`impact_3.wav` | Original synthesized impact transients; [`audio.py`](../tools/art_proof/audio.py) | Proof mix; three base variations, with a heavier melee/body mix |
| `assets/audio/proof/rack_1.wav` | Original synthesized reload cue; [`audio.py`](../tools/art_proof/audio.py) | Proof mix |
| `assets/fonts/Vazirmatn-Regular.ttf` | Bundled unmodified; [upstream font](https://github.com/rastikerdar/vazirmatn/blob/6e553e33489a8f9dfaccc76860a2e3f3c1e66de7/fonts/ttf/Vazirmatn-Regular.ttf) | **SIL Open Font License 1.1**; upstream copyright and full text in [`assets/fonts/OFL.txt`](../assets/fonts/OFL.txt). Include with build distributions. |

## Retained Phase 1 / Phase 2 assets

- Phase 1's silhouette, crate and lane are original placeholder geometry; they are still visible in standalone `Main.tscn`, not in the Depot proof.
- `assets/audio/{growl,impact,rack,shot}.wav` are the Phase 2 project's original temporary synthesized PCM cues, not recordings or third-party samples. Kept for preservation, not played by the proof.
- The legacy proof’s animated **bat arc remains a gameplay placeholder**. There is no new bat sprite, bespoke runner art, reload-body animation, player damage/death cel sequence, or campaign art in this milestone. No proof asset is designated final production art.

Godot itself and its export templates are not vendored. If distributing an exported build, follow Godot’s license/attribution guidance for the engine as well as including the font notice above.
