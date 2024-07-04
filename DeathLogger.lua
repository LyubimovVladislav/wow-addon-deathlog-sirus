--------------------------------------------------------------------------------------------------------------
-- Copyright 2024 Lyubimov Vladislav (grifon7676@gmail.com)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the “Software”), to deal in the Software
-- without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
-- BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
-- .toc file doesn't seem to be able to load additional files besides the one that matches the .toc file name.
-- Idk why it doesn't work so i guess i have to dump it all into one file.
-- This is also why there will be no different localization files. (at least for now)
--------------------------------------------------------------------------------------------------------------

local DeathLogWidget = {}
DeathLogWidget.__index = DeathLogWidget

local widgetInstance = nil
local DeathLoggerTooltip = CreateFrame("GameTooltip", "DeathLoggerTooltip", UIParent, "SharedTooltipTemplate")


DeathLoggerDB = DeathLoggerDB or {}

local function SaveFramePositionAndSize(frame)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
	DeathLoggerDB.point = point
	DeathLoggerDB.relativePoint = relativePoint
	DeathLoggerDB.xOfs = xOfs
	DeathLoggerDB.yOfs = yOfs
	DeathLoggerDB.width = frame:GetWidth()
	DeathLoggerDB.height = frame:GetHeight()
end

local function ShowTooltip(self)
	DeathLoggerTooltip:SetOwner(self, "ANCHOR_TOP")
	DeathLoggerTooltip:SetText(self.tooltip, 1, 1, 1, 1, false)
	DeathLoggerTooltip:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
		-- insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	DeathLoggerTooltip:SetBackdropColor(0, 0, 0, 1)
	DeathLoggerTooltip:Show()
end

local function HideTooltip(self)
	DeathLoggerTooltip:Hide()
end

function DeathLogWidget.new()
	local instance = setmetatable({}, DeathLogWidget)
	local windowAlpha = .5
	instance.mainWnd = CreateFrame("Frame", "MyDialogFrame", UIParent)

	if DeathLoggerDB.point then
		instance.mainWnd:SetPoint(DeathLoggerDB.point, UIParent, DeathLoggerDB.relativePoint, DeathLoggerDB.xOfs,
			DeathLoggerDB.yOfs)
	else
		instance.mainWnd:SetPoint("CENTER")
	end
	if DeathLoggerDB.width and DeathLoggerDB.height then
		instance.mainWnd:SetSize(DeathLoggerDB.width, DeathLoggerDB.height)
	else
		instance.mainWnd:SetSize(300, 200)
	end

	instance.mainWnd:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	instance.mainWnd:SetBackdropColor(0, 0, 0, windowAlpha)

	local closeButton = CreateFrame("Button", nil, instance.mainWnd, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", instance.mainWnd, "TOPRIGHT")
	closeButton:HookScript("OnClick", function() DeathLoggerDB.showOnStartup = false end)

	instance.mainWnd.title = instance.mainWnd:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	instance.mainWnd.title:SetPoint("TOPLEFT", instance.mainWnd, "TOPLEFT", 10, -8)
	instance.mainWnd.title:SetPoint("TOPRIGHT", instance.mainWnd, "TOPRIGHT", -closeButton:GetWidth(), -8)
	instance.mainWnd.title:SetJustifyH("LEFT")
	instance.mainWnd.title:SetJustifyV("CENTER")
	instance.mainWnd.title:SetText("DeathLog")

	local separator = instance.mainWnd:CreateTexture(nil, "ARTWORK")
	separator:SetTexture(1, 1, 1, windowAlpha)
	separator:SetSize(100, 1)
	separator:SetPoint("TOPLEFT", instance.mainWnd.title, "BOTTOMLEFT", 0, -8)
	separator:SetPoint("TOPRIGHT", instance.mainWnd.title, "BOTTOMRIGHT", 1, -8)

	instance.mainWnd:SetMovable(true)
	instance.mainWnd:EnableMouse(true)
	instance.mainWnd:RegisterForDrag("LeftButton")
	instance.mainWnd:SetScript("OnDragStart", instance.mainWnd.StartMoving)
	instance.mainWnd:SetScript("OnDragStop", instance.mainWnd.StopMovingOrSizing)
	instance.mainWnd:SetResizable(true)
	instance.mainWnd:SetMinResize(75, 75)

	instance.scrollFrame = CreateFrame("ScrollFrame", nil, instance.mainWnd, "UIPanelScrollFrameTemplate")
	instance.scrollFrame:SetPoint("TOPLEFT", instance.mainWnd, "TOPLEFT", 10, -30)
	instance.scrollFrame:SetPoint("BOTTOMRIGHT", instance.mainWnd, "BOTTOMRIGHT", -30, 15)

	instance.scrollChild = CreateFrame("Frame", nil, instance.scrollFrame)
	-- It seems it controls minimal size when it can activate scroll(even if all of the content fits). X is irrelevant since no slider on that side
	instance.scrollChild:SetSize(instance.scrollFrame:GetWidth(), 1)
	instance.scrollFrame:SetScrollChild(instance.scrollChild)

	instance.scrollFrame:SetScript("OnSizeChanged", function()
		instance.scrollChild:SetWidth(instance.scrollFrame:GetWidth())
	end)

	local resizeButton = CreateFrame("Button", nil, instance.mainWnd)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT", -2, 3)
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			instance.mainWnd:StartSizing("BOTTOMRIGHT")
		end
	end)
	resizeButton:SetScript("OnMouseUp", function(self, button)
		instance.mainWnd:StopMovingOrSizing()
		SaveFramePositionAndSize(instance.mainWnd)
	end)

	instance.textFrames = {}
	instance.previousEntry = nil

	return instance
end

function DeathLogWidget:AddTooltip(target, tooltip)
	target.tooltip = tooltip
	target:SetScript("OnEnter", ShowTooltip)
	target:SetScript("OnLeave", HideTooltip)
end

function DeathLogWidget:CreateTextFrame()
	local frame = CreateFrame("Frame", nil, self.scrollChild)
	frame:SetHeight(14)
	frame:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT")
	frame:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT")
	frame:EnableMouse(true)

	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.text:SetPoint("TOPLEFT")
	frame.text:SetSize(0, 0) -- X, Y is 0 so it ignores the parent X,Y limitations and stratches as far as it wants
	frame.text:SetJustifyH("LEFT")
	frame.text:SetJustifyV("TOP")
	return frame
end

function DeathLogWidget:AddEntry(data, tooltip)
	local entry = self:CreateTextFrame()
	table.insert(self.textFrames, entry)
	entry.text:SetText(data)
	self:AddTooltip(entry, tooltip)
	if self.previousEntry then
		self.previousEntry:SetPoint("TOPLEFT", entry, "BOTTOMLEFT")
		self.previousEntry:SetPoint("TOPRIGHT", entry, "BOTTOMRIGHT")
	end
	self.previousEntry = entry
	self.scrollFrame:UpdateScrollChildRect()
end

function DeathLogWidget:Show()
	widgetInstance.mainWnd:Show()
end

-----------------------------------------------------------------------------------------
-- This should be in another file but idk why .toc doesn't want to load additional files
-----------------------------------------------------------------------------------------

local _, core = ...;


local classes = {
	[1] = "Воин",
	[2] = "Паладин",
	[3] = "Охотник",
	[4] = "Разбойник",
	[5] = "Жрец",
	[6] = "Рыцарь смерти", -- ??
	[7] = "Шаман", -- 7 is shaman
	[8] = "Маг", -- 8 is mage
	[9] = "Чернокнижник", -- 9 is warlock
	-- [10] = "someone?",
	[11] = "Друид" -- 11 druid
}

local alliances = {
	[0] = "Орда",
	[1] = "Альянс",
	[2] = "Neutral"
}

local races = {
	[1] = { "Человек", "Альянс" },
	[2] = { "Орк", "Орда" },
	[3] = { "Дворф", "Альянс" },
	[4] = { "Ночной эльф", "Альянс" },
	[5] = { "Нежить", "Орда" },
	[6] = { "Таурен", "Орда" },
	[7] = { "Гном", "Альянс" },
	[8] = { "Тролль", "Орда" },
	[9] = { "Гоблин", "Орда" },
	[10] = { "Син'дорей", "Орда" },
	[11] = { "Дреней", "Альянс" },
	[12] = { "Ворген", "Альянс" },
	[13] = { "Нага", "Орда" },
	[14] = { "Пандарен", "Альянс" }, -- Alliance
	[15] = { "Высший эльф", "Альянс" },
	[16] = { "Пандарен", "Орда" }, -- Horde
	-- [17] = {"Пандарен", "Альянс"},		-- not pandaren
	[18] = { "Эльф бездны", "Альянс" },
	[19] = { "Вульпера", "Альянс" }, -- Alliance
	[20] = { "Вульпера", "Орда" }, -- Horde
	[21] = { "Эльф крови", "Орда" },
	[22] = { "Пандарен", "Нейтрал" }, -- Neutral
	[23] = { "Зандалар", "Орда" },
	[24] = { "Озаренный дреней", "Альянс" }, -- Should be it
	[25] = { "Эредар", "Орда" },
	[26] = { "Дворф Черного Железа", "Альянс" },
	[27] = { "Драктир", "Альянс" }
}

local colors = {
	["Орда"] = "FFFF0000",
	["Альянс"] = "FF0070DD",
	["Нейтрал"] = "FFFFFFFF",
	["Воин"] = "FFC79C6E",
	["Паладин"] = "FFF58CBA",
	["Охотник"] = "FFABD473",
	["Разбойник"] = "FFFFF569",
	["Жрец"] = "FFFFFFFF",
	["Рыцарь смерти"] = "FFC41F3B",
	["Шаман"] = "FF0070DE",
	["Маг"] = "FF69CCF0",
	["Чернокнижник"] = "FF9482C9",
	["Друид"] = "FFFF7D0A",
	["Золотой"] = "FFFFD700",
	["Зеленый"] = "FF00FF00",
	["Красный"] = "FFFF0000"
}

local causes = {
	[0] = "Усталость",
	[1] = "Утопление",
	[2] = "Падение",
	[7] = "Убийство",
}

---		[-5] = "Fire",
---		[-6] = "Lava",
---		[-7] = "Slime",

local function ColorWord(word, colorRepr)
	if not word or not colorRepr then
		return nil
	end
	local colorCode = colors[colorRepr]
	if not colorCode then
		return nil
	end
	return "|c" .. colorCode .. word .. "|r"
end

local function StringToMap(str, sep)
	local tbl = {}
	local keys = { "name", "raceID", "sideID", "classID", "level", "locationStr", "causeID", "enemyName", "enemyLevel" }
	local index = 1
	for str in string.gmatch(str, "[^:]+") do
		tbl[keys[index]] = tonumber(str) or str
		index = index + 1
	end

	return tbl
end

local function TimeNow()
	return date("%H:%M:%S", GetServerTime())
end

local function GetRaceData(id)
	local raceTuple = races[id]
	local coloredRace, race, side
	if raceTuple then
		race = raceTuple[1]
		side = raceTuple[2]
		coloredRace = ColorWord(race, side)
	else
		race = id
		coloredRace = race
		side = "Неизвестно"
	end
	return coloredRace, race, side
end

local function FormatData(data)
	local timeData = "[" .. TimeNow() .. "]"
	local name = ColorWord(data.name, classes[data.classID])
	local coloredRace, race, side = GetRaceData(data.raceID)
	local level
	if data.level >= 60 then
		level = ColorWord(data.level .. "ур.", "Золотой")
	else
		level = data.level .. "ур."
	end
	local cause = causes[data.causeID] or data.causeID


	local mainStr = string.format("%s %s %s %s", timeData, name, coloredRace, level)
	local tooltip = string.format(
		"Статус: %s\nИмя: %s\nУровень: %d\nКласс: %s\nРаса: %s\nФракция: %s\nЛокация: %s\nПричина: %s",
		ColorWord("Провален", "Красный"), data.name, data.level, classes[data.classID], race, side, data.locationStr,
		cause)
	if data.causeID == 7 then
		tooltip = tooltip .. "\nОт: " .. data.enemyName .. " " .. data.enemyLevel .. "-го уровня"
	end
	return mainStr, tooltip
end

local function FormatCompletedChallengeData(data)
	local timeData = ColorWord("[" .. TimeNow() .. "]", "Золотой")
	local name = ColorWord(data.name, classes[data.classID])
	local coloredRace, race, side = GetRaceData(data.raceID)
	local mainStr = string.format("%s %s %s %s", timeData, name, coloredRace, ColorWord("завершил испытание!", "Золотой"))
	local tooltip = string.format("Статус: %s\nИмя: %s\nКласс: %s\nРаса: %s\nФракция: %s",
		ColorWord("Пройден", "Зеленый"), data.name, classes[data.classID], race, side)
	return mainStr, tooltip
end

local function HandleFormattedData(data, tooltip)
	if widgetInstance then
		widgetInstance:AddEntry(data, tooltip)
	end
end

local function OnDeath(text)
	local deadPlayerData, tooltip = FormatData(StringToMap(text))
	HandleFormattedData(deadPlayerData, tooltip)
end

local function OnComplete(text)
	local challengeCompletedData, tooltip = FormatCompletedChallengeData(StringToMap(text))
	HandleFormattedData(challengeCompletedData, tooltip)
end

local function OnEvent(self, event, prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
	if prefix == "ASMSG_HARDCORE_DEATH" then
		OnDeath(text)
		return
	end

	if prefix == "ASMSG_HARDCORE_COMPLETE" then
		OnComplete(text)
		return
	end
end

local function InitWindow(show)
	if not widgetInstance then
		widgetInstance = DeathLogWidget.new()
	end
	if show then
		widgetInstance:Show()
	end
end

local function SlashCommandHandle(msg)
	if widgetInstance then
		widgetInstance:Show()
		return
	end
	DeathLoggerDB.showOnStartup = true
	InitWindow(true)
end

local function OnReady(self, event, arg1, ...)
	if event == "ADDON_LOADED" and arg1 == "DeathLogger" then
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:SetScript("OnEvent", OnEvent)
		if DeathLoggerDB.showOnStartup == nil then
			DeathLoggerDB.showOnStartup = true
		end
		InitWindow(DeathLoggerDB.showOnStartup)
	end
end



SLASH_DEATHLOGGER1, SLASH_DEATHLOGGER2 = "/deathlog", "/dl"
SlashCmdList["DEATHLOGGER"]            = SlashCommandHandle


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:HookScript("OnEvent", OnReady)
