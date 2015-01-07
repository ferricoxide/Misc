#!/bin/sh
#
# Note: This script is intended to be run on an EL6-based Linux 
#       system. In order for this script to work, the following
#       RPMs must be present:
#
#       * dosfstools
#       * genisoimage
#       * udftools
#       * ntfs-3g (optional: for future functionality)
#
################################################################


IMGROOT="/var/tmp/FSimage"
MNTROOT="/mnt/testing"
DDCMD="dd bs=1024 count=49152 if=/dev/urandom"

# Set up an MSDOS testable "media" mount
if [ -f ${IMGROOT}.msdos ]
then
   losetup /dev/loop0 ${IMGROOT}.msdos
else
   echo "Creating ${IMGROOT}.msdos"
   ${DDCMD} of=${IMGROOT}.msdos && echo "File-create succeeded"
   losetup /dev/loop0 ${IMGROOT}.msdos && echo "Loop setup succeeded"
   mkfs -t msdos /dev/loop0 && echo "Filesystem created"
fi
mount -t msdos /dev/loop0 ${MNTROOT}/msdos

# Set up an VFAT testable "media" mount
if [ -f ${IMGROOT}.vfat ]
then
   losetup /dev/loop1 ${IMGROOT}.vfat
else
   echo "Creating ${IMGROOT}.vfat"
   ${DDCMD} of=${IMGROOT}.vfat && echo "File-create succeeded"
   losetup /dev/loop1 ${IMGROOT}.vfat && echo "Loop setup succeeded"
   mkfs -t vfat /dev/loop1 && echo "Filesystem created"
fi
mount -t vfat /dev/loop1 ${MNTROOT}/vfat

# Set up an ISO9660 testable "media" mount
if [ -f ${IMGROOT}.iso9660 ]
then
   losetup /dev/loop2 ${IMGROOT}.iso9660
else
   echo "Creating ${IMGROOT}.iso9660"
   genisoimage -quiet -o ${IMGROOT}.iso9660 /etc > /dev/null 2>&1 && echo "File-create succeeded"
   losetup /dev/loop2 ${IMGROOT}.iso9660 && echo "Loop setup succeeded"
fi
mount -t iso9660 /dev/loop2 ${MNTROOT}/iso9660

# Set up an UDF testable "media" mount
if [ -f ${IMGROOT}.udf ]
then
   losetup /dev/loop3 ${IMGROOT}.udf
else
   echo "Creating ${IMGROOT}.udf"
   ${DDCMD} of=${IMGROOT}.udf && echo "File-create succeeded"
   losetup /dev/loop3 ${IMGROOT}.udf && echo "Loop setup succeeded"
   mkudffs /dev/loop3 > /dev/null 2>&1 && echo "Filesystem created"
fi
mount -t udf /dev/loop3 ${MNTROOT}/udf/
