#!/bin/bash

pull_spack() {
   local trydir="$1/spack"
   if [[ -d "$trydir" ]]; then
      pushd "$trydir" >/dev/null || return 0
      git pull --ff-only
      popd >/dev/null || true
   fi
}

get_home_dir() {
	local u
	u=${1:-$USER}
	getent passwd "$u" | cut -d: -f6
}

if ! command -v git >/dev/null; then
   exit 0
fi

pull_spack /opt
pull_spack "$(get_home_dir "$USER")"
pull_spack "$(get_home_dir "$USER")"/tmp
