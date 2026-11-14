"""Génère les textures TGA de ForeverPath (flèche, halo). Usage : python3 make_media.py <dossier Media>"""
import math, struct, sys

def write_tga(path, w, h, pixel):
    # TGA 32 bits non compressé, origine en haut à gauche
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8 | 0x20)
    data = bytearray()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixel(x, y)
            data += bytes((b, g, r, a))
    open(path, "wb").write(hdr + data)

def clamp(v): return max(0, min(255, int(v)))

def arrow(x, y, n=64):
    # flèche pointant vers le haut, blanche (teintée en jeu), bord adouci
    u, v = (x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5   # -0.5..0.5, v vers le bas
    # triangle de pointe : sommet (0,-0.46), base y=-0.02, demi-largeur 0.40
    def inside(u, v):
        if -0.46 <= v <= -0.02:
            half = (v + 0.46) / 0.44 * 0.40
            return abs(u) <= half
        if -0.02 < v <= 0.44:
            return abs(u) <= 0.15
        return False
    s = 0
    for dx in (-0.25, 0.25):
        for dy in (-0.25, 0.25):
            s += inside(u + dx / n, v + dy / n)
    a = s / 4
    shade = 255 - (v + 0.5) * 70
    return clamp(shade), clamp(shade), clamp(shade), clamp(a * 255)

def glow(x, y, w=128, h=64):
    u, v = (x + 0.5) / w - 0.5, (y + 0.5) / h - 0.5
    d = math.sqrt((u / 0.5) ** 2 + (v / 0.5) ** 2)
    a = max(0.0, 1 - d) ** 1.6
    return 255, 255, 255, clamp(a * 255)

def dot(x, y, n=32):
    # disque plein (bouton d'enregistrement), blanc, bord adouci
    u, v = (x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5
    d = math.hypot(u, v)
    a = max(0.0, min(1.0, (0.36 - d) * n))
    return 255, 255, 255, clamp(a * 255)

def pin(x, y, n=32):
    # épingle de carte : cercle en haut + pointe en bas, trou au centre
    u, v = (x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5
    cy = -0.12
    d = math.hypot(u, v - cy)
    inside = d <= 0.28
    if not inside and v > cy:
        # pointe : triangle sous le cercle
        half = 0.26 * (1 - (v - cy) / 0.58)
        inside = v <= 0.46 and abs(u) <= half
    if d <= 0.1:
        inside = False
    return 255, 255, 255, 255 if inside else 0

def chevron(x, y, n=16):
    # petit chevron » pour les étapes suivantes
    u, v = (x + 0.5) / n, (y + 0.5) / n
    def stroke(off):
        return abs((u - off) - (0.5 - abs(v - 0.5)) * 0.8) < 0.09
    on = (stroke(0.15) or stroke(0.45)) and 0.15 < v < 0.85
    return 255, 255, 255, 255 if on else 0

def beam(x, y, w=32, h=256):
    # colonne de lumière : douce sur les bords, s'estompe vers le haut
    u = (x + 0.5) / w - 0.5
    v = (y + 0.5) / h            # 0 en haut, 1 en bas
    across = max(0.0, 1 - (abs(u) / 0.5) ** 1.5)
    along = v ** 1.8
    core = max(0.0, 1 - abs(u) / 0.12) * 0.6
    a = min(1.0, across * along + core * along)
    return 255, 255, 255, clamp(a * 255)

out = sys.argv[1]
write_tga(out + "/arrow.tga", 64, 64, arrow)
write_tga(out + "/glow.tga", 128, 64, glow)
write_tga(out + "/dot.tga", 32, 32, dot)
write_tga(out + "/pin.tga", 32, 32, pin)
write_tga(out + "/chevron.tga", 16, 16, chevron)
write_tga(out + "/beam.tga", 32, 256, beam)
print("ok")
