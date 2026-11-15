local _, ns = ...

-- Dialogues : avec le PNJ de l'étape, choisit tout seul l'option de dialogue utile (unique option,
-- ou auberge pour une étape « Lier la pierre »).
local M = ns.RegisterModule({
    id = "dialogue", category = "comfort", default = true,
    name = "Dialogues accélérés",
    desc = "Avec le PNJ de l'étape : choisit tout seul l'option de dialogue quand il n'y en a qu'une, et l'option « auberge » pour lier ta pierre de foyer. Maintiens Maj pour lire tranquillement.",
    options = {
        { key = "single", label = "Option unique du PNJ de l'étape", type = "check", default = true },
        { key = "bind", label = "Lier la pierre à l'auberge (étape « Lier »)", type = "check", default = true },
    },
})

M:On("GOSSIP_SHOW", function()
    if IsShiftKeyDown() then return end
    if #(C_GossipInfo.GetAvailableQuests() or {}) > 0 or #(C_GossipInfo.GetActiveQuests() or {}) > 0 then return end
    local _, step = ns.Engine.Current()
    if not step then return end
    local opts = C_GossipInfo.GetOptions() or {}
    if step.type == "bind" and M:Opt("bind") then
        local o = ns.GossipOption("binder", opts)
        if o then C_GossipInfo.SelectOption(o.gossipOptionID) return end
    end
    local npc = ns.NpcIDFromUnit("npc")
    if M:Opt("single") and #opts == 1 and step.npcID and npc == step.npcID then
        C_GossipInfo.SelectOption(opts[1].gossipOptionID)
    end
end)

-- confirmation « faire de cette auberge votre foyer » : seulement pendant une étape « Lier »
M:On("CONFIRM_BINDER", function()
    local _, step = ns.Engine.Current()
    if not (M:Opt("bind") and step and step.type == "bind") or IsShiftKeyDown() then return end
    if C_PlayerInteractionManager and C_PlayerInteractionManager.ConfirmationInteraction and Enum.PlayerInteractionType then
        pcall(C_PlayerInteractionManager.ConfirmationInteraction, Enum.PlayerInteractionType.Binder)
    elseif ConfirmBinder then
        pcall(ConfirmBinder)
    end
end)

function M.preview(p)
    local fs = p:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
    fs:SetPoint("CENTER")
    fs:SetText("|TInterface\\GossipFrame\\BinderGossipIcon:16|t Faites de cette auberge\nvotre foyer  |cff3fbf3f(auto)|r")
end
