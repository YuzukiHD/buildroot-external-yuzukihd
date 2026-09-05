#!/bin/sh
# SPDX-License-Identifier: GPL-2.0+
#
# Bring up the persistent overlay on YuzukiNeko:
#   - find the "overlay" MTD partition (last 1 MiB of the SPI NOR)
#   - (first use) erase it and let JFFS2 initialize on the erased flash
#   - mount JFFS2 and overlayfs the read-only squashfs root
#
# Resulting merged tree is mounted on /mnt/root; to make it the live root
# pivot_root(2) onto it (needs an init context that supports pivoting), or
# bind-mount individual directories as needed.
set -e

PART="overlay"

# /proc/mtd line:  mtd5: 00100000 00001000 "overlay"
mtd="$(sed -n 's/^mtd\([0-9]\+\):.*"'${PART}'".*/\1/p' /proc/mtd | head -n1)"
if [ -z "$mtd" ]; then
	echo "mount-overlayfs: no MTD partition named '$PART' in /proc/mtd" >&2
	exit 1
fi

# flash_erase needs the char device; JFFS2 is mounted by the partition name.
mtdchr="/dev/mtd$mtd"
mtdsrc="mtd:$PART"
mountpoint="/mnt/overlay"
upper="$mountpoint/upper"
work="$mountpoint/work"
merged="/mnt/root"

mkdir -p "$mountpoint" "$merged"

# First boot (or a partition that never got initialized): the flash reads
# erased (0xFF). Try to mount JFFS2; if that fails, erase and retry.
if ! mount -t jffs2 "$mtdsrc" "$mountpoint" 2>/dev/null; then
	echo "mount-overlayfs: formatting JFFS2 on $mtdchr ($PART, erased flash)"
	flash_erase "$mtdchr" 0 0 >/dev/null
	mount -t jffs2 "$mtdsrc" "$mountpoint"
fi

mkdir -p "$upper" "$work"

# Lower is the running read-only squashfs root. Overlay gives every file a
# writable copy-on-write copy in the JFFS2 upper dir.
mount -t overlay overlay \
-o "lowerdir=/,upperdir=$upper,workdir=$work" "$merged"

echo "mount-overlayfs: overlay ready at $merged (upper on $mtdsrc)"
