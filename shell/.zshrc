ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
# Caches must live in each account's own home: root's shell setup is symlinked from this one,
# and would otherwise rewrite the unprivileged account's cache files.
ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
# The image makes every directory group-writable so the package manager works without root, which
# makes zsh's compaudit consider them insecure and drop them from fpath when running as root.
# The layout is deliberate, so skip that check.
ZSH_DISABLE_COMPFIX=true
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
# Plugins are read by oh-my-zsh when it loads, at the bottom of this file, so a consumer image can
# drop a ~/.zshrc-plugins file to change the list (e.g. plugins=($plugins golang)) before that load.
plugins=(vscode git colorize docker docker-compose)
[ -f ~/.zshrc-plugins ] && source ~/.zshrc-plugins
unsetopt HIST_SAVE_BY_COPY # Tell zsh to write directly to the file

# TODO Ascii art

[ -f ~/.ssh.sh ] && source ~/.ssh.sh

# SSH directory check
[ -d ~/.ssh ] ||  >&2 echo "[WARNING] No SSH directory found, SSH functionalities might not work"

# Timezone check
[ -z $TZ ] && >&2 echo "[WARNING] TZ environment variable not set, time might be wrong!"

# Docker check
test -S /var/run/docker.sock
[ "$?" = 0 ] && DOCKERSOCK_OK=yes
[ -z $DOCKERSOCK_OK ] && >&2 echo "[WARNING] Docker socket not found, docker will not be available"

# Running as root: the shell setup is symlinked from the unprivileged account's home
[ "$(id -u)" = 0 ] && echo "Running as root"
echo
echo "Base version: $BASE_VERSION"
where code &> /dev/null && echo "VS code server `code -v | head -n 1`"
if [ ! -z $DOCKERSOCK_OK ]; then
  echo "Docker server `docker version --format {{.Server.Version}}` | client `docker version --format {{.Client.Version}}`"
  echo "Docker-Compose `docker compose version | cut -d' ' -f 4`"
  alias alpine='docker run -it --rm alpine:3.24'
fi
echo

[ -f ~/.welcome.sh ] && source ~/.welcome.sh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source $ZSH/oh-my-zsh.sh
source ~/.p10k.zsh

[ -f ~/.zshrc-specific ] && source ~/.zshrc-specific
