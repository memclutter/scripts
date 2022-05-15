#!/usr/bin/env bash
# This script allows you to interactively post-install packages that may be required in daily work.
# Logic:
# - Detect OS (@TODO use only for ubuntu first time)
# - Install required packages (git, vim, curl)
# - Start interactive session
# - Start actions
# Questions:
# - Create user? [no]
# - Install docker? [yes]
# - Install docker-compose? [yes]
# - Install zsh [yes]
# - Install oh-my-zsh [no]
OS_RELEASE=`awk -F= '/^ID/{print $2}' /etc/os-release`

log () {
  echo "[$1]: $2"
}

install_required_packages () {
  log INFO "install required packages"
  if [ "$OS_RELEASE" == "ubuntu" ] || [ "$OS_RELEASE" == "debian" ]; then
    log DEBUG "apt install git curl vim"
    apt update -qqy && apt upgrade -qqy && apt install -qqy git curl vim
  fi
}

log INFO "detect os release ${OS_RELEASE}"

install_required_packages
