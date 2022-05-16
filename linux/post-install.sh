#!/usr/bin/env bash
# This script allows you to interactively post-install packages that may be required in daily work.
# Logic:
# - Detect OS (@TODO use only for ubuntu first time)
# - Install required packages (git, vim, curl)
# - Start interactive session
# - Start actions
# Questions:
# - Create user? [n]
# - Install docker? [y]
# - Install docker-compose? [y]
# - Install zsh [y]
# - Install oh-my-zsh [n]
# Debug:
# - docker run --name debian --rm -v `pwd`:/scripts/ -it debian /scripts/post-install.sh
# - docker run --name ubuntu --rm -v `pwd`:/scripts/ -it ubuntu /scripts/post-install.sh
OS_RELEASE=`awk -F= '/^ID/{print $2}' /etc/os-release`

QUEST_CREATE_USER=n
QUEST_SSH_USE=y
QUEST_SSH_CHANGE_PORT=n
QUEST_INSTALL_DOCKER=y
QUEST_INSTALL_DOCKER_COMPOSE=y
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
    log DEBUG "adduser"
    adduser --disabled-password --gecos "" ubuntu
    log DEBUG "update sudoers"
    usermod -aG sudo ubuntu
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  fi
}

function ssh_use() {
  log INFO "install ssh"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "apt install openssh-server openssh-client"
    apt install -qqy openssh-server openssh-client
  fi
}

function ssh_change_port() {
  log INFO "change ssh port to 2222"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    sed -i "s/#Port 22/Port 2222/" /etc/ssh/sshd_config
    if [ "$OS_RELEASE" == "debian" ]; then
      service ssh restart
    elif [ "$OS_RELEASE" == "ubuntu" ]; then
      service sshd restart
    fi
  fi
}

function install_docker() {
  log INFO "install docker"
}

function install_docker_compose() {
  log INFO "install docker compose"
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
QUEST_SSH_USE=$(question "Use SSH?" $QUEST_SSH_USE)
QUEST_SSH_CHANGE_PORT=$(question "Change SSH port to 2222?" $QUEST_SSH_CHANGE_PORT)
QUEST_INSTALL_DOCKER=$(question "Install docker?" $QUEST_INSTALL_DOCKER)
QUEST_INSTALL_DOCKER_COMPOSE=$(question "Install docker-compose?" $QUEST_INSTALL_DOCKER_COMPOSE)
QUEST_INSTALL_ZSH=$(question "Install zsh?" $QUEST_INSTALL_ZSH)
QUEST_INSTALL_OMZ=$(question "Install oh-my-zsh?" $QUEST_INSTALL_OMZ)

if [ "$QUEST_CREATE_USER" == "y" ]; then
  create_user
fi

if [ "$QUEST_SSH_USE" == "y" ]; then
  ssh_use

  if [ "$QUEST_SSH_CHANGE_PORT" == "y" ]; then
    ssh_change_port
  fi
fi

if [ "$QUEST_INSTALL_DOCKER" == "y" ]; then
  install_docker
fi

if [ "$QUEST_INSTALL_DOCKER_COMPOSE" == "y" ]; then
  install_docker_compose
fi

if [ "$QUEST_INSTALL_ZSH" == "y" ]; then
  install_zsh
fi

if [ "$QUEST_INSTALL_OMZ" == "y" ]; then
  install_omz
fi
