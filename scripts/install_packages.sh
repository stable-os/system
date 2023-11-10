BUILD_REPO=$TMPROOT/build-repo
ARCH=$(uname -m)

for package in packages/package_*
do
    package_name=$(echo $package | sed 's/packages\/package_//')
    echo $package_name as stable-os/$ARCH/$package_name from $package

    ls $WORKING_DIR/$package
    ls $WORKING_DIR/$package/out.tar.gz
    file $WORKING_DIR/$package/out.tar.gz
    ls $package
    ls $package/out.tar.gz
    file $package/out.tar.gz

    # extract package to tmp/install_packages
    mkdir -p tmp_install_packages
    tar -C tmp_install_packages -xzf ../$package/out.tar.gz
    # delete package.toml
    rm -rf tmp_install_packages/package.toml
    # delete package
    rm -rf $package/out.tar.gz
    # create tar.gz
    tar -C tmp_install_packages -czf ../$package/out.tar.gz .
    # delete tmp_install_packages
    rm -rf tmp_install_packages

    ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/$package_name --tree=tar=$package/out.tar.gz
done

rm -rf packages
mkdir stable-os-build

for package in bash glibc coreutils; do
  ostree --repo=$BUILD_REPO checkout -U --union stable-os/$ARCH/${package} stable-os-build
done
# Set up a "rofiles-fuse" mount point; this ensures that any processes
# we run for post-processing of the tree don't corrupt the hardlinks.
mkdir -p mnt
rofiles-fuse stable-os-build mnt
# Now run global "triggers", generate cache files:
ldconfig -r mnt
#   (Insert other programs here)

# tar filesystem for debugging
tar -C mnt -czf stable-os-build.tar.gz .

# chroot mnt /bin/bash -c "echo test; exit"

docker image build -t ghcr.io/stable-os/stable-os-build -f Containerfile .

fusermount -u mnt
ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/standard --link-checkout-speedup stable-os-build
