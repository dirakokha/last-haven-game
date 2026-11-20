"""Native-pixel layout and pose study from the shipped assets; not an engine screenshot."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, features

ROOT=Path(__file__).resolve().parents[2]
ASSET=ROOT/'build/gate2-reference'
DEST=ASSET
FONT=ROOT/'assets/fonts/Vazirmatn-Regular.ttf'


def cel(name, index):
    atlas=Image.open(ASSET/('review_'+name+'.png')).convert('RGBA')
    return atlas.crop((144*index,0,144*(index+1),128))


def frame(pose, walker, x, y):
    scene=Image.open(ASSET/'court.png').convert('RGBA').crop((100,0,1060,540))
    d=ImageDraw.Draw(scene,'RGBA')
    def shadow(center, radius):
        # Six-pixel contact shadow, tied to the visible asphalt rather than the air pose.
        d.polygon([(center-radius,426),(center-radius+8,422),(center+radius-5,422),(center+radius,426),(center+radius-7,429),(center-radius+7,429)],fill=(8,18,21,210))
    scene.alpha_composite(Image.open(ASSET/'review_case.png').convert('RGBA'),(365,381))
    shadow(x,22); shadow(744,23)
    scene.alpha_composite(cel('survivor',pose),(x-68,y-114))
    scene.alpha_composite(cel('walker',walker),(676,311))
    d=ImageDraw.Draw(scene,'RGBA')
    rtl=features.check_feature('raqm')
    def words(x,y,text,size,color):
        if rtl:
            d.text((x,y),text,font=ImageFont.truetype(FONT,size),fill=color,anchor='rt',direction='rtl',language='fa')
        else:
            import arabic_reshaper
            from bidi.algorithm import get_display
            shaped = get_display(arabic_reshaper.reshape(text), base_dir='R')
            d.text((x,y),shaped,font=ImageFont.truetype(FONT,size),fill=color,anchor='rt')
    d.polygon([(24,41),(296,41),(296,108),(284,120),(24,120)],fill=(12,25,32,248),outline=(75,105,106))
    d.rectangle((24,41,26,119),fill='#79adac')
    words(279,54,'آخرین پناهگاه',30,'#e0e7d8')
    words(279,96,'محوطهٔ بارگیری ۰۴  /  پیش‌نمایش',14,'#a0bdb8')
    d.polygon([(789,41),(936,41),(936,75),(924,82),(789,82)],fill=(13,26,32,247),outline=(75,105,106))
    words(920,54,'سلامت   ۱۰۰',16,'#d6e2d6')
    d.polygon([(793,463),(936,463),(936,502),(923,510),(793,510)],fill=(13,26,32,247),outline=(75,105,106))
    words(918,473,'خشاب  ۱۲  /  ۳۶',16,'#eac696')
    d.rectangle((24,467,243,504),fill=(13,26,32,247),outline=(75,105,106))
    words(229,478,'آزمون اندازهٔ واقعی  /  ۱×',14,'#b4cfca')
    return scene.convert('RGB')


if __name__=='__main__':
    f=frame(0,0,527,425)
    f.save(DEST/'side_native.png',optimize=True)
    sequence=[(0,0,523,425),(1,0,532,425),(0,0,543,425),(2,1,562,374),
              (2,1,581,333),(2,1,602,357),(0,1,617,425),(0,0,622,425)]
    frames=[frame(*spec).quantize(220,dither=Image.Dither.NONE) for spec in sequence]
    frames[0].save(DEST/'side_pose_study.gif',save_all=True,append_images=frames[1:],
                   duration=[700,230,180,140,180,140,280,800],loop=0,optimize=True)
