-- RaidTracker.lua - Turtle WoW 1.12

-- Saved DB
RaidMembersData = RaidMembersData or {}
RaidTrackerMinimapButtonDB = RaidTrackerMinimapButtonDB or {}
local nextId = 1

-- Ottieni ora corrente in formato HH:MM
local function GetCurrentTime()
    return date("%H:%M")
end

-- ==========================
-- Finestra principale
-- ==========================
local frame = CreateFrame("Frame", "RaidTrackerFrame", UIParent)
frame:SetWidth(345)
frame:SetHeight(700)
frame:SetPoint("CENTER", UIParent, "CENTER", 413, 0)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.3)
frame:Hide()

-- Bottone chiudi
local close = CreateFrame("Button", "RaidTrackerCloseButton", frame, "UIPanelButtonTemplate")
close:SetWidth(20)
close:SetHeight(20)
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
close:SetText("X")
close:SetScript("OnClick", function()
    frame:Hide()
end)

-- Bottone Copia
local copyBtn = CreateFrame("Button", "RaidTrackerCopyButton", frame, "UIPanelButtonTemplate")
copyBtn:SetWidth(50)
copyBtn:SetHeight(20)
copyBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
copyBtn:SetText("Copy")

-- ==========================
-- ScrollFrame contenitore righe con bottoni
-- ==========================
local scrollFrame = CreateFrame("ScrollFrame", "RaidTrackerScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", "RaidTrackerContent", scrollFrame)
content:SetWidth(360)
content:SetHeight(1) -- sarà ridimensionato dinamicamente
scrollFrame:SetScrollChild(content)

-- Abilita rotellina e handler robusto compatibile TWOW 1.12
local invertMouseWheel = false  -- metti true se vuoi invertire la direzione

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
    -- In 1.12 il delta è in arg1 (variabile globale)
    local delta = arg1
    if not delta then return end  -- nessun valore, esci

    local cur = scrollFrame:GetVerticalScroll() or 0
    local max = scrollFrame:GetVerticalScrollRange() or 0
    local step = 20
    local new  = cur - delta * step   -- usa + se vuoi invertire

    if new < 0 then new = 0 end
    if new > max then new = max end

    scrollFrame:SetVerticalScroll(new)
end)



-- ==========================
-- Funzione refresh UI
-- ==========================
local function RefreshRaidUI()
    -- Pulisci righe precedenti
    local children = {content:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Crea lista ordinata dei nomi
    local names = {}
    for name, _ in pairs(RaidMembersData) do
        table.insert(names, name)
    end
    table.sort(names) -- ordina alfabeticamente

    local yOffset = -5
    local totalHeight = 0

    for _, name in ipairs(names) do
        local memberName = name                            -- copia locale per le closure
        local data = RaidMembersData[memberName] or {}

        local row = CreateFrame("Frame", nil, content)
        row:SetWidth(360)
        row:SetHeight(20)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

        -- valori di sicurezza per evitare nil
        local safeName  = tostring(data.name or memberName)
        local safeClass = tostring(data.class or "-")
        local safePts   = tonumber(data.points) or 0

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", row, "LEFT", 0, 0)
        text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")  -- <== font più grande (14) con bordo sottile
        local ok, sText = pcall(string.format, "%s (%s) - Points: %d", safeName, safeClass, safePts)
        if not ok or not sText then
            sText = tostring(safeName) .. " (" .. tostring(safeClass) .. ") - Points: " .. tostring(safePts)
        end
        text:SetText(sText)

        -- Bottone +
        local plus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        plus:SetWidth(20) plus:SetHeight(20)
        plus:SetPoint("RIGHT", row, "RIGHT", -95, 0)
        plus:SetText("+")
        plus:SetScript("OnClick", function()
            if not RaidMembersData[memberName] then
                local nid = nextId
                RaidMembersData[memberName] = {
                    id = nid,
                    name = memberName,
                    class = data.class or "-",
                    joinTime = data.joinTime or GetCurrentTime(),
                    leaveTime = data.leaveTime or "",
                    points = 0
                }
                nextId = nid + 1
            end
            RaidMembersData[memberName].points = (RaidMembersData[memberName].points or 0) + 1
            RefreshRaidUI()
        end)

        -- Bottone -
        local minus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        minus:SetWidth(20) minus:SetHeight(20)
        minus:SetPoint("RIGHT", row, "RIGHT", -75, 0)
        minus:SetText("-")
        minus:SetScript("OnClick", function()
            if not RaidMembersData[memberName] then
                local nid = nextId
                RaidMembersData[memberName] = {
                    id = nid,
                    name = memberName,
                    class = data.class or "-",
                    joinTime = data.joinTime or GetCurrentTime(),
                    leaveTime = data.leaveTime or "",
                    points = 0
                }
                nextId = nid + 1
            end
            RaidMembersData[memberName].points = (RaidMembersData[memberName].points or 0) - 1
            RefreshRaidUI()
        end)

        -- Bottone "x" (+3 punti)
        local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        reset:SetWidth(20) reset:SetHeight(20)
        reset:SetPoint("RIGHT", row, "RIGHT", -55, 0)
        reset:SetText("x")
        reset:SetScript("OnClick", function()
            if not RaidMembersData[memberName] then
                local nid = nextId
                RaidMembersData[memberName] = {
                    id = nid,
                    name = memberName,
                    class = data.class or "-",
                    joinTime = data.joinTime or GetCurrentTime(),
                    leaveTime = data.leaveTime or "",
                    points = 0
                }
                nextId = nid + 1
            end
            RaidMembersData[memberName].points = (RaidMembersData[memberName].points or 0) + 3
            RefreshRaidUI()
        end)

        yOffset = yOffset - 22
        totalHeight = totalHeight + 22
    end



    content:SetHeight(totalHeight)
end

-- Bottone "Reset"
local resetBtn = CreateFrame("Button", "RaidTrackerResetButton", frame, "UIPanelButtonTemplate")
resetBtn:SetWidth(60)
resetBtn:SetHeight(20)
resetBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -5) -- accanto al bottone Copia
resetBtn:SetText("Reset")
resetBtn:SetScript("OnClick", function()
    -- Finestra di conferma per sicurezza
    StaticPopupDialogs["RAIDTRACKER_RESET_CONFIRM"] = {
        text = "Vuoi davvero azzerare la lista?",
        button1 = "Si",
        button2 = "No",
        OnAccept = function()
            RaidMembersData = {}
            nextId = 1
            RefreshRaidUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("RAIDTRACKER_RESET_CONFIRM")
end)

local copyFrame, copyEditBox

-- Bottone " Boss Debuffs "

local buffBtn = CreateFrame("Button", "RaidTrackerBuffButton", frame, "UIPanelButtonTemplate")
buffBtn:SetWidth(60)
buffBtn:SetHeight(20)
buffBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -5)
buffBtn:SetText("BuffCheck")
buffBtn:SetScript("OnClick", function()
    RunBuffCheck()
end)

-- ==============
-- SHOWCOPYWINDOW
-- ===============

local function ShowCopyWindow()
    if not copyFrame then
        copyFrame = CreateFrame("Frame", "RaidTrackerCopyFrame", UIParent)
        copyFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        copyFrame:SetFrameLevel(20)
        copyFrame:SetWidth(350)
        copyFrame:SetHeight(300)
        copyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        copyFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        copyFrame:SetBackdropColor(0, 0, 0, 1)
        copyFrame:Hide()

        local close = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
        close:SetWidth(20) close:SetHeight(20)
        close:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -4, -4)
        close:SetText("X")
        close:SetScript("OnClick", function() copyFrame:Hide() end)

        -- ScrollFrame con barra laterale
        local scroll = CreateFrame("ScrollFrame", "RaidTrackerCopyScroll", copyFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 10, -30)
        scroll:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -30, 10)

        -- EditBox più alto del frame così il contenuto è scrollabile
        copyEditBox = CreateFrame("EditBox", nil, scroll)
        copyEditBox:SetMultiLine(true)
        copyEditBox:SetWidth(310)
        copyEditBox:SetHeight(1000)             -- <<< altezza grande, importante
        copyEditBox:SetAutoFocus(false)
        copyEditBox:SetFont("Fonts\\ARIALN.TTF", 12)
        copyEditBox:EnableMouse(true)
        copyEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(copyEditBox)

        -- Rotellina mouse (come per la finestra principale)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function()
            local delta = arg1        -- WoW 1.12 passa il delta in arg1
            if not delta then return end
            local cur = scroll:GetVerticalScroll() or 0
            local max = scroll:GetVerticalScrollRange() or 0
            local step = 20
            local new  = cur - delta * step
            if new < 0 then new = 0 end
            if new > max then new = max end
            scroll:SetVerticalScroll(new)
        end)
    end

    -- raccogli e ordina i nomi
    local names = {}
    for name in pairs(RaidMembersData) do table.insert(names, name) end
    table.sort(names)

    -- Se non ci sono membri, mostra messaggio
    if next(names) == nil then
        copyEditBox:SetText("Nessun membro nel DB di RaidTracker.")
        copyEditBox:HighlightText()
        copyFrame:Show()
        return
    end

    -- Trova lunghezza massima di "Nome (Classe)"
    local maxLabelLen = 0
    for _, name in ipairs(names) do
        local data = RaidMembersData[name] or {}
        local label = tostring(data.name or name) .. " (" .. tostring(data.class or "-") .. ")"
        local labelLen = string.len(label)
        if labelLen > maxLabelLen then maxLabelLen = labelLen end
    end

    -- Costruisci formato dinamico: riserva spazio sufficiente per tutte le etichette
    local labelFieldWidth = maxLabelLen + 2 -- +2 spazi di separazione
    local fmt = "[%02d] %-" .. tostring(labelFieldWidth) .. "s In:%-6s Out:%-6s Pts:%-3d"

    -- Crea le righe in modo completamente sicuro
    local lines = {}
    for _, name in ipairs(names) do
        local d = RaidMembersData[name] or {}

        local id       = tonumber(d.id)       or 0
        local label    = string.format("%s (%s)", tostring(d.name or name), tostring(d.class or "-"))
        local joinStr  = tostring(d.joinTime or "-")
        local leaveStr = tostring(d.leaveTime or "-")
        local pts      = tonumber(d.points)   or 0

        -- pcall per intercettare eventuali errori di format
        local ok, line = pcall(string.format, fmt, id, label, joinStr, leaveStr, pts)
        if not ok then
            line = string.format("[%02d] %s In:%s Out:%s Pts:%d",
                                 id, label, joinStr, leaveStr, pts)
        end

        table.insert(lines, line)
    end


    local outputPlain = table.concat(lines, "\n")
    copyEditBox:SetText(outputPlain)


    copyEditBox:HighlightText()
    copyFrame:Show()
end


copyBtn:SetScript("OnClick", ShowCopyWindow)


-- ==========================
-- Aggiorna dati raid
-- ==========================
local function UpdateRaidMembers()
    local currentRaid = {}
    local num = GetNumRaidMembers() or 0

    for i = 1, num do
        local name, _, _, _, class = GetRaidRosterInfo(i)
        if name and name ~= "" then
            currentRaid[name] = true
            if not RaidMembersData[name] then
                RaidMembersData[name] = {
                    id = nextId,
                    name = name,
                    class = class or "Unknown",
                    joinTime = GetCurrentTime(),
                    leaveTime = "",
                    points = 0
                }
                nextId = nextId + 1
            elseif RaidMembersData[name].leaveTime ~= "" then
                RaidMembersData[name].leaveTime = ""
            end
        end
    end

    -- Segna chi è uscito
    for name, data in pairs(RaidMembersData) do
        if data.leaveTime == "" and not currentRaid[name] then
            data.leaveTime = GetCurrentTime()
        end
    end

    RefreshRaidUI()
end

-- ==========================
-- Evento RAID_ROSTER_UPDATE
-- ==========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", UpdateRaidMembers)

-- ==========================
-- Popup reset e ricarica raid (compatibile Turtle WoW 1.12)
-- ==========================
local resetFrame = CreateFrame("Frame")
resetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
resetFrame:RegisterEvent("RAID_ROSTER_UPDATE")

local wasInRaid = false

resetFrame:SetScript("OnEvent", function()
    local inRaid = (GetNumRaidMembers() or 0) > 0

    -- Mostra il popup solo quando si passa da fuori raid a dentro raid
    if inRaid and not wasInRaid then
        StaticPopupDialogs["RAIDTRACKER_RESET_CONFIRM"] = {
            text = "You'have joined a new raid. Do you want to reset the previous data and load the new list?",
            button1 = "Si",
            button2 = "No",
            OnAccept = function()
                -- 1. Svuota dati precedenti
                RaidMembersData = {}
                nextId = 1
                -- 2. Popola subito con i membri del raid attuale
                UpdateRaidMembers()
                RefreshRaidUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("RAIDTRACKER_RESET_CONFIRM")
    end

    wasInRaid = inRaid
end)


-- ==========================
-- Slash command /rt
-- ==========================
SLASH_RAIDTRACKER1 = "/rt"
SlashCmdList["RAIDTRACKER"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        RefreshRaidUI()
        frame:Show()
    end
end

-- ==========================
-- Pulsante minimappa
-- ==========================
local minimapButton = CreateFrame("Button", "RaidTrackerMinimapButton", Minimap)
minimapButton:SetWidth(23)
minimapButton:SetHeight(23)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetClampedToScreen(true)

local function SetMinimapButtonPosition()
    if RaidTrackerMinimapButtonDB.x and RaidTrackerMinimapButtonDB.y then
        minimapButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", RaidTrackerMinimapButtonDB.x, RaidTrackerMinimapButtonDB.y)
    else
        minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    end
end
SetMinimapButtonPosition()

local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints(minimapButton)
icon:SetTexture("Interface\\Icons\\INV_Potion_01")
icon:SetAlpha(1)

minimapButton:SetScript("OnClick", function()
    if SlashCmdList["RAIDTRACKER"] then
        SlashCmdList["RAIDTRACKER"]()
    end
end)

minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText("Raid Tracker\nClicca per aprire")
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

minimapButton:EnableMouse(true)
minimapButton:SetMovable(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function()
    minimapButton:StartMoving()
end)
minimapButton:SetScript("OnDragStop", function()
    minimapButton:StopMovingOrSizing()
    local x, y = minimapButton:GetLeft(), minimapButton:GetTop()
    if x and y then
        RaidTrackerMinimapButtonDB.x = math.floor(x + 0.5)
        RaidTrackerMinimapButtonDB.y = math.floor(y + 0.5)
    end
end)

minimapButton:Show()


-- =========================================== BOSS DEBUFFS ===============

function RunBuffCheck()
    if not UnitExists("target") or UnitIsFriend("player", "target") then
        DEFAULT_CHAT_FRAME:AddMessage("You must target an Enemy.")
        return
    end

    local debuffs = {
        ["Sunder Armor"] = {count = 0, max = 5},
        ["Faerie Fire"] = {found = false},
        ["Curse of the Elements"] = {found = false},
        ["Curse of Shadow"] = {found = false},
        ["Curse of Recklessness"] = {found = false},
    }

    -- Debuff 1–16 tramite UnitDebuff
    for i = 1, 16 do
        local debuffName, _, count = UnitDebuff("target", i)
        if not debuffName then break end
        if debuffName == "Sunder Armor" then
            debuffs["Sunder Armor"].count = count or 1
        elseif debuffs[debuffName] then
            debuffs[debuffName].found = true
        end
    end

    -- Debuff 17–48 trasformati in buff
    for i = 1, 32 do
        local buffName, _, count = UnitBuff("target", i)
        if not buffName then break end
        if buffName == "Sunder Armor" then
            debuffs["Sunder Armor"].count = count or 1
        elseif debuffs[buffName] then
            debuffs[buffName].found = true
        end
    end

    -- Output in una sola linea
    local msg = string.format(
        "Sunder %d/%d FF:%s E:%s S:%s R:%s",
        debuffs["Sunder Armor"].count,
        debuffs["Sunder Armor"].max,
        debuffs["Faerie Fire"].found and "y" or "n",
        debuffs["Curse of the Elements"].found and "y" or "n",
        debuffs["Curse of Shadow"].found and "y" or "n",
        debuffs["Curse of Recklessness"].found and "y" or "n"
    )
    SendChatMessage(msg, "SAY")

end

-- Se vuoi tenere anche la slash command /buff:
SLASH_RAIDBUFFCHECK1 = "/buff"
SlashCmdList["RAIDBUFFCHECK"] = RunBuffCheck

