const WebSocket = require('ws');
const Ajv = require('ajv');

let socket_map = new Map();

const EItemDefinitionIndex = new Set(
[
    0, 1, 2, 3, 4, 7, 8, 9, 10, 11, 13, 14, 16, 
    17, 19, 23, 24, 25, 26, 27, 28, 29, 30, 31, 
    32, 33, 34, 35, 36, 37, 38, 39, 40, 60, 61, 
    63, 64
]);

const weapon_schema = {
    "properties": {
        "steamid": { "type": "number" },
        "shareids": { 
            "type": "array",
            "items": {
                "type": "number"
            },
            "minItems": 1
        },
        "m_iItemDefinitionIndex": { "type": "number" },
        "m_nFallbackPaintKit": { "type": "number" },
        "m_flFallbackWear": { "type": "number" },
        "m_nFallbackStatTrak": { "type": "number" },
        "m_nFallbackSeed": { "type": "number" }
    },
    "required": [
        "steamid", 
        "shareids", 
        "m_iItemDefinitionIndex", 
        "m_nFallbackPaintKit", 
        "m_flFallbackWear", 
        "m_nFallbackStatTrak",
        "m_nFallbackSeed"
    ]
}

const ajv = new Ajv();
const weapon_validate = ajv.compile(weapon_schema);

const ws = new WebSocket.Server({ port: 8080 });
ws.on('connection', function connection(socket) {

    socket.on('close', function() {
        console.log("deleting socket from map");
        socket_map.delete(socket);
    });

    socket.on('message', function(data) {
        const jsondata = JSON.parse(data);



        if(weapon_validate(jsondata)) {
            
            if(!socket_map.has(socket)) {
                console.log("socket is not in map... adding it");
                socket_map.set(socket, { steamid: jsondata.steamid });
                console.log(socket_map.size);
            }

            if(EItemDefinitionIndex.has(jsondata.m_iItemDefinitionIndex)) {
                const jsondata_str = JSON.stringify({
                    "steamid": jsondata.steamid,
                    "m_iItemDefinitionIndex": jsondata.m_iItemDefinitionIndex,
                    "m_nFallbackPaintKit": jsondata.m_nFallbackPaintKit,
                    "m_flFallbackWear": jsondata.m_flFallbackWear,
                    "m_nFallbackStatTrak": jsondata.m_nFallbackStatTrak,
                    "m_nFallbackSeed": jsondata.m_nFallbackSeed,
                    "forceupdate": true
                });

                ws.clients.forEach(function(client) {
                    if(client.readyState === WebSocket.OPEN) {
                        jsondata.shareids.forEach(function(id) {
                            if(socket_map.has(client) && socket_map.get(client).steamid == id) {
                                console.log('socket steamid: ' + socket_map.get(client).steamid);
                                client.send(jsondata_str);
                            }
                        })
                    }
                });
            }
        }
    });
});