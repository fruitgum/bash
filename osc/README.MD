## OSC - Organainzer of SSH Connections
It's may be useful when you need to be connect to а many remote servers by SSH, but u too lazy for editing ssh connection file :)
This "app" keeps in itself parametrs of connection to a remote server, except password, e.g. ip, port (and username in future). It also have a default settings, e.g. username and SSH default port.

## Requirements

`jq` - Linux JSON Parcer

## Installation:
Copy osc to /usr/local/bin
`sudo cp osc  /usr/local/bin`

Make it executeable
`sudo chmod +x /usr/local/bin/osc`

At first run osc creates an empty config.json, witch will be contain information about servers, and also defaults.json, witch will be contain default values, witch you may specify now or later

**All about usage you may find out by executing** `osc -h`
