#!/bin/bash

screen /bin/bash -c 'octave --quiet --no-gui-libs scenario_script.m 2>&1 ~/scenario.log'
