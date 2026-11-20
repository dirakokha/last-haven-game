"""Editable pixel-painting recipe for Depot 04 (Pillow, no external textures)."""
from pathlib import Path
from random import Random
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[2] / 'assets/art'
R = Random(1602)
W,H=1440,540
im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im)

def rgb(s): return tuple(bytes.fromhex(s))
def mix(a,b,f): return tuple(round(x+(y-x)*f) for x,y in zip(a,b))
def box(x,y,w,h,c): d.rectangle((x,y,x+w-1,y+h-1),fill='#'+c if isinstance(c,str) else c)
def line(points,c,w=1): d.line(points,fill='#'+c if isinstance(c,str) else c,width=w)
def poly(points,c): d.polygon(points,fill='#'+c if isinstance(c,str) else c)

def ramp(a,b,start,stop):
    for y in range(start,stop): box(0,y,W,1,mix(rgb(a),rgb(b),(y-start)/(stop-start)))

# A small display alphabet. Set into the masonry, not screen-space UI.
GLYPHS = dict(zip('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./-:', (
 '011101111101101','110101110101110','111100100100111','110101101101110','111100110100111',
 '111100110100100','111100101101111','101101111101101','111010010010111','001001001101111',
 '101101110101101','100100100100111','101111111101101','101111111111101','111101101101111',
 '111101111100100','111101101111001','110101110101101','111100111001111','111010010010010',
 '101101101101111','101101101101010','101101111111101','101101010101101','101101010010010',
 '111001010100111','111101101101111','010110010010111','111001111100111','111001111001111',
 '101101111001001','111100111001111','111100111101111','111001010010010','111101111101111',
 '111101111001111','000000000000010','001001010100100','000000111000000','000010000010000',
)))

def text(x,y,s,c,z=1):
    for n,ch in enumerate(s):
        for j,b in enumerate(GLYPHS.get(ch,'')):
            if b=='1': box(x+z*(n*4+j%3),y+z*(j//3),z,z,c)

ramp('101d2c','415560',0,184)
# Distant haze, cranes and roof tiers.
for i in range(150):
    x=R.randrange(W); y=R.randrange(5,87)
    a=tuple(im.getpixel((x,y))); box(x,y,min(W-x,R.randint(9,110)),1,mix(a,rgb('6b7280'),.09))
for x,y,w in [(-28,63,150),(197,48,74),(275,57,95),(466,54,90),(637,47,101),(930,42,101),(1200,27,114),(1325,64,120)]:
    box(x,y,w,106-y,'223140'); box(x,y,w,2,'344853')
    for a in range(x+8,x+w-9,13):
        box(a,y+7,5,2,R.choice(['3a4c55','3b4e57','526269','5f5b58']))
for x,y,run in [(163,35,163),(1062,27,131),(1334,41,100)]:
    line([(x-5,113),(x, y),(x+5,113)],'273745',2)
    line([(x-43,y+5),(x+run,y+5),(x+21,y-5),(x-43,y+5)],'2e3f4d',2)
    for xx in range(x-35,x+run,10): line([(xx,y+5),(xx+5,y)],'2e3f4d')
    line([(x+run-13,y+6),(x+run-13,y+29),(x+run-10,y+28)],'273745')

# Three overlapping warehouse masses.
def facade(x,y,w,b,wall,shadow,lit):
    poly([(x-14,y+14),(x+29,y-4),(x+w-20,y-4),(x+w+13,y+14)],shadow)
    box(x-14,y+13,w+26,2,lit); box(x,y+15,w,b-y-15,wall)
    box(x,y+15,w,6,shadow)
    for a in range(x+4,x+w,7):
        box(a,y+21,1,b-y-21,shadow)
    for a in range(x+38,x+w,86):
        box(a,y+24,48,22,'182632'); box(a+2,y+26,44,17,'314853'); box(a+2,y+26,44,2,'546771')
        for q in range(a+5,a+46,8): box(q,y+27,1,16,'182932')
        box(a+1,y+35,46,1,'23353d'); box(a-2,y+46,52,2,lit)

facade(0,79,345,191,'26353c','202c36','4a5860')
facade(884,70,556,192,'26373c','202e36','4c5d62')
poly([(307,112),(343,91),(369,91),(369,192),(307,192)],'182934')
facade(353,70,542,193,'39474b','2b3940','566367')
box(353,153,542,40,'303b3e'); box(353,157,542,1,'625e51')
# Specific worn vertical box trims around numbered loading doors.
for x,n in [(382,'03'),(545,'04'),(708,'05'),(1000,'06'),(1163,'07')]:
    box(x-7,122,129,71,'20292f'); box(x-4,126,122,65,'576061'); box(x,130,114,63,'333d43')
    for y in range(133,191,5):
        box(x+2,y,109,1,'495457'); box(x+2,y+1,109,2,'292f33')
    box(x+7,135,28,15,'2b343a'); text(x+11,137,n,'aab4a7',2)
    box(x-4,156,4,37,'867343'); box(x+114,156,4,37,'867343')
    for y in range(157,192,8):
        line([(x-4,y+3),(x-1,y)],'292d2c',2); line([(x+114,y+3),(x+117,y)],'292d2c',2)
    box(x+1,187,111,6,'24292c')
box(470,63,200,16,'141f29'); box(471,63,198,1,'607174'); box(474,67,192,9,'2c3941')
text(483,67,'NORTH QUAY / FREIGHT TERMINAL','b8b9a1')
for x in [360,522,686,848]:
    box(x,125,7,53,'202f36'); box(x+1,126,2,50,'5b645b'); box(x-1,142,9,2,'666955')
# Left service enclosure, bins, and cab nose. All are behind the far curb.
box(91,138,159,53,'253039'); box(93,140,151,50,'2d3d43'); box(92,139,156,2,'52636a')
for x in range(95,249,7): box(x,145,1,43,'23323b')
box(107,148,56,11,'1b2c35'); text(112,151,'SERVICE 01','9aabac')
for x in (214,239,266,819,839,943,1288):
    box(x,177,21,14,'263932'); box(x+2,175,17,2,'76806a'); box(x+1,178,2,10,'42574f')
for x in (278,293,922,971,1314):
    box(x,172,11,19,'384348'); box(x+1,174,8,14,'53615e'); box(x,176,11,2,'263539'); box(x,186,11,2,'263539')
poly([(1361,186),(1361,164),(1374,144),(1417,144),(1439,158),(1439,190),(1361,190)],'44535a')
poly([(1369,163),(1378,149),(1410,149),(1410,164)],'182732')
box(1362,167,25,4,'58666a'); box(1361,179,17,4,'b59e77'); box(1391,183,24,8,'16222b')
# Paved lane. Gameplay edges stay at x=80/1360 and y=200/450.
ramp('374448','202d36',191,540)
for y in [193,196,200,236,303,401,449,454,459,470]:
    col=tuple(im.getpixel((100,y)))
    box(80,y,1280,1,mix(col,rgb('101927'),.38)); box(80,y+1,1280,1,mix(col,rgb('839194'),.12))
for x in range(82,1360,41):
    box(x,193,39,3,'6c7470'); box(x,449,39,3,'65665e')
    if x%3: box(x+1,451,35,2,'474b48')
for x in [-120,100,320,540,760,980,1200,1420]:
    line([(x,200),(x+(x-720)//6,449)],'344147')
for x in range(107,1350,75):
    box(x,422,31,2,'646a5d'); box(x+1,424,16,1,'4b5450')
for x in range(110,1330,118):
    box(x,203,79,2,'575f58'); box(x,207,17,1,'556259')
for x,y in [(290,219),(742,379),(1144,229),(1038,407),(153,407),(585,266),(438,435)]:
    box(x,y,29,6,'202d33'); box(x+1,y+6,28,1,'546064')
    for xx in range(x+2,x+28,3): box(xx,y+1,1,4,'495456')
# Clusters of dark standing water, cut with thin sky-colored broken reflection strips.
for x,y,ww,hh in [(164,247,134,15),(410,286,145,16),(612,241,135,18),(840,352,169,23),(1086,281,135,17),(1275,379,142,19),(370,389,140,19),(651,429,117,18),(143,428,87,11),(1180,416,114,12),(740,322,88,8)]:
    c=tuple(im.getpixel((x,y)))
    poly([(x-ww//2,y),(x-ww//3,y-3),(x-ww//6,y-5),(x+ww//5,y-3),(x+ww//2,y+1),(x+ww//3,y+4),(x+ww//4,y+hh//3),(x-ww//5,y+hh//3),(x-ww//4,y+3)],mix(c,rgb('142630'),.40))
    for j in range(hh//2):
        q=R.randint(13,ww//2); a=R.randint(-ww//3,ww//3-q//2)
        box(x+a,y-3+j,q,1,mix(c,rgb('6a8a8a'),R.uniform(.12,.29)))
for i in range(5600):
    x=R.randrange(W); y=R.randrange(200,H); c=tuple(im.getpixel((x,y)))
    box(x,y,min(W-x,R.choices([1,2,3,5,9],[8,14,11,7,3])[0]),1,mix(c,rgb(R.choice(['78a0a3','739291','162632','162632'])),R.uniform(.06,.18)))
for x,y in [(177,284),(311,387),(608,403),(757,237),(989,286),(1208,320)]:
    line([(x-24,y+2),(x-10,y),(x,y+1),(x+4,y+4),(x+15,y+5)],'2b3940')
    line([(x,y+1),(x+5,y-2),(x+16,y-3)],'2b3940')
# Foreground utility tracks and tall dark shoulder markers (outside the walkable area).
for x in range(95,1350,138):
    box(x,477,99,19,'24313a'); box(x,477,97,1,'4b5a60'); box(x+2,494,98,1,'17252f')
    for xx in range(x+5,x+95,7): box(xx,480,3,12,'1c2934')
for x in [81,1357]:
    box(x-2,201,4,247,'4c5754'); box(x-3,200,6,8,'a08b56'); box(x-3,441,6,8,'a08b56')
# Lamp hardware is drawn onto the facade, so it doesn't introduce false collision.
for x in [514, 1064]:
    box(x-3,98,5,27,'1d2b32'); box(x-8,116,18,3,'222e32'); box(x-13,120,29,4,'1b282c')
    box(x-12,122,27,1,'60716c'); box(x-10,124,23,3,'bc884d'); box(x-8,125,19,1,'ffe2a2')
text(99,462,'NQ / 04','788381',2)
text(1230,462,'KEEP CLEAR','788381',2)
OUT.mkdir(parents=True,exist_ok=True)
im.save(OUT/'depot.png',optimize=True)

# Fine optional baked lighting; static transparent overlay avoids dynamic shadow passes.
glow=Image.new('RGBA',im.size); d=ImageDraw.Draw(glow)
for lx in [514,1064]:
    for y in range(106,332):
        width = max(22, (y-110)*.64)
        for x in range(int(lx-width),int(lx+width)+1):
            from math import exp
            dx=(x-lx)/width
            if y<191:
                a=int(89*exp(-((y-130)/39)**2)*max(0,1-abs(dx))**1.45)
            else:
                a=int(43*exp(-((y-223)/42)**2)*max(0,1-abs(dx))**1.55)
            if a>1: glow.putpixel((x,y),(236,153,64,a))
    for i in range(100):
        y=R.randrange(198,303); w=R.randrange(2,36); x=lx+R.randint(-int((y-191)*.35+8),int((y-191)*.35+8))
        box(x-w//2,y,w,1,(226,155,77,R.randint(12,53)))
glow.save(OUT/'depot_lamps.png',optimize=True)

# Walk-around shipping cases. Origin (32,50) corresponds to the existing 48x16 footing.
prop=Image.new('RGBA',(64,60)); d=ImageDraw.Draw(prop)
poly([(1,52),(8,42),(52,42),(63,53),(52,59),(7,59)],(6,14,22,112))
poly([(8,20),(15,13),(55,13),(55,57),(8,57)],'202c30')
poly([(8,21),(16,13),(55,13),(48,21)],'737464')
box(9,22,42,34,'4f5147'); box(10,24,40,29,'49483d')
for y in [26,32,38,44,50]:
    box(10,y,40,1,'606052'); box(10,y+1,40,1,'383c34')
poly([(51,22),(55,16),(55,50),(51,57)],'343c34')
for x in [13,44]:
    box(x,20,3,37,'343c39'); box(x,23,1,32,'85877b')
box(23,30,13,9,'766e55'); text(24,32,'04','c2b58c'); box(9,56,44,1,'202a2b')
prop.save(OUT/'cargo.png',optimize=True)
