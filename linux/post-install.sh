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
