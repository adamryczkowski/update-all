#!/bin/sh
if [ $(which rustup) >/dev/null ]; then
	rustup update
fi

if [ ! $(which cargo) >/dev/null ]; then
	exit 0
fi
echo "Updating rust-installed packages..."
cargo install cargo-update
cargo install-update -a
