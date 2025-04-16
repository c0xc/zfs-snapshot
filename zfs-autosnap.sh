#!/usr/bin/env bash

# zfs-autosnap for Linux
# Auto-create and rotate ZFS snapshots. Works just like zfs-snapshot.sh
# but creates named snapshots like Temp_snapshot_2020-01-01)
# instead of numbered snapshots (monthly.12).
# Named snapshots may be useful when creating backups:
# toctar create -C /datapool/Temp/.zfs/snapshot/ Temp_snapshot_2020-01-01
# This way, all files in the tape archive will be relative to .../snapshot/
# like Temp_snapshot_2020-01-01/file.
# 2020 - Philip <philip@c0xc.net>


# Dependency: zfs
ZFS=/sbin/zfs
ZFS=${ZFS:-/sbin/zfs}
if ! [ -x "$ZFS" ]; then
    echo -e "Dependency not found: zfs" >&2
    exit 1
fi

# Arguments
filesystem=$1
filesystem=${filesystem%/}
filesystem=${filesystem#/}
max_count=0
if [[ "$max_count" =~ ^[0-9]+$ ]]; then
    max_count=$2
fi

# Usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 filesystem count"
    echo ""
    echo "Arguments:"
    echo "  filesystem                       ZFS filesystem"
    echo "  count                            Number of snapshots to be kept"
    echo ""
    echo "This will create a snapshot named FS_snapshot_DATE,"
    echo "where FS is the basename of the given mountpoint and"
    echo "date is the current date in the form YYYY-MM-DD."
    echo "It is assumed that something or someone will clean up after ourselves."
    echo ""
    exit
fi

# Check argument: filesystem
snap_root="/$filesystem/.zfs/snapshot"
if [ -z "$filesystem" ]; then
    echo -e "Missing argument: filesystem" >&2
    exit 1
elif ! [ -d "/$filesystem" ]; then
    echo -e "ZFS filesystem not found: $filesystem" >&2
    exit 1
elif ! [ -d $snap_root ]; then
    echo -e "Not a ZFS filesystem: $filesystem" >&2
    exit 1
fi

# Snapshot name
# e.g., filesystem=datapool/Temp => name=Temp
name=$(basename "$filesystem")
if [[ -z "$name" ]]; then
    echo -e "Whoops, name is blank." >&2
    exit 1
fi
date=$(date +%F)
snap_prefix="${name}_snapshot_"
snap_name="${snap_prefix}${date}"

# List old snapshots
snap_names=()
while IFS= read -r -d '' subfile; do
    subfile="$(basename "$subfile")"
    # Skip those with other prefix
    if ! [[ "$subfile" == "$snap_prefix"* ]]; then
        continue
    fi
    # Skip those without date suffix
    if ! [[ "$subfile" =~ _[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        continue
    fi
    # Add to list
    snap_names+=("$subfile")
done < <(find "$snap_root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
old_snaps_count=${#snap_names[@]}

# Delete old snapshots if max_count defined (2nd arg)
if (( $max_count )); then
    # Determine how many snapshots to delete
    del_count=$((old_snaps_count - max_count + 1))
    # Delete old snapshots
    for ((i = 0; i < del_count; i++)); do
        name="${snap_names[$i]}"
        # "deleting: $name"
        echo "deleting old snapshot: $name"
        $ZFS destroy "${filesystem}@${name}"
        if [ $? -ne 0 ]; then
            echo -e "Error: Deleting snapshot failed!" >&2
            echo -e "${filesystem}@${name}" >&2
            exit 2
        fi
    done
fi

# Create snapshot like Temp_snapshot_2022-08-01
echo "creating snapshot: ${filesystem}@${snap_name}"
$ZFS snapshot "${filesystem}@${snap_name}"

