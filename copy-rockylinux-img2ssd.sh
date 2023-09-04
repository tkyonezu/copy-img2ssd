#!/bin/bash

SSDDEV=/dev/sda
BOOTSZ=512M

ROCKY_URL="https://dl.rockylinux.org/pub/sig/9/altarch/aarch64/images/"
ROCKY_IMG="RockyLinuxRpi_9-latest.img"

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
sudo parted ${SSDDEV} mklabel msdos
sudo parted ${SSDDEV} mkpart primary fat32 0% ${BOOTSZ}   
sudo parted ${SSDDEV} mkpart primary ext4 ${BOOTSZ} 100%

sudo parted ${SSDDEV} print

logmsg "Make filesystems"
sudo mkfs.vfat -F 32 ${SSDDEV}1
sudo mkfs.ext4 ${SSDDEV}2

sudo e2label ${SSDDEV}2 "_/"

cd /var/tmp

if [ ! -f RockyLinuxRpi_9-latest.img ]; then
  logmsg "Get Latest Rocky Linux image"
  curl -L ${ROCKY_URL}${ROCKY_IMG}.xz -o ${ROCKY_IMG}.xz

  xz -dv ${ROCKY_IMG}.xz
fi

logmsg "Loopback mount Rocky Linux image"
sudo kpartx -av ${ROCKY_IMG}

logmsg "Copy boot filesystem to SSD"
[ -d /var/tmp/mnt2 ] && sudo rm -fr /var/tmp/mnt2
sudo mkdir /var/tmp/mnt2

sudo mount /dev/mapper/loop0p1 /mnt
sudo mount ${SSDDEV}1 /var/tmp/mnt2

sudo rsync -avh --info=progress2 /mnt/ /var/tmp/mnt2/

sudo umount /var/tmp/mnt2 /mnt

logmsg "Copy root filesystem to SSD"
sudo mount /dev/mapper/loop0p3 /mnt
sudo mount ${SSDDEV}2 /var/tmp/mnt2

sudo rsync -avh --info=progress2 --exclude /mnt/lost+found /mnt/ /var/tmp/mnt2/

logmsg "Unmount Rocky Linux image"
sudo umount /var/tmp/mnt2 /mnt

sudo kpartx -d ${ROCKY_IMG}

logmsg "Modify PARTUUID of 'cmdline.txt'"
BPU=$(get_partuuid ${SSDDEV}1)

sudo mount ${SSDDEV}1 /mnt
sudo sed -i "s/PARTUUID=.*-03/PARTUUID=${BPU}-02/" /mnt/cmdline.txt
sudo sed -i 's/$/ selinux=0/' /mnt/cmdline.txt
sudo umount /mnt

logmsg "Modify UUID of '/etc/fstab'"
BUU=$(get_uuid ${SSDDEV}1)
RUU=$(get_uuid ${SSDDEV}2)

sudo mount ${SSDDEV}2 /mnt

sudo sed -i "/ ext4 /s/^UUID=.................................... /UUID=${RUU} /" /mnt/etc/fstab
sudo sed -i "/fat /s/^UUID=......... /UUID=${BUU} /" /mnt/etc/fstab
sudo sed -i "/ swap /s/^/## /" /mnt/etc/fstab

sudo umount /mnt

sudo rm -fr /var/tmp/mnt2

logmsg "End of Copy Rocky Linux to SSD"

exit 0
