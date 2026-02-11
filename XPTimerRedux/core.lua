local addonName, addon = ...

addon.state = {
    sessionStartTime = 0,
    accumulatedElapsed = 0,
    running = true,
    sessionXP = 0,
    lastXP = 0,
    lastXPMax = 0,
    lastLevel = 0,
    initialized = false,
    tickerElapsed = 0,
}

local function SafeRound(value)
    if not value then
        return 0
    end

    return floor(value + 0.5)
end

function addon:FormatTime(seconds)
    if not seconds or seconds < 0 then
        seconds = 0
    end

    local totalSeconds = floor(seconds)
    local hours = floor(totalSeconds / 3600)
    local minutes = floor((totalSeconds % 3600) / 60)
    local secs = totalSeconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function addon:GetElapsedSeconds()
    local state = self.state
    local elapsed = state.accumulatedElapsed or 0

    if state.running and state.sessionStartTime and state.sessionStartTime > 0 then
        elapsed = elapsed + max(0, time() - state.sessionStartTime)
    end

    return max(0, elapsed)
end

function addon:StartTracking()
    if self.state.running then
        return
    end

    self.state.sessionStartTime = time()
    self.state.running = true

    if self.UI then
        self.UI:SetTrackingState(true)
    end

    self:UpdateUI()
end

function addon:StopTracking()
    if not self.state.running then
        return
    end

    self.state.accumulatedElapsed = self:GetElapsedSeconds()
    self.state.sessionStartTime = 0
    self.state.running = false

    if self.UI then
        self.UI:SetTrackingState(false)
    end

    self:UpdateUI()
end

function addon:ToggleTracking()
    if self.state.running then
        self:StopTracking()
    else
        self:StartTracking()
    end
end

function addon:ResetSession()
    self.state.accumulatedElapsed = 0
    self.state.sessionStartTime = time()
    self.state.running = true
    self.state.sessionXP = 0
    self.state.lastXP = UnitXP("player") or 0
    self.state.lastXPMax = UnitXPMax("player") or 0
    self.state.lastLevel = UnitLevel("player") or 0

    if self.UI then
        self.UI:SetTrackingState(true)
    end

    self:UpdateUI()
end

function addon:ProcessXPChange()
    if not self.state.running then
        self.state.lastXP = UnitXP("player") or 0
        self.state.lastXPMax = UnitXPMax("player") or 0
        self.state.lastLevel = UnitLevel("player") or 0
        return
    end

    local state = self.state
    local currentXP = UnitXP("player") or 0
    local currentXPMax = UnitXPMax("player") or 0
    local currentLevel = UnitLevel("player") or 0

    if not state.initialized then
        state.lastXP = currentXP
        state.lastXPMax = currentXPMax
        state.lastLevel = currentLevel
        state.initialized = true
        return
    end

    local gainedXP = 0
    if currentLevel > state.lastLevel then
        gainedXP = max(0, (state.lastXPMax - state.lastXP) + currentXP)
    elseif currentLevel == state.lastLevel then
        if currentXP >= state.lastXP then
            gainedXP = currentXP - state.lastXP
        else
            gainedXP = 0
        end
    else
        gainedXP = 0
    end

    state.sessionXP = state.sessionXP + max(0, gainedXP)
    state.lastXP = currentXP
    state.lastXPMax = currentXPMax
    state.lastLevel = currentLevel
end

function addon:BuildUIData()
    local currentXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 0
    local level = UnitLevel("player") or 0
    local elapsed = self:GetElapsedSeconds()

    local percent = 0
    if maxXP > 0 then
        percent = (currentXP / maxXP) * 100
    end

    local xpPerHour
    if elapsed >= 1 and self.state.sessionXP > 0 then
        xpPerHour = (self.state.sessionXP / elapsed) * 3600
    end

    local ttl
    if xpPerHour and xpPerHour > 0 and maxXP > 0 then
        local remainingXP = max(0, maxXP - currentXP)
        ttl = (remainingXP / xpPerHour) * 3600
    end

    return {
        levelText = tostring(level),
        xpText = string.format("%d / %d (%.1f%%)", currentXP, maxXP, percent),
        sessionXPText = tostring(self.state.sessionXP),
        xpPerHourText = xpPerHour and tostring(SafeRound(xpPerHour)) or "—",
        ttlText = ttl and self:FormatTime(ttl) or "—",
        elapsedText = self:FormatTime(elapsed),
    }
end

function addon:UpdateUI()
    if not self.UI or not self.UI.frame then
        return
    end

    self.UI:Update(self:BuildUIData())
end

function addon:HandleSlashCommand(input)
    local command, value = strsplit(" ", (input or ""), 2)
    command = string.lower(command or "")

    if command == "show" then
        self.UI:SetVisible(true)
    elseif command == "hide" then
        self.UI:SetVisible(false)
    elseif command == "reset" then
        self:ResetSession()
    elseif command == "start" then
        self:StartTracking()
    elseif command == "stop" then
        self:StopTracking()
    elseif command == "scale" then
        if self:SetScale(value) then
            print("XPTimerRedux: scale set to " .. string.format("%.2f", self.db.scale))
        else
            print("XPTimerRedux: usage /xpt scale <number>")
        end
    else
        print("XPTimerRedux commands: /xpt show | hide | reset | start | stop | scale <number>")
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        addon:InitializeDB()
        addon.UI:CreateMainFrame()
        addon:ResetSession()
        addon.state.initialized = true
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        addon:ProcessXPChange()
    end

    addon:UpdateUI()
end)

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    addon.state.tickerElapsed = addon.state.tickerElapsed + elapsed
    if addon.state.tickerElapsed >= 1 then
        addon.state.tickerElapsed = 0
        addon:UpdateUI()
    end
end)

SLASH_XPTIMERREDUX1 = "/xpt"
SlashCmdList.XPTIMERREDUX = function(msg)
    addon:HandleSlashCommand(msg)
end
