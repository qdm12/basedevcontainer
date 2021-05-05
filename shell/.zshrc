ZSH=/root/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
plugins=(vscode git colorize docker docker-compose)
source $ZSH/oh-my-zsh.sh
source ~/.p10k.zsh
# TODO Ascii art

[ -f ~/.windows.sh ] && source ~/.windows.sh

# SSH key check
list="$(ls -al ~/.ssh)"
[ "$?" = 0 ] && SSHRSA_OK=yes
[ -z $SSHRSA_OK ] && >&2 echo "[WARNING] No id_rsa SSH private key found, SSH functionalities might not work"

# Timezone check
[ -z $TZ ] && >&2 echo "[WARNING] TZ environment variable not set, time might be wrong!"

# Docker check
test -S /var/run/docker.sock
[ "$?" = 0 ] && DOCKERSOCK_OK=yes
[ -z $DOCKERSOCK_OK ] && >&2 echo "[WARNING] Docker socket not found, docker will not be available"

echo
echo "Base version: $BASE_VERSION"
where code &> /dev/null && echo "VS code server `code -v | head -n 1`"
if [ ! -z $DOCKERSOCK_OK ]; then
  echo "Docker server `docker version --format {{.Server.Version}}` | client `docker version --format {{.Client.Version}}`"
  echo "Docker-Compose `docker-compose version --short`"
  alias alpine='docker run -it --rm alpine:3.13'
fi
echo
[ -f ~/.zshrc-specific.sh ] && source ~/.zshrc-specific
[ -f ~/.welcome.sh ] && source ~/.welcome.sh
