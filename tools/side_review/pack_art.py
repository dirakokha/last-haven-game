"""Pack AI-assisted direction keys into one-bit-alpha review cels; not a finished animation pipeline."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools/side_review/source'
OUT = ROOT / 'build/gate2-reference'
CELL = (144, 128)
ORIGIN = (68, 114)


def key_sprite(name, anchor, scale, crop=None):
    rgb = Image.open(SOURCE / (name + '.png')).convert('RGB')
    if crop:
        rgb = rgb.crop(crop)
    alpha = Image.frombytes('L', rgb.size, bytes(
        0 if r > 95 and b > 95 and min(r, b) - g > 55 else 255
        for r, g, b in rgb.get_flattened_data()))
    l,t,r,b = alpha.getbbox()
    trim = rgb.crop((l,t,r,b)).convert('RGBA')
    trim.putalpha(alpha.crop((l,t,r,b)))
    trim = trim.resize((round((r-l)*scale), round((b-t)*scale)), Image.Resampling.NEAREST)
    # Compact, stable cluster colors: no blur or dither. Restore exact alpha after indexing.
    colors = trim.convert('RGB').quantize(48, dither=Image.Dither.NONE).convert('RGBA')
    colors.putalpha(trim.getchannel('A'))
    cel = Image.new('RGBA', CELL)
    cel.paste(colors, (ORIGIN[0]+round((l-anchor[0])*scale), ORIGIN[1]+round((t-anchor[1])*scale)))
    return cel


def pack(name, cels, out=OUT):
    sheet = Image.new('RGBA', (CELL[0]*len(cels), CELL[1]))
    for i, cel in enumerate(cels):
        sheet.paste(cel, (CELL[0]*i, 0))
    sheet.save(out / (name+'.png'), optimize=True)


def environment(out=OUT):
    plate = Image.open(SOURCE/'court_plate.png').convert('RGB')
    image = plate.resize((1100, 614), Image.Resampling.NEAREST).crop((0,7,1100,547))
    image.save(out/'court.png', optimize=True)
    falloff = Image.new('RGBA', (256, 256))
    falloff.putdata([(255, 240, 209, round(255*max(0, 1 - (((x-127.5)/127.5)**2 + ((y-127.5)/127.5)**2)**.5)**2))
                     for y in range(256) for x in range(256)])
    falloff.save(out/'lamp.png', optimize=True)
    cargo = Image.new('RGBA',(70,44))
    d=ImageDraw.Draw(cargo)
    d.rectangle((0,0,69,43), fill='#1b2428'); d.rectangle((2,2,67,40), fill='#4a514f')
    d.rectangle((2,2,67,4), fill='#84928a'); d.rectangle((4,7,65,37), fill='#393e40')
    d.rectangle((11,12,58,31), outline='#585d56')
    for x in (6,61):
        d.rectangle((x,5,x+2,41), fill='#6e7267')
        for y in (7,34): d.point((x+1,y),fill='#aead9b')
    for i in range(6):
        x=25+i*4; d.line([(x,34),(x+3,39)],fill='#94825f',width=2)
    cargo.save(out/'review_case.png', optimize=True)


if __name__=='__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    pack('review_survivor', [key_sprite('survivor_'+p, (652,721), 100/650)
                            for p in ('guard','stride','air')])
    pack('review_walker', [key_sprite('walker_guard', (136,739), 104/692, (970,0,1245,768)),
                          key_sprite('walker_warn', (350,1541), 99/1443)])
    environment()
