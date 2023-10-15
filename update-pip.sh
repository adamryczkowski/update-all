#!/bin/bash

trusted_infix=""

function is_host_up {
	ping -c 1 -w 1  $1 >/dev/null
}

function is_host_tcp_port_up {
   if is_host_up $1; then
      local host=$1
      local port=$2
      nc -zw3 $1 $2
   fi
}

function get_home_dir {
	if [ -n "$1" ]; then
		local USER=$1
	fi
	echo $( getent passwd "$USER" | cut -d: -f6 )
}

function enable_devpi_client {
   local user=$1
   local address=$2
   
   local contents="[global]
index-url = http://${address}/root/pypi/+simple/
trusted-host=${address}

[search]
index = http://${address}/root/pypi/"
   
   file=$(get_home_dir $1)/.pip/pip.conf
   echo "$contents" | sudo tee $file >/dev/null
   trusted_infix="--trusted ${address}"
}

function disable_devpi_client {
   local user=$1

   file_src=$(get_home_dir $1)/.pip/pip.conf
   file_dest=$(get_home_dir $1)/.pip/pip.conf.bak
   if [ -e file_src ]; then
      if [ -e $file_dest ]; then
         sudo rm $file_dest
      fi
      sudo mv $file_src $file_dest
   fi
}

function find_devpi_server {
   local user=$1
   local file=$2
   if [[ "$devpi_server_tried" == 1 ]]; then
      return
   fi
   devpi_server_tried=1
   file=$(get_home_dir $1)/.pip/$file
   if sudo [ ! -e $file ]; then
   	devpi_server_ip=""
	   devpi_server_port=""
	   return
   fi
	pattern='^index *= *https?://(.*):([0-9]+)/.*/$'
   phrase=$(sudo grep -rE "$pattern" $file | head -n 1)
   if [[ $phrase =~ $pattern ]]; then
   	devpi_server_ip=${BASH_REMATCH[1]}
	   devpi_server_port=${BASH_REMATCH[2]}
	else
   	devpi_server_ip=""
	   devpi_server_port=""
	fi
}

function pip_update {
   $1 -m pip install --upgrade pip
}

function run_pipupgrade {
   pip_update
   if [[ "$2" == 1 ]]; then
      user_update="--user"
    else
      user_update=""
   fi
	if ! which pipupgrade >/dev/null; then
		$1 -m pip install --upgrade $user_update pipupgrade
	fi
	if which pipupgrade >/dev/null; then
		pipupgrade --ignore-error --latest --yes
	else
	   $1 -m pipupgrade --ignore-error --latest --yes
	fi
#   $1 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 $1 install -U
}

function get_devpi_server {
   find_devpi_server root pip.conf
   if [[ "$devpi_server_ip" == "" ]]; then
      find_devpi_server $USER pip.conf
      if [[ "$devpi_server_ip" == "" ]]; then
         find_devpi_server root pip.conf.bak
         if [[ "$devpi_server_ip" == "" ]]; then
            find_devpi_server $USER pip.conf.bak
         fi
      fi
   fi
}

devpi_server_tried=0
user_update=0
if which pip>/dev/null; then
   python=$(which python2)
   if [[ "${python}" != "" ]]; then
		if [[ "${python}" == "/usr/bin/python2" ]]; then
		   python="$python"
		   user_update=1
#		   python="sudo -H $python"
		fi
		get_devpi_server 
		pip_update "$python" $user_update
	fi
fi
if which pip3>/dev/null; then
   python=$(which python3)
   if [[ "${python}" != "" ]]; then
		if [[ "${python}" == "/usr/bin/python3" ]]; then
#		   python="sudo -H $python"
		   user_update=1
		   python="$python"
		fi
		get_devpi_server 
		pip_update "$python" $user_update
	fi
fi
#if which pip>/dev/null; then
#   pipbin=$(which pip)
#   get_devpi_server
#   pip_update "$pipbin"
#fi

