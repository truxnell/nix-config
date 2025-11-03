#!/usr/bin/env bash
# Cold HDD Backup Script
# Manual quarterly backup of critical data to external HDD
# Usage: sudo ./backup-to-external-hdd.sh /mnt/external-hdd

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <external-hdd-mount-point>"
    echo "Example: $0 /mnt/external-hdd"
    exit 1
fi

EXTERNAL_HDD="$1"
BACKUP_DATE=$(date +%Y-%m-%d)
BACKUP_ROOT="${EXTERNAL_HDD}/backups/${BACKUP_DATE}"

# Critical data directories to backup
CRITICAL_DATA=(
    "/zfs/photos/immich/"
    "/zfs/syncthing/"
    "/zfs/forgejo/"
)

# Check if external HDD is mounted and writable
if [ ! -d "$EXTERNAL_HDD" ] || [ ! -w "$EXTERNAL_HDD" ]; then
    echo "ERROR: External HDD not mounted or not writable at $EXTERNAL_HDD" >&2
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_ROOT"

echo "Starting cold HDD backup to $BACKUP_ROOT"
echo "Backup date: $BACKUP_DATE"
echo ""

# Backup each critical directory
for data_dir in "${CRITICAL_DATA[@]}"; do
    if [ ! -d "$data_dir" ]; then
        echo "WARNING: Directory $data_dir does not exist, skipping..." >&2
        continue
    fi

    dir_name=$(basename "$data_dir")
    echo "Backing up $data_dir to $BACKUP_ROOT/$dir_name..."
    
    # Use rsync with archive mode and progress
    rsync -avh --progress \
        --exclude='*.tmp' \
        --exclude='.DS_Store' \
        --exclude='Thumbs.db' \
        "$data_dir" "$BACKUP_ROOT/"
    
    echo "Completed: $dir_name"
    echo ""
done

# Create backup manifest
MANIFEST="${BACKUP_ROOT}/MANIFEST.txt"
{
    echo "Cold HDD Backup Manifest"
    echo "========================"
    echo "Date: $BACKUP_DATE"
    echo "Host: $(hostname)"
    echo "Backup location: $BACKUP_ROOT"
    echo ""
    echo "Directories backed up:"
    for data_dir in "${CRITICAL_DATA[@]}"; do
        if [ -d "$data_dir" ]; then
            echo "  - $data_dir ($(du -sh "$data_dir" | cut -f1))"
        fi
    done
    echo ""
    echo "Total backup size: $(du -sh "$BACKUP_ROOT" | cut -f1)"
    echo ""
    echo "Verification:"
    echo "  To verify backups, check directory structure and file counts."
    echo "  Example: find $BACKUP_ROOT -type f | wc -l"
} > "$MANIFEST"

echo "Backup completed successfully!"
echo "Manifest saved to: $MANIFEST"
echo ""
echo "Backup location: $BACKUP_ROOT"
echo "Total size: $(du -sh "$BACKUP_ROOT" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Verify backup integrity"
echo "  2. Store HDD in offsite location"
echo "  3. Update backup rotation schedule"

