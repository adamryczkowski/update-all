
function add_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	if [ ! -n "$(grep ${host} /etc/hosts)" ]; then
		$loglog
		echo "$HOSTS_LINE" | sudo tee -a /etc/hosts
	fi
}

function enable_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} #replace . into \.
	if grep  -E "$pattern" /etc/hosts;  then #element is already added
	   on_pattern=" *# *${ip} +${host}"
   	if grep  -E "$on_pattern" /etc/hosts; then #element is not already turned on
   	   sudo sed -i -r "s/${pattern}/${ip} ${host}/g" /etc/hosts
   	fi
	else
	   add_host "$1" "$2"
	fi
}

function disable_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} #replace . into \.
	if ! grep  -E "$pattern" /etc/hosts;  then #element is already added
	   add_host "$1" "$2"
	fi
   on_pattern=" *# *${ip} +${host}"
	if ! grep  -E "$on_pattern" /etc/hosts; then #element is not already turned on
	   sudo sed -i -r "s/${pattern}/# ${ip} ${host}/g" /etc/hosts
	fi
}

if which snap >/dev/null; then
   enable_host api.snapcraft.io 127.0.0.1
   snap refresh
   disable_host api.snapcraft.io 127.0.0.1
fi
