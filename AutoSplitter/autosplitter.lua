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
	local hours, minutes, seconds = str:match("([^:]+):([^:]+):([^:]+)") -- best regex ever
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
		self:SendCmd(pipe, "setgametime " .. igt)
	end
end

function AutoSplitter:DoActionAndUpdateTime(igt, action)
	local pipe = self:GetPipe()
	if pipe then
		self:SendCmd(pipe, "getsplitindex")
		local currentIndex = tonumber(self:GetCmdResult(pipe))

		if self._data.sendIGT then
			self:SendCmd(pipe, "alwayspausegametime")
			if currentIndex >= 0 and igt then
				self:SendIGT(pipe, igt)
			end
		end
		if action and self._action_cmds[action] then
			self:SendCmd(pipe, self._action_cmds[action])
		end
		if self._data.sendIGT then
			-- set game time to zero when starting
			if (action == self._actions.Start or action == self._actions.StartOrSplit) and currentIndex < 0 then
				self:SendIGT(pipe, "0")
			end
		end
		
		pipe:close()
	end
end