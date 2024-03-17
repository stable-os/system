# loop over all files in the ./etc/pkgs folder
for package in $(ls ./etc/pkgs); do

  # create the temporary directory
  mkdir -pv /tmp/pkgpostinstall/{users,groups}

  # copy the file to /tmp
  cp ./etc/pkgs/$package /tmp/pkgpostinstall/package.toml

  echo "Handling package $package."

  yq /tmp/pkgpostinstall/package.toml -oy

  # split all the users and groups into separate files
  # and move them to the folders
  yq '.user.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/users/" + .id'
  yq '.group.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/groups/" + .id'

  ls -l /tmp/pkgpostinstall/users
  ls -l /tmp/pkgpostinstall/groups

  for group in /tmp/pkgpostinstall/groups/*; do
    local ID = $(yq '.id' /tmp/pkgpostinstall/groups/$group)
    local NAME = $(yq '.name' /tmp/pkgpostinstall/groups/$group)

    echo "Adding group $NAME with id $ID."

    # add the group
    echo "$ID::$NAME:" >> ./etc/group
  done

  for user in /tmp/pkgpostinstall/users/*; do
    local ID = $(yq '.id' /tmp/pkgpostinstall/users/$user)
    local GID = $(yq '.gid' /tmp/pkgpostinstall/users/$user)
    local NAME = $(yq '.name' /tmp/pkgpostinstall/users/$user)
    local LOGIN = $(yq '.login' /tmp/pkgpostinstall/users/$user)
    local HOME = $(yq '.home' /tmp/pkgpostinstall/users/$user)
    local SHELL = $(yq '.shell' /tmp/pkgpostinstall/users/$user)

    echo "Adding user $LOGIN with id $ID and gid $GID."

    # add the user
    echo "$LOGIN:*:$ID:$GID:$NAME:$HOME:$SHELL" >> ./etc/passwd
  done

  # cleanup
  rm -r /tmp/pkgpostinstall
done

cat ./etc/passwd
cat ./etc/group
