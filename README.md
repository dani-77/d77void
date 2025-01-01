# d77void repo is a iso generator for d77void-fluxbbox

To generate the d77void-live-fluxbox iso just run as root:

```
# ./build-x86-images.sh -b fluxbox -- -K -T d77void
```

Then, immediatly after rootfs generation is complete, run as root:

```
# ./skel.sh
```

This will create the iso with a ready to use Void based system with Fluxbox as windoww manager.

As in Void Linux, user is **anon** with password **voidlinux**.
