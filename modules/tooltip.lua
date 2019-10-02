local name, addon = ...
local tooltip = addon:NewModule('Tooltip')

-- Localise global variables
local _G = _G
local collectgarbage, ipairs, floor, type = _G.collectgarbage, _G.ipairs, _G.floor, _G.type
local format, insert, sort = _G.string.format, _G.table.insert, _G.table.sort
local LoadAddOn, GetNumAddOns, GetAddOnInfo = _G.LoadAddOn, _G.GetNumAddOns, _G.GetAddOnInfo
local UpdateAddOnMemoryUsage, GetAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage, _G.GetAddOnMemoryUsage
local SetPortraitTexture, SetSmallGuildTabardTextures = _G.SetPortraitTexture, _G.SetSmallGuildTabardTextures
local ShowUIPanel, HideUIPanel = _G.ShowUIPanel, _G.HideUIPanel
local GetBindingKey, GetAtlasInfo = _G.GetBindingKey, _G.GetAtlasInfo
local UnitFactionGroup, IsInGuild, IsStoreEnabled = _G.UnitFactionGroup, _G.IsInGuild, _G.C_StorePublic.IsEnabled
local CHARACTER_BUTTON, COLLECTIONS = _G.CHARACTER_BUTTON, _G.COLLECTIONS
local MICRO_BUTTONS, SOCIAL_BUTTON, SPELLBOOK_ABILITIES_BUTTON = _G.MICRO_BUTTONS, _G.SOCIAL_BUTTON, _G.SPELLBOOK_ABILITIES_BUTTON
local ToggleAchievementFrame, ToggleLFDParentFrame = _G.ToggleAchievementFrame, _G.ToggleLFDParentFrame
local ToggleCollectionsJournal, ToggleHelpFrame = _G.ToggleCollectionsJournal, _G.ToggleHelpFrame
local ToggleStoreUI, ToggleQuestLog = _G.ToggleStoreUI, _G.ToggleQuestLog
local ToggleFriendsFrame, ToggleWorldMap, ToggleTalentFrame = _G.ToggleFriendsFrame, _G.ToggleWorldMap, _G.ToggleTalentFrame
local GetCVarBool, GetFramerate, GetDownloadedPercentage = _G.GetCVarBool, _G.GetFramerate, _G.GetDownloadedPercentage
local GetNetStats, GetNetIpTypes, GetAvailableBandwidth = _G.GetNetStats, _G.GetNetIpTypes, _G.GetAvailableBandwidth
local MAINMENUBAR_LATENCY_LABEL, MAINMENUBAR_FPS_LABEL = _G.MAINMENUBAR_LATENCY_LABEL, _G.MAINMENUBAR_FPS_LABEL
local MAINMENUBAR_PROTOCOLS_LABEL, MAINMENUBAR_BANDWIDTH_LABEL = _G.MAINMENUBAR_PROTOCOLS_LABEL, _G.MAINMENUBAR_BANDWIDTH_LABEL
local MAINMENUBAR_DOWNLOAD_PERCENT_LABEL, UNKNOWN = _G.MAINMENUBAR_DOWNLOAD_PERCENT_LABEL, _G.UNKNOWN

local options = addon:GetModule('Options')
local LibQTip = LibStub('LibQTip-1.0')

function tooltip:OnInitialize()
	options = options.db.tooltip
end

function tooltip:OnEnable()
	addon:Subscribe('MOUSE_ENTER', self, 'Show')
	addon:Subscribe('UPDATE_OPTIONS', self, 'OnUpdateOptions')
end

function tooltip:OnDisable()
	self:Hide()
	addon:Unsubscribe('MOUSE_ENTER', self, 'Show')
	addon:Unsubscribe('UPDATE_OPTIONS', self, 'OnUpdateOptions')
end

function tooltip:OnUpdateOptions(group)
	if group == nil then
		options = addon:GetModule('Options').db.tooltip
	end
end

function tooltip:Show(anchor)
	self:Hide()

	if self.enabledState then
		self.tip = LibQTip:Acquire(name .. 'Tooltip', 2, 'LEFT', 'LEFT')
		self.tip.OnRelease = function() self.tip = nil end

		if self:Update() then
			self.tip:SetAutoHideDelay(0.1, anchor)
			self.tip:SmartAnchorTo(anchor)
			self.tip:Show()
		else
			self:Hide()
		end
	end
end

function tooltip:Update()
	local hasData = false

	if self.enabledState then
		self.tip:Clear()

		local order
		if options.order == 1 then
			order = {'AddStats', 'AddSeparator', 'AddMemory', 'AddSeparator', 'AddMenu'}
		elseif options.order == 2 then
			order = {'AddStats', 'AddSeparator', 'AddMenu', 'AddSeparator', 'AddMemory'}
		elseif options.order == 3 then
			order = {'AddMenu', 'AddSeparator', 'AddStats', 'AddSeparator', 'AddMemory'}
		elseif options.order == 4 then
			order = {'AddMenu', 'AddSeparator', 'AddMemory', 'AddSeparator', 'AddStats'}
		elseif options.order == 5 then
			order = {'AddMemory', 'AddSeparator', 'AddStats', 'AddSeparator', 'AddMenu'}
		elseif options.order == 6 then
			order = {'AddMemory', 'AddSeparator', 'AddMenu', 'AddSeparator', 'AddStats'}
		end

		local callNext = true
		for _, fn in ipairs(order) do
			if callNext then
				callNext = self[fn](self)
				if callNext then
					hasData = true
				end
			else
				callNext = true
			end
		end
	end

	return hasData
end

function tooltip:Hide()
	if self.tip then
		LibQTip:Release(self.tip)
	end
end

function tooltip:AddLine(text, icon, action)
	local line = self.tip:AddLine()

	if icon then
		self.tip:SetCell(line, 1, icon, self:GetIconProvider())
	end

	if text then
		self.tip:SetCell(line, 2, text)
	end

	if action then
		self.tip:SetLineScript(line, 'OnMouseUp', action)
	end

	return line
end

function tooltip:AddSeparator()
	return self.tip:AddSeparator(10, 0, 0, 0, 0)
end

function tooltip:AddStats()
	if not options.showStats then
		return false
	end

	local _, _, latencyHome, latencyWorld = GetNetStats();
	self:AddLine(format(MAINMENUBAR_LATENCY_LABEL, latencyHome, latencyWorld));
	self:AddSeparator()

	if GetCVarBool('useIPv6') then
		local ipTypes = {'IPv4', 'IPv6'}
		local ipTypeHome, ipTypeWorld = GetNetIpTypes();
		self:AddLine(format(MAINMENUBAR_PROTOCOLS_LABEL, ipTypes[ipTypeHome or 0] or UNKNOWN, ipTypes[ipTypeWorld or 0] or UNKNOWN));
		self:AddSeparator()
	end

	self:AddLine(format(MAINMENUBAR_FPS_LABEL, GetFramerate()));
	self:AddLine(format(MAINMENUBAR_BANDWIDTH_LABEL, GetAvailableBandwidth()));

	local percent = floor(GetDownloadedPercentage() * 100 + 0.5);
	if percent > 0 then
		self:AddLine(format(MAINMENUBAR_DOWNLOAD_PERCENT_LABEL, percent));
	end

	return true
end

function tooltip:AddMemory()
	if not options.showMemory then
		return false
	end

	local entries, memory, total = {}, 0, 0
	local entry

	collectgarbage()
	UpdateAddOnMemoryUsage()

	for index = 1, GetNumAddOns() do
		memory = GetAddOnMemoryUsage(index)
		if memory > 0 then
			entry = {name=GetAddOnInfo(index), memory=memory}
			insert(entries, entry)
			total = total + memory
		end
	end

	sort(entries, tooltip.CompareAddOns)

	self:AddLine(addon.L['AddOn Memory: '] .. self.FormatMemory(total))
	self:AddLine(addon.L['..with Blizzard: '] .. self.FormatMemory(collectgarbage('count')))

	if options.addonCount > 0 then
		self:AddSeparator()

		for index = 1, options.addonCount do
			entry = entries[index]
			if entry then
				self:AddLine(format('(%s) %s', self.FormatMemory(entry.memory), entry.name))
			end
		end
	end

	return true
end

function tooltip:AddMenu()
	if not options.showMenu then
		return false
	end

	for _, buttonName in ipairs(MICRO_BUTTONS) do
		local enabled = true

		if buttonName == 'StoreMicroButton' then
			if not IsStoreEnabled() then
				enabled = false
			end
		end

		if enabled then
			self:AddLine(self.GetButtonText(buttonName), self.GetButtonTexture(buttonName), self.GetButtonAction(buttonName))
		end
	end

	return true
end

function tooltip:GetIconProvider()
	if self.iconProvider then
		return self.iconProvider
	end

	local provider, prototype = LibQTip:CreateCellProvider()

	function prototype:InitializeCell()
		self.texture = self:CreateTexture()
		self.texture:SetAllPoints(self)
	end

	function prototype:SetupCell(tooltip, value)
		local texture = self.texture
		local width, height = 14, 15

		texture:SetWidth(width)
		texture:SetHeight(height)

		if value == 'player' then
			SetPortraitTexture(texture, 'player')
			texture:SetTexCoord(0.22, 0.78, 0.2, 0.8)

		elseif value == 'guild' then
			SetSmallGuildTabardTextures('player', texture, texture)

		elseif value == 'pvp' then
			local faction = UnitFactionGroup('player')
			if faction == 'Alliance' then
				texture:SetTexture('Interface\\TargetingFrame\\UI-PVP-Alliance')
			elseif faction == 'Horde' then
				texture:SetTexture('Interface\\TargetingFrame\\UI-PVP-Horde')
			else
				texture:SetTexture('Interface\\TargetingFrame\\UI-PVP-FFA')
			end
			texture:SetTexCoord(0.07, 0.63, 0.05, 0.65)

		elseif value == 'Interface\\ChatFrame\\UI-ChatIcon-BattleBro-Up' then
			texture:SetTexture(value)
			texture:SetTexCoord(0.17, 0.77, 0.15, 0.75)

		elseif type(value) == 'table' then
			texture:SetTexture(value[1])
			if #value >= 7 then
				texture:SetTexCoord(value[4] + 0.005, value[5] - 0.005, value[6] + 0.04, value[7] - 0.03)
			end

		else
			texture:SetTexture(value)
			texture:SetTexCoord(0.05, 0.95, 0.5, 0.9)

		end

		return width, height
	end

	self.iconProvider = provider

	return provider
end

function tooltip.FormatMemory(memory)
	if memory > 1024 then
		return format('%.2f MiB', memory / 1024)
	else
		return format('%.2f KiB', memory)
	end
end

function tooltip.CompareAddOns(a, b)
	return a.memory > b.memory
end

function tooltip.GetButtonText(name)
	local text, key

	if _G[name].tooltipText then
		text = _G[name].tooltipText
	elseif name == 'CharacterMicroButton' then
		text = CHARACTER_BUTTON
		key = GetBindingKey('TOGGLECHARACTER0')
	elseif name == 'CollectionsMicroButton' then
		text = COLLECTIONS
		key = GetBindingKey('TOGGLECOLLECTIONS')
	elseif name == 'SpellbookMicroButton' then
		text = SPELLBOOK_ABILITIES_BUTTON
		key = GetBindingKey('TOGGLESPELLBOOK')
	elseif name == 'FriendsMicroButton' then
		text = SOCIAL_BUTTON
		key = GetBindingKey('TOGGLESOCIAL')
	end

	if text and key then
		text = text .. '|cffffd200 (' .. key .. ')|r'
	end

	return text
end

function tooltip.GetButtonTexture(name)
	local texture

	if name == 'CharacterMicroButton' then
		texture = 'player'
	elseif name == 'GuildMicroButton' then
		texture = 'guild'
	elseif name == 'PVPMicroButton' then
		texture = 'pvp'
	else
		local atlas = _G[name]:GetNormalTexture():GetAtlas()
		if atlas then
			texture = {GetAtlasInfo(atlas)}
		else
			texture = _G[name]:GetNormalTexture():GetTexture()
		end
	end

	return texture
end

function tooltip.GetButtonAction(name)
	local action, addon, frame, fn

	if name == 'CharacterMicroButton' then
		frame = 'CharacterFrame'

	elseif name == 'SpellbookMicroButton' then
		frame = 'SpellBookFrame'

	elseif name == 'TalentMicroButton' then
		if ToggleTalentFrame == nil then
			addon = 'Blizzard_TalentUI'
			frame = 'PlayerTalentFrame'
		else
			fn = ToggleTalentFrame
		end

	elseif name == 'AchievementMicroButton' then
		fn = ToggleAchievementFrame

	elseif name == 'QuestLogMicroButton' then
		fn = ToggleQuestLog

	elseif name == 'GuildMicroButton' then
		fn = function()
			local frame

			if IsInGuild() then
				if not _G.GuildFrame then
					LoadAddOn('Blizzard_GuildUI')
				end
				frame = _G.GuildFrame
			else
				if not _G.GuildFrame then
					LoadAddOn('Blizzard_LookingForGuildUI')
				end
				frame = _G.LookingForGuildFrame
			end

			if frame:IsShown() then
				HideUIPanel(frame)
			else
				ShowUIPanel(frame)
			end
		end

	elseif name == 'PVPMicroButton' then
		addon = 'Blizzard_PVPUI'
		frame = 'PVPUIFrame'

	elseif name == 'LFDMicroButton' then
		fn = ToggleLFDParentFrame

	elseif name == 'EJMicroButton' then
		addon = 'Blizzard_EncounterJournal'
		frame = 'EncounterJournal'

	elseif name == 'CollectionsMicroButton' then
		fn = ToggleCollectionsJournal

	elseif name == 'MainMenuMicroButton' then
		frame = 'GameMenuFrame'

	elseif name == 'HelpMicroButton' then
		fn = ToggleHelpFrame

	elseif name == 'FriendsMicroButton' then
		frame = 'FriendsFrame'

	elseif name == 'SocialsMicroButton' then
		fn = ToggleFriendsFrame

	elseif name == 'StoreMicroButton' then
		fn = ToggleStoreUI

	elseif name == 'WorldMapMicroButton' then
		fn = ToggleWorldMap

	end

	if not fn then
		if addon and frame then
			fn = function()
				if not _G[frame] then
					LoadAddOn(addon)
				end

				if _G[frame]:IsShown() then
					HideUIPanel(_G[frame])
				else
					ShowUIPanel(_G[frame])
				end
			end
		elseif frame then
			fn = function()
				if _G[frame]:IsShown() then
					HideUIPanel(_G[frame])
				else
					ShowUIPanel(_G[frame])
				end
			end
		end
	end

	if fn then
		action = function()
			fn()
			tooltip:Hide()
		end
	end

	return action
end
