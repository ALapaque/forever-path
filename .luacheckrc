-- Configuration luacheck pour ForeverPath (WoW Forever, Lua 5.1)
std = "lua51"
max_line_length = false
exclude_files = { ".release/", "tools/", "tests/" }

-- L'API WoW compte des milliers de globales : on ne signale pas leur lecture,
-- mais on interdit d'en créer de nouvelles par accident (sauf celles listées).
ignore = {
    "113",       -- accès à une globale non définie (API WoW)
    "212/self",  -- argument self inutilisé
    "212/_.*",   -- arguments préfixés par _
}
globals = {
    "ForeverPathDB", "ForeverPathCharDB",
    "SLASH_FOREVERPATH1", "SLASH_FOREVERPATH2", "SlashCmdList",
    "BINDING_HEADER_FOREVERPATH", "BINDING_NAME_FOREVERPATH_NEXT", "BINDING_NAME_FOREVERPATH_PREV",
    "BINDING_NAME_FOREVERPATH_TOGGLE", "BINDING_NAME_CLICK_ForeverPathTargetButton_LeftButton",
    "BINDING_NAME_CLICK_ForeverPathQuestItemButton_LeftButton",
    "ForeverPath_Next", "ForeverPath_Prev", "ForeverPath_Toggle",
    "UISpecialFrames",
}
