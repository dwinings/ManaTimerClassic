local frame, events = CreateFrame("Frame"), {}
local config = {}
local bar_max = 0
local last_passed = 0
local time_passed = 0
local old_mana = 0
local time_till_next_mana = 0
local spell_pause_timer = 0
local count = 0
local full_mana = false
local bar_full = true
local power_type = 'MANA'
local regen = 0
local main_bar = nil
local pause_bar = nil

function ManaTimerClassic_OnLoad(self)
	ManaTimerClassic_UpdateFrame:RegisterEvent("UNIT_POWER_UPDATE")
	ManaTimerClassic_UpdateFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	ManaTimerClassic_UpdateFrame:RegisterEvent("ADDON_LOADED")
end

function ManaTimerClassic_OnUpdate(self, elapsed)
	local max_mana = UnitPowerMax("player")
	local mana = UnitPower("player")

-- todo: track mana ticks during full_mana times.
	time_passed = time_passed + elapsed

	if spell_pause_timer > 0 then
		spell_pause_timer = math.max(0, spell_pause_timer - elapsed)
	end

	-- We keep track of the spell ticks regardless of whether we're running the
	-- spell pause timer.
	if elapsed > time_till_next_mana then
		time_till_next_mana = 2 - (elapsed - time_till_next_mana)

		-- We want to leave the bar full until the next tick causes it to be set to 0
		-- BUT: We still need to track time_till_next_mana to keep our predictions accurate
		-- through the spell pause stuff.
		if spell_pause_timer == 0 then
			bar_full = true
		end
	else
		time_till_next_mana = time_till_next_mana - elapsed
	end

	if time_passed >= last_passed + 0.1 and TimeTillNextRegen() > 0 then
		last_passed = time_passed
		-- print('Time till next mana regen: ' ..(TimeTillNextRegen()))
	end

	if not bar_full and not (mana == max_mana) then
		ManaTimerClassic_MainBar:SetValue(1 - (TimeTillNextRegen()/bar_max))
		pause_bar:SetValue(1 - (spell_pause_timer / 5))
	else 
		ManaTimerClassic_MainBar:SetValue(1)
		pause_bar:SetValue(1)
	end
end

function ManaTimerClassic_DidLoad()
	main_bar = ManaTimerClassic_Container.MainBar
	pause_bar = ManaTimerClassic_Container.PauseBar
	main_bar:SetMinMaxValues(0, 1)
	main_bar:SetValue(1)
	pause_bar:SetMinMaxValues(0, 1)
	pause_bar:SetValue(1)

	if ManaTimerClassic_Options == nil then
		ManaTimerClassic_Options = {}
    end

	ManaTimerClassic_UpdateRegen()
	ManaTimerClassic_InitializeOptions()
	ShowBarIfApplicable()
end

function ManaTimerClassic_OnEvent(self, event, ...)
	if event == "UNIT_POWER_UPDATE" then
		local unit_id, _ = ...

		if unit_id == "player" then
            ShowBarIfApplicable()

			local new_mana = UnitPower("player")
			local max_mana = UnitPowerMax("player")

			-- This if statement is because our regen is shown as 0 if we are in combat.BCB
			local player_class, _, _= UnitClass("player")

			ManaTimerClassic_UpdateRegen()

			if new_mana < old_mana then
				spell_pause_timer = 5
				ResetBar()
			end
			if new_mana > old_mana and (new_mana - old_mana) - regen < 5 then
				time_till_next_mana = 2
				-- print("Hey, this looks like a regen tick.")
				ResetBar()
			end
			old_mana = new_mana
		end
	elseif event == "ADDON_LOADED" then
        local name, _ = ...
    	if name == "ManaTimerClassic" then
			ManaTimerClassic_DidLoad()
		end
	elseif event == "UNIT_DISPLAYPOWER" then
		_, power_type = UnitPowerType("player")
		ShowBarIfApplicable()
		ResetBar()
	end
end

function ResetBar(time)
	bar_full = false
	bar_max = math.max(TimeTillNextRegen(), 2)
end

function ManaTimerClassic_OnOptionsChanged()
	ShowBarIfApplicable()
	ManaTimerClassic_UpdateRegen(regen)
end

function ShowBarIfApplicable()
	power_type = select(2, UnitPowerType("player"))
	if power_type == 'MANA' then
		ManaTimerClassic_MainBar:SetStatusBarColor(0, 0, 1, 1)
	elseif power_type == 'ENERGY' then
		ManaTimerClassic_MainBar:SetStatusBarColor(1, 1, 0.33, 1)
	else
		ManaTimerClassic_Container:Hide()
		return
	end

	ManaTimerClassic_Container:Show()

	if ManaTimerClassic_Options["SeparateSpellPause"] == true and power_type == 'MANA' then
		pause_bar:Show()
    else
        pause_bar:Hide()
	end
end

function TimeTillNextRegen()
	-- Fun fact, the spell pause timer doesn't freeze your mana ticks.
	-- It actually just causes you to skip updates for 2 secs. This means that
	-- if you use a spell after a mana tick (t = 0.01), then your next mana tick will
	-- be at t = 6. However, if you use a spell a second after a mana tick (t = 1.01), then
	-- your spell pause timer will wear off at t = 6.01 and you will miss the t=6 regen tick, for
	-- the same number of spells! This means that you'll have to wait until t=8 to have another
	-- mana tick. That behavior is what this loop is tracking.

	if ManaTimerClassic_Options["SeparateSpellPause"] == true then
		return time_till_next_mana
	end

	local speculative_time = time_till_next_mana
	if power_type == 'MANA' then
		while speculative_time < spell_pause_timer do
			speculative_time = speculative_time + 2
		end
	end

	return speculative_time
end

function ManaTimerClassic_UpdateRegen()
	local new_regen, _ = GetPowerRegen("player")
	if (math.floor(new_regen) ~= 0) then
		regen = new_regen * 2
	end

	if ManaTimerClassic_Options["ShowRegenAmount"] == true then
		main_bar.Text:SetText(" +" ..math.floor(regen))
	else
		main_bar.Text:SetText("")
	end
end