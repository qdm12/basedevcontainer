ZSH=/HOMEPATH/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
plugins=(vscode git colorize docker docker-compose)

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

# Fixing permission on Docker socket
if [ ! -z $DOCKERSOCK_OK ]; then
  DOCKERSOCK_USER=`stat -c "%u" /var/run/docker.sock`
  DOCKERSOCK_GROUP=`stat -c "%g" /var/run/docker.sock`
  if [ "$DOCKERSOCK_GROUP" != "1000" ] && [ "$DOCKERSOCK_GROUP" != "102" ] && [ "$DOCKERSOCK_GROUP" != "976" ]; then
    echo "Docker socket not owned by group IDs 1000, 102 or 976, changing its group to `id -g`"
    sudo chown $DOCKERSOCK_USER:`id -g` /var/run/docker.sock
    sudo chmod 770 /var/run/docker.sock
  fi
fi

echo
echo "Base version: $BASE_VERSION"
echo "Running as `whoami`"
where code &> /dev/null && echo "VS code server `code -v | head -n 1`"
if [ ! -z $DOCKERSOCK_OK ]; then
  echo "Docker server `docker version --format {{.Server.Version}}` | client `docker version --format {{.Client.Version}}`"
  echo "Docker-Compose `docker compose version | cut -d' ' -f 4`"
  alias alpine='docker run -it --rm alpine:3.20'
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

[ -f ~/.zshrc-specific.sh ] && source ~/.zshrc-specific
