sudo apt-get update
sudo apt-get install ostree libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev pkg-config go-md2man

# Rust
sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

chmod +x ./ostree-ext-cli/ostree-ext-cli

git clone https://github.com/containers/skopeo /home/runner/go/src/github.com/containers/skopeo
cd /home/runner/go/src/github.com/containers/skopeo && DISABLE_DOCS=1 make bin/skopeo && sudo make install