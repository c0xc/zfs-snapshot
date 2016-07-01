zfs-snapshot
============

A simple snapshot rotation script for ZFS filesystems.

Unlike some example scripts found online, this one handles errors
and does not continue when a command has failed.



Usage
-----

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



Notes
-----

The snapshot base name may only contain letters, digits and underscores.

In order to prevent a "Device busy" error when moving an existing snapshot,
the list of snapshots is generated without directly accessing one.
Even a stat would return this error in such a case.



Author
------

Philip Seeger (philip@philip-seeger.de)



License
-------

Please see the file called LICENSE.



