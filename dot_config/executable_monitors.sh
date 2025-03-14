#!/bin/bash

# Monitor 1
xrandr --output DP-0 --mode 1920x1080 --rate 239.76 --primary

# Monitor 2
xrandr --output DP-2 --mode 2560x1440 --rate 59.95 --right-of DP-0
