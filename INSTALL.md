# d77void iso generator

To use the repo properly, clone the void-mklive repo:

```
git clone https://github.com/void-linux/void-mklive
```

and copy the contents of this repo to void-mklive that you previously cloned.

terminal example)

```
sudo ./d77 -r /home/dani77/cereus-pkgs/hostdir/binpkgs/cereus-extra -b fluxbox -- -T d77void
```

## side note *dwm*

To use it properly, run this:

```
sudo ./d77 -b dwm -- -T d77void
```

## side note *hyprland*

To use it properly, run this:

```
sudo ./d777 -r /home/dani77/cereus-pkgs/hostdir/binpkgs/cereus-extra -r https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc -b hyprland -- -T d77void
```

instead of the usual mkiso/d77 command; it is needed to accept a new outside repo.

## side note *labwc*

To use it properly, run this:

```
sudo ./d777 -r /home/dani77/cereus-pkgs/hostdir/binpkgs/cereus-extra  -r /home/dani77/void-packages/hostdir/binpkgs/  -b labwc -- -T d77void
```

instead of the usual mkiso/d77 command; it is needed to accept a local repo or to remove labwc-menu-generator, labwc-tweaks-qt and sfwbar packages from the d77 labwc variant.

Happy hacking. 
