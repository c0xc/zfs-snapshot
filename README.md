zfs-snapshot
============

A simple snapshot rotation script for ZFS filesystems.

Unlike some example scripts found online, this one handles errors
and does not continue when a command has failed.



Usage
-----

Create and rotate up to count snapshots, where filesystem is the ZFS filesystem
and name is the name of the snapshot (cycle, e.g., "hourly"):

    # zfs-snapshot filesystem name count

A filesystem snapshot with the specified base name will be created.
Typical snapshot base names are "hourly", "nightly", "weekly" or "monthly".
Not more than *count* snapshots are kept,
additional snapshots of this filesystem are deleted.

Example cron jobs:

    @hourly         /root/bin/zfs-snapshot datapool/Temp hourly 24
    @midnight       /root/bin/zfs-snapshot datapool/Temp nightly 31
    @monthly        /root/bin/zfs-snapshot datapool/Temp monthly 12
    0 0 * * 1       /root/bin/zfs-snapshot datapool/Temp weekly 4

Create up to 3 named snapshots using zfs-autosnap.sh:

    0 12 1 * *              /root/bin/zfs-autosnap datapool/Temp 3

Named snapshots may be useful when creating backups:

    toctar create -C /datapool/Temp/.zfs/snapshot/ Temp_snapshot_2020-01-01

This way, all files in the tape archive will be relative to .../snapshot/
like Temp_snapshot_2020-01-01/file.



Notes
-----

The snapshot base name may only contain letters, digits and underscores.

In order to prevent a "Device busy" error when moving an existing snapshot,
the list of snapshots is generated without directly accessing one.
Even a stat would return this error in such a case.



Author
------

Philip Seeger (philip@c0xc.net)



License
-------

Please see the file called LICENSE.



