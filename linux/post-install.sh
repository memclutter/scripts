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
    log DEBUG "apt install git curl vim"
    apt update -qqy && apt upgrade -qqy && apt install -qqy git curl vim
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
    log DEBUG "apt install openssh-server openssh-client"
    apt install -qqy openssh-server openssh-client
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
    log DEBUG "install requirements for $OS_RELEASE"
    apt install -qqy ca-certificates gnupg lsb-release

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
}

function install_omz() {
  log INFO "install oh-my-zsh"
}

log INFO "detect os release ${OS_RELEASE}"

install_required_packages

QUEST_CREATE_USER=$(question "Create user?" $QUEST_CREATE_USER)
QUEST_CHANGE_USER_NAME=$(question_input "Change username?" $QUEST_CHANGE_USER_NAME)
QUEST_SSH_USE=$(question "Use SSH?" $QUEST_SSH_USE)
QUEST_SSH_CHANGE_PORT=$(question_input "Change SSH port?" $QUEST_SSH_CHANGE_PORT)
QUEST_INSTALL_DOCKER=$(question "Install docker?" $QUEST_INSTALL_DOCKER)
QUEST_INSTALL_ZSH=$(question "Install zsh?" $QUEST_INSTALL_ZSH)
QUEST_INSTALL_OMZ=$(question "Install oh-my-zsh?" $QUEST_INSTALL_OMZ)

if [ "$QUEST_CREATE_USER" == "y" ]; then
  create_user
fi

if [ "$QUEST_SSH_USE" == "y" ]; then
  ssh_use

  if [ "$QUEST_SSH_CHANGE_PORT" != "22" ]; then
    ssh_change_port
  fi
fi

if [ "$QUEST_INSTALL_DOCKER" == "y" ]; then
  install_docker
fi

if [ "$QUEST_INSTALL_ZSH" == "y" ]; then
  install_zsh
fi

if [ "$QUEST_INSTALL_OMZ" == "y" ]; then
  install_omz
fi
