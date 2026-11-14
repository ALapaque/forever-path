"""Cuisson du terrain ForeverPath : fichiers ADT bruts (export « Raw » de wow.export) -> zones praticables.

Pour chaque tuile, on lit les morceaux de terrain (MCNK) : hauteurs (MCVT), trous, et l'eau (MH2O).
On en déduit une grille de cases de 8,33 yards (4 x 4 par morceau, 64 x 64 par tuile) :
    0 = infranchissable (pente > 50°, trou dans le terrain, lave / slime)
    1 = sol praticable
    2 = eau (on nage : plus lent)
La grille est compressée (RLE) et écrite dans un addon de données chargé à la demande :
    ForeverPath_Terrain/Data_<continent>.lua

Usage :
    python3 tools/bake_terrain.py --out ForeverPath_Terrain --map Kalimdor=1 <dossier Kalimdor> --map Azeroth=0 <dossier Azeroth>
    (option --preview : écrit aussi un PNG d'aperçu par continent)
Les fichiers sont lus comme des données binaires ; rien n'est exécuté.
"""
import argparse, glob, math, os, re, struct, sys

TILE = 51200 / 3 / 32          # 533.333 yards
CHUNK = TILE / 16              # 33.333
UNIT = CHUNK / 8               # 4.1667 (un « quad »)
CELL = CHUNK / 4               # 8.333  (case de la grille)
ORIGIN = 32 * TILE
CELLS = 64                     # cases par côté de tuile
MAX_SLOPE = math.tan(math.radians(50))
SWIM_DEPTH = 1.5               # yards d'eau au-dessus du sol pour nager
LAVA_TYPES = {3, 4}            # LiquidType : magma, slime

MCNK, MCVT, MH2O, MVER = 0x4D434E4B, 0x4D435654, 0x4D48324F, 0x4D564552


def chunks(buf, start=0, end=None):
    end = len(buf) if end is None else end
    o = start
    while o + 8 <= end:
        cid, size = struct.unpack_from("<II", buf, o)
        yield cid, o + 8, size
        o += 8 + size


def parse_mh2o(buf, base, size):
    """-> {chunk_index: [(liquidType, [[height or None]*9]*9 (sommets), exists 8x8)]}"""
    out = {}
    for i in range(256):
        off_inst, layers, _attr = struct.unpack_from("<III", buf, base + i * 12)
        if not layers:
            continue
        lst = []
        for j in range(layers):
            p = base + off_inst + j * 24
            ltype, lobj, hmin, hmax, xo, yo, w, h, off_bmp, off_vtx = struct.unpack_from("<HHffBBBBII", buf, p)
            if lobj <= 41:
                xo, yo, w, h = 0, 0, 8, 8
            exists = [[False] * 8 for _ in range(8)]
            if off_bmp:
                nbits = w * h
                bm = buf[base + off_bmp: base + off_bmp + (nbits + 7) // 8]
                k = 0
                for yy in range(h):
                    for xx in range(w):
                        if bm[k >> 3] >> (k & 7) & 1:
                            exists[yo + yy][xo + xx] = True
                        k += 1
            else:
                for yy in range(h):
                    for xx in range(w):
                        exists[yo + yy][xo + xx] = True
            heights = [[None] * 9 for _ in range(9)]
            nv = (w + 1) * (h + 1)
            level = (hmin + hmax) / 2 if not (hmin == 0 and hmax == 0) else 0.0
            vals = None
            if off_vtx and lobj not in (2,):         # format 2 (océan) : profondeur seule
                try:
                    vals = struct.unpack_from("<%df" % nv, buf, base + off_vtx)
                except struct.error:
                    vals = None
            for yy in range(h + 1):
                for xx in range(w + 1):
                    v = vals[yy * (w + 1) + xx] if vals else level
                    if not (isinstance(v, float) and abs(v) < 1e6):
                        v = level
                    heights[yo + yy][xo + xx] = v
            lst.append((ltype, heights, exists))
        out[i] = lst
    return out


def parse_adt(path):
    """-> liste de morceaux : dict(pos=(X, Y, Z), h=[145 hauteurs absolues], holes=fn(qy,qx), index)"""
    buf = open(path, "rb").read()
    result, liquids, idx = [], {}, 0
    for cid, o, size in chunks(buf):
        if cid == MVER:
            ver = struct.unpack_from("<I", buf, o)[0]
            if ver != 18:
                raise ValueError("%s : version ADT inattendue %d" % (path, ver))
        elif cid == MH2O:
            liquids = parse_mh2o(buf, o, size)
        elif cid == MCNK:
            flags = struct.unpack_from("<I", buf, o)[0]
            hi = buf[o + 20: o + 28]
            lo = struct.unpack_from("<H", buf, o + 60)[0]
            px, py, pz = struct.unpack_from("<fff", buf, o + 104)
            verts = None
            for scid, so, ssize in chunks(buf, o + 128, o + size):
                if scid == MCVT:
                    verts = struct.unpack_from("<145f", buf, so)
            if verts is None:
                idx += 1
                continue
            if flags & 0x10000:
                holes = (lambda hb: (lambda qy, qx: bool(hb[qy] >> qx & 1)))(hi)
            else:
                holes = (lambda l: (lambda qy, qx: bool(l >> ((qy // 2) * 4 + qx // 2) & 1)))(lo)
            result.append({"pos": (px, py, pz), "h": [pz + v for v in verts], "holes": holes, "index": idx})
            idx += 1
    for c in result:
        c["liquid"] = liquids.get(c["index"], [])
    return result


def outer(h, r, c):
    """sommet extérieur (ligne r 0..8, colonne c 0..8) du tableau MCVT (17 lignes alternées 9/8)"""
    return h[r * 17 + c]


def inner(h, r, c):
    return h[r * 17 + 9 + c]


def classify_chunk(ch):
    """-> grille 4x4 de valeurs (0/1/2) pour un morceau"""
    h = ch["h"]
    steep = [[False] * 8 for _ in range(8)]
    for qy in range(8):
        for qx in range(8):
            a, b = outer(h, qy, qx), outer(h, qy, qx + 1)
            c, d = outer(h, qy + 1, qx), outer(h, qy + 1, qx + 1)
            m = inner(h, qy, qx)
            g = max(abs(a - b), abs(c - d), abs(a - c), abs(b - d)) / UNIT
            g2 = max(abs(m - a), abs(m - b), abs(m - c), abs(m - d)) / (UNIT * 0.7071)
            steep[qy][qx] = max(g, g2) > MAX_SLOPE
    water = [[0] * 8 for _ in range(8)]      # 0 sec, 1 nage, 2 lave
    for ltype, heights, exists in ch["liquid"]:
        for qy in range(8):
            for qx in range(8):
                if not exists[qy][qx]:
                    continue
                ws = [heights[qy + dy][qx + dx] for dy in (0, 1) for dx in (0, 1) if heights[qy + dy][qx + dx] is not None]
                if not ws:
                    continue
                surface = sum(ws) / len(ws)
                ground = (outer(h, qy, qx) + outer(h, qy, qx + 1) + outer(h, qy + 1, qx) + outer(h, qy + 1, qx + 1)) / 4
                if ltype in LAVA_TYPES:
                    water[qy][qx] = 2
                elif surface - ground > SWIM_DEPTH:
                    water[qy][qx] = max(water[qy][qx], 1)
    grid = [[1] * 4 for _ in range(4)]
    for cy in range(4):
        for cx in range(4):
            quads = [(cy * 2 + dy, cx * 2 + dx) for dy in (0, 1) for dx in (0, 1)]
            nh = sum(1 for q in quads if ch["holes"](*q))
            ns = sum(1 for q in quads if steep[q[0]][q[1]])
            nl = sum(1 for q in quads if water[q[0]][q[1]] == 2)
            nw = sum(1 for q in quads if water[q[0]][q[1]] == 1)
            if nh >= 2 or nl >= 2:
                v = 0
            elif nw >= 2:
                v = 2                     # on nage : la pente du fond ne compte pas
            elif ns >= 2:
                v = 0
            else:
                v = 1
            grid[cy][cx] = v
    return grid


B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


def rle(cells):
    """4096 valeurs -> chaîne : par série, une lettre (a/b/c = 0/1/2) + longueur sur 2 caractères base 62"""
    out, i, n = [], 0, len(cells)
    while i < n:
        v, j = cells[i], i
        while j < n and cells[j] == v and j - i < 3843:
            j += 1
        L = j - i
        out.append("abc"[v] + B62[L // 62] + B62[L % 62])
        i = j
    return "".join(out)


def bake(maps, out_dir, preview=False):
    os.makedirs(out_dir, exist_ok=True)
    summary = []
    for name, cont, folder in maps:
        files = [f for f in glob.glob(os.path.join(folder, "*.adt"))
                 if re.search(r"_\d+_\d+\.adt$", f, re.I)]      # fichiers « racine » seulement
        tiles = {}
        bad = 0
        for f in sorted(files):
            try:
                for ch in parse_adt(f):
                    X, Y, _ = ch["pos"]
                    gr0 = round((ORIGIN - X) / CELL)
                    gc0 = round((ORIGIN - Y) / CELL)
                    g = classify_chunk(ch)
                    for cy in range(4):
                        for cx in range(4):
                            gr, gc = gr0 + cy, gc0 + cx
                            key = (gr // CELLS, gc // CELLS)
                            t = tiles.setdefault(key, [1] * (CELLS * CELLS))
                            t[(gr % CELLS) * CELLS + (gc % CELLS)] = g[cy][cx]
            except Exception as e:      # tuile illisible : on continue
                bad += 1
                print("  ! %s : %s" % (os.path.basename(f), e), file=sys.stderr)
        lines = [
            "-- GÉNÉRÉ par tools/bake_terrain.py — zones praticables (%s, continent %d)." % (name, cont),
            "-- Dérivé des fichiers de terrain du client WoW Forever. Ne pas modifier à la main.",
            "local T = ForeverPathTerrainData or {}",
            "ForeverPathTerrainData = T",
            "T[%d] = T[%d] or {}" % (cont, cont),
            "local d = T[%d]" % cont,
        ]
        counts = [0, 0, 0]
        for (tr, tc), cells in sorted(tiles.items()):
            for v in cells:
                counts[v] += 1
            lines.append('d["%d:%d"]="%s"' % (tr, tc, rle(cells)))
        path = os.path.join(out_dir, "Data_%d.lua" % cont)
        open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
        size = os.path.getsize(path)
        total = sum(counts) or 1
        summary.append((name, cont, len(files), bad, len(tiles), size, counts))
        print("%-12s continent %d : %d fichiers (%d illisibles), %d tuiles, %.1f Ko — sol %.0f%%, eau %.0f%%, bloqué %.0f%%"
              % (name, cont, len(files), bad, len(tiles), size / 1024,
                 100 * counts[1] / total, 100 * counts[2] / total, 100 * counts[0] / total))
        if preview and tiles:
            write_preview(tiles, os.path.join(out_dir, "preview_%s.png" % name))
    return summary


def write_preview(tiles, path, scale=4):
    from PIL import Image
    trs = [k[0] for k in tiles]; tcs = [k[1] for k in tiles]
    r0, c0 = min(trs), min(tcs)
    H = (max(trs) - r0 + 1) * CELLS // scale
    W = (max(tcs) - c0 + 1) * CELLS // scale
    img = Image.new("RGB", (W, H), (20, 20, 24))
    px = img.load()
    col = {0: (200, 60, 50), 1: (90, 170, 80), 2: (60, 120, 210)}
    for (tr, tc), cells in tiles.items():
        for i in range(0, CELLS, scale):
            for j in range(0, CELLS, scale):
                px[((tc - c0) * CELLS + j) // scale, ((tr - r0) * CELLS + i) // scale] = col[cells[i * CELLS + j]]
    img.save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="ForeverPath_Terrain")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("items", nargs="*")
    ap.add_argument("--map", action="append", default=[], help="Nom=continent (suivi du dossier en argument)")
    args = ap.parse_args()
    if len(args.map) != len(args.items):
        ap.error("donne un --map Nom=continent par dossier")
    maps = []
    for spec, folder in zip(args.map, args.items):
        name, cont = spec.split("=")
        maps.append((name, int(cont), folder))
    bake(maps, args.out, args.preview)


if __name__ == "__main__":
    main()
