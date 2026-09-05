YuzukiHD YuzukiNeko (Allwinner SUN252I-F101)
================================================

This board is provided by the YuzukiHD Buildroot external tree
(buildroot-external-yuzukihd).

Two dev/ramdisk defconfigs build the initramfs used for bring-up/debug:

  yuzukihd_yuzukineko_ramdisk_defconfig          - Buildroot internal musl
                                                   toolchain
  yuzukihd_yuzukineko_xuantie_ramdisk_defconfig  - prebuilt Xuantie musl32
                                                   toolchain, downloaded by
                                                   Buildroot (see the
                                                   BR2_TOOLCHAIN_EXTERNAL_URL
                                                   in it)

The resulting uncompressed initramfs is output/images/rootfs.cpio.

Two NOR-firmware defconfigs additionally build OpenSBI fw_jump
(YuzukiHD/opensbi sun252i-f101), the Linux Image/dtb (YuzukiHD/linux-mainline
sun252i_f101_7.2) and a SquashFS (xz) rootfs, then assemble the flashable
16 MiB output/images/yuzukineko-nor.img:

  yuzukihd_yuzukineko_nor_defconfig             - Buildroot internal musl
                                                   toolchain
  yuzukihd_yuzukineko_xuantie_nor_defconfig     - Xuantie musl32 toolchain

NOR layout produced by board/yuzukihd/yuzukineko/post-image-nor.sh:
  0x000000 bootloader  spinor-boot_spi.bin  (SyterKit, 48 KiB)
  0x010000 device tree sun252i-f101-yuzukineko.dtb  (256 KiB)
  0x050000 fw_jump.bin OpenSBI fw_jump      (512 KiB)
  0x0d0000 Image       Linux kernel         (6 MiB)
  0x6d0000 rootfs      rootfs.squashfs      (to end)

Build (e.g. the Xuantie ramdisk dev image) from the upstream buildroot tree,
pointing BR2_EXTERNAL at this directory:

    make BR2_EXTERNAL=/path/to/buildroot-external-yuzukihd \
        yuzukihd_yuzukineko_xuantie_ramdisk_defconfig
    make

This configuration targets the F101 C907 CPU as rv32imafdc with the ilp32d
ABI. It provides a BusyBox root filesystem and a login prompt (getty) on the
board console UART1 / ttyS1 at 115200 baud. It intentionally builds no
kernel, firmware, or storage image; load rootfs.cpio as an initrd, or link
it into the board kernel as an initramfs.

The F101 kernel configuration must enable devtmpfs and mount it at boot. Use
the kernel command line console=ttyS1,115200.
