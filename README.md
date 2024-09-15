# KMIP Server for Synology DSM

This container implements a private KMIP server for Synology DSM to store the
Encryption Key Vault. By default, DSM offers you to store your vault on the same
hard drives where you have encrypted data, which is a big security risk, or to
store it on another Synology NAS somewhere online, which might not be convenient
for most setups. This KMIP server is very easy to use and can be started on a
small computer like Raspberry Pi, where you can have your own way to protect the
KMIP server itself, for example, store it on LUKS partition and do not
automatically mount it on reboot.

The minimum version of Synology DSM that works properly with this KMIP server is
DSM 7.2-64570.

Latest Synology DSM which was checked to be compatible with this KMIP server is 
DSM 7.2.2-72806.

Based on [PyKMIP](https://github.com/OpenKMIP/PyKMIP) project.

## Installation

You will need a Linux computer/board/VM running Git, and Podman or Docker. There
are no other requirements. This container does not pollute your system and only
touches files in the directory it was launched from.

1. Clone this repository
```
$ git clone https://github.com/rnurgaliyev/kmip-server-dsm
$ cd kmip-server-dsm
```

2. Review configuration file with your favorite text editor (important!)
```
$ vim ./config.sh
```

### Building and runnning container manually

1. Build and run the container using docker compose. I don't provide binary
images because you don't want to trust your secrets to unknown binaries.
Instead, study the contents of this repository to feel comfortable, and build a
KMIP server yourself.
```
$ docker compose up -d
```

## Where is my data stored?
All keys and certificates are stored in the `certs` directory, and the KMIP
database itself is stored in the `state` directory. Both directories are mounted
in the KMIP server container. You can stop and remove a running container, but
your certificates and data will not be lost. It is in your best interest to keep
this repository with these directories in a safe place, such as an encrypted
file system or RAM disk. You can always wipe the contents of these directories
and start from scratch if you have recovery keys for your NAS volumes.

## Synology DSM configuration
Shortly after the container is started for the first time, some SSL keys and
certificates in the `certs` directory. You will need to copy these files to your
NAS:

* client.key
* client.crt
* ca.crt

Connect to your DSM web interface and go to Control Panel -> Security ->
Certificate. Click `Add`, then `Add a new certificate`, enter `KMIP` in the
`Description` field, then `Import certificate`. Select the file `client.key` for
`Private Key`, `client.crt` for `Certificate` and `ca.crt` for `Intermediate
Certificate`. Then click on `Settings` and select the newly imported certificate
for `KMIP`.

Switch to the 'KMIP' tab and configure the 'Remote Key Client'. Hostname is the
address of this KMIP server, port is 5696, and select the `ca.crt` file again
for `Certificate Authority`.

You should now have a fully functional remote Encryption Key Vault.

## Troubleshooting

On DSM side:
1. Connect to your NAS via SSH
2. Check logs of kmip service:
```
$ sudo journalctl -u kmip.service -ef
```

On KMIP server side:
1. Jump into the container (replace podman with docker if needed):
```
$ podman exec -ti dsm-kmip-server /bin/sh
```
2. Check pykmip logs:
```
$ cat /var/log/pykmip/server.log
```

## Tips on creating encrypted storage on Raspberry Pi

These are tips on how to create an encrypted filesystem on Raspberry Pi where
you can store your KMIP server. These steps can be adapted for any other type of
computer or VM.

1. Download Ubuntu Server image for Raspebby Pi from the 
[Ubuntu website](https://ubuntu.com/download/raspberry-pi).

2. Write the image to an SD card. Before rebooting, plug the SD card into
existing Linux machine. We will play with partitioning table a little bit.
Assuming your SD card is `/dev/sdc`:
```
$ xz -d ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz
$ sudo dd if=./ubuntu-22.04.2-preinstalled-server-arm64+raspi.img of=/dev/sdc status=progress
```
3. Assuming your SD card is `/dev/sdc`, start fdisk:
```
$ sudo fdisk /dev/sdc

Welcome to fdisk (util-linux 2.38.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): 
```

4. List partitions and note where the second partition starts, we will need this
address later:
```
Command (m for help): p
Disk /dev/sdc: 58,63 GiB, 62948114432 bytes, 122945536 sectors
Disk model: Micro blackhole based storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x12c9124a

Device     Boot  Start     End Sectors  Size Id Type
/dev/sdc1  *      2048  526335  524288  256M  c W95 FAT32 (LBA)
/dev/sdc2       526336 8074399 7548064  3,6G 83 Linux

Command (m for help): 
```
Note that `/dev/sdc2` starts at 526336.

5. Delete the second partition:
```
Command (m for help): d
Partition number (1,2, default 2): 2

Partition 2 has been deleted.
```

6. Create a new partition. Make sure you start the new partition on the same
sector where the old one was. Decide how much space you want to leave for the
encrypted storage and enter it in the `Last sector` with a minus sign, in the
example below I left 8 gigabytes at the end of the disk:
```
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (2-4, default 2): 2
First sector (526336-122945535, default 526336): 526336
Last sector, +/-sectors or +/-size{K,M,G,T,P} (526336-122945535, default 122945535): -8G

Created a new partition 2 of type 'Linux' and of size 50,4 GiB.
Partition #2 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: No

Command (m for help): 
```
Be sure to answer NO when you are asked if you want to remove the existing file
system signature.

7. Now create the last partition, that you will use for your encrypted storage.
Just hit `ENTER` on all questions:
```
Command (m for help): n
Partition type
   p   primary (2 primary, 0 extended, 2 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (3,4, default 3): 
First sector (106168320-122945535, default 106168320): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (106168320-122945535, default 122945535): 

Created a new partition 3 of type 'Linux' and of size 8 GiB.

Command (m for help): 
```

8. Now you have an SD card with boot, root, and data partition, which you will
use later for an encrypted file system. Check that everything looks good and
write the changes to disk:
```
Command (m for help): p
Disk /dev/sdc: 58,63 GiB, 62948114432 bytes, 122945536 sectors
Disk model: Micro blackhole based storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x12c9124a

Device     Boot     Start       End   Sectors  Size Id Type
/dev/sdc1  *         2048    526335    524288  256M  c W95 FAT32 (LBA)
/dev/sdc2          526336 106168319 105641984 50,4G 83 Linux
/dev/sdc3       106168320 122945535  16777216    8G 83 Linux

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

9. Last step before booting your Raspberry Pi with this SD card is to expand
root file system:
```
$ sudo resize2fs /dev/sdc2
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /dev/sdc2 to 13205248 (4k) blocks.
The filesystem on /dev/sdc2 is now 13205248 (4k) blocks long.
```

10. Boot your Raspberry Pi and do a basic initial setup. Check that you can see
the third partition you created above and make sure it is not mounted anywhere:
```
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  59.1M  1 loop /snap/core20/1826
loop1    7:1    0 109.6M  1 loop /snap/lxd/24326
loop2    7:2    0  43.2M  1 loop /snap/snapd/18363
loop3    7:3    0  59.1M  1 loop /snap/core20/1832
sda      8:0    0 111.8G  0 disk 
├─sda1   8:1    0   256M  0 part /boot/firmware
├─sda2   8:2    0 104.1G  0 part /
└─sda3   8:3    0   7.5G  0 part 
```

11. You can now create an encrypted file system:
```
$ sudo cryptsetup luksFormat /dev/sda3

WARNING!
========
This will overwrite data on /dev/sda3 irrevocably.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/sda3: 
Verify passphrase: 
Ignoring bogus optimal-io size for data device (33553920 bytes).
```

12. You can now open /dev/sda3, create filesystem on it and mount it:
```
$ sudo cryptsetup open /dev/sda3 myvault
Enter passphrase for /dev/sda3: 

$ sudo mkfs.ext4 /dev/mapper/myvault 
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 1949046 4k blocks and 487680 inodes
Filesystem UUID: 9e9183a9-5d51-4782-9990-d99eb48dfc87
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

$ sudo mount /dev/mapper/myvault /mnt
```

13. You now have encrypted storage in `/mnt`. Check it with `df -h`:
```
$ df -h
Filesystem           Size  Used Avail Use% Mounted on
tmpfs                781M  3.1M  778M   1% /run
/dev/sda2            103G   18G   81G  18% /
tmpfs                3.9G  200K  3.9G   1% /dev/shm
tmpfs                5.0M     0  5.0M   0% /run/lock
/dev/sda1            253M  148M  105M  59% /boot/firmware
tmpfs                781M   80K  781M   1% /run/user/1001
/dev/mapper/myvault  7.3G   24K  6.9G   1% /mnt
```
Now you can clone this repository to a protected space on your Raspberry Pi.
This file system will not be automatically unsealed after reboot, and you will
need to unseal it with a password and mount it. After that, just restart the
KMIP server container with `run-container.sh`.

## Disclaimer

Everything in this repository is provided to you "as is". I am not affiliated
with Synology or the PyKMIP project. I take no responsibility for lost data or
security issues.