#!/bin/bash
# If atuin is not present - exit

if ! command -v atuin >/dev/null; then
  exit 0
fi

atuin sync
