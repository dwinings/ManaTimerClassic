local Name,AddOn=...;
AddOn.API=AddOn.API or {};
local Title = select(2, GetAddOnInfo(Name));
local Version = GetAddOnMetadata(Name, "Version");
local Author = GetAddOnMetadata(Name, "Author");

function OnOptionToggleClicked(self)
    ManaTimerClassic_Options[self.Key] = self:GetChecked()
    ManaTimerClassic_OnOptionsChanged()
end

function ManaTimerClassic_InitializeOptions()
    local Panel = CreateFrame("Frame")
    Panel.name = Title

    InterfaceOptions_AddCategory(Panel);
    local title = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOP", 0, -12);
    title:SetText("Mana Timer Classic (v" ..Version.. ")");

    local button = CreateFrame("CheckButton", nil, Panel, "UICheckButtonTemplate");
    button:SetPoint("TOPLEFT", 32, -48)
    button.Key = "SeparateSpellPause"
    button:SetChecked(ManaTimerClassic_Options[button.Key])
    button.text:SetText("Show Separate 5-second-rule bar")
    button:SetScript("OnClick", OnOptionToggleClicked);

    local button2 = CreateFrame("CheckButton", nil, Panel, "UICheckButtonTemplate");
    button2:SetPoint("TOPLEFT", 32, -72)
    button2.Key = "ShowRegenAmount"
    button2:SetChecked(ManaTimerClassic_Options[button2.Key])
    button2.text:SetText("Show amount of mana regenerated per tick.")
    button2:SetScript("OnClick", OnOptionToggleClicked);

    local button3 = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    button3:SetSize(130, 22);
    button3:SetPoint("TOPLEFT", 34, -100);
    button3:SetText("Reset Position")
    button3:SetScript("OnClick", function(self)
        ManaTimerClassic_Container:ClearAllPoints()
        ManaTimerClassic_Container:SetPoint("CENTER", UIParent, 0, 0)
    end);
end