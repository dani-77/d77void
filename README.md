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

terminal 2)

```
sudo ./skel.sh
```

Happy hacking. 
