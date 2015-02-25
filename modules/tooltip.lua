local name, addon = ...
local tooltip = addon:NewModule('Tooltip')

-- Localise global variables
local _G = _G
local collectgarbage, ipairs = _G.collectgarbage, _G.ipairs
local format, insert, sort = _G.string.format, _G.table.insert, _G.table.sort
local LoadAddOn, GetNumAddOns, GetAddOnInfo = _G.LoadAddOn, _G.GetNumAddOns, _G.GetAddOnInfo
local UpdateAddOnMemoryUsage, GetAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage, _G.GetAddOnMemoryUsage
local SetPortraitTexture, SetSmallGuildTabardTextures = _G.SetPortraitTexture, _G.SetSmallGuildTabardTextures
local ShowUIPanel, HideUIPanel, GetBindingKey = _G.ShowUIPanel, _G.HideUIPanel, _G.GetBindingKey
local UnitFactionGroup, IsInGuild, IsStoreEnabled = _G.UnitFactionGroup, _G.IsInGuild, _G.C_StorePublic.IsEnabled
local MICRO_BUTTONS, SOCIAL_BUTTON, SPELLBOOK_ABILITIES_BUTTON = _G.MICRO_BUTTONS, _G.SOCIAL_BUTTON, _G.SPELLBOOK_ABILITIES_BUTTON
local ToggleAchievementFrame, ToggleLFDParentFrame = _G.ToggleAchievementFrame, _G.ToggleLFDParentFrame
local ToggleCollectionsJournal, ToggleHelpFrame = _G.ToggleCollectionsJournal, _G.ToggleHelpFrame
local ToggleStoreUI, ToggleQuestLog = _G.ToggleStoreUI, _G.ToggleQuestLog

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
		local hasData

		self.tip = LibQTip:Acquire(name .. 'Tooltip', 2, 'LEFT', 'LEFT')
		self.tip:Clear()

		if options.showMenu and options.order == 2 then
			self:AddMenu()
			hasData = true

			if options.showMemory then
				self:AddSeparator()
			end
		end

		if options.showMemory then
			self:AddMemory()
			hasData = true

			if options.showMenu and options.order == 1 then
				self:AddSeparator()
			end
		end

		if options.showMenu and options.order == 1 then
			self:AddMenu()
			hasData = true
		end

		self.tip.OnRelease = function() self.tip = nil end

		if hasData then
			self.tip:SetAutoHideDelay(0.1, anchor)
			self.tip:SmartAnchorTo(anchor)
			self.tip:Show()
		else
			self:Hide()
		end
	end
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

function tooltip:AddMemory()
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
end

function tooltip:AddMenu()
	for _, buttonName in ipairs(MICRO_BUTTONS) do
		local enabled = true

		if buttonName == 'MainMenuMicroButton' then
			self:AddLine(self.GetButtonText('FriendsMicroButton'), self.GetButtonTexture('FriendsMicroButton'), self.GetButtonAction('FriendsMicroButton'))

		elseif buttonName == 'StoreMicroButton' then
			if not IsStoreEnabled() then
				enabled = false
			end
		end

		if enabled then
			self:AddLine(self.GetButtonText(buttonName), self.GetButtonTexture(buttonName), self.GetButtonAction(buttonName))

		end
	end
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

	if name == 'SpellbookMicroButton' then
		text = SPELLBOOK_ABILITIES_BUTTON
		key = GetBindingKey('TOGGLESPELLBOOK')
	elseif name == 'FriendsMicroButton' then
		text = SOCIAL_BUTTON
		key = GetBindingKey('TOGGLESOCIAL')
	end

	if text then
		if key then
			text = text .. '|cffffd200 (' .. key .. ')|r'
		end
	else
		text = _G[name].tooltipText
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
		texture = _G[name]:GetNormalTexture():GetTexture()
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
		addon = 'Blizzard_TalentUI'
		frame = 'PlayerTalentFrame'

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

	elseif name == 'StoreMicroButton' then
		fn = ToggleStoreUI

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
