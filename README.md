# Shared-SkinChanger
A shared skin changer for skeet

This is no longer a proof of concept build.

It has progressed into a beta build.

You need to download node js on your vps

You can follow this tutorial https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-debian-10

Or just run these commands

sudo apt update

sudo apt install nodejs npm

Then download the index.js file and upload to vps then run these commands in the same folder as you put the index.js

npm i ws && npm i ajv

node index.js || To turn on the websocket

and that should make the websocket work

in the lua format the websocket ip like this ws://127.0.0.1:8080 so the format would be ws://ip:port


### Required luas/libraries:
- https://gamesense.pub/forums/viewtopic.php?id=23653
- https://gamesense.pub/forums/viewtopic.php?id=18807


### Bugs/Issues
- Like a 0.002% of crashing
- Constantly updates skins, could cause issues on local matches
- Still no knife skin changer
- Hud can get messed up on death (Fixes when respawned)
- If loaded while dead you will not receive updates


Project is going to be halted. Due to no sub and lua is a yuck language
