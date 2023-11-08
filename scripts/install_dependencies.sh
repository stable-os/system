sudo apt-get update
sudo apt-get install ostree podman

# Setup podman socket and allow non-root users to use it
podman system service unix:///podman.sock --log-level=debug --time=50
sudo chmod 666 /podman.sock