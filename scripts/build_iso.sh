make-ca -g

skopeo copy docker://ghcr.io/stable-os/stable-os-bootable:latest dir:/tmp/filesystemimage --dest-decompress

mkdir -pv /tmp/filesystemimage_decompressed && tar -xf $(file --mime-type /tmp/filesystemimage/* | awk -F': ' '$2=="application/x-tar"{print $1}' | head -n 1) -C /tmp/filesystemimage_decompressed

# this should get mounted later on by fstab i think
mkdir -pv /tmp/filesystemimage_decompressed/{proc,tmp,etc,boot}

# create the fstab file
cat >/tmp/filesystemimage_decompressed/etc/fstab <<"EOF"
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
tmpfs           /tmp            tmpfs   defaults        0       0
/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
/media/cdrom0/image.squashfs / squashfs ro,loop 0 0
EOF

rm -rf /tmp/filesystemimage_decompressed/sysroot

# create squashfs image
mksquashfs /tmp/filesystemimage_decompressed /tmp/filesystemimage_decompressed.squashfs # -comp gzip -Xbcj x86 -b 1M -noappend

mkdir -pv /tmp/livecd
mv -v /tmp/filesystemimage_decompressed.squashfs /tmp/livecd/image.squashfs

# copy kernel, config and system map
mkdir -pv /tmp/livecd/boot
cp /tmp/filesystemimage_decompressed/boot/* /tmp/livecd/boot

grub-mkrescue -o /tmp/grub-rescue.iso /tmp/livecd

cp /tmp/grub-rescue.iso /shareddir/grub-rescue.iso

# make iso readable by everyone
chmod 777 /shareddir/grub-rescue.iso
