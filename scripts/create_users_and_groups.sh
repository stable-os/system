# loop over all files in the ./etc/pkgs folder
for package in $(ls ./etc/pkgs); do

  # create the temporary directory
  mkdir -pv /tmp/pkgpostinstall/{users,groups}

  # copy the file to /tmp
  cp ./etc/pkgs/$package /tmp/pkgpostinstall/package.toml

  # split all the users and groups into separate files
  # and move them to the folders
  yq '.user.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/users/" + .id'
  yq '.group.[]' /tmp/pkgpostinstall/package.toml -oy -s '"/tmp/pkgpostinstall/groups/" + .id'

  for group in $(ls /tmp/pkgpostinstall/groups); do
    id = $(yq '.id' /tmp/pkgpostinstall/groups/$group)
    name = $(yq '.name' /tmp/pkgpostinstall/groups/$group)

    echo "Adding group $name with id $id."

    # add the group
    echo "$id::$name:" >> ./etc/group
  done

  for user in $(ls /tmp/pkgpostinstall/users); do
    id = $(yq '.id' /tmp/pkgpostinstall/users/$user)
    gid = $(yq '.gid' /tmp/pkgpostinstall/users/$user)
    name = $(yq '.name' /tmp/pkgpostinstall/users/$user)
    login = $(yq '.login' /tmp/pkgpostinstall/users/$user)
    home = $(yq '.home' /tmp/pkgpostinstall/users/$user)
    shell = $(yq '.shell' /tmp/pkgpostinstall/users/$user)

    echo "Adding user $login with id $id and gid $gid."

    # add the user
    echo "$login:*:$id:$gid:$name:$home:$shell" >> ./etc/passwd
  done

  # cleanup
  rm -r /tmp/pkgpostinstall
done

cat ./etc/passwd
cat ./etc/group
