local addonName, addon = ...

addon.defaults = {
    pos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
    scale = 1.0,
    minimized = false,
}

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then
        return dst
    end

    if type(dst) ~= "table" then
        dst = {}
    end

    for key, value in pairs(src) do
        if type(value) == "table" then
            dst[key] = CopyDefaults(value, dst[key])
        elseif dst[key] == nil then
            dst[key] = value
        end
    end

    return dst
end

function addon:InitializeDB()
    XPTimerReduxDB = CopyDefaults(self.defaults, XPTimerReduxDB)
    self.db = XPTimerReduxDB
end

function addon:SaveFramePosition(frame)
    if not frame or not self.db then
        return
    end

    local point, _, relPoint, x, y = frame:GetPoint(1)
    self.db.pos.point = point
    self.db.pos.relPoint = relPoint
    self.db.pos.x = x
    self.db.pos.y = y
end

function addon:ApplyFramePosition(frame)
    if not frame or not self.db or not self.db.pos then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(self.db.pos.point, UIParent, self.db.pos.relPoint, self.db.pos.x, self.db.pos.y)
end

function addon:SetScale(scale)
    if not self.db then
        return false
    end

    local numericScale = tonumber(scale)
    if not numericScale then
        return false
    end

    numericScale = max(0.5, min(2.0, numericScale))
    self.db.scale = numericScale

    if self.UI and self.UI.frame then
        self.UI.frame:SetScale(numericScale)
    end

    return true
end
