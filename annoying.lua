local DEFAULTS = {
    cd  = 10,
    say = false
}

local lastSent = {}
local sendingFromBox = false
local restoreText = nil

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|annoying|r: " .. msg)
end

local function ChannelKey(chatType, target)
    if chatType == "CHANNEL" then
        local _, name = GetChannelName(target)
        return "CHANNEL:" .. string.lower(name or tostring(target))
    end
    return chatType
end

local function IsTracked(chatType)
    if chatType == "CHANNEL" then return true end
    if annoyingDB.say and (chatType == "SAY" or chatType == "YELL") then return true end
    return false
end

local origSendChatMessage = SendChatMessage
SendChatMessage = function(msg, chatType, language, target, ...)
    local ct = chatType and string.upper(chatType) or "SAY"
    if annoyingDB and IsTracked(ct) then
        local key = ChannelKey(ct, target)
        local now = GetTime()
        local last = lastSent[key]
        if last and now - last < annoyingDB.cd then
            local left = annoyingDB.cd - (now - last)
            Print(string.format("|cffff4040chat cooldown: %.1f с|r", left))
            UIErrorsFrame:AddMessage(string.format("chat cooldown: %.1f с", left), 1, 0.25, 0.25, 1, 2)
            if sendingFromBox then restoreText = msg end
            return
        end
        lastSent[key] = now
    end
    return origSendChatMessage(msg, chatType, language, target, ...)
end

local origEditSend = ChatEdit_SendText
ChatEdit_SendText = function(editBox, addHistory)
    sendingFromBox = true
    local ok, err = pcall(origEditSend, editBox, addHistory)
    sendingFromBox = false
    if not ok then error(err) end
end

hooksecurefunc("ChatEdit_OnEnterPressed", function(self)
    if restoreText then
        local text = restoreText
        restoreText = nil
        ChatFrame_OpenChat(text)
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name ~= "annoying" then return end
    annoyingDB = annoyingDB or {}
    for k, v in pairs(DEFAULTS) do
        if annoyingDB[k] == nil then annoyingDB[k] = v end
    end
    self:UnregisterEvent("ADDON_LOADED")
end)
