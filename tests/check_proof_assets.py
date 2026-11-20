"""Validate editable/proof asset contracts without opening Godot (Pillow required)."""
from math import cos, hypot, sin, tau
from pathlib import Path
from struct import iter_unpack
import wave
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/art'
W, H = 56, 44


def atlas(name, columns, count):
    with Image.open(ART / (name + '.png')) as sheet:
        assert sheet.mode == 'RGBA', name
        assert sheet.size == (columns * W, ((count + columns - 1) // columns) * H), name
        for i in range(count):
            x, y = (i % columns) * W, (i // columns) * H
            cel = sheet.crop((x, y, x + W, y + H))
            alpha = cel.getchannel('A')
            assert set(alpha.tobytes()) == {0, 255}, (name, i)
            bounds = alpha.getbbox()
            assert 0 < bounds[0] < bounds[2] < W and 0 < bounds[1] < bounds[3] < H, (name, i)
            yield cel


def unique(cels, start, count):
    return len({cel.tobytes() for cel in cels[start:start+count]}) == count


def check_sprites():
    for facing in ('side', 'front', 'back'):
        cels = list(atlas('survivor_' + facing, 8, 20))
        for start, count in ((0, 4), (4, 8), (12, 8)):
            assert unique(cels, start, count), (facing, start)
            sizes = [cel.getbbox() for cel in cels[start:start+count]]
            assert all(31 <= y2 - y1 <= 35 and 39 <= y2 <= 41 for _, y1, _, y2 in sizes), facing
    walker = list(atlas('walker', 8, 27))
    for start, count in ((0, 4), (4, 8), (12, 4), (16, 5), (21, 2), (23, 4)):
        assert unique(walker, start, count), start
    aim = list(atlas('survivor_aim', 17, 16*4*17))
    for direction in range(16):
        a = direction * tau / 16
        socket = (28 + round(sin(a)*19), 40 - 18 + round(cos(a)*19))
        for motion in range(17):
            poses = [aim[direction*68 + recoil*17 + motion] for recoil in range(4)]
            assert unique(poses, 0, 4), (direction, motion)
            for cel in poses:
                x, y = socket
                # The nominal sector socket touches authored pixels within two texels.
                assert any(cel.getpixel((x+dx,y+dy))[3] and hypot(dx, dy) <= 2.0
                           for dy in range(-2,3) for dx in range(-2,3)), (direction, motion, socket)


def check_audio():
    path = ROOT / 'assets/audio/proof'
    groups = [('rain', ['rain'], 2, 8), ('pistol', [f'pistol_{i}' for i in range(1,4)], 1, .32),
              ('impact', [f'impact_{i}' for i in range(1,4)], 1, .20),
              ('step', [f'step_{i}' for i in range(1,5)], 1, .19), ('rack', ['rack_1'], 1, .98)]
    for label, names, channels, seconds in groups:
        clips = []
        for name in names:
            with wave.open(str(path / (name + '.wav'))) as wav:
                assert wav.getnchannels() == channels and wav.getsampwidth() == 2, name
                assert wav.getframerate() == 32000 and wav.getnframes() == int(32000*seconds), name
                pcm = wav.readframes(wav.getnframes())
            samples = [s for (s,) in iter_unpack('<h', pcm)]
            assert 200 < max(map(abs, samples)) < 32767, name
            if label == 'rain':
                assert max(abs(samples[i] - samples[i-2]) for i in range(2)) < 3096, 'rain loop seam'
            clips.append(pcm)
        assert len(set(clips)) == len(clips), label


if __name__ == '__main__':
    check_sprites()
    check_audio()
    print('PASS: native-size transparent cels, animation uniqueness, muzzle registration and PCM cues')
