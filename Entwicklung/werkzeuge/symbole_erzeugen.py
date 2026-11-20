#!/usr/bin/env python3
"""Erzeugt die farbigen Wettersymbole (SVG) für das Tux-Wetter-Widget."""
import math
import pathlib

ZIEL = pathlib.Path(__file__).resolve().parent.parent / "package" / "contents" / "icons"

DEFS = """<defs>
  <radialGradient id="sonne" cx="0.4" cy="0.35" r="0.7">
    <stop offset="0" stop-color="#FFF3A0"/>
    <stop offset="0.55" stop-color="#FFC928"/>
    <stop offset="1" stop-color="#FF9F0A"/>
  </radialGradient>
  <linearGradient id="wolke" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="0.6" stop-color="#EEF2FA"/>
    <stop offset="1" stop-color="#C4CEE4"/>
  </linearGradient>
  <linearGradient id="wolkeHinten" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#D9DFEE"/>
    <stop offset="1" stop-color="#9EA9C6"/>
  </linearGradient>
  <linearGradient id="wolkeDunkel" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#B9C1D6"/>
    <stop offset="1" stop-color="#7A84A3"/>
  </linearGradient>
  <linearGradient id="tropfen" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#7FD3FF"/>
    <stop offset="1" stop-color="#1E8BFF"/>
  </linearGradient>
  <linearGradient id="mond" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#FFF6C8"/>
    <stop offset="1" stop-color="#F2C94C"/>
  </linearGradient>
  <linearGradient id="blitz" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFE45C"/>
    <stop offset="1" stop-color="#FF9F0A"/>
  </linearGradient>
</defs>"""

WOLKE = "M17 52 A9 9 0 0 1 17 34 A13 13 0 0 1 41 29 A11 11 0 0 1 51 52 Z"
# Blitz; liegt im Ausschnitt 24…41 × 39…62 (als Einzelbild für die Animation)
BLITZ = "M34 40 L25 52 L32 52 L28 61 L40 47 L33 47 L37 40 Z"


def svg(inhalt):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">\n{DEFS}\n{inhalt}\n</svg>\n'


def sonne(cx, cy, r, strahlen=True, scheibe=True):
    teile = []
    if strahlen:
        for i in range(8):
            w = math.radians(i * 45)
            x1, y1 = cx + math.cos(w) * (r + 4), cy + math.sin(w) * (r + 4)
            x2, y2 = cx + math.cos(w) * (r + 8.5), cy + math.sin(w) * (r + 8.5)
            teile.append(f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" '
                         f'stroke="#FFC23A" stroke-width="2.6" stroke-linecap="round"/>')
    if scheibe:
        teile.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#sonne)"/>')
    return "\n".join(teile)


def mond(dx=0, dy=0, k=1.0):
    return (f'<g transform="translate({dx} {dy}) scale({k})">'
            '<path d="M30 9 A20 20 0 1 0 54 37 A16 16 0 0 1 30 9 Z" fill="url(#mond)"/></g>')


def wolke(dx=0, dy=0, k=1.0, fuellung="wolke"):
    return (f'<g transform="translate({dx} {dy}) scale({k})">'
            f'<path d="{WOLKE}" transform="translate(0 1.6)" fill="#1B1450" opacity="0.18"/>'
            f'<path d="{WOLKE}" fill="url(#{fuellung})"/></g>')


def tropfen(x, y):
    return (f'<path d="M{x} {y - 4.5} Q{x + 2.8} {y - 0.8} {x + 2.8} {y + 0.8} '
            f'A2.8 2.8 0 0 1 {x - 2.8} {y + 0.8} Q{x - 2.8} {y - 0.8} {x} {y - 4.5} Z" fill="url(#tropfen)"/>')


def flocke(x, y):
    return f'<circle cx="{x}" cy="{y}" r="2.4" fill="#FFFFFF" stroke="#BFE3FF" stroke-width="0.8"/>'


SYMBOLE = {
    "clear-day": sonne(32, 32, 13),
    "clear-night": mond(-4, 0, 1.0),
    "partly-day": sonne(25, 25, 10) + wolke(2, 0),
    "partly-night": mond(-6, -4, 0.85) + wolke(2, 0),
    "cloudy": wolke(-6, -9, 0.9, "wolkeHinten") + wolke(3, 1),
    "fog": wolke(0, -8) + "".join(
        f'<line x1="{a}" y1="{y}" x2="{b}" y2="{y}" stroke="#DCE3F2" stroke-width="3" stroke-linecap="round"/>'
        for a, b, y in ((14, 46, 50), (20, 52, 57))),
    "drizzle": wolke(0, -9) + tropfen(24, 54) + tropfen(36, 54),
    "rain": wolke(0, -9, 1.0, "wolkeHinten") + tropfen(20, 53) + tropfen(31, 56) + tropfen(42, 53),
    "showers-day": sonne(25, 20, 9) + wolke(2, -8) + tropfen(24, 54) + tropfen(34, 56) + tropfen(44, 54),
    "showers-night": mond(-6, -9, 0.8) + wolke(2, -8) + tropfen(24, 54) + tropfen(34, 56) + tropfen(44, 54),
    "snow": wolke(0, -9) + flocke(20, 53) + flocke(32, 57) + flocke(44, 53),
    "thunder": wolke(0, -9, 1.0, "wolkeDunkel")
               + f'<path d="{BLITZ}" fill="url(#blitz)"/>',
}

# Nur die Wolke (ohne Tropfen/Flocken) – darunter fallen in QML animierte Tropfen bzw. Flocken
SYMBOLE.update({
    "drizzle-cloud": wolke(0, -9),
    "rain-cloud": wolke(0, -9, 1.0, "wolkeHinten"),
    "showers-day-cloud": sonne(25, 20, 9) + wolke(2, -8),
    "showers-night-cloud": mond(-6, -9, 0.8) + wolke(2, -8),
    "snow-cloud": wolke(0, -9),
    "thunder-cloud": wolke(0, -9, 1.0, "wolkeDunkel"),
    # Wolke vor der animierten Sonne
    "partly-day-front": wolke(2, 0),
    "showers-day-front": wolke(2, -8),
    # Mond einzeln (an seiner Stelle im jeweiligen Symbol) und Wolke davor
    "moon-clear": mond(-4, 0, 1.0),
    "moon-partly": mond(-6, -4, 0.85),
    "moon-showers": mond(-6, -9, 0.8),
    "partly-night-front": wolke(2, 0),
    "showers-night-front": wolke(2, -8),
    # „Bedeckt“ in zwei Ebenen, damit sich die Wolken gegeneinander bewegen können
    "cloudy-back": wolke(-6, -9, 0.9, "wolkeHinten"),
    "cloudy-front": wolke(3, 1),
})

# Sonnenstrahlen (um 0/0 zentriert, damit sie sich drehen lassen) für die drei Sonnengrössen
SONNE_EINZELN = {
    f"rays-{r}": f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-r - 10} {-r - 10} {2 * r + 20} {2 * r + 20}">'
                 + sonne(0, 0, r, scheibe=False) + '</svg>\n'
    for r in (13, 10, 9)
}
SONNE_EINZELN["moon-glow"] = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
    '<defs><radialGradient id="g"><stop offset="0" stop-color="#FFF1B0" stop-opacity="0.7"/>'
    '<stop offset="1" stop-color="#FFF1B0" stop-opacity="0"/></radialGradient></defs>'
    '<circle cx="5" cy="5" r="5" fill="url(#g)"/></svg>\n')
SONNE_EINZELN["star"] = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
    '<path d="M5 0 Q5.6 4.4 10 5 Q5.6 5.6 5 10 Q4.4 5.6 0 5 Q4.4 4.4 5 0 Z" fill="#FFF8D6"/></svg>\n')
SONNE_EINZELN["sun-disc"] = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 20 20">'
                             + DEFS + '<circle cx="0" cy="0" r="10" fill="url(#sonne)"/></svg>\n')


# Kleine Symbole für Wind, Regenwahrscheinlichkeit (Schirm) und Luftfeuchtigkeit (Tropfen) in der
# Kopfzeile sowie die animierte Flocke
EXTRA = {
    "umbrella": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
                '<defs><linearGradient id="t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FD3FF"/>'
                '<stop offset="1" stop-color="#1E8BFF"/></linearGradient></defs>'
                '<path d="M12 12.5 V18.5 A2 2 0 0 1 8 18.5" fill="none" stroke="#FFFFFF" stroke-width="1.8" '
                'stroke-linecap="round"/>'
                '<path d="M2.5 12.5 A9.5 9.5 0 0 1 21.5 12.5 Q19.1 10.6 16.75 12.5 Q14.4 10.6 12 12.5 '
                'Q9.6 10.6 7.25 12.5 Q4.9 10.6 2.5 12.5 Z" fill="url(#t)"/></svg>\n',
    "wind": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" '
            'stroke-width="1.8" stroke-linecap="round">'
            '<path d="M3 9 H14 A3 3 0 1 0 11 6"/><path d="M3 13 H18 A3 3 0 1 1 15 16"/>'
            '<path d="M3 17 H9"/></svg>\n',
    "drop": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
            '<defs><linearGradient id="t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FD3FF"/>'
            '<stop offset="1" stop-color="#1E8BFF"/></linearGradient></defs>'
            '<path d="M12 3 Q18 10.5 18 14.5 A6 6 0 0 1 6 14.5 Q6 10.5 12 3 Z" fill="url(#t)"/></svg>\n',
    "bolt": f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="24 39 17 23">{DEFS}<path d="{BLITZ}" fill="url(#blitz)"/></svg>\n',
    "bolt-glow": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
                 '<defs><radialGradient id="g"><stop offset="0" stop-color="#FFE45C" stop-opacity="0.75"/>'
                 '<stop offset="1" stop-color="#FFE45C" stop-opacity="0"/></radialGradient></defs>'
                 '<circle cx="5" cy="5" r="5" fill="url(#g)"/></svg>\n',
    "flake": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8">'
             '<circle cx="4" cy="4" r="3.2" fill="#FFFFFF" stroke="#BFE3FF" stroke-width="1.1"/></svg>\n',
}

if __name__ == "__main__":
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, inhalt in SYMBOLE.items():
        (ZIEL / f"{name}.svg").write_text(svg(inhalt))
    for name, inhalt in {**EXTRA, **SONNE_EINZELN}.items():
        (ZIEL / f"{name}.svg").write_text(inhalt)
    print(f"{len(SYMBOLE) + len(EXTRA) + len(SONNE_EINZELN)} Symbole nach {ZIEL} geschrieben")
