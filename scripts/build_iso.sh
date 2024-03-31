make-ca -g

skopeo copy docker://ghcr.io/stable-os/stable-os-installer:latest dir:/tmp/filesystemimage --dest-decompress

mkdir -pv /tmp/filesystemimage_decompressed && tar -xf $(file --mime-type /tmp/filesystemimage/* | awk -F': ' '$2=="application/x-tar"{print $1}' | head -n 1) -C /tmp/filesystemimage_decompressed

# this should get mounted later on by fstab i think
mkdir -pv /tmp/filesystemimage_decompressed/{proc,tmp,etc,boot}

# download the image for the installer
mkdir -pv /var/tmp
mkdir -pv /tmp/filesystemimage_decompressed/{etc/containers,tmp/podmanrunroot,tmp/podmangraphroot}

# TODO: Perform the nessecary database mods to make the podman errors go away
# UPDATE DBConfig SET StaticDir = '/podmanimage/libpod';
# UPDATE DBConfig SET GraphRoot = '/podmanimage';

# We install the postflash before installing the actual image to prevent running out of ram
podman pull --root=/tmp/filesystemimage_decompressed/podmanimage ghcr.io/stable-os/stable-os-postflash:latest

# skopeo copy docker://ghcr.io/stable-os/stable-os-bootable:latest docker-archive:/tmp/filesystemimage_decompressed/image.tar:stable-os-bootable:latest

# create the fstab file
# cat >/tmp/filesystemimage_decompressed/etc/fstab <<"EOF"
# # <file system> <mount point>   <type>  <options>       <dump>  <pass>
# tmpfs           /tmp            tmpfs   defaults        0       0
# /dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
# /media/cdrom0/image.squashfs / squashfs ro,loop 0 0
# EOF

rm -rf /tmp/filesystemimage_decompressed/sysroot

mkdir /tmp/filesystemimage_decompressed/{proc,dev}
mount --bind /proc /tmp/filesystemimage_decompressed/proc
mount --bind /dev /tmp/filesystemimage_decompressed/dev

# create initramfs using dracut
chroot /tmp/filesystemimage_decompressed /usr/bin/bash <<"EOT"
KERNEL_VERSION=$(find /lib/modules -maxdepth 1 -type d -printf "%f" | sed 's/modules//')
echo KERNEL VERSION: $KERNEL_VERSION
mkdir -pv /var/tmp
dracut --add dmsquash-live /tmp/initramfs.img "$KERNEL_VERSION"
rm -rf /var/tmp

systemctl preset-all
augenrules --load
EOT

umount /tmp/filesystemimage_decompressed/proc
umount /tmp/filesystemimage_decompressed/dev

cp /tmp/filesystemimage_decompressed/tmp/initramfs.img /tmp/initramfs.img
rm -rf /tmp/filesystemimage_decompressed/tmp/initramfs.img

# password is "root"
cat >/tmp/filesystemimage_decompressed/etc/shadow <<"EOF"
root:$1$cln3295b$cIb9zBngnbVV/PLn05q.T0:19740::::::
EOF

cp /tmp/filesystemimage_decompressed/usr/lib/ld-linux-x86-64.so.2 /tmp/filesystemimage_decompressed/usr/lib/ld-linux-x86-64.so

# set to false to place root fs on squashfs, true to place it inside ext4 wrapper
USE_EXT4=false

if [ "$USE_EXT4" = true ]; then
    echo "Using ext4 wrapper"
    # move to ext4 img file
    dd if=/dev/zero of=/tmp/filesystemimage_decompressed.ext4 bs=1M count=8192
    mkfs.ext4 /tmp/filesystemimage_decompressed.ext4
    mkdir /tmp/filesystemimage_decompressed_ext4
    mount /tmp/filesystemimage_decompressed.ext4 /tmp/filesystemimage_decompressed_ext4
    cp -a /tmp/filesystemimage_decompressed/* /tmp/filesystemimage_decompressed_ext4
    umount /tmp/filesystemimage_decompressed_ext4

    # move to squashfs img file
    mkdir -pv /tmp/squashfsimage/LiveOS
    cp /tmp/filesystemimage_decompressed.ext4 /tmp/squashfsimage/LiveOS/rootfs.img

    # create squashfs image
    mksquashfs /tmp/squashfsimage /tmp/filesystemimage_decompressed.squashfs # -comp gzip -Xbcj x86 -b 1M -noappend
else
    echo "Using squashfs"
    mksquashfs /tmp/filesystemimage_decompressed /tmp/filesystemimage_decompressed.squashfs # -comp gzip -Xbcj x86 -b 1M -noappend
fi

mkdir -pv /tmp/livecd/LiveOS
mv -v /tmp/filesystemimage_decompressed.squashfs /tmp/livecd/LiveOS/squashfs.img

# copy kernel, config and system map
mkdir -pv /tmp/livecd/boot/grub
cp /tmp/filesystemimage_decompressed/boot/* /tmp/livecd/boot
cp /tmp/initramfs.img /tmp/livecd/boot/initramfs.img

cat >/tmp/livecd/boot/grub/grub.cfg <<"EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2

menuentry "Linux 6.4.12-lfs-12.0" {
    linux   /boot/vmlinuz-6.4.12-lfs-12.0 root=live:/dev/sr0 rd.live.overlay.overlayfs=1 init=/usr/lib/systemd/systemd console=ttyS0,115200n8 console=tty0
    initrd  /boot/initramfs.img
}

menuentry "Linux 6.4.12-lfs-12.0 RESCUE MODE" {
    linux   /boot/vmlinuz-6.4.12-lfs-12.0 root=live:/dev/sr0 rd.live.overlay.overlayfs=1 init=/usr/lib/systemd/systemd console=ttyS0,115200n8 console=tty0 systemd.unit=rescue.target
    initrd  /boot/initramfs.img
}
EOF

grub-mkrescue -o /tmp/grub-rescue.iso /tmp/livecd

cp /tmp/grub-rescue.iso /shareddir/grub-rescue.iso

# make iso readable by everyone
chmod 777 /shareddir/grub-rescue.iso
