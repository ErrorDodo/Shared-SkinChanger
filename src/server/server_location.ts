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
        console.log("Getting Server Location...")
        uri = "http://ip-api.com/json";
        const request = await (await fetch(uri, {method: "GET"})).json();
        return request as IReturnData;
    }
    else {
        console.log("Getting Client Location...");
        uri = `https://ipwhois.app/json/${ip}`;
        const request = await (await fetch(uri, {method: "GET"})).json();
        return request as IReturnData;
    }
}