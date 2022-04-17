import { StartWebServer } from "./websocket.js";
import { GetServerLocation, IReturnData } from "./server_location.js";

StartWebServer();
console.log("Server started on port 8080");
// Get country from ip
GetServerLocation().then((data: IReturnData) => {
    console.log("Server is currently located in " + data.country);
});