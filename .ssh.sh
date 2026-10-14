#!/bin/sh

copy_missing_ssh_entries() {
  source_dir="$1"

  find "$source_dir" -mindepth 1 | while IFS= read -r source_path; do
    relative_path=${source_path#"$source_dir"/}
    destination_path="$HOME/.ssh/$relative_path"

    if [ -d "$source_path" ]; then
      mkdir -p "$destination_path"
      continue
    fi

    if [ -e "$destination_path" ]; then
      continue
    fi

    mkdir -p "$(dirname "$destination_path")"
    cp -p "$source_path" "$destination_path"

    case "$destination_path" in
      *.pub)
        chmod 644 "$destination_path" 2>/dev/null
        ;;
      *)
        chmod 600 "$destination_path"
        ;;
    esac
  done
}

if [ -d ~/.ssh ]; then
  if echo "$(mountpoint ~/.ssh 2>&1)" | grep -q "is a mountpoint"; then
    # ~/.ssh is a bind mount from the host
    return 0;
  fi
  echo "$(/bin/ls -a /mnt/ssh 2>/dev/null)" > /tmp/ls_mnt_ssh
  echo "$(/bin/ls -a ~/.ssh 2>/dev/null)" > /tmp/ls_ssh
  echo "$(/bin/ls -a /tmp/.ssh 2>/dev/null)" > /tmp/ls_tmp_ssh
  if [ -d /mnt/ssh ] && [ -z "$(comm -3 /tmp/ls_mnt_ssh /tmp/ls_ssh)" ]; then
    # /mnt/ssh and ~/.ssh are the same in terms of file names.
    rm /tmp/ls_mnt_ssh
    rm /tmp/ls_ssh
    rm /tmp/ls_tmp_ssh
    return 0;
  fi
  if [ -d /tmp/.ssh ] && [ -z "$(comm -3 /tmp/ls_tmp_ssh /tmp/ls_ssh)" ]; then
    # Retro-compatibility: /tmp/.ssh and ~/.ssh are the same in terms of file names.
    rm /tmp/ls_mnt_ssh
    rm /tmp/ls_ssh
    rm /tmp/ls_tmp_ssh
    return 0;
  fi
  rm /tmp/ls_mnt_ssh
  rm /tmp/ls_ssh
  rm /tmp/ls_tmp_ssh
fi

if [ -d /tmp/.ssh ]; then
  # Retro-compatibility
  echo "Copying content of /tmp/.ssh to ~/.ssh"
  mkdir -p ~/.ssh
  copy_missing_ssh_entries /tmp/.ssh
  return 0
fi

if [ ! -d /mnt/ssh ]; then
  echo "No bind mounted ssh directory found (~/.ssh, /tmp/.ssh, /mnt/ssh), exiting"
  return 0
fi

if [ "$(stat -c '%U' /mnt/ssh)" != "UNKNOWN" ]; then
  echo "Unix host detected, symlinking /mnt/ssh to ~/.ssh"
  rm -r ~/.ssh
  ln -s /mnt/ssh ~/.ssh
  return 0
fi

echo "Windows host detected, copying content of /mnt/ssh to ~/.ssh"
mkdir -p ~/.ssh
copy_missing_ssh_entries /mnt/ssh
