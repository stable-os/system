make-ca -g

skopeo copy docker://ghcr.io/stable-os/stable-os-bootable:latest dir:/tmp/filesystemimage --dest-decompress

mkdir -pv /tmp/filesystemimage_decompressed && tar -xf $(file --mime-type /tmp/filesystemimage/* | awk -F': ' '$2=="application/x-tar"{print $1}' | head -n 1) -C /tmp/filesystemimage_decompressed

# this should get mounted later on by fstab i think
mkdir -pv /tmp/filesystemimage_decompressed/{proc,tmp,etc,boot}

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
dracut -o "dracut-systemd systemd" --add "dmsquash-live" /tmp/initramfs.img "$KERNEL_VERSION"
rm -rf /var/tmp

systemctl preset-all
EOT

umount /tmp/filesystemimage_decompressed/proc
umount /tmp/filesystemimage_decompressed/dev

cp /tmp/filesystemimage_decompressed/tmp/initramfs.img /tmp/initramfs.img
rm -rf /tmp/filesystemimage_decompressed/tmp/initramfs.img

# create passwd and shadow files for root login
# password is "root"
cat >/tmp/filesystemimage_decompressed/etc/passwd <<"EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat >/tmp/filesystemimage_decompressed/etc/group <<"EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# password is "root"
cat >/tmp/filesystemimage_decompressed/etc/shadow <<"EOF"
root:$1$cln3295b$cIb9zBngnbVV/PLn05q.T0:19740::::::
EOF

echo "Using ext4 wrapper"
# move to ext4 img file
dd if=/dev/zero of=/tmp/filesystemimage_decompressed.ext4 bs=1M count=16384
mkfs.ext4 /tmp/filesystemimage_decompressed.ext4
mkdir /tmp/filesystemimage_decompressed_ext4
mount /tmp/filesystemimage_decompressed.ext4 /tmp/filesystemimage_decompressed_ext4
cp -a /tmp/filesystemimage_decompressed/* /tmp/filesystemimage_decompressed_ext4
umount /tmp/filesystemimage_decompressed_ext4

mkdir -pv /tmp/livecd/boot/grub

# copy kernel and stuff before wiping the fs image
cp /tmp/filesystemimage_decompressed/boot/* /tmp/livecd/boot
cp /tmp/initramfs.img /tmp/livecd/boot/initramfs.img

# cleanup
rm -rf /tmp/filesystemimage_decompressed

# move to squashfs img file
mkdir -pv /tmp/squashfsimage/LiveOS
cp /tmp/filesystemimage_decompressed.ext4 /tmp/squashfsimage/LiveOS/rootfs.img

# create squashfs image
mksquashfs /tmp/squashfsimage /tmp/filesystemimage_decompressed.squashfs # -comp gzip -Xbcj x86 -b 1M -noappend

mv -v /tmp/filesystemimage_decompressed.squashfs /tmp/livecd/LiveOS/squashfs.img

cat >/tmp/livecd/boot/grub/grub.cfg <<"EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod all_video
insmod part_gpt
insmod ext2

menuentry "Linux 6.4.12-lfs-12.0" {
    linux   /boot/vmlinuz-6.4.12-lfs-12.0 root=live:/dev/sr0 rd.live.image console=ttyS0,115200n8 console=tty0
    initrd  /boot/initramfs.img
}

menuentry "Linux 6.4.12-lfs-12.0 RESCUE MODE" {
    linux   /boot/vmlinuz-6.4.12-lfs-12.0 root=live:/dev/sr0 rd.live.image console=ttyS0,115200n8 console=tty0 systemd.unit=rescue.target
    initrd  /boot/initramfs.img
}
EOF

grub-mkrescue -o /tmp/grub-rescue.iso /tmp/livecd

cp /tmp/grub-rescue.iso /shareddir/grub-rescue.iso

# make iso readable by everyone
chmod 777 /shareddir/grub-rescue.iso
