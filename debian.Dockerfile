ARG DEBIAN_VERSION=13-slim

ARG DOCKER_VERSION=v29.8.1
ARG COMPOSE_VERSION=v5.5.1
ARG BUILDX_VERSION=v0.37.1
ARG LOGOLS_VERSION=v1.3.7
ARG BIT_VERSION=v1.1.2
ARG GH_VERSION=v2.102.0
ARG DEVTAINR_VERSION=v0.7.0

FROM ghcr.io/qdm12/binpot:docker-${DOCKER_VERSION} AS docker
FROM ghcr.io/qdm12/binpot:compose-${COMPOSE_VERSION} AS compose
FROM ghcr.io/qdm12/binpot:buildx-${BUILDX_VERSION} AS buildx
FROM ghcr.io/qdm12/binpot:logo-ls-${LOGOLS_VERSION} AS logo-ls
FROM ghcr.io/qdm12/binpot:bit-${BIT_VERSION} AS bit
FROM ghcr.io/qdm12/binpot:gh-${GH_VERSION} AS gh
FROM ghcr.io/qdm12/devtainr:${DEVTAINR_VERSION} AS devtainr

FROM debian:${DEBIAN_VERSION}
ARG CREATED
ARG COMMIT
ARG VERSION=local
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$CREATED \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.url="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.documentation="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.source="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.title="Base Dev container Debian" \
    org.opencontainers.image.description="Base Debian development container for Visual Studio Code Dev Containers development"
ENV BASE_VERSION="${VERSION}-${CREATED}-${COMMIT}"

# CA certificates
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -r /var/cache/* /var/lib/apt/lists/*

# Timezone
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends tzdata && \
    rm -r /var/cache/* /var/lib/apt/lists/*
ENV TZ=

# Unprivileged user the container runs as.
ARG USERNAME=user
ARG GROUP_NAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_HOME=/home/${USERNAME}
# Group ID of the `docker` group on the host, needed to reach a rootful engine's
# /var/run/docker.sock. If left empty, the group is not created.
# Alternatively, a dockerd socket can be reached without rebuilding by passing
# --group-add=$(stat -c %g /var/run/docker.sock) to the container.
ARG DOCKER_GID=
RUN set -eux && \
    groupadd -g "${USER_GID}" "${GROUP_NAME}" && \
    useradd -u "${USER_UID}" -g "${GROUP_NAME}" -m -d "${USER_HOME}" -s /bin/zsh "${USERNAME}" && \
    if [ -n "${DOCKER_GID}" ] && ! grep -q "^docker:" /etc/group; then \
    groupadd -g "${DOCKER_GID}" docker && \
    usermod -aG docker "${USERNAME}"; \
    fi && \
    # Pre-created so bind mounts of ~/.ssh/* and ~/.config/* into it do not create
    # root-owned directories the user cannot write into
    mkdir -p "${USER_HOME}/.ssh" "${USER_HOME}/.config/containers" && \
    chown "${USER_UID}:${USER_GID}" "${USER_HOME}" "${USER_HOME}/.ssh" "${USER_HOME}/.config" "${USER_HOME}/.config/containers" && \
    chmod 755 "${USER_HOME}" "${USER_HOME}/.config" "${USER_HOME}/.config/containers" && \
    chmod 700 "${USER_HOME}/.ssh"

# Setup Git and SSH and GPG
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git git-man man openssh-client less gpg && \
    rm -r /var/cache/* /var/lib/apt/lists/*
COPY --chown="${USER_UID}:${USER_GID}" --chmod=755 .ssh.sh ${USER_HOME}/

# Setup shell for root and ${USERNAME}
ENTRYPOINT [ "/bin/zsh" ]
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends zsh nano locales wget && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -r /var/cache/* /var/lib/apt/lists/*
ENV EDITOR=nano \
    LANG=en_US.UTF-8 \
    # MacOS compatibility
    TERM=xterm
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8
RUN usermod --shell /bin/zsh root

COPY --chown="${USER_UID}:${USER_GID}" shell/.zshrc shell/.welcome.sh ${USER_HOME}/
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git "${USER_HOME}/.oh-my-zsh" && \
    chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}/.oh-my-zsh"

# Powerlevel10k prompt theme, and its configuration
ARG POWERLEVEL10K_VERSION=v1.20.0
RUN set -eux && \
    git clone --branch "${POWERLEVEL10K_VERSION}" --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git "${USER_HOME}/.oh-my-zsh/custom/themes/powerlevel10k" && \
    rm -rf "${USER_HOME}/.oh-my-zsh/custom/themes/powerlevel10k/.git" && \
    chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
COPY --chown="${USER_UID}:${USER_GID}" shell/.p10k.zsh ${USER_HOME}/

# Same shell setup for root as for ${USERNAME}: root's configuration is symlinked into
# ${USERNAME}'s home, so both accounts share zsh, oh-my-zsh, Powerlevel10k, the aliases added
# below, and no second copy of anything is installed.
RUN set -eux && \
    mkdir -m 700 /root/.ssh && \
    for file in .zshrc .welcome.sh .p10k.zsh .ssh.sh .oh-my-zsh; do \
    ln -s "${USER_HOME}/${file}" "/root/${file}"; \
    done

# Docker CLI
COPY --chown="${USER_UID}:${USER_GID}" --from=docker /bin /usr/local/bin/docker
ENV DOCKER_BUILDKIT=1

# Docker compose
COPY --chown="${USER_UID}:${USER_GID}" --from=compose /bin /usr/libexec/docker/cli-plugins/docker-compose
ENV COMPOSE_DOCKER_CLI_BUILD=1
RUN echo "alias docker-compose='docker compose'" >> "${USER_HOME}/.zshrc"
RUN ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Buildx plugin
COPY --chown="${USER_UID}:${USER_GID}" --from=buildx /bin /usr/libexec/docker/cli-plugins/docker-buildx

# Podman
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends podman-remote && \
    ln -sf /usr/bin/podman-remote /usr/local/bin/podman && \
    rm -r /var/cache/* /var/lib/apt/lists/*

# Logo ls
COPY --chown="${USER_UID}:${USER_GID}" --from=logo-ls /bin /usr/local/bin/logo-ls
RUN echo "alias ls='logo-ls'" >> "${USER_HOME}/.zshrc"

# Bit
COPY --chown="${USER_UID}:${USER_GID}" --from=bit /bin /usr/local/bin/bit
ARG TARGETPLATFORM
RUN if [ "${TARGETPLATFORM}" != "linux/s390x" ]; then \
    # Completion appends to the shell configuration file of the account running it, resolved
    # from /etc/passwd and not from HOME, hence the su. root gets the same completion through
    # its symlinked /root/.zshrc.
    echo y | su -s /bin/sh -c "bit complete" "${USERNAME}"; \
    fi

COPY --chown="${USER_UID}:${USER_GID}" --from=gh /bin /usr/local/bin/gh

COPY --chown="${USER_UID}:${USER_GID}" --from=devtainr /devtainr /usr/local/bin/devtainr

# dpkg refuses to unpack when it is not run by root unless told otherwise; with
# force-not-root its maintainer scripts run as the calling user and their root-only
# steps fail softly.
# The rest is write access for package management: apt/dpkg state, plus every
# directory a package may create or remove files in. Existing files keep their root
# ownership, so they stay read-only for ${USERNAME}.
RUN set -eux && \
    # /var/cache/man is deleted by the cleanup of every apt layer, and man-db's trigger
    # recreates it with `install -d -o man -g man`, which only root can do: create it here
    # so the check in its script skips that chown, otherwise every apt install fails.
    mkdir -p /etc/dpkg/dpkg.cfg.d /var/log/apt /var/cache/debconf /var/cache/man /var/lib/man-db /run/lock && \
    printf 'force-not-root\n' > /etc/dpkg/dpkg.cfg.d/99-nonroot && \
    for path in /etc/apt /etc/alternatives /etc/dpkg /var/lib/apt /var/cache/apt /var/lib/dpkg /var/cache/debconf /var/cache/man /var/lib/man-db /var/log /run/lock; do \
    if [ -e "${path}" ]; then chown -R "${USER_UID}:${USER_GID}" "${path}"; fi; \
    done && \
    # ldconfig rewrites this one on every install, and it is owned by root otherwise
    if [ -e /etc/ld.so.cache ]; then chown "${USER_UID}:${USER_GID}" /etc/ld.so.cache; fi && \
    # ${USER_HOME} is not in the list below: it already belongs to ${USERNAME}, and making it
    # group-writable would loosen ${USER_HOME}/.ssh too.
    for dir in /usr /etc /var /opt /srv /run; do \
    find "${dir}" -xdev -type d -exec chgrp "${USER_GID}" {} + && \
    find "${dir}" -xdev -type d -exec chmod g+w {} +; \
    done && \
    for file in /etc/shadow /etc/gshadow; do \
    if [ -f "${file}" ]; then chmod 640 "${file}"; fi; \
    done && \
    chmod 700 /root

USER ${USERNAME}
WORKDIR ${USER_HOME}
