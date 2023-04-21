if RequiredScript == "lib/managers/menumanager" then
	function disable_items()
		local menu = MenuHelper:GetMenu("autosplitter_menu")
		for _, item in pairs(menu._items) do
			local name = item._parameters.name
			if name == "autosplitter_igt_on_restarts" or name == "autosplitter_round_igt" then
				item:set_enabled(AutoSplitter._data.game_time_mode == AutoSplitter._game_time_modes.HeistTime)
			end
		end
	end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_AutoSplitter", function( loc )
		loc:load_localization_file( AutoSplitter._path .. "lua/loc/english.json")
	end)

	Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_AutoSplitter", function( menu_manager )

		MenuCallbackHandler.callback_autosplitter_enabled = function(self, item)
			AutoSplitter._data.enabled = (item:value() == "on" and true or false)
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_game_time_mode = function(self, item)
			AutoSplitter._data.game_time_mode = item:value()
			AutoSplitter:SaveSettings()
			disable_items()
		end
		
		MenuCallbackHandler.callback_autosplitter_igt_on_restarts = function(self, item)
			AutoSplitter._data.igt_on_restarts = (item:value() == "on" and true or false)
			AutoSplitter:SaveSettings()
		end
		MenuCallbackHandler.callback_autosplitter_round_igt = function(self, item)
			AutoSplitter._data.round_igt = (item:value() == "on" and true or false)
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
			AutoSplitter:DoActionAndUpdateTime(nil, AutoSplitter._actions.StartOrSplit, nil, nil)
		end

		AutoSplitter:LoadSettings()
		MenuHelper:LoadFromJsonFile( AutoSplitter._path .. "lua/menu.json", AutoSplitter, AutoSplitter._data )
		Hooks:Add("MenuManagerBuildCustomMenus","autosplitter_disable_items", function(menu_manager, nodes)
			disable_items()
		end)
	end )
end