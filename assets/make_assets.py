#!/usr/bin/env python3
"""Genereaza vizualurile din README (light + dark).

Cand termin un lab, schimb STATUS mai jos si rulez:
    python3 assets/make_assets.py
"""
from pathlib import Path

OUT = Path(__file__).parent

# stare: done | almost | todo | next
STATUS = [
    ("00", "Setup", "Foundry pe Mac", "done", "gata"),
    ("01", "Wallets", "& RPC", "todo", "de recuperat"),
    ("02", "Solidity", "& Sepolia setup", "todo", "de recuperat"),
    ("03", "Fidelity", "points", "todo", "de recuperat"),
    ("04", "Contract", "interaction", "almost", "7/8 · Sepolia"),
    ("05", "ERC-20", "tokens", "done", "gata"),
    ("06", "Ether &", "re-entrancy", "done", "gata"),
    ("07", "Shop", "dApp", "done", "gata"),
    ("08", "Lab 8", "", "next", "urmează"),
]
UPDATED = "25 nov 2026"

THEMES = {
    "light": dict(
        paper="#f4f3f0", ink="#141414", graphite="#66645f", hairline="#d6d2cb", navy="#1f2a48",
        sky="#7fb0ee", peach="#f3c6a8", blush="#efc9cf", lilac="#b9a6e6",
        glass="#faf9f6", glass_o=".66", line="#141414", line_o=".08", orb_o="1",
        ok="#2c6649", ok_bg="#2c6649", soon="#855712", soon_bg="#855712", tint_o=".1",
        on_navy="#f4f3f0",
    ),
    "dark": dict(
        paper="#141414", ink="#efede8", graphite="#a8a59e", hairline="#3a3936", navy="#9fb2e0",
        sky="#7fb0ee", peach="#f3c6a8", blush="#efc9cf", lilac="#b9a6e6",
        glass="#1e1d1c", glass_o=".72", line="#efede8", line_o=".1", orb_o=".42",
        ok="#93d3b0", ok_bg="#93d3b0", soon="#e9c27e", soon_bg="#e9c27e", tint_o=".14",
        on_navy="#141414",
    ),
}

DISPLAY = "'Playfair Display', 'Iowan Old Style', Georgia, 'Times New Roman', serif"
SANS = "'Hanken Grotesk', -apple-system, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
MONO = "'DM Mono', 'SF Mono', ui-monospace, Menlo, Consolas, monospace"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def defs(t, w, h):
    return f"""  <defs>
    <radialGradient id="orbA" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{t['sky']}"/>
      <stop offset="50%" stop-color="{t['sky']}" stop-opacity=".85"/>
      <stop offset="74%" stop-color="{t['peach']}" stop-opacity=".85"/>
      <stop offset="96%" stop-color="{t['peach']}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="orbB" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{t['lilac']}"/>
      <stop offset="55%" stop-color="{t['lilac']}" stop-opacity=".8"/>
      <stop offset="80%" stop-color="{t['sky']}" stop-opacity=".6"/>
      <stop offset="98%" stop-color="{t['sky']}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="orbC" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{t['peach']}"/>
      <stop offset="55%" stop-color="{t['peach']}" stop-opacity=".8"/>
      <stop offset="80%" stop-color="{t['blush']}" stop-opacity=".7"/>
      <stop offset="98%" stop-color="{t['blush']}" stop-opacity="0"/>
    </radialGradient>
    <filter id="blur" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{w + 400}" height="{h + 400}">
      <feGaussianBlur stdDeviation="38"/>
    </filter>
    <clipPath id="frame"><rect width="{w}" height="{h}" rx="28"/></clipPath>
  </defs>"""


def svg(w, h, label, body, t):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" '
        f'role="img" aria-label="{esc(label)}">\n{defs(t, w, h)}\n'
        f'  <g clip-path="url(#frame)">\n  <rect width="{w}" height="{h}" fill="{t["paper"]}"/>\n{body}\n  </g>\n</svg>\n'
    )


def glass(x, y, w, h, t, rx=20, extra=""):
    return (
        f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{t["glass"]}" '
        f'fill-opacity="{t["glass_o"]}" stroke="{t["line"]}" stroke-opacity="{t["line_o"]}" {extra}/>\n'
    )


# ---------------------------------------------------------------- banner
def banner(t):
    w, h = 1280, 420
    b = f"""  <g opacity="{t['orb_o']}" filter="url(#blur)">
    <circle cx="930" cy="170" r="210" fill="url(#orbA)"/>
    <circle cx="1170" cy="400" r="150" fill="url(#orbB)"/>
    <circle cx="610" cy="470" r="120" fill="url(#orbC)"/>
  </g>
  <text x="120" y="118" font-family="{MONO}" font-size="22" letter-spacing=".9" fill="{t['graphite']}">fmi · an 3 · blockchain labs</text>
  <text font-family="{DISPLAY}" font-size="96" letter-spacing="-1.9" fill="{t['ink']}">
    <tspan x="120" y="228">Blockchain</tspan>
    <tspan x="120" y="322" font-style="italic" fill="{t['navy']}">labs.</tspan>
  </text>
"""
    # lantul de blocuri: un bloc pentru fiecare lab
    x0, y0, s, gap = 672, 300, 46, 18
    chain = ""
    for i, (num, *_rest, state, _note) in enumerate(STATUS[:8]):
        x = x0 + i * (s + gap)
        if i:
            chain += (f'  <line x1="{x - gap}" y1="{y0 + s / 2}" x2="{x}" y2="{y0 + s / 2}" '
                      f'stroke="{t["ink"]}" stroke-opacity=".35" stroke-width="2"/>\n')
        if state == "done":
            fill, fo, txt, stroke = t["navy"], "1", t["on_navy"], "none"
        elif state == "almost":
            fill, fo, txt, stroke = t["peach"], ".95", "#141414", "none"
        else:
            fill, fo, txt, stroke = t["glass"], t["glass_o"], t["graphite"], t["ink"]
        so = ".25" if stroke != "none" else "0"
        chain += (f'  <rect x="{x}" y="{y0}" width="{s}" height="{s}" rx="11" fill="{fill}" fill-opacity="{fo}" '
                  f'stroke="{stroke}" stroke-opacity="{so}" stroke-width="1.5"/>\n')
        chain += (f'  <text x="{x + s / 2}" y="{y0 + s / 2 + 5}" text-anchor="middle" font-family="{MONO}" '
                  f'font-size="15" fill="{txt}">{num}</text>\n')
    b += chain
    return svg(w, h, "Blockchain labs, FMI anul 3", b, t)


# ---------------------------------------------------------------- progress
def progress(t):
    w, h = 1280, 400
    b = f"""  <g opacity="{t['orb_o']}" filter="url(#blur)">
    <circle cx="1130" cy="60" r="170" fill="url(#orbA)"/>
    <circle cx="140" cy="390" r="150" fill="url(#orbB)"/>
  </g>
"""
    b += glass(40, 40, w - 80, h - 80, t, rx=24)
    b += (f'  <text x="88" y="98" font-family="{MONO}" font-size="17" letter-spacing=".7" '
          f'fill="{t["graphite"]}">unde sunt · {UPDATED}</text>\n')
    done = sum(1 for s in STATUS if s[3] == "done" and s[0] != "00")
    almost = sum(1 for s in STATUS if s[3] == "almost")
    b += (f'  <text x="88" y="142" font-family="{DISPLAY}" font-size="36" fill="{t["ink"]}">'
          f'{done + almost} din 7 labs rezolvate, <tspan font-style="italic" fill="{t["navy"]}">'
          f'{almost} aproape gata.</tspan></text>\n')

    n = len(STATUS)
    left, right, ty = 120, w - 120, 232
    step = (right - left) / (n - 1)
    xs = [left + i * step for i in range(n)]
    filled = {"done", "almost"}
    for i in range(n - 1):
        a, c = STATUS[i][3], STATUS[i + 1][3]
        if a in filled and c in filled:
            b += (f'  <line x1="{xs[i]}" y1="{ty}" x2="{xs[i + 1]}" y2="{ty}" stroke="{t["navy"]}" '
                  f'stroke-width="3" stroke-linecap="round"/>\n')
        else:
            b += (f'  <line x1="{xs[i]}" y1="{ty}" x2="{xs[i + 1]}" y2="{ty}" stroke="{t["ink"]}" '
                  f'stroke-opacity=".22" stroke-width="2" stroke-dasharray="2 9" stroke-linecap="round"/>\n')

    for x, (num, l1, l2, state, note) in zip(xs, STATUS):
        if state == "done":
            b += f'  <circle cx="{x}" cy="{ty}" r="19" fill="{t["navy"]}"/>\n'
            b += (f'  <path d="M{x - 7} {ty + 0.5} l5 5 l10 -11" fill="none" stroke="{t["on_navy"]}" '
                  f'stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>\n')
            nc, pill, pill_c = t["ink"], t["ok_bg"], t["ok"]
        elif state == "almost":
            b += f'  <circle cx="{x}" cy="{ty}" r="19" fill="{t["paper"]}" stroke="{t["navy"]}" stroke-width="3"/>\n'
            b += f'  <path d="M{x} {ty - 11} A11 11 0 0 1 {x} {ty + 11} Z" fill="{t["navy"]}"/>\n'
            nc, pill, pill_c = t["ink"], t["soon_bg"], t["soon"]
        elif state == "next":
            b += (f'  <circle cx="{x}" cy="{ty}" r="19" fill="{t["lilac"]}" fill-opacity=".25" stroke="{t["lilac"]}" '
                  f'stroke-width="2.5" stroke-dasharray="4 4"/>\n')
            b += f'  <circle cx="{x}" cy="{ty}" r="5" fill="{t["lilac"]}"/>\n'
            nc, pill, pill_c = t["graphite"], t["lilac"], t["navy"]
        else:
            b += (f'  <circle cx="{x}" cy="{ty}" r="17" fill="{t["paper"]}" stroke="{t["ink"]}" '
                  f'stroke-opacity=".3" stroke-width="2"/>\n')
            nc, pill, pill_c = t["graphite"], t["ink"], t["graphite"]
        b += (f'  <text x="{x}" y="{ty - 36}" text-anchor="middle" font-family="{MONO}" font-size="15" '
              f'fill="{nc}">{num}</text>\n')
        b += (f'  <text x="{x}" y="{ty + 50}" text-anchor="middle" font-family="{SANS}" font-size="16" '
              f'font-weight="600" fill="{nc}">{esc(l1)}</text>\n')
        if l2:
            b += (f'  <text x="{x}" y="{ty + 70}" text-anchor="middle" font-family="{SANS}" font-size="14" '
                  f'fill="{t["graphite"]}">{esc(l2)}</text>\n')
        pw = 11 + len(note) * 7.6
        b += (f'  <rect x="{x - pw / 2}" y="{ty + 84}" width="{pw}" height="24" rx="12" fill="{pill}" '
              f'fill-opacity="{t["tint_o"] if state != "next" else ".22"}"/>\n')
        b += (f'  <text x="{x}" y="{ty + 100.5}" text-anchor="middle" font-family="{MONO}" font-size="12.5" '
              f'fill="{pill_c}">{esc(note)}</text>\n')
    return svg(w, h, "Progresul la laboratoarele de Blockchain", b, t)


# ---------------------------------------------------------------- story
CARDS = [
    ("lab 03", "Punctele de", "fidelitate.", ["FidelityPoints + Catalog", "addPoints, spendPoints", "punctul de plecare"], "start"),
    ("lab 04", "Contractele", "vorbesc.", ["redeem: puncte → produse", "try/catch, events, errors", "packing: addProduct −27% gas"], "almost"),
    ("lab 05", "Punctele devin", "token.", ["ERC-20 FPT cu OpenZeppelin", "badge ERC-721 în BadgeShop", "FeeToken: 1% prin _update"], "done"),
    ("lab 07", "Ajung în", "browser.", ["React + ethers v6 + MetaMask", "sold live din events", "spendPoints, fără leaks"], "almost"),
]


def story(t):
    w, h = 1280, 640
    b = f"""  <g opacity="{t['orb_o']}" filter="url(#blur)">
    <circle cx="160" cy="80" r="160" fill="url(#orbC)"/>
    <circle cx="1150" cy="560" r="190" fill="url(#orbA)"/>
    <circle cx="640" cy="640" r="140" fill="url(#orbB)"/>
  </g>
  <text x="64" y="84" font-family="{MONO}" font-size="17" letter-spacing=".7" fill="{t['graphite']}">povestea unui contract · lab 03 → 07</text>
  <text x="64" y="132" font-family="{DISPLAY}" font-size="38" fill="{t['ink']}">Același <tspan font-style="italic" fill="{t['navy']}">FidelityPoints</tspan>, lab după lab.</text>
"""
    cw, ch, y = 266, 236, 178
    gap = (w - 128 - 4 * cw) / 3
    xs = [64 + i * (cw + gap) for i in range(4)]
    for i, (lab, t1, t2, lines, state) in enumerate(CARDS):
        x = xs[i]
        dash = 'stroke-dasharray="5 6"' if state == "start" else ""
        b += glass(x, y, cw, ch, t, rx=22, extra=dash)
        b += f'  <text x="{x + 24}" y="{y + 40}" font-family="{MONO}" font-size="14" fill="{t["graphite"]}">{lab}</text>\n'
        dot = {"done": t["ok"], "almost": t["soon"], "start": t["graphite"]}[state]
        b += f'  <circle cx="{x + cw - 28}" cy="{y + 35}" r="6" fill="{dot}" fill-opacity="{".5" if state == "start" else "1"}"/>\n'
        b += (f'  <text font-family="{DISPLAY}" font-size="29" fill="{t["ink"]}"><tspan x="{x + 24}" y="{y + 84}">{esc(t1)}</tspan>'
              f'<tspan x="{x + 24}" y="{y + 118}" font-style="italic" fill="{t["navy"]}">{esc(t2)}</tspan></text>\n')
        for j, ln in enumerate(lines):
            ly = y + 156 + j * 25
            b += f'  <circle cx="{x + 28}" cy="{ly - 5}" r="2.5" fill="{t["graphite"]}"/>\n'
            b += f'  <text x="{x + 40}" y="{ly}" font-family="{SANS}" font-size="15" fill="{t["ink"]}" fill-opacity=".86">{esc(ln)}</text>\n'
        if i < 3:
            ax1, ax2, ay = x + cw + 8, x + cw + gap - 8, y + ch / 2
            b += (f'  <line x1="{ax1}" y1="{ay}" x2="{ax2 - 4}" y2="{ay}" stroke="{t["navy"]}" stroke-width="2.2" '
                  f'stroke-linecap="round"/>\n'
                  f'  <path d="M{ax2 - 10} {ay - 6} L{ax2} {ay} L{ax2 - 10} {ay + 6}" fill="none" stroke="{t["navy"]}" '
                  f'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>\n')

    # ocolul: lab 06
    ox, oy, ow, oh = xs[1] + cw / 2 + 40, 474, 640, 116
    b += (f'  <path d="M{xs[1] + cw / 2} {y + ch + 6} C{xs[1] + cw / 2} {oy + 20}, {ox - 40} {oy + oh / 2}, {ox - 6} {oy + oh / 2}" '
          f'fill="none" stroke="{t["lilac"]}" stroke-width="2.2" stroke-dasharray="3 7" stroke-linecap="round"/>\n')
    b += glass(ox, oy, ow, oh, t, rx=22)
    b += f'  <text x="{ox + 24}" y="{oy + 38}" font-family="{MONO}" font-size="14" fill="{t["graphite"]}">lab 06 · ocol</text>\n'
    b += f'  <circle cx="{ox + ow - 28}" cy="{oy + 33}" r="6" fill="{t["ok"]}"/>\n'
    b += (f'  <text x="{ox + 24}" y="{oy + 78}" font-family="{DISPLAY}" font-size="27" fill="{t["ink"]}">Ether și '
          f'<tspan font-style="italic" fill="{t["navy"]}">securitate.</tspan></text>\n')
    lx = ox + 310
    for j, ln in enumerate(["receive / fallback", "re-entrancy + nonReentrant", "pull over push: 230k vs 427k gas"]):
        ly = oy + 40 + j * 25
        b += f'  <circle cx="{lx}" cy="{ly - 5}" r="2.5" fill="{t["graphite"]}"/>\n'
        b += f'  <text x="{lx + 12}" y="{ly}" font-family="{SANS}" font-size="15" fill="{t["ink"]}" fill-opacity=".86">{esc(ln)}</text>\n'

    # legenda, in stanga ocolului
    legend = [("gata", t["ok"], "1"), ("aproape", t["soon"], "1"), ("primit, de recuperat", t["graphite"], ".5")]
    for k, (name, col, o) in enumerate(legend):
        ly = oy + 28 + k * 30
        b += f'  <circle cx="70" cy="{ly - 4}" r="6" fill="{col}" fill-opacity="{o}"/>\n'
        b += f'  <text x="84" y="{ly}" font-family="{MONO}" font-size="13" fill="{t["graphite"]}">{name}</text>\n'
    return svg(w, h, "Povestea contractului FidelityPoints de la Lab 3 la Lab 7", b, t)


if __name__ == "__main__":
    for name, fn in (("banner", banner), ("progress", progress), ("story", story)):
        for theme, t in THEMES.items():
            (OUT / f"{name}-{theme}.svg").write_text(fn(t), encoding="utf-8")
    print("ok:", sorted(p.name for p in OUT.glob("*.svg")))
