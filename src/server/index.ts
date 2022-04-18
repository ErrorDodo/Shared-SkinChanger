import { StartWebServer } from "./websocket.js";
import { GetLocation, IReturnData } from "./server_location.js";
import CheckUpdates from "./update.js";

// Run CheckUpdates() every 5 minutes and on startup.
setInterval(CheckUpdates, 1000 * 60 * 5);
CheckUpdates();
StartWebServer();
console.log("Server started on port 8080");
GetLocation(undefined).then((data: IReturnData) => {
    console.log("Server is currently located in " + data.country);
});