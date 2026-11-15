-- Configuration luacheck pour Questweaver (WoW Forever, Lua 5.1)
std = "lua51"
max_line_length = false
exclude_files = { ".release/", "tools/", "tests/", "Questweaver_Terrain/" }

-- L'API WoW compte des milliers de globales : on ne signale pas leur lecture,
-- mais on interdit d'en créer de nouvelles par accident (sauf celles listées).
ignore = {
    "113",       -- accès à une globale non définie (API WoW)
    "212/self",  -- argument self inutilisé
    "212/_.*",   -- arguments préfixés par _
}
globals = {
    "QuestweaverDB", "QuestweaverCharDB", "QuestweaverNavDB", "QuestweaverAPI", "QuestweaverTerrainData",
    "SLASH_QUESTWEAVER1", "SLASH_QUESTWEAVER2", "SlashCmdList",
    "BINDING_HEADER_QUESTWEAVER", "BINDING_NAME_QUESTWEAVER_NEXT", "BINDING_NAME_QUESTWEAVER_PREV",
    "BINDING_NAME_QUESTWEAVER_TOGGLE", "BINDING_NAME_CLICK_QuestweaverTargetButton_LeftButton",
    "BINDING_NAME_CLICK_QuestweaverQuestItemButton_LeftButton",
    "Questweaver_Next", "Questweaver_Prev", "Questweaver_Toggle",
    "UISpecialFrames",
}
