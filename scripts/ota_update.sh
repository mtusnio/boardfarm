#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 IMAGE_URL BOARD_IP"
    echo "IMAGE_URL - URL of the image the board will download"
    echo "BOARD_IP - IP of the board we want to update"
    exit 1
fi

URL=$1
IP=$2

VERIFICATION_FILE="/FILESYSTEM_NOT_FLASHED"
IMAGE_FILE="/tmp/openwrt.ubi"

sshpass -p 'root' ssh -o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null root@$IP \
"touch $VERIFICATION_FILE && wget $URL -O $IMAGE_FILE"

if [[ $? -ne 0 ]]; then
    echo "Failed to get image"
    exit 1
fi

UPDATE_SCRIPT="BOOT_PARTITION=\$(fw_printenv | grep '^boot_partition=[01]$' | tail -c 2) &&
if [ \$BOOT_PARTITION -eq 1 ]; then
    DEVICE_NAME='/dev/mtd4' &&
    FORMAT_PARTITION=0;
else
    DEVICE_NAME='/dev/mtd5' &&
    FORMAT_PARTITION=1;
fi &&
    ubiformat -f $IMAGE_FILE \$DEVICE_NAME && fw_setenv boot_partition \$FORMAT_PARTITION && reboot"

sshpass -p 'root' ssh -o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null -o ServerAliveInterval=3 \
-o ServerAliveCountMax=2 root@$IP $UPDATE_SCRIPT || exit 1
