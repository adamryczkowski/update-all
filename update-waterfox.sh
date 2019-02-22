#!/bin/bash

if which waterfox; then
	waterfox=$(which waterfox)
elif [ -f /opt/waterfox/waterfox ]; then
	waterfox=/opt/waterfox/waterfox
else
	exit 0 #no waterfox
fi

version=$(${waterfox} --version)
pattern='^Mozilla Waterfox ([0-9.]+)$'

if [[ "$version" =~ $pattern ]]; then
	version=${BASH_REMATCH[1]}
else
	echo "Something wrong with the waterfox. ${waterfox} --version returned\n${version}"
	exit 1
fi

function get_latest_github_release_name { #source: https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
	curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
		grep '"tag_name":' |                                            # Get tag line
		sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

waterfox_version=$(get_latest_github_release_name MrAlex94/Waterfox)
pattern='^(([0-9]+)\.([0-9]+)\.([0-9]+)).*$'

if [[ "$waterfox_version" =~ $pattern ]]; then
	waterfox_version=${BASH_REMATCH[1]}
else
	echo "Something wrong with the waterfox. ${waterfox} --version returned\n${version}"
	exit 1
fi

function get_cached_file {
	local filename="$1"
	local download_link="$2"
	if [ ! -d "${repo_path}" ]; then
		mkdir -p /tmp/repo_path
		local repo_path="/tmp/repo_path"
	fi
	if [ ! -f "${repo_path}/${filename}" ]; then
		if [ -z "$download_link" ]; then
			echo "File is missing from cache"
			return 1
		fi
		if [ ! -w "${repo_path}" ]; then
			if ! sudo chown ${USER} "${repo_path}"; then
				echo "Cannot write to the repo ${repo_path}" >/dev/stderr
				exit 1
			fi
			local repo_path="/tmp/repo_path"
			mkdir -p /tmp/repo_path
		fi
		wget -c "${download_link}" -O "${repo_path}/${filename}"
	fi
	if [ ! -f "${repo_path}/${filename}" ]; then
		echo "Cannot download the file"
		return 1
	fi
	echo "${repo_path}/${filename}"
}

function is_folder_writable {
	local folder="$1"
	local user="$2"
	
	#source: https://stackoverflow.com/questions/14103806/bash-test-if-a-directory-is-writable-by-a-given-uid
	# Use -L to get information about the target of a symlink,
	# not the link itself, as pointed out in the comments
	INFO=( $(stat -L -c "0%a %G %U" $folder) )
	PERM=${INFO[0]}
	GROUP=${INFO[1]}
	OWNER=${INFO[2]}

	ACCESS=no
	if (( ($PERM & 0002) != 0 )); then
		# Everyone has write access
		ACCESS=yes
	elif (( ($PERM & 0020) != 0 )); then
		# Some group has write access.
		# Is user in that group?
		gs=( $(groups $user) )
		for g in "${gs[@]}"; do
			if [[ $GROUP == $g ]]; then
				ACCESS=yes
				break
			fi
		done
	elif (( ($PERM & 0200) != 0 )); then
		# The owner has write access.
		# Does the user own the file?
		[[ $user == $OWNER ]] && ACCESS=yes
	fi
	if [ "$ACCESS" == 'yes' ]; then
		return 0
	else
		return 1
	fi
}


function uncompress_cached_file {
	local filename="$1"
	local destination="$2"
	local usergr="$3"
	local user
	local timestamp_path="${destination}/$(basename ${filename}).timestamp"
	if [ -z "$usergr" ]; then
		user=$USER
		usergr=$user
		group=""
	else
		local pattern='^([^:]+):([^:]+)$'
		if [[ "$usergr" != $pattern ]]; then
			group=${BASH_REMATCH[2]}
			user=${BASH_REMATCH[1]}
		else
			group=""
			user=$user
		fi
	fi
	
	if [ ! -f "$filename" ]; then
		path_filename=$(get_cached_file "$filename")
	else
		path_filename="$filename"
	fi
	if [ -z "$path_filename" ]; then
		return 1
	fi
	if [ -z "$destination" ]; then
		return 2
	fi
	moddate_remote=$(stat -c %y "$path_filename")
	if [ -f "$timestamp_path" ]; then
		moddate_hdd=$(cat "$timestamp_path")
		if [ "$moddate_hdd" == "$moddate_remote" ]; then
			return 0
		fi
	fi
	if is_folder_writable "$destination" "$user"; then
		if [ "$user" == "$USER" ]; then
			tar -xvf "$path_filename" -C "$destination"
			echo "$moddate_remote" | tee "$timestamp_path"
		else
			sudo -u "$user" -- tar -xvf "$path_filename" -C "$destination"
			echo "$moddate_remote" | sudo -u "$user" -- tee "$timestamp_path"
		fi
	else
		sudo tar -xvf "$path_filename" -C "$destination"
		sudo chown -R "$usergr" "$destination"
		echo "$moddate_remote" | sudo -u "$user" -- tee "$timestamp_path"
	fi
}


if [[ $waterfox_version != $version ]]; then
	file=$(get_cached_file "waterfox-${waterfox_version}.en-US.linux-x86_64.tar.bz2" "https://storage-waterfox.netdna-ssl.com/releases/linux64/installer/waterfox-${waterfox_version}.en-US.linux-x86_64.tar.bz2")
	uncompress_cached_file waterfox-${waterfox_version}.en-US.linux-x86_64.tar.bz2 "/opt/"
	sudo chown root -R "/opt/waterfix"
fi



