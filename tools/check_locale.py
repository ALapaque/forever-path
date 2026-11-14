"""Vérifie que chaque texte d'interface passé à ns.Tr(...) et chaque fiche de module (nom, description,
réglages) a sa traduction anglaise dans Locale_enUS.lua. Échoue (code 1) s'il en manque."""
import glob, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
LIT = r'"((?:[^"\\\n]|\\.)*)"'
en = set(m.group(1) for m in re.finditer(r'\[' + LIT + r'\] =', open(ROOT + "/Locale_enUS.lua", encoding="utf-8").read()))
IGNORE = {"Guide", "Blizzard", "Minimal", "ForeverPath", "Daylight UI", "Zeppelin", "Tram", "Morpheus", "Skurri",
          "Arial Narrow", "Friz Quadrata (Blizzard)", "Sombre doré", "Doux (style Daylight UI)", "Thrall", "Jaina",
          "|cffffd100%s|r — %s", "mapID=%s (%s) x=%.1f y=%.1f zone=%s interface=%s cartes=%s"}
missing = {}
for f in glob.glob(ROOT + "/**/*.lua", recursive=True):
    rel = f[len(ROOT) + 1:]
    if rel.startswith(("Guides/", "Data/", "tests/", "tools/", "ForeverPath_Terrain")) or rel.startswith("Locale"):
        continue
    src = open(f, encoding="utf-8").read()
    texts = [m.group(1) for m in re.finditer(r"ns\.Tr\(" + LIT + r"\)", src)]
    # textes formatés ou affichés (messages, toasts) : ils passent par ns.Tr à l'affichage
    FRISH = re.compile(r"[éèàùêçâîôûÉÈÀ]|\b(le|la|les|de|des|du|une?|ton|tes|pour|dans|sur|avec|vers|au|aux)\b")
    for m in re.finditer(r"(?:ns\.Print|ns\.Toast)\(\(?" + LIT, src):
        texts.append(m.group(1))
    for m in re.finditer(r"\(" + LIT + r"\):format", src):
        if FRISH.search(m.group(1)):
            texts.append(m.group(1))
    if "RegisterModule" in src:
        texts += [m.group(1) for m in re.finditer(r"\b(?:name|desc|label)\s*=\s*" + LIT, src)]
    for t in texts:
        if t not in en and t not in IGNORE and re.search("[a-zA-Z]", t):
            missing.setdefault(t, rel)
for t, rel in sorted(missing.items(), key=lambda kv: kv[1]):
    print("%s : %s" % (rel, t))
if missing:
    print("%d texte(s) sans traduction anglaise (ajoute-les à Locale_enUS.lua)" % len(missing))
    sys.exit(1)
print("traductions : %d textes, tout est couvert" % len(en))
