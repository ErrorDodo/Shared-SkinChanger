// Figure out where the clients connection is coming from and send them to the closest server.
//
// Language: typescript
// Path: src\server\server_location.ts

import fetch from 'node-fetch';

export interface IReturnData{
    success: boolean,
    continent: string,
    country: string,
    country_code: string,
    country_capital: string,
}


export async function GetLocation(ip: any){
    let uri = "";
    if(ip === undefined) {
        uri = "http://ip-api.com/json";
    }
    else {
        uri = `http://ip-api.com/json/${ip}`;
    }
    const request = await (await fetch(uri, {method: "GET"})).json();
    return request as IReturnData;
}