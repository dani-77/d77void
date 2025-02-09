#!/bin/bash

cp -r greeny_dark/ mklive-build.*/image/rootfs/usr/share/slim/themes/
cp -r skel/ mklive-build.*/image/rootfs/etc/
cp slim.conf mklive-build.*/image/rootfs/etc/
cp rofi-power-menu mklive-build.*/image/rootfs/usr/bin/
cp 50-udisks.rules mklive-build.*/image/rootfs/usr/share/polkit-1/rules.d/
cp splash.png mklive-build.*/image/rootfs/usr/share/void-artwork/
cp wswap-X mklive-build.*/image/rootfs/usr/bin/