"""Recoupement de QuestieDB avec tools/cross.json (écrit par tools/load_cross.py), partagé par les
générateurs (gen_routes.py, gen_items.py, gen_links.py, gen_world.py).

En cas de désaccord entre les bases, la valeur la plus prudente gagne : une quête que le serveur ne
connaît pas, que Questie masque ou que Polestar a retirée après vérification en jeu sort des données ;
le niveau requis est le plus haut des valeurs connues ; un prérequis connu d'une seule base compte.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
FOREVER_MIN = 90000


def g(t, k, d=None):
    if isinstance(t, dict):
        v = t.get(k, d)
        return d if v is None else v
    return d


def lst(t):
    if isinstance(t, dict):
        return [t[k] for k in sorted(t) if isinstance(k, int)]
    return list(t) if isinstance(t, (list, tuple)) else ([t] if isinstance(t, int) else [])


def load(path=None, optional=False):
    path = path or os.path.join(HERE, "cross.json")
    if os.path.exists(path):
        return {int(k): v for k, v in json.load(open(path, encoding="utf-8"))["quests"].items()}
    if optional:
        return {}
    sys.exit("tools/cross.json manque : lance tools/load_cross.py (ou --no-cross pour s'en passer)")


def apply(Q, CROSS, confirmed=(), SAN=None):
    """Corrige la table des quêtes Q sur place. confirmed : quêtes vues en jeu, jamais retirées."""
    if SAN is None:
        SAN = {}

    def count(key):
        SAN[key] = SAN.get(key, 0) + 1

    for qid in list(Q):
        c = CROSS.get(qid)
        if not c:
            continue
        q = Q[qid]
        if c.get("x") and qid not in confirmed:
            del Q[qid]
            count("pas dans le jeu (%s)" % c["x"])
            continue
        lvl = g(q, 5)
        if c.get("l") and isinstance(lvl, int) and lvl > 0 and lvl != c["l"]:
            q[5] = lvl = c["l"]
            count("niveau de quête corrigé (serveur)")
        req = g(q, 4) or 0
        if c.get("m"):
            q["req_known"] = True                 # réponse du serveur : pas d'estimation ensuite
            if c["m"] > req or (req <= 1 and qid >= FOREVER_MIN):
                if c["m"] != req:
                    count("niveau requis corrigé (serveur)")
                q[4] = req = c["m"]
        elif c.get("pm") and (c["pm"] > req or req <= 1):
            if c["pm"] != req:
                count("niveau requis corrigé (Polestar)")
            q[4] = req = c["pm"]
            q["req_known"] = True
        if isinstance(lvl, int) and lvl > 0 and req > lvl:
            q[4] = lvl                            # jamais au-dessus du niveau de la quête
        if c.get("r"):
            mask = g(q, 6) or 0
            new = (mask & c["r"]) or c["r"]
            if new != mask:
                q[6] = new
                count("races corrigées (serveur)")
        if c.get("pr") and not (g(q, 6) or 0):
            q[6] = c["pr"]                        # QuestieDB ne dit rien : la faction selon Polestar
            count("races ajoutées (Polestar)")
        if c.get("c") and not g(q, 7):
            q[7] = c["c"]
            count("quête de classe (Polestar)")
        pa, pn = set(c.get("pa", ())), set(c.get("pn", ()))
        if pa or pn:
            grp, single = set(lst(g(q, 12))), set(lst(g(q, 13)))
            new_grp, new_single = grp | pa, single
            if pn and not single:
                new_single = pn
            elif pn and single and not (pn & single):
                if len(pn) == 1:
                    new_grp |= pn                 # deux conditions différentes : il faut les deux
            elif pn and single:
                new_single = pn & single
            new_single = new_single - new_grp
            if new_grp != grp or new_single != single:
                q[12] = {i + 1: v for i, v in enumerate(sorted(new_grp))} or None
                q[13] = {i + 1: v for i, v in enumerate(sorted(new_single))} or None
                count("prérequis ajoutés (Polestar)")
    return SAN
