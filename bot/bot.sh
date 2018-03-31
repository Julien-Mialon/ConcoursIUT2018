#!/bin/bash
#set -eux

declare -A mapArray
declare -A playerPositions
declare -A playerDirections
declare -A playerScores

function handleInit {
    echo "Handle init"
    json=$1
    idJoueur=$(echo $json | jq .idJoueur)
    
    echo $idJoueur
}

function handleMap {
    echo "Handle map"
    json=$1
    idJoueur=$(echo $json | jq .idJoueur)
    joueurs=$(echo $json | jq .joueurs)
    
    echo "id:" $idJoueur
    echo "joueurs:" $joueurs

    for mapJson in $(echo $json | jq -c ".map[]") ; do
        echo "line:" $mapJson

        point=$(echo $mapJson | jq .points)
        cassable=$(echo $mapJson | jq .cassable)
        posX=$(echo $mapJson | jq .pos[0])
        posY=$(echo $mapJson | jq .pos[1])

        type="none"
        if [ $point != "null" ] ; then
            type=$point
        fi
        if [ $cassable = "false" ] ; then
            type="B" #mur non cassable
        fi
        if [ $cassable = "true" ] ; then
            type="x" #mur cassable
        fi

        key=$(echo $posX"z"$posY)
        mapArray["$key"]=$type
    done

    for playerJson in $(echo $json | jq -c ".joueurs[]") ; do
        playerId=$(echo $playerJson | jq .id)
        playerX=$(echo $playerJson | jq .position[0])
        playerY=$(echo $playerJson | jq .position[1])
        playerDirectionX=$(echo $playerJson | jq .direction[0])
        playerDirectionY=$(echo $playerJson | jq .direction[1])
        playerScore=$(echo $playerJson | jq .score)

        playerPositions[$playerId]=$(echo $playerX";"$playerY)
        playerDirections[$playerId]=$(echo $playerDirectionX";"$playerDirectionY)
        playerScores[$playerId]=$playerScore

        key=$(echo $playerX"z"$playerY)
        mapArray[$key]=$playerId
    done

    for (( x=1; x<=100; x++ ))
    do
        for (( y=1; y<=100; y++ ))
        do
            key=$(echo $x"z"$y)
            value=$mapArray[$key]

            echo $value
        done
    done
}

function handleTurn {
    echo "Handle turn"
    json=$1
}

# $1 : line json $2 : enum (init, map, turn)
function run {
    json=$1
    
    if [ $2 = "init" ]; then
        handleInit "$json"
    fi
    
    if [ $2 = "map" ]; then
        handleMap "$json"
    fi
    
    if [ $2 = "turn" ]; then
        handleTurn "$json"    
    fi
}