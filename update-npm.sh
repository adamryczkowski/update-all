#!/bin/bash
if which npm; then
    pushd ~
    sudo npm update -g
    popd
fi

