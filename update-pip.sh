#!/bin/bash

function is_host_up {
	ping -c 1 -w 1 "$1" >/dev/null
}

function is_host_tcp_port_up {
   if is_host_up "$1"; then
      local _host=$1
      local _port=$2
      nc -zw3 "$1" "$2"
   fi
}

function get_home_dir {
	local u
	u=${1:-$USER}
	getent passwd "$u" | cut -d: -f6
}

function enable_devpi_client {
   local user=$1
   local address=$2
   local contents="[global]
index-url = http://${address}/root/pypi/+simple/
trusted-host=${address}

[search]
index = http://${address}/root/pypi/"
   local file
   file=$(get_home_dir "$user")/.pip/pip.conf
   echo "$contents" | sudo tee "$file" >/dev/null
}

function disable_devpi_client {
   local user=$1
   local file_src
   local file_dest
   file_src=$(get_home_dir "$user")/.pip/pip.conf
   file_dest=$(get_home_dir "$user")/.pip/pip.conf.bak
   if [ -e "$file_src" ]; then
      if [ -e "$file_dest" ]; then
         sudo rm "$file_dest"
      fi
      sudo mv "$file_src" "$file_dest"
   fi
}

function find_devpi_server {
   local user=$1
   local file=$2
   if [[ "$devpi_server_tried" == 1 ]]; then
      return
   fi
   devpi_server_tried=1
   file=$(get_home_dir "$user")/.pip/$file
   if ! sudo test -e "$file"; then
   	devpi_server_ip=""
   	devpi_server_port=""
   	return
   fi
	pattern='^index *= *https?://(.*):([0-9]+)/.*/$'
   phrase=$(sudo grep -rE "$pattern" "$file" | head -n 1)
   if [[ $phrase =~ $pattern ]]; then
   	devpi_server_ip=${BASH_REMATCH[1]}
   	devpi_server_port=${BASH_REMATCH[2]}
   	: "${devpi_server_port}"
	else
   	devpi_server_ip=""
   	devpi_server_port=""
	fi
}

function pip_update {
   "$1" -m pip install --upgrade pip
}

# Unused helper left for reference; prefer pip_update directly
# function run_pipupgrade { ... }

function get_devpi_server {
   find_devpi_server root pip.conf
   if [[ -z "$devpi_server_ip" ]]; then
      find_devpi_server "$USER" pip.conf
      if [[ -z "$devpi_server_ip" ]]; then
         find_devpi_server root pip.conf.bak
         if [[ -z "$devpi_server_ip" ]]; then
            find_devpi_server "$USER" pip.conf.bak
         fi
      fi
   fi
}

devpi_server_tried=0
user_update=0
if command -v pip >/dev/null; then
   python=$(command -v python2 || true)
   if [[ -n "${python}" ]]; then
		if [[ "${python}" == "/usr/bin/python2" ]]; then
		   user_update=1
		fi
		get_devpi_server 
		pip_update "$python" "$user_update"
	fi
fi
if command -v pip3 >/dev/null; then
   python=$(command -v python3)
   if [[ -n "${python}" ]]; then
		if [[ "${python}" == "/usr/bin/python3" ]]; then
		   user_update=1
		fi
		get_devpi_server 
		pip_update "$python" "$user_update"
	fi
fi
