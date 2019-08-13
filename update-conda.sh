#!/bin/bash

if [ ! $(which conda >/dev/null) ]; then
   conda update conda --yes
   local str=$(conda env list | grep -E '^[^ ]+ *\*? */.*$' | grep -Eo '^[^ ]+')
   readarray -t myenvs <<< "${str}"
   for myenv in "${myenvs[@]}"; do
      conda update -n myenv --all --yes
   done
   conda clean --yes --all
fi

