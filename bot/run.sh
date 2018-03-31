#!/usr/bin/env bash

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
echo -e '{"nickname": "BashBinder"}' >&3

currentType="init"

while true;
do 
    line=$(head -n1 <&3)
    run "$line" $currentType

    case $currentType in
        init)
            currentType="map" ;;
        map)
            currentType="turn" ;;
        turn)
            #echo "result:" $RESULT_IA
            echo -e $RESULT_IA >&3
            ;;
    esac
done
