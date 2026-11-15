local _, ns = ...
local L = ns.L

-- Fenêtre de copie / collage (export d'une route, import de chemins partagés)
local f = CreateFrame("Frame", "QuestweaverExport", UIParent, "BackdropTemplate")
f:SetSize(520, 380)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
ns.Skin(f, 0.96)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "QuestweaverExport") -- fermeture avec Échap

f.title = f:CreateFontString(nil, "OVERLAY", "QuestweaverFontNormal")
f.title:SetPoint("TOPLEFT", 10, -8)
f.title:SetText(L.EXPORT_TITLE)

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -30)
scroll:SetPoint("BOTTOMRIGHT", -30, 38)

local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(470)
edit:SetScript("OnEscapePressed", function() f:Hide() end)
scroll:SetScrollChild(edit)

local ok = ns.Button(f, "Importer", 100, 22)
ok:SetPoint("BOTTOMRIGHT", -10, 10)
ok:Hide()

function ns.ShowExport(text, title)
    f.title:SetText(title or L.EXPORT_TITLE)
    ok:Hide()
    edit:SetText(text)
    f:Show()
    edit:SetFocus()
    edit:HighlightText()
end

-- Fenêtre de collage : onImport(text) est appelé au clic sur « Importer »
function ns.ShowImport(title, onImport)
    f.title:SetText(title)
    edit:SetText("")
    ok:SetScript("OnClick", function()
        onImport(edit:GetText())
        f:Hide()
    end)
    ok:Show()
    f:Show()
    edit:SetFocus()
end
