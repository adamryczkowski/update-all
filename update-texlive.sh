#!/bin/sh
if ! which tlmgr >/dev/null; then
	exit 0
fi

sudo tlmgr update --self
sudo tlmgr update --all
