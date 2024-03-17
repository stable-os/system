sudo apt-get update
sudo apt-get install ostree libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev pkg-config go-md2man rsync

# Rust
sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

chmod +x ./ostree-ext-cli/ostree-ext-cli

git clone https://github.com/containers/skopeo /home/runner/go/src/github.com/containers/skopeo
cd /home/runner/go/src/github.com/containers/skopeo && DISABLE_DOCS=1 make bin/skopeo && sudo make install

# tool for reading the toml files
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq
