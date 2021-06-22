ARG ALPINE_VERSION=3.13

ARG BUILDPLATFORM=linux/amd64

ARG GO_VERSION=1.16
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS gobuilder
ENV CGO_ENABLED=0
RUN apk add --no-cache git && \
    git config --global advice.detachedHead false
COPY --from=qmcgaw/xcputranslate:v0.6.0 /xcputranslate /usr/local/bin/xcputranslate
WORKDIR /tmp/build
ARG TARGETPLATFORM

FROM gobuilder AS docker
WORKDIR /go/src/github.com/docker/cli
ARG DOCKER_VERSION=v20.10.7
RUN git clone --depth 1 --branch ${DOCKER_VERSION} https://github.com/docker/cli.git .
RUN GITCOMMIT="$(git rev-parse --short HEAD)" && \
    BUILDTIME="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" && \
    GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    GO111MODULE=off \
    go build -trimpath -ldflags="-s -w \
    -X 'github.com/docker/cli/cli/version.GitCommit=${GITCOMMIT}' \
    -X 'github.com/docker/cli/cli/version.BuildTime=${BUILDTIME}' \
    -X 'github.com/docker/cli/cli/version.Version=${DOCKER_VERSION}' \
    " -o /tmp/docker cmd/docker/docker.go && \
    chmod 500 /tmp/docker

FROM gobuilder AS docker-compose
ARG DOCKER_COMPOSE_PLUGIN_VERSION=v2.0.0-beta.3
RUN git clone --depth 1 --branch ${DOCKER_COMPOSE_PLUGIN_VERSION} https://github.com/docker/compose-cli.git .
RUN go mod download
RUN GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    go build -trimpath -ldflags="-s -w \
    -X 'github.com/docker/compose-cli/internal.Version=${DOCKER_COMPOSE_PLUGIN_VERSION}' \
    " -o /tmp/docker-compose && \
    chmod 500 /tmp/docker-compose

FROM gobuilder AS logo-ls
ARG LOGOLS_VERSION=v1.3.7
RUN git clone --depth 1 --branch ${LOGOLS_VERSION} https://github.com/Yash-Handa/logo-ls.git .
RUN go mod download
RUN GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    go build -trimpath -ldflags="-s -w" -o /tmp/logo-ls && \
    chmod 500 /tmp/logo-ls

FROM gobuilder AS bit
ARG BIT_VERSION=v1.1.1
RUN git clone --depth 1 --branch ${BIT_VERSION} https://github.com/chriswalz/bit.git .
RUN go mod download
RUN GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    go build -trimpath -ldflags="-s -w \
    -X 'main.version=${BIT_VERSION}' \
    " -o /tmp/bit && \
    chmod 500 /tmp/bit

FROM gobuilder AS gh
ARG GITHUBCLI_VERSION=v1.11.0
RUN git clone --depth 1 --branch ${GITHUBCLI_VERSION} https://github.com/cli/cli.git .
RUN go mod download
RUN GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    BUILD_DATE="$(date +%F)" \
    go build -trimpath -ldflags "-s -w \
    -X 'github.com/cli/cli/internal/build.Date=${BUILD_DATE}' \
    -X 'github.com/cli/cli/internal/build.Version=${GITHUBCLI_VERSION}' \
    " -o /tmp/gh ./cmd/gh && \
    chmod 500 /tmp/gh

FROM alpine:${ALPINE_VERSION}
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=local
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.url="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.documentation="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.source="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.title="Base Dev container" \
    org.opencontainers.image.description="Base Alpine development container for Visual Studio Code Remote Containers development"
ENV BASE_VERSION="${VERSION}-${BUILD_DATE}-${VCS_REF}"

# CA certificates
RUN apk add -q --update --progress --no-cache ca-certificates

# Timezone
RUN apk add -q --update --progress --no-cache tzdata
ENV TZ=

# Setup Git and SSH
RUN apk add -q --update --progress --no-cache git openssh-client
COPY .windows.sh /root/

WORKDIR /root

# Setup shell for root and ${USERNAME}
ENTRYPOINT [ "/bin/zsh" ]
RUN apk add -q --update --progress --no-cache zsh nano
ENV EDITOR=nano \
    LANG=en_US.UTF-8 \
    # MacOS compatibility
    TERM=xterm
RUN apk add -q --update --progress --no-cache shadow && \
    usermod --shell /bin/zsh root && \
    apk del shadow

RUN git config --global advice.detachedHead false

COPY shell/.zshrc shell/.welcome.sh /root/
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

ARG POWERLEVEL10K_VERSION=v1.15.0
COPY shell/.p10k.zsh /root/
RUN git clone --branch ${POWERLEVEL10K_VERSION} --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k/.git

RUN git config --global advice.detachedHead true

# Docker CLI
COPY --from=docker /tmp/docker /usr/local/bin/
ENV DOCKER_BUILDKIT=1

# Docker compose
COPY --from=docker-compose /tmp/docker-compose /usr/local/bin/
ENV COMPOSE_DOCKER_CLI_BUILD=1
RUN echo "alias docker-compose='docker compose'" >> /root/.zshrc

# Logo ls
COPY --from=logo-ls /tmp/logo-ls /usr/local/bin/
RUN echo "alias ls='logo-ls'" >> /root/.zshrc

# Bit
COPY --from=bit /tmp/bit /usr/local/bin/
RUN echo "y" | bit complete

COPY --from=gh /tmp/gh /usr/local/bin/

# VSCode specific (speed up setup)
RUN apk add -q --update --progress --no-cache libstdc++
