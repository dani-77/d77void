#!/bin/bash

cp -r skel/ mklive-build.*/image/rootfs/etc/
cp -r slice/ mklive-build.*/image/rootfs/usr/share/sddm/themes/
cp 50-udisks.rules mklive-build.*/image/rootfs/usr/share/polkit-1/rules.d/
cp anon.face.icon mklive-build.*/image/rootfs/usr/share/sddm/faces
cp rofi-power-menu mklive-build.*/image/rootfs/usr/bin/
cp sddm.conf mklive-build.*/image/rootfs/etc/
cp splash.png mklive-build.*/image/rootfs/usr/share/void-artwork/
