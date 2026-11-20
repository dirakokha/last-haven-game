# Asset source and license register

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
- The animated **bat arc remains a gameplay placeholder**. There is no new bat sprite, bespoke runner art, reload-body animation, player damage/death cel sequence, or campaign art in this milestone. No proof asset is designated final production art.

Godot itself and its export templates are not vendored. If distributing an exported build, follow Godot’s license/attribution guidance for the engine as well as including the font notice above.
