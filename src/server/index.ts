import { StartWebServer } from "./websocket.js";
import { GetLocation, IReturnData } from "./server_location.js";
import CheckUpdates from "./update.js";

CheckUpdates();
StartWebServer();
console.log("Server started on port 8080");
GetLocation(undefined).then((data: IReturnData) => {
    console.log("Server is currently located in " + data.country);
});