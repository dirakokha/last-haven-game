"""Original pixel cels. Each letter is one opaque pixel, '.' is transparent.
Rows are painted at their given coordinates relative to the shared ground pin.
Mirroring and stamping are offline only; the game plays complete PNG cels.
"""
from PIL import Image
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / 'assets/art'
W, H, OX, OY = 56, 44, 28, 40
INK = dict(zip('kdbstgphwomlnaecirf', (
    '#101b23', '#24343b', '#344d56', '#48646a', '#714638', '#9f5340',
    '#c67550', '#edab71', '#f7d6a3', '#7e7765', '#478b86', '#76c1ac',
    '#a4b4ab', '#685628', '#b69746', '#e6c965', '#434236', '#633e3c', '#ac6961',
)))


def stamp(img, x, y, rows):
    for j, row in enumerate(rows.split('/') if isinstance(rows, str) else rows):
        for i, c in enumerate(row):
            if c != '.':
                img.putpixel((OX+x+i, OY+y+j), (*bytes.fromhex(INK[c][1:]), 255))


def blank():
    return Image.new('RGBA', (W, H))


# Jacket and face cels: cropped storm hood, dark hair, coral shell, teal sling.
SURVIVOR = (
    '..kkkkk/ .kddbbsk/ kdbbbssk/ kdbkkkhk/ kdkkphhk/ .kkdphhk/ .kbhppk/'
    '.ktgppk/ .kthhhk/ .ktpgpk/ kggppgkk/ kghhpgdmk/ kghhppgkk/ kphppggdmk/ kghpggdmmsk/ ktgpggmshhk/ ktgppmsphgk/'
    'ktggmsgphgk/ kggmsggptgk/ kggssggtgdk/ kggsgggtgbk/ .ktggttdkk/ .kdddddk'
).replace(' ', '')
# Sleepy eyelids, inhale, settled shoulder, exhale; all edits are pixel stamps.
BREATH = ['.../..h/...', '.../.hh/...', '.../.pp/...', '.../..w/...']
# Grounded boots are the final row. During each passing phase the swing boot lifts.
WALK = [
    (-9, '....kkdddk/....kdbbbkk/...kbbdbbbkk/...kbskkbbbk/..kbsk..kbbk/..kbbk...kbsk/.kbbk.....kbsk/kddk.......kddkk/kkkk.......kkkkkk'),
    (-8, '...kkdddk/...kdbbbkk/...kbbbbbk/..kbbdsbk/..kbskkbbk/..kbsk.kbbk/.kbbk...kbsk/.kddkk...kddkk/.kkkkk...kkkkk'),
    (-7, '..kkdddk/..kdbbbkk/..kbbbbbk/..kbbsbbk/..kbbskbk/...kbskkbk/...kbsbkkk/...kdddk/...kkkkkk'),
    (-7, '..kkdddk/..kdbbbkk/..kbbbbbk/...kbsbbk/...kbsbbk/..kbdkbsk/..kddkbsk/..kk..kddkk/......kkkkk'),
    (-8, '...kkdddk/...kdbbbkk/..kbbbbbbkk/..kbbkkbsbk/.kbbk..kbsbk/.kbbk...kbsbk/kbbk.....kbsbk/kddkk.....kbdkk/kkkkk.....kkkkkk'),
    (-8, '...kkdddk/...kdbbbkk/...kbbbbbk/..kbbsdbbk/..kbbkkbsk/.kbbk..kbsk/.kbbk...kbsk/.kddkk...kddkk/.kkkkk...kkkkk'),
    (-7, '..kkdddk/..kdbbbkk/..kbbbbbk/...kbbsbbk/...kbbsbbk/...kbskbbk/..kbsbkkdk/..kdddk/..kkkkkk'),
    (-7, '..kkdddk/..kdbbbkk/..kbbbbbk/..kbbsbk/..kbbsbk/..kbskbbk/..kbskddk/..kddkkk/..kkkkk'),
]
RUN = [
    (-12, '......kkdbbk/.....kdbbssbk/....kbbbkksbbk/...kbbkk..ksbbk/..kbbk.....ksbbk/.kbbk.......ksbbk/kbbk.........kbddkk/kddk..........kkkkkk/kkk'),
    (-11, '.....kkdbbk/....kdbbssbk/...kbbbkbsbbk/..kbbkk.kbsbbk/.kbbk....kbsbbk/.kddk.....kbsbbk/..kk.......kbsbk/............kddkk/............kkkkk'),
    (-9, '....kkdbbk/...kdbbssbk/...kbbbbsbk/...kbbbsbk/..kdbkbsbk/..kk.kbsbk/.....kbbk/.....kddk/.....kkkkk'),
    (-9, '....kkdbbk/....kdbbssbk/...kbbbssbbk/..kbsbkksbbk/.kbsbk..kddk/.kbbk....kk/..kbk/..kddk/..kkkkk'),
    (-11, '.....kkdbbk/....kdbbssbk/...ksbbkbsbbk/..ksbbk..kbbbk/.ksbbk.....kbbk/kbsbk.......kbbk/kddk.........kbbk/kkkk..........kddk/...............kkk'),
    (-11, '.....kkdbbk/....kdbbssbk/...ksbbkbsbbk/..ksbbk.kbbbk/.ksbbk...kbbbk/.ksbk......kbbk/.kddk.......kddk/.kkkkk.......kk/.kkkk'),
    (-9, '....kkdbbk/....kdbbssbk/...ksbbbsbbk/...ksbbbsbk/...ksbbkbbk/....kbbkkdk/....kbbk.kk/....kddkk/....kkkkk'),
    (-9, '....kkdbbk/....kdbbssbk/....ksbbbsbbk/...ksbbkksbbk/..ksbk..ksbbk/..kddk...kbbk/...kk....kbk/.........kddk/.........kkkkk'),
]
STAND = (-7, '..kkdddk/..kdbbbkk/..kbbbbbk/..kbbdsbk/..kbskbbk/..kbskbbk/..kbskbbk/.kddkkkddkk/.kkkk.kkkkk')
# Each entry paints a separate arm / pistol silhouette. Angles run screen-up to
# screen-down in 22.5 degree steps; the other half is reflected in the atlas builder.
AIM = [
    (0,-37,'ksk/kbk/kbk/kbk/kdk/kdhk/khhk/kpgk/kpgk/kggk/kggk/kgpk/kgpk/ktpk/kggk/kggk/kgpk/kkkk'),
    (2,-37,'.....ksk/.....ksbk/.....kdbk/....kdbk/....kdhk/...khhk/...kphk/...kpgk/..kpgk/..kggk/.kggk/.kgpk/kggpk/kggk/kggk/kkkk'),
    (2,-32,'...........kss/..........ksbk/.........ksbk/........kddk/.......kdhk/......khhk/.....kphkk/....kppgk/...kppgk/..kppgk/.kggpk/kggpk/kkkk'),
    (3,-27,'.............kss/...........kssbk/.........kbbddk/........kdhhkk/.....kkgkhhkk/...kkgpphhk/.kkggppgkk/kgggppkk/kgggkk/kkkk'),
    (3,-22,'........kk/..kkkkkgppkkkkkkk/kgggpppphhhssbbsk/kgggpgpphhdbddddk/kkkkkkkkkkdk/.........kk'),
    (3,-20,'kkkkkk/kgggppkkkkk/kgggppgpphhkkk/kkkkgppgphhssbkk/....kkkkkkdbssbkk/.........kkddbsbk/...........kkkddbk/.............kddbk/..............kkbk/...............kk'),
    (3,-20,'kkkkk/kggppk/kggppgk/.kkgppgk/...kgpghk/....kgphhk/.....kkhdbk/......kdbsk/.......kdbsk/........kdbsk/........kdbsk/.........kdbsk/.........kdbsk/.........kdbsk/..........kdbk/..........kkkk'),
    (2,-20,'kkkk/kggpk/kggpgk/.kgppk/.kgppgk/..kgphk/..kghhk/..khdbk/...kdbk/...kdbsk/...kdbsk/....kdbsk/....kdbsk/....kdbsk/....kdbsk/....kdbsk/.....kdbk/.....kdbk/.....kdbk/.....kkk/.....kk'),
    (-1,-20,'kkkk/kggpk/kggpk/kggpk/kggpk/.kgpk/.kghk/.khhk/.kdhk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kdbk/.kkkk'),
]


# Hand-painted sleeves for the eight phases of each gait. Running tears the loose
# shoulder out of the silhouette; compression cels pull it back behind the sling.
WALK_SLEEVES = [
    (-8,-18,'..kk/.kgk/.kphk/kppk/kghk/kkk'), (-7,-17,'.kk/kggk/kppk/.khk/.kk'),
    (-6,-17,'kk/kgk/kpgk/kppk/khk/kk'), (-6,-17,'kk/kgk/kpgk/kpgk/kphk/.kkk'),
    (-5,-18,'kk/kggk/kppk/.kphk/..khk/..kk'), (-5,-17,'kk/kgk/kppk/kphk/.khk/.kk'),
    (-6,-17,'kk/kgk/kpgk/kppk/khk/kk'), (-7,-18,'.kk/kggk/kpgk/kphk/.kkk'),
]
RUN_SLEEVES = [
    (-11,-18,'....kk/...kgpk/..kgpk/.kppk/kphk/khk/kk'),
    (-9,-17,'..kk/.kgpk/kpgk/kphk/khk/kk'),
    (-6,-16,'kk/kgk/kpgk/kpgk/kphk/.kk'),
    (-5,-17,'kk/kggk/kppk/.kppk/..kphk/...kk'),
    (-4,-17,'kk/kggk/kpppkk/.kkpghhk/...kkhhk/.....kk'),
    (-5,-17,'kk/kggk/kpppk/.kgphk/..khk/..kk'),
    (-6,-16,'kk/kgk/kpgk/kppk/kphk/.kk'),
    (-8,-17,'..kk/.kgpk/kpgk/kphk/khk/kk'),
]
VERTICAL = [
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbskdbk/..kbskddk/..kbdkkkk/.kddkk/.kkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbskbdk/..kbskddk/..kbdkkk/.kddkk/.kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbskbbk/..kbskdbk/..kbdkddk/.kddkkkkk/.kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbdkbbk/..kddkbbk/..kkkdbbk/......kddkk/......kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kddkbbk/..kkkkbsk/.....kbsk/.....kddkk/.....kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kddkbsk/..kkkbbsk/.....kbsk/.....kddkk/.....kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbskbbk/..kddkbsk/..kkkkbsk/.....kddkk/.....kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbbbbbk/..kbskbbk/..kbskbbk/..kbskddk/..kbskkkk/.kddkk/.kkkkk'),
]

VERTICAL_RUN = [
    (-7,'..kkdddk/..kdbsskk/..kbbbsbk/..ksbsbbk/..ksbkdbk/..ksbkddk/..ksbkkkk/.kdddkk/.kkkkkk'),
    (-7,'..kkdddk/..kdbsskk/..kbbbsbk/..ksbsbbk/..ksbbddk/..ksbdddkk/..kbdkkkkk/.kddkk/.kkkkk'),
    (-7,'..kkdddk/..kdbsskk/..kbbbsbk/..kbssbdk/..kbsbdddkk/..kbsbkkkkk/..kbsk/.kdddkk/.kkkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbssbbk/..kbdkkbk/..kddkbbk/..kkkkbbk/......kbsk/......kddkk/......kkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbssbbk/..kddkbbk/..kkkkbbk/.....kbbsk/.....kbbsk/.....kbddkk/.....kkkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbssbbk/..kddkbsk/..kkkkbsk/.....kbsk/.....kbsk/.....kdddkk/.....kkkkkk'),
    (-7,'..kkdddk/..kdbbbkk/..kbsbbbk/..kddkbsk/..kdddksk/..kkkkksk/.....kbsk/.....kbddkk/.....kkkkkk'),
    (-7,'..kkdddk/..kdbsskk/..kbbbsbk/..ksbsbbk/..ksbkddk/..ksbkddk/..ksbkkkk/.kddkk/.kkkkk'),
]


def survivor(legs, breath=0, aim=None, recoil=0, travel='side', sleeve=None):
    im = blank()
    stamp(im, legs[0], -8, legs[1])
    stamp(im, -6, -31, SURVIVOR)
    stamp(im, 0, -28, BREATH[breath])
    if travel == 'side':
        stamp(im, -8, -19, '..kkk/.kdmlk/kddmlk/kdmmmk/kddmk/.kdk/.kk')
    if aim is None:
        if travel == 'back':
            stamp(im,-6,-31,'..kkkkk/.kddbbsk/kdbbbssk/kdbbbssk/kdbbbsbk/.kdbbbk/.ktgggk/.ktgggk/.ktppgk/kggppgk/kggpphgk/ktgpphgk/kggpppgkk/kpppppgmgk/kppppgmsgk/kpppgmsgpk/kppgmsgppk/kpgmsgppgk/kgmsgppggk/kgggppgtdk/kggggttdkk/.ktgttddk')
        elif travel == 'front':
            stamp(im,-6,-26,'..kphphk/..khhhpk/..kphpgk/.ktgpgpk/.khhhgk/.kghpgk/ktgppgpk/kpgpmppk/khgphgphk/kppgmgppgk/kppgmggpgk/kgpgmgppgk/kgpgmgpgdk/ktggmgpgdk/ktggmggdbk/.kggtgtkk')
        if sleeve:
            stamp(im, *sleeve)
        stamp(im, 3 if breath in (0,3) else 2, -17, 'kk/kgk/kpk/kpk/khk/kdk/kbk/kk')
    else:
        x,y,rows = AIM[aim]
        # Recoil is a separate stamped pixel cel, with a painted slide highlight.
        if recoil == 1:
            x -= 1 if 0 < aim < 8 else 0
            y += 1 if aim < 4 else -1 if aim > 4 else 0
            rows = rows.replace('s', 'w', 1)
        elif recoil == 2:
            rows = rows.replace('d', 'n', 1)
        elif recoil == 3:
            rows = rows.replace('d', 'b', 1)
        stamp(im,x,y,rows)
    return im


# Worker's tilted hardhat, dangling belt, torn high visibility bands and oversized arm.
WORKER = ('....kkkk/..kkaeeck/..kaeeccck/.kaeccccck/kaeeeccccck/.kkkkiaaak/'
          '..kimmllk/..kimkmmlk/...krnmlk/...krmllk/...krfmkk/...kiimmk/..kiimmk/..kibimmk/..kbiimmkk/..kibimmk/'
          '.kbieibbdkk/kbbieibbbmmk/kbbecibmmlmk/kbbcibimmmlk/kbbiibimlmk/'
          'kbbiiaimlmk/kbeecimlk/kbiiiimlk/kiiiiimk/.kiiik')
WORK_LEGS = [
    (-9,'...kiiik/...kiidik/..kiiidikk/..kiikkiik/.kiik..kiik/.kik....kik/kdk.....kidkk/kkkk....kkkkk'),
    (-8,'..kiiik/..kiidik/..kiiidikk/..kiiikiik/.kiik.kiik/.kiik..kik/kddk...kidkk/kkkk...kkkkk'),
    (-7,'..kiiik/..kiidik/..kiiidik/..kiiidiik/..kiikkiik/..kiik.kik/.kddkk.kidk/.kkkkk.kkkkk'),
    (-7,'..kiiik/..kiidik/..kiidik/..kiidiik/...kiiik/...kidik/...kddkk/...kkkkkk'),
    (-8,'..kiiik/..kiidik/.kiiiidik/.kiikkiiik/kiik..kiiik/kik....kiik/kddk....kidkk/kkkk....kkkkk'),
    (-8,'...kiiik/...kiidik/..kiiidik/..kiikiik/..kiikkiik/.kik..kiik/.kddk..kidkk/.kkkk..kkkkk'),
    (-7,'..kiiik/..kiidik/..kiiidik/..kiidiik/...kiidiik/...kiikkiik/...kddkk/. .kkkkkk'.replace(' ','')),
    (-7,'..kiiik/..kiidik/..kiiidik/..kiiidiik/..kiikkiik/..kik.kiik/.kddk..kidkk/.kkkk..kkkkk'),
]
WARN = [
    (4,-22,'kmmk/kmlmk/kmlmk/.kmllk/.kmllk/..kmmk/...kk'),
    (4,-23,'kmmk/kmlmk/kmlmmk/.kmlmlk/..kmlmk/...kmmk/....kk'),
    (4,-25,'..kkkk/.kmmllk/kmmmllk/kmmmk/kkk'),
    (4,-29,'......kkk/.....kmllk/....kmmlk/...kmmlk/..kmmlk/.kmmlk/kmmmk/kkk'),
]
ATTACK = [
    (5,-27,'.......kkk/......kmllk/.....kmmlk/...kkmmlk/.kkmmmlk/kmmmkkk/kkkk'),
    (5,-24,'......kkkk/....kkmmllkk/..kkmmmlmlllk/kkmmmmmkkmmk/kmmmkkk..kk/kkkk'),
    (5,-21,'..kkkkkkkkkk/kkmmmmmlmmllkk/kmmmmmmlmmmlllk/kkkkkkkkkmmmk/.........kkk'),
    (5,-20,'kkkk/kmmmk/kkmmlkk/.kkmmlmkk/...kkmmllkk/.....kmmlllk/......kmmkk/.......kk'),
    (5,-20,'kkk/kmmk/kmlmk/.kmlmk/.kmmlk/..kmllk/...kmmk/....kk'),
]
FALL = [
    (-9,-18,'........kkkk/......kkaeck/.....kaeccck/....kaeecck/....kkkiiak/...kimmllk/..kiimlmlk/..kiimmmlk/..kiiiimmk/...kiiicikk/..kddiiicikk/.kddiibiiiikk/kddkkiiibimmk/kkkk.kddiimmlk/.....kkkkmmllk/.........kkkk'),
    (-14,-8,'...........kkkkkk/.....kkkkkkkiiieck/...kddiidiiibeeccck/.kkddiiddiimmleeck/kddkkiiiimmllkmmlk/kkkkkkkkkkkkkkkkkk'),
    (-15,-7,'...............kkkkk/....kkkkkkkkkkkiiecck/.kkdddiidibieeecccck/kddkkiiidiimmlmmllk/kkkkkkkkkkkkkkkkkkk'),
    (-15,-6,'...............kkkkk/..kkkkkkkkkkkkkiiecck/kddkddiidiibieeccceck/kkdkkiiidiimmlmmllk/.kkkkkkkkkkkkkkkkkk'),
]


def worker(leg=0, phase=0, arm=None, hit=False):
    im=blank()
    stamp(im, WORK_LEGS[leg][0], -7, WORK_LEGS[leg][1])
    stamp(im, -6, -33, WORKER)
    if phase % 4 == 1:
        stamp(im,-5,-11,'kbiecimk/kiicciimk/kbiikiimk')
    elif phase % 4 == 2:
        stamp(im,-5,-11,'kbiecimk/kiiccmmk/kbiikiimk')
    elif phase % 4 == 3:
        stamp(im,-5,-11,'kbiicimk/kiicciimk/kbiikiimk')
    if arm:
        stamp(im,*arm)
    if hit:
        stamp(im,-1,-22,'krrnk/krrmk/.krmk')
        stamp(im,-7,-18,'r.r/..r')
    return im


def sheet(name, rows, cols=8):
    im=Image.new('RGBA',(W*cols,H*((len(rows)+cols-1)//cols)))
    for i, cel in enumerate(rows):
        im.paste(cel, (i%cols*W,i//cols*H))
    im.save(OUT / (name + '.png'), optimize=True)


def mirror(cel):
    # Reflect about x=28, not the midpoint between texels 27 and 28.
    im = blank()
    im.paste(cel.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(1,0))
    return im


if __name__=='__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for face in ('side','front','back'):
        sheet('survivor_'+face, [survivor(STAND,i,travel=face) for i in range(4)] +
              [survivor(l if face == 'side' else VERTICAL[i],i%4,travel=face,
                        sleeve=WALK_SLEEVES[i] if face == 'side' else None) for i,l in enumerate(WALK)] +
              [survivor(l if face == 'side' else VERTICAL_RUN[i],i%4,travel=face,
                        sleeve=RUN_SLEEVES[i] if face == 'side' else None) for i,l in enumerate(RUN)])
    # Aim rows: down, down-right ... up-right, up, then the seven mirror poses.
    # Per direction: idle, eight walk, eight run, then three recoil cels for each gait cel.
    a = []
    for angle in range(16):
        index = angle if angle <= 8 else 16-angle
        cels = [survivor(leg,0,8-index,r) for r in range(4) for leg in [STAND]+WALK+RUN]
        a.extend(cels if angle <= 8 else [mirror(c) for c in cels])
    sheet('survivor_aim',a,17)
    w = [worker(3,i) for i in range(4)] + [worker(i,i) for i in range(8)]
    w += [worker(3,0,arm) for arm in WARN]
    w += [worker(min(i,7),i,arm) for i,arm in enumerate(ATTACK)]
    w += [worker(0,0,WARN[0],True),worker(3,1,WARN[0],True)]
    for spec in FALL:
        cel=blank()
        stamp(cel,*spec)
        w.append(cel)
    sheet('walker',w)
