#!/bin/bash

if which conda >/dev/null; then
   pushd $(dirname $(which conda))
   conda update conda -n base --yes
   conda update conda-build -n base --yes
   str=$(conda env list | grep -E '^[^ ]+ *\*? */.*$' | grep -Eo '^[^ ]+')
   readarray -t myenvs <<< "${str}"
   for myenv in "${myenvs[@]}"; do
      conda update -n ${myenv} --all --yes
   done
   conda clean --yes --all
   popd
fi

