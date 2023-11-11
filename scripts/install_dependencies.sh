sudo apt-get update
sudo apt-get install ostree skopeo

# Rust
sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

chmod +x ./ostree-ext-cli/ostree-ext-cli