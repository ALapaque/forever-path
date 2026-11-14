local _, ns = ...

ns.GOLD = { 0.83, 0.69, 0.22 }

function ns.Skin(frame, alpha, borderAlpha)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(0.05, 0.05, 0.07, alpha or 0.88)
    frame:SetBackdropBorderColor(ns.GOLD[1], ns.GOLD[2], ns.GOLD[3], borderAlpha or 0.9)
end

function ns.Button(parent, label, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h or 20)
    b:SetText(label)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

-- Toast : message temporaire en haut de l'écran
local toast = CreateFrame("Frame", "ForeverPathToast", UIParent)
toast:SetSize(420, 40)
toast:SetPoint("TOP", 0, -140)
toast:SetFrameStrata("HIGH")
toast:Hide()
ns.Skin(toast, 0.85)
toast.icon = toast:CreateTexture(nil, "ARTWORK")
toast.icon:SetSize(24, 24)
toast.icon:SetPoint("LEFT", 8, 0)
toast.text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
toast.text:SetPoint("LEFT", toast.icon, "RIGHT", 8, 0)
toast.text:SetPoint("RIGHT", -8, 0)
toast.text:SetJustifyH("LEFT")
toast.elapsed = 0
toast:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed > self.duration then
        local a = 1 - (self.elapsed - self.duration) / 0.6
        if a <= 0 then self:Hide() else self:SetAlpha(a) end
    end
end)

function ns.Toast(msg, icon, r, g, b, duration)
    toast.text:SetText(msg)
    toast.text:SetTextColor(r or 1, g or 1, b or 1)
    toast.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Map_01")
    toast.elapsed, toast.duration = 0, duration or 4
    toast:SetAlpha(1)
    toast:Show()
end
