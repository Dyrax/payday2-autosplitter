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
					action = AutoSplitter._data.action_heist_completion
				end
				AutoSplitter:DoActionAndUpdateTime(igt, action)
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
				AutoSplitter:DoActionAndUpdateTime(igt, nil)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/menumainstate" then
	Hooks:PostHook(MenuMainState, "at_enter" , "autosplitter_menumainstate_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_menu)
			end
		end, state)
	end)
end

if RequiredScript == "lib/states/ingamewaitingforplayers" then
	Hooks:PostHook(IngameWaitingForPlayersState, "at_enter" , "autosplitter_ingamewaitingforplayers_at_enter" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_waiting_for_players)
			end
		end, state)
	end)
	Hooks:PostHook(IngameWaitingForPlayersState, "at_exit" , "autosplitter_ingamewaitingforplayers_at_exit" , function(state)
		pcall(function(state)
			if AutoSplitter._data.enabled then
				AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._data.action_heist_start)
			end
		end, state)
	end)
end

-- Update time on restarts
if RequiredScript == "lib/managers/jobmanager" then
	Hooks:PreHook(JobManager, "_on_retry_job_stage" , "autosplitter_on_retry_job_stage" , function(gsm)
		pcall(function(state)
			if AutoSplitter._data.enabled and AutoSplitter._data.igt_on_restarts and Utils:IsInHeist() then
				local igt = tostring(math.round(managers.statistics:get_session_time_seconds()))
				AutoSplitter:DoActionAndUpdateTime(igt, nil)
			end
		end, state)
	end)
end