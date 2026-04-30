local uiRebuilt = false

local function iterConfigFrames(fn)
    local i = 1
    while true do
        local frame = getglobal("pfQuestConfig" .. i)
        if not frame then break end
        fn(frame)
        i = i + 1
    end
end

function OnCheckboxClick(self, key)
    print(key .. " is now " .. tostring(self:GetChecked()))
    pfQuest_config[key] = self:GetChecked()
end

function OnEditBoxEnterPressed(self, key)
    print(key .. " value is " .. self:GetText())
    pfQuest_config[key] = self:GetText()
end

function AddLabel(parent, item, anchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    label:SetPoint("LEFT", anchor, "RIGHT", 3, 0)
    label:SetText(item.text)
end

function AddOptionsPanel(name, parent)	
	local optionsPanel = CreateFrame("Frame", nil, UIParent)
	optionsPanel.name = name
    optionsPanel.parent = parent
	
	InterfaceOptions_AddCategory(optionsPanel)
	
	return optionsPanel
end

function AddCheckboxToPanel(parent, item, anchor)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")

    checkbox:SetScript("OnClick", function(self)
        OnCheckboxClick(self, item.config)
    end)

    if anchor == nil then
	    checkbox:SetPoint("TOPLEFT", 10, -10)
    else
        checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    end

    checkbox:SetChecked(pfQuest_config[item.config])

    AddLabel(parent, item, checkbox)

    return checkbox
end

function AddEditBoxToPanel(parent, item, anchor)
    local editbox = CreateFrame("EditBox", nil, parent)

    editbox:SetScript("OnEnterPressed", function(self)
        OnEditBoxEnterPressed(self, item.config)
    end)

    if anchor == nil then
        editbox:SetPoint("TOPLEFT", 10, -10)
    else
        editbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    end

    editbox:SetWidth(40)
    editbox:SetHeight(20)
    editbox:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })

    editbox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    editbox:SetFont("Fonts/FRIZQT__.TTF", 12)
    editbox:SetTextColor(1, 1, 1, 1)
    editbox:SetAutoFocus(false)
    editbox:SetJustifyH("CENTER")
    editbox:SetText(pfQuest_config[item.config])
    editbox:ClearFocus()
    editbox:SetCursorPosition(0)

    AddLabel(parent, item, editbox)

    return editbox
end

function AddSliderToPanel(parent, item, anchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    if anchor == nil then
        label:SetPoint("TOPLEFT", 20, -15)
    else
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -15)
    end
    label:SetText(item.text)

    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -10)
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetValueStep(0.1)
    slider:SetMinMaxValues(item.min * 100, item.max * 100)
    slider:SetValue(item.default * 100)

    slider:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slider:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local thumb = slider:CreateTexture()
    thumb:SetWidth(16)
    thumb:SetHeight(16)
    thumb:SetColorTexture(0.8, 0.8, 0.8, 1)
    thumb:SetTexCoord(0, 1, 0, 1)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture(thumb)

    local valueLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    valueLabel:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueLabel:SetText(tostring(math.floor(pfQuest_config[item.config])))

    slider:SetScript("OnValueChanged", function(self, value)
        valueLabel:SetText(string.format("%.1f", value / 100))
        pfQuest_config[item.config] = tostring(value / 100)

        if pfQuest and pfQuest.route and pfQuest.route.arrow then
            pfQuest.route.arrow:ApplyScale()
        end
    end)

    return slider
end

local function RebuildConfigUI()
    if uiRebuilt then
        return
    end

     if not pfQuestConfig or not pfQuestConfig.CreateConfigEntries then
        return false
     end

    local i = 1
    while true do
        local name = "pfQuestConfig" .. i
        local frame = getglobal(name)
        if not frame then break end
        frame:Hide()
        frame:SetParent(nil)
        setglobal(name, nil)
        i = i + 1
    end

    pfQuestConfig.vpos = 40
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    local pfQuestConfigPanel = AddOptionsPanel("pfQuest", nil)
    local currentPanel = pfQuestConfigPanel

    local optionAnchor = nil

    for _, item in ipairs(pfQuest_defconfig) do
        if item.type == "header" then
            currentPanel = AddOptionsPanel(item.text, pfQuestConfigPanel.name)
            optionAnchor = nil
        elseif item.type == "checkbox" then
            optionAnchor = AddCheckboxToPanel(currentPanel, item, optionAnchor)
        elseif item.type == "text" then
            optionAnchor = AddEditBoxToPanel(currentPanel, item, optionAnchor)
        elseif item.type == "slider" then
            optionAnchor = AddSliderToPanel(currentPanel, item, optionAnchor)
        end
    end
    
    uiRebuilt = true
    return true
end

local function CreateSearchBar()
    if pfQuestConfig.searchBar then
        return
    end

    -- Create backdrop frame
    pfQuestConfig.searchBackdrop = CreateFrame("Frame", nil, pfQuestConfig)
    pfQuestConfig.searchBackdrop:SetHeight(24)
    pfQuestConfig.searchBackdrop:SetWidth(180)
    pfQuestConfig.searchBackdrop:SetPoint("BOTTOM", pfQuestConfig, "BOTTOM", 0, 10)

    -- Dark backdrop styling
    pfQuestConfig.searchBackdrop:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    pfQuestConfig.searchBackdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    pfQuestConfig.searchBackdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Create edit box
    pfQuestConfig.searchBar = CreateFrame("EditBox", "pfQuestConfigSearch", pfQuestConfig.searchBackdrop)
    pfQuestConfig.searchBar:SetAllPoints(pfQuestConfig.searchBackdrop)
    pfQuestConfig.searchBar:SetAutoFocus(false)
    pfQuestConfig.searchBar:SetTextInsets(8, 8, 0, 0)
    pfQuestConfig.searchBar:SetFontObject(GameFontNormalSmall)

    -- Placeholder text
    pfQuestConfig.searchBar.placeholder = pfQuestConfig.searchBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pfQuestConfig.searchBar.placeholder:SetPoint("LEFT", pfQuestConfig.searchBar, "LEFT", 8, 0)
    pfQuestConfig.searchBar.placeholder:SetText("Search...")
    pfQuestConfig.searchBar.placeholder:SetJustifyH("LEFT")
    pfQuestConfig.searchBar.placeholder:Show()

    pfQuestConfig.searchBar:SetScript("OnEditFocusGained", function(self)
        self.placeholder:Hide()
    end)

    pfQuestConfig.searchBar:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self.placeholder:Show()
        end
    end)

    pfQuestConfig.searchBar:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        self.placeholder:Show()
        iterConfigFrames(function(frame) frame:Show() end)
    end)

    -- Click outside to clear search (hook into existing OnMouseDown)
    local originalOnMouseDown = pfQuestConfig:GetScript("OnMouseDown")
    pfQuestConfig:SetScript("OnMouseDown", function(self, button)
        -- Call original handler for window dragging
        if originalOnMouseDown then
            originalOnMouseDown(self, button)
        end

        -- Clear search on click outside
        if button == "LeftButton" or button == "RightButton" then
            if not pfQuestConfig.searchBar:IsMouseOver() then
                if pfQuestConfig.searchBar:GetText() ~= "" then
                    pfQuestConfig.searchBar:SetText("")
                    pfQuestConfig.searchBar:ClearFocus()
                    pfQuestConfig.searchBar.placeholder:Show()
                    iterConfigFrames(function(frame) frame:Show() end)
                end
            end
        end
    end)

    pfQuestConfig.searchBar:SetScript("OnTextChanged", function(self)
        local searchText = string.lower(self:GetText())

        iterConfigFrames(function(frame)
            if frame.caption then
                local captionText = string.lower(frame.caption:GetText() or "")
                if searchText == "" or string.find(captionText, searchText, 1, true) then
                    frame:Show()
                else
                    frame:Hide()
                end
            end
        end)
    end)
end

local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("VARIABLES_LOADED")
configFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        local timer = 0
        self:SetScript("OnUpdate", function()
            timer = timer + 1

            if timer > 10 then
                if pfQuestConfig then
                    RebuildConfigUI()

                    -- Rebuild UI on first show to include epoch entries
                    local originalOnShow = pfQuestConfig:GetScript("OnShow")
                    pfQuestConfig:SetScript("OnShow", function()
                        if originalOnShow then
                            originalOnShow()
                        end
                        RebuildConfigUI()
                        CreateSearchBar()
                    end)

                    self:SetScript("OnUpdate", nil)
                    self:UnregisterAllEvents()
                elseif timer > 300 then
                    self:SetScript("OnUpdate", nil)
                    self:UnregisterAllEvents()
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest |cffcccccc[Epoch]|r: Search bar creation failed")
                end
            end
        end)
    end
end)
