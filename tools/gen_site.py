"""Génère site/data.json pour le site GitHub Pages à partir du code de l'addon :
fiches des modules (nom, description, réglages, catégorie, état par défaut) en français et en anglais,
commandes, version et dernières notes de version. La documentation suit donc toujours le code.
Usage : python3 -I tools/gen_site.py [racine] [site/data.json]
"""
import glob, json, os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "site", "data.json")
STR = r'(?:ns\.Tr\()?"((?:[^"\\]|\\.)*)"\)?'


def unescape(s):
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def clean(s):
    """Retire les codes de couleur / textures WoW."""
    s = re.sub(r"\|c[0-9a-fA-F]{8}", "", s).replace("|r", "")
    s = re.sub(r"\|T[^|]*\|t", "", s)
    return s.strip()


# --- dictionnaire anglais
EN = {}
for m in re.finditer(r'\["((?:[^"\\]|\\.)*)"\] = "((?:[^"\\]|\\.)*)"', open(os.path.join(ROOT, "Locale_enUS.lua"), encoding="utf-8").read()):
    EN[unescape(m.group(1))] = unescape(m.group(2))


def both(fr):
    fr = unescape(fr)
    return {"fr": clean(fr), "en": clean(EN.get(fr, fr))}


def block(src, start):
    """Texte entre l'accolade ouvrante à `start` et sa fermante."""
    depth, i, instr = 0, start, False
    while i < len(src):
        c = src[i]
        if c == '"' and src[i - 1] != "\\":
            instr = not instr
        elif not instr:
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return src[start:i + 1]
        i += 1
    return src[start:]


def field(b, name):
    m = re.search(r"\b" + name + r"\s*=\s*" + STR, b)
    return m and m.group(1)


modules = []
for f in sorted(glob.glob(os.path.join(ROOT, "Modules", "*.lua"))):
    src = open(f, encoding="utf-8").read()
    i = src.find("ns.RegisterModule({")
    if i < 0:
        continue
    b = block(src, src.index("{", i))
    head = b.split("options", 1)[0]
    mid = re.search(r'\bid\s*=\s*"([^"]+)"', head).group(1)
    cat = re.search(r'\bcategory\s*=\s*"([^"]+)"', head)
    default = re.search(r"\bdefault\s*=\s*(true|false)", head)
    opts = []
    oi = b.find("options")
    if oi >= 0 and "{" in b[oi:]:
        ob = block(b, b.index("{", oi))
        for om in re.finditer(r"\{\s*key\s*=", ob):
            o = block(ob, om.start())
            label = field(o, "label")
            typ = re.search(r'\btype\s*=\s*"([^"]+)"', o)
            d = re.search(r"\bdefault\s*=\s*([^,}\s]+)", o)
            rng = re.search(r"\bmin\s*=\s*([\d.]+).*?\bmax\s*=\s*([\d.]+)", o)
            if label:
                opts.append({"label": both(label), "type": typ and typ.group(1),
                             "default": d and d.group(1).strip('"'),
                             "range": rng and [rng.group(1), rng.group(2)]})
    modules.append({
        "id": mid, "file": os.path.basename(f), "category": cat and cat.group(1) or "comfort",
        "default": (default.group(1) == "true") if default else True,
        "locked": bool(re.search(r"\blocked\s*=\s*true", head)),
        "name": both(field(head, "name") or mid), "desc": both(field(head, "desc") or ""), "options": opts,
    })

# --- commandes (aide /qw, fr et en)
loc = open(os.path.join(ROOT, "Locale.lua"), encoding="utf-8").read()
helps = [re.findall(r'"(/qw[^"]*)"', h) for h in re.findall(r"HELP = \{(.*?)\n    \}", loc, re.S)]
commands = []
for k, fr in enumerate(helps[0] if helps else []):
    en = helps[1][k] if len(helps) > 1 and k < len(helps[1]) else fr
    cmd, _, dfr = fr.partition(" — ")
    _, _, den = en.partition(" — ")
    commands.append({"cmd": cmd, "fr": dfr, "en": den or dfr})

# --- version et notes de version (3 dernières, en français)
changelog = open(os.path.join(ROOT, "CHANGELOG.md"), encoding="utf-8").read()
releases = []
for m in re.finditer(r"^## (v[\w.\-]+)\n(.*?)(?=^## |\Z)", changelog, re.S | re.M):
    items = [re.sub(r"\*\*(.+?)\*\*", r"\1", l[2:]).strip() for l in m.group(2).splitlines() if l.startswith("- ")]
    releases.append({"version": m.group(1), "items": items[:8]})
    if len(releases) >= 3:
        break

data = {"version": releases[0]["version"] if releases else "dev", "modules": modules, "commands": commands,
        "releases": releases, "repo": "https://github.com/ALapaque/quest-weaver"}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("site : %d modules, %d commandes, version %s" % (len(modules), len(commands), data["version"]))
