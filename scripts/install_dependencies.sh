sudo apt-get update
sudo apt-get install ostree

# Rust
sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
sudo cargo install ostree-ext-cli