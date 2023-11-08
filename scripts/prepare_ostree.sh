sudo mkdir -p $TMPROOT/build-repo
sudo chown -R $(whoami) $TMPROOT
ostree --repo=$TMPROOT/build-repo init --mode=bare-user
