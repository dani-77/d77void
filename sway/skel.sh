#!/bin/bash

cp -r skel/ mklive-build.*/image/rootfs/etc/
cp 50-udisks.rules mklive-build.*/image/rootfs/usr/share/polkit-1/rules.d/
cp anon.face.icon mklive-build.*/image/rootfs/usr/share/sddm/faces
cp rofi-power-menu mklive-build.*/image/rootfs/usr/bin/
cp splash.png mklive-build.*/image/rootfs/usr/share/void-artwork/
cp st mklive-build.*/image/rootfs/usr/bin/
cp st-* mklive-build.*/image/rootfs/usr/share/terminfo/s/
