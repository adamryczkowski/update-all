#!/bin/bash

if [ ! $(which julia) >/dev/null ]; then
	exit 0
fi

julia_path=$(readlink $(which julia))

pattern='^(.*)\/([^\/]+)\/bin\/julia$'
if [[ $julia_path =~ $pattern ]]; then
	julia_path="${BASH_REMATCH[1]}"
else
	exit 1
fi

if [ $(which jill >/dev/null) ]; then
	pip install jill
fi

if [ $(which jill >/dev/null) ]; then
	exit 1
fi

jill install --upgrade -i "$julia_path" --confirm

