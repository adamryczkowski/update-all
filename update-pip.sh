#!/bin/bash
if which pip2; then
    sudo -H pip2 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H pip2 install -U
fi 
if which pip3; then
    sudo -H pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H pip3 install -U
fi 

if which bedup; then
	sudo bedup dedup
fi

