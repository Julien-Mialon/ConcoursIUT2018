#!/bin/bash
#set -eux
#set -ux

declare -A mapArray
declare -A playerPositions
declare -A playerDirections
declare -A playerScores
declare -A projectilesPositions
declare -A projectilesDirections

declare -A mapFlower 

myProjectile=0
myIdPlayer=0

function handleInit {
    echo "Handle init"
    json=$1
    idJoueur=$(echo $json | jq .idJoueur)
    myIdPlayer=$idJoueur
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
        #echo "line:" $mapJson

        point=$(echo $mapJson | jq .points)
        cassable=$(echo $mapJson | jq .cassable)
        posX=$(echo $mapJson | jq .pos[0])
        posY=$(echo $mapJson | jq .pos[1])

        type="none"
        if [ $point != "null" ] ; then
            type="p" #bonus without point ($point)
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

        playerPositions[$playerId]=$(echo $playerX" "$playerY)
        playerDirections[$playerId]=$(echo $playerDirectionX" "$playerDirectionY)
        playerScores[$playerId]=$playerScore

        key=$(echo $playerX"z"$playerY)
        mapArray[$key]=$playerId
    done

}

function updatePlayerPosition {
    id=$1
    currentX=$2
    currentY=$3
    dirX=$4
    dirY=$5

    newX=$(($currentX + $dirX))
    newY=$(($currentY + $dirY))

    currentPosKey=$(echo $currentX"z"$currentY)
    mapArray[$currentPosKey]=""
    playerPositions[$id]=$(echo $newX $newY)
    newPosKey=$(echo $newX"z"$newY)
    mapArray[$newPosKey]=$id

    echo "Move to: " $newX $newY
}

function rotatePlayer {
    id=$1
    dirX=$2
    dirY=$3

    playerDirections[$id]=$(echo $dirX $dirY)
    echo "Rotate player: " $id " to " ${playerDirections[$id]}
}

function removeBonus {
    posX=$1
    posY=$2

    posKey=$(echo $posX"z"$posY)
    value=${mapArray[$posKey]}

    if [ $value = "p" ]; then
        mapArray[$posKey]=""
    fi

    echo "remove bonus: " $posX $posY
}

function newShoot {
    id=$1
    posX=$2
    posY=$3
    dirX=$4
    dirY=$5

    projectilesPositions[$id]=$(echo $posX $posY)
    projectilesDirections[$id]=$(echo $dirX $dirY)

    echo "new shoot: " $id $posX $posY $dirX $dirY
}

function respawnPlayer {
    id=$1
    currentX=$2
    currentY=$3
    newX=$4
    newY=$5

    currentPosKey=$(echo $currentX"z"$currentY)
    mapArray[$currentPosKey]=""
    playerPositions[$id]=$(echo $newX $newY)
    newPosKey=$(echo $newX"z"$newY)
    mapArray[$newPosKey]=$id

    echo "Respawn" $id " from: " $currentX $currentY "to: " $newX $newY
}

function moveShoot {
    id=$1
    posX=$2
    posY=$3

    projectilesPositions[$id]=$(echo $posX $posY)

    echo "move shoot: " $id $posX $posY
}

function explodeShoot {
    id=$1
    posX=$2
    posY=$3

    unset projectilesPositions[$id]

    echo "explode shoot: " $id $posX $posY
}

function removeWall {
    posX=$1
    posY=$2

    key=$(echo $posX"z"$posY)
    value=${mapArray[$key]}
    if [ $value = "x" ]; then
        echo "wall removed"
        mapArray[$key]=""
    fi

    echo "remove wall: " $posX $posY "(" $value ")"
}


function flowApplyOnCase {
    incX=$1
    incY=$2
    newX=$(($3 + $incX))
    newY=$(($4 + $incY))
    key=$(echo $newX"z"$newY)
    flowMapValue=${mapArray[$key]}
    mapFlower[$key]=$5

    if [ -z $flowMapValue ]; then
        flowArrayPositions[$writeIndex]=$newX
        flowArrayPositions[$writeNextIndex]=$newY

        writeIndex=$(($writeIndex + 1))
        writeNextIndex=$(($writeNextIndex + 1))

    elif [ $flowMapValue = "p" ]; then
        funResult_flowNow=$(echo $newX $newY)
    elif [ $flowMapValue = "x" ]; then
        flowArrayPositions[$writeIndex]=$newX
        flowArrayPositions[$writeNextIndex]=$newY

        writeIndex=$(($writeIndex + 1))
        writeNextIndex=$(($writeNextIndex + 1))
    fi
}

# $1 = x ; $2 = y
function flowBackTracking {
    posX=$1
    posY=$2

    key=$(echo $posX"z"$posY)
    curDepth=${mapFlower[$key]}
    echo "Pos0:" $posX $posY $curDepth
    while [ $curDepth -gt 1 ]
    do
        echo "Pos:" $posX $posY $curDepth
        nextDepth=$(($curDepth - 1))

        incX=0
        incY=1
        newX=$(($incX + $posX))
        newY=$(($incY + $posY))

        key=$(echo $newX"z"$newY)
        curDepth=${mapFlower[$key]}

        if [ -n "$curDepth" ]; then
            if [ $curDepth -eq $nextDepth ]; then
                posX=$newX
                posY=$newY

                continue
            fi
        fi

        incX=0
        incY=-1
        newX=$(($incX + $posX))
        newY=$(($incY + $posY))

        key=$(echo $newX"z"$newY)
        curDepth=${mapFlower[$key]}

        if [ -n "$curDepth" ]; then
            if [ $curDepth -eq $nextDepth ]; then
                posX=$newX
                posY=$newY

                continue
            fi
        fi

        incX=1
        incY=0
        newX=$(($incX + $posX))
        newY=$(($incY + $posY))

        key=$(echo $newX"z"$newY)
        curDepth=${mapFlower[$key]}

        if [ -n "$curDepth" ]; then
            if [ $curDepth -eq $nextDepth ]; then
                posX=$newX
                posY=$newY

                continue
            fi
        fi

        incX=-1
        incY=0
        newX=$(($incX + $posX))
        newY=$(($incY + $posY))

        key=$(echo $newX"z"$newY)
        curDepth=${mapFlower[$key]}

        if [ -n "$curDepth" ]; then
            if [ $curDepth -eq $nextDepth ]; then
                posX=$newX
                posY=$newY

                continue
            fi
        fi
    done

    if [ $curDepth -eq 1 ]; then
        funResult_flowBackTracking=$(echo $posX $posY)
        return 0
    fi
}

# $1 = x ; $2 = y
function flowNow {
    flowArrayPositions=($1 $2)
    index=0
    nextIndex=1
    writeIndex=2
    writeNextIndex=3
    flowerKey=$(echo $1"z"$2)
    mapFlower[$flowerKey]=0
    while true
    do
        posX=${flowArrayPositions[$index]}
        posY=${flowArrayPositions[$nextIndex]}
                
        if [ -z $posX ]; then
            break
        fi

        flowerKey=$(echo $posX"z"$posY)
        curDepth=${mapFlower[$flowerKey]}
        nextDepth=$(($curDepth + 1))

        if [ $nextDepth -gt 7 ]; then
            break
        fi
        
        flowApplyOnCase 1 0 $posX $posY $nextDepth
        echo "flownow #"$funResult_flowNow"#";
        if [ -n "$funResult_flowNow" ]; then
            break;
        fi
        flowApplyOnCase -1 0 $posX $posY $nextDepth
        if [ -n "$funResult_flowNow" ]; then
            break;
        fi
        flowApplyOnCase 0 1 $posX $posY $nextDepth
        if [ -n "$funResult_flowNow" ]; then
            break;
        fi
        flowApplyOnCase 0 -1 $posX $posY $nextDepth
        if [ -n "$funResult_flowNow" ]; then
            break;
        fi

        index=$(($index + 1))
        nextIndex=$(($nextIndex + 1))
    done

    if [ -n "$funResult_flowNow" ]; then
        flowBackTracking $funResult_flowNow

        if [ -n "$funResult_flowBackTracking" ]; then
            echo "Next position" $funResult_flowBackTracking
        fi
    fi
}

function findBestDirection {
    unset mapFlower
    funResult_flowNow=""
    declare -A mapFlower 
    depth=8
    flowNow ${playerPositions[$myIdPlayer]} 0 1 $depth

    if [ -n "$funResult_flowNow" ]; then
        echo "Find something: " $funResult_flowNow
    fi
}

#$1 = x ; $2 = y ; $3 = dirX ; $4 = dirY
function canMoveForward {
    newX=$(($1 + $3))
    newY=$(($2 + $4))

    currentPosKey=$(echo $newX"z"$newY)
    value=${mapArray[$currentPosKey]}
    echo "plop: #"$value"#"

    funResult_canMoveForward="false"
    funResult_shootFirst="false"
    if [ -z $value ]; then
        funResult_canMoveForward="true"
    elif [ $value = "p" ]; then
        funResult_canMoveForward="true"
    elif [ $value = "B" ]; then
        funResult_canMoveForward="false"
    else
        funResult_canMoveForward="true"
        funResult_shootFirst="true"
        #elif [ $value = "x" ]; then || value = player
    fi
}

function updateLine {
    #echo "line:arg1: #"$1"#"
    #echo "line:arg2: #"$2"#"
    case $1 in
        "\"joueur\"")
            case $2 in
                "\"move\"")
                    updatePlayerPosition $3 ${playerPositions[$3]} ${playerDirections[$3]} 
                    ;;
                "\"rotate\"")
                    rotatePlayer $3 $(echo $5 | cut -d"," -f1) $6
                    ;;
                "\"recupere_bonus\"")
                    removeBonus $(echo $5 | cut -d"," -f1) $6
                    ;;
                "\"shoot\"")
                    newShoot $4 $(echo $6 | cut -d"," -f1) $7 $(echo ${10} | cut -d"," -f1) ${11}
                    if [ $3 = $myIdPlayer ]; then
                        myProjectile=0
                    fi
                    ;;
                "\"respawn\"")
                    respawnPlayer $3 ${playerPositions[$3]} $(echo $5 | cut -d"," -f1) $6
                    ;;
            esac
            ;;
        "\"projectile\"")
            case $2 in
                "\"move\"")
                    moveShoot $3 $(echo $5 | cut -d"," -f1) $6
                    ;;
                "\"explode\"")
                    explodeShoot $3 $(echo $5 | cut -d"," -f1) $6
                    if [ $9 = "[" ]; then
                        removeWall $(echo ${10} | cut -d"," -f1) ${11}
                    fi
                    ;;
            esac
            ;;
        
    esac
}

function handleTurn {
    echo "Handle turn"
    json=$1

    echo $json

    for itemJson in $(echo $json | jq -c ".[]") ; do
        line=$(echo $itemJson | jq ".[]")
        updateLine $line
    done

    findBestDirection
    canMoveForward ${playerPositions[$myIdPlayer]} ${playerDirections[$myIdPlayer]}
    if [ $funResult_canMoveForward = "true" ]; then
        if [ $funResult_shootFirst = "true" ]; then
            RESULT_IA='["shoot", "move"]'
        else
            RESULT_IA='["move", "shoot"]'
        fi
    else
        if [ $funResult_shootFirst = "true" ]; then
            RESULT_IA='["shoot", "hrotate"]'
        else
            RESULT_IA='["hrotate", "shoot"]'
        fi
    fi
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