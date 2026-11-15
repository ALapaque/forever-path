"""Analyse les rapports de parcours (/qw rapport) envoyés par les joueurs.

Chaque fichier peut contenir un ou plusieurs rapports (blocs qui commencent par « FPR1; »).
Sortie : segments les plus lents, les plus mortels, étapes les plus souvent passées, temps par niveau.
Usage : python3 -I tools/analyze_reports.py rapports/*.txt
"""
import statistics, sys
from collections import defaultdict


def parse(text):
    runs, cur = [], None
    for line in text.splitlines():
        p = line.strip().split(";")
        if not p or not p[0]:
            continue
        if p[0] == "FPR1" and len(p) >= 8:
            cur = {"version": p[1], "path": p[2], "race": p[3], "class": p[4], "level": int(p[5]),
                   "played": int(p[6]), "deaths": int(p[7]), "levels": {}, "segs": {}, "skips": []}
            runs.append(cur)
        elif cur is None:
            continue
        elif p[0] == "L" and len(p) >= 3:
            cur["levels"][int(p[1])] = int(p[2])
        elif p[0] == "S" and len(p) >= 5:
            cur["segs"][p[1]] = {"sec": int(p[2]), "deaths": int(p[3]), "skipped": int(p[4])}
        elif p[0] == "K" and len(p) >= 4:
            cur["skips"].append((p[1], int(p[2]), p[3], p[4] if len(p) > 4 else ""))
    return runs


def fmt(sec):
    sec = int(sec)
    return "%dh%02d" % (sec // 3600, sec % 3600 // 60) if sec >= 3600 else "%d min" % (sec // 60)


def main(files):
    runs = []
    for f in files:
        runs += parse(open(f, encoding="utf-8", errors="replace").read())
    if not runs:
        print("Aucun rapport trouvé.")
        return
    print("# Rapports de parcours : %d partie(s)\n" % len(runs))
    segs = defaultdict(list)
    for r in runs:
        for gid, s in r["segs"].items():
            segs[gid].append(s)
    print("## Segments les plus lents (médiane)\n")
    rows = sorted(((statistics.median(x["sec"] for x in v), gid, v) for gid, v in segs.items()), reverse=True)
    for med, gid, v in rows[:15]:
        d = sum(x["deaths"] for x in v) / len(v)
        sk = sum(x["skipped"] for x in v) / len(v)
        print("- %-40s %8s  (%d partie(s), %.1f mort(s), %.1f étape(s) passée(s))" % (gid, fmt(med), len(v), d, sk))
    print("\n## Segments les plus mortels\n")
    for d, gid, n in sorted(((sum(x["deaths"] for x in v) / len(v), gid, len(v)) for gid, v in segs.items()), reverse=True)[:10]:
        if d > 0:
            print("- %-40s %.1f mort(s) par partie (%d)" % (gid, d, n))
    print("\n## Étapes les plus souvent passées\n")
    skips = defaultdict(int)
    for r in runs:
        for gid, idx, typ, q in r["skips"]:
            skips[(gid, idx, typ, q)] += 1
    for (gid, idx, typ, q), n in sorted(skips.items(), key=lambda kv: -kv[1])[:20]:
        print("- %s étape %d (%s%s) : %d fois" % (gid, idx, typ, " quête %s" % q if q else "", n))
    print("\n## Temps de jeu pour atteindre chaque palier (médiane)\n")
    for lvl in (10, 20, 30, 40, 50, 60):
        v = [r["levels"][lvl] for r in runs if lvl in r["levels"]]
        if v:
            print("- niveau %d : %s (%d partie(s))" % (lvl, fmt(statistics.median(v)), len(v)))


if __name__ == "__main__":
    main(sys.argv[1:])
