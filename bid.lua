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
bf:SetHeight(350)
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

    local counttext = bf:CreateFontString(nil, 'OVERLAY')
    counttext:SetFontObject('NumberFontNormal')
    counttext:SetPoint('BOTTOMRIGHT', itemTexture, -3, 3)
    counttext:SetJustifyH('RIGHT')

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

    bf.SetItem = function(item, count)

        counttext:SetText("1")

        if tonumber(count) then
            counttext:SetText(count)
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

    s:SetValue(20)

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
            return "GOLD", usegold.slide:GetValue(), usegold.check:GetChecked()
        end

        if usepercent:GetChecked() then
            return "PERCENT", usepercent.slide:GetValue()
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

        -- support easy bid mode: using 100 as unit
        do
            local tt = CreateFrame("CheckButton", nil, bf, "UICheckButtonTemplate")            
            tt.text = tt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tt.text:SetPoint("RIGHT", tt, "Left", -10, 1)
            tt.text:SetText(L["EasyBidMode(100 as unit)"])
            tt:SetPoint("TOPLEFT", bf, 30 + tt.text:GetStringWidth(), -230)
            tt:SetScript("OnClick", function()
                if tt:GetChecked() then
                    bf.bidmode.usegold.slide:SetValue(math.floor(bf.bidmode.usegold.slide:GetValue() / 100) * 100)
                end
            end)
            -- tt:SetChecked(true)
            b.check = tt
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
    b:SetPoint("TOPLEFT", bf, 15, -260)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
    b.text:SetText("/RA")

    b:SetScript("OnClick", function() 
        Database:SetConfig("bfusera", b:GetChecked())
    end)
    b:SetChecked(Database:GetConfigOrDefault("bfusera", true))            

    bf.usera = b
end

do
    local ctx = nil

    local currentitem = function()
        local entry = bf.curEntry
        local item = entry["detail"]["item"] or entry["detail"]["displayname"]                
        item = item .. " (" .. (entry["detail"]["count"] or 1) .. ")"
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

    local SendRaidMessage = function(text)
        if bf.usera:GetChecked() and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player')) then
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

        local realask
        if ctx.easybid then
            realask = rawask * 100
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
            SendRaidMessage(L["Bid accept"] .. " " .. item .. " " .. L["Current price"] .. " >>" .. GetMoneyStringL(ctx.currentprice) .. "<< ".. (ctx.pause and "" or L["Time left"] .. " " .. (SECOND_ONELETTER_ABBR:format(ctx.countdown))))
        else
            SendRaidMessage(L["Bid denied"] .. " " .. item .. " " .. L["Must bid higher than"] .. " " .. GetMoneyStringL(bid * 10000))
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
            local mode, inc, easybid = bf.GetBidMode()
            ctx = {
                entry = bf.curEntry,
                currentprice = bf.startprice:GetValue() * 10000,
                currentwinner = nil,
                mode = mode,
                easybid = easybid,
                inc = inc,
                countdown = bf.countdown:GetValue(),
                bidwatch = {},
            }

            bf:OpenBidWatch()

            local item = currentitem()

            SendRaidMessage(L["Start bid"] .. " " .. item .. " " .. L["Starting price"] .. " >>" .. GetMoneyStringL(ctx.currentprice) .. "<< " .. (ctx.pause and "" or L["Time left"] .. " " .. (SECOND_ONELETTER_ABBR:format(ctx.countdown))))
            if ctx.easybid then SendRaidMessage(L["Easy bid mode on, you can use 100 as bid unit"]) end
            ctx.timer = C_Timer.NewTicker(1, function()
                if ctx.pause then
                    return
                end

                ctx.countdown = ctx.countdown - 1

                -- bf.UpdateButtonCountdown()

                if ctx.countdown <= 0 then
                    ctx.timer:Cancel()

                    if ctx.currentwinner then
                        SendRaidMessage(item .. " " .. L["Hammer Price"] .. " >>" .. GetMoneyStringL(ctx.currentprice) .. "<< " .. L["Winner"] .. " " .. ctx.currentwinner)
                        ctx.entry["beneficiary"] = ctx.currentwinner
                        ctx.entry["cost"] = ctx.currentprice / 10000
                        ctx.entry["lock"] = true
                        bf:CloseBidWatch()
                        GUI:UpdateLootTableFromDatabase()
                    else
                        SendRaidMessage(item .. " " .. L["is bought in"])
                    end

                    ctx = nil

                    return
                end

                local sendalert = ctx.countdown <= 5
                -- sendalert = sendalert or (ctx.countdown <= 15 and (ctx.countdown % 5 == 0))
                -- sendalert = sendalert or (ctx.countdown <= 30 and (ctx.countdown % 10 == 0))
                -- sendalert = sendalert or (ctx.countdown % 30 == 0)

                if sendalert then
                    SendRaidMessage(" " .. L["Current price"] .. " >>" .. GetMoneyStringL(ctx.currentprice) .. "<< " .. L["Time left"] .. " " .. (SECOND_ONELETTER_ABBR:format(ctx.countdown)))
                end
            end)
            bf:Hide()
        end)

        bf.CancelBid = function()
            if ctx then
                ctx.timer:Cancel()
                bf:CloseBidWatch()
                SendRaidMessage(L["Bid canceled"], "RAID")
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

        -- title
        
        local h = f:CreateTexture(nil, "ARTWORK")
        h:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
        h:SetWidth(500)
        h:SetHeight(64)
        h:SetPoint("TOP", f, 0, 12)
        f.header = h
        
        local itemTexture = f:CreateTexture()
        itemTexture:SetTexCoord(0, 1, 0, 1)
        itemTexture:Show()
        itemTexture:SetPoint("TOPLEFT", f.header, 150, -10)
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
        -- local _, itemLink = GetItemInfo(item)
        -- if itemLink then
        --     itemtext.link = itemLink
        --     itemtext.text:SetText(itemLink)
        --     itemtext:SetWidth(math.min(230, itemtext.text:GetStringWidth() + 45))
        -- else
        --     itemtext.link = nil
        --     itemtext.text:SetText(item)
        -- end
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
        st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -50)
        st:Show()
        f.watchlist = st
        bf.bidwatch = f
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
                self.bidwatch.itemtext.text:SetText(itemLink)
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