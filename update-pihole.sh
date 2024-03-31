#!/bin/bash

if ! which pihole >/dev/null; then
    exit 0 #No youtube-dl
fi

pihole updatePihole


