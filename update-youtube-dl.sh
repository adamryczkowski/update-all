#!/bin/bash

if ! which youtube-dl >/dev/null; then
    exit 0 #No youtube-dl
fi

loc=$(which youtube-dl)

if [[ "${loc}" == "/usr/local/bin/youtube-dl" ]]; then
    sudo youtube-dl -U
fi
