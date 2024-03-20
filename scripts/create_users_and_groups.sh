# loop over all files in the ./etc/pkgs folder
for package in $(ls ./etc/pkgs); do

  # create the temporary directory
  mkdir -pv /tmp/pkgpostinstall/{users,groups,shadow}

  # copy the file to /tmp
  cp ./etc/pkgs/$package /tmp/pkgpostinstall/package.toml

  echo "Handling package $package."

  yq /tmp/pkgpostinstall/package.toml -oy

  # split all the users and groups into separate files
  # and move them to the folders
  yq '.user.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/users/" + .id'
  yq '.group.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/groups/" + .id'
  yq '.shadow.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/shadow/" + .id'

  ls -l /tmp/pkgpostinstall/users
  ls -l /tmp/pkgpostinstall/groups

  for group in /tmp/pkgpostinstall/groups/*; do
    ID=$(yq '.id' $group)
    NAME=$(yq '.name' $group)

    # make sure the id string is not empty
    # if it is, skip the group
    if [ -z "$ID" ]; then
      echo "Skipping group $NAME because id ($ID) is empty."
      continue
    fi

    echo "Adding group $NAME with id $ID."

    # add the group
    echo "$NAME:x:$ID:" >> ./etc/group
  done

  for shadow in /tmp/pkgpostinstall/shadow/*; do
    NAME=$(yq '.name' $shadow)
    PASSWORD=$(yq '.password' $shadow)

    echo "Adding shadow entry for user $NAME with password $PASSWORD."

    # add the group
    echo "$NAME:$PASSWORD:::::::" >> ./etc/shadow
  done

  for user in /tmp/pkgpostinstall/users/*; do
    ID=$(yq '.id' $user)
    GID=$(yq '.gid' $user)
    NAME=$(yq '.name' $user)
    LOGIN=$(yq '.login' $user)
    HOME=$(yq '.home' $user)
    SHELL=$(yq '.shell' $user)

    # make sure the id string is not empty
    # if it is, skip the group
    if [ -z "$ID" ]; then
      echo "Skipping user $NAME ($LOGIN) because id ($ID) is empty."
      continue
    fi

    echo "Adding user $LOGIN with id $ID and gid $GID."

    # add the user
    echo "$LOGIN:x:$ID:$GID:$NAME:$HOME:$SHELL" >> ./etc/passwd
  done

  # cleanup
  rm -r /tmp/pkgpostinstall
done

cat ./etc/passwd
cat ./etc/group
cat ./etc/shadow
