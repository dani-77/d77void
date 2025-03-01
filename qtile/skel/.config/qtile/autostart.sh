#!/usr/bin/env bash
wlsunset -t 3500 -T 5700 -l 41.6 -L -8.62 -g 0.8 &
xcompmgr -c -f -n &
redshift -l 41.6:-8.62 &
