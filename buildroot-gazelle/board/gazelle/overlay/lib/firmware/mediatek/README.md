# overlay/lib/firmware/mediatek/ — MT7961 Wi-Fi firmware (included)

The MT7921S driver `request_firmware()`s MediaTek MT7961 firmware at boot. These are the
**stock upstream `linux-firmware` blobs** (byte-identical to
`git.kernel.org/.../linux-firmware/mediatek/`), committed here so the image works out of
the box. They land at `/lib/firmware/mediatek/` in the rootfs, where the driver looks.

| file | role |
|------|------|
| `WIFI_RAM_CODE_MT7961_1.bin`         | WiFi RAM code (chip rev 1)   |
| `WIFI_RAM_CODE_MT7961_1a.bin`        | WiFi RAM code (chip rev 1a)  |
| `WIFI_MT7961_patch_mcu_1_2_hdr.bin`  | MCU ROM patch (rev 1)        |
| `WIFI_MT7961_patch_mcu_1a_2_hdr.bin` | MCU ROM patch (rev 1a)       |
| `TxPwrLimit_MT79x1.dat`              | TX power limit table         |
| `TxPwrLimit6G_MT79x1.dat`            | TX power limit table (6 GHz) |

Both chip revisions (`_1` and `_1a`) are included because the driver auto-selects by the
HW version it reads at probe.

## Provenance / license

Redistributable MediaTek firmware from **[linux-firmware]** (also present on the CoreELEC
image we harvest from), covered by `LICENCE.mediatek` there, which permits redistribution.

[linux-firmware]: https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/mediatek

```
sha256  WIFI_RAM_CODE_MT7961_1.bin          b94217a951518a9c14095765f367bc5dd7698f2dc033941d6f18fc2ebd6a2ab9
sha256  WIFI_RAM_CODE_MT7961_1a.bin         3edec74ffe341b917e7fa4ddb2b68851411f2416555f10619a5900fa4b141e6c
sha256  WIFI_MT7961_patch_mcu_1_2_hdr.bin   a276c06c2b772adb50b86639d33c82824ff4c21d617feb78caea74c040b873f6
sha256  WIFI_MT7961_patch_mcu_1a_2_hdr.bin  a766c4e39815e554c80ce5b1596095ff283a60db93356679fecd6494f71cee23
sha256  TxPwrLimit_MT79x1.dat               886bd480983c73089b6f9029844c0868177c6db45aa89ffea3b86dff12e3881e
sha256  TxPwrLimit6G_MT79x1.dat             680075dfed22f3df742a15874bce796540de9a1e2a64f8f0d493fad3698b0690
```

> Alternatively, drop these files and have Buildroot install them from upstream via
> `BR2_PACKAGE_LINUX_FIRMWARE` (MediaTek MT7921) — same blobs, fetched at build time.
>
> `cfg80211` logging `Direct firmware load for regulatory.db failed` is cosmetic: MT7921
> uses internal regulatory data (`country 00`); add a `regulatory.db` from `wireless-regdb`
> for a proper regdomain.
