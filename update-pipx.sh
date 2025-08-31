#!/bin/bash

if ! command -v pipx >/dev/null; then
	exit 0
fi

echo "Updating pipx-installed packages..."
pipx upgrade-all
