#!/bin/bash

PENDULUM_RUNTIME_BASE=$HOME/pendulum_pi/active

PENDULUM_BIN_DIR=$PENDULUM_RUNTIME_BASE
PENDULUM_CFG_DIR=$PENDULUM_RUNTIME_BASE/config

COMMAND=pendulum

pigpio_is_running() {
    test -f /var/run/pigpio.pid 
}


USAGE="Usage: $COMMAND start|stop|status|demo|help"

show_help() {
    cat << EOF
$USAGE

start  : starts the hardware controller and run it in background. 
         *** MUST BE DONE BEFORE RUNNING THE DEMO ***
stop   : stops the controller
status : displays the current status of the controller
    
demo   : starts the demonstration application

EOF
}

case "$1" in
    "start")
        if pigpio_is_running ; then
            echo "Already started."
            exit 0
        fi

        echo ""
        echo "The hardware controller is starting in background..."
        echo ""
        echo "Wait for the '--- Pendulum ready ---' message before starting the demo"
        echo "with command : $COMMAND demo"
        echo ""
        echo "In case of initialisation error, just launch the command again."
        echo ""
        sudo $PENDULUM_BIN_DIR/low_level_interface $PENDULUM_CFG_DIR/pendule_pi_config.yaml &
        ;;

    "stop")
        if pigpio_is_running ; then
            pid=$(cat /var/run/pigpio.pid)
            echo "Stopping the hardware controller (pid=$pid)..."
            sudo kill $pid
        else
            echo "not running"
        fi
        ;;

    "status")
	if pigpio_is_running; then
	    echo "running"
	else
	    echo "stopped"
	fi
        ;;

    "demo")
        if pigpio_is_running ; then
            $PENDULUM_BIN_DIR/demo $PENDULUM_CFG_DIR/demo.yaml
            echo ""
            echo "Demo terminated."
            echo ""
            echo "Use '$COMMAND stop' to stop the low level interface if needed."
            echo ""
        else
            echo "ERROR: Demonstration cannot be started because the hardware controller is not running."
            echo "Use the command '$COMMAND start' to start it."
            exit 1
        fi
        ;;

    "help"|"-h"|"--help")
        show_help
        ;;

    *)
        echo "Invalid command."
        echo $USAGE
        exit 2
        ;;
esac
