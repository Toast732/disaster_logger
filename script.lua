-- Author: Toastery
-- GitHub: https://github.com/Toast732
-- Workshop: 
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

-- library prefixes
local debugging = {} -- functions related to debugging

-- shortened library names
local s = server
local m = matrix
local d = debugging

DISASTER_LOGGER_VERSION = "(0.1.0)"

g_savedata = {
	disaster_log = {},
	owner = nil
}

function onCreate()
	d.print("Loading Script: " .. s.getAddonData((s.getAddonIndex())).name, "Complete, Version: "..DISASTER_LOGGER_VERSION, -1)
end

local player_commands = {
	normal = {
		info = {
			short_desc = "prints info about the mod",
			desc = "prints some info about the mod in chat! specifically the version of the mod.",
			args = "none",
			example = "?dlog info",
		},
		help = {
			short_desc = "shows a list of all of the commands",
			desc = "shows a list of all of the commands, to learn more about a command, type to commands name after \"help\" to learn more about it",
			args = "[command]",
			example = "?dlog help history",
		},
	},		
	admin = {},
	host = {
		history = {
			short_desc = "prints disaster history",
			desc = "prints history on disasters, will show the most recent one, you can specify a number to see back in history, for example, ?dlog history 1 will show the second most recent disaster",
			args = "[disasters_ago]",
			example = "?dlog history\n?dlog history 1",
		},
		clear_history = {
			short_desc = "clears disaster history",
			desc = "clears all disaster history",
			args = "none",
			example = "?dlog clear_history",
		}
	}
}

function onCustomCommand(full_message, peer_id, is_admin, is_auth, prefix, command, ...)
	if prefix == "?dlog" then
		command = string.lower(command) -- makes the command friendly, removing underscores and captitals
		local arg = table.pack(...) -- this will supply all the remaining arguments to the function

		-- commands


		-- host only commands
		if is_admin and g_savedata.owner == getSteamID(peer_id) then
			if command == "history" then
				if #g_savedata.disaster_log ~= 0 then
					local disasters_ago = (#g_savedata.disaster_log) - (arg[1] and tonumber(arg[1]) or 0)
					if disasters_ago > #g_savedata.disaster_log then
						d.print("That disaster never occured! the oldest one was "..#g_savedata.disaster_log.." disasters ago!", peer_id)
					else
						d.print("Disaster Type: "..g_savedata.disaster_log[disasters_ago].disaster_data.type)
						for _, player in pairs(g_savedata.disaster_log[disasters_ago].player_data) do
							d.print("-----\nname: "..player.name.."\nSteamID: "..player.steam_id.."\nHas Admin: "..(player.is_admin and "True" or "False").."\nDistance from disaster: "..math.floor(player.distance).."m")
						end
					end
				else
					d.print("There have been no disasters yet!", peer_id)
				end
			elseif command == "clear_history" then
				g_savedata.disaster_log = {}
				d.print("Disaster history cleared!", peer_id)
			end
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id)
	-- set the owner as the first player to join
	if not g_savedata.owner then
		g_savedata.owner = tostring(steam_id)
		d.print("You have been set as the owner! if this is a mistake, please contact the real owner.", peer_id)
	end
end

function onDisaster(disaster_type, disaster_transform)
	local player_list = s.getPlayers()
	local disaster_info = {
		player_data = {},
		disaster_data = {
			type = disaster_type
		}
	}

	for peer_index, player in pairs(player_list) do
		local player_transform = s.getPlayerPos(player.id)
		table.insert(disaster_info.player_data, {
			name = player.name,
			steam_id = getSteamID(player.id),
			is_admin = player.admin,
			distance = m.distance(player_transform, disaster_transform)
		})
	end

	table.insert(g_savedata.disaster_log, disaster_info)
end

function onTornado(transform)
	onDisaster("Tornado", transform)
end

function onMeteor(transform)
	onDisaster("Meteor", transform)
end

function onTsunami(transform)
	onDisaster("Tsunami", transform)
end

function onWhirlpool(transform)
	onDisaster("Whirlpool", transform)
end

function onVolcano(transform)
	onDisaster("Volcano", transform)
end

--------------------------------------------------------------------------------
--
-- Debugging Functions
--
--------------------------------------------------------------------------------

---@param message string the message you want to print
---@param peer_id integer if you want to send it to a specific player, leave empty to send to all players
function debugging.print(message, peer_id)
	local prefix = s.getAddonData((s.getAddonIndex())).name
	
	if type(message) == "table" then
		printTable(message, requires_debug, debug_type, peer_id)

	elseif peer_id then
		s.announce(prefix, message, peer_id)
	else
		local player_list = s.getPlayers()
		for peer_index, player in pairs(player_list) do
			s.announce(prefix, message, player.id)
		end
	end
end

--------------------------------------------------------------------------------
--
-- Other
--
--------------------------------------------------------------------------------

---@param peer_id integer the peer_id of the player you want to get the steam id of
---@return string steam_id the steam id of the player, nil if not found
function getSteamID(peer_id)
	local player_list = s.getPlayers()
	for peer_index, peer in pairs(player_list) do
		if peer.id == peer_id then
			return tostring(peer.steam_id)
		end
	end
	d.print("(getSteamID) unable to get steam_id for peer_id: "..peer_id, true, 1)
	return nil
end