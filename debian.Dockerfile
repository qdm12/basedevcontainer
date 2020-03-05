ARG DEBIAN_VERSION=stretch-slim
ARG DOCKER_VERSION=19.03.6
ARG DOCKER_COMPOSE_VERSION=debian-1.25.4

FROM docker:${DOCKER_VERSION} AS docker-cli
FROM docker/compose:${DOCKER_COMPOSE_VERSION} AS docker-compose

FROM debian:${DEBIAN_VERSION}
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=local
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.url="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.documentation="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.source="https://github.com/qdm12/basedevcontainer" \
    org.opencontainers.image.title="Base Dev container Debian" \
    org.opencontainers.image.description="Base Debian development container for Visual Studio Code Remote Containers development"
WORKDIR /home/${USERNAME}
ENTRYPOINT [ "/bin/zsh" ]
ENV TZ=
# Setup user
RUN addgroup --gid $USER_GID $USERNAME && \
    useradd $USERNAME --shell /bin/sh --create-home --uid $USER_UID --gid $USER_GID && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    rm /var/log/faillog /var/log/lastlog
# Install Debian packages
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends zsh sudo ca-certificates git openssh-client nano curl tzdata htop && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -r /var/cache/* /var/lib/apt/lists/*
COPY --from=docker-cli --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-compose --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker-compose /usr/local/bin/docker-compose
ENV DOCKER_BUILDKIT=1
# All possible docker host groups
RUN G102=`getent group 102 | cut -d":" -f 1` && \
    G976=`getent group 976 | cut -d":" -f 1` && \
    G1000=`getent group 1000 | cut -d":" -f 1` && \
    if [ -z $G102 ]; then G102=docker102; addgroup --gid 102 $G102; fi && \
    if [ -z $G976 ]; then G976=docker976; addgroup --gid 976 $G976; fi && \
    if [ -z $G1000 ]; then G1000=docker1000; addgroup --gid 1000 $G1000; fi && \
    echo 2222 && \
    addgroup ${USERNAME} $G102 && \
    addgroup ${USERNAME} $G976 && \
    addgroup ${USERNAME} $G1000
# Setup shells
ENV EDITOR=nano \
    TERM=xterm
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends locales && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8 && \
    apt-get purge -y locales && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -r /var/cache/* /var/lib/apt/lists/*
RUN usermod --shell /bin/zsh root && \
    usermod --shell /bin/zsh ${USERNAME}
COPY --chown=${USER_UID}:${USER_GID} shell/.p10k.zsh shell/.zshrc shell/.welcome.sh /home/${USERNAME}/
RUN ln -s /home/${USERNAME}/.p10k.zsh /root/.p10k.zsh && \
    cp /home/${USERNAME}/.zshrc /root/.zshrc && \
    cp /home/${USERNAME}/.welcome.sh /root/.welcome.sh && \
    sed -i "s/HOMEPATH/home\/${USERNAME}/" /home/${USERNAME}/.zshrc && \
    sed -i "s/HOMEPATH/root/" /root/.zshrc
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /home/${USERNAME}/.oh-my-zsh && \
    git clone --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k/.git && \
    chown -R ${USERNAME}:${USER_GID} /home/${USERNAME} && \
    chmod -R 700 /home/${USERNAME} && \
    cp -r /home/${USERNAME}/.oh-my-zsh /root/.oh-my-zsh && \
    chown -R root:root /root/.oh-my-zsh
USER ${USERNAME}