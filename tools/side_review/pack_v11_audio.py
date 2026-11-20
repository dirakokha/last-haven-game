"""Pack verified CC0 clips from pinned local checkouts. Requires numpy and imageio-ffmpeg."""
import subprocess
import sys
import wave
from pathlib import Path

import imageio_ffmpeg
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 32000
# output: (relative input, leading cut seconds, max length, target peak)
DEAD = 'Dead-Hours/client/src/audio/recorded/'
TIDES = 'tides-of-rlyeh/assets/sounds/'
ANIM = 'anim-sounds/sfx/'
ADA = 'ada/sounds of adafruit/'
AIR = 'air/public/audio/guns/'
CLIPS = {
    **{f'report_{i}': (DEAD + f'pistol-{i}.mp3', 0, .92, .87) for i in range(4)},
    'mag_release': (DEAD+'pmagout-0.mp3', 0, .35, .72),
    'mag_insert': (DEAD+'pmagin-0.mp3', 0, .42, .72),
    'slide': (DEAD+'pslide-0.mp3', 0, .33, .72),
    'casing_0': (AIR+'casing_210102_1.wav', 0, .38, .64),
    'casing_1': (AIR+'casing_210102_2.wav', 0, .38, .64),
    'concrete': (TIDES+'impact_concrete.ogg', 0, .42, .72),
    'metal': (TIDES+'hit_world.ogg', 0, .43, .74),
    'infected': (TIDES+'hit_flesh.ogg', 0, .39, .74),
    'melee': (DEAD+'punch-0.mp3', 0, .60, .75),
    'step_stone': (TIDES+'footstep.ogg', .021, .25, .76),
    'step_case': (ADA+'Warehouse/wire_deck_1.wav', 0, .5, .72),
    'breath': (ANIM+'breathing_2.mp3', 0, 1.6, .65),
    'hurt': (TIDES+'enemy_death.ogg', .015, .38, .72),
    'walker_breath': (ANIM+'zombie_breath.mp3', 0, 1.35, .68),
    'walker_warn': (ANIM+'zombie_groan.mp3', 0, 1.1, .72),
    'walker_attack': (ANIM+'zombie_attack.mp3', 0, 1.25, .75),
    'walker_damage': (ANIM+'zombie_attack.mp3', .70, .46, .71),
    'walker_death': (ANIM+'zombie_groan.mp3', .95, 1.4, .73),
    'runner_warn': (ANIM+'zombie_2.mp3', .15, .75, .73),
    'runner_attack': (ANIM+'zombie_1.mp3', .18, .85, .75),
    'runner_breath': (ANIM+'breathing_3.mp3', 1.05, 1.05, .69),
    'runner_damage': (ANIM+'zombie_3.mp3', .05, .44, .67),
    'runner_death': (ANIM+'monster_growl.mp3', 3.15, 1.15, .69),
    'warehouse': (ADA+'autobagger.wav', .25, 3.5, .63),
}


def pack(source):
    out = ROOT / 'assets/side_review/recorded'
    out.mkdir(exist_ok=True, parents=True)
    for name, (relative, seek, length, peak) in CLIPS.items():
        raw = subprocess.check_output([imageio_ffmpeg.get_ffmpeg_exe(), '-loglevel', 'error',
                                       '-i', str(source / relative), '-ss', str(seek), '-t', str(length),
                                       '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
        x = np.frombuffer(raw, dtype='<f4').astype(float)
        if len(x) < 320 or np.max(np.abs(x)) < .0005:
            raise ValueError(f'Empty source for {name}')
        x -= x.mean()
        if name == 'warehouse':
            # Fade the last segment into the first, leaving a continuous PCM loop.
            n = min(RATE // 3, len(x) // 4)
            ramp = np.linspace(0, 1, n)
            x[-n:] = (1-ramp)*x[-n:] + ramp*x[:n]
            x = x[n:]
        else:
            end = min(len(x)//5, RATE//25)
            x[:96] *= np.linspace(0, 1, 96)
            x[-end:] *= np.linspace(1, 0, end)
        x *= peak / np.max(np.abs(x))
        with wave.open(str(out / f'{name}.wav'), 'wb') as f:
            f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            f.writeframes(np.round(x*32767).astype('<i2').tobytes())
        density = np.sqrt(np.mean(x*x))
        print(f'{name:16s} {len(x)/RATE:5.2f}s rms {density:.3f}')


if __name__ == '__main__':
    pack(Path(sys.argv[1]))
