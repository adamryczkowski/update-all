#!/bin/bash
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
trusted-host=adam-minipc

[search]
index = http://${address}/root/pypi/"
   
   file=$(get_home_dir $1)/.pip/pip.conf
   echo "$contents" | sudo tee $file >/dev/null
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


if which pip3; then
   devpi_disabled=0
   find_devpi_server root pip.conf
   if [[ "$devpi_server_ip" == "" ]]; then
      find_devpi_server $USER pip.conf
      devpi_disabled=1
   fi
   if [[ "$devpi_server_ip" != "" ]]; then
   	echo "System can use devpi_server: ${devpi_server_ip}:${devpi_server_port}"
      if is_host_tcp_port_up $devpi_server_ip $devpi_server_port; then
      	echo "devpi server ${devpi_server_ip}:${devpi_server_port} seems up and running!"
         enable_devpi_client root ${devpi_server_ip}:${devpi_server_port}
      else
      	echo "no devpi server running on the current network!"
         disable_devpi_client root
      fi
   fi
   sudo -H pip3 install --upgrade pip
   sudo -H pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H pip3 install -U
fi 

