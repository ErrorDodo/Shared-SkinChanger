import WebSocket, { WebSocketServer } from 'ws'
import Ajv from 'ajv';
import { GetLocation, IReturnData } from './server_location.js';

let socket_map = new Map();

interface IUserdata {
    steamid: number,
    shareids: number[],
    m_iItemDefinitionIndex: number,
    m_nFallbackPaintKit: number,
    m_flFallbackWear: number,
    m_nFallbackStatTrak: number,
    m_nFallbackSeed: number,
}

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

const ajv = new Ajv({ allErrors: true });
const weapon_validation = ajv.compile(weapon_schema);

export function StartWebServer() {
    const ws = new WebSocketServer({ port: 8080 });
    ws.on('connection', (socket: WebSocket, rq) => {
        GetLocation(rq.socket.remoteAddress).then((data: IReturnData) => {
            console.log("New Connection from:  " + data.country);
        });

        socket.on('close', function() {
            console.log("Removing socket from map");
            socket_map.delete(socket);
        });

        socket.on('message', function(data: string) {
            const jsondata: IUserdata = JSON.parse(data);
    
            if(!weapon_validation(jsondata)) {
                socket.close();
            }
    
            if(weapon_validation(jsondata)) {
                if(!socket_map.has(socket)) {
                    console.log("socket is no in map");
                    socket_map.set(socket, {steamid: jsondata.steamid})
                };
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
                            jsondata.shareids.forEach(function(id: any) {
                                if(socket_map.has(client) && socket_map.get(client).steamid == id) {
                                    client.send(jsondata_str);
                                }
                            })
                        }
                    });
                };
            };
        });
    });
};
