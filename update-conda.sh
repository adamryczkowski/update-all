#!/bin/bash

if command -v conda >/dev/null; then
   conda_bin=$(command -v conda)
   conda_dir=$(dirname "$conda_bin")
   pushd "$conda_dir" >/dev/null || exit 0
   conda update conda -n base --yes
   conda update conda-build -n base --yes
   str=$(conda env list | grep -E '^[^ ]+ *\*? */.*$' | grep -Eo '^[^ ]+')
   readarray -t myenvs <<< "${str}"
   for myenv in "${myenvs[@]}"; do
      conda update -n "${myenv}" --all --yes
   done
   conda clean --yes --all
   popd >/dev/null || true
fi
