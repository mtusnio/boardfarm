#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 BOARD_IP"
    echo "BOARD_IP - IP of the board we want to verify"
    exit 1;
fi

IP=$1
VERIFICATION_FILE="/FILESYSTEM_NOT_FLASHED"

echo "Verifying if $IP was flashed..."
for i in {1..12}
do
    sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$IP \
       "if [ ! -f $VERIFICATION_FILE ]; then exit 0; fi; exit 1"
    RETURN=$?
    if [[ $RETURN -gt 1 ]]; then
       sleep 10
       continue
    elif [[ $RETURN -eq 0 ]]; then
       echo "Verification of $IP successful"
       exit 0
    fi
    echo "Failed to verify $IP, filesystem had not been flashed"
    exit 1
done
