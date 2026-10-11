# overlay/lib/modules/ — Wi-Fi driver modules (included)

The gazelle's Wi-Fi is a **MediaTek MT7921S** (SDIO `037a:7901`), driven by the mainline
`mt76` / `mac80211` stack. Because this repo reuses the device's **prebuilt** vendor
kernel (it doesn't compile one), these modules can't come from Buildroot — they're the
**prebuilt `.ko` for kernel 5.15.196** (`modversions`), committed here so Wi-Fi works out
of the box. They are copied into the rootfs at `/lib/modules/` and loaded, in dependency
order, by `../../etc/init.d/S30wifi`.

Load order: `cfg80211 → libarc4 → mac80211 → mt76 → mt76-connac-lib → mt76-sdio →
mt7921-common → mt7921s` (`mt76` is a mac80211 softmac driver, so `mac80211` is required).

## Provenance / license

Harvested from a **CoreELEC Amlogic-no (CE-22)** gazelle image
(`/usr/lib/kernel-overlays/base/lib/modules/5.15.196/`), the same source as `inputs/`.
These are Linux kernel modules: `mt76`/`mt7921s` are **Dual BSD/GPL**, `mac80211`/
`cfg80211` are **GPL-2.0** — corresponding source is CoreELEC's
<https://github.com/CoreELEC/linux-amlogic> (branch `5.15.196_*`).

```
sha256  cfg80211.ko          e21f049326f78bc73788b96e433531fe7b4fefa64c72915506f28c54e93098f7
sha256  libarc4.ko           d6cff23a769950619c1376b0fa24ae79e7f42a1c505c82cce212f2aa6a46021a
sha256  mac80211.ko          c4b28ca9655ba1b2c222d6742900f2a10ea929023523401fc7291fef06a137b4
sha256  mt76.ko              955382bc7ffac9dd26e77ec857e0b85fd3de4e5d42f9f5db5c5b970dec624c0d
sha256  mt76-connac-lib.ko   ab56952e2c16fa08bf9f5804509d1c4bce0a033228870030d05f088573a51d69
sha256  mt76-sdio.ko         bffe0d558f683053f31517434d54944a9256be424e577ec91d32be1042eaa4e7
sha256  mt7921-common.ko     eb1ab47761e689e57be960fa2615b3b14c2dc0eb2c39ebf9b4fc8620b6120baa
sha256  mt7921s.ko           c96acb16f730e702e74d72c7cd39415fd4eebe0ef335b3e5e60fbf0e6dbb3609
```

## Re-harvesting / updating (optional)

To refresh from a newer CoreELEC image, copy the 8 files from
`/usr/lib/kernel-overlays/base/lib/modules/<kver>/` (flattened here):
`kernel/net/wireless/cfg80211.ko`, `kernel/lib/crypto/libarc4.ko`,
`kernel/net/mac80211/mac80211.ko`, and `mt76/{mt76,mt76-connac-lib,mt76-sdio,mt7921-common,mt7921s}.ko`.
Make sure their `vermagic` matches the kernel in `inputs/kernel_Image`:

```bash
modinfo -F vermagic mt7921s.ko   # expect: 5.15.196 SMP preempt ... modversions aarch64
```

Firmware lives in `../firmware/mediatek/`.
