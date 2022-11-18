local _, ADDONSELF = ...
ADDONSELF.bid = {
}
local BID = ADDONSELF.bid
local L = ADDONSELF.L
local ScrollingTable = ADDONSELF.st
local RegEvent = ADDONSELF.regevent
local Database = ADDONSELF.db
local Print = ADDONSELF.print
local Print_Dump = ADDONSELF.print_dump
local GetMoneyStringL = ADDONSELF.GetMoneyStringL

function BID:Init()
-- bf frame
local GUI = ADDONSELF.gui
local bf = CreateFrame("Frame", nil, GUI.mainframe, BackdropTemplateMixin and "BackdropTemplate" or nil)
bf:SetWidth(290)
bf:SetHeight(400)
bf:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    -- tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 10, bottom = 10}
})

-- bf:SetBackdropColor(1, 1, 1, 1)
bf:SetPoint("CENTER", GUI.mainframe, 0, 0)
bf:SetToplevel(true)
bf:EnableMouse(true)
bf:SetFrameLevel(GUI.mainframe:GetFrameLevel() + 10)
bf:SetMovable(true)
bf:RegisterForDrag("LeftButton")
bf:SetScript("OnDragStart", bf.StartMoving)
bf:SetScript("OnDragStop", bf.StopMovingOrSizing)

do
    local b = CreateFrame("Button", nil, bf, "UIPanelCloseButton")
    b:SetPoint("TOPRIGHT", bf, 0, 0);
end

do
    local tooltip = GUI.itemtooltip

    local itemTexture = bf:CreateTexture()
    itemTexture:SetTexCoord(0, 1, 0, 1)
    itemTexture:Show()
    itemTexture:SetPoint("TOPLEFT", bf, 20, -20)
    itemTexture:SetWidth(30)
    itemTexture:SetHeight(30)            
    itemTexture:SetTexture(134400) -- question mark


    bf.itemTexture = itemTexture

    local stackCounTtext = bf:CreateFontString(nil, 'OVERLAY')
    stackCounTtext:SetFontObject('NumberFontNormal')
    stackCounTtext:SetPoint('BOTTOMRIGHT', itemTexture, -3, 3)
    stackCounTtext:SetJustifyH('RIGHT')

    local itemtext = CreateFrame("Button", nil, bf)
    itemtext.text = itemtext:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemtext.text:SetPoint("LEFT", itemtext, "LEFT", 45, 0)
    itemtext.text:SetWidth(230)
    itemtext.text:SetJustifyH("LEFT")

    itemtext:SetPoint('LEFT', itemTexture, "RIGHT", -40, 0)
    itemtext:SetSize(30, 30)
    itemtext:EnableMouse(true)
    itemtext:RegisterForClicks("AnyUp")
    itemtext:SetScript("OnClick", function()
        ChatEdit_InsertLink(itemtext.link)
    end)

    itemtext:SetScript("OnEnter", function()
        if itemtext.link then
            tooltip:SetOwner(itemtext, "ANCHOR_CURSOR")
            tooltip:SetHyperlink(itemtext.link)
            tooltip:Show()
        end
    end)

    itemtext:SetScript("OnLeave", function()
        tooltip:Hide()
        tooltip:SetOwner(itemtext, "ANCHOR_NONE")
    end)

    local sameItemCountText = bf:CreateFontString(nil, 'OVERLAY')
    sameItemCountText:SetFontObject('NumberFontNormal')
    sameItemCountText:SetPoint('RIGHT', itemtext, 50, 3)
    sameItemCountText:SetTextColor(1,0,0)
    sameItemCountText:SetTextHeight(20)
    sameItemCountText:SetJustifyH('RIGHT')

    bf.SetItem = function(self, item, entry, entryIndex)
        self.curEntry = entry
        self.sameItemCount = 1
        self.sameItemEntry = {}
        self.stackCount = entry["detail"]["count"]
        -- calculate item count
        for idx, entry in pairs(Database:GetCurrentLedger()["items"]) do
            if entry.detail then
                if entry.detail.item == item and not (entryIndex == idx) then
                    self.sameItemCount = self.sameItemCount + 1
                    table.insert(self.sameItemEntry,1,entry)
                end
            end
        end
        if self.sameItemCount >1 then
            sameItemCountText:SetText("X"..self.sameItemCount)
            bf.batchBidCheck:SetChecked(true)
            bf.batchBidCheck.text:SetTextColor(unpack(bf.batchBidCheck.text.defaultTextColor))
        else
            sameItemCountText:SetText("")
            bf.batchBidCheck:SetChecked(false)
            bf.batchBidCheck.text:SetTextColor(.5,.5,.5)
        end
        stackCounTtext:SetText("1")

        if tonumber(self.stackCount) then
            stackCounTtext:SetText(self.stackCount)
        end
        itemTexture:SetTexture(134400)

        local _, itemLink = GetItemInfo(item)
        if itemLink then
            itemtext.link = itemLink
            itemtext.text:SetText(itemLink)
            itemtext:SetWidth(math.min(230, itemtext.text:GetStringWidth() + 45))

        else
            itemtext.link = nil
            itemtext.text:SetText(item)
        end

        local itemTexture =  GetItemIcon(item)

        if itemTexture then
            bf.itemTexture:SetTexture(itemTexture)
        end

        bf.startprice:SetValue(Database:GetConfigOrDefault("defaultbidstartingprice", 500))
        bf.bidmode.usegold.slide:SetValue(Database:GetConfigOrDefault("defaultbidincrement", 100))

    end

end

local slideShowMoneyFrame = function(self, button)
    if button == "RightButton" then
        self:SetValueStep(1)
        OpenStackSplitFrame(999999, self, "BOTTOMLEFT", "TOPLEFT", 1)
        StackSplitText:SetText(self:GetValue())
        StackSplitFrame.split = self:GetValue()
        UpdateStackSplitFrame(999999)
    else
        StackSplitFrame:Hide()
        self:SetValueStep(self.slidestep)
        self:SetMinMaxValues(self.slidemin, self.slidemax)
    end

end

local slideMoneySet = function(owner, split)
    if owner.moneyslide then
        local min = math.min(split, owner.slidemin)
        local max = math.max(split, owner.slidemax)
        owner:SetMinMaxValues(min, max)
        owner:SetValueStep(1)
        owner:SetValue(split)
    end
end

do
    hooksecurefunc(StackSplitText, "SetText", function(self, value)
        if StackSplitFrame.owner.moneyslide then
            if not strfind(value, "MoneyFrame") then
                self:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(value))
            end
        end
    end)
end


do
    local s = CreateFrame("Slider", nil, bf, "OptionsSliderTemplate")
    s:SetOrientation('HORIZONTAL')
    s:SetHeight(14)
    s:SetWidth(160)
    s:SetMinMaxValues(5, 60)
    s:SetValueStep(1)
    s:SetObeyStepOnDrag(true)
    s.Low:SetText(SecondsToTime(5))
    s.High:SetText(SecondsToTime(60))

    local l = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("RIGHT", s, "LEFT", -20, 1)
    l:SetText(L["Count down time"])
    bf:SetWidth(math.max(bf:GetWidth(), l:GetStringWidth() + 220))


    s:SetPoint("TOPLEFT", bf, 40 + l:GetStringWidth(), -70)

    s:SetScript("OnValueChanged", function(self, value)
        s.Text:SetText(SecondsToTime(value))
    end)

    s:SetValue(30)

    bf.countdown = s
end

do
    local tooltip = GUI.commtooltip

    local s = CreateFrame("Slider", nil, bf, "OptionsSliderTemplate")
    s:SetOrientation('HORIZONTAL')
    s:SetHeight(14)
    s:SetWidth(160)
    s:SetMinMaxValues(50, 5000)
    s:SetValueStep(50)
    s:SetObeyStepOnDrag(true)
    s.Low:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(50))
    s.High:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(5000))

    local l = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("RIGHT", s, "LEFT", -20, 1)
    l:SetText(L["Starting price"])
    bf:SetWidth(math.max(bf:GetWidth(), l:GetStringWidth() + 220))


    s:SetPoint("TOPLEFT", bf, 40 + l:GetStringWidth(), -120)

    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        s.Text:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(value))
    end)

    s.moneyslide = true
    s.SplitStack = slideMoneySet
    s.slidestep = s:GetValueStep()
    s.slidemin, s.slidemax = s:GetMinMaxValues()
    s:SetScript("OnMouseDown", slideShowMoneyFrame)
    s:SetScript("OnMouseUp", slideShowMoneyFrame)

    s:SetScript("OnEnter", function()
        tooltip:SetOwner(s, "ANCHOR_RIGHT")
        tooltip:SetText(L["Right click to fine-tune"])
        tooltip:Show()
    end)

    s:SetScript("OnLeave", function()
        tooltip:Hide()
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end)

    s:SetValue(Database:GetConfigOrDefault("defaultbidstartingprice",500))

    bf.startprice = s
end

do
    local l = bf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("TOPLEFT", bf, 20, -160)
    l:SetText(L["Bid mode"])

    local usegold
    local usepercent

    local ensurechecked = function(self)
        if self == usegold then
            usepercent:SetChecked(not usegold:GetChecked())
            return
        end

        if self == usepercent then
            usegold:SetChecked(not usepercent:GetChecked())
            return
        end

        if usegold:GetChecked() then
            usepercent:SetChecked(false)
            return
        end

        if usepercent:GetChecked() then
            usegold:SetChecked(false)
            return
        end

        usegold:SetChecked(true)
        usepercent:SetChecked(false)
    end

    bf.GetBidMode = function()
        if usegold:GetChecked() then
            return "GOLD", usegold.slide:GetValue(), usegold.check:GetChecked(), bf.batchBidCheck:GetChecked()
        end

        if usepercent:GetChecked() then
            return "PERCENT", usepercent.slide:GetValue(), bf.batchBidCheck:GetChecked()
        end                
    end

    local ensureone = function(self)
        ensurechecked(self)
        usegold.slide:Hide()
        usegold.check:Hide()
        usepercent.slide:Hide()

        if usegold:GetChecked() then
            usegold.slide:Show()
            usegold.check:Show()
        end

        if usepercent:GetChecked() then
            usepercent.slide:Show()
        end                
    end

    do
        local b = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")
        b:SetPoint("TOPLEFT", bf, 30 + l:GetStringWidth(), -150)

        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
        b.text:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(""))
        b:SetScript("OnClick", ensureone)

        usegold = b
        l.usegold = b


        do
            local tooltip = GUI.commtooltip

            local s = CreateFrame("Slider", nil, bf, "OptionsSliderTemplate")
            s:SetOrientation('HORIZONTAL')
            s:SetHeight(14)
            s:SetWidth(160)
            s:SetMinMaxValues(10, 500)
            s:SetValueStep(10)
            s:SetObeyStepOnDrag(true)
            s.Low:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(10))
            s.High:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(500))
    
            local l = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            l:SetPoint("RIGHT", s, "LEFT", -20, 1)
            l:SetText(L["Bid increment"])

            bf:SetWidth(math.max(bf:GetWidth(), l:GetStringWidth() + 220))

            s:SetPoint("TOPLEFT", bf, 40 + l:GetStringWidth(), -200)

            s:SetScript("OnValueChanged", function(self, value)
                value = math.floor(value)
                s.Text:SetText(GOLD_AMOUNT_TEXTURE_STRING:format(value))
            end)

            s.moneyslide = true
            s.SplitStack = slideMoneySet
            s.slidestep = s:GetValueStep()
            s.slidemin, s.slidemax = s:GetMinMaxValues()
            s:SetScript("OnMouseDown", slideShowMoneyFrame)
            s:SetScript("OnMouseUp", slideShowMoneyFrame)

            s:SetScript("OnEnter", function()
                tooltip:SetOwner(s, "ANCHOR_RIGHT")
                tooltip:SetText(L["Right click to fine-tune"])
                tooltip:Show()
            end)

            s:SetScript("OnLeave", function()
                tooltip:Hide()
                tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            end)

            s:SetValue(Database:GetConfigOrDefault("defaultbidincrement", 100))
            s:Hide()

            b.slide = s
        end

        -- support smart bid mode: autofit bid price
        do
            local tt = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")            
            tt.text = tt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tt.text:SetPoint("RIGHT", tt, "Left", -10, 1)
            tt.text:SetText(L["SmartBidMode(autofit bid price)"])
            tt:SetPoint("TOPLEFT", bf, 30 + tt.text:GetStringWidth(), -230)
            tt:SetScript("OnClick", function()
                if tt:GetChecked() then
                    bf.bidmode.usegold.slide:SetValue(math.floor(bf.bidmode.usegold.slide:GetValue() / 100) * 100)
                end
            end)
            tt:SetChecked(true)
            b.check = tt
        end

        -- support batch bid mode: sell same item in one bid
        do
            local tt = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")        
            tt.text = tt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tt.text:SetPoint("RIGHT", tt, "Left", -10, 1)
            tt.text:SetText(L["BatchBidMode(same item in one bid)"])
            tt:SetPoint("TOPLEFT", bf, 30 + tt.text:GetStringWidth(), -260)
            tt:SetScript("OnClick", function()
                if bf.sameItemCount < 2 then
                    tt:SetChecked(false)
                end
            end)
            tt:SetChecked(false)
            local r,g,b,a = tt.text:GetTextColor()
            tt.text.defaultTextColor = {r,g,b,a}
            tt.text:SetTextColor(.5,.5,.5)
            bf.batchBidCheck = tt
        end


    end

    do
        local b = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")
        b:SetPoint("TOPLEFT", bf, 90 + l:GetStringWidth(), -150)

        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
        b.text:SetText("%")
        b:SetScript("OnClick", ensureone)

        usepercent = b
        l.usepercent = b

        do
            local s = CreateFrame("Slider", nil, bf, "OptionsSliderTemplate")
            s:SetOrientation('HORIZONTAL')
            s:SetHeight(14)
            s:SetWidth(160)
            s:SetMinMaxValues(1, 100)
            s:SetValueStep(1)
            s:SetObeyStepOnDrag(true)
            s.Low:SetText("1%")
            s.High:SetText("100%")
    
            local l = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            l:SetPoint("RIGHT", s, "LEFT", -20, 1)
            l:SetText(L["Bid increment"])

            s:SetPoint("TOPLEFT", bf, 40 + l:GetStringWidth(), -200)

            s:SetScript("OnValueChanged", function(self, value)
                value = math.floor(value)
                s.Text:SetText(value .. "%")
            end)

            s:SetValue(10)
            s:Hide()

            b.slide = s
        end                
    end

    ensureone()
    bf.bidmode = l
end

do
    local b = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")
    b:SetPoint("TOPLEFT", bf, 15, -290)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
    b.text:SetText(L["always in raid warning channel"])

    b:SetScript("OnClick", function() 
        Database:SetConfig("bfusera", b:GetChecked())
    end)
    b:SetChecked(Database:GetConfigOrDefault("bfusera", false))

    bf.usera = b
end

do
    local ctx = nil

    local currentitem = function()
        local entry = bf.curEntry
        local item = entry["detail"]["item"] or entry["detail"]["displayname"]
        if bf.sameItemCount > 1 then return item .. " (X" .. bf.sameItemCount .. ")" end 
        if bf.stackCount > 1 then return item .. " (X" .. bf.stackCount .. ")" end
        return item                     
    end
 

    local bidprice = function()
        if not ctx then
            return 0
        end

        local bid = ctx.currentprice

        if ctx.currentwinner then
            if ctx.mode == "GOLD" then
                bid = bid + ctx.inc * 10000
            elseif ctx.mode == "PERCENT" then
                bid = math.floor(bid * (1 + (ctx.inc / 100)) / 10000) * 10000
            end
        end

        return bid
    end

    local SendRaidMessage = function(text, userw)
        if userw and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player')) then
            SendChatMessage(text, "RAID_WARNING")
        else
            SendChatMessage(text, "RAID")
        end
    end

    local evt = function(text, playerName)
        if not ctx then
            return
        end

        local rawask = tonumber(text)
        if not rawask then
            return
        end

        playerName = strsplit("-", playerName)
        local bid = bidprice() / 10000
        local item = currentitem()

        local function smartbid_autofit(bid, rawask)
            local realask = rawask
            while(true)
            do
                if realask < bid then 
                    realask = realask * 10
                elseif realask > bid * 3 then
                    if realask == rawask then break end
                    realask = math.floor(realask / 10) 
                    break
                else
                    break
                end
            end
            return realask
        end 

        local realask
        if ctx.smartbid then
            realask = smartbid_autofit(bid, rawask)
        else
            realask = rawask
        end

        if realask >= bid then
            ctx.currentwinner = playerName
            ctx.currentprice = realask * 10000
            ctx.countdown = bf.countdown:GetValue()
            bf:AddBidWatch(playerName, realask *10000)
            bf:UpdateBidWatchList()
            -- L["Bid price"]
            SendRaidMessage("[" .. L["Bid accept"] .. "] " .. playerName .. " " .. GetMoneyStringL(ctx.currentprice) .. ">>" ..item, bf.usera:GetChecked())
        else
            SendRaidMessage("[" .. L["Bid denied"] .. "] " .. L["Must bid higher than"] .. " " .. GetMoneyStringL(bid * 10000), bf.usera:GetChecked())
        end
        
    end

    RegEvent("CHAT_MSG_RAID_LEADER", evt)
    RegEvent("CHAT_MSG_RAID", evt)

    do
        
        local tooltip = GUI.commtooltip


        local b = CreateFrame("Button", nil, bf, "GameMenuButtonTemplate")
        b:SetWidth(100)
        b:SetHeight(25)
        b:SetPoint("BOTTOMRIGHT", -40, 15)
        b:SetText(START)

        b:SetScript("OnEnter", function()
            tooltip:SetOwner(b, "ANCHOR_RIGHT")
            tooltip:SetText(L["CTRL + Click to start and then pause timer"])
            tooltip:Show()
        end)

        b:SetScript("OnLeave", function()
            tooltip:Hide()
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        end)

        b:SetScript("OnClick", function() 
            local mode, inc, smartbid, batchbid = bf.GetBidMode()
            ctx = {
                entry = bf.curEntry,
                sameItemCount = bf.sameItemCount,
                sameItemEntry = bf.sameItemEntry,
                currentprice = bf.startprice:GetValue() * 10000,
                currentwinner = nil,
                mode = mode,
                smartbid = smartbid,
                batchbid = batchbid,
                inc = inc,
                countdown = bf.countdown:GetValue(),
                bidwatch = {},
            }

            bf:OpenBidWatch()
            ADDONSELF.gui:Hide()

            local item = currentitem()

            SendRaidMessage("[" .. L["Start bid"] .. "] " .. item .." " .. L["Starting price"] .. " >>" .. GetMoneyStringL(ctx.currentprice) .. "<< ",true)
            if ctx.smartbid then SendRaidMessage(L["Smart bid mode on, your bid price will be auto fitted"], bf.usera:GetChecked()) end
            ctx.timer = C_Timer.NewTicker(1, function()
                if ctx.pause then
                    return
                end

                ctx.countdown = ctx.countdown - 1

                bf:UpdateBidCountDown()

                if ctx.countdown <= 0 then
                    ctx.timer:Cancel()

                    if ctx.currentwinner then
                        SendRaidMessage(L["Hammer"] .. ctx.entry.detail.item .. " " .. GetMoneyStringL(ctx.currentprice) .. ">> " .. ctx.currentwinner, bf.usera:GetChecked())
                        ctx.entry["beneficiary"] = ctx.currentwinner
                        ctx.entry["cost"] = ctx.currentprice / 10000
                        ctx.entry["lock"] = true
                        ctx.entry.bidtimes = ctx.entry.bidtimes and ctx.entry.bidtimes + 1 or 1
                        -- deal with batch bid mode
                        if ctx.batchbid then
                            for i=1,#ctx.sameItemEntry do
                                local secondWinner = ctx.bidwatch[#ctx.bidwatch - i]
                                if secondWinner == nil then break end
                                Print_Dump(ctx.sameItemEntry)
                                Print_Dump(ctx.bidwatch)
                                local entry2 = ctx.sameItemEntry[i]
                                SendRaidMessage(L["Hammer"] .. entry2.detail.item .. " " .. GetMoneyStringL(secondWinner.bidPrice) .. ">> " .. secondWinner.playerName, bf.usera:GetChecked())
                                entry2["beneficiary"] = secondWinner.playerName
                                entry2["cost"] = secondWinner.bidPrice / 10000
                                entry2["lock"] = true
                            end 
                        end
                        bf:CloseBidWatch()
                        GUI:UpdateLootTableFromDatabase()
                    else
                        SendRaidMessage(item .. " " .. L["is bought in"],bf.usera:GetChecked())
                        ctx.entry.bidtimes = ctx.entry.bidtimes and ctx.entry.bidtimes + 1 or 1
                        bf:CancelBid()
                        GUI:UpdateLootTableFromDatabase()
                    end

                    ctx = nil

                    return
                end

                local sendalert = ctx.countdown <= 10 and ctx.countdown % 2 == 0
                if sendalert then
                    SendRaidMessage("[" .. L["Bid Countdown"] ..string.format("%d", ctx.countdown/2).."] ".. item .." >> " .. GetMoneyStringL(ctx.currentprice), true)
                end
            end)
            bf:Hide()
        end)

        bf.CancelBid = function()
            if ctx then
                ctx.timer:Cancel()
                bf:CloseBidWatch()
                SendRaidMessage(L["Bid canceled"], bf.usera:GetChecked())
            end
            ctx = nil
        end
    end
    -- init bid watch frame
    do
        local tooltip = GUI.itemtooltip
        local f = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        f:SetWidth(250)
        f:SetHeight(100)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = {left = 8, right = 8, top = 10, bottom = 10}
        })

        f:SetBackdropColor(0, 0, 0)
        f:SetPoint("CENTER", 0, 0)
        f:SetToplevel(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetScript("OnMouseDown", clearAllFocus)
        f:Hide()

        do
            local b = CreateFrame("Button", nil, f, "UIPanelCloseButton")
            b:SetPoint("TOPRIGHT", f , 0, 0);
            b:SetScript("OnClick", function() 
                bf:CancelBid()
            end)
        end

        -- bid watch title and countdown
        
        local h = f:CreateTexture(nil, "ARTWORK")
        h:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
        h:SetWidth(250)
        h:SetHeight(64)
        h:SetPoint("TOP", f, 0, 12)
        f.header = h
        local ht = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ht:SetText(L["Current Bid"])
        ht:SetPoint("TOP", f, 0, 0)
        ht:Show()
        f.header.text = ht
        
        local itemTexture = f:CreateTexture()
        itemTexture:SetTexCoord(0, 1, 0, 1)
        itemTexture:Show()
        itemTexture:SetPoint("TOPLEFT", f, 30, -30)
        itemTexture:SetWidth(20)
        itemTexture:SetHeight(20) 
        itemTexture:SetTexture(134400) -- question mark
        f.itemTexture = itemTexture

        local itemtext = CreateFrame("Button", nil, f)
        itemtext.text = itemtext:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemtext.text:SetPoint("LEFT", itemtext, "LEFT", 45, 0)
        itemtext.text:SetWidth(230)
        itemtext.text:SetJustifyH("LEFT")

        itemtext:SetPoint('LEFT', itemTexture, "RIGHT", -40, 0)
        itemtext:SetSize(20, 20)
        itemtext:EnableMouse(true)
        itemtext:RegisterForClicks("AnyUp")
        itemtext:SetScript("OnClick", function()
            ChatEdit_InsertLink(itemtext.link)
        end)

        local hc = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hc:SetText(string.format("(%d)s", 20))
        hc:SetPoint("TOPRIGHT", itemtext, 40, 0)
        hc:Show()
        f.header.countdown = hc

        itemtext:SetScript("OnEnter", function()
            if itemtext.link then
                tooltip:SetOwner(itemtext, "ANCHOR_CURSOR")
                tooltip:SetHyperlink(itemtext.link)
                tooltip:Show()
            end
        end)

        itemtext:SetScript("OnLeave", function()
            tooltip:Hide()
            tooltip:SetOwner(itemtext, "ANCHOR_NONE")
        end)
        f.itemtext = itemtext

        -- bid watch list

        local bidWatchPlayerUpdate = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, stable, ...)
            local rowdata = stable:GetRow(realrow)
            if not rowdata then
                return nil
            end
            local celldata = stable:GetCell(rowdata, column)
            cellFrame.text:SetText(celldata["playerName"])
        end
        local bidWatchPriceUpdate = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, stable, ...)
            local rowdata = stable:GetRow(realrow)
            if not rowdata then
                return nil
            end

            local celldata = stable:GetCell(rowdata, column)
            cellFrame.text:SetText(GetMoneyStringL(celldata["bidPrice"]))
        end

        local st = ScrollingTable:CreateST({
            {
                ["name"] = "",
                ["width"] = 100,
                ["DoCellUpdate"] = bidWatchPlayerUpdate,
            },
            {
                ["name"] = "",
                ["width"] = 50,
                ["DoCellUpdate"] = bidWatchPriceUpdate,
            }
        }, 6, 30, nil, f)
        st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -60)
        st.scrollframe:SetScript("OnHide",function() end)
        st.scrollframe:Hide()
        st.frame:SetBackdropColor(0.1,0.1,0.1,0.5)
        st:Show()
        f.watchlist = st
        bf.bidwatch = f
        bf.UpdateBidCountDown = function(self)
            bf.bidwatch.header.countdown:SetText(string.format("(%d)s", ctx.countdown))
        end
        bf.UpdateBidWatchList = function(self)
            -- construct scrollingtable's data from ctx
            local data = {}
            for i=1,#ctx.bidwatch do
                 table.insert(data, 1, {
                    ["cols"] = {
                        {["playerName"]=ctx.bidwatch[i]["playerName"]},
                        {["bidPrice"]=ctx.bidwatch[i]["bidPrice"]},
                    }
                })
            end            
            self.bidwatch.watchlist:SetData(data)
            self.bidwatch:SetHeight(self.bidwatch.watchlist.frame:GetHeight()+80)
        end
        bf.AddBidWatch = function(self, playerName, bidPrice)
           local found = false
            for i=1,#ctx.bidwatch do
                if ctx.bidwatch[i]["playerName"] == playerName then
                    ctx.bidwatch[i]["bidPrice"] = bidPrice
                    found = true
                end
            end
            if not found then 
                table.insert(ctx.bidwatch, {["playerName"]=playerName, ["bidPrice"]=bidPrice})
            end
            local function priceSort(a, b)
                return a["bidPrice"] < b["bidPrice"]
            end
            table.sort(ctx.bidwatch, priceSort)
        end
        bf.OpenBidWatch = function(self)
            local item = currentitem()
            self.bidwatch.itemTexture:SetTexture(GetItemIcon(item))
            local _, itemLink = GetItemInfo(item)
            if itemLink then
                self.bidwatch.itemtext.link = itemLink
                self.bidwatch.itemtext.text:SetText(item)
                self.bidwatch.itemtext:SetWidth(math.min(230, itemtext.text:GetStringWidth() + 45))
            else
                self.bidwatch.itemtext.link = nil
                self.bidwatch.itemtext.text:SetText(item)
            end
            self.bidwatch:Show()
            -- test data
            -- self:AddBidWatch("包你满意呀",6000000)
            -- self:AddBidWatch("陆战之王",7000000)
            -- self:AddBidWatch("自然骚",5000000)
            self:UpdateBidWatchList()
        end
        bf.CloseBidWatch = function(self)
            self:UpdateBidWatchList()
            self.bidwatch:Hide()
        end
    end
end

bf:Hide()
bf:SetScript("OnHide", function() 
end)

GUI.bidframe = bf
end