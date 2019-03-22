#!/bin/bash
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
	echo "Found aptproxy: ${aptproxy_ip}:${aptproxy_port} in ${aptproxy_file}"
	if ping -c 1 -w 1  $aptproxy_ip >/dev/null; then
		turn_http_all winehq.org
		turn_http_all nodesource.com
		turn_http_all slacktechnologies
		turn_http_all syncthing.net
		turn_http_all gitlab
		turn_http_all skype.com
		turn_http_all docker
		turn_http_all rstudio.com
		turn_http_all virtualbox.org
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
		turn_https_all winehq.org
		turn_https_all nodesource.com
		turn_https_all slacktechnologies
		turn_https_all syncthing.net
		turn_https_all gitlab
		turn_https_all skype.com
		turn_https_all docker
		turn_https_all rstudio.com
		turn_https_all virtualbox.org
		turn_https_all signal.org
		turn_https_all bintray.com/zulip
		turn_https_all packagecloud.io/AtomEditor
		turn_http_all dl.bintray.com/fedarovich/qbittorrent
		turn_http_all mkvtoolnix.download
	fi
fi

sudo apt update
sudo apt upgrade -y --fix-missing
sudo apt autoremove -y

