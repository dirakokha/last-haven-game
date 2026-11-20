"""Original synthetic Gate 2 direction cues. No samples, imitated recordings, or external assets."""
from array import array
from math import exp, pi, sin
from pathlib import Path
from random import Random
import sys
import wave

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'build/gate2-reference'
RATE=32000


def encode(path, signal):
    path.parent.mkdir(parents=True, exist_ok=True)
    samples=array('h',(round(max(-.99,min(.99,v))*32767) for v in signal))
    if sys.byteorder!='little': samples.byteswap()
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed')); f.writeframes(samples.tobytes())


def cue(kind, index, duration):
    random=Random(2407+index*307)
    close=0.; bass=0.; prior=0.; phase=0.
    for i in range(round(RATE*duration)):
        t=i/RATE
        n=random.uniform(-1,1)
        bass+=.067*(n-bass); close+=.31*(n-close)
        high=n-prior; prior=n
        if kind=='pistol':
            # Dry crack, shifted body partials, separate cycling click and diffuse wall slap.
            attack=(.39*high+.29*n)*exp(-220*t)
            body=sum(a*sin(2*pi*f*t-39*t*t)*exp(-k*t) for a,f,k in ((.34,143+index*9,78),(.17,211,99),(.07,421,143)))
            action=0.0 if t<.028 else (.22*high+.14*sin(2*pi*316*t))*exp(-410*(t-.028))
            reverb=sum(a*(.69*close+.31*bass)*exp(-k*(t-d)) for d,a,k in ((.053,.22,47),(.081,.14,36),(.136,.075,27),(.215,.045,18)) if t>=d)
            v=attack+body+action+reverb
        elif kind=='step':
            # Heel compression plus a separated water-and-grit toe release.
            thud=(.49*bass+.20*sin(2*pi*(106+index*14)*t))*exp(-44*t)
            splatter=0.0 if t<.024+index*.004 else (.16*high+.18*close)*exp(-31*(t-.024-index*.004))
            v=(thud+splatter)*(1-exp(-310*t))
        elif kind=='walker':
            # Irregular breath plus a low pulse through three moving formants, no real voice source.
            wobble=sin(t*37+index)*11+sin(t*123)*5+5*n
            phase+=2*pi*(49+index*26+wobble)/RATE
            scrape=.57*sin(phase)+.23*sin(phase*2.03)+.20*bass
            shape=(1-exp(-t*17))*exp(-4.2*t)*(0.74+0.26*sin(t*39))
            resonant=(.19*sin(phase*4.6)+.09*sin(phase*9.1))*(.48+.52*sin(phase)**2)
            v=(scrape*.52+resonant+.14*close+.055*high)*shape
        else:
            v=(.29*bass+.16*sin(2*pi*(127+index*14)*t)+.12*high)*exp(-(37+index*6)*t)
            if index:
                v+=.14*sin(2*pi*1150*t)*exp(-74*t)
        yield v * min(i/12,1) * min((duration-t)*70,1)


def group(name,count,duration):
    clips=[]
    for i in range(count):
        audio=list(cue(name,i,duration)); clips.append(audio)
        encode(OUT/f'gate_{name}_{i+1}.wav',audio)
    return clips


if __name__=='__main__':
    gun=group('pistol',2,.36); step=group('step',2,.21)
    walker=group('walker',2,.91); impact=group('impact',2,.25)
    demo=[0.]*(RATE*8)
    for t,clip,vol in [(.40,step[0],.92),(.78,step[1],.91),(1.13,step[0],1),(1.55,step[1],1),
        (2.12,walker[0],1),(3.35,walker[1],1),(4.40,gun[0],1),(4.56,impact[1],.62),
        (5.16,gun[1],1),(5.36,impact[0],.67),(6.22,walker[0],.72),(7.15,impact[0],.8)]:
        a=int(t*RATE)
        for i,v in enumerate(clip): demo[a+i]+=v*vol
    encode(OUT/'side_audio_direction.wav',demo)
