# Base Dev Container

Base Ubuntu development container for Visual Studio Code, used as base image by other images.

Forked from [qdm12/basedevcontainer](https://github.com/qdm12/basedevcontainer)

<!-- TODO: Add badges for tests -->

[![GitHub last commit](https://img.shields.io/github/last-commit/mkell43/basedevcontainer.svg)](https://github.com/mkell43/basedevcontainer/commits/main)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/mkell43/basedevcontainer.svg)](https://github.com/mkell43/basedevcontainer/graphs/contributors)
[![GitHub closed PRs](https://img.shields.io/github/issues-pr-closed/mkell43/basedevcontainer.svg)](https://github.com/mkell43/basedevcontainer/pulls?q=is%3Apr+is%3Aclosed)
[![GitHub issues](https://img.shields.io/github/issues/mkell43/basedevcontainer.svg)](https://github.com/mkell43/basedevcontainer/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/mkell43/basedevcontainer.svg)](https://github.com/mkell43/basedevcontainer/issues?q=is%3Aissue+is%3Aclosed)

[![MIT](https://img.shields.io/github/license/mkell43/basedevcontainer)](https://github.com/mkell43/basedevcontainer/main/LICENSE)

## Features

- `qmcgaw/basedevcontainer:alpine` (or `:latest`) based on Alpine 3.16 in **209MB**
- `qmcgaw/basedevcontainer:debian` based on Debian Buster Slim in **376MB**
- All images are compatible with `amd64`, `386`, `arm64`, `armv7`, `armv6` and `ppc64le` CPU architectures
- Contains the packages:
  - `libstdc++`: needed by the VS code server
  - `zsh`: main shell instead of `/bin/sh`
  - `git`: interact with Git repositories
  - `openssh-client`: use SSH keys
  - `nano`: edit files from the terminal
- Contains the binaries:
  - [`gh`](https://github.com/cli/cli): interact with Github with the terminal
  - `docker`
  - `docker-compose` and `docker compose` docker plugin
  - [`docker buildx`](https://github.com/docker/buildx) docker plugin
  - [`bit`](https://github.com/chriswalz/bit)
  - [`devtainr`](https://github.com/qdm12/devtainr)
- Custom integrated terminal
  - Based on zsh and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
  - Uses the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
  - With [Logo LS](https://github.com/Yash-Handa/logo-ls) as a replacement for `ls`
    - Shows information on login; easily extensible
- Cross platform
  - Easily bind mount your SSH keys to use with **git**
  - Manage your host Docker from within the dev container on Linux, MacOS and Windows
- Docker uses buildkit by default, with the latest Docker client binary.
- Extensible with docker-compose.yml
- Supports SSH keys with Windows (Hyperv) bind mounts at /tmp/.ssh

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop) installed and running
  - If you don't use Linux, share the directories `~/.ssh` and the directory of your project with Docker Desktop
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- [VS code](https://code.visualstudio.com/download) installed
- [VS code remote containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed

## Setup for a project

1. Download this repository and put the `.devcontainer` directory in your project.
   Alternatively, use this shell script from your project path

    ```sh
    # we assume you are in /yourpath/myproject
    mkdir .devcontainer
    cd .devcontainer
    wget -q https://raw.githubusercontent.com/mkell43/basedevcontainer/main/.devcontainer/devcontainer.json
    wget -q https://raw.githubusercontent.com/mkell43/basedevcontainer/main/.devcontainer/docker-compose.yml
    ```

1. If you have a *.vscode/settings.json*, eventually move the settings to *.devcontainer/devcontainer.json* in the `"settings"` section as *.vscode/settings.json* take precedence over the settings defined in *.devcontainer/devcontainer.json*.
1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P) and select `Remote-Containers: Open Folder in Container...` and choose your project directory

## More

### devcontainer.json

- You can change the `"postCreateCommand"` to be relevant to your situation. In example it could be `echo "downloading" && npm i` to combine two commands
- You can change the extensions installed in the Docker image within the `"extensions"` array
- VScode settings can be changed or added in the `"settings"` object.

### docker-compose.yml

- You can publish a port to access it from your host
- Add containers to be launched with your development container. In example, let's add a postgres database.
    1. Add this block to `.devcontainer/docker-compose.yml`

        ```yml
          database:
            image: postgres
            restart: always
            environment:
              POSTGRES_PASSWORD: password
        ```

    1. In `.devcontainer/devcontainer.json` change the line `"runServices": ["vscode"],` to `"runServices": ["vscode", "database"],`
    1. In the VS code command palette, rebuild the container

### Development image

You can build and extend the Docker development image to suit your needs.

- You can build the development image yourself:

    ```sh
    docker build -t qmcgaw/basedevcontainer -f alpine.Dockerfile  https://github.com/mkell43/basedevcontainer.git
    ```

- You can extend the Docker image `qmcgaw/basedevcontainer` with your own instructions.

    1. Create a file `.devcontainer/Dockerfile` with `FROM qmcgaw/basedevcontainer`
    1. Append instructions to the Dockerfile created. For example:
        - Add more Go packages and add an alias

            ```Dockerfile
            FROM qmcgaw/basedevcontainer
            COPY . .
            RUN echo "alias ls='ls -al'" >> ~/.zshrc
            ```

        - Add some Alpine packages, you will need to switch to `root`:

            ```Dockerfile
            FROM qmcgaw/basedevcontainer
            USER root
            RUN apk add bind-tools
            USER vscode
            ```

    1. Modify `.devcontainer/docker-compose.yml` and add `build: .` in the vscode service.
    1. Open the VS code command palette and choose `Remote-Containers: Rebuild container`

- You can bind mount a file at `/home/vscode/.welcome.sh` to modify the welcome message (use `/root/.welcome.sh` for `root`)

## TODO

- [ ] `bit complete` yes flag
- [ ] Firewall, see [this](https://code.visualstudio.com/docs/remote/containers#_what-are-the-connectivity-requirements-for-the-vs-code-server-when-it-is-running-in-a-container)
- [ ] Extend another docker-compose.yml
- [ ] Fonts for host OS for the VS code shell
- [ ] Gifs and images
- [ ] Install VS code server and extensions in image, waiting for [this issue](https://github.com/microsoft/vscode-remote-release/issues/1718)
