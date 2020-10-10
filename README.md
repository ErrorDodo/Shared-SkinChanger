# Shared-SkinChanger
A shared skin changer for skeet


This is only a proof of concept build.

It could be written better but this was done at 2am because bordem had struck.



You need to download node js on your vps

You can follow this tutorial https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-debian-10

Or just run these commands

sudo apt update

sudo apt install nodejs npm

Then download the index.js fileand upload to vps then run these commands in the same folder as you put the index.js

npm i ws && npm i sqlite3

and that should make the websocket work

in the lua format the websocket ip like this ws://192.168.0.1:8080 so the format would be ws://ip:port


### Required luas/libraries:
- https://gamesense.pub/forums/viewtopic.php?id=23653
- https://gamesense.pub/forums/viewtopic.php?id=23490
