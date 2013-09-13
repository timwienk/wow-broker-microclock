local name, addon = ...
local broker = addon:NewModule('DataBroker')

-- Localise global variables
local format, insert, concat = string.format, table.insert, table.concat

local options

broker.type = 'data source'
broker.icon = 'Interface\\Icons\\Spell_Holy_BorrowedTime'
broker.text = 'Micro Menu'

function broker:OnInitialize()
	options = addon:GetModule('Options').db.clock
	LibStub('LibDataBroker-1.1'):NewDataObject(name, self)
end

function broker:OnEnable()
	addon:Subscribe('UPDATE_TIME', self, 'OnUpdateTime')
end

function broker:OnDisable()
	addon:Unsubscribe('UPDATE_TIME', self, 'OnUpdateTime')
end

function broker:OnUpdateTime(localTime, realmTime, universalTime)
	local timeStrings = {}

	if options.showLocalTime then
		insert(timeStrings, self.CreateTimeString(localTime))
	end

	if options.showRealmTime then
		insert(timeStrings, self.CreateTimeString(realmTime))
	end

	if options.showUniversalTime then
		insert(timeStrings, self.CreateTimeString(universalTime))
	end

	self.text = concat(timeStrings, ' | ')
end

function broker.OnEnter(frame)
	if broker.enabledState then
		addon:Publish('MOUSE_ENTER', frame)
	end
end

function broker.OnLeave(frame)
	if broker.enabledState then
		addon:Publish('MOUSE_LEAVE', frame)
	end
end

function broker.OnClick(frame, ...)
	if broker.enabledState then
		addon:Publish('MOUSE_CLICK', frame, ...)
	end
end

function broker.CreateTimeString(time)
	local hours, timeString

	if options.mode == 12 then
		hours = time.hours % 12
		if hours == 0 then
			hours = 12
		end
	else
		hours = time.hours % 24
	end

	if options.showSeconds then
		timeString = format('%d:%02d:%02d', hours, time.minutes, time.seconds)
	else
		timeString = format('%d:%02d', hours, time.minutes)
	end

	if options.mode == 12 then
		timeString = timeString .. (time.pm and addon.L[' PM'] or addon.L[' AM'])
	end

	return timeString
end
