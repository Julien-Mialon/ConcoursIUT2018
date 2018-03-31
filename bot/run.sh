#!/bin/bash

# Arguments parting
usage="run.sh [host] [port]"
case "$#" in
    0)
        host='localhost'
        port='8889'
        ;;
    1)
        host="$1"
        port='8889'
        ;;
    2)
        host="$1"
        port="$2"
        ;;
esac
echo "host=${host}"
echo "port=${port}"

# Bot
source ./bot.sh

exec 3<>/dev/tcp/${host}/${port}
echo -e '{"nickname": "Bash Binder"}' >&3

currentType="init"

while true;
do 
    line=$(head -n1 <&3)
    echo $(time run "$line" $currentType)

    case $currentType in
        init)
            currentType="map" ;;
        map)
            currentType="turn" ;;
        turn)
            exit ;;
    esac
done
