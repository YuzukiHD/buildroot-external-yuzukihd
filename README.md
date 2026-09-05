# buildroot-external-yuzukihd

External tree for [Buildroot](https://buildroot.org) with custom packages
and board configurations for YuzukiHD boards.

All YuzukiHD board support and extra features live here **outside** the
upstream `buildroot` checkout, so the upstream tree stays pristine and can
be updated freely. `BR2_EXTERNAL` is the official Buildroot mechanism for
this; see the [Buildroot manual](https://buildroot.org/downloads/manual/manual.html#outside-br-custom).

## Layout

```
configs/    board defconfigs (make BR2_EXTERNAL=<this dir> <name>_defconfig)
board/      board support files: readme, rootfs overlays, post-build scripts
package/    custom packages (each in package/<name>/)
external.desc / Config.in / external.mk   BR2_EXTERNAL plumbing
```

## Boards

### YuzukiNeko (Allwinner SUN252I-F101, RV32)

- Defconfigs:
  - `configs/yuzukihd_yuzukineko_ramdisk_defconfig` — Buildroot internal musl
    toolchain; builds the dev initramfs (`rootfs.cpio`)
  - `configs/yuzukihd_yuzukineko_xuantie_ramdisk_defconfig` — prebuilt
    **Xuantie** musl32 toolchain (downloaded by Buildroot from the URL in
    the defconfig); builds the dev initramfs
  - `configs/yuzukihd_yuzukineko_nor_defconfig` — internal musl toolchain;
    builds the **NOR firmware** image
  - `configs/yuzukihd_yuzukineko_xuantie_nor_defconfig` — Xuantie toolchain;
    builds the **NOR firmware** image
- The NOR defconfigs build OpenSBI `fw_jump.bin` (`YuzukiHD/opensbi`,
  `sun252i-f101` branch, generic platform + `sun252i-f101` defconfig) and
  the Linux `Image`/dtb (`YuzukiHD/linux-mainline`, `sun252i_f101_7.2`,
  defconfig `sun252i_f101_yuzukineko`), then
  `board/yuzukihd/yuzukineko/scripts/post-image-nor.sh` assembles
  `images/yuzukineko-nor.img` (16 MiB). Board support files live under
  `board/yuzukihd/yuzukineko/{bin,scripts,overlay}` (binaries / packaging
  scripts / rootfs-overlay content merged into the rootfs).

  ```
  0x000000  bootloader    board/yuzukihd/yuzukineko/bin/spinor-boot_spi.bin
                          (SyterKit, 48 KiB, loaded by BROM)
  0x010000  device tree   sun252i-f101-yuzukineko.dtb   (reserved 256 KiB)
  0x050000  fw_jump.bin   OpenSBI fw_jump               (reserved 512 KiB)
  0x0d0000  Image         Linux kernel                  (6 MiB)
  0x6d0000  rootfs        rootfs.squashfs (actual size, up to 0xf00000)
  0xf00000  overlay       last 1 MiB, erased (0xFF) for a JFFS2 overlayfs
                          upper on the device
  ```
  This layout is mirrored as MTD fixed partitions in the kernel device tree
  (`sun252i-f101-yuzukineko.dts`, `flash@0/partitions`).
- Board dir: `board/yuzukihd/yuzukineko/` (see `readme.txt`)

## Adding a custom package

1. Create `package/<name>/Config.in` and `package/<name>/<name>.mk`.
2. Reference `Config.in` from the root `Config.in` of this tree.
3. Enable it in a defconfig.

## Building

```sh
make -C <path-to-upstream-buildroot> O=<build-dir> \
    BR2_EXTERNAL=/path/to/buildroot-external-yuzukihd \
    yuzukihd_yuzukineko_xuantie_ramdisk_defconfig
make -C <path-to-upstream-buildroot> O=<build-dir>
```
