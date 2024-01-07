make-ca -g

skopeo copy docker://ghcr.io/stable-os/stable-os-bootable:latest dir:/tmp/filesystemimage --dest-decompress

mkdir -pv /tmp/filesystemimage_decompressed/mnt/{lower,upper} && tar -xf $(file --mime-type /tmp/filesystemimage/* | awk -F': ' '$2=="application/x-tar"{print $1}' | head -n 1) -C /tmp/filesystemimage_decompressed/mnt/lower

# this should get mounted later on by fstab i think
mkdir -pv /tmp/filesystemimage_decompressed/{proc}

# the boot stuff is in /mnt/lower, so this should be symlinked to /boot
# ln -svf /mnt/lower/boot /tmp/filesystemimage_decompressed/boot
# but because grub also wants to be in there all files have to be symlinked separately
for file in $(ls /tmp/filesystemimage_decompressed/mnt/lower/boot); do
    ln -svf /mnt/lower/boot/$file /tmp/filesystemimage_decompressed/boot/$file
done

# create the fstab file
cat >/tmp/filesystemimage_decompressed/etc/fstab <<"EOF"
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
tmpfs           /mnt/upper      tmpfs   defaults        0       0
tmpfs           /tmp            tmpfs   defaults        0       0

overlay         /               overlay defaults,lowerdir=/mnt/lower,upperdir=/mnt/upper,workdir=/mnt/work 0 0
EOF

rm -rf /tmp/filesystemimage_decompressed/sysroot

grub-mkrescue -o /tmp/grub-rescue.iso /tmp/filesystemimage_decompressed

cp /tmp/grub-rescue.iso /shareddir/grub-rescue.iso

# make iso readable by everyone
chmod 777 /shareddir/grub-rescue.iso
