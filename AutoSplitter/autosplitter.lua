if not _G.AutoSplitter then
	_G.AutoSplitter = _G.AutoSplitter or {}
	AutoSplitter._path = ModPath
	AutoSplitter._data_path = SavePath .. "autosplitter.json"
	AutoSplitter._data = {}
	AutoSplitter._actions = { nil, 'startorsplit', 'split', 'starttimer' }
	AutoSplitter._debug = true
end
local AutoSplitter = _G.AutoSplitter

function AutoSplitter:SaveSettings()
	local file = io.open( self._data_path, "w+" )
	if file then
		file:write( json.encode( self._data ) )
		file:close()
	end
end

function AutoSplitter:setDefaultValue(field, value)
	-- explicit check for nil to not override fields with value false
	if self._data[field] == nil then
		self._data[field] = value
	end
end

function AutoSplitter:LoadSettings()
	local file = io.open( self._data_path, "r" )
	if file then
		self._data = json.decode( file:read("*all") ) or {}
		file:close()
	end
	
	-- default values
	self:setDefaultValue("enabled", true)
	self:setDefaultValue("sendIGT", true)
	self:setDefaultValue("igt_on_restarts", true)
	self:setDefaultValue("action_heist_completion", 3)
	self:setDefaultValue("action_menu", 4)
	self:setDefaultValue("action_heist_start", 1)
	self:setDefaultValue("action_waiting_for_players", 1)
end

function AutoSplitter:GetPipe()
	-- reusing the handle might be faster but leads to problems when restarting livesplit
	return io.open("//./pipe/LiveSplit", 'a+')
end

function AutoSplitter:SendCmd(pipe, cmd)
	pipe:write(cmd, "\r\n")
	pipe:flush()
end

function AutoSplitter:GetCmdResult(pipe)
	local res = pipe:read("*line")
	pipe:seek("end") -- skip any unconsumed chars
	return res
end

function AutoSplitter:GetCmdTimeResult(pipe)
	local str = self:GetCmdResult(pipe)
	local hours, minutes, seconds = str:match("([^:]+):([^:]+):([^:]+)")
	if not hours then
		minutes, seconds = str:match("([^:]+):([^:]+)")
		hours = 0
	end
	return tonumber(seconds) + tonumber(minutes or 0) * 60 + tonumber(hours or 0) * 3600
end

function AutoSplitter:SendIGT(pipe, igt)
	if self._data.sendIGT and igt and pipe then
		-- might return realtime, no way to check unfortunately
		self:SendCmd(pipe, "getcurrentgametime") 
		prev_igt = self:GetCmdTimeResult(pipe)
		igt = igt + prev_igt
		igt = tostring(igt)
		if self._debug then
			log("Sending IGT to LiveSplit: " .. igt)
		end
		self:SendCmd(pipe, "setgametime " .. igt)
	end
end

function AutoSplitter:StartOrSplitWithIGT(igt, action)
	local pipe = self:GetPipe()
	if pipe then
		self:SendCmd(pipe, "alwayspausegametime")
		self:SendCmd(pipe, "getsplitindex")
		local currentIndex = tonumber(self:GetCmdResult(pipe))
		
		if currentIndex >= 0 and self._data.sendIGT then
			self:SendIGT(pipe, igt)
		end
		if action then
			self:SendCmd(pipe, action)
		end
		-- set game time to zero when starting
		if (action == "starttimer" or action == "startorsplit") and currentIndex < 0 and self._data.sendIGT then
			self:SendIGT(pipe, "0")
		end
		pipe:close()
	elseif self._debug then
		log("Could not connect to livesplit")
	end
end

-- Menu
if RequiredScript == "lib/managers/menumanager" then
	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_AutoSplitter", function( loc )
		loc:load_localization_file( AutoSplitter._path .. "loc/english.json")
	end)

	Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_AutoSplitter", function( menu_manager )

		MenuCallbackHandler.callback_autosplitter_enabled = function(self, item)
			AutoSplitter._data.enabled = (item:value() == "on" and true or false)
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_send_igt = function(self, item)
			AutoSplitter._data.sendIGT = (item:value() == "on" and true or false)
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_igt_on_restarts = function(self, item)
			AutoSplitter._data.igt_on_restarts = (item:value() == "on" and true or false)
			AutoSplitter:SaveSettings()
		end
		
		MenuCallbackHandler.callback_autosplitter_action_heist_completion = function(self, item)
			AutoSplitter._data.action_heist_completion = item:value()
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_action_menu = function(self, item)
			AutoSplitter._data.action_menu = item:value()
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_action_heist_start = function(self, item)
			AutoSplitter._data.action_heist_start = item:value()
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_action_waiting_for_players = function(self, item)
			AutoSplitter._data.action_waiting_for_players = item:value()
			AutoSplitter:SaveSettings()
		end

		MenuCallbackHandler.callback_autosplitter_btn_split = function(self, item)
			AutoSplitter:StartOrSplitWithIGT(nil, AutoSplitter._actions[2])
		end

		AutoSplitter:LoadSettings()
		MenuHelper:LoadFromJsonFile( AutoSplitter._path .. "menu.json", AutoSplitter, AutoSplitter._data )
	end )
end

-- Split after successfull mission
if RequiredScript == "lib/states/victorystate" then
	Hooks:PreHook(VictoryState, "at_enter" , "autosplitter_victorystate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				local isLastDay = (not managers.job:current_job_chain_data()) or #(managers.job:current_job_chain_data()) == managers.job:current_stage()
				local igt = tostring(math.round(managers.statistics:get_session_time_seconds()))
				local action = nil
				
				-- only split on job finish not day, but otherwise still update IGT 
				if isLastDay then
					action = AutoSplitter._actions[AutoSplitter._data.action_heist_completion]
				end
				AutoSplitter:StartOrSplitWithIGT(igt, action)
			end
		end, state)
	end)
end

-- Update IGT on fail
if RequiredScript == "lib/states/gameoverstate" then
	Hooks:PreHook(GameOverState, "at_enter" , "autosplitter_gameoverstate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled and AutoSplitter._data.igt_on_restarts then
				local igt = tostring(math.round(managers.statistics:get_session_time_seconds()))
				AutoSplitter:StartOrSplitWithIGT(igt, nil)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/menumainstate" then
	Hooks:PostHook(MenuMainState, "at_enter" , "autosplitter_menumainstate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				local action = AutoSplitter._actions[AutoSplitter._data.action_menu]
				AutoSplitter:StartOrSplitWithIGT(nil, action)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/ingamewaitingforplayers" then
	Hooks:PostHook(IngameWaitingForPlayersState, "at_enter" , "autosplitter_ingamewaitingforplayers_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				local action = AutoSplitter._actions[AutoSplitter._data.action_waiting_for_players]
				AutoSplitter:StartOrSplitWithIGT(nil, action)
			end
		end, state)
	end)
	Hooks:PostHook(IngameWaitingForPlayersState, "at_exit" , "autosplitter_ingamewaitingforplayers_at_exit" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				local action = AutoSplitter._actions[AutoSplitter._data.action_heist_start]
				AutoSplitter:StartOrSplitWithIGT(nil, action)
			end
		end, state)
	end)
end

-- Update time on restarts
if RequiredScript == "lib/managers/gameplaycentralmanager" then
	Hooks:PreHook(GamePlayCentralManager, "restart_the_game" , "autosplitter_restart_the_game" , function(gsm)
		pcall(function(state)
			if AutoSplitter._data.enabled and AutoSplitter._data.igt_on_restarts and Utils:IsInHeist() then
				local igt = tostring(math.round(managers.statistics:get_session_time_seconds()))
				AutoSplitter:StartOrSplitWithIGT(igt, nil)
			end
		end, state)
	end)
end