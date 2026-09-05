YuzukiHD YuzukiNeko (Allwinner SUN252I-F101)
================================================

This defconfig is provided by the YuzukiHD Buildroot external tree
(buildroot-external-yuzukihd). Build it from the upstream buildroot tree,
pointing BR2_EXTERNAL at this directory:

    make BR2_EXTERNAL=/path/to/buildroot-external-yuzukihd \
        yuzukihd_yuzukineko_defconfig
    make

The resulting uncompressed initramfs is:

    output/images/rootfs.cpio

This configuration targets the F101 C907 CPU as rv32imafdc with the ilp32d
ABI. It provides a BusyBox root filesystem and a login prompt (getty) on the
board console UART1 / ttyS1 at 115200 baud. It intentionally builds no
kernel, firmware, or storage image; load rootfs.cpio as an initrd, or link
it into the board kernel as an initramfs.

The F101 kernel configuration must enable devtmpfs and mount it at boot. Use
the kernel command line console=ttyS1,115200.
