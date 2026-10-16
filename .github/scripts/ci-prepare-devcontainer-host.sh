#!/bin/sh
# Create the host-side files the devcontainer.json bind mounts point at, so that
# `devcontainer up` can run on a machine (a CI runner) which has none of them.
# Mirrors the requirements documented in .devcontainer/README.md.
#
# Existing files are never modified nor replaced, and directories are only created
# when missing, so it is safe to run against a real home directory too.
#
# Logs go to stderr. When an SSH agent is started, the line
# 'SSH_AUTH_SOCK=<path>' is printed on stdout, ready to be appended to $GITHUB_ENV.

set -eu

if [ ! -d "$HOME" ]; then
    echo "$HOME is not a directory, refusing to create mock files in it" >&2
    exit 1
fi

for file in \
    .gitconfig \
    .zsh_history \
    AGENTS.md \
    .ssh/known_hosts \
    .ssh/id_ed25519.pub \
    .ssh/allowed_signers; do
    if [ -e "$HOME/$file" ]; then
        echo "present  $HOME/$file" >&2
        continue
    fi
    directory=$(dirname "$file")
    if [ "$directory" != "." ]; then
        mkdir -p "$HOME/$directory"
    fi
    # Empty files: the container reads them as an absent configuration
    : >"$HOME/$file"
    echo "created  $HOME/$file" >&2
done

# The container registry configuration cannot be empty: podman reads it as a
# credentials file and fails any pull with 'reading JSON file ... unexpected end
# of JSON input' when it parses as nothing. A zero-length file is treated as
# unset because it carries no configuration to preserve.
auth_file=$HOME/.config/containers/auth.json
if [ -s "$auth_file" ]; then
    echo "present  $auth_file" >&2
else
    mkdir -p "$(dirname "$auth_file")"
    printf '{"auths":{}}\n' >"$auth_file"
    echo "created  $auth_file" >&2
fi

# The SSH agent socket has to be a real socket, not an empty file.
if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
    echo "present  $SSH_AUTH_SOCK" >&2
elif command -v ssh-agent >/dev/null 2>&1; then
    agent_socket="$HOME/ssh-agent.sock"
    ssh-agent -a "$agent_socket" >/dev/null
    echo "created  $agent_socket" >&2
    echo "SSH_AUTH_SOCK=$agent_socket"
else
    echo "ssh-agent is not available and SSH_AUTH_SOCK is not a socket: the bind mount would fail" >&2
    exit 1
fi
