ARG UBUNTU_VERSION=22.04

ARG DOCKER_VERSION=v20.10.17
ARG COMPOSE_VERSION=v2.6.1
ARG BUILDX_VERSION=v0.8.2
ARG LOGOLS_VERSION=v1.3.7
ARG BIT_VERSION=v1.1.2
ARG GH_VERSION=v2.14.1
ARG DEVTAINR_VERSION=v0.6.0

FROM qmcgaw/binpot:docker-${DOCKER_VERSION} AS docker
FROM qmcgaw/binpot:compose-${COMPOSE_VERSION} AS compose
FROM qmcgaw/binpot:buildx-${BUILDX_VERSION} AS buildx
FROM qmcgaw/binpot:logo-ls-${LOGOLS_VERSION} AS logo-ls
FROM qmcgaw/binpot:bit-${BIT_VERSION} AS bit
FROM qmcgaw/binpot:gh-${GH_VERSION} AS gh
FROM qmcgaw/devtainr:${DEVTAINR_VERSION} AS devtainr

FROM ubuntu:${UBUNTU_VERSION}
ARG CREATED
ARG COMMIT
ARG VERSION=local
LABEL \
  org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
  org.opencontainers.image.created=$CREATED \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$COMMIT \
  org.opencontainers.image.url="https://github.com/mkell43/basedevcontainer" \
  org.opencontainers.image.documentation="https://github.com/mkell43/basedevcontainer" \
  org.opencontainers.image.source="https://github.com/mkell43/basedevcontainer" \
  org.opencontainers.image.title="Base Dev container Ubuntu" \
  org.opencontainers.image.description="Base Ubuntu development container for Visual Studio Code Remote Containers development"
ENV BASE_VERSION="${VERSION}-${CREATED}-${COMMIT}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# CA certificates
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends ca-certificates && \
  rm -r /var/cache/* /var/lib/apt/lists/*

# Timezone
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends tzdata && \
  rm -r /var/cache/* /var/lib/apt/lists/*
ENV TZ=

# Setup Git and SSH
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends git git-man man openssh-client less && \
  rm -r /var/cache/* /var/lib/apt/lists/*

# Add a non-root user to the container image
# Credit:
#   - https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
#   - https://web.archive.org/web/20220624145403/https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
ARG USER_NAME="developer"
ARG USER_ID
ARG GROUP_ID
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
  if getent passwd ${USER_NAME} ; then userdel -f ${USER_NAME}; fi &&\
  # userdel -f ${USER_NAME} &&\
  if getent group ${USER_NAME} ; then groupdel ${USER_NAME}; fi &&\
  groupadd -g ${GROUP_ID} ${USER_NAME} &&\
  useradd -l -u ${USER_ID} -g ${USER_NAME} ${USER_NAME} &&\
  install -d -m 0755 -o ${USER_NAME} -g ${USER_NAME} /home/${USER_NAME} \
  ;fi
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends sudo && \
  rm -r /var/cache/* /var/lib/apt/lists/* && \
  usermod -a -G sudo ${USER_NAME}

# Windows compat for adding SSH keys
# See comments in the file for more information
COPY .windows.sh /home/${USER_NAME}
RUN chmod +x /home/${USER_NAME}/.windows.sh

# Setup shell
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
RUN usermod --shell /bin/zsh ${USER_NAME}

USER ${USER_NAME}

RUN git config --global advice.detachedHead false

COPY shell/.zshrc shell/.welcome.sh /home/${USER_NAME}/
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

ARG POWERLEVEL10K_VERSION=v1.16.1
COPY shell/.p10k.zsh /home/${USER_NAME}/
RUN git clone --branch ${POWERLEVEL10K_VERSION} --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k && \
  rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k/.git

RUN git config --global advice.detachedHead true

USER root

# Docker CLI
COPY --from=docker /bin /usr/local/bin/docker
RUN chmod 755 /usr/local/bin/docker
ENV DOCKER_BUILDKIT=1

# Docker compose
COPY --from=compose /bin /usr/libexec/docker/cli-plugins/docker-compose
RUN chmod 755 /usr/libexec/docker/cli-plugins/docker-compose
ENV COMPOSE_DOCKER_CLI_BUILD=1
RUN echo "alias docker-compose='docker compose'" >> /home/${USER_NAME}/.zshrc

# Buildx plugin
COPY --from=buildx /bin /usr/libexec/docker/cli-plugins/docker-buildx
RUN chmod 755 /usr/libexec/docker/cli-plugins/docker-buildx

# Logo ls
COPY --from=logo-ls /bin /usr/local/bin/logo-ls
RUN chmod 755 /usr/local/bin/logo-ls && \
  echo "alias ls='logo-ls'" >> /home/${USER_NAME}/.zshrc

# Bit
COPY --from=bit /bin /usr/local/bin/bit
RUN chmod 755 /usr/local/bin/bit
ARG TARGETPLATFORM
RUN if [ "${TARGETPLATFORM}" != "linux/s390x" ]; then echo "y" | bit complete; fi

COPY --from=gh /bin /usr/local/bin/gh
RUN chmod 755 /usr/local/bin/gh

COPY --from=devtainr /devtainr /usr/local/bin/devtainr
RUN chmod 755 /usr/local/bin/devtainr

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}/
