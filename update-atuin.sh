# If steam is not present - exit

if ! which atuin; then
  exit 0
fi

atuin sync

