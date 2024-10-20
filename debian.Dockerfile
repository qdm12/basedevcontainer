ARG DEBIAN_VERSION=12-slim

ARG DOCKER_VERSION=v27.3.1
ARG COMPOSE_VERSION=v2.29.7
ARG BUILDX_VERSION=v0.17.1
ARG LOGOLS_VERSION=v1.3.7
ARG BIT_VERSION=v1.1.2
ARG GH_VERSION=v2.58.0
ARG DEVTAINR_VERSION=v0.6.0

FROM qmcgaw/binpot:docker-${DOCKER_VERSION} AS docker
FROM qmcgaw/binpot:compose-${COMPOSE_VERSION} AS compose
FROM qmcgaw/binpot:buildx-${BUILDX_VERSION} AS buildx
FROM qmcgaw/binpot:logo-ls-${LOGOLS_VERSION} AS logo-ls
FROM qmcgaw/binpot:bit-${BIT_VERSION} AS bit
FROM qmcgaw/binpot:gh-${GH_VERSION} AS gh
FROM qmcgaw/devtainr:${DEVTAINR_VERSION} AS devtainr

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
ARG USER_UID=1000
ARG USER_GID=1000

# CA certificates
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -r /var/cache/* /var/lib/apt/lists/*

# Timezone
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends tzdata && \
    rm -r /var/cache/* /var/lib/apt/lists/*
ENV TZ=

# Setup non root user with sudo access
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends sudo && \
    rm -r /var/cache/* /var/lib/apt/lists/*
WORKDIR /home/user
RUN addgroup --gid $USER_GID user && \
    useradd user --shell /bin/sh --create-home --uid $USER_UID --gid $USER_GID && \
    mkdir -p /etc/sudoers.d && \
    echo user ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user && \
    rm /var/log/faillog /var/log/lastlog

# Setup Git and SSH
# Workaround for older Debian in order to be able to sign commits
RUN echo "deb https://deb.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends -t bookworm git git-man && \
    rm -r /var/cache/* /var/lib/apt/lists/*
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends man openssh-client less && \
    rm -r /var/cache/* /var/lib/apt/lists/*
COPY --chown=0:0 .ssh.sh /root/
RUN chmod +x /root/.ssh.sh && \
    cp /root/.ssh.sh /home/user/.ssh.sh && \
    chown ${USER_UID}:${USER_GID} /home/user/.ssh.sh && \
    # Retro-compatibility symlinks
    ln -s /root/.ssh.sh /root/.windows.sh && \
    ln -s /home/user/.ssh.sh /home/user/.windows.sh

# Setup shell for root and user
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
RUN usermod --shell /bin/zsh user && \
    usermod --shell /bin/zsh root

COPY --chown=${USER_UID}:${USER_GID} shell/.zshrc shell/.welcome.sh /home/user/
RUN cp /home/user/.zshrc /root/.zshrc && \
    cp /home/user/.welcome.sh /root/.welcome.sh && \
    chown 0:0 /root/.zshrc /root/.welcome.sh && \
    sed -i "s/HOMEPATH/home\/user/" /home/user/.zshrc && \
    sed -i "s/HOMEPATH/root/" /root/.zshrc
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /home/user/.oh-my-zsh && \
    chown ${USER_UID}:${USER_GID} -R /home/user/.oh-my-zsh && \
    cp -r /home/user/.oh-my-zsh /root/.oh-my-zsh && \
    chown 0:0 -R /root/.oh-my-zsh

ARG POWERLEVEL10K_VERSION=v1.16.1
COPY shell/.p10k.zsh /home/user/
RUN ln -s /home/user/.p10k.zsh /root/.p10k.zsh && \
    git clone --branch ${POWERLEVEL10K_VERSION} --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git /home/user/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf /home/user/.oh-my-zsh/custom/themes/powerlevel10k/.git && \
    chown -R ${USER_UID}:${USER_GID} /home/user/.oh-my-zsh/custom/themes/powerlevel10k && \
    ln -s /home/user/.oh-my-zsh/custom/themes/powerlevel10k /root/.oh-my-zsh/custom/themes/powerlevel10k

# Docker CLI
COPY --from=docker /bin /usr/local/bin/docker
ENV DOCKER_BUILDKIT=1
# All possible docker host groups
RUN G102=`getent group 102 | cut -d":" -f 1` && \
    G976=`getent group 976 | cut -d":" -f 1` && \
    G1000=`getent group 1000 | cut -d":" -f 1` && \
    if [ -z $G102 ]; then G102=docker102; addgroup --gid 102 $G102; fi && \
    if [ -z $G976 ]; then G976=docker976; addgroup --gid 976 $G976; fi && \
    if [ -z $G1000 ]; then G1000=docker1000; addgroup --gid 1000 $G1000; fi && \
    usermod -a -G $G102 user && \
    usermod -a -G $G976 user && \
    usermod -a -G $G1000 user

# Docker compose
COPY --from=compose --chown=${USER_UID}:${USER_GID} /bin /usr/libexec/docker/cli-plugins/docker-compose
ENV COMPOSE_DOCKER_CLI_BUILD=1
RUN echo "alias docker-compose='docker compose'" >> /home/user/.zshrc && \
    echo "alias docker-compose='docker compose'" >> /root/.zshrc

# Buildx plugin
COPY --from=buildx --chown=${USER_UID}:${USER_GID} /bin /usr/libexec/docker/cli-plugins/docker-buildx

# Logo ls
COPY --from=logo-ls --chown=${USER_UID}:${USER_GID} /bin /usr/local/bin/logo-ls
RUN echo "alias ls='logo-ls'" >> /home/user/.zshrc && \
    echo "alias ls='logo-ls'" >> /root/.zshrc

# Bit
COPY --from=bit --chown=${USER_UID}:${USER_GID} /bin /usr/local/bin/bit
ARG TARGETPLATFORM
RUN if [ "${TARGETPLATFORM}" != "linux/s390x" ]; then echo "y" | bit complete; fi

COPY --from=gh --chown=${USER_UID}:${USER_GID} /bin /usr/local/bin/gh

COPY --from=devtainr --chown=${USER_UID}:${USER_GID} /devtainr /usr/local/bin/devtainr

USER user
