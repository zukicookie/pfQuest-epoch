local XConfigObjectOffset = 10
local YConfigObjectOffset = -10

local modifiedConfig = {}
function GetModifiedConfig()
    return modifiedConfig
end

for key, value in pairs(pfQuest_config) do
    modifiedConfig[key] = value
end
    
function OnCheckboxClick(self, key)
    modifiedConfig[key] = self:GetChecked() and "1" or "0"
end

function OnEditBoxEnterPressed(self, key)
    modifiedConfig[key] = self:GetText()
end

function AddLabel(parent, text, anchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    label:SetPoint("LEFT", anchor, "RIGHT", 3, 0)
    label:SetText(text)
    return label
end

function SetConfigObjectLocation(object, anchor)
    if anchor == nil then
	    object:SetPoint("TOPLEFT", XConfigObjectOffset, YConfigObjectOffset)
    else
        object:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, YConfigObjectOffset)
    end
end

function AddOptionsPanel(name, parent)	
	local optionsPanel = CreateFrame("Frame", nil, UIParent)

	optionsPanel.name = string.gsub(name, "^|c%x%x%x%x%x%x%x%x(.-)|r$", "%1")
    optionsPanel.parent = parent
	
    optionsPanel.okay = function(self)
        for key, value in pairs(modifiedConfig) do
            if value ~= pfQuest_config[key] then
                pfQuest_config[key] = value
                ReloadUI()
            end
        end
    end

	InterfaceOptions_AddCategory(optionsPanel)
	
	return optionsPanel
end

function AddCheckboxToPanel(parent, item, value, anchor)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetChecked(value)

    checkbox:SetScript("OnClick", function(self)
        OnCheckboxClick(self, item.config)
    end)

    SetConfigObjectLocation(checkbox, anchor)

    AddLabel(parent, item.text, checkbox)

    return checkbox
end

function AddEditBoxToPanel(parent, item, anchor)
    local editbox = CreateFrame("EditBox", nil, parent)

    editbox:SetScript("OnEnterPressed", function(self)
        OnEditBoxEnterPressed(self, item.config)
    end)

    SetConfigObjectLocation(editbox, anchor)

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
    editbox:SetText(modifiedConfig[item.config] or item.default or "")
    editbox:ClearFocus()
    editbox:SetCursorPosition(0)

    AddLabel(parent, item.text, editbox)

    return editbox
end

function AddSliderToPanel(parent, item, anchor)
    local label = AddLabel(parent, item.text, anchor)
    SetConfigObjectLocation(label, anchor)

    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("LEFT", label, "RIGHT", XConfigObjectOffset, 0)
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetValueStep(0.1)
    slider:SetMinMaxValues(item.min * 100, item.max * 100)
    slider:SetValue((modifiedConfig[item.config] or item.default) * 100)

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

    local value = tostring(math.floor(modifiedConfig[item.config]))
    slider.label = AddLabel(parent, value, slider)

    slider:SetScript("OnValueChanged", function(self, value)
        OnSliderValueChanged(self, value, item.config, item.func)
    end)

    return slider
end

function OnSliderValueChanged(self, value, key, func)
    value = value / 100
    self.label:SetText(string.format("%.1f", value))
    
    pfQuest_config[key] = tostring(value)

    if func ~= nil then
        func()
    end
end

function AddButtonToPanel(parent, item, anchor)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("LEFT", anchor, "RIGHT", XConfigObjectOffset, 0)
    button:SetWidth(200)
    button:SetHeight(25)
    button:SetText(item.text)

    SetConfigObjectLocation(button, anchor)

    if item.func then
        button:SetScript("OnClick", item.func)
    end

    return button
end

local function RebuildConfigUI()
    if not pfQuestConfig or not pfQuestConfig.CreateConfigEntries then
        return false
    end

    for i = 1, 50 do
        local frame = getglobal("pfQuestConfig" .. i)
        if frame then
            frame:Hide()
            frame:SetParent(nil)
        else
            break
        end
    end

    pfQuestConfig.vpos = 40
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    pfQuestConfig:SetScale(math.min(1.0, 0.6 / UIParent:GetEffectiveScale()))

    local pfQuestConfigPanel = AddOptionsPanel("pfQuest", nil)

    modifiedConfig = {}
    for _, item in ipairs(pfQuest_defconfig) do
        if item.config then
            modifiedConfig[item.config] = pfQuest_config[item.config]
        end
    end
    
    local currentPanel = pfQuestConfigPanel
    local lastAddedItem = nil   -- used as an anchor for the next item that is added

    for _, item in ipairs(pfQuest_defconfig) do
        if item.type == "header" then
            currentPanel = AddOptionsPanel(item.text, pfQuestConfigPanel.name)
            lastAddedItem = nil
        elseif item.type == "checkbox" then
            lastAddedItem = AddCheckboxToPanel(currentPanel, item, modifiedConfig[item.config], lastAddedItem)
        elseif item.type_ex == "slider" then
            lastAddedItem = AddSliderToPanel(currentPanel, item, lastAddedItem)
        elseif item.type == "text" then
            lastAddedItem = AddEditBoxToPanel(currentPanel, item, lastAddedItem)
        elseif item.type == "button" then
            lastAddedItem = AddButtonToPanel(currentPanel, item, lastAddedItem)
        end
    end

    return true
end

local function OnConfigUIRebuilt()
    ResizeArrow()
end

local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("VARIABLES_LOADED")
configFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        local timer = 0
        self:SetScript("OnUpdate", function()
            timer = timer + 1

            if timer > 10 then
                if RebuildConfigUI() then
                    self:SetScript("OnUpdate", nil)
                    self:UnregisterAllEvents()
                    OnConfigUIRebuilt()
                elseif timer > 300 then
                    self:SetScript("OnUpdate", nil)
                    self:UnregisterAllEvents()
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest |cffcccccc[Epoch]|r: Config UI rebuild failed")
                end
            end
        end)
    end
end)
