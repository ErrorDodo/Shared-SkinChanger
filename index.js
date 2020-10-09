const WebSocket = require('ws');
var sqlite3 = require('sqlite3').verbose();

const ws = new WebSocket.Server({ port: 8080 });
ws.on('connection', function connection(socket) {
    socket.on('message', function(data) {
        let splitdata = data.split('\n');
        let type = splitdata.shift();
        let json = splitdata.join('');
        let jsondata = JSON.parse(json);
        
        console.log(jsondata);
        console.log(socket);

        switch(type) {
            case 'update': {
                let jsondata_str = JSON.stringify({
                    "hostname": jsondata.hostname,
                    "steamid": jsondata.steamid,
                    "m_iItemDefinitionIndex": jsondata.m_iItemDefinitionIndex,
                    "m_iItemIDHigh": jsondata.m_iItemIDHigh,
                    "m_nFallbackPaintKit": jsondata.m_nFallbackPaintKit,
                    "m_flFallbackWear": jsondata.m_flFallbackWear,
                    "m_nFallbackStatTrak": jsondata.m_nFallbackStatTrak,
                    "m_nFallbackSeed": jsondata.m_nFallbackSeed,
                    "forceupdate": true
                });

                ws.clients.forEach(function(client) {
                    if (client !== socket && client.readyState === WebSocket.OPEN) {
                        client.send(jsondata_str);
                    }
                });

                break;
            }
            default: break;
        }
    });
});

