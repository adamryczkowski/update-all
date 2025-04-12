#!/bin/bash

if [ ! $(which julia) >/dev/null ]; then
	exit 0
fi

julia_path=$(readlink -f $(which julia))

pattern='^(.*)\/([^\/]+)\/bin\/julia$'
if [[ $julia_path =~ $pattern ]]; then
	julia_path="${BASH_REMATCH[1]}"
else
	exit 1
fi

if ! which juliaup >/dev/null; then
	if which cargo >/dev/null; then 
		cargo install juliaup
	fi
fi

if which juliaup >/dev/null; then
	juliaup update
fi


# Upgrade all packages in the default environment
julia -e 'using Pkg; Pkg.update()'
