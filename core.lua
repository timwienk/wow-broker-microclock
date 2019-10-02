local name, addon = ...
LibStub('AceAddon-3.0'):NewAddon(addon, name, 'AceTimer-3.0', 'LibPubSub-1.0')

-- Localise global variables
local _G = _G
local date, floor, GetGameTime = _G.date, _G.floor, _G.GetGameTime
local IsAltKeyDown, IsAddOnLoaded = _G.IsAltKeyDown, _G.IsAddOnLoaded
local ToggleCalendar, Stopwatch_Toggle = _G.ToggleCalendar, _G.Stopwatch_Toggle
local GroupCalendar = _G.GroupCalendar

function addon:OnInitialize()
	self.L = LibStub('AceLocale-3.0'):GetLocale(name)
end

function addon:OnEnable()
	self.timer = self:ScheduleRepeatingTimer('UpdateTime', 1)
	self:Subscribe('MOUSE_CLICK', 'OnClick')
	self:Subscribe('UPDATE_OPTIONS', 'OnUpdateOptions')
end

function addon:OnDisable()
	self:CancelTimer(self.timer)
	self:Unsubscribe('MOUSE_CLICK', 'OnClick')
	self:Unsubscribe('UPDATE_OPTIONS', 'OnUpdateOptions')
end

function addon:OnClick(frame, button)
	if IsAltKeyDown() then
		self:GetModule('Options').Open()
	elseif button == 'RightButton' then
		Stopwatch_Toggle()
	elseif IsAddOnLoaded('GroupCalendar5') then
		if GroupCalendar.UI.Window:IsShown() then
			GroupCalendar.UI.Window:Hide()
		else
			GroupCalendar.UI.Window:Show()
		end
	elseif ToggleCalendar then
		ToggleCalendar()
	end
end

function addon:OnUpdateOptions(group)
	if group == nil or group == 'clock' then
		self:UpdateTime()
	end
end

function addon:UpdateTime()
	local seconds = date('%S')
	local realmHours, realmMinutes = GetGameTime()

	local localTime = {hours=date('%H'), minutes=date('%M'), seconds=seconds}
	local realmTime = {hours=realmHours, minutes=realmMinutes, seconds=seconds}
	local universalTime = {hours=date('!%H'), minutes=date('!%M'), seconds=seconds}

	localTime.am = (floor(localTime.hours / 12) == 0)
	realmTime.am = (floor(realmTime.hours / 12) == 0)
	universalTime.am = (floor(universalTime.hours / 12) == 0)

	localTime.pm = (localTime.am == false)
	realmTime.pm = (realmTime.am == false)
	universalTime.pm = (universalTime.am == false)

	self:Publish('UPDATE_TIME', localTime, realmTime, universalTime)
end
