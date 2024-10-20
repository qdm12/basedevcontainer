# Base Dev Container

Base Alpine development container for Visual Studio Code, used as base image by other images

<img height="300" src="https://raw.githubusercontent.com/qdm12/basedevcontainer/master/title.svg">

[![Alpine](https://github.com/qdm12/basedevcontainer/actions/workflows/alpine.yml/badge.svg)](https://github.com/qdm12/basedevcontainer/actions/workflows/alpine.yml)
[![Debian](https://github.com/qdm12/basedevcontainer/actions/workflows/debian.yml/badge.svg)](https://github.com/qdm12/basedevcontainer/actions/workflows/debian.yml)

[![dockeri.co](https://dockeri.co/image/qmcgaw/basedevcontainer)](https://hub.docker.com/r/qmcgaw/basedevcontainer)

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

[![Lines of code](https://img.shields.io/tokei/lines/github/qdm12/basedevcontainer)](https://github.com/qdm12/basedevcontainer)
![Code size](https://img.shields.io/github/languages/code-size/qdm12/basedevcontainer)
![GitHub repo size](https://img.shields.io/github/repo-size/qdm12/basedevcontainer)

[![MIT](https://img.shields.io/github/license/qdm12/basedevcontainer)](https://github.com/qdm12/basedevcontainer/master/LICENSE)
![Visitors count](https://visitor-badge.laobi.icu/badge?page_id=basedevcontainer.readme)

## Features

- `qmcgaw/basedevcontainer:alpine` (or `:latest`) based on Alpine 3.20 in **230MB**
- `qmcgaw/basedevcontainer:debian` based on Debian Buster Slim in **376MB**
- All images are compatible with `amd64`, `386`, `arm64`, `armv7`, `armv6` and `ppc64le` CPU architectures
- Contains the packages:
  - `libstdc++`: needed by the VS code server
  - `zsh`: main shell instead of `/bin/sh`
  - `sudo`: run commands as root if needed
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
- Supports SSH keys with Linux, OSX and Windows
- Runs without root as `user` (uid 1000 and gid 1000) user but you can run Docker without sudo and can use sudo if needed

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop) installed and running
  - If you use OSX, share the directory `~/.ssh` and the directory of your project with Docker Desktop
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- [VS code](https://code.visualstudio.com/download) installed
- [VS code dev containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed

## Setup for a project

1. Download this repository and put the `.devcontainer` directory in your project.
   Alternatively, use this shell script from your project path

    ```sh
    # we assume you are in /yourpath/myproject
    mkdir .devcontainer
    cd .devcontainer
    wget -q https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/devcontainer.json
    wget -q https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/docker-compose.yml
    ```

1. If you have a *.vscode/settings.json*, eventually move the settings to *.devcontainer/devcontainer.json* in the `"settings"` section as *.vscode/settings.json* take precedence over the settings defined in *.devcontainer/devcontainer.json*.
1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P) and select `Dev Containers: Open Folder in Container...` and choose your project directory

## More

### devcontainer.json

- You can change the `"postCreateCommand"` to be relevant to your situation. In example it could be `echo "downloading" && npm i` to combine two commands
- You can change the extensions installed in the Docker image within the `"extensions"` array
- VScode settings can be changed or added in the `"settings"` object.

### docker-compose.yml

- Add containers to be launched with your development container. In example, let's add a postgres database.
    1. Add this block to `.devcontainer/docker-compose.yml`

        ```yml
          database:
            image: postgres
            restart: always
            environment:
              POSTGRES_PASSWORD: password
        ```

    1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P)
    1. Select `Dev-Containers: Rebuild Container`

### Development image

You can build and extend the Docker development image to suit your needs.

- You can build the development image yourself:

    ```sh
    docker build -t qmcgaw/basedevcontainer -f alpine.Dockerfile  https://github.com/qdm12/basedevcontainer.git
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
            USER user
            ```

    1. Modify `.devcontainer/docker-compose.yml` and add `build: .` in the vscode service.
    1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P)
    1. Select `Dev-Containers: Rebuild Container`

- You can bind mount a file at `/home/user/.welcome.sh` to modify the welcome message (use `/root/.welcome.sh` for `root`)

## TODO

- [ ] `bit complete` yes flag
- [ ] Firewall, see [this](https://code.visualstudio.com/docs/remote/containers#_what-are-the-connectivity-requirements-for-the-vs-code-server-when-it-is-running-in-a-container)
- [ ] Extend another docker-compose.yml
- [ ] Fonts for host OS for the VS code shell
- [ ] Gifs and images
- [ ] Install VS code server and extensions in image, waiting for [this issue](https://github.com/microsoft/vscode-remote-release/issues/1718)
