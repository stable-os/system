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

for package in bash \
    glibc \
    coreutils \
    selinux \
    libcap \
    libpcre2 \
    ncurses \
    pkg-builder \
    gmp \
    mpfr \
    mpc \
    gcc \
    git \
    tar \
    zlib \
    curl \
    openssl \
    p11-kit \
    make-ca \
    sed \
    grep \
    gawk \
    readline \
    libffi \
    libtasn1 \
    findutils \
    xz \
    binutils \
    attr \
    autoconf \
    automake \
    bc \
    bison \
    check \
    dejagnu \
    diffutils \
    expat \
    file \
    gdbm \
    gettext \
    gperf \
    intltool \
    less \
    libpipeline \
    libtool \
    libxcrypt \
    m4 \
    make \
    manpages \
    patch \
    perl \
    psmisc \
    sysklogd \
    tcl \
    texinfo \
    utillinux \
    xmlparser \
    zstd \
    gzip \
    linux-api-headers \
    python3 \
    which \
    ostree \
    glib \
    libarchive \
    libpgpme \
    libgpg-error \
    bzip2 \
    avahi \
    dbus \
    systemd \
    libassuan \
    skopeo \
    lvm2 \
    pkgconf \
    wget \
    asciidoc \
    meson \
    flit-core \
    wheel \
    essential-files \
    ninja \
    libdaemon \
    e2fsprogs \
    flex \
    groff \
    iana-etc \
    kbd \
    libelf \
    procps \
    shadow \
    timezonedata \
    libaio \
    libxml2 \
    libxslt \
    swig \
    audit \
    fuse \
    pam \
    markupsafe \
    jinja2 \
    xmlto \
    unzip \
    docbook-xml \
    docbook-xsl-nons \
    perl; do

    shouldusestableosbuiltpackageinstead=false
    for usestableosbuiltpackageinstead in flit-core ninja wheel meson asciidoc which linux-api-headers pkg-builder bash libcap libpcre2 ncurses gmp mpc mpfr tar zlib gzip curl openssl p11-kit make-ca grep gawk readline libffi libtasn1 findutils bzip2 xz attr autoconf automake bc bison check diffutils e2fsprogs expat file flex gdbm gettext gperf groff iana-etc kbd less libelf libpipeline libtool libxcrypt m4 make manpages patch perl pkgconf procps python3 shadow sysklogd tcl texinfo timezonedata utillinux xmlparser glib libarchive libpgpme libgpg-error avahi dbus libassuan wget essential-files libdaemon libaio libxslt libxml2 skopeo swig audit fuse pam markupsafe jinja2 xmlto unzip docbook-xml docbook-xsl-nons; do
        if [ "$package" = "$usestableosbuiltpackageinstead" ]; then
            shouldusestableosbuiltpackageinstead=true
        fi
    done
    if [ "$shouldusestableosbuiltpackageinstead" = true ]; then
        # grab the stableosbuilt version instead
        ./ostree-ext-cli/ostree-ext-cli container unencapsulate --repo=$BUILD_REPO --write-ref=stable-os/$ARCH/${package} ostree-unverified-image:docker://ghcr.io/stable-os/package-$package-$ARCH-builtonstableos:latest
    else
        # continue like normal
        ./ostree-ext-cli/ostree-ext-cli container unencapsulate --repo=$BUILD_REPO --write-ref=stable-os/$ARCH/${package} ostree-unverified-image:docker://ghcr.io/stable-os/package-$package-$ARCH:latest
    fi
    ostree --repo=$BUILD_REPO checkout -UC --union stable-os/$ARCH/${package} stable-os-build
    find stable-os-build | grep bzip2
done
# Set up a "rofiles-fuse" mount point; this ensures that any processes
# we run for post-processing of the tree don't corrupt the hardlinks.
mkdir -p mnt
rofiles-fuse stable-os-build mnt
# Now run global "triggers", generate cache files:
ldconfig -r mnt
#   (Insert other programs here)

# we can't do this right now because chmod does not work on Github Actions, would have to be left to the installer
# sudo chroot ./mnt /usr/sbin/make-ca -g || true

rm -rf mnt/package.toml
# ln -svf /usr/bin/bash mnt/bin/sh
ln -svf /usr/bin mnt/bin
ln -svf /usr/lib mnt/lib

find mnt

# tar filesystem for debugging
# this is bugged and creates a massive (2GB) tarball, the OCI image is only 600MB
# tar -C mnt -czf stable-os-build.tar.gz .

# chroot mnt /bin/bash -c "echo test; exit"

fusermount -u mnt
ostree --repo=$BUILD_REPO commit -b stable-os/$ARCH/standard --link-checkout-speedup stable-os-build
