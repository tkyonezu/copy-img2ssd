#!/bin/bash

logmsg() {
  echo ">>> $1"
}

function get_partuuid() {
  sudo blkid $1 >/var/tmp/blkid$$.txt
  PARTUUID=$(cat /var/tmp/blkid$$.txt  | sed 's/^.*PARTUUID=\"//' | cut -c1-8)
  sudo rm /var/tmp/blkid$$.txt

  echo ${PARTUUID}
}

function get_uuid() {
  sudo blkid $1 >/var/tmp/blkid$$.txt
  UUID=$(cat /var/tmp/blkid$$.txt  | sed 's/^.* UUID=\"//' | sed 's/\".*//')
  sudo rm /var/tmp/blkid$$.txt

  echo ${UUID}
}

logmsg "Start Copy Rocky Linux to SSD"

logmsg "Create partitions"
sudo parted /dev/sda mklabel msdos
sudo parted /dev/sda mkpart primary fat32 0% 512M   
sudo parted /dev/sda mkpart primary ext4 512M 100%

sudo parted /dev/sda print

logmsg "Make filesystems"
sudo mkfs.vfat -F 32 /dev/sda1
sudo mkfs.ext4 /dev/sda2

sudo e2label /dev/sda2 "_/"

cd /var/tmp

if [ ! -f RockyLinuxRpi_9-latest.img ]; then
  logmsg "Get Latest Rocky Linux image"
  wget https://dl.rockylinux.org/pub/sig/9/altarch/aarch64/images/RockyLinuxRpi_9-latest.img.xz

  xz -dv RockyLinuxRpi_9-latest.img.xz
fi

logmsg "Loopback mount Rocky Linux image"
sudo kpartx -av RockyLinuxRpi_9-latest.img

logmsg "Copy boot filesystem to SSD"
sudo rm -fr /var/tmp/mnt2
sudo mkdir /var/tmp/mnt2

sudo mount /dev/mapper/loop0p1 /mnt
sudo mount /dev/sda1 /var/tmp/mnt2

sudo rsync -avhP /mnt/ /var/tmp/mnt2/

sudo umount /var/tmp/mnt2 /mnt

logmsg "Copy root filesystem to SSD"
sudo mount /dev/mapper/loop0p3 /mnt
sudo mount /dev/sda2 /var/tmp/mnt2

sudo rsync -avhP --exclude /mnt/lost+found /mnt/ /var/tmp/mnt2/

logmsg "Unmount Rocky Linux image"
sudo umount /var/tmp/mnt2 /mnt

sudo kpartx -d RockyLinuxRpi_9-latest.img

logmsg "Modify PARTUUID of 'cmdline.txt'"
BPU=$(get_partuuid /dev/sda1)

sudo mount /dev/sda1 /mnt
sudo sed -i "s/PARTUUID=.*-03/PARTUUID=${BPU}-02/" /mnt/cmdline.txt
sudo sed -i 's/$/ selinux=0/' /mnt/cmdline.txt
sudo umount /mnt

logmsg "Modify UUID of '/etc/fstab'"
BUU=$(get_uuid /dev/sda1)
RUU=$(get_uuid /dev/sda2)

sudo mount /dev/sda2 /mnt

sudo sed -i "/ ext4 /s/^UUID=.................................... /UUID=${RUU} /" /mnt/etc/fstab
sudo sed -i "/fat /s/^UUID=......... /UUID=${BUU} /" /mnt/etc/fstab
sudo sed -i "/ swap /s/^/## /" /mnt/etc/fstab

sudo umount /mnt

logmsg "End of Copy Rocky Linux to SSD"

exit 0
