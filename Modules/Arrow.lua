local _, ns = ...
local L = ns.L

local M = ns.RegisterModule({
    id = "arrow", category = "nav", default = true,
    name = "Flèche de direction",
    desc = "Une flèche à l'écran qui pointe vers l'étape, avec la distance. Verte quand tu es dans la bonne direction.",
    options = {
        { key = "size", label = "Taille", type = "slider", min = 32, max = 96, step = 4, default = 56 },
        { key = "hideClose", label = "Masquer à l'arrivée", type = "check", default = true },
    },
})

local f = CreateFrame("Frame", "ForeverPathArrow", UIParent)
f:SetSize(70, 90)
f:SetFrameStrata("MEDIUM")
f:Hide()
ns.MakeMovable(f, "arrow", { "TOP", "TOP", 0, -180 })

f.tex = f:CreateTexture(nil, "ARTWORK")
f.tex:SetPoint("TOP", 0, 0)
f.tex:SetTexture(ns.MEDIA .. "arrow")

f.dist = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.dist:SetPoint("TOP", f.tex, "BOTTOM", 0, -2)
f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
f.label:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
f.label:SetWidth(160)
f.label:SetWordWrap(false)

local function color(rel)
    -- 0 = droit devant ; vert -> jaune -> rouge selon l'écart
    local off = rel > math.pi and (2 * math.pi - rel) or rel
    local t = off / math.pi
    if t < 0.5 then return t * 2, 1, 0.2 end
    return 1, 1 - (t - 0.5) * 2, 0.2
end

local acc = 0
f:SetScript("OnUpdate", function(self, dt)
    acc = acc + dt
    if acc < 0.03 then return end
    acc = 0
    local _, step = ns.Engine.Current()
    if not step or not step.x then self.tex:Hide(); self.dist:SetText(""); self.label:SetText(""); return end
    local d, bearing = ns.Geo.Vector(step)
    if not d then
        self.tex:Hide(); self.dist:SetText(""); self.label:SetText("")
        return
    end
    local radius = step.radius or 15
    if d <= radius and M:Opt("hideClose") then
        self.tex:Show()
        self.tex:SetRotation(0)
        self.tex:SetVertexColor(0.3, 1, 0.3)
        self.dist:SetText(L.ARRIVED or "Arrivé")
        return
    end
    local rel = ns.Geo.RelativeAngle(bearing)
    if not rel then self.tex:Hide(); return end
    self.tex:Show()
    self.tex:SetRotation(rel)
    self.tex:SetVertexColor(color(rel))
    self.dist:SetText(("%d m"):format(math.floor(d * 0.9144)))
    local label = ns.Guide and ns.Guide.StepLabel(step) or ""
    self.label:SetText(label)
end)

function M:Apply()
    local s = self:Opt("size") or 56
    f.tex:SetSize(s, s)
end
function M:OnEnable() self:Apply(); f:Show() end
function M:OnDisable() f:Hide() end
function M:OnOptionChanged() self:Apply() end

function M.preview(p)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetSize(48, 48)
    t:SetPoint("CENTER", 0, 8)
    t:SetTexture(ns.MEDIA .. "arrow")
    t:SetVertexColor(0.4, 1, 0.2)
    local d = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d:SetPoint("TOP", t, "BOTTOM", 0, -2)
    d:SetText("86 m")
    -- petite animation de rotation
    local a = 0
    p:SetScript("OnUpdate", function(_, dt)
        a = a + dt
        local r = math.sin(a * 1.2) * 0.9
        t:SetRotation(r)
        t:SetVertexColor(color(r < 0 and 2 * math.pi + r or r))
    end)
end
