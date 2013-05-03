date > /usbkey/vagrant_box_build_time

CDROM=c0t0d0
BOOTDISK=c2t0d0
ZONESDISK=c2t1d0

export PATH=/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin

# Boot from local disk (thanks to Andrzej Szeszo (@aszeszo))
SetupBootDisk() {

  echo Mounting cdrom...
  mkdir /mnt-cdrom
  mount -F hsfs /dev/dsk/${CDROM}p0 /mnt-cdrom

  echo Setting up the boot disk...
  cat <<EOF | fdisk -F /dev/stdin /dev/rdsk/${BOOTDISK}p0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
EOF
  NUMSECT=$(iostat -En $BOOTDISK | awk '/^Size:/ { sub("<",""); \
    print $3/512 - 2048 }')
  fdisk -A 12:128:0:0:0:0:0:0:2048:$NUMSECT /dev/rdsk/${BOOTDISK}p0
  echo y|mkfs -F pcfs -o fat=32 /dev/rdsk/${BOOTDISK}p0:c

  echo Mounting boot disk...
  mkdir /mnt-boot
  mount -F pcfs /dev/dsk/${BOOTDISK}p1 /mnt-boot

  echo Copying SmartOS platform boot files to the boot disk...
  rsync -a /mnt-cdrom/ /mnt-boot/

  echo "Installing GRUB..."
  grub --batch <<EOF >/dev/null 2>&1
device (hd0) /dev/dsk/${BOOTDISK}p0
root (hd0,0)
install /boot/grub/stage1 (hd0) (hd0,0)/boot/grub/stage2 p (hd0,0)/boot/grub/menu.lst
quit
EOF

  echo "Fixing GRUB kernel & module menu.lst entries..."
  sed -i '' -e 's%kernel /platform/%kernel (hd0,0)/platform/%' \
    -e 's%module /platform/%module (hd0,0)/platform/%' \
    /mnt-boot/boot/grub/menu.lst

  echo "Setting GRUB timeout to 0s..."
  sed -i '' 's/timeout=.*/timeout=0/' /mnt-boot/boot/grub/menu.lst

  umount /mnt-cdrom
  umount /mnt-boot

  rmdir /mnt-cdrom
  rmdir /mnt-boot
}

SetupPackageManager() {
  cd /
  curl -k http://pkgsrc.joyent.com/sdc6/2012Q2/x86_64/bootstrap.tar.gz | gzcat | tar -xf - -C /
  pkg_admin rebuild
}

InstallChef() {
  # Install build dependencies for Chef
  pkgin -y update
  pkgin -y install gcc47 gcc47-runtime scmgit-base gmake ruby193-base ruby193-yajl ruby193-nokogiri ruby193-readline pkg-config

  OLDPATH=${PATH}
  export PATH=/opt/local/gnu/bin:/opt/local/gcc47/bin:/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin
  
  gem193 update --system
  
  # Install Chef
  gem193 install --no-ri --no-rdoc ohai
  gem193 install --no-ri --no-rdoc chef
  gem193 install --no-ri --no-rdoc rb-readline

  export PATH=${OLDPATH}
}

SetupBootDisk
SetupPackageManager
InstallChef

exit