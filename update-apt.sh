#!/bin/bash

function turn_https {
	plik="/etc/apt/sources.list.d/$1"
	if [ -f "$plik" ]; then
		sudo sed -i 's/http:/https:/g' ${plik}*
	fi
}

function turn_http {
	plik="/etc/apt/sources.list.d/$1"
	if [ -f "${plik}" ]; then
		sudo sed -i 's/https/http/g' ${plik}*
	fi
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
		turn_http wine.list
		turn_http nodesource.list
		turn_http slack.list
		turn_http syncthing.list
		turn_http gitlab.list
		turn_http skype-stable.list
		if [ -z "$aptproxy_enabled" ]; then
			echo "Acquire::http::Proxy \"http://${aptproxy_ip}:${aptproxy_port}\";" > ${aptproxy_file}
		fi
	else
		if [ -n "$aptproxy_enabled" ]; then
			echo "#Acquire::http::Proxy \"http://${aptproxy_ip}:${aptproxy_port}\";" > ${aptproxy_file}
		fi
		turn_https wine.list
		turn_https nodesource.list
		turn_https slack.list
		turn_https syncthing.list
		turn_https gitlab.list
		turn_https skype-stable.list
	fi
fi

sudo apt update
sudo apt upgrade -y --fix-missing
sudo apt autoremove -y

