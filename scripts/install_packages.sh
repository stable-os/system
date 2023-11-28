BUILD_REPO=$TMPROOT/build-repo
ARCH=$(uname -m)

# for package in packages/package_*
# do
#     package_name=$(echo $package | sed 's/packages\/package_//')
#     echo $package_name as stable-os/$ARCH/$package_name from $package

#     ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/$package_name --tree=tar=$package/out.tar.gz
# done

# rm -rf packages
mkdir stable-os-build

for package in bash glibc coreutils selinux libcap; do
  ./ostree-ext-cli/ostree-ext-cli container unencapsulate --repo=$BUILD_REPO --write-ref=stable-os/$ARCH/${package} ostree-unverified-image:docker://ghcr.io/stable-os/package-$package-$ARCH:latest
  ostree refs --repo=$BUILD_REPO
  ostree --repo=$BUILD_REPO checkout -UC --union stable-os/$ARCH/${package} stable-os-build
done
# Set up a "rofiles-fuse" mount point; this ensures that any processes
# we run for post-processing of the tree don't corrupt the hardlinks.
mkdir -p mnt
rofiles-fuse stable-os-build mnt
# Now run global "triggers", generate cache files:
ldconfig -r mnt
#   (Insert other programs here)
find mnt

# tar filesystem for debugging
tar -C mnt -czf stable-os-build.tar.gz .

# chroot mnt /bin/bash -c "echo test; exit"

ln -sv mnt/usr/bin mnt/bin
ln -sv mnt/usr/sbin mnt/sbin
ln -sv mnt/usr/lib mnt/lib

fusermount -u mnt
ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/standard --link-checkout-speedup stable-os-build
