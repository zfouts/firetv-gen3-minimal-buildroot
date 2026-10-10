# inputs/ - gazelle device artifacts (included)

The build reuses the gazelle **vendor kernel + device tree + Amlogic boot script**. These
three files are **committed here** so the repo builds out of the box:

| file | what it is |
|------|------------|
| `kernel_Image`   | raw ARM64 `Image` (vendor 5.15.196 kernel), unpacked from CoreELEC's `kernel.img` |
| `dtb.img`        | gazelle device tree (`t7_pop1-g_amazon_3rd_gen_cube.dtb`) |
| `aml_autoscript` | Amlogic U-Boot autoscript (verbatim from CoreELEC) |

## Provenance / license

Harvested from a **CoreELEC Amlogic-no (CE-22)** gazelle image. These are GPL-2.0+
components; corresponding kernel source is published at
<https://github.com/CoreELEC/linux-amlogic> (branch `5.15.196_*`).

```
sha256  kernel_Image    65147c1ad7f9027d7490f99901b40a2c11d9c1ce17ca5aae0acd1064119ce76a
sha256  dtb.img         3ba34538e770169c95f220c36003ee23d4567cb7f7de9791e3fd6cce23628d1f
sha256  aml_autoscript  8d3f0bbf30a073d4d1b03aa1581065ab1cd62829df9b5a90ce537536ee9146b6
```

## Re-harvesting / updating (optional)

To refresh from a newer CoreELEC image: mount its FAT (`COREELEC`) partition, copy
`aml_autoscript` and `device_trees/t7_pop1-g_amazon_3rd_gen_cube.dtb` (→ `dtb.img`), and
unpack the kernel `Image` out of its `kernel.img`:

```bash
python3 boot-glue/unpackbootimg_v0.py kernel.img --out-kernel inputs/kernel_Image
```

> Wi-Fi (Amlogic W2) additionally needs proprietary modules + firmware harvested the same
> way - left out of this minimal image (Ethernet works with the in-kernel MAC).
