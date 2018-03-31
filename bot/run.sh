#!/bin/bash

source ./bot.sh

exec 3<>/dev/tcp/localhost/8889
echo -e '{"nickname": "Bash Binder"}' >&3

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
            exit ;;
    esac
done
#cat <&3