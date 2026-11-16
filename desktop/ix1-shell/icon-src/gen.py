# Generates the dock app icon SVGs in this directory; ./render.sh turns them into
# the 256px PNGs under qml/assets/icons.
import os, subprocess
OUT = os.path.dirname(os.path.abspath(__file__))
GEAR = ("M19.14 12.94c.04-.3.06-.61.06-.94s-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61"
 "l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54"
 "c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94"
 "l-2.39-.96c-.22-.08-.47 0-.59.22l-1.92 3.32c-.11.2-.07.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94"
 "s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96"
 "c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54"
 "c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61z"
 "M12 15.6a3.6 3.6 0 1 1 0-7.2 3.6 3.6 0 0 1 0 7.2z")

def squircle(cx=128, cy=128, r=115, n=4.0, steps=240):
    import math
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s_ = math.cos(t), math.sin(t)
        x = cx + r * math.copysign(abs(c) ** (2 / n), c)
        y = cy + r * math.copysign(abs(s_) ** (2 / n), s_)
        pts.append(f"{x:.2f} {y:.2f}")
    return "M" + "L".join(pts) + "Z"

TILE = squircle()

def lg(id, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return f'<linearGradient id="{id}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'

def rg(id, stops, cx=.5, cy=.5, r=.5, fx=None, fy=None):
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    f = f' fx="{fx}" fy="{fy}"' if fx is not None else ""
    return f'<radialGradient id="{id}" cx="{cx}" cy="{cy}" r="{r}"{f}>{s}</radialGradient>'

COMMON = (
    '<filter id="sh" x="-40%" y="-40%" width="180%" height="180%">'
    '<feDropShadow dx="0" dy="7" stdDeviation="7" flood-color="#000" flood-opacity="0.34"/></filter>'
    '<filter id="glow" x="-40%" y="-40%" width="180%" height="180%">'
    '<feGaussianBlur stdDeviation="6" result="b"/><feMerge><feMergeNode in="b"/>'
    '<feMergeNode in="SourceGraphic"/></feMerge></filter>'
    f'<clipPath id="tileclip"><path d="{TILE}"/></clipPath>'
    + lg("sheen", [(0, "#fff", .16), (.42, "#fff", 0)])
    + lg("shade", [(.6, "#000", 0), (1, "#000", .22)])
    + lg("rim", [(0, "#fff", .38), (.18, "#fff", .10), (.8, "#fff", .03), (1, "#fff", .12)])
)

def tile(top, bottom, glyph, defs="", k=1.0):
    glyph = f'<g transform="translate(128 128) scale({k}) translate(-128 -128)">{glyph}</g>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
            f'<defs>{COMMON}{lg("tg", [(0, top, 1), (1, bottom, 1)], .2, 0, .8, 1)}{defs}</defs>'
            f'<path d="{TILE}" fill="url(#tg)"/>'
            f'<path d="{TILE}" fill="url(#sheen)"/>'
            f'<path d="{TILE}" fill="url(#shade)"/>'
            f'<g clip-path="url(#tileclip)">{glyph}'
            f'<path d="{TILE}" fill="none" stroke="url(#rim)" stroke-width="5"/></g></svg>')

ICONS = {}
def tilek(k, *a, **kw):
    return tile(*a, k=k, **kw)

# Browser: glossy globe with an orbit ring (concept).
ICONS["browser"] = tilek(1.1, "#2BB6FF", "#0A63EC",
    '<g transform="rotate(-28 128 132)"><ellipse cx="128" cy="132" rx="96" ry="31" fill="none" '
    'stroke="url(#ringb)" stroke-width="11"/></g>'
    '<g filter="url(#sh)"><circle cx="126" cy="130" r="64" fill="url(#sph)"/></g>'
    '<g clip-path="url(#sphc)">'
    '<path d="M150 74c14 6 20 18 16 28-5 11-18 10-22 20-3 9 6 18 2 28-5 10-18 6-22-4-4-9 2-20-4-28-7-9-22-6-24-16-2-11 12-22 26-28 9-4 19-4 28 0z" fill="#0B5FD8" opacity=".55"/>'
    '<path d="M78 140c8-4 18 0 22 8s0 16 6 22c5 6 4 14-4 16-10 2-22-8-26-20-3-9-4-22 2-26z" fill="#0B5FD8" opacity=".5"/>'
    '<path d="M176 132c6 4 6 16 0 26-6 9-16 14-18 8-2-7 6-12 8-20 2-7 4-17 10-14z" fill="#0B5FD8" opacity=".5"/>'
    '<ellipse cx="100" cy="98" rx="46" ry="28" transform="rotate(-38 100 98)" fill="url(#cap)"/>'
    '<circle cx="126" cy="130" r="63" fill="none" stroke="#003C9E" stroke-opacity=".25" stroke-width="2"/></g>'
    '<g transform="rotate(-28 128 132)" clip-path="url(#front)" filter="url(#sh)"><ellipse cx="128" cy="132" rx="96" ry="31" '
    'fill="none" stroke="url(#ringf)" stroke-width="11"/></g>',
    rg("sph", [(0, "#7FDEFF", 1), (.45, "#2499FB", 1), (1, "#0757D6", 1)], .5, .5, .62, .32, .26)
    + rg("cap", [(0, "#fff", .85), (.55, "#fff", .35), (1, "#fff", 0)])
    + lg("ringb", [(0, "#CFEAFF", .9), (1, "#8CCBFF", .9)], 0, 0, 1, 0)
    + lg("ringf", [(0, "#FFFFFF", 1), (1, "#D7EDFF", 1)], 0, 0, 0, 1)
    + '<clipPath id="sphc"><circle cx="126" cy="130" r="64"/></clipPath>'
    + '<clipPath id="front"><rect x="0" y="132" width="256" height="200"/></clipPath>')

# Files: luminous folder on a deep navy tile (concept).
ICONS["files"] = tilek(1.2, "#0F4DB4", "#031A57",
    '<path d="M60 84a14 14 0 0 1 14-14h34a12 12 0 0 1 9 4l10 10h55a14 14 0 0 1 14 14v70H60z" fill="url(#back)"/>'
    '<rect x="80" y="88" width="100" height="56" rx="7" fill="#BCD4FF"/>'
    '<rect x="70" y="97" width="116" height="56" rx="7" fill="url(#paper)"/>'
    '<g filter="url(#sh)"><rect x="52" y="110" width="152" height="84" rx="14" fill="url(#front)"/></g>'
    '<rect x="52" y="110" width="152" height="84" rx="14" fill="url(#gloss)"/>'
    '<path d="M66 111.5h124" stroke="#fff" stroke-opacity=".55" stroke-width="2" stroke-linecap="round"/>',
    lg("back", [(0, "#58A2FF", 1), (1, "#2B6FE6", 1)])
    + lg("paper", [(0, "#FFFFFF", 1), (1, "#D5E5FF", 1)])
    + lg("front", [(0, "#6FB3FF", 1), (1, "#3B84F4", 1)])
    + lg("gloss", [(0, "#fff", .22), (.5, "#fff", 0)]))

# System/htop bars.
ICONS["bars"] = tilek(1.14, "#0F8A48", "#03381B",
    '<g filter="url(#sh)">'
    '<rect x="66" y="138" width="34" height="52" rx="11" fill="url(#bar)"/>'
    '<rect x="111" y="108" width="34" height="82" rx="11" fill="url(#bar)"/>'
    '<rect x="156" y="70" width="34" height="120" rx="11" fill="url(#bar)"/></g>'
    '<g fill="url(#barg)"><rect x="66" y="138" width="34" height="52" rx="11"/>'
    '<rect x="111" y="108" width="34" height="82" rx="11"/><rect x="156" y="70" width="34" height="120" rx="11"/></g>',
    lg("bar", [(0, "#C4FFDE", 1), (1, "#3BD683", 1)])
    + lg("barg", [(0, "#fff", .55), (.4, "#fff", 0)], 0, 0, 1, 0))

# Editor: document with pencil.
ICONS["editor"] = tilek(1.12, "#6C35E6", "#260A80",
    '<g filter="url(#sh)"><path d="M84 58h58l32 32v94a14 14 0 0 1-14 14H84a14 14 0 0 1-14-14V72a14 14 0 0 1 14-14z" fill="url(#doc)"/></g>'
    '<path d="M142 58v20a12 12 0 0 0 12 12h20z" fill="#9C84F6"/>'
    '<g stroke="#8F74EE" stroke-opacity=".8" stroke-width="8" stroke-linecap="round"><path d="M92 110h52"/><path d="M92 132h60"/><path d="M92 154h34"/></g>'
    '<g transform="rotate(45 160 140)" filter="url(#sh)">'
    '<rect x="146" y="70" width="28" height="92" rx="5" fill="url(#pen)"/>'
    '<rect x="146" y="64" width="28" height="18" rx="7" fill="#FF8DB6"/>'
    '<rect x="146" y="80" width="28" height="6" fill="#E6DBFF"/>'
    '<path d="M146 162h28l-14 26z" fill="#FFE2BE"/><path d="M155.6 179.8h8.8L160 188z" fill="#3A2A85"/>'
    '<rect x="150" y="86" width="6" height="76" fill="#fff" opacity=".55"/></g>',
    lg("doc", [(0, "#F5F0FF", 1), (1, "#B9A3FF", 1)])
    + lg("pen", [(0, "#EFE8FF", 1), (1, "#A68DFF", 1)], 0, 0, 1, 0))

# Terminal: recessed screen with glowing prompt.
ICONS["terminal"] = tilek(1.04, "#3E465C", "#141925",
    '<rect x="50" y="62" width="156" height="132" rx="20" fill="url(#scr)"/>'
    '<rect x="50.75" y="62.75" width="154.5" height="130.5" rx="19.25" fill="none" stroke="#fff" stroke-opacity=".10" stroke-width="1.5"/>'
    '<g filter="url(#glow)" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="15">'
    '<path d="M82 100l30 28-30 28" stroke="url(#chev)"/><path d="M126 158h46" stroke="#7DF3CC"/></g>',
    lg("scr", [(0, "#0A0E17", 1), (1, "#141A27", 1)])
    + lg("chev", [(0, "#FFFFFF", 1), (1, "#A9E9FF", 1)]))

# Settings: silver cog.
ICONS["settings"] = tilek(1.12, "#3F485E", "#111624",
    f'<g filter="url(#sh)"><path transform="translate(128 128) scale(7.4) translate(-12 -12)" fill-rule="evenodd" d="{GEAR}" fill="url(#steel)"/></g>'
    f'<path transform="translate(128 128) scale(7.4) translate(-12 -12)" fill-rule="evenodd" d="{GEAR}" fill="url(#gg)"/>'
    '<circle cx="128" cy="128" r="26.6" fill="none" stroke="url(#hub)" stroke-width="3"/>',
    lg("steel", [(0, "#EEF2FA", 1), (1, "#8794AE", 1)])
    + lg("gg", [(0, "#fff", .5), (.45, "#fff", 0)])
    + lg("hub", [(0, "#000", .35), (1, "#fff", .45)]))

# Software store: shopping bag with star.
ICONS["store"] = tilek(1.14, "#5A44F0", "#1F1188",
    '<path d="M100 106V90a28 28 0 0 1 56 0v16" fill="none" stroke="url(#hdl)" stroke-width="10" stroke-linecap="round"/>'
    '<g filter="url(#sh)"><path d="M76 100h104a8 8 0 0 1 8 8l-4 76a14 14 0 0 1-14 13H86a14 14 0 0 1-14-13l-4-76a8 8 0 0 1 8-8z" fill="url(#bag)"/></g>'
    '<path d="M76 100h104a8 8 0 0 1 8 8l-.6 10H68.6l-.6-10a8 8 0 0 1 8-8z" fill="url(#lip)"/>'
    '<path d="M128 124l7.6 15.4 17 2.5-12.3 12 2.9 16.9-15.2-8-15.2 8 2.9-16.9-12.3-12 17-2.5z" fill="url(#star)" stroke="url(#star)" stroke-width="3" stroke-linejoin="round"/>',
    lg("bag", [(0, "#ECE8FF", 1), (1, "#A393FF", 1)])
    + lg("hdl", [(0, "#E4DEFF", 1), (1, "#B6A9FF", 1)])
    + lg("star", [(0, "#6E55FF", 1), (1, "#3517C9", 1)])
    + lg("lip", [(0, "#fff", .75), (1, "#fff", .15)]))

# App grid / launcher.
cells = "".join(f'<rect x="{65 + c * 46}" y="{65 + r * 46}" width="34" height="34" rx="10"/>' for r in range(3) for c in range(3))
ICONS["grid"] = tilek(1.12, "#0FA79C", "#03434B",
    f'<g filter="url(#sh)" fill="url(#cell)">{cells}</g><g fill="url(#cellg)">{cells}</g>',
    lg("cell", [(0, "#CBFFF9", 1), (1, "#44DCCD", 1)])
    + lg("cellg", [(0, "#fff", .5), (.5, "#fff", 0)]))

# System monitor: display with pulse.
ICONS["monitor"] = tilek(1.12, "#E2385A", "#6A0522",
    '<g filter="url(#sh)"><rect x="108" y="168" width="40" height="18" fill="url(#stand)"/>'
    '<rect x="86" y="182" width="84" height="12" rx="6" fill="url(#stand)"/>'
    '<rect x="48" y="62" width="160" height="110" rx="18" fill="url(#bez)"/></g>'
    '<rect x="58" y="72" width="140" height="90" rx="10" fill="url(#glass)"/>'
    '<path d="M68 118h30l12-24 16 48 14-38 10 14h38" fill="none" stroke="#FFFFFF" stroke-width="9" '
    'stroke-linecap="round" stroke-linejoin="round" filter="url(#glow)"/>',
    lg("stand", [(0, "#FFC9D4", 1), (1, "#FF7F99", 1)])
    + lg("bez", [(0, "#FFDCE3", 1), (1, "#FF8AA2", 1)])
    + lg("glass", [(0, "#7A0F2C", 1), (1, "#3E0716", 1)]))

# btop: bold waveform.
ICONS["pulse"] = tilek(1.0, "#F28A1E", "#842703",
    '<path d="M44 130h40l18-44 26 88 22-70 14 26h48" fill="none" stroke="#3A0E00" stroke-opacity=".45" '
    'stroke-width="17" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 7)" filter="url(#blur)"/>'
    '<path d="M44 130h40l18-44 26 88 22-70 14 26h48" fill="none" stroke="url(#wave)" '
    'stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/>',
    lg("wave", [(0, "#FFF3E0", 1), (1, "#FFAE52", 1)])
    + '<filter id="blur"><feGaussianBlur stdDeviation="6"/></filter>')

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, svg in ICONS.items():
        open(f"{OUT}/{name}.svg", "w").write(svg)
