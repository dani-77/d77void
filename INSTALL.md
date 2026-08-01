# d77void iso generator

> [!NOTE]
> This project is **not affiliated with or endorsed by the Void Linux project** or its maintainers.
>
> Use at your own discretion.

## Overview

This repository provides:

- **scripts and skels to build d77void ISOs**

- **d77 and musl-d77 will be used to build with Calamares**

- **d77nc and musl-d77nc will be used to build without Calamares**

If you want to build with Calamares, you should fork d77void/srcpkgs-d77 too and build calamares or 
add the repository to your custom repositories like this:

```
x86_64

sudo touch /etc/xbps.d/d77void.conf
su
echo repository=https://sourceforge.net/projects/d77void/files/d77void-repo >> /etc/xbps.d/d77void.conf
```

```
x86_64-musl

sudo touch /etc/xbps.d/d77void.conf
su
echo repository=https://sourceforge.net/projects/d77void/files/d77void-musl >> /etc/xbps.d/d77void.conf
```

Now update the system and you will be able to use d77void srcpkgs repository.

<hr>

## Building

<details>
<summary><b> building with calamares </b></summary>


```
sudo ./d77 -r https://sourceforge.net/projects/d77void/files/d77void-repo -b wmd77 -- -T d77void
```
As you can see, the d77 script builds and has the same options as mkiso.sh.

It is though heavily modified to include the skel of the desired variant and a few more things.

Audit the script and adapt it to your need and desire.

</details>

<details>
<summary><b> building without calamares </b></summary>


```
sudo ./d77nc -r https://raw.githubusercontent.com/Event-Horizon-VL/blackhole-vl/repository-x86_64 -b hyprland -- -T d77void
```
As you can see, the d77nc script builds and has the same options as mkiso.sh.

It is though heavily modified to include the skel of the desired variant and a few more things.

Audit the script and adapt it to your need and desire.

</details>

<hr>

## Credits

- [Nizarjh: blackhole-vl](https://github.com/Event-Horizon-VL/blackhole-vl): Inspiration on README file

