#!/bin/bash

PENDULUM_PI_BASE=$HOME/pendulum_pi

PENDULUM_RUNTIME_BASE=$PENDULUM_PI_BASE/active

PENDULUM_BIN_DIR=$PENDULUM_RUNTIME_BASE
PENDULUM_CFG_DIR=$PENDULUM_RUNTIME_BASE/config

PENDULUM_CFG_FILE=$PENDULUM_CFG_DIR/pendule_pi_config.yaml

COMMAND=pendulum
PID_FILE=/var/run/pigpio.pid

if [ ! -L $PENDULUM_RUNTIME_BASE ] ; then
  echo "ERROR: the active symbolic link pointing to the runtime configuration is not defined."
  echo ""
  echo "Refer to content of $PENDULUM_PI_BASE/NOTICE for detail. "
  exit 1
fi

pigpio_is_running() {
    test -f $PID_FILE && ps -p $(cat $PID_FILE) > /dev/null 2>&1
}


USAGE="Usage: $COMMAND start|stop|status|demo|reset|check|help"

show_help() {
    cat << EOF
$USAGE

start  : starts the hardware controller and run it in background. 
         *** MUST BE DONE BEFORE RUNNING THE DEMO ***
stop   : stops the controller
status : displays the current status of the controller
demo   : starts the demonstration application
reset  : resets the GPIO pins
check  : runs various checks on the hardware

EOF
}

show_current_profile() {
  echo "Current profile : $(readlink $PENDULUM_RUNTIME_BASE)"
}

switch_profile() {
  if [ -n "$1" ] ; then
    if [ -L $PENDULUM_RUNTIME_BASE ] ; then
        rm $PENDULUM_RUNTIME_BASE
    fi
    (cd $PENDULUM_PI_BASE && ln -s $1 active)
  else
    echo "ERROR: missing profile name"
  fi
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
        
        sudo $PENDULUM_BIN_DIR/low_level_interface "$PENDULUM_CFG_FILE" &
        ;;

    "stop")
        if pigpio_is_running ; then
            pid=$(cat $PID_FILE)
            echo "Stopping the low level controller (pid=$pid)..."
            sudo kill $pid

            # Wait for the process to terminate and check is current status
            sleep 0.5
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
            clear
            $PENDULUM_BIN_DIR/demo $PENDULUM_CFG_DIR/demo.yaml

            echo ""
            echo "Demo terminated. Use '$COMMAND stop' to stop the low level interface when done."
            echo ""
        else
            echo ""
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

    "check")
        case "$2" in
          "motor"|"m")
            sudo $PENDULUM_BIN_DIR/check_motor "$PENDULUM_CFG_FILE"
            ;;
          "encoders"|"e")
            sudo $PENDULUM_BIN_DIR/check_encoders "$PENDULUM_CFG_FILE"
            ;;
          "switches"|"s")
            sudo $PENDULUM_BIN_DIR/check_limit_switches "$PENDULUM_CFG_FILE"
            ;;
          "")
            echo "Usage: $COMMAND $1 motor|encoders|switches"
            ;;
          *)
            echo "ERROR: invalid check name"
            echo "Usage: $COMMAND $1 motor|encoders|switches"
        esac
        ;;

    "help"|"-h"|"--help")
        show_help
        ;;

# Internal use for development
    "profile")
        case "$2" in
          "dev"|"stable")
            switch_profile $2
            show_current_profile
            ;;
          "")
            show_current_profile
            ;;
          *)
            echo "ERROR: invalid profile name (valid: dev|stable)"
            ;;
        esac
        ;;

    *)
        echo "ERROR: $COMMAND used with a wrong or missing sub-command."
        echo $USAGE
        exit 2
        ;;
esac
