# Base Dev Container

**Base Alpine development container for Visual Studio Code, used as base image by other images**

[![basedevcontainer](https://github.com/qdm12/basedevcontainer/raw/master/title.png)](https://hub.docker.com/r/qmcgaw/basedevcontainer)

[![Build Status](https://travis-ci.org/qdm12/basedevcontainer.svg?branch=master)](https://travis-ci.org/qdm12/basedevcontainer)
[![Docker Pulls](https://img.shields.io/docker/pulls/qmcgaw/basedevcontainer.svg)](https://hub.docker.com/r/qmcgaw/basedevcontainer)
[![Docker Stars](https://img.shields.io/docker/stars/qmcgaw/basedevcontainer.svg)](https://hub.docker.com/r/qmcgaw/basedevcontainer)
[![Image size](https://images.microbadger.com/badges/image/qmcgaw/basedevcontainer.svg)](https://microbadger.com/images/qmcgaw/basedevcontainer)
[![Image version](https://images.microbadger.com/badges/version/qmcgaw/basedevcontainer.svg)](https://microbadger.com/images/qmcgaw/basedevcontainer)

[![Join Slack channel](https://img.shields.io/badge/slack-@qdm12-yellow.svg?logo=slack)](https://join.slack.com/t/qdm12/shared_invite/enQtOTE0NjcxNTM1ODc5LTYyZmVlOTM3MGI4ZWU0YmJkMjUxNmQ4ODQ2OTAwYzMxMTlhY2Q1MWQyOWUyNjc2ODliNjFjMDUxNWNmNzk5MDk)
[![GitHub last commit](https://img.shields.io/github/last-commit/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/issues)
[![GitHub issues](https://img.shields.io/github/issues/qdm12/basedevcontainer.svg)](https://github.com/qdm12/basedevcontainer/issues)

## Features

- Based on Alpine 3.11 with the packages:
    - `libstdc++`: needed by the VS code server
    - `zsh`: main shell instead of `/bin/sh`
    - `sudo`: run commands as root if needed
    - `git`: interact with Git repositories
    - `openssh-client`: use SSH keys
    - `nano`: edit files from the terminal
    - `curl`: do HTTP requests
    - `hub`: interact with Github like a god
- Custom integrated terminal
    - Based on zsh and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
    - Uses the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
    - Shows information on login; easily extensible
- Cross platform
    - Easily bind mount your SSH keys to use with **git**
    - Manage your host Docker from within the dev container on Linux, MacOS and Windows
- Docker uses buildkit by default, with the latest Docker client binary.
- Runs without root as `vscode` user but you can run Docker without sudo and can use sudo if needed
- 'Minimal' size of **?MB**
- Extensible with docker-compose.yml
- Compatible with `amd64`, `arm/v8` and `arm/v7`

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
    wget -q https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/devcontainer.json
    wget -q https://raw.githubusercontent.com/qdm12/basedevcontainer/master/.devcontainer/docker-compose.yml
    ```

1. If you have a *.vscode/settings.json*, eventually move the settings to *.devcontainer/devcontainer.json* in the `"settings"` section as *.vscode/settings.json* take precedence over the settings defined in *.devcontainer/devcontainer.json*.
1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P) and select `Remote-Containers: Open Folder in Container...` and choose your project directory

## More

### devcontainer.json

- You can change the `"postCreateCommand"` to be relevant to your situation. In example it could be `go mod download && gofmt ./...` to combine two commands
- You can change the extensions installed in the Docker image within the `"extensions"` array
- Other Go settings can be changed or added in the `"settings"` object.

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
    docker build -t qmcgaw/godevcontainer https://github.com/qdm12/godevcontainer.git
    ```

- You can extend the Docker image `qmcgaw/godevcontainer` with your own instructions.

    1. Create a file `.devcontainer/Dockerfile` with `FROM qmcgaw/godevcontainer`
    1. Append instructions to the Dockerfile created. For example:
        - Add more Go packages and add an alias

            ```Dockerfile
            FROM qmcgaw/godevcontainer
            RUN go get -v honnef.co/go/tools/...
            RUN echo "alias ls='ls -al'" >> ~/.zshrc
            ```

        - Add some Alpine packages, you will need to switch to `root`:

            ```Dockerfile
            FROM qmcgaw/godevcontainer
            USER root
            apk add curl
            USER vscode
            ```

    1. Modify `.devcontainer/docker-compose.yml` and add `build: .` in the vscode service.
    1. Open the VS code command palette and choose `Remote-Containers: Rebuild container`

- You can bind mount a file at `/home/vscode/.welcome.sh` to modify the welcome message (use `/root/.welcome.sh` for `root`)

# TODO

- [ ] Firewall, see [this](https://code.visualstudio.com/docs/remote/containers#_what-are-the-connectivity-requirements-for-the-vs-code-server-when-it-is-running-in-a-container)
- [ ] Extend another docker-compose.yml
- [ ] Fonts for host OS for the VS code shell
- [ ] Gifs and images
- [ ] Install VS code server and extensions in image, waiting for [this issue](https://github.com/microsoft/vscode-remote-release/issues/1718)

## License

This repository is under an [MIT license](https://github.com/qdm12/basedevcontainer/master/LICENSE) unless indicated otherwise.
