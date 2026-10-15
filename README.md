# Base Dev Container

Base Alpine development container for Visual Studio Code, used as base image by other images

<img height="300" src="https://raw.githubusercontent.com/qdm12/basedevcontainer/master/title.svg">

[![Alpine](https://github.com/qdm12/basedevcontainer/actions/workflows/alpine.yml/badge.svg)](https://github.com/qdm12/basedevcontainer/actions/workflows/alpine.yml)
[![Debian](https://github.com/qdm12/basedevcontainer/actions/workflows/debian.yml/badge.svg)](https://github.com/qdm12/basedevcontainer/actions/workflows/debian.yml)

![Last release](https://img.shields.io/github/release/qdm12/basedevcontainer?label=Last%20release)
![Last Docker tag](https://img.shields.io/docker/v/qmcgaw/basedevcontainer?sort=semver&label=Last%20Docker%20tag)
[![Last release size](https://img.shields.io/docker/image-size/qmcgaw/basedevcontainer?sort=semver&label=Last%20released%20image)](https://hub.docker.com/r/qmcgaw/basedevcontainer/tags?page=1&ordering=last_updated)
![GitHub last release date](https://img.shields.io/github/release-date/qdm12/basedevcontainer?label=Last%20release%20date)
![Commits since release](https://img.shields.io/github/commits-since/qdm12/basedevcontainer/latest?sort=semver)

[![Latest size](https://img.shields.io/docker/image-size/qmcgaw/basedevcontainer/latest?label=Latest%20image)](https://hub.docker.com/r/qmcgaw/basedevcontainer/tags)

[![GitHub last commit](https://img.shields.io/github/last-commit/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/commits/master)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/graphs/contributors)
[![GitHub closed PRs](https://img.shields.io/github/issues-pr-closed/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/pulls?q=is%3Apr+is%3Aclosed)
[![GitHub issues](https://img.shields.io/github/issues/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/issues?q=is%3Aissue+is%3Aclosed)

[![MIT](https://img.shields.io/github/license/qdm12/basedevcontainer)](https://github.com/qdm12/basedevcontainer/master/LICENSE)
![Visitors count](https://visitor-badge.laobi.icu/badge?page_id=basedevcontainer.readme)

## Features

- `ghcr.io/qdm12/basedevcontainer:alpine` (or `:latest`) based on Alpine 3.24 in **250MB**
- `ghcr.io/qdm12/basedevcontainer:debian` based on Debian Trixie Slim in **438MB**
- All images are compatible with `amd64`, `386`, `arm64`, `armv7`, `armv6` and `ppc64le` CPU architectures
- Contains the packages:
  - `libstdc++`: needed by the VS code server
  - `zsh`: main shell instead of `/bin/sh`
  - `git`: interact with Git repositories
  - `openssh-client`: use SSH keys
  - `nano`: edit files from the terminal
- Contains the binaries:
  - [`gh`](https://github.com/cli/cli): interact with Github with the terminal
  - `docker`, `podman-remote` (aliased as `podman`)
  - `docker-compose` and `docker compose` docker plugin
  - [`docker buildx`](https://github.com/docker/buildx) docker plugin
  - [`bit`](https://github.com/chriswalz/bit)
  - [`devtainr`](https://github.com/qdm12/devtainr)
- Custom integrated terminal
  - Based on zsh and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
  - Uses the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
  - With [Logo LS](https://github.com/Yash-Handa/logo-ls) as a replacement for `ls`
    - Shows information on login; easily extensible
- Runs as an unprivileged user (`user`, uid/gid `1000` by default, configurable), see [Non-root user](#non-root-user)
  - `apk` (Alpine) and `apt-get` (Debian) install packages from that user, no sudo involved
- Cross platform
  - Use the host SSH agent or bind mount your SSH keys
  - Manage your host Docker from within the dev container on Linux, MacOS and Windows
- Docker uses buildkit by default, with the latest Docker client binary.
- Compatible with both the Docker and Podman engines
- Extensible with docker-compose.yml
- Supports SSH keys with Linux, OSX and Windows

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop) or [Podman](https://podman.io/getting-started/installation) installed and running
  - If you use OSX, share the directory `~/.ssh` and the directory of your project with Docker Desktop
- [VS code](https://code.visualstudio.com/download) installed
- [VS code dev containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed

## Setup for a project

1. Download this repository and put the `.devcontainer` directory in your project.
   Alternatively, use this shell script from your project path

    ```sh
    # we assume you are in /yourpath/myproject
    mkdir -p .devcontainer/docker .devcontainer/podman
    wget -qO .devcontainer/README.md https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/README.md
    wget -qO .devcontainer/.dockerignore https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/.dockerignore
    wget -qO .devcontainer/Dockerfile https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/Dockerfile
    wget -qO .devcontainer/docker/devcontainer.json https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/docker/devcontainer.json
    wget -qO .devcontainer/podman/devcontainer.json https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/podman/devcontainer.json
    ```

1. If you have a *.vscode/settings.json*, eventually move the settings to *`.devcontainer/*/devcontainer.json`* in the `"settings"` section as *.vscode/settings.json* take precedence over the settings defined in *.devcontainer/devcontainer.json*.
1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P) and select `Dev Containers: Open Folder in Container...` and choose your project directory

## Non-root user

The image runs using an unprivileged account `user`.

💁 In case you need root access, see [the root user section](#root-user)

The non root user is configurable with container build arguments, defined both in Dockerfiles and in devcontainer.json files:

| Build argument | Default | Description |
| --- | --- | --- |
| `USERNAME` | `user` | account name, home is `/home/$USERNAME`. Update the `"remoteUser"` key and mount targets in `devcontainer.json` to match this one if changed. |
| `GROUP_NAME` | `user` | name of the account's primary group |
| `USER_UID` | `1000` | user ID of the account |
| `USER_GID` | `1000` | group ID of the account's primary group (`$GROUP_NAME`) |
| `DOCKER_GID` | | create a `docker` group with this GID and put the account in it, to reach a rootful engine's socket, see [Container engine socket](#container-engine-socket) |

The unprivileged account:

- owns its home, and the state directories of the package manager, so it can install and remove packages without `sudo` or `doas`
- can write to a directory a package may add or remove a file in (`/usr/local/bin`, `/etc/ssl/certs`, `/var/log`...), which all belong to `$GROUP_NAME` and are group-writable.
- can only read and execute files installed in the container image and setup by the container engine
- cannot read `/root` and `/etc/shadow`

On system package management, note:

- it cannot replace a file the image already has installed, since those keep their root ownership
- for the Debian container, some packages have maintainer scripts that insist on running as root, and will fail to install (i.e. `dbus`); the fix is to finish the job as root for example `docker exec --user root <container-name> sh -c 'apt-get install -y dbus && dpkg --configure -a'`

## Root user

If you need to run a command as root, exec in the container using for example

```sh
docker exec --user root <container-name> command
```

Root has the same terminal setup as the unprivileged account, given all the configuration files are symlinked into `/home/user`.
Note however that by default the zsh historyand ssh files are not symlinked or copied from the unprivileged user to root.
The shell prints `Running as root` at startup, so you always know which account a terminal belongs to.

## More

### devcontainer.json

- You can change the `"postCreateCommand"` to be relevant to your situation. In example it could be `echo "downloading" && npm i` to combine two commands
- You can change the extensions installed in the Docker image within the `"extensions"` array
- VScode settings can be changed or added in the `"settings"` object.

### docker-compose.yml

You can create a `.devcontainer/docker-compose.yml` to create the devcontainer and other containers at the same time:

```yml
services:
  vscode: # configured in devcontainer.json
    build: .
  postgres: # example of a database container
    image: postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: password
```

And change the following in your relevant `devcontainer.json`:

- remove `"build": { "dockerfile": "../Dockerfile" },`
- add `"dockerComposeFile": "../docker-compose.yml",`
- add `"overrideCommand": true,`
- add `"service": "vscode",`
- add `"runServices": ["vscode", "postgres"],`

Finally, open the command palette in Visual Studio Code (CTRL+SHIFT+P) and select `Dev-Containers: Rebuild Container`

### Development image

You can build and extend the Docker development image to suit your needs.

- You can build the development image yourself:

    ```sh
    docker build -t ghcr.io/qdm12/basedevcontainer -f alpine.Dockerfile  https://github.com/qdm12/basedevcontainer.git
    ```

- You can extend the Docker image `ghcr.io/qdm12/basedevcontainer` with your own instructions.

    1. Modify the `.devcontainer/Dockerfile` by appending instructions. For example to add Alpine packages:

        ```Dockerfile
        FROM ghcr.io/qdm12/basedevcontainer
        RUN apk add bind-tools
        ```

       Use `USER root` before instructions that do need root, and `USER user` to give it back.

    1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P)
    1. Select `Dev-Containers: Rebuild Container`

- You can bind mount a file at `/home/user/.welcome.sh` to modify the welcome message.

### SSH keys

You can either use an SSH agent (preferred, more secure) or bind mount your `~/.ssh` directory at `/mnt/ssh`, or not use SSH at all. See the [.devcontainer/README.md#SSH-keys](.devcontainer/README.md) for more information.

## TODO

- [ ] `bit complete` yes flag
- [ ] Firewall, see [this](https://code.visualstudio.com/docs/remote/containers#_what-are-the-connectivity-requirements-for-the-vs-code-server-when-it-is-running-in-a-container)
- [ ] Extend another docker-compose.yml
- [ ] Fonts for host OS for the VS code shell
- [ ] Gifs and images
- [ ] Install VS code server and extensions in image, waiting for [this issue](https://github.com/microsoft/vscode-remote-release/issues/1718)
