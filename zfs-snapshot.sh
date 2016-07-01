#!/usr/bin/env bash

# Dependency: zfs
ZFS=${ZFS:-/sbin/zfs}
if ! [ -x "$ZFS" ]; then
    echo -e "Dependency not found: zfs" >&2
    exit 1
fi

# Arguments
filesystem=$1
snap_name=$2
snap_count=$3

# Usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 filesystem name count"
    echo ""
    echo "Arguments:"
    echo "  filesystem                       ZFS filesystem"
    echo "  name                             Snapshot base name (e.g., hourly)"
    echo "  count                            Number of snapshots to be kept"
    echo ""
    echo "Example cron jobs:"
    echo "  @hourly         $0 datapool/Temp hourly 24"
    echo "  @midnight       $0 datapool/Temp nightly 31"
    echo "  @monthly        $0 datapool/Temp monthly 12"
    echo "  0 0 * * 1       $0 datapool/Temp weekly 4"
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

# Check argument: name
if [ -z "$snap_name" ]; then
    echo -e "Missing argument: name" >&2
    exit 1
elif ! [[ "$snap_name" =~ ^[a-z_0-9]+$ ]]; then
    echo -e "Invalid name: $snap_name" >&2
    exit 1
fi

# Check argument: count
if [ -z "$snap_count" ]; then
    echo -e "Missing argument: count" >&2
    exit 1
elif ! [[ "$snap_count" =~ ^[0-9]+$ ]]; then
    echo -e "Invalid count: $snap_count" >&2
    exit 1
elif [ $snap_count -eq 0 ]; then
    echo -e "Invalid count: $snap_count" >&2
    exit 1
fi

# Check for additional argument
if ! [ -z "$4" ]; then
    echo -e "Too many arguments" >&2
    exit 1
fi

# Set nullglob (don't handle '${snap_name}.*')
shopt -s nullglob

# Index of last snapshot to be kept
snap_max=$(($snap_count - 1))

# List old snapshots
snap_names=()
for s in "${snap_root}/${snap_name}."*; do
    current_name="${s##*/}" # ${snap_name}.X
    current_suffix="${s##*.}" # X

    # Non-integer suffix
    if ! [[ "$current_suffix" =~ ^[0-9]+$ ]]; then
        # Ignore
        continue
    fi
    # Integer suffix

    # Delete oldest (or greater than max)
    # 25 should not be kept if max is 24 (25 would not be 25 units back)
    if [ $current_suffix -ge $snap_max ]; then
        # $current_suffix is not a valid index
        $ZFS destroy -r "${filesystem}@${snap_name}.${current_suffix}"
        if [ $? -ne 0 ]; then
            echo -e "Error: Deleting snapshot failed!" >&2
            echo -e "${filesystem}@${snap_name}.${current_suffix}" >&2
            exit 2
        fi
    else
        # $current_suffix is a valid index
        snap_names[$current_suffix]="$current_name"
    fi
done

# Move old snapshots
for ((i=$snap_max; i > 0; i--)); do
    new_index=$i
    ((old_index=new_index - 1))

    if [ -n "${snap_names[old_index]}" ]; then
        $ZFS rename -r \
            "${filesystem}@${snap_name}.${old_index}" \
            "${filesystem}@${snap_name}.${new_index}"
        if [ $? -ne 0 ]; then
            echo -e "Error: Renaming snapshot failed!" >&2
            echo -e "${filesystem}@${snap_name}.${old_index}" >&2
            exit 2
        fi
    fi
done

# Create snapshot
$ZFS snapshot -r "${filesystem}@${snap_name}.0"
if [ $? -ne 0 ]; then
    echo -e "Error: Creating snapshot failed!" >&2
    echo -e "${filesystem}@${snap_name}.0" >&2
    exit 2
fi

