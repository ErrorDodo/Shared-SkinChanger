local websockets            = require "gamesense/websockets"
local pretty_json           = require "gamesense/pretty_json"
local ffi                   = require("ffi")

local get_tickcount         = globals.tickcount
local get_realtime          = globals.realtime
local get_maxplayers        = globals.maxplayers

local get_local_player      = entity.get_local_player
local get_player_weapon     = entity.get_player_weapon
local get_prop              = entity.get_prop
local set_prop              = entity.set_prop
local get_steam64           = entity.get_steam64
local get_classname         = entity.get_classname

local userid_to_entindex    = client.userid_to_entindex
local set_event_callback    = client.set_event_callback
local find_signature        = client.find_signature

local bit_band              = bit.band

local weapondata = {}

local DEFAULT_URL = "" --Enter Websocket serverip here
local websocket_connection

local function update_skin()

end

local callbacks = {
	open = function(ws)
		print("[WS] connection to ", ws.url, " opened!")
		websocket_connection = ws
	end,
    message = function(ws, data)
        if data:match("^{") then
            local jsondata = json.parse(data)
                for k,v in ipairs(weapondata) do
                    if v.steamid == jsondata.steamid then
                        table.remove(weapondata, k)
                    end
                end
                table.insert(weapondata, jsondata)
        end
	end,
	close = function(ws, code, reason, was_clean)
        print("[WS] Connection closed: code=", code, " reason=", reason, " was_clean=", was_clean)
		websocket_connection = nil
	end,
	error = function(ws, err)
		print("[WS] Error: ", err)
		websocket_connection = nil
	end
}

local connect = true
local function send_data(type, data)
    if websocket_connection == nil and connect == true then
        websockets.connect(DEFAULT_URL, callbacks)
        connect = false
    elseif websocket_connection ~= nil then
        websocket_connection:send(string.format("%s\n%s", type, pretty_json.stringify(data)))
        return true
    end
    return false
end

local prev_weapon = nil
--net_update_start
set_event_callback("net_update_start", function()
    if get_prop(get_local_player(), "m_lifeState") ~= 0 or not get_local_player() then 
        return 
    end

    local player_weapon = get_player_weapon(get_local_player())
    
    local weapon_index = bit_band(65535, get_prop(player_weapon, "m_iItemDefinitionIndex") or 0)
    if weapon_index == prev_weapon then
        return
    end

    local table = {
        type = "update",
        hostname = cvar.hostname:get_string(),
        steamid = get_steam64(get_local_player()),
        m_iItemDefinitionIndex = weapon_index,
        m_iItemIDHigh = get_prop(player_weapon, "m_iItemIDHigh"),
        m_nFallbackPaintKit = get_prop(player_weapon, "m_nFallbackPaintKit"),
        m_flFallbackWear = get_prop(player_weapon, "m_flFallbackWear"),
        m_nFallbackStatTrak = get_prop(player_weapon, "m_nFallbackStatTrak"),
        m_nFallbackSeed = get_prop(player_weapon, "m_nFallbackSeed")
    }

    if send_data("update", table) then
        prev_weapon = weapon_index
    end
end)

set_event_callback("net_update_start", function()
    if get_prop(get_local_player(), "m_lifeState") ~= 0 or not get_local_player() then 
        return 
    end

    if table.maxn(weapondata) == 0 then 
        return
    end

    local update = false
    for i=1, get_maxplayers() do
        if get_classname(i) == "CCSPlayer" then
            for k,v in ipairs(weapondata) do
                if get_steam64(i) == v.steamid then
                    for x = 0, 64 do
                        local weapon = get_prop(i, "m_hMyWeapons", x)
                        if weapon ~= nil then
                            if bit_band(65535, get_prop(weapon, "m_iItemDefinitionIndex") or 0) == v.m_iItemDefinitionIndex then
                                set_prop(weapon, "m_iItemIDHigh", -1)
                                set_prop(weapon, "m_nFallbackPaintKit", v.m_nFallbackPaintKit)
                                set_prop(weapon, "m_flFallbackWear", v.m_flFallbackWear)
                                set_prop(weapon, "m_nFallbackStatTrak", v.m_nFallbackStatTrak)
                                set_prop(weapon, "m_nFallbackSeed", v.m_nFallbackSeed)

                                if v.forceupdate == true then
                                    cvar.cl_fullupdate:invoke_callback()
                                    v.forceupdate = false
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)