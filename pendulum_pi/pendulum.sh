#!/bin/bash

PENDULUM_RUNTIME_BASE=$HOME/pendulum_pi/active

PENDULUM_BIN_DIR=$PENDULUM_RUNTIME_BASE
PENDULUM_CFG_DIR=$PENDULUM_RUNTIME_BASE/config

COMMAND=pendulum
PID_FILE=/var/run/pigpio.pid

pigpio_is_running() {
    test -f $PID_FILE && ps -p $(cat $PID_FILE) > /dev/null 2>&1
}


USAGE="Usage: $COMMAND start|stop|status|demo|reset|help"

show_help() {
    cat << EOF
$USAGE

start  : starts the hardware controller and run it in background. 
         *** MUST BE DONE BEFORE RUNNING THE DEMO ***
stop   : stops the controller
status : displays the current status of the controller
demo   : starts the demonstration application
reset  : resets the GPIO pins

EOF
}

case "$1" in
    "start")
        if pigpio_is_running ; then
            echo "Already started."
            exit 0
        fi

        echo "
        The low level controller is starting in background...

        Wait for the '--- Pendulum ready ---' message before starting the demo.

        In case of initialisation error, just launch the command again,
        after waiting for the pendulum to be still if this was the failure cause.
        "
        
        sudo $PENDULUM_BIN_DIR/low_level_interface $PENDULUM_CFG_DIR/pendule_pi_config.yaml &
        ;;

    "stop")
        if pigpio_is_running ; then
            pid=$(cat $PID_FILE)
            echo "Stopping the low level controller (pid=$pid)..."
            sudo kill $pid

            # Wait for the process to terminate
            while pigpio_is_running ; do
                sleep 0.1
            done
            echo "Stop completed."

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
            echo "Use '$COMMAND stop' to stop the low level interface when done."
            echo ""
        else
            echo "ERROR: Demonstration cannot be started because the hardware controller is not running."
            echo "Use the command '$COMMAND start' to start it."
            exit 1
        fi
        ;;

    "reset")
        if pigpio_is_running ; then
            echo "ERROR: GPIO pins cannot be reset because the hardware controller is running."
            echo "Use the command '$COMMAND stop' to stop it."
            exit 1
        else
            echo "Resetting GPIO pins..."
            sudo $PENDULUM_BIN_DIR/reset_gpio && echo "Done." || echo "ERROR: GPIO pins reset failed (rc=$?)."
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
