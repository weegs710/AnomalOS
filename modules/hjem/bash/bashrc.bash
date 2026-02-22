#!/usr/bin/env bash

# Exit early for non-interactive shells
[[ $- != *i* ]] && return

# Hand-off to nushell early if that's the intent
# Checks prevent recursion and provide escape hatch via BASH_NO_NU
if [[ -z "$NUSHELL" && -z "$BASH_NO_NU" ]] &&
   [[ "$(ps -o comm= -p "$PPID" 2>/dev/null)" != "nu" ]] &&
   command -v nu >/dev/null 2>&1 &&
   [[ -t 0 && -t 1 ]]; then
  export NUSHELL=1
  exec nu
fi

# Source system bashrc for NixOS environment and aliases
if [[ -r /etc/bashrc ]]; then
  . /etc/bashrc
fi
