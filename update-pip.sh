#!/bin/bash
if which pip; then
    sudo -H pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H pip install -U
fi 

if which bedup; then
	sudo bedup dedup
fi

