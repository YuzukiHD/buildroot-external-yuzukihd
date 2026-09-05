#!/bin/sh
# SPDX-License-Identifier: GPL-2.0+
#
# Assemble the 16 MiB SPI NOR firmware image for YuzukiNeko.
#
# Region layout (fixed, matches the SyterKit spinor-boot reader):
#	0x000000  bootloader  spinor-boot_spi.bin   (<= 64 KiB, loaded by BROM)
#	0x010000  device tree sun252i-f101-yuzukineko.dtb (reserved 256 KiB)
#	0x050000  fw_jump     fw_jump.bin (OpenSBI, reserved 512 KiB)
#	0x0d0000  Image       arch/riscv/boot/Image (kernel, reserved 6 MiB)
#	0x6d0000  rootfs      rootfs.squashfs  (to end of flash)
#
# Called by Buildroot as a post-image script: $1 = images directory.
set -e

if [ "$#" -lt 1 ]; then
	echo "usage: post-image-nor.sh <images-dir>" >&2
	exit 1
fi

BINARIES_DIR="$1"
BOARD_DIR="$(dirname "$0")"

IMG="$BINARIES_DIR/yuzukineko-nor.img"
BOOT="$BOARD_DIR/spinor-boot_spi.bin"
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

# 16 MiB, zero-filled first so gaps between regions stay clean padding.
dd if=/dev/zero of="$IMG" bs=1M count=16 status=none

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

echo "post-image-nor.sh: wrote $IMG"
ls -l "$IMG"
