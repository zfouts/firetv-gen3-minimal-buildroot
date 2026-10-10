# firetv-gen3-minimal-buildroot

A minimal **Buildroot** Linux image for the **Amazon Fire TV Cube 3rd gen** (codename
`gazelle`, model `AFTGAZL`, Amlogic **T7 POP1-G** / A311D2). BusyBox + OpenSSH (dropbear),
boots from USB, reachable over **Ethernet via SSH** - a clean, tiny base to build on.

> **Status:** verified booting on real hardware (kernel 5.15.196 aarch64, BusyBox 1.37.0,
> Buildroot 2026.02.3), SSH over Ethernet. RAM-only initramfs (nothing persists yet).
> Wi-Fi and a persistent rootfs are future work (see [Roadmap](#roadmap)).

## How it works

Buildroot builds only the **userland** (BusyBox + dropbear) as a compressed cpio
**initramfs**. The hard, device-specific parts - the kernel and the Amlogic boot chain -
are **reused from CoreELEC**, which is the one stack proven to boot this device:

```
unlocked U-Boot → aml_autoscript → cfgload → loads kernel.img + dtb.img → bootm
kernel.img = Android bootimg v0 = [ vendor 5.15.x Image ] + [ our Buildroot initramfs ]
  initramfs /init (BusyBox): mount devtmpfs → eth0 DHCP → dropbear → shell
```

We take CoreELEC's harvested `Image` + `dtb.img` + `aml_autoscript`, repack the `Image`
together with our initramfs into a new `kernel.img` (`boot-glue/mkbootimg_v0.py`, which
reproduces the stock bootimg byte-for-byte), and lay it on a FAT partition the Amlogic
bootrom will boot.

## Prerequisites

- A gazelle with an **unlocked bootloader** (FireOS <= PS7717; see the
  [XDA gazelle unlock thread](https://xdaforums.com/t/unlock-magisk-twrp-firetv-3nd-gen-cube-gazelle-ps7717.4800530/)).
- An **x86_64 Linux** build host (Buildroot is only supported there; a Docker container is fine).
- A USB stick, and `adb` to the Cube's FireOS to trigger USB boot.

The gazelle kernel/dtb/boot-script are **included** in [`inputs/`](inputs/README.md)
(CoreELEC/GPL - provenance + checksums there), so the repo builds out of the box.

## Build

```bash
# optional: bake in an SSH key for root (otherwise it's password auth, user "root")
export GAZELLE_SSH_PUBKEY="ssh-ed25519 AAAA... you@host"

./scripts/build.sh
# -> out/firetv-gen3-minimal.img
```

First build compiles a cross-toolchain (several minutes on a fast box). Re-runs are quick.

## Flash + boot

```bash
./scripts/flash.sh            # auto-detects a single USB (macOS or Linux); confirms first
# put the stick in the Cube, then from a machine with adb to FireOS:
adb connect <cube-fireos-ip>:5555
adb -s <cube-fireos-ip>:5555 shell reboot rescueparty   # = boot from USB
```

Give it ~60-90 s (kernel → BusyBox → `eth0` DHCP → dropbear). **The HDMI output stays on
the boot logo - this image is headless, so a blank/static screen is normal.** Find the
Cube's DHCP lease (hostname `gazelle`) and connect:

```bash
ssh root@<cube-ip>            # key auth if you set GAZELLE_SSH_PUBKEY; else password (default: gazelle)
```

## Auth

- **Password (default):** user `root`, password from `configs/gazelle_defconfig`
  (`BR2_TARGET_GENERIC_ROOT_PASSWD`, default `gazelle`). Change it for anything real.
- **SSH key:** set `GAZELLE_SSH_PUBKEY` before building; it's installed to
  `/root/.ssh/authorized_keys`. No keys are committed to this repo.

## Debugging without a serial cable

The initramfs writes `GAZL_BOOTLOG.txt` back onto the USB's FAT partition every ~15 s
(uname, cmdline, interfaces, dmesg). If it doesn't come up on the network, power off, pull
the USB, and read that file on another machine to see how far it got.

## Repo layout

```
buildroot-gazelle/   BR2_EXTERNAL tree: defconfig, /etc/inittab (devtmpfs fix), post-build (SSH key env)
boot-glue/           mkbootimg_v0.py (+ unpack), make-boot-image.sh, cfgload.txt
scripts/             build.sh (end-to-end), flash.sh
inputs/              harvested kernel_Image / dtb.img / aml_autoscript (you provide; git-ignored)
```

## Roadmap

- Persistent ext4 rootfs (`switch_root`) so changes/packages survive reboot
- eMMC install (boot without the USB)
- Optional Wi-Fi (Amlogic W2 - needs harvested proprietary modules + firmware)
- A larger userland / Debian-on-ext4 path toward a home server

## Credits

This project stands entirely on the work of others - it mostly just repackages their
gazelle bring-up into a minimal Buildroot image:

- **[CoreELEC](https://coreelec.org)** - the Amlogic-no (CE-22) vendor **kernel**, the
  **gazelle device tree** (`t7_pop1-g_amazon_3rd_gen_cube.dtb`), the initramfs boot chain
  we reverse-engineered, and `aml_autoscript`. None of this boots without their gazelle work.
  Kernel source: <https://github.com/CoreELEC/linux-amlogic>.
- **[LibreELEC](https://libreelec.tv)** - upstream of CoreELEC; the init/boot design.
- **[Buildroot](https://buildroot.org)** - the build system producing the rootfs.
- **The [XDA gazelle unlock thread](https://xdaforums.com/t/unlock-magisk-twrp-firetv-3nd-gen-cube-gazelle-ps7717.4800530/)**
  (Pro-me3us and contributors) - the bootloader unlock (CVE-2022-38181 / CVE-2022-46395)
  that makes booting anything custom on this device possible.
- **Amlogic** - the T7/A311D2 SoC and vendor kernel.

## License

**GPL-2.0-or-later** (see [LICENSE](LICENSE)). The bundled kernel/dtb/`aml_autoscript` in
`inputs/` are GPL-2.0+ from CoreELEC/LibreELEC (source linked above); the build scripts,
Buildroot config, and overlay in this repo are Copyright (C) 2026 the contributors and
licensed GPL-2.0-or-later. Fire TV, Amazon, and Amlogic are trademarks of their respective owners.
