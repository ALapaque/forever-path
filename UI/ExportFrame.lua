local _, ns = ...
local L = ns.L

-- Fenêtre de copie pour exporter un guide enregistré
local f = CreateFrame("Frame", "ForeverPathExport", UIParent, "BackdropTemplate")
f:SetSize(520, 380)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
f:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
f:SetBackdropBorderColor(0.83, 0.69, 0.22, 0.9)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "ForeverPathExport") -- fermeture avec Échap

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.title:SetPoint("TOPLEFT", 10, -8)
f.title:SetText(L.EXPORT_TITLE)

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -30)
scroll:SetPoint("BOTTOMRIGHT", -30, 10)

local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(470)
edit:SetScript("OnEscapePressed", function() f:Hide() end)
scroll:SetScrollChild(edit)

function ns.ShowExport(text)
    edit:SetText(text)
    f:Show()
    edit:SetFocus()
    edit:HighlightText()
end
