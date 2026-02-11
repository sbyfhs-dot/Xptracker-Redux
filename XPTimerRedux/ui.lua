local addonName, addon = ...

addon.UI = addon.UI or {}

local PADDING = 10
local ROW_HEIGHT = 16
local HEADER_HEIGHT = 24
local CONTENT_WIDTH = 250

local function CreateValueRow(parent, label)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetText(label)

    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value:SetJustifyH("RIGHT")
    row.value:SetText("—")

    row.label:SetWidth(CONTENT_WIDTH * 0.55)
    row.value:SetWidth(CONTENT_WIDTH * 0.40)

    return row
end

local function SetMinimized(minimized)
    local frame = addon.UI.frame
    if not frame then
        return
    end

    addon.db.minimized = minimized and true or false
    frame.content:SetShown(not addon.db.minimized)
    frame.minimizeButton:SetText(addon.db.minimized and "+" or "-")

    local totalHeight = HEADER_HEIGHT + (PADDING * 2)
    if not addon.db.minimized then
        totalHeight = totalHeight + frame.content:GetHeight() + 4
    end

    frame:SetHeight(totalHeight)
end

function addon.UI:CreateMainFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", "XPTimerReduxFrame", UIParent, "BackdropTemplate")
    frame:SetSize(CONTENT_WIDTH + (PADDING * 2), 180)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        addon:SaveFramePosition(self)
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    title:SetText("XP Tracker")
    frame.title = title

    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(46, 18)
    resetButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -58, -7)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        addon:ResetSession()
    end)
    frame.resetButton = resetButton

    local startStopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    startStopButton:SetSize(42, 18)
    startStopButton:SetPoint("RIGHT", resetButton, "LEFT", -2, 0)
    startStopButton:SetText("Stop")
    startStopButton:SetScript("OnClick", function()
        addon:ToggleTracking()
    end)
    frame.startStopButton = startStopButton

    local minimizeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    minimizeButton:SetSize(22, 18)
    minimizeButton:SetPoint("LEFT", resetButton, "RIGHT", 2, 0)
    minimizeButton:SetText("-")
    minimizeButton:SetScript("OnClick", function()
        SetMinimized(not addon.db.minimized)
    end)
    frame.minimizeButton = minimizeButton

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -(HEADER_HEIGHT + 2))
    content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(HEADER_HEIGHT + 2))
    frame.content = content

    local rows = {}
    rows.level = CreateValueRow(content, "Level")
    rows.level:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    rows.level:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    rows.xp = CreateValueRow(content, "XP")
    rows.xp:SetPoint("TOPLEFT", rows.level, "BOTTOMLEFT", 0, -4)
    rows.xp:SetPoint("TOPRIGHT", rows.level, "BOTTOMRIGHT", 0, -4)

    rows.sessionXP = CreateValueRow(content, "Session XP")
    rows.sessionXP:SetPoint("TOPLEFT", rows.xp, "BOTTOMLEFT", 0, -4)
    rows.sessionXP:SetPoint("TOPRIGHT", rows.xp, "BOTTOMRIGHT", 0, -4)

    rows.xpPerHour = CreateValueRow(content, "XP/hour")
    rows.xpPerHour:SetPoint("TOPLEFT", rows.sessionXP, "BOTTOMLEFT", 0, -4)
    rows.xpPerHour:SetPoint("TOPRIGHT", rows.sessionXP, "BOTTOMRIGHT", 0, -4)

    rows.ttl = CreateValueRow(content, "Time to level")
    rows.ttl:SetPoint("TOPLEFT", rows.xpPerHour, "BOTTOMLEFT", 0, -4)
    rows.ttl:SetPoint("TOPRIGHT", rows.xpPerHour, "BOTTOMRIGHT", 0, -4)

    rows.elapsed = CreateValueRow(content, "Time elapsed")
    rows.elapsed:SetPoint("TOPLEFT", rows.ttl, "BOTTOMLEFT", 0, -4)
    rows.elapsed:SetPoint("TOPRIGHT", rows.ttl, "BOTTOMRIGHT", 0, -4)

    rows.elapsed:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    rows.elapsed:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local contentHeight = ((ROW_HEIGHT + 4) * 6) - 4
    content:SetHeight(contentHeight)

    frame.rows = rows
    self.frame = frame

    addon:ApplyFramePosition(frame)
    frame:SetScale(addon.db.scale or 1.0)

    SetMinimized(addon.db.minimized)

    return frame
end

function addon.UI:SetVisible(isShown)
    if not self.frame then
        return
    end

    if isShown then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function addon.UI:SetTrackingState(isRunning)
    if not self.frame or not self.frame.startStopButton then
        return
    end

    self.frame.startStopButton:SetText(isRunning and "Stop" or "Start")
end

function addon.UI:Update(data)
    if not self.frame or not data then
        return
    end

    local rows = self.frame.rows
    rows.level.value:SetText(data.levelText)
    rows.xp.value:SetText(data.xpText)
    rows.sessionXP.value:SetText(data.sessionXPText)
    rows.xpPerHour.value:SetText(data.xpPerHourText)
    rows.ttl.value:SetText(data.ttlText)
    rows.elapsed.value:SetText(data.elapsedText)
end
