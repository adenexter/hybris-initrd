#!/bin/sh

# Simple script to generate inird rootfs for Sailfish OS running on Jolla Tablet
# NOTE: if you run this locally, please do it inside Scratchbox 2 target.

# Add your tools here. They need to be present in your sb2 target.
TOOL_LIST="res/images/* sbin/* /sbin/e2fsck /usr/sbin/lvm /usr/bin/yamui \
/sbin/resize2fs /sbin/mkfs.ext4 /sbin/factory-reset-lvm /sbin/find-mmc-bypartlabel"

RECOVERY_FILES="etc/udhcpd.conf etc/fstab usr/bin/* /usr/bin/txeireader"

if test x"$1" = x"recovery"; then
	TOOL_LIST="$TOOL_LIST $RECOVERY_FILES"
	DEF_INIT="recovery-init"
else
	# The default init script
	DEF_INIT="jolla-init"
fi

set -e

OLD_DIR=$(pwd)
TMP_DIR=/tmp/sfosinitrd

check_files()
{
	local FILES=$1
	for f in $FILES; do
		if test ! -e "$f"; then
			echo "File \"$f\" does not exist!"
			echo "Please install required RPM package or add \"$f\" manually"
			return 1
		fi
	done
	return 0
}

check_files "$TOOL_LIST" || exit 1

rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

# Copy local files to be added to initrd. If you add more, add also to TOOL_LIST.
cp -a "$OLD_DIR"/sbin .
cp -a "$OLD_DIR"/res .

# Copy recovery files
if test x"$1" = x"recovery"; then
	cp -a "$OLD_DIR"/usr/ "$OLD_DIR"/etc/ -t ./
fi

# Create the ramdisk
initialize-ramdisk.sh -w ./ -t "$TOOL_LIST" -i "$OLD_DIR"/"$DEF_INIT" || exit 1
moslo-build.sh -w ./ -v 2.0 || exit 1
cd "$OLD_DIR"
cp -a "$TMP_DIR"/rootfs.cpio.gz .

rm -rf "$TMP_DIR"
