#!/bin/bash
if command -v npm >/dev/null; then
    pushd ~ >/dev/null || exit 0
    sudo npm update -g
    popd >/dev/null || true
fi
