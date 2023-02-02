-- Split after successfull mission
if RequiredScript == "lib/states/victorystate" then
	Hooks:PreHook(VictoryState, "at_enter" , "autosplitter_victorystate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				local isLastDay = (not managers.job:current_job_chain_data()) or #(managers.job:current_job_chain_data()) == managers.job:current_stage()
				local igt = AutoSplitter:GetHeistTime()
				local action = nil
				
				-- only split on job finish not day, but otherwise still update IGT 
				if isLastDay then
					action = AutoSplitter._data.action_heist_completion
				end
				AutoSplitter:DoActionAndUpdateTime(igt, action, AutoSplitter.PAUSE, nil)
			end
		end, state)
	end)
end

-- Update IGT on fail
if RequiredScript == "lib/states/gameoverstate" then
	Hooks:PreHook(GameOverState, "at_enter" , "autosplitter_gameoverstate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled and AutoSplitter._data.igt_on_restarts then
				local igt = AutoSplitter:GetHeistTime()
				AutoSplitter:DoActionAndUpdateTime(igt, nil, AutoSplitter.PAUSE, nil)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/menumainstate" then
	Hooks:PostHook(MenuMainState, "at_enter" , "autosplitter_menumainstate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_menu, nil, AutoSplitter.UNPAUSE)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/ingamewaitingforplayers" then
	Hooks:PostHook(IngameWaitingForPlayersState, "at_enter" , "autosplitter_ingamewaitingforplayers_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_waiting_for_players, nil, AutoSplitter.UNPAUSE)
			end
		end, state)
	end)
	Hooks:PostHook(IngameWaitingForPlayersState, "at_exit" , "autosplitter_ingamewaitingforplayers_at_exit" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_heist_start, AutoSplitter.UNPAUSE, nil)
			end
		end, state)
	end)
end

-- Update time on restarts
if RequiredScript == "lib/managers/jobmanager" then
	Hooks:PreHook(JobManager, "_on_retry_job_stage" , "autosplitter_on_retry_job_stage" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled and AutoSplitter._data.igt_on_restarts and Utils:IsInHeist() then
				local igt = AutoSplitter:GetHeistTime()
				AutoSplitter:DoActionAndUpdateTime(igt, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
			end
		end, state)
	end)
end

if RequiredScript == "lib/setups/setup" then
	-- timers should always be paused when we reach init, but to be sure in case we somehow missed a previous pause hook
	Hooks:PreHook(Setup, "init" , "autosplitter_setup_init" , function(setup)
		pcall(function(setup)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
			end
		end, setup)
	end)
	-- Action when buying a heist in singleplayer or the host presses start in multiplayer
	Hooks:PreHook(Setup, "load_level" , "autosplitter_setup_load_level" , function(setup)
		pcall(function(setup)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, nil, nil, AutoSplitter.PAUSE)
			end
		end, setup)
	end)
	-- Action when going back to the main menu (Quitting, Terminating or after the MissionEndScreen)
	Hooks:PreHook(Setup, "load_start_menu" , "autosplitter_setup_load_start_menu" , function(setup)
		pcall(function(setup)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.PAUSE, AutoSplitter.PAUSE)
			end
		end, setup)
	end)

	local isPaused = false
	Hooks:PreHook(Setup, "paused_update" , "autosplitter_setup_paused_update" , function(setup)
		pcall(function(setup)
			if AutoSplitter._data.enabled then
				if not isPaused then
					isPaused = true
					if Utils:IsInHeist() then
						AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.WEAK_PAUSE, nil)
					end
				end
			end
		end, setup)
	end)
	Hooks:PreHook(Setup, "update" , "autosplitter_setup_update" , function(setup)
		pcall(function(setup)
			if AutoSplitter._data.enabled then
				if isPaused then
					isPaused = false
					if Utils:IsInHeist() then
						AutoSplitter:DoActionAndUpdateTime(nil, nil, AutoSplitter.WEAK_UNPAUSE, nil)
					end
				end
			end
		end, setup)
	end)
end