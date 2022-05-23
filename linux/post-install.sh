#!/usr/bin/env bash
# This script allows you to interactively post-install packages that may be required in daily work.
# Logic:
# - Detect OS (@TODO use only for ubuntu first time)
# - Install required packages (git, vim, curl)
# - Start interactive session
# - Start actions
# Questions:
# - Create user? [n]
# - Change user name? [user]
# - Use SSH? [y]
# - Change SSH port? [22]
# - Install docker? [y]
# - Install zsh [y]
# - Install oh-my-zsh [n]
# Debug:
# - docker run --name debian --rm -v `pwd`:/scripts/ -it debian /scripts/post-install.sh
# - docker run --name ubuntu --rm -v `pwd`:/scripts/ -it ubuntu /scripts/post-install.sh
OS_RELEASE=`awk -F= '/^ID/{print $2}' /etc/os-release`

QUEST_CREATE_USER=n
QUEST_CHANGE_USER_NAME=user
QUEST_SSH_USE=y
QUEST_SSH_CHANGE_PORT=22
QUEST_INSTALL_DOCKER=y
QUEST_INSTALL_ZSH=y
QUEST_INSTALL_OMZ=n

if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
  export DEBIAN_FRONTEND=noninteractive
fi

log () {
  echo "[$1]: $2"
}

function question() {
    read -p "$1 [${2}]: "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo 'y' ;;
        n|no)  echo 'n' ;;
        *) echo $2
    esac
}

function question_input() {
    read -p "$1 [${2}]: "
    if [ "$REPLY" == "" ]; then
        echo $2
    else
        echo $REPLY
    fi
}

function install_required_packages () {
  log INFO "install required packages"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    packages="git curl vim"
    $QUEST_SSH_USE && packages="$packages openssh-server openssh-client"
    $QUEST_INSTALL_DOCKER && packages="$packages ca-certificates gnupg lsb-release"
    $QUEST_INSTALL_ZSH && packages="$packages zsh"
    log DEBUG "apt install $packages"
    apt update -qqy && apt upgrade -qqy && apt install -qqy $packages
  fi
}

function create_user() {
  log INFO "create user"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "adduser ${QUEST_CHANGE_USER_NAME}"
    adduser --disabled-password --gecos "" $QUEST_CHANGE_USER_NAME
    log DEBUG "update sudoers"
    usermod -aG sudo $QUEST_CHANGE_USER_NAME
    echo "${QUEST_CHANGE_USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  fi
}

function ssh_use() {
  log INFO "install ssh"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "rsync ssh keys from root to user"
    rsync --archive --chown=${QUEST_CHANGE_USER_NAME}:${QUEST_CHANGE_USER_NAME} ~/.ssh /home/${QUEST_CHANGE_USER_NAME}
  fi
}

function ssh_change_port() {
  log INFO "change ssh port to ${QUEST_SSH_CHANGE_PORT}"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    sed -i "s/#Port 22/Port ${QUEST_SSH_CHANGE_PORT}/" /etc/ssh/sshd_config
    if [ "$OS_RELEASE" == "debian" ]; then
      service ssh restart
    elif [ "$OS_RELEASE" == "ubuntu" ]; then
      service sshd restart
    fi
  fi
}

function install_docker() {
  log INFO "install docker"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "setup docker apt repository"
    curl -fsSL https://download.docker.com/linux/${OS_RELEASE}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${OS_RELEASE} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    log DEBUG "install docker engine"
    apt update -qqy
    apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -qqy

    if [ "$QUEST_CREATE_USER" == "y" ]; then
      log DEBUG "add user to docker group"
      usermod -aG docker ${QUEST_CHANGE_USER_NAME}
    fi

    if [ -f /.dockerenv ]; then
        /etc/init.d/docker start
    else
        systemctl enable docker
        systemctl start docker
    fi
  fi
}

function install_zsh() {
  log INFO "install zsh"

  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "change sh"
    chsh --shell `which zsh` root

    if [ "$QUEST_CREATE_USER" == "y" ]; then
      chsh --shell `which zsh` $QUEST_CHANGE_USER_NAME
    fi
  fi
}

function install_omz() {
  log INFO "install oh-my-zsh"

  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "download ohmyzsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
}

log INFO "detect os release ${OS_RELEASE}"

QUEST_CREATE_USER=$(question "Create user?" $QUEST_CREATE_USER)
[ "$QUEST_CREATE_USER" == "y" ] && QUEST_CHANGE_USER_NAME=$(question_input "Change username?" $QUEST_CHANGE_USER_NAME)
QUEST_SSH_USE=$(question "Use SSH?" $QUEST_SSH_USE)
[ "$QUEST_SSH_USE" == "y" ] && QUEST_SSH_CHANGE_PORT=$(question_input "Change SSH port?" $QUEST_SSH_CHANGE_PORT)
QUEST_INSTALL_DOCKER=$(question "Install docker?" $QUEST_INSTALL_DOCKER)
QUEST_INSTALL_ZSH=$(question "Install zsh?" $QUEST_INSTALL_ZSH)
[ "$QUEST_INSTALL_ZSH" == "y" ] && QUEST_INSTALL_OMZ=$(question "Install oh-my-zsh?" $QUEST_INSTALL_OMZ)

install_required_packages

[ "$QUEST_CREATE_USER" == "y" ] && create_user
[ "$QUEST_SSH_USE" == "y" ] && ssh_use
[ "$QUEST_SSH_USE" == "y" ] && [ "$QUEST_SSH_CHANGE_PORT" != "22" ] && ssh_change_port
[ "$QUEST_INSTALL_DOCKER" == "y" ] && install_docker
[ "$QUEST_INSTALL_ZSH" == "y" ] && install_zsh
[ "$QUEST_INSTALL_ZSH" == "y" ] && [ "$QUEST_INSTALL_OMZ" == "y" ] && install_omz
