"""Fabrique une tuile ADT « racine » synthétique (format v18) pour tester tools/bake_terrain.py.
Terrain : plaine à 0 m traversée d'ouest en est par une crête infranchissable (60 m) au milieu
de la tuile, avec un passage à l'est (morceaux 12 à 15) ; un lac au sud-est ; un morceau troué."""
import struct, sys

TILE = 51200 / 3 / 32
CHUNK = TILE / 16
UNIT = CHUNK / 8

def chunk(cid, data):
    return struct.pack("<II", cid, len(data)) + data

def make(path, tile_row=32, tile_col=32):
    X0 = (32 - tile_row) * TILE      # coin nord de la tuile (monde X = nord)
    Y0 = (32 - tile_col) * TILE      # coin ouest (monde Y = ouest)
    mcnks = []
    for cy in range(16):
        for cx in range(16):
            px, py = X0 - cy * CHUNK, Y0 - cx * CHUNK
            verts = []
            for r in range(17):
                inner = r % 2 == 1
                for c in range(8 if inner else 9):
                    vx = px - (r / 2) * UNIT                 # nord -> sud
                    vy = py - (c + (0.5 if inner else 0)) * UNIT   # ouest -> est
                    ridge = abs(vx - (X0 - TILE / 2)) < UNIT * 1.6 and vy > Y0 - 12 * CHUNK
                    verts.append(60.0 if ridge else 0.0)
            flags = 0
            holes = 0
            if cy == 12 and cx == 3:
                holes = 0xFFFF                                # morceau entièrement troué
            header = bytearray(128)
            struct.pack_into("<IIII", header, 0, flags, cx, cy, 0)
            struct.pack_into("<H", header, 60, holes)
            struct.pack_into("<fff", header, 104, px, py, 0.0)
            sub = chunk(0x4D435654, struct.pack("<145f", *verts))
            mcnks.append(chunk(0x4D434E4B, bytes(header) + sub))
    # MH2O : un lac (eau 5 m au-dessus du sol) sur les morceaux cy 13..15, cx 12..15
    headers, tail = bytearray(256 * 12), bytearray()
    base_tail = 256 * 12
    for i in range(256):
        cy, cx = divmod(i, 16)
        if 13 <= cy <= 15 and 12 <= cx <= 15:
            off = base_tail + len(tail)
            tail += struct.pack("<HHffBBBBII", 1, 0, 5.0, 5.0, 0, 0, 8, 8, 0, 0)
            struct.pack_into("<III", headers, i * 12, off, 1, 0)
    mh2o = chunk(0x4D48324F, bytes(headers) + bytes(tail))
    data = chunk(0x4D564552, struct.pack("<I", 18)) + mh2o + b"".join(mcnks)
    open(path, "wb").write(data)

if __name__ == "__main__":
    make(sys.argv[1])
