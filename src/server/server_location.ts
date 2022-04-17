import fetch from 'node-fetch';

export interface IReturnData{
    success: boolean,
    continent: string,
    country: string,
    country_code: string,
    country_capital: string,
}

export async function GetLocation(){
    const request = await (await fetch("https://ipwhois.app/json/", {method: "GET"})).json();
    return request as IReturnData;
}