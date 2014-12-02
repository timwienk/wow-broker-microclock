local name, addon = ...
local options = addon:NewModule('Options')

-- Localise global variables
local _G = _G
local gsub, lower = _G.string.gsub, _G.string.lower

local db
local defaultOptions = {
	clock = {
		mode = 24,
		showSeconds = true,

		showLocalTime = true,
		showRealmTime = false,
		showUniversalTime = false
	},
	tooltip = {
		order = 1,
		showMenu = true,
		showMemory = true,
		addonCount = 15
	}
}

function options:OnInitialize()
	db = LibStub('AceDB-3.0'):New(name .. 'DB', {profile = defaultOptions}, true)
	db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
	db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileChanged')
	db.RegisterCallback(self, 'OnProfileReset', 'OnProfileChanged')

	self.db = db.profile

	self:InitializeConfig()
end

function options:OnProfileChanged(event, db)
	self.db = db.profile
	addon:Publish('UPDATE_OPTIONS')
end

function options:MakeGetter(group)
	local function get(key)
		return self.db[group][key.arg]
	end

	return get
end

function options:MakeSetter(group)
	local function set(key, value)
		self.db[group][key.arg] = value
		addon:Publish('UPDATE_OPTIONS', group, key.arg, value)
	end

	return set
end

function options:InitializeConfig()
	local L = addon.L
	local profileOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(db)
	profileOptions.guiHidden = true
	profileOptions.cmdHidden = true

	local clockModes = {}
	clockModes[12] = L['12 hours']
	clockModes[24] = L['24 hours']

	local tooltipOrders = {}
	tooltipOrders[1] = L['Memory on top']
	tooltipOrders[2] = L['Menu on top']

	local config = {
		type = 'group',
		name = name,
		args = {
			clock = {
				order = 1,
				type = 'group',
				name = L['Clock options'],
				get = options:MakeGetter('clock'),
				set = options:MakeSetter('clock'),
				args = {
					headerStyle = {order=1, type='header', name=L['Display style']},
					mode = {order=2, type='select', name=L['Clock mode'], arg='mode', values=clockModes, style='radio'},
					seconds = {order=3, type='toggle', name=L['Show seconds'], arg='showSeconds'},
					headerTimes = {order=4, type='header', name=L['Show times']},
					localTime = {order=5, type='toggle', name=L['Show local time'], arg='showLocalTime'},
					realmTime = {order=6, type='toggle', name=L['Show realm time'], arg='showRealmTime'},
					universalTime = {order=7, type='toggle', name=L['Show universal time'], arg='showUniversalTime'}
				}
			},

			tooltip = {
				order = 2,
				type = 'group',
				name = L['Tooltip options'],
				get = options:MakeGetter('tooltip'),
				set = options:MakeSetter('tooltip'),
				args = {
					headerStyle = {order=1, type='header', name=L['Display style']},
					order = {order=2, type='select', name=L['Order'], arg='order', values=tooltipOrders, style='radio'},
					headerMenu = {order=3, type='header', name=L['Menu']},
					menu = {order=4, type='toggle', name=L['Show menu'], arg='showMenu'},
					headerMemory = {order=5, type='header', name=L['Memory']},
					memory = {order=6, type='toggle', name=L['Show memory'], arg='showMemory'},
					addons = {order=7, type='range', name=L['Number of addons'], arg='addonCount', min=0, max=50, step=1}
				}
			},

			config = {
				order = 3,
				type = 'execute',
				guiHidden = true,
				name = L['Open configuration interface'],
				func = self.Open
			},

			profile = profileOptions
		}
	}

	LibStub('AceConfig-3.0'):RegisterOptionsTable(name, config, gsub(lower(name), '^broker_', ''))

	local ConfigDialog = LibStub('AceConfigDialog-3.0')
	ConfigDialog:AddToBlizOptions(name)
	ConfigDialog:AddToBlizOptions(name, profileOptions.name, name, 'profile') 
end

function options.Open()
	LibStub('AceConfigDialog-3.0'):Open(name)
end
