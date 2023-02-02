if not _G.AutoSplitter then
	_G.AutoSplitter = _G.AutoSplitter or {}
	AutoSplitter._path = ModPath
	AutoSplitter._data_path = SavePath .. "autosplitter.json"
	AutoSplitter._data = {}
	AutoSplitter._actions = {
		None = 1,
		StartOrSplit = 2,
		Split = 3,
		Start = 4
	}
	AutoSplitter._action_cmds = {
		[AutoSplitter._actions.StartOrSplit] = 'startorsplit',
		[AutoSplitter._actions.Split] = 'split',
		[AutoSplitter._actions.Start] = 'starttimer'
	}
	AutoSplitter._game_time_modes = {
		Disabled = 1,
		HeistTime = 2,
		RealTimeHeistOnly = 3,
		LoadRemovedTime = 4
	}
	AutoSplitter.PAUSE = 1
	AutoSplitter.UNPAUSE = 2
	AutoSplitter.WEAK_PAUSE = 3
	-- weak unpause only undo weak pause, used for RealTimeHeistOnly when opening the menu in a heist
	AutoSplitter.WEAK_UNPAUSE = 4
	AutoSplitter._isPaused = false
	AutoSplitter._isWeakPaused = false
end

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
	self:setDefaultValue("game_time_mode", self._game_time_modes.HeistTime)
	self:setDefaultValue("igt_on_restarts", true)
	self:setDefaultValue("round_igt", true)
	self:setDefaultValue("action_heist_completion", self._actions.Split)
	self:setDefaultValue("action_menu", self._actions.Start)
	self:setDefaultValue("action_heist_start", self._actions.None)
	self:setDefaultValue("action_waiting_for_players", self._actions.None)
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
	local hours, minutes, seconds = str:match("([^:]+):([^:]+):([^:]+)") -- best regex ever
	if not hours then
		minutes, seconds = str:match("([^:]+):([^:]+)")
		hours = 0
	end
	return tonumber(seconds) + tonumber(minutes or 0) * 60 + tonumber(hours or 0) * 3600
end

function AutoSplitter:SendIGT(pipe, igt)
	if igt and pipe then
		-- might return realtime, no way to check unfortunately
		self:SendCmd(pipe, "getcurrentgametime") 
		prev_igt = self:GetCmdTimeResult(pipe)
		igt = igt + prev_igt
		igt = tostring(igt)
		self:SendCmd(pipe, "setgametime " .. igt)
	end
end

function AutoSplitter:DoActionAndUpdateTime(igt, action, pauseHeistOnly, pauseLoadRemoving)
	local pipe = self:GetPipe()
	if pipe then
		self:SendCmd(pipe, "getsplitindex")
		local currentIndex = tonumber(self:GetCmdResult(pipe))
		local isStart = (action == self._actions.Start or action == self._actions.StartOrSplit) and currentIndex < 0

		if self:UsesHeistTime() then
			self:SendCmd(pipe, "alwayspausegametime")
			if currentIndex >= 0 and igt then
				self:SendIGT(pipe, igt)
			end
		end

		local pauseAction = nil
		if self:UsesRealTimeHeistOnly() then
			pauseAction = pauseHeistOnly or (isStart and self.PAUSE) -- default paused at start
		elseif self:UsesLoadRemoving() then
			pauseAction = pauseLoadRemoving or (isStart and self.UNPAUSE) -- default unpaused at start
		end
		if pauseAction == self.PAUSE then
			self:SendCmd(pipe, "pausegametime")
			self._isPaused = true
			self._isWeakPaused = false
		elseif pauseAction == self.UNPAUSE then
			self:SendCmd(pipe, "unpausegametime")
			self._isPaused = false
			self._isWeakPaused = false
		elseif pauseAction == self.WEAK_PAUSE then
			self:SendCmd(pipe, "pausegametime")
			self._isWeakPaused = self._isWeakPaused or not self._isPaused
			self._isPaused = true
		elseif pauseAction == self.WEAK_UNPAUSE and self._isWeakPaused then
			self:SendCmd(pipe, "unpausegametime")
			self._isPaused = false
			self._isWeakPaused = false
		end

		if action and self._action_cmds[action] then
			self:SendCmd(pipe, self._action_cmds[action])
		end
		if isStart and self:UsesHeistTime() then
			-- set game time to zero when starting
			self:SendIGT(pipe, 0)
		end
		pipe:close()
	end
end

function AutoSplitter:GetHeistTime()
	local time = managers.statistics:get_session_time_seconds()
	if self._data.round_igt then
		time = math.round(time)
	end
	return time
end

function AutoSplitter:UsesHeistTime()
	return self._data.game_time_mode == self._game_time_modes.HeistTime
end

function AutoSplitter:UsesRealTimeHeistOnly()
	return self._data.game_time_mode == self._game_time_modes.RealTimeHeistOnly
end

function AutoSplitter:UsesLoadRemoving()
	return self._data.game_time_mode == self._game_time_modes.LoadRemovedTime
end
