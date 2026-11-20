# Art & audio proof 01 — North Quay / Yard 04

A limited, playable presentation pass on the existing Depot combat yard. The civilian survivor wears a coral rain shell and teal shoulder sling; the Walker wears a dented hard hat and torn high-visibility workwear. The single yard is still the Phase 2 encounter, including its faster Walker variant. See the [asset register](ASSET_LICENSES.md) for sources, redistribution notes, and remaining placeholders.

## Run locally on Windows x64

1. Use **Godot 4.7.2 Stable Standard (Windows x86_64)**, not .NET. Extract or clone the project. Import `project.godot`, wait for the PNG/WAV imports, and press **F5**. No other engine, plugin, Python install, or external asset download is needed to play.
2. **WASD** move, **Shift** run, mouse position aims, **LMB** fires, **R** reloads, **F** bats, **Esc** pauses, and **Enter** restarts after the result. **RMB** shows the steady aiming pose; it does not change accuracy, inhibit movement, or gate firing. **F2** disables moving rain/ripples; **F3** disables the baked amber lamp pools. The rain audio and underlying asphalt/puddles stay in both modes. The controls and statuses are displayed in the HUD.
3. Optional export: install the same-version Standard export templates, create `build/`, and use the existing **Windows x64** preset. Keep the EXE and PCK together and include `assets/fonts/OFL.txt`; test a copy offline without the editor.

## Owner's acceptance checklist

- [ ] At **960×540** content size, start a fresh encounter and look at the survivor and Walker without zooming. Their heads, weapon/arms, clothing and feet should separate from warehouse and road tones. Confirm the coat, hair, sling and hard hat are visible in motion; check both east and west portions of the yard.
- [ ] Compare a **1920×1080** content area (e.g., use `--fullscreen` on a 1080p display, or `--resolution 1920x1080` on a larger display). Check that character and road pixels become exact 2× blocks, with no blur. Intermediate window sizes letterbox rather than applying a fractional factor. Keep Windows DPI/monitor scaling in mind when measuring physical pixels.
- [ ] Walk/run horizontally, vertically and diagonally; stop and reverse. Look for distinct swing/plant cels, stable foot baseline and no visual hopping on direction changes. Try walking against a case and a curb: footsteps should stop when movement stops, and collision pins should not shift. Confirm the camera still scrolls to the original bounds.
- [ ] Hold **RMB** and aim around a full circle while standing and moving. Fire in cardinal and diagonal directions; the flash should register on the pistol and the tracer should originate there on the firing frame. Quickly flick the mouse after firing; recoil should retain the shot pose. Art uses 16 hand-painted/reflected sectors; **the click, flash and ray use continuous aim**, not angles snapped to the atlas.
- [ ] Fire past both sides of a crate and through its silhouette from a different depth. Only the original footprint should block the ray. Walk above and below the same crate and pass a Walker on both sides of its Y pin; verify depth ordering. See also the [Phase 2 checklist](PHASE2_CHECKLIST.md).
- [ ] Observe the Walker’s uneven gait, attack anticipation, lunge, stagger and collapse. Try the faster variant. Both still do original contact damage; a corpse should not block movement or fire. Win, lose, and use **Enter** to restart; pause/resume with **Esc** mid-encounter.
- [ ] Consume a round, reload, and verify the HUD magazine, reserve, reload progress, health and enemy count. Try an empty magazine and the legacy bat. Check that the HUD does not obscure the usable lane.
- [ ] Listen to the rain beyond the eight-second loop boundary, walking/running, a pistol volley, an audible hit, and a reload. Confirm there is no obvious loop click, clipping or immediate identical variation; test on headphones and speakers. These are synthetic cues, not recordings.
- [ ] Toggle **F2/F3** independently. Ensure the weather complements rather than hides the warning/actor art. In the Windows profiler, compare the default and reduced modes during combat and record frame time/PC specs; do not infer hardware performance from headless checks.
- [ ] Open standalone `scenes/main/Main.tscn` and `scenes/test/PersianRTL.tscn` with **F6** and run the original [Phase 1 checks](PHASE1_CHECKLIST.md). The proof HUD is English; the original Persian/RTL test and font are retained.

## Integration notes

- Actor art is attached to the original feet nodes. Both atlases use **56×44** transparent cels and common pixel origin **(28, 40)**. Typical standing art is about 32–34 screen pixels high; the remaining cell space is for the pistol and extremities. Walker corpses have no body or collision and are spawned at the same Y-sort pin; only their presentation continues if the last kill freezes the yard.
- The survivor locomotion sheets pack 4 idle / 8 walk / 8 run cels per facing. The aiming sheet packs 16 sectors with neutral aim and 3 recoil cels per stance; rows contain standing and locomotion variants. The Walker sheet is 4 idle, 8 walk, 4 warning, 5 attack, 2 damage and 4 collapse cels. Gait is driven by traveled distance, Walker state timing uses the live encounter timers, and footstep timing comes from gait contact phases.
- Backdrop/shiny pavement and optional glow are baked sprites. Rain is capped at 148 short pixel streaks and 22 splash anchors, with only locally visible, active splashes drawn. There are no physics particles, full-scene shaders, or dynamic light shadow passes. Sound uses one loop and eight reusable positional voices.
- Movement scripts, camera limits, arena bounds, crate footprints, spawn locations, damage/health, enemy state transitions, firing and reload conditions, ammunition, and both ground-space ray casts are unchanged. The original lifted visual muzzle remains `LIFT + aim * 19` with `LIFT = (0,-18)`. The tracer uses the shot direction rather than the later pointer position during its short flash. The art-facing angle can differ by at most 11.25° from the shot; this does not affect hits.
- Removing the old depot stubs, hiding the inherited placeholder meshes in Depot, dispatching read-only state to the presentation, and retaining a noncolliding death cel are the intentional integration changes. Project display settings present a nearest-filtered 960×540 pixel buffer at integer multiples; shot/foot calculations remain in the existing coordinates.

## Rebuild and test

The committed assets are ready to import. To regenerate from editable source, run these from the project root with Python 3.11+ and Pillow (`python -m pip install Pillow`; the audio generator only needs the standard library):

```text
python tools/art_proof/sprites.py
python tools/art_proof/yard.py
python tools/art_proof/audio.py
python tests/check_proof_assets.py
```

With a Godot 4.7.2 Standard binary on your path (on Windows, use its console executable when viewing logs):

```text
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/depot_smoke.gd
```

The smoke test checks 1×/2× viewport transforms and drives movement, pause, effects, cover/ground rays, ammo/reload, live enemy warning/contact, and death/victory. It is not a substitute for the visual, input-device and sound checks. For a graphical pixel-buffer capture, rerun the smoke test **without** `--headless` and add `-- --capture` (or `--resolution 1920x1080 -- --capture`); it writes `user://depot_960_buffer.png` and prints the window size. Also check the actual window visually, since the capture is **before** upscaling.

**Sandbox results:** Asset checks passed, and regeneration reproduced all 20 PNG/WAV outputs byte-for-byte. The Depot smoke passed with a Linux headless runner compiled from the Godot `4.7.2-stable` source tag, using temporary native resource equivalents because the editor import binary was unavailable. That run verified the actual Depot scene's 1×/2× transforms, not its rendered pixels. A separate artwork/layout review at 960×540 and nearest-neighbor 1920×1080 informed the character size.

**Still to verify locally:** Graphical Godot capture, Windows editor/import and export, on-device audio/performance, and owner visual acceptance.
