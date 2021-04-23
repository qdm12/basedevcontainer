#!/bin/sh

# As Windows bind mounts do not allow the container to chmod files
# and SSH requires your keys to have not too opened permissions,
# we offer the user to bind mount their SSH directory in /tmp/.ssh
# as read only which we then copy over to /root/.ssh with the right
# permissions
if [ -d "/tmp/.ssh" ]; then
  if [ -d "~/.ssh" ]; then
    echo "~/.ssh already exists, not overriding with files from /tmp/.ssh"
    exit 0
  fi
  cp -r /tmp/.ssh/ ~/.ssh/
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/*
  chmod 644 ~/.ssh/*.pub &> /dev/null
  echo "SSH files copied to ~/.ssh with correct permissions"
fi
