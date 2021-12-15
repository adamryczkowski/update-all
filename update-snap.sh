
function add_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	if [ ! -n "$(grep ${host} /etc/hosts)" >/dev/null ]; then
		$loglog
		echo "$HOSTS_LINE" | sudo tee -a /etc/hosts
	fi
}

function disable_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} #replace . into \.
	if grep  -E "$pattern" /etc/hosts >/dev/null;  then #element is already added
	   on_pattern=" *# *${ip} +${host}"
   	if grep  -E "$on_pattern" /etc/hosts >/dev/null; then #element is not already turned on
   	   sudo sed -i -r "s/${pattern}/${ip} ${host}/g" /etc/hosts
   	fi
	else
	   add_host "$1" "$2"
	fi
}

function enable_host {
	local host=$1
	local ip=$2
	local HOSTS_LINE="${ip} ${host}"
	local pattern=" *#? *${ip} +${host}"
	pattern=${pattern//./\\.} #replace . into \.
	if ! grep  -E "$pattern" /etc/hosts >/dev/null;  then #element is already added
	   add_host "$1" "$2"
	fi
   on_pattern=" *# *${ip} +${host}"
	if ! grep  -E "$on_pattern" /etc/hosts >/dev/null; then #element is not already turned on
	   sudo sed -i -r "s/${pattern}/# ${ip} ${host}/g" /etc/hosts
	fi
}

if which snap >/dev/null; then
   echo "Enabling api.snapcraft.io..."
   enable_host api.snapcraft.io 127.0.0.1
   echo "Refreshing snaps..."
   sudo snap refresh

	echo "Removing old snaps..."
	set -eu
	LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
	while read snapname revision; do
		snap remove "$snapname" --revision="$revision"
	done
    

   echo "Disabling api.snapcraft.io..."
   disable_host api.snapcraft.io 127.0.0.1
fi
