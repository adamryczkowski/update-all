#!/bin/bash


function is_host_up {
	ping -c1 -w1  $1 >/dev/null
	return $?
}

function is_host_tcp_port_up {
   if is_host_up $1; then
      local host=$1
      local port=$2
      nc -zw3 $1 $2
      return $?
   else
      return 1
   fi
}


function find_apt_list {
	phrase="$1"
	if [ -n "$(find /etc/apt/sources.list.d -name '*.list' | head -1)" ]; then
		grep -l /etc/apt/sources.list.d/*.list -e "${phrase}"
	fi
}

function turn_https {
	echo "http->https: $1"
#	plik="/etc/apt/sources.list.d/$1"
	plik="$1"
	if [ -f "$plik" ]; then
		sudo sed -i 's/http:/https:/g' ${plik}*
	else
	   return 1
	fi
}

function turn_http {
	echo "https->http: $1"
#	plik="/etc/apt/sources.list.d/$1"
	plik="$1"
	if [ -f "${plik}" ]; then
		sudo sed -i 's/https/http/g' ${plik}*
	fi
}

function turn_https_all {
	find_apt_list "$1" | while read file; do turn_https ${file}; done
}

function turn_http_all {
	find_apt_list "$1" | while read file; do turn_http ${file}; done
}

pattern1='(#?)Acquire::http::Proxy "https?://(.*):([0-9]+)";$'
pattern2="^([^:]+):$pattern1"
myproxy=$(grep -rE "^$pattern1" /etc/apt/apt.conf.d | head -n 1)
if [[ $myproxy =~ $pattern2 ]]; then
	aptproxy_file=${BASH_REMATCH[1]}
	aptproxy_enabled=${BASH_REMATCH[2]}
	aptproxy_ip=${BASH_REMATCH[3]}
	aptproxy_port=${BASH_REMATCH[4]}
	echo "System can use aptproxy: ${aptproxy_ip}:${aptproxy_port} in ${aptproxy_file}"
	if is_host_tcp_port_up $aptproxy_ip $aptproxy_port >/dev/null; then
#	if is_host_tcp_port_up $aptproxy_ip  >/dev/null; then
   	echo "aptproxy ${aptproxy_ip}:${aptproxy_port} seems up and running!"
		turn_http_all winehq.org
		turn_http_all nodesource.com
		turn_http_all slacktechnologies
		turn_http_all syncthing.net
		turn_http_all gitlab
		turn_http_all skype.com
		turn_http_all download.jitsi.org
		turn_http_all docker
		turn_http_all rstudio.com
		turn_http_all virtualbox.org
		turn_http_all nvidia.github.io
		turn_http_all signal.org
		turn_http_all bintray.com/zulip
		turn_http_all packagecloud.io/AtomEditor
		turn_http_all dl.bintray.com/fedarovich/qbittorrent
		turn_http_all mkvtoolnix.download
		if [ -n "$aptproxy_enabled" ]; then
			echo "Acquire::http::Proxy \"http://${aptproxy_ip}:${aptproxy_port}\";" | sudo tee ${aptproxy_file}
		fi
	else
		if [ -z "$aptproxy_enabled" ]; then
			echo "#Acquire::http::Proxy \"http://${aptproxy_ip}:${aptproxy_port}\";" | sudo tee ${aptproxy_file}
		fi
   	echo "no aptproxy running on the current network!"
		turn_https_all winehq.org
		turn_https_all nodesource.com
		turn_https_all slacktechnologies
		turn_https_all syncthing.net
		turn_https_all gitlab
		turn_https_all skype.com
		turn_https_all download.jitsi.org
		turn_https_all docker
		turn_https_all rstudio.com
		turn_https_all virtualbox.org
		turn_https_all nvidia.github.io
		turn_https_all signal.org
		turn_https_all bintray.com/zulip
		turn_https_all packagecloud.io/AtomEditor
		turn_https_all dl.bintray.com/fedarovich/qbittorrent
		turn_https_all mkvtoolnix.download
	fi
fi

sudo apt update
sudo apt upgrade -y --fix-missing
sudo apt autoremove -y

