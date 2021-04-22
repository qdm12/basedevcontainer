ARG ALPINE_VERSION=3.13
ARG DOCKER_VERSION=20.10.6
ARG DOCKER_COMPOSE_VERSION=alpine-1.29.1
ARG GOLANG_VERSION=1.16

FROM docker:${DOCKER_VERSION} AS docker-cli
FROM docker/compose:${DOCKER_COMPOSE_VERSION} AS docker-compose

FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS gobuilder
RUN apk add --no-cache --update -q git make
ENV CGO_ENABLED=0
WORKDIR /githubcli
ARG GITHUBCLI_VERSION=v1.9.2
RUN git clone --branch ${GITHUBCLI_VERSION} --single-branch --depth 1 https://github.com/cli/cli.git .
RUN make && \
    chmod 500 bin/gh

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

COPY shell/.zshrc shell/.welcome.sh /root/
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh 2>&1

ARG POWERLEVEL10K_VERSION=v1.14.6
COPY shell/.p10k.zsh /root/
RUN git clone --branch ${POWERLEVEL10K_VERSION} --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k 2>&1 && \
    rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k/.git

ARG ZSHAUTOCOMPLETE_VERSION=21.04.13
RUN git clone --branch ${ZSHAUTOCOMPLETE_VERSION} --single-branch --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.oh-my-zsh/custom/plugins/zsh-autocomplete 2>&1 && \
    rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autocomplete/.git

ARG LOGO_LS_VERSION=1.3.7
RUN wget -qO- "https://github.com/Yash-Handa/logo-ls/releases/download/v$LOGO_LS_VERSION/logo-ls_Linux_x86_64.tar.gz" | \
    tar -xzC /usr/local/bin --strip-components=1 logo-ls_Linux_x86_64/logo-ls && \
    chmod 500 /usr/local/bin/logo-ls && \
    echo "alias ls='logo-ls'" >> /root/.zshrc

# Docker and docker-compose
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
ENV DOCKER_BUILDKIT=1 \
    COMPOSE_DOCKER_CLI_BUILD=1

# Bit
ARG BIT_VERSION=1.1.1
RUN wget -qO- https://github.com/chriswalz/bit/releases/download/v${BIT_VERSION}/bit_${BIT_VERSION}_linux_amd64.tar.gz | \
    tar -xzC /usr/local/bin bit && \
    echo "y" | bit complete

# Github CLI
COPY --from=gobuilder /githubcli/bin/gh /usr/local/bin/gh

# VSCode specific (speed up setup)
RUN apk add -q --update --progress --no-cache libstdc++
