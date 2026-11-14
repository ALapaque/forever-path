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

out = sys.argv[1]
write_tga(out + "/arrow.tga", 64, 64, arrow)
write_tga(out + "/glow.tga", 128, 64, glow)
print("ok")
