/* Questweaver — site : langue, rendu des modules (data.json, généré depuis l'addon), animations */
(() => {
  "use strict";

  const UI = {
    fr: {
      "nav.features": "Fonctions", "nav.install": "Installer", "nav.modules": "Modules", "nav.commands": "Commandes", "nav.releases": "Nouveautés",
      "hero.eyebrow": "Gratuit · Open source · Horde & Alliance",
      "hero.title1": "Le chemin le plus court", "hero.title2": "de 1 à 60.",
      "hero.lead": "Questweaver te dit quelle quête prendre, où aller, quoi tuer et où rendre, dans WoW Forever. Flèche, guidage 3D, itinéraires optimisés et plus de 40 modules à cocher selon tes envies.",
      "hero.download": "Télécharger", "hero.docs": "Voir les modules",
      "mock.turnin": "Rendre", "mock.quest": "La menace kobold", "mock.sub": "Garde-maréchal Dughan · Comté-de-l'Or", "mock.journey": "Itinéraire ~2 min",
      "stats.modules": "modules à la carte", "stats.routes": "routes complètes 1-60", "stats.quests": "quêtes par route", "stats.lang": "interface traduite", "stats.price": "pour toujours",
      "features.kicker": "Pourquoi Questweaver", "features.title": "Tout ce qu'un guide payant fait. En mieux, et gratuit.",
      "install.kicker": "Installation", "install.title": "Trois étapes, deux minutes.",
      "install.s1t": "Télécharge", "install.s1": "Récupère le zip de la dernière version sur GitHub (bientôt aussi sur CurseForge et Wago).",
      "install.s2t": "Copie", "install.s2": "Place les dossiers Questweaver et Questweaver_Terrain dans <code>_forever_/Interface/AddOns</code>.",
      "install.s3t": "Joue", "install.s3": "Le panneau d'options s'ouvre à la première connexion : coche ce que tu veux. Ensuite, <code>/qw config</code>.",
      "modules.kicker": "Documentation", "modules.title": "Chaque module, en détail.",
      "modules.sub": "Tout se coche ou se décoche dans le panneau d'options, avec un aperçu. Cette documentation est générée à partir du code de l'addon : elle est toujours à jour.",
      "modules.search": "Chercher un module…", "modules.empty": "Aucun module ne correspond.",
      "modules.all": "Tous", "modules.on": "Activé par défaut", "modules.off": "En option", "modules.locked": "Toujours actif", "modules.settings": "Réglages",
      "commands.kicker": "Commandes", "commands.title": "Le guide au bout des doigts.",
      "releases.kicker": "Nouveautés", "releases.title": "Ça bouge vite.", "releases.all": "Toutes les versions sur GitHub",
      "faq.title": "Questions fréquentes.",
      "foot.text": "Addon libre sous licence GPL-3.0. Données de quêtes : QuestieDB. Non affilié à Blizzard Entertainment.",
      "foot.bug": "Signaler un bug", "foot.routes": "Routes partagées",
      "opt.check": "case", "opt.slider": "curseur", "opt.select": "liste", "opt.default": "défaut",
    },
    en: {
      "nav.features": "Features", "nav.install": "Install", "nav.modules": "Modules", "nav.commands": "Commands", "nav.releases": "What's new",
      "hero.eyebrow": "Free · Open source · Horde & Alliance",
      "hero.title1": "The shortest path", "hero.title2": "from 1 to 60.",
      "hero.lead": "Questweaver tells you which quest to take, where to go, what to kill and where to turn in, in WoW Forever. Arrow, 3D guidance, optimized journeys and 40+ modules you pick yourself.",
      "hero.download": "Download", "hero.docs": "Browse modules",
      "mock.turnin": "Turn in", "mock.quest": "The Kobold Menace", "mock.sub": "Marshal Dughan · Goldshire", "mock.journey": "Journey ~2 min",
      "stats.modules": "pick-and-choose modules", "stats.routes": "complete 1-60 routes", "stats.quests": "quests per route", "stats.lang": "translated interface", "stats.price": "forever",
      "features.kicker": "Why Questweaver", "features.title": "Everything a paid guide does. Better, and free.",
      "install.kicker": "Install", "install.title": "Three steps, two minutes.",
      "install.s1t": "Download", "install.s1": "Grab the latest release zip on GitHub (CurseForge and Wago coming soon).",
      "install.s2t": "Copy", "install.s2": "Put the Questweaver and Questweaver_Terrain folders in <code>_forever_/Interface/AddOns</code>.",
      "install.s3t": "Play", "install.s3": "The options panel opens on first login: tick what you want. Later, <code>/qw config</code>.",
      "modules.kicker": "Documentation", "modules.title": "Every module, in detail.",
      "modules.sub": "Everything can be switched on or off in the options panel, with a live preview. This documentation is generated from the addon's code: it's always up to date.",
      "modules.search": "Search a module…", "modules.empty": "No module matches.",
      "modules.all": "All", "modules.on": "On by default", "modules.off": "Optional", "modules.locked": "Always on", "modules.settings": "Settings",
      "commands.kicker": "Commands", "commands.title": "The guide at your fingertips.",
      "releases.kicker": "What's new", "releases.title": "Moving fast.", "releases.all": "All releases on GitHub",
      "faq.title": "Frequently asked questions.",
      "foot.text": "Free software under the GPL-3.0 license. Quest data: QuestieDB. Not affiliated with Blizzard Entertainment.",
      "foot.bug": "Report a bug", "foot.routes": "Shared routes",
      "opt.check": "toggle", "opt.slider": "slider", "opt.select": "list", "opt.default": "default",
    },
  };

  const CATS = {
    look: { fr: "Apparence", en: "Appearance", c: "#e9dfc6" },
    core: { fr: "Guide", en: "Guide", c: "#d4af37" },
    guide: { fr: "Guide", en: "Guide", c: "#d4af37" },
    nav: { fr: "Navigation", en: "Navigation", c: "#5fd4c4" },
    targets: { fr: "Repérage", en: "Targeting", c: "#ff8a4c" },
    comfort: { fr: "Confort", en: "Comfort", c: "#6cc4ff" },
    safety: { fr: "Sécurité", en: "Safety", c: "#ff5f5f" },
    community: { fr: "Communauté", en: "Community", c: "#b48cff" },
  };
  const CAT_ORDER = ["guide", "nav", "targets", "comfort", "safety", "community", "look"];

  const ICONS = {
    route: '<path d="M4 19c4 0 4-6 8-6s4-8 8-8"/><circle cx="4" cy="19" r="2"/><circle cx="20" cy="5" r="2"/>',
    beam: '<path d="M12 2v14"/><path d="M8 20h8"/><circle cx="12" cy="18" r="2"/><path d="M5 9l-2-1M19 9l2-1"/>',
    target: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/><path d="M12 1v4M12 19v4M1 12h4M19 12h4"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    group: '<circle cx="8" cy="9" r="3"/><circle cx="17" cy="9" r="3"/><path d="M2 20c0-3 3-5 6-5s6 2 6 5M14 15c3 0 8 1 8 5"/>',
    sliders: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
  };
  const FEATURES = [
    { i: "route", a: "rgba(212,175,55,.25)",
      fr: ["Des routes optimisées", "8 routes complètes de 1 à 60, de 450 à 600 quêtes chacune, nouveau contenu de Forever compris, générées et mesurées pour l'XP par heure : pierre de foyer planifiée, quêtes groupées par relais, saut automatique de ce qui est devenu trop bas."],
      en: ["Optimized routes", "8 complete 1-60 routes, 450 to 600 quests each, including Forever's new content, generated and measured for XP per hour: planned hearthstone, quests grouped by hub, automatic skipping of what got too low."] },
    { i: "beam", a: "rgba(95,212,196,.22)",
      fr: ["Guidage 3D et itinéraires", "Un faisceau dans le monde, une flèche, le point sur la carte et la minimap. Le chemin le plus rapide par vols, bateaux et chemins appris, virage par virage."],
      en: ["3D guidance and journeys", "A beam in the world, an arrow, the waypoint on map and minimap. The fastest way through flights, boats and learned paths, turn by turn."] },
    { i: "target", a: "rgba(255,138,76,.22)",
      fr: ["Repérage immédiat", "Les monstres et le PNJ de l'étape surlignés, un bouton pour les cibler même dans la foule, l'objet de quête en un clic."],
      en: ["Instant targeting", "Step monsters and NPC highlighted, a button to target them even in a crowd, the quest item one click away."] },
    { i: "clock", a: "rgba(108,196,255,.22)",
      fr: ["Ton temps compte", "« J'ai 45 minutes » : un point d'arrêt sur un rendu, puis l'auberge. Vols, dialogues, marchand et achats automatiques."],
      en: ["Your time matters", "\"I have 45 minutes\": a stop point on a turn-in, then the inn. Automatic flights, dialogues, merchant and supplies."] },
    { i: "group", a: "rgba(180,140,255,.22)",
      fr: ["Mieux à plusieurs", "Qui est en avance, qui n'a pas la quête, partage en un clic. Chrono, records et rapports pour améliorer la route ensemble."],
      en: ["Better together", "Who's ahead, who lacks the quest, one-click sharing. Timer, records and reports to improve the route together."] },
    { i: "sliders", a: "rgba(233,223,198,.18)",
      fr: ["Entièrement à la carte", "Plus de 40 modules avec aperçu, thèmes, compatibilité Daylight UI, Naowh, TomTom et Pawn. Route prudente pour éviter les quêtes dangereuses."],
      en: ["Fully modular", "40+ modules with previews, themes, Daylight UI, Naowh, TomTom and Pawn support. Safe route to avoid dangerous quests."] },
  ];
  const FAQ = [
    { fr: ["C'est vraiment gratuit ?", "Oui, pour toujours, et le code est ouvert (GPL-3.0). Pas d'abonnement, pas de fonctions bloquées."],
      en: ["Is it really free?", "Yes, forever, and the code is open (GPL-3.0). No subscription, no locked features."] },
    { fr: ["D'où viennent les quêtes ?", "De QuestieDB (données WoW Forever). Les routes sont générées par un simulateur qui mesure l'XP par heure. Les nouvelles zones de Forever s'ajoutent grâce à l'enregistreur et à la bibliothèque de routes."],
      en: ["Where do the quests come from?", "From QuestieDB (WoW Forever data). Routes are generated by a simulator that measures XP per hour. Forever's new zones are added through the recorder and the route library."] },
    { fr: ["Ça marche avec Daylight UI, Naowh, TomTom ?", "Oui : thème Daylight UI officiel, Questweaver laisse la main à Naowh s'il pose son point, TomTom et Pawn sont utilisés s'ils sont installés."],
      en: ["Does it work with Daylight UI, Naowh, TomTom?", "Yes: official Daylight UI theme, Questweaver steps aside if Naowh sets its own waypoint, TomTom and Pawn are used when installed."] },
    { fr: ["Et si je veux jouer prudent ?", "Active la route prudente (profil Prudent) : les quêtes dont les monstres sont trop hauts sont sautées, les zones dangereuses signalées, et les rares affichés sur la carte."],
      en: ["What if I want to play it safe?", "Turn on the safe route (Cautious profile): quests with monsters too high are skipped, dangerous zones flagged, and rares shown on the map."] },
    { fr: ["Une étape est fausse, je fais quoi ?", "Corrige-la en jeu avec /qw edit pos (ou suppr, note), puis /qw edit export et propose-la sur GitHub. Tout le monde en profite."],
      en: ["A step is wrong, what do I do?", "Fix it in game with /qw edit pos (or suppr, note), then /qw edit export and share it on GitHub. Everyone benefits."] },
    { fr: ["Mon client est en anglais ?", "L'interface est en français pour les clients frFR et en anglais pour toutes les autres langues."],
      en: ["My client is in English?", "The interface is in French on frFR clients and in English for every other language."] },
  ];

  const $ = (s, r = document) => r.querySelector(s);
  const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const md = (s) => esc(s).replace(/`([^`]+)`/g, "<code>$1</code>");

  let lang = "fr";
  try { lang = localStorage.getItem("fp-lang") || ((navigator.language || "fr").startsWith("fr") ? "fr" : "en"); } catch (e) { /* stockage indisponible */ }
  let data = null, cat = "all", query = "";

  function t(k) { return UI[lang][k] ?? UI.fr[k] ?? k; }

  function applyStatic() {
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach((el) => { el.innerHTML = t(el.dataset.i18n); });
    document.querySelectorAll("[data-i18n-ph]").forEach((el) => { el.placeholder = t(el.dataset.i18nPh); });
    document.querySelectorAll(".lang button").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.lang === lang)));
    document.title = lang === "fr" ? "Questweaver — guide de leveling 1-60 gratuit pour WoW Forever" : "Questweaver — free 1-60 leveling guide for WoW Forever";
  }

  function renderFeatures() {
    $("#feature-grid").innerHTML = FEATURES.map((f, i) => `
      <article class="feature reveal" style="--accent:${f.a};--d:${(i % 3) * 0.08}s">
        <div class="ico"><svg viewBox="0 0 24 24">${ICONS[f.i]}</svg></div>
        <h3>${esc(f[lang][0])}</h3><p>${esc(f[lang][1])}</p>
      </article>`).join("");
  }

  function renderChips() {
    if (!data) return;
    const counts = {};
    data.modules.forEach((m) => { const c = m.category === "core" ? "guide" : m.category; counts[c] = (counts[c] || 0) + 1; });
    const list = [["all", t("modules.all"), data.modules.length]].concat(
      CAT_ORDER.filter((c) => counts[c]).map((c) => [c, CATS[c][lang], counts[c]]));
    $("#chips").innerHTML = list.map(([id, label, n]) =>
      `<button class="chip" role="tab" data-cat="${id}" aria-selected="${id === cat}">${esc(label)}<span class="n">${n}</span></button>`).join("");
  }

  function optLine(o) {
    let d = o.default;
    if (d === "true") d = "✓"; else if (d === "false") d = "—";
    const kind = t("opt." + (o.type || "check"));
    const range = o.range ? ` ${o.range[0]}–${o.range[1]}` : "";
    return `<li><span>${esc(o.label[lang])}</span><span>${esc(kind)}${range}${d && d !== "nil" ? ` · ${esc(d)}` : ""}</span></li>`;
  }

  function renderModules() {
    if (!data) return;
    const q = query.trim().toLowerCase();
    const mods = data.modules
      .filter((m) => cat === "all" || (m.category === "core" ? "guide" : m.category) === cat)
      .filter((m) => !q || (m.name[lang] + " " + m.desc[lang] + " " + m.id).toLowerCase().includes(q))
      .sort((a, b) => CAT_ORDER.indexOf(a.category === "core" ? "guide" : a.category) - CAT_ORDER.indexOf(b.category === "core" ? "guide" : b.category));
    $("#module-grid").innerHTML = mods.map((m, i) => {
      const c = CATS[m.category] || CATS.comfort;
      const state = m.locked ? ["locked", t("modules.locked")] : m.default ? ["on", t("modules.on")] : ["", t("modules.off")];
      const opts = m.options.length
        ? `<details><summary>${t("modules.settings")} (${m.options.length})</summary><ul>${m.options.map(optLine).join("")}</ul></details>` : "";
      return `<article class="module" style="--c:${c.c};animation-delay:${Math.min(i, 12) * 0.035}s" id="m-${m.id}">
        <div class="m-top"><span class="tag">${esc(c[lang])}</span><span class="state ${state[0]}">${esc(state[1])}</span></div>
        <h3>${esc(m.name[lang])}</h3><p>${esc(m.desc[lang])}</p>${opts}</article>`;
    }).join("");
    $("#empty").hidden = mods.length > 0;
  }

  function renderCommands() {
    if (!data) return;
    $("#command-list").innerHTML = data.commands.map((c) =>
      `<li><code>${esc(c.cmd)}</code><span>${esc(c[lang])}</span></li>`).join("");
  }

  function renderReleases() {
    if (!data) return;
    const note = lang === "en" ? '<p class="note">Release notes are written in French.</p>' : "";
    $("#release-list").innerHTML = data.releases.map((r) =>
      `<article class="release reveal"><h3>${esc(r.version)}</h3><ul>${r.items.map((i) => `<li>${md(i)}</li>`).join("")}</ul>${note}</article>`).join("")
      + `<p><a href="${data.repo}/releases">${t("releases.all")} →</a></p>`;
    observe();
  }

  function renderFaq() {
    $("#faq-list").innerHTML = FAQ.map((f) => `<details class="reveal"><summary>${esc(f[lang][0])}</summary><p>${esc(f[lang][1])}</p></details>`).join("");
  }

  function renderAll() {
    applyStatic(); renderFeatures(); renderChips(); renderModules(); renderCommands(); renderReleases(); renderFaq(); observe();
    if (data) {
      document.querySelectorAll("[data-version]").forEach((el) => { el.textContent = data.version; });
      const n = $("[data-count-modules]"); if (n) n.textContent = data.modules.length;
    }
  }

  // apparitions au défilement
  let io;
  function observe() {
    if (!("IntersectionObserver" in window)) { document.querySelectorAll(".reveal").forEach((e) => e.classList.add("in")); return; }
    io = io || new IntersectionObserver((entries) => entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
    }), { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    document.querySelectorAll(".reveal:not(.in)").forEach((e) => io.observe(e));
  }

  // interactions
  document.addEventListener("click", (e) => {
    const lb = e.target.closest(".lang button");
    if (lb) { lang = lb.dataset.lang; try { localStorage.setItem("fp-lang", lang); } catch (err) { /* ignoré */ } renderAll(); return; }
    const chip = e.target.closest(".chip");
    if (chip) { cat = chip.dataset.cat; renderChips(); renderModules(); return; }
    const burger = e.target.closest(".burger");
    if (burger) { const open = burger.getAttribute("aria-expanded") !== "true"; burger.setAttribute("aria-expanded", String(open)); $(".links").classList.toggle("open", open); return; }
    if (e.target.closest(".links a")) { $(".burger").setAttribute("aria-expanded", "false"); $(".links").classList.remove("open"); }
  });
  $("#q").addEventListener("input", (e) => { query = e.target.value; renderModules(); });

  // parallaxe légère de la carte
  const map = $(".map");
  if (map && matchMedia("(pointer: fine)").matches && !matchMedia("(prefers-reduced-motion: reduce)").matches) {
    map.addEventListener("pointermove", (e) => {
      const r = map.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5, y = (e.clientY - r.top) / r.height - 0.5;
      map.style.transform = `perspective(1200px) rotateY(${-6 + x * 8}deg) rotateX(${4 - y * 8}deg)`;
    });
    map.addEventListener("pointerleave", () => { map.style.transform = ""; });
  }

  renderAll();
  fetch("data.json", { cache: "no-cache" }).then((r) => r.json()).then((d) => { data = d; renderAll(); })
    .catch(() => { $("#module-grid").innerHTML = '<p class="empty">data.json introuvable — lance tools/gen_site.py.</p>'; });
})();
