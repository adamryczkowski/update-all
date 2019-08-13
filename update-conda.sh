#!/bin/bash

if [ ! $(which conda >/dev/null) ]; then
   conda update conda --yes
   conda env list | grep -E '^[^ ]+ *\*? */.*$' | grep -Eo '^[^ ]+' | readarray -t
   for myenv in "${MAPFILE[@]}"; do
      conda update -n myenv --all --yes
   done
   conda clean --yes --all
fi

