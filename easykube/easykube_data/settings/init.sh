#!/bin/bash
if [[ $USER != 'root' ]]; then
    if [[ ! -d "/home/$USER/.easykube/" ]]; then
        mkdir /home/$USER/.easykube/
    fi
    CONFIGFILE="/home/$USER/.easykube/config.json"
    CONNFILE="/home/$USER/.easykube/connections.json"
else
    if [[ ! -d " /root/.easykube/" ]]; then
        mkdir /root/.easykube/
    fi
    CONFIGFILE="/root/.easykube/config.json"
    CONNFILE="/root/.easykube/connections.json"
fi

if [[ ! -e $CONFIGFILE ]]; then
    touch $CONFIGFILE
    chmod 775 $CONFIGFILE
    echo '{"kubeconfig":"'$(kubectl config current-context)'"}' | jq > $CONFIGFILE
fi

if [[ ! -e $CONNFILE ]]; then
    touch $CONNFILE
    chmod 775 $CONNFILE
    echo '[]' | jq > $CONNFILE
fi