local Pre = true
local Post = false
function AddHook(isPre, objName, funcName, hookFunc)
	addHook = pre and Hooks.PreHook or Hooks.PostHook
	addHook(Hooks, _G[objName], funcName , "autosplitter_" .. objName .. funcName , function()
		pcall(function()
			if AutoSplitter._data.enabled then
				hookFunc()
			end
		end)
	end)
end

-- Split after successfull mission
if RequiredScript == "lib/states/victorystate" then
	AddHook(Pre, "VictoryState", "at_enter" , function()
		local isLastDay = (not managers.job:current_job_chain_data()) or #(managers.job:current_job_chain_data()) == managers.job:current_stage()
		local igt = AutoSplitter:GetHeistTime()
		local action = nil
		
		-- only split on job finish not day, but otherwise still update IGT 
		if isLastDay then
			action = AutoSplitter._data.action_heist_completion
		end
		AutoSplitter:DoActionAndUpdateTime(igt, action, AutoSplitter.PAUSE, nil)
	end)
end

-- Update IGT on fail
if RequiredScript == "lib/states/gameoverstate" then
	AddHook(Pre, "GameOverState", "at_enter" , function()
		if AutoSplitter._data.igt_on_restarts then
			local igt = AutoSplitter:GetHeistTime()
			AutoSplitter:DoActionAndUpdateTime(igt, nil, AutoSplitter.PAUSE, nil)
		end
	end)
end

if RequiredScript == "lib/states/menumainstate" then
	AddHook(Post, "MenuMainState", "at_enter" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_menu, nil, AutoSplitter.UNPAUSE)
	end)
end

if RequiredScript == "lib/states/ingamewaitingforplayers" then
	AddHook(Post, "IngameWaitingForPlayersState", "at_enter" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_waiting_for_players, nil, AutoSplitter.UNPAUSE)
	end)
	AddHook(Post, "IngameWaitingForPlayersState", "at_exit" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_heist_start, AutoSplitter.UNPAUSE, nil)
	end)
end

-- Update time on restarts
if RequiredScript == "lib/managers/jobmanager" then
	AddHook(Pre, "JobManager", "_on_retry_job_stage" , function()
		if AutoSplitter._data.igt_on_restarts and Utils:IsInHeist() then
			local igt = AutoSplitter:GetHeistTime()
			AutoSplitter:DoActionAndUpdateTime(igt, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
		end
	end)
end

if RequiredScript == "lib/setups/setup" then
	-- timers should always be paused when we reach init, but to be sure in case we somehow missed a previous pause hook
	AddHook(Pre, "Setup", "init" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
	end)
	-- Action when buying a heist in singleplayer or the host presses start in multiplayer
	AddHook(Pre, "Setup", "load_level" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, nil, nil, AutoSplitter.PAUSE)
	end)
	-- Action when going back to the main menu (Quitting, Terminating or after the MissionEndScreen)
	AddHook(Pre, "Setup", "load_start_menu" , function()
		AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
	end)

	local isPaused = false
	AddHook(Pre, "Setup", "paused_update" , function()
		if not isPaused then
			isPaused = true
			if Utils:IsInHeist() then
				AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.WEAK_PAUSE, nil)
			end
		end
	end)
	AddHook(Pre, "Setup", "update" , function()
		if isPaused then
			isPaused = false
			if Utils:IsInHeist() then
				AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.WEAK_UNPAUSE, nil)
			end
		end
	end)
end