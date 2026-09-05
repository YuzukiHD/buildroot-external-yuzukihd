#!/bin/sh
# SPDX-License-Identifier: GPL-2.0+
#
# Assemble the 16 MiB SPI NOR firmware image for YuzukiNeko.
#
# Region layout (fixed, mirrors the kernel MTD partition table in
# sun252i-f101-yuzukineko.dts and the SyterKit spinor-boot reader):
#	0x000000  bootloader  spinor-boot_spi.bin   (<= 64 KiB, loaded by BROM)
#	0x010000  device tree sun252i-f101-yuzukineko.dtb (256 KiB)
#	0x050000  fw_jump     fw_jump.bin (OpenSBI, 512 KiB)
#	0x0d0000  Image       arch/riscv/boot/Image (kernel, 6 MiB)
#	0x6d0000  rootfs      rootfs.squashfs (written at its real size;
#	                      must fit in the 0x6d0000..0xf00000 region)
#	0xf00000  overlay     last 1 MiB, erased (0xFF), for a JFFS2 overlayfs
#	                      upper on the device
#
# Called by Buildroot as a post-image script: $1 = images directory.
set -e

if [ "$#" -lt 1 ]; then
	echo "usage: post-image-nor.sh <images-dir>" >&2
	exit 1
fi

BINARIES_DIR="$1"
BOARD_DIR="$(dirname "$0")/.."

IMG="$BINARIES_DIR/yuzukineko-nor.img"
BOOT="$BOARD_DIR/bin/spinor-boot_spi.bin"
DTB="$BINARIES_DIR/sun252i-f101-yuzukineko.dtb"
FW="$BINARIES_DIR/fw_jump.bin"
IMAGE="$BINARIES_DIR/Image"
ROOTFS="$BINARIES_DIR/rootfs.squashfs"

for f in "$BOOT" "$DTB" "$FW" "$IMAGE" "$ROOTFS"; do
	if [ ! -f "$f" ]; then
		echo "post-image-nor.sh: missing input: $f" >&2
		exit 1
	fi
done

# The last 1 MiB is reserved for the overlayfs (JFFS2) partition; the
# SquashFS rootfs must fit entirely in 0x6d0000..0xf00000.
OVERLAY_OFF=$((0xf00000))
OVERLAY_SIZE=$((0x1000000 - OVERLAY_OFF))   # 1 MiB
ROOTFS_END=$((OVERLAY_OFF))

# 16 MiB image, pre-filled with 0xFF (blank NOR) so gaps and the reserved
# overlay partition stay erased for JFFS2.
dd if=/dev/zero bs=1M count=16 status=none | tr '\000' '\377' >"$IMG"

# write_at <offset-hex> <file>: offset must be a multiple of 1 KiB.
write_at() {
	off="$1"
	file="$2"
	dd if="$file" of="$IMG" bs=1K seek=$((off / 1024)) conv=notrunc status=none
}

write_at 0x000000 "$BOOT"
write_at 0x010000 "$DTB"
write_at 0x050000 "$FW"
write_at 0x0d0000 "$IMAGE"
write_at 0x6d0000 "$ROOTFS"

# ---- report ----

kib() { # bytes -> KiB (rounded up)
	echo "$(((($1) + 1023) / 1024))"
}

rootfs_size=$(wc -c <"$ROOTFS")
if [ $((0x6d0000 + rootfs_size)) -gt "$ROOTFS_END" ]; then
	echo "post-image-nor.sh: rootfs ($rootfs_size B) overflows into overlay @ 0x$(printf '%x' "$OVERLAY_OFF")" >&2
	exit 1
fi

row() {
	printf '  %-10s  %-9s  %9s  %-7s  %s\n' "$1" "$2" "$3" "$4" "$5"
}

echo "== $IMG : 16 MiB SPI NOR image =="
row REGION OFFSET SIZE LIMIT CONTENT
row bootloader 0x000000 "$(kib "$(wc -c <"$BOOT")") KiB" "<64K" "bin/spinor-boot_spi.bin"
row dtb        0x010000 "$(kib "$(wc -c <"$DTB")") KiB" "<256K" "$(basename "$DTB")"
row fw_jump    0x050000 "$(kib "$(wc -c <"$FW")") KiB" "<512K" "$(basename "$FW")"
row Image      0x0d0000 "$(kib "$(wc -c <"$IMAGE")") KiB" "<6M" "$(basename "$IMAGE")"
row rootfs     0x6d0000 "$(kib "$rootfs_size") KiB" "<8.2M" "$(basename "$ROOTFS")"
row overlay    0xf00000 "$((OVERLAY_SIZE / 1024)) KiB" "=1M" "erased; JFFS2 overlayfs upper"
echo "== done: $IMG ($(kib "$(wc -c <"$IMG")") KiB on disk) =="
