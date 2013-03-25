#!/usr/bin/env bash

SCREEN_NAME=xcp
SCREEN_LOGDIR=/tmp/screenlogs
LOGDAYS=1
SCREEN_HARDSTATUS='%{= .} %-Lw%{= .}%> %n%f %t*%{= .}%+Lw%< %-=%{g}(%{d}%H/%l%{g})'
DEST=/tmp

yum install -y screen

# VAR=$(trueorfalse default-value test-value)
function trueorfalse() {
    local default=$1
    local testval=$2

    [[ -z "$testval" ]] && { echo "$default"; return; }
    [[ "0 no false False FALSE" =~ "$testval" ]] && { echo "False"; return; }
    [[ "1 yes true True TRUE" =~ "$testval" ]] && { echo "True"; return; }
    echo "$default"
}

function screen_it { 
	SCREEN_NAME=${SCREEN_NAME:-xcp} 
	SERVICE_DIR=${SERVICE_DIR:-${DEST}/status} 
	SCREEN_DEV=`trueorfalse True $SCREEN_DEV` 
	 
	# Append the service to the screen rc file 
	screen_rc "$1" "$2" 

	screen -S $SCREEN_NAME -X screen -t $1 

	if [[ -n ${SCREEN_LOGDIR} ]]; then 
	    screen -S $SCREEN_NAME -p $1 -X logfile ${SCREEN_LOGDIR}/screen-${1}.${CURRENT_LOG_TIME}.log 
	    screen -S $SCREEN_NAME -p $1 -X log on 
	    ln -sf ${SCREEN_LOGDIR}/screen-${1}.${CURRENT_LOG_TIME}.log ${SCREEN_LOGDIR}/screen-${1}.log 
	fi 

	if [[ "$SCREEN_DEV" = "True" ]]; then 
	    # sleep to allow bash to be ready to be send the command - we are 
	    # creating a new window in screen and then sends characters, so if 
	    # bash isn't running by the time we send the command, nothing happens 
	    sleep 1.5 

	    NL=`echo -ne '\015'` 
	    screen -S $SCREEN_NAME -p $1 -X stuff "$2 || touch \"$SERVICE_DIR/$SCREEN_NAME/$1.failure\"$NL" 
	else 
	    screen -S $SCREEN_NAME -p $1 -X exec /bin/bash -c "$2 || touch \"$SERVICE_DIR/$SCREEN_NAME/$1.failure\"" 
	fi 
}

function screen_rc {
    SCREEN_NAME=${SCREEN_NAME:-stack}
    SCREENRC=$TOP_DIR/$SCREEN_NAME-screenrc
    if [[ ! -e $SCREENRC ]]; then
        # Name the screen session
        echo "sessionname $SCREEN_NAME" > $SCREENRC
        # Set a reasonable statusbar
        echo "hardstatus alwayslastline '$SCREEN_HARDSTATUS'" >> $SCREENRC
        echo "screen -t shell bash" >> $SCREENRC
    fi
    # If this service doesn't already exist in the screenrc file
    if ! grep $1 $SCREENRC 2>&1 > /dev/null; then
        NL=`echo -ne '\015'`
        echo "screen -t $1 bash" >> $SCREENRC
        echo "stuff \"$2$NL\"" >> $SCREENRC
    fi
}

# Helper to remove the *.failure files under $SERVICE_DIR/$SCREEN_NAME
# This is used for service_check when all the screen_it are called finished
# init_service_check
function init_service_check() {
    SCREEN_NAME=${SCREEN_NAME:-stack}
    SERVICE_DIR=${SERVICE_DIR:-${DEST}/status}

    if [[ ! -d "$SERVICE_DIR/$SCREEN_NAME" ]]; then
        mkdir -p "$SERVICE_DIR/$SCREEN_NAME"
    fi

    rm -f "$SERVICE_DIR/$SCREEN_NAME"/*.failure
}

# Helper to get the status of each running service
# service_check
function service_check() {
    local service
    local failures
    SCREEN_NAME=${SCREEN_NAME:-stack}
    SERVICE_DIR=${SERVICE_DIR:-${DEST}/status}


    if [[ ! -d "$SERVICE_DIR/$SCREEN_NAME" ]]; then
        echo "No service status directory found"
        return
    fi

    # Check if there is any falure flag file under $SERVICE_DIR/$SCREEN_NAME
    failures=`ls "$SERVICE_DIR/$SCREEN_NAME"/*.failure 2>/dev/null`

    for service in $failures; do
        service=`basename $service`
        service=${service::-8}
        echo "Error: Service $service is not running"
    done

    if [ -n "$failures" ]; then
        echo "More details about the above errors can be found with screen, with ./rejoin-stack.sh"
    fi
}



if screen -ls | egrep -q "[0-9].$SCREEN_NAME"; then
    echo "You are already running a run.sh session."
    echo "To rejoin this session type: screen -x $SCREEN_NAME."
    exit 1
fi

if [[ -n "$SCREEN_LOGDIR" ]]; then

    # We make sure the directory is created.
    if [[ -d "$SCREEN_LOGDIR" ]]; then
        # We cleanup the old logs
        find $SCREEN_LOGDIR -maxdepth 1 -name screen-\*.log -mtime +$LOGDAYS -exec rm {} \;
    else
        mkdir -p $SCREEN_LOGDIR
    fi
fi

screen -d -m -S $SCREEN_NAME -t shell -s /bin/bash
sleep 1
screen -r $SCREEN_NAME -X hardstatus alwayslastline "$SCREEN_HARDSTATUS"

init_service_check
