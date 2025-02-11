# d77void iso generator

To use the repo properly, clone the void-mklive repo:

```
git clone https://github.com/void-linux/void-mklive
```

and copy the contents of this repo to void-mklive that you previously cloned.

Edit mkiso.sh with the contents of mkiso.md after lxqt variant, before *).

Copy the contents of one of the directories to main void-mklive repo directory, and then:

terminal 1 example)

```
sudo ./mkiso.sh -b fluxbox -- -K -T d77void
```

## side note *hyprland*

To use it properly, run this:

```
sudo ./mkiso.sh -r https://repo-de.voidlinux.org/current -r https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc -b hyprland -- -K -T d77void
```

instead of the usual mkiso command; it is needed to accept a new outside repo.

## side note *labwc*

To use it properly, run this:

```
sudo ./mkiso.sh -r /home/dani77/void-packages/hostdir/binpkgs/  -b labwc -- -K -T d77void
```

instead of the usual mkiso command; it is needed to accept a local repo.


terminal 2)

```
sudo ./skel.sh
```

Happy hacking. 
