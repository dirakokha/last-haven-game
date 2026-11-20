"""Editable key cels and targeted non-destructive cleanup of the approved court plate."""
from PIL import Image
from pack_art import ROOT, SOURCE, CELL, ORIGIN, key_sprite, pack, environment

OUT = ROOT / "assets/side_review"

# Mask strips in runtime plate coordinates: x, first row, last row, half width.
# Only the falling lines are masked, leaving horizontal puddle/reflection bands in place.
STREAKS = [
    (26,0,42,2),(70,0,18,1),(92,0,87,3),(97,36,68,1),(166,95,145,2),
    (183,107,130,1),(219,116,176,2),(233,3,52,2),(263,6,30,2),(310,20,43,2),
    (350,73,102,2),(366,19,66,2),(390,65,119,2),(418,0,18,2),(438,89,114,2),
    (461,24,58,2),(468,4,25,1),(500,0,27,1),(514,3,25,2),(528,59,86,2),
    (546,59,81,1),(596,0,12,1),(674,54,93,2),(706,57,90,2),(748,39,78,2),
    (775,0,23,2),(821,22,120,3),(863,0,60,2),(881,51,96,2),(907,50,96,2),
    (930,22,116,2),(984,15,78,2),(1019,2,24,2),(1070,9,31,2),(1095,20,57,2),
    (233,167,210,2),(271,202,271,2),(299,200,267,2),(316,229,273,2),(375,216,286,2),
    (344,173,191,1),(421,168,202,2),(428,243,277,2),(438,229,258,1),(25,204,242,2),
    (40,308,339,2),(71,239,251,1),(624,261,272,1),(676,177,220,2),(730,203,234,2),
    (747,252,304,2),(783,208,234,1),(829,171,207,2),(884,286,339,2),(907,293,340,2),
    (1039,263,321,2),(1056,171,202,2),(1064,222,238,1),(1079,242,298,2),(1091,165,197,2),
    (11,366,392,2),(29,363,398,2),(40,447,483,2),(49,362,399,2),(90,362,385,2),
    (110,413,475,3),(147,421,479,2),(166,392,428,2),(182,455,483,2),(337,417,481,3),
    (375,458,483,2),(422,440,485,3),(456,444,472,2),(488,401,437,2),(510,417,461,2),
    (525,422,449,2),(570,420,451,2),(621,451,470,2),(657,448,470,2),(766,406,443,2),
    (790,451,478,2),(808,451,483,2),(872,396,436,2),(907,397,423,2),(912,408,453,2),
    (976,422,451,2),(1010,393,478,2),(1060,364,390,1),(1077,410,444,2),(1092,348,372,2),
    (333,489,539,2),(405,488,524,2),(757,475,501,2),(873,490,521,2),(912,494,530,2),
    (1054,494,536,2),(1066,494,521,2),
    (1012,390,461,3),(947,75,175,2),(927,132,176,2),(1068,152,192,2),
    (1070,239,305,2),(110,111,161,2),(155,369,444,2),(164,409,453,2),
    (434,395,462,2),(637,357,423,2),(950,390,445,2),(881,365,402,2),
    (900,369,403,2),(786,398,436,2),(776,394,449,2),(722,178,231,2),
    (657,417,443,2),(527,386,443,2),(392,275,319,2),(114,259,284,2),
]


def dry_plate():
    # Same scale and crop as Gate 2. Neighbor interpolation stays on the same row,
    # so a streak crossing a horizontal wet reflection does not erase that reflection.
    original = Image.open(OUT / 'court.png').convert('RGB')
    result = original.copy()
    for x, start, end, r in STREAKS:
        left, right = x-r-1, x+r+1
        for y in range(start, end+1):
            blend = min(1, (y-start+1)/3, (end-y+1)/3)
            for u in range(left+1, right):
                t = (u-left)/(right-left)
                a, b, pixel = original.getpixel((left,y)), original.getpixel((right,y)), original.getpixel((u,y))
                result.putpixel((u,y), tuple(round(p*(1-blend)+(j*(1-t)+k*t)*blend) for p,j,k in zip(pixel,a,b)))
    result.save(OUT / 'court_dry.png', optimize=True)


def new_key(name, ratio, pin):
    im = Image.open(SOURCE / 'v11' / (name + '.png')).convert('RGBA')
    im = im.resize(tuple(round(x * ratio) for x in im.size), Image.Resampling.NEAREST)
    indexed = im.convert('RGB').quantize(48, dither=Image.Dither.NONE).convert('RGBA')
    indexed.putalpha(im.getchannel('A'))
    cel = Image.new('RGBA', CELL)
    cel.paste(indexed, tuple(ORIGIN[i] - round(pin[i]*ratio) for i in range(2)))
    return cel


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    environment(OUT)
    dry_plate()
    (OUT / 'court.png').unlink()
    survivor = [key_sprite('survivor_'+p, (652,721), 100/650) for p in ('guard','stride','air')]
    walker = [key_sprite('walker_guard', (136,739), 104/692, (970,0,1245,768)),
              key_sprite('walker_warn', (350,1541), 99/1443)]
    survivor += [new_key('hero_'+name, ratio, pin) for name, ratio, pin in [
        ('land', 100/650, (139,629)), ('run', 100/650,(241,650)),
        ('reload', 100/650,(143,652)), ('pass', 100/650,(138,652)),
        ('melee', 100/650,(272,644)), ('dodge', 100/650,(226,546)),
    ]]
    walker += [new_key('walker_'+name, ratio, pin) for name, ratio, pin in [
        ('stride', 104/1440, (345,1440)),('lunge', 104/1447, (475,1447)),
        ('hit', 104/1440, (282,1375)), ('fall', 108/916, (460,280)),
    ]]
    pack('review_survivor', survivor, OUT)
    pack('review_walker', walker, OUT)


if __name__ == '__main__':
    main()
