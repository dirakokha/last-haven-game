"""Original synthetic sounds. No recordings, samples, or audio dependencies."""
from array import array
from math import exp, pi, sin, cos
from pathlib import Path
from random import Random
import sys
import wave

OUT = Path(__file__).resolve().parents[2] / 'assets/audio/proof'
RATE = 32000


def write(name, left, right=None):
    frames = left if right is None else (s for pair in zip(left, right) for s in pair)
    samples = array('h', (int(32767 * max(-1, min(1, v))) for v in frames))
    if sys.byteorder != 'little':
        samples.byteswap()
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1 if right is None else 2, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(samples.tobytes())


def rainfall(seed, duration):
    r=Random(seed); N=int(duration*RATE)
    white=[r.uniform(-1,1) for _ in range(N)]
    slow=0; med=0
    # Two passes settle recursive filters across the wrap point.
    out=[]
    for _ in range(2):
        out=[]
        for v in white:
            slow+=(v-slow)*.016; med+=(v-med)*.24
            out.append(.22*slow+.15*med+.036*v)
    for _ in range(175):
        i=r.randrange(N); amp=r.uniform(.014,.054); f=r.uniform(570,2600)
        for j in range(660):
            t=j/RATE
            out[(i+j)%N]+=amp*(1-exp(-t*4500))*exp(-t*195)*sin(2*pi*f*t)
    for i in range(N):
        out[i]*=.90+.07*cos(2*pi*i/N)+.03*sin(2*pi*i/N*5)
    return out


def cue(kind, i, duration):
    r=Random(1891+i*89); prev=0.; low=0.
    for n in range(int(duration*RATE)):
        t=n/RATE; v=r.uniform(-1,1); low+=(v-low)*.13
        grit=v-prev; prev=v
        if kind=='pistol':
            # Dry crack, low transient and a handful of diffuse yard echoes.
            y=(.39*v+.19*grit+.26*sin(2*pi*(169+i*7)*t))*exp(-t*83)
            for lag,amp in ((.036,.11),(.071,.09),(.126,.05),(.180,.027)):
                if t>lag:
                    y+=amp*(.56*low+.44*v)*exp(-(t-lag)*43)
        elif kind=='step':
            y=(.65*low+.12*v)*exp(-t*(24+i))
            tt=max(0,t-(.031+i*.003))
            if tt>0: y+=(.10*v+.07*grit)*exp(-tt*28)
        elif kind=='rack':
            y=0.
            for lag,amp,f in ((0,.18,538),(.106,.33,730),(.134,.12,195),(.331,.24,659),(.388,.11,320),(.794,.30,934),(.846,.2,411)):
                if t>=lag:
                    tt=t-lag
                    y+=amp*(low*.66+v*.23+sin(2*pi*f*tt)*.35)*exp(-tt*112)
        else:
            y=(.37*low+.16*sin(2*pi*(93+i*13)*t))*exp(-t*43)
            if t>.018:
                y+=(.10*v+.07*grit)*exp(-(t-.018)*70)
        yield y*min(1,n/16)*min(1,(duration-t)*85)


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    write('rain',rainfall(1732,8),rainfall(741,8))
    for group,count,seconds in [('step',4,.19),('pistol',3,.32),('impact',3,.20),('rack',1,.98)]:
        for i in range(count): write(f'{group}_{i+1}',cue(group,i,seconds))
