local _, ns = ...

local M = ns.RegisterModule({
    id = "npcmodel", category = "targets", default = false,
    name = ns.Tr("Aperçu 3D du PNJ"),
    desc = ns.Tr("Montre à côté du guide le modèle 3D du PNJ ou du monstre de l'étape, pour le reconnaître du premier coup d'œil."),
    options = {
        { key = "size", label = ns.Tr("Taille"), type = "slider", min = 80, max = 200, step = 10, default = 120 },
    },
})

local f = CreateFrame("Frame", "QuestweaverModelFrame", UIParent)
f:SetSize(120, 140)
f:Hide()
ns.Skin(f, 0.75, 0.5)
f.model = CreateFrame("PlayerModel", nil, f)
f.model:SetPoint("TOPLEFT", 3, -3)
f.model:SetPoint("BOTTOMRIGHT", -3, 16)
f.name = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontSmall")
f.name:SetPoint("BOTTOM", 0, 3)
f.name:SetWidth(114)
f.name:SetWordWrap(false)
f.model:SetScript("OnUpdate", function(self, dt)
    if ns.Eco and ns.Eco() then return end          -- économie : le modèle ne tourne plus
    self.r = (self.r or 0) + dt * 0.6
    self:SetFacing(self.r)
end)

local function anchor()
    f:ClearAllPoints()
    local g = ns.Guide and ns.Guide.frame
    if g and g:IsShown() then f:SetPoint("TOPRIGHT", g, "TOPLEFT", -4, 0)
    else f:SetPoint("CENTER", UIParent, "CENTER", -300, 0) end
end

function M:Update()
    local _, step = ns.Engine.Current()
    local id = step and (step.npcID or (step.mobs and next(step.mobs)))
    if not id then f:Hide() return end
    local s = self:Opt("size") or 120
    f:SetSize(s, s + 20)
    anchor()
    f.model:ClearModel()
    f.model:SetCreature(id)
    f.name:SetText(ns.NpcName(id) or "")
    f:Show()
end

function M:OnEnable() self:Update() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:Update() end
M:On("FP_STEP_CHANGED", function() M:Update() end)

function M.preview(p)
    local m = CreateFrame("PlayerModel", nil, p)
    m:SetSize(70, 74)
    m:SetPoint("CENTER")
    pcall(m.SetCreature, m, 197)
    m:SetScript("OnUpdate", function(self, dt) self.r = (self.r or 0) + dt * 0.6; self:SetFacing(self.r) end)
end
