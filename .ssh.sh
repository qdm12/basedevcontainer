#!/bin/sh

if [ -d ~/.ssh ]; then
  if echo "$(mountpoint ~/.ssh)" | grep -q "is a mountpoint"; then
    # ~/.ssh is a bind mount from the host
    return 0;
  fi
  if [ -d /mnt/ssh ] && [ -z "$(comm -3 <(/bin/ls -a /mnt/ssh) <(/bin/ls -a ~/.ssh))" ]; then
    # /mnt/ssh and ~/.ssh are the same in terms of file names.
    return 0;
  fi
  if [ -d /tmp/.ssh ] && [ -z "$(comm -3 <(/bin/ls -a /tmp/.ssh) <(/bin/ls -a ~/.ssh))" ]; then
    # Retro-compatibility: /tmp/.ssh and ~/.ssh are the same in terms of file names.
    return 0;
  fi
fi

if [ -d /tmp/.ssh ]; then
  # Retro-compatibility
  echo "Copying content of /tmp/.ssh to ~/.ssh"
  mkdir -p ~/.ssh
  cp -r /tmp/.ssh/* ~/.ssh/
  chmod 600 ~/.ssh/*
  chmod 644 ~/.ssh/*.pub &> /dev/null
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
cp -rf /mnt/ssh/* ~/.ssh/
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub &> /dev/null
