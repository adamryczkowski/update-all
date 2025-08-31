#!/bin/bash

# Checks if the host is disabled/enabled in /etc/hosts and toggles snap API accordingly,
# or acts as a library when called with argument "lib".

function add_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	if ! grep -qE "(^|\s)${host}(\s|$)" /etc/hosts; then
		echo "$HOSTS_LINE" | sudo tee -a /etc/hosts >/dev/null
	fi
}

function is_host_disabled {
  # Checks if the host is disabled, mapped to 127.0.0.1
  local host=$1
  local pattern="^\s*127\.0\.0\.1\s+${host}(\s|$)"
  if grep -E "$pattern" /etc/hosts >/dev/null; then
    echo "1"
  else
    echo "0"
  fi
}

function disable_host {
	local host=$1
	local ip=$2
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} # replace . into \.
	if grep -E "$pattern" /etc/hosts >/dev/null; then # element is already added
	   local on_pattern=" *# *${ip} +${host}"
   	if grep -E "$on_pattern" /etc/hosts >/dev/null; then # element is not already turned on
   	   sudo sed -i -r "s/${pattern}/${ip} ${host}/g" /etc/hosts
   	fi
	else
	   add_host "$host" "$ip"
	fi
}

function enable_host {
	local host=$1
	local ip=$2
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} # replace . into \.
	if ! grep -E "$pattern" /etc/hosts >/dev/null; then # element is not added yet
	   add_host "$host" "$ip"
	fi
  local on_pattern=" *# *${ip} +${host}"
	if ! grep -E "$on_pattern" /etc/hosts >/dev/null; then # element is not already turned on
	   sudo sed -i -r "s/${pattern}/# ${ip} ${host}/g" /etc/hosts
	fi
}

# If arg1 == "lib" we are doing nothing - just adding the functions

if [ "$1" != "lib" ]; then

  if command -v snap >/dev/null; then
    host_is_disabled=$(is_host_disabled api.snapcraft.io)
    if [ "$host_is_disabled" = "1" ]; then
      echo "Enabling api.snapcraft.io..."
      enable_host api.snapcraft.io 127.0.0.1
    fi
    echo "Refreshing snaps..."
    sudo snap refresh
    echo "Removing old snaps..."
    set -eu
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read -r snapname revision; do
      sudo snap remove "$snapname" --revision="$revision"
    done

    if [ "$host_is_disabled" = "1" ]; then
      echo "Disabling back api.snapcraft.io..."
      disable_host api.snapcraft.io 127.0.0.1
    fi
  fi

fi
