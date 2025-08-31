#!/bin/bash
if command -v rustup >/dev/null; then
	rustup update
fi

if ! command -v cargo >/dev/null; then
	exit 0
fi
echo "Updating rust-installed packages..."
cargo install cargo-update
cargo install-update -a
