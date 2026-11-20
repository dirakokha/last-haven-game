# آخرین پناهگاه · Art Direction V1.1

**Status:** Owner tested Gate 2 on Windows and approved the visual foundation. V1.1 is a focused playable review in [the existing PR #3](https://github.com/dirakokha/last-haven-game/pull/3), not a final-animation sign-off or permission to start the campaign. The earlier Gate 2 PNG, GIF and synthetic audio in `docs/review/` are historical comparisons, not what F5 plays today.

## Owner decisions that govern this pass

- Keep the civilian's copper coat and turquoise satchel, Walker's industrial-worker silhouette, strictly side-on gameplay, 960×540 logical frame, fixed camera height/zoom, Court and Warehouse navigation fixture. No new levels, full menu overhaul, W/S depth movement, inventory system, hunger or thirst.
- **A/D are the only facing inputs.** Idle remembers the last side. LMB fires straight horizontally from the displayed muzzle even in the air; no cursor aim, crosshair, diagonal trajectory or vertical aiming. Keep finite swept contact and obstruction tests, the 12-round magazine and 36 starting reserve, reload, and direct F melee. There is no legacy weapon-select mode in this side slice to preserve.
- Show flash, smoke, recoil, brass and a short trail only on a real shot. Supply metal sparks and concrete dust only at actual contacts; use small blood flecks only for a projectile hit on infected, with a separate melee contact cue. No blood effects on masonry, metal or a miss. Keep visual presentation separate from damage.
- F2 controls the precipitation layer and the existing rain loop together, immediately. Keep wet ground, puddles and amber reflection even when rain is off. Remember the choice across both rooms and launches. No second rain bed or indoor precipitation.
- Default to traceable recorded/library sounds and a restrained mix of Weapons, Player, Zombies, Environment and Interface. Do not add synth placeholders for missing recordings; the inherited rain is the explicit exception. Use only assets with verified licenses; no restricted libraries, anonymous downloads, copyrighted extraction or paid tools. See [asset register](ASSET_LICENSES.md).
- Use distinct registered sprite drawings, not rotated parts, in-between copies or inflated frame counts. Preserve pins, consistent proportions and gameplay readability above frame targets. HUD is Persian, Vazirmatn with Godot's font fallback, RTL with isolated Latin key labels; use real health, injury, equipped pistol/bat, magazine/reserve and interaction conditions, not fictional survival meters.

## Run the playable review

Import `project.godot` in **Godot 4.7.2 Stable Standard**, wait for imports and press **F5**. Use the standalone play window for function keys if the editor intercepts them. Older `Main.tscn`, `PersianRTL.tscn` and `Depot.tscn` are F6-only compatibility fixtures. No settings or routes from those fixtures reach the side-view slice.

| Control | What to try |
| --- | --- |
| A/D, Space, Shift, Ctrl | Walk either way, jump once until landing, run, dodge without invulnerability. The low case blocks movement but is **below** the level pistol muzzle; the previous angled shot could be steered into it. |
| LMB | Move the cursor up, down and behind the actor. Shoot both directions while still and while jumping: muzzle, flash and trajectory should line up on both sides. A click does not turn the actor. Concrete wall contacts and infected strikes should differ and nothing appears at the cursor. |
| R, F | Reload a partly filled and empty magazine; only empty reload gets a slide cue, reserve should decrement by rounds loaded. Bat melee should react only when the swept strike reaches a Walker. |
| W | At the lit door, use the Persian prompt to enter, then W to return. Verify health, ammo and Walker damage transfer. Other positions should not admit W; S has no depth action. |
| F2, F3, F11 | Toggle rain, shadow pass and fullscreen. Turn rain off, cross the door and return, then restart: the precipitation stays off, the reflections remain. Toggle back on and repeat with speakers/headphones. F3 toggles the lamp's shadow pass, not the baked amber light. |
| Esc, Enter | Pause/resume; Enter restarts from defeat without resetting saved rain. |

## What is in V1.1 and what remains

The court plate is the same image/crop, locally retouched where prominent falling streaks were painted in. F2 controls only the new composited state; it does not swap backgrounds. Weather-off may still show narrow vertical texture highlights. Inspect the dry plate at gameplay size for any ambiguous residual strokes. There is no separate splash layer in this pass. The low case retains its exact bounds; a temporary high metal collider in the smoke test checks metal occlusion and effects without changing approved level geometry.

There are **nine distinct survivor cels and six distinct Walker cels** in the runtime atlases, not full cycles. The ten new editable keyed RGBA sources are in `tools/side_review/source/v11/`; `pack_v11_art.py` places them on authored foot pins. The shot has a two-pixel visual kick after the flash; that transform does not count as an authored pose. The generation limit was reached in this pass, and these are the frame-count and quality gaps:

| Set | Review implementation (shared keys listed explicitly) | Target, not yet met |
| --- | --- | --- |
| Survivor idle / walk / run | Guard, two walk gait keys, one additional run key. Run shares walk contact. Walk/run share the contact clock that emits a sample at contact and actual landing, rather than a timer independent of the animation. | Idle 4–6; walk/run 10–12 each, with alternating-foot contacts. |
| Survivor jump / shoot | Distinct air key and low key shared by takeoff and landing; registered guard/air during flash, then short recoil. | Separate takeoff and landing, shoot 4–6. |
| Survivor reload / melee / dodge | One distinct key each, dispatch driven by real action state. | Reload/melee 8–12 each, dodge 6–8. |
| Survivor damage / death | Low-key reaction and subdued tint; defeat holds the low key. No dedicated hero damage or fall animation. | Damage 4, death 8–12. |
| Walker idle / walk / warning / attack | Guard, one stride key (shares guard), one warning and one separate lunge. | Idle/warning 4–6 each, walk 10–12, attack 6–8. |
| Walker damage / death | One recoil and one grounded death cel. Death passes through recoil and leaves a nonblocking corpse until room change. | Damage 4, death 8–12. |

The report has four takes; reload has release/insert/empty-slide; actual brass contact on a solid surface plays a casing take. Stone boots and a metal-cargo contact proxy follow the footfall signal; indoor walking still uses stone because both actual floors are concrete. There is recorded exertion, a short pain cut, source-based zombie vocals and quiet machinery indoors. The Runner profile uses distinct source recordings (not pitch shifts of the Walker) and a different playback pace; there is still no Runner encounter in the active rooms for an in-game A/B. The concrete hit is library Foley, not a field-recorded projectile hitting concrete. A wet-specific boot set, weapon dry/failure cue, melee whiff, interface sounds and real warehouse room-tone recording remain gaps. No synthetic workaround fills them; the warehouse currently uses a short loop of licensed machinery.

## Validation boundaries

- **Executable:** source-built Linux Godot 4.7.2 headless, with temporary runtime-import equivalents. `tests/side_gate_smoke.gd` exercises real input events for LMB with opposing cursor positions, A/D facing retention, overlap/finite sweep and material contact coordinates, blood at infected contact only, jump/case/case landing surface, two reload paths, Walker warning/melee/death, camera transform, Persian prompt visibility, bus presence, F2 paired node state, disk-backed room transfer and defeat restart. This is not a Windows or physical-audio test.
- **Static/offline:** sprite cells examined at native pixel scale and registered on actor pins; source/runtime checks cover one-bit alpha, distinct cels, horizontal barrel alignment on firing keys, plate geometry and local-only changes, audio PCM headroom and source manifest. No runtime timing or perceived quality inferred from offline images/WAVs.
- **Owner/desktop pass still required:** V1.1 Windows F5/export, visible alignment while moving, flash/impact readability, dry plate and amber reflection at F2 off/on, audibility vs. rain/machinery, subjective gait smoothness and footstep sync, Runner-vs-Walker voice quality later, Persian glyph joins and mixed-label ordering, and rendered 1×/2× performance and fullscreen. The custom fallback text server cannot shape Persian correctly.

Reproduce on an official binary:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/side_gate_smoke.gd
python tests/check_proof_assets.py
python tests/check_v11_assets.py
```

Repack current images with `python tools/side_review/pack_v11_art.py` (Pillow); audio with `python tools/side_review/pack_v11_audio.py /path/to/pinned/sources` (NumPy and imageio-ffmpeg, directory aliases/versions in the license register). The old `pack_art.py`, `pack_audio.py`, `make_review.py` write historical samples only to `build/gate2-reference/`.
