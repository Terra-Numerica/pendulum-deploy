# Mobile pendulum #2 environment

## Content

This file tree contains the customized version of the system environment of the
RPi controlling the mobile pendulum.


## Stable/dev switching

In order for the binairies not to be tampered with by experiments, they have
been moved from the build tree of the development project to the
`$HOME/pendulum_pi` folder. This area contains the binairies and the
configuration files needed at runtime.

It is organized as follows :

    pendulum_pi/
    ├── active -> stable
    ├── dev
    │   ├── config
    │   │   ├── demo.yaml -> /home/pi/coding/pendule_pi/config/demo_fred.yaml
    │   │   └── pendule_pi_config.yaml -> /home/pi/coding/pendule_pi/pendule_pi_config.yaml
    │   ├── demo -> /home/pi/coding/pendule_pi/build/demo
    │   └── low_level_interface -> /home/pi/coding/pendule_pi/build/low_level_interface
    ├── pendulum.sh
    └── stable
        ├── config
        │   ├── demo.yaml
        │   └── pendule_pi_config.yaml
        ├── demo
        ├── low_level_interface
        └── reset_gpio

Switching the `active` symbolic link between `stable` and `dev` makes it 
possible to safely switch between the stable version and the dev one.


## `pendulum` command

For the `pendulum` command to be available on the RPi, create the following
symbolic link :

    $HOME/.local/bin/pendulum -> $HOME/pendulum_pi/pendulum.sh

