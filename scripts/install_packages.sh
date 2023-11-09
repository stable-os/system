BUILD_REPO=$TMPROOT/build-repo
ARCH=$(uname -m)

for package in packages/package_*
do
    package_name=$(echo $package | sed 's/packages\/package_//')
    echo $package_name
    ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/$package_name --tree=tar=packages/$package/out.tar.gz
done
