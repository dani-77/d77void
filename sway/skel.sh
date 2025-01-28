#!/bin/bash

cp -r greeny_dark/ mklive-build.*/image/rootfs/usr/share/slim/themes/
cp -r skel/ mklive-build.*/image/rootfs/etc/
cp 50-udisks.rules mklive-build.*/image/rootfs/usr/share/polkit-1/rules.d/
cp splash.png mklive-build.*/image/rootfs/usr/share/void-artwork/
cp st mklive-build.*/image/rootfs/usr/bin/
cp st-* mklive-build.*/image/rootfs/usr/share/terminfo/s/
