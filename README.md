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
  - NOR-firmware defconfigs (`yuzukihd_yuzukineko_*_nor_defconfig`) are
    added alongside once the flash layout (offsets / fixed bootloader bin)
    is defined
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
