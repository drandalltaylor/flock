#/usr/bin/env bash
#set -x

function FlockLog() {
    local msg=$@
    logger -s -- "$msg"
}

function FlockLogFileUsers() {
    local LOCK_FILE=$1 
    pids=`fuser $LOCK_FILE`
    for pid in $pids; do
        pidinfo=`ps -o args="" -p $pid`
        if [ "$pidinfo" != "" ]; then
            FlockLog "$FUNCNAME: file:[$LOCK_FILE] cmd:[$pidinfo] pid:[$pid]"
        fi
    done
}

