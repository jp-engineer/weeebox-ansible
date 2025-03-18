#!/bin/bash

# Set mount point and router backup directory
MOUNT_POINT="/mnt/router-backup"

# Use environment variable set by systemd or cron
USB_DEVICE="${USB_DEVICE:-USB_DEVICE_PLACEHOLDER}"

# Ensure the mount point exists
mkdir -p "$MOUNT_POINT"

# Mount the USB drive if not already mounted
if ! mount | grep -q "$MOUNT_POINT"; then
    mount "$USB_DEVICE" "$MOUNT_POINT"
    if [ $? -ne 0 ]; then
        echo "Failed to mount USB drive. Exiting."
        exit 1
    fi
fi

# Run OpenWRT backup via SSH and store it on the USB drive
BACKUP_FILE="$MOUNT_POINT/openwrt-$(date +%F).tar.gz"
sshpass -p "{{ router_admin_password }}" ssh root@router "sysupgrade -b -" > "$BACKUP_FILE"

# Verify backup was created
if [ -f "$BACKUP_FILE" ]; then
    echo "Backup successfully created: $BACKUP_FILE"
else
    echo "Backup failed. Exiting."
    exit 1
fi

# Cleanup old backups (keep last 4 weeks)
find "$MOUNT_POINT" -type f -mtime +28 -delete

echo " Old backups cleaned up. Process complete."

exit 0
