#!/bin/bash

cp -r greeny_dark tmp.*/image/rootfs/usr/share/slim/themes/
cp -r skel tmp.*/image/rootfs/etc/
cp slim.conf tmp.*/image/rootfs/etc/
cp rofi-power-menu tmp.*/image/rootfs/usr/bin/
cp 50-udisks.rules tmp.*/image/rootfs/usr/share/polkit-1/rules.d/
