local addonName, addon = ...
local module = addon:CreateModule("Unit Frames")

module.defaultSettings = {
	x = 350,
	y = 100,
	scale = 1,
	frameSpacing = 20,
	statusTextScale = 1,
	classColors = true,
	hideNames = false,
	hideBlizzardFrames = true,
}

module.optionsTable = {
	scale = {
		order = 1,
		type = "range",
		name = "Scale",
		min = 0.1,
		max = 5.0,
		step = 0.1,
		set = module.UpdateSettings,
	},
	frameSpacing = {
		order = 2,
		type = "range",
		name = "Spacing",
		min = -100,
		max = 100,
		softMin = -100,
		softMax = 100,
		step = 1,
		set = module.UpdateSettings,
	},
	hideNames = {
		order = 5,
		type = "toggle",
		name = "Hide names",
		set = module.UpdateSettings,
	},
	classColors = {
		order = 6,
		type = "toggle",
		name = "Class-colored health bars",
		width = "full",
	},
	hideBlizzardFrames = {
		order = 7,
		type = "toggle",
		name = "Hide Blizzard arena frames",
		hidden = function() return not CompactArenaFrame end,
		width = "full",
		set = module.UpdateSettings,
	},
}

local hiddenFrame = CreateFrame("Frame", nil, UIParent)
hiddenFrame:Hide()

local sArenaEnemyFrames = ArenaEnemyFrame1:GetParent()
sArenaEnemyFrames:Hide()
sArenaEnemyFrames:SetMovable(true)

local function ShowEnemyFrames()
	if not InCombatLockdown() then
		sArenaEnemyFrames:Show()
	end
end

hooksecurefunc("ArenaEnemyFrames_UpdateVisible", ShowEnemyFrames)

local function HideBlizzardFrames()
	local frame = CompactArenaFrame
	if not frame then
		return
	end

	if module.db.hideBlizzardFrames and not EditModeManagerFrame:IsEditModeActive() then
		if not frame:IsShown() then
			return
		end

		if InCombatLockdown() then
			frame:SetAlpha(0)
		else
			frame:SetAlpha(1)
			frame:Hide()
		end
	else
		frame:SetAlpha(1)
	end
end

local combatEndFrame = CreateFrame("Frame")
combatEndFrame:SetScript("OnEvent", function()
	ShowEnemyFrames()
	HideBlizzardFrames()
end)

function module:OnEvent(event, ...)
	if event == "UNIT_AURA" then
		return;
	end

	if event == "ADDON_LOADED" then
		for i = 1, MAX_ARENA_ENEMIES do
			local arenaFrame = _G["ArenaEnemyFrame"..i]

			addon:SetupDrag(module, false, arenaFrame, sArenaEnemyFrames)
			addon:SetupDrag(module, false, arenaFrame.healthbar, sArenaEnemyFrames)
			addon:SetupDrag(module, false, arenaFrame.manabar, sArenaEnemyFrames)
		end

		--ArenaEnemyBackground:SetParent(hiddenFrame)

		if CompactArenaFrame and CompactArenaFrame.UpdateVisibility then
			hooksecurefunc(CompactArenaFrame, "UpdateVisibility", HideBlizzardFrames)
		end
		combatEndFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

		self:OnEvent("UPDATE_SETTINGS")
	elseif event == "PLAYER_ENTERING_WORLD" then
		ShowEnemyFrames()
	elseif event == "TEST_MODE" then
		if addon.testMode then
			ShowEnemyFrames()
		end

		for i = 1, MAX_ARENA_ENEMIES do
			local arenaFrame = _G["ArenaEnemyFrame"..i]

			if addon.testMode then
				arenaFrame.healthbar:SetMinMaxValues(0,100)
				arenaFrame.healthbar:SetValue(100)
				arenaFrame.healthbar.forceHideText = false
				arenaFrame.manabar:SetMinMaxValues(0,100)
				arenaFrame.manabar:SetValue(100)
				arenaFrame.manabar:SetStatusBarColor(0, 0, 1)
				arenaFrame.manabar.forceHideText = false
				
				ArenaEnemyFrame_SetMysteryPlayer(arenaFrame)

				arenaFrame.name:SetText("arena"..i)
				arenaFrame:Show()
			else
				arenaFrame:Hide()
			end
		end
	elseif event == "UPDATE_SETTINGS" then
		sArenaEnemyFrames:ClearAllPoints()
		sArenaEnemyFrames:SetPoint("CENTER", self.db.x, self.db.y)
		sArenaEnemyFrames:SetScale(self.db.scale)

		for i = 1, MAX_ARENA_ENEMIES do
			local arenaFrame = _G["ArenaEnemyFrame"..i]
			arenaFrame.name:SetShown(not self.db.hideNames)

			if i > 1 then
				arenaFrame:SetPoint("TOP", _G["ArenaEnemyFrame"..i-1], "BOTTOM", 0, self.db.frameSpacing * -1)
			end
		end

		HideBlizzardFrames()
	end
end

-- Class colored health bars
local healthBars = {
	ArenaEnemyFrame1HealthBar = 1,
	ArenaEnemyFrame2HealthBar = 1,
	ArenaEnemyFrame3HealthBar = 1,
	ArenaEnemyFrame4HealthBar = 1,
	ArenaEnemyFrame5HealthBar = 1
}

local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local function colorStatusBar(statusbar)
	if module.db.classColors and healthBars[statusbar:GetName()] then
		local _, class = UnitClass(statusbar.unit)
		if class then
			local c = RAID_CLASS_COLORS[class]
			if not statusbar.lockColor then statusbar:SetStatusBarColor(c.r, c.g, c.b) end
		end
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colorStatusBar)
hooksecurefunc("HealthBar_OnValueChanged", colorStatusBar)