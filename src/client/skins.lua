local websockets            = require "gamesense/websockets"
local csgo_weapons          = require "gamesense/csgo_weapons"
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
local get_player_name       = entity.get_player_name
local get_all               = entity.get_all

local is_alive              = entity.is_alive
local is_dormant            = entity.is_dormant
local is_enemy              = entity.is_enemy

local userid_to_entindex    = client.userid_to_entindex
local set_event_callback    = client.set_event_callback
local find_signature        = client.find_signature
local create_interface      = client.create_interface

local bit_band              = bit.band

local ffi_cast              = ffi.cast
local ffi_typeof            = ffi.typeof
local ffi_new               = ffi.new

local table_maxn            = table.maxn
local table_insert          = table.insert
local table_remove          = table.remove
local table_foreach         = table.foreach

local fuckdododata          = {}

ffi.cdef([[
    struct IRefCounted {
        volatile long refCount;
    };

	struct C_Utl_Vector_s { 
		struct IRefCounted**    m_pMemory;
		int32_t                 m_nAllocationCount;
        int32_t                 m_nGrowSize;
        int32_t                 m_Size;
        void*                   m_pElements;
    };

    struct PlayerInfo_s {
        uint64_t	    ullVersion;
        int				nXuidLow;
        int				nXuidHigh;
        char			szName[128];
        int				nUserID;
        char			szSteamID[33];
        uint32_t	    nFriendsID;
        char			szFriendsName[128];
        bool			bFakePlayer;
        bool			bIsHLTV;
        uint32_t		CustomFiles[4];
        char	        dFilesDownloaded;
    };

    typedef void(__thiscall* Destructor_t)(struct IRefCounted*, char);      //0
    typedef bool(__thiscall* OnFinalRelease_t)(struct IRefCounted*);        //1

    //VClientEntityList003
    typedef void*(__thiscall* GetClientEntityFromHandle_t)(void*, unsigned long);

    //VEngineClient014
    typedef bool(__thiscall* GetPlayerInfo_t)(void*, int, struct PlayerInfo_s*);

    //VModelInfoClient004
    typedef int(__thiscall* get_model_index_t)(void*, const char*);

    typedef void(__thiscall* PostDataUpdate_t)(void*, int);
    typedef void(__thiscall* OnDataChanged_t)(void*, int);
    typedef void(__thiscall* set_model_index_t)(void*, int);
]])

local interface_ptr                     = ffi_typeof("void***")

local m_CustomMaterials_a               = find_signature("client.dll", "\x83\xBE\xCC\xCC\xCC\xCC\xCC\x7F\x67") or error("m_CustomMaterials not found")
local m_CustomMaterials                 = ffi_cast("uint32_t*", ffi_cast("uint32_t", m_CustomMaterials_a) + 2)[0] - 12

local m_bCustomMaterialInitialized_a    = find_signature("client.dll", "\xC6\x86\xCC\xCC\xCC\xCC\xCC\xFF\x50\x04") or error("m_bCustomMaterialInitialized not found")
local m_bCustomMaterialInitialized      = ffi_cast("uint32_t*", ffi_cast("uint32_t", m_bCustomMaterialInitialized_a) + 2)[0]

local raw_ent_list                      = create_interface("client.dll", "VClientEntityList003") or error("VClientEntityList003 wasnt found")
local ent_list                          = ffi_cast(interface_ptr, raw_ent_list) or error("raw_ent_list is nil", 2)
local get_client_entity                 = ffi_cast("GetClientEntityFromHandle_t", ent_list[0][3]) or error("ent_list is nil")

local raw_engine                        = create_interface("engine.dll", "VEngineClient014") or error("VClientEntityList003 wasnt found")
local engine                            = ffi_cast(interface_ptr, raw_engine) or error("raw_engine is nil")
local get_player_info                   = ffi_cast("GetPlayerInfo_t", engine[0][8]) or error("engine is nil")

local rawivmodelinfo                    = create_interface("engine.dll", "VModelInfoClient004") or error("VModelInfoClient004 wasnt found", 2)
local ivmodelinfo                       = ffi_cast(interface_ptr, rawivmodelinfo) or error("rawivmodelinfo is nil", 2)
local get_model_index                   = ffi_cast("get_model_index_t", ivmodelinfo[0][2]) or error("get_model_info is nil", 2)

local DEFAULT_URL                       = "ws://127.0.0.1:8080"
local websocket_connection              = nil

local callbacks = {
	open = function(ws)
		print("[WS] connection to ", ws.url, " opened!")
		websocket_connection = ws
	end,
    message = function(ws, data)
        if data:match("^{") then
            local jsondata = json.parse(data)
            for k, v in ipairs(fuckdododata) do
                if v.steamid == jsondata.steamid then
                    table_remove(fuckdododata, k)
                end
            end
            table_insert(fuckdododata, jsondata)
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
local function send_data(data)
    if websocket_connection == nil and connect == true then
        websockets.connect(DEFAULT_URL, callbacks)
        connect = false
    elseif websocket_connection ~= nil then
        websocket_connection:send(json.stringify(data))
        return true
    end
    return websocket_connection ~= nil
end

set_event_callback("setup_command", function(c)
    local player_weapon = get_player_weapon(get_local_player())
    if player_weapon ~= nil then
        local weapon_index = get_prop(player_weapon, "m_iItemDefinitionIndex")
        if csgo_weapons[weapon_index].is_melee_weapon then
            return
        end

        local table = {
            steamid = get_steam64(get_local_player()),
            shareids = {},
            m_iItemDefinitionIndex = weapon_index,
            m_nFallbackPaintKit = get_prop(player_weapon, "m_nFallbackPaintKit"),
            m_flFallbackWear = get_prop(player_weapon, "m_flFallbackWear"),
            m_nFallbackStatTrak = get_prop(player_weapon, "m_nFallbackStatTrak"),
            m_nFallbackSeed = get_prop(player_weapon, "m_nFallbackSeed")
        }

        for i = 1, get_maxplayers() do
            if i ~= get_local_player() then
                local steamid = get_steam64(i)
                if steamid ~= 0 and steamid ~= nil then
                    table.shareids[#table.shareids + 1] = steamid
                end
            end
        end

        if send_data(table) then
        end
    end
end)

local function forceupdate(weapon_ptr)  
    local network_ptr = ffi_cast("char*", weapon_ptr + 0x8)
    local network_vtable = ffi_cast(interface_ptr, weapon_ptr + 0x8)

    local on_data_changed = ffi_cast("OnDataChanged_t", network_vtable[0][5])
    local post_data_update = ffi_cast("PostDataUpdate_t", network_vtable[0][7])

    --C_WeaponCSBase->m_CustomMaterials
    local base_m_CustomMaterials = ffi_cast("struct C_Utl_Vector_s*", weapon_ptr + m_CustomMaterials)[0]
    base_m_CustomMaterials.m_Size = 0

    --C_WeaponCSBase->m_bCustomMaterialInitialized
    ffi_cast("bool*", weapon_ptr + m_bCustomMaterialInitialized)[0] = ffi_cast("int*", weapon_ptr + 0x31C8)[0] <= 0
    
    --C_EconItemView->m_CustomMaterials
    local item_m_CustomMaterials = ffi_cast("struct C_Utl_Vector_s*", weapon_ptr + 0x2D80 + 0x40 + 0x14)[0]
    item_m_CustomMaterials.m_Size = 0

    --C_EconItemView->m_VisualsDataProcessors
    local item_m_VisualsDataProcessors = ffi_cast("struct C_Utl_Vector_s*",  ffi_cast("struct C_Utl_Vector_s*", weapon_ptr + 0x2D80 + 0x40 + 0x230)[0])

    if item_m_VisualsDataProcessors.m_Size ~= 0 then
        local m_Size = item_m_VisualsDataProcessors.m_Size - 1
        for i = 0, m_Size do
            local m_pMemory = ffi_cast("struct IRefCounted*", item_m_VisualsDataProcessors.m_pMemory[i])
            local vtable = ffi_cast(interface_ptr, item_m_VisualsDataProcessors.m_pMemory[i])[0]
            local Destructor = ffi_cast("Destructor_t", vtable[0])
            local OnFinalRelease = ffi_cast("OnFinalRelease_t", vtable[1])
                    
            if OnFinalRelease(m_pMemory) then
                Destructor(m_pMemory, 1)
                item_m_VisualsDataProcessors.m_pMemory[i] = nil
            end
        end
        item_m_VisualsDataProcessors.m_Size = 0
    end

    post_data_update(network_ptr, 0)
    on_data_changed(network_ptr, 0)
end

local function override_weapon(index, active_weapon, weapon_ptr, data)
    set_prop(active_weapon, "m_iAccountID", get_steam64(index));
    set_prop(active_weapon, "m_iItemIDHigh", -1);
    set_prop(active_weapon, "m_nFallbackPaintKit", data.m_nFallbackPaintKit);
    set_prop(active_weapon, "m_flFallbackWear", data.m_flFallbackWear);
    set_prop(active_weapon, "m_nFallbackStatTrak", data.m_nFallbackStatTrak);
    set_prop(active_weapon, "m_nFallbackSeed", data.m_nFallbackSeed);
    
    if data.forceupdate then
        forceupdate(weapon_ptr)
    end
end

set_event_callback("net_update_start", function()
    if table_maxn(fuckdododata) == 0 then
        return
    end

    table_foreach(get_all("CCSPlayer"), function(k, ent_index)
        if ent_index ~= get_local_player() then
            for k, v in ipairs(fuckdododata) do
                if get_steam64(ent_index) == v.steamid then
                    local active_weapon = get_player_weapon(ent_index)
                    if active_weapon ~= nil and get_prop(active_weapon, "m_iItemDefinitionIndex") == v.m_iItemDefinitionIndex then
                        local player_ptr = ffi_cast("char*", get_client_entity(ent_list, ent_index))
                        if player_ptr ~= nil then
                            local m_hActiveWeapon = ffi_cast("unsigned long*", player_ptr + 0x2EF8)[0]
                            local bit_handle = bit_band(0xFFF, m_hActiveWeapon)
                            local weapon_ptr = ffi_cast("char*", get_client_entity(ent_list, bit_handle))
                            if weapon_ptr ~= nil then
                                override_weapon(ent_index, active_weapon, weapon_ptr, v)
                                v.forceupdate = false
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end)
