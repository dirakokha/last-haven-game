"""Offline V1.1 assets check; not a graphical/audio playback test. Requires Pillow."""
from array import array
from pathlib import Path
import re
import sys
import wave

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/side_review'
CELL = (144, 128)
PIN = (68, 114)


def atlas(name, count):
    sheet = Image.open(ASSETS / f'review_{name}.png')
    assert sheet.mode == 'RGBA' and sheet.size == (CELL[0]*count, CELL[1])
    cels = [sheet.crop((i*CELL[0], 0, (i+1)*CELL[0], CELL[1])) for i in range(count)]
    assert len({cel.tobytes() for cel in cels}) == count
    for cel in cels:
        a = cel.getchannel('A')
        l, t, r, b = a.getbbox()
        assert set(a.get_flattened_data()) == {0, 255}
        assert 0 < l < PIN[0] < r < CELL[0] and 0 < t < 100 and abs(b - PIN[1]) <= 2
    return cels


def main():
    hero, walker = atlas('survivor', 9), atlas('walker', 6)
    # Verify the visible barrel terminates one pixel before the muzzle. Godot's
    # flip uses column 143-x and offset -75, mirroring about the identical pin.
    muzzle_x, muzzle_y = PIN[0]+42, PIN[1]-78
    for i in (0, 1, 2, 4, 6):
        assert hero[i].getpixel((muzzle_x-1, muzzle_y))[3] == 255
        assert hero[i].getpixel((muzzle_x, muzzle_y))[3] == 0
    assert hero[0].getchannel('A').getbbox()[1] == 14
    assert 102 <= walker[0].getchannel('A').getbbox()[3]-walker[0].getchannel('A').getbbox()[1] <= 105

    old = Image.open(ROOT/'tools/side_review/source/court_plate.png').convert('RGB')
    old = old.resize((1100, 614), Image.Resampling.NEAREST).crop((0, 7, 1100, 547))
    dry = Image.open(ASSETS/'court_dry.png').convert('RGB')
    assert dry.size == old.size == (1100, 540)
    matches = sum(a == b for a, b in zip(old.get_flattened_data(), dry.get_flattened_data()))
    assert .94 < matches / (1100*540) < .998
    # The signature reflection under the amber door was not repainted.
    assert old.crop((680, 452, 752, 486)).tobytes() == dry.crop((680, 452, 752, 486)).tobytes()

    docs = (ROOT/'docs/ASSET_LICENSES.md').read_text()
    source = (ROOT/'scripts/side/side_review_audio.gd').read_text()
    entries = sorted((ASSETS/'recorded').glob('*.wav'))
    assert len(entries) == 28
    mapped = set(re.findall(r'preload\("res://assets/side_review/recorded/([^"]+)"\)', source))
    assert mapped == {f.name for f in entries}
    assert 'gate_' not in source and 'rack_1.wav' not in source
    for path in entries:
        assert f'`{path.stem}`' in docs
        with wave.open(str(path), 'rb') as pcm:
            assert (pcm.getnchannels(), pcm.getsampwidth(), pcm.getframerate()) == (1, 2, 32000)
            samples = array('h', pcm.readframes(pcm.getnframes()))
            if sys.byteorder != 'little':
                samples.byteswap()
            assert .10 < len(samples) / 32000 <= 1.75
            assert 1000 < max(map(abs, samples)) < 29500
    print('PASS: V1.1 PNG registration, plate crop/reflections, PCM headroom and source coverage')


if __name__ == '__main__':
    main()
