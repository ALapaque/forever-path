"""Après tools/update_data.sh : décide si les données régénérées méritent une version, et l'écrit.

Compare les routes régénérées à celles du dernier commit (git) :
  - rien n'a changé dans Guides/ ni Data/ : affiche RIEN, code 0, ne touche à rien ;
  - changement sain : ajoute une section « ## vX.Y.(Z+1) » en tête du CHANGELOG, affiche PUBLIER, code 0 ;
  - changement suspect (garde-fous ci-dessous) : affiche A_VERIFIER et la raison, code 2, n'écrit rien.

Garde-fous : chaque parcours atteint le niveau 60 ; pas plus de 5 % de quêtes en moins ni de 5 %
d'heures en plus en moyenne ; pas plus de 12 % des quêtes d'un parcours remplacées d'un coup.

Usage : python3 -I tools/data_release.py [--dry]     (--dry : n'écrit pas le CHANGELOG)
"""
import datetime, glob, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRY = "--dry" in sys.argv
MAX_FEWER, MAX_SLOWER, MAX_CHURN = 0.05, 0.05, 0.12


def git(*args):
    return subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=True, check=True).stdout


def quests(text):
    return set(int(q) for q in re.findall(r"^A (\d+)", text, re.M))


changed = [l[3:] for l in git("status", "--porcelain", "--", "Guides", "Data").splitlines() if l.strip()]
if not changed:
    print("RIEN : les routes et les données sont identiques")
    sys.exit(0)

new_m = json.load(open(os.path.join(ROOT, "tools", "route_metrics.json"), encoding="utf-8"))
old_m = json.loads(git("show", "HEAD:tools/route_metrics.json"))
old_by = {m["path"]: m for m in old_m}
problems, added, removed = [], set(), set()
for f in sorted(glob.glob(os.path.join(ROOT, "Guides", "Route_*.lua"))):
    rel = os.path.relpath(f, ROOT).replace(os.sep, "/")
    new_q = quests(open(f, encoding="utf-8").read())
    try:
        old_q = quests(git("show", "HEAD:" + rel))
    except subprocess.CalledProcessError:
        old_q = set()
    added |= new_q - old_q
    removed |= old_q - new_q
    if old_q and len(old_q - new_q) > MAX_CHURN * len(old_q):
        problems.append("%s : %d quêtes sur %d remplacées" % (os.path.basename(f), len(old_q - new_q), len(old_q)))
for m in new_m:
    if m["level"] < 60:
        problems.append("%s s'arrête au niveau %d" % (m["path"], m["level"]))
avg = lambda ms, k: sum(m[k] for m in ms) / len(ms)
nq, oq = avg(new_m, "quests"), avg(old_m, "quests")
nh, oh = avg(new_m, "hours_to_60"), avg(old_m, "hours_to_60")
if nq < oq * (1 - MAX_FEWER):
    problems.append("quêtes par parcours : %.0f -> %.0f" % (oq, nq))
if nh > oh * (1 + MAX_SLOWER):
    problems.append("heures jusqu'au 60 : %.1f -> %.1f" % (oh, nh))
if len(new_m) != len(old_m) or set(m["path"] for m in new_m) != set(old_by):
    problems.append("la liste des parcours a changé")

print("fichiers modifiés : %d ; quêtes ajoutées aux routes : %d, retirées : %d" % (len(changed), len(added - removed), len(removed - added)))
print("quêtes par parcours : %.0f -> %.0f ; heures jusqu'au 60 : %.1f -> %.1f ; farm : %.0f %% -> %.0f %%" % (
    oq, nq, oh, nh, avg(old_m, "grind_share") * 100, avg(new_m, "grind_share") * 100))
if problems:
    print("A_VERIFIER : " + " ; ".join(problems))
    sys.exit(2)

path = os.path.join(ROOT, "CHANGELOG.md")
log = open(path, encoding="utf-8").read()
m = re.search(r"^## v(\d+)\.(\d+)\.(\d+)\s*$", log, re.M)
if not m or not log.startswith("# Questweaver\n\n"):
    print("A_VERIFIER : CHANGELOG.md sans version en tête")
    sys.exit(2)
version = "v%s.%s.%d" % (m.group(1), m.group(2), int(m.group(3)) + 1)
today = datetime.date.today().strftime("%d/%m/%Y")
a, r = len(added - removed), len(removed - added)
parts = []
if a: parts.append("%d quête(s) ajoutée(s) aux routes" % a)
if r: parts.append("%d retirée(s)" % r)
detail = (", ".join(parts) + ". ") if parts else "Positions, niveaux et prérequis corrigés. "
entry = ("## %s\n\n- **Données de quêtes mises à jour** (QuestieDB, EG Link et Polestar du %s). %s"
         "%.0f quêtes en moyenne par parcours, environ %.0f h jusqu'au 60.\n\n" % (version, today, detail, nq, nh))
if not DRY:
    open(path, "w", encoding="utf-8").write("# Questweaver\n\n" + entry + log[len("# Questweaver\n\n"):])
print("PUBLIER %s" % version)
