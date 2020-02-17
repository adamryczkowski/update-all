#!/bin/bash

function pull_spack {
   local trydir=$1/spack
   if [[ -d $trydir ]]; then
      pushd $trydir >/dev/null
      git pull
   fi
}


function get_home_dir {
	if [ -n "$1" ]; then
		local USER=$1
	fi
	echo $( getent passwd "$USER" | cut -d: -f6 )
}

if ! which git >/dev/null; then
   exit 0
fi

pull_spack /opt
pull_spack $(get_home_dir)
pull_spack $(get_home_dir)/tmp
