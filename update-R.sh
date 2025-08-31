#!/bin/bash

if  ! command -v R >/dev/null; then
    exit 0
fi

localrmirror="/media/adam-minipc/other"
remotemirror="https://cloud.r-project.org"
minipc=192.168.10.2

function mount_smb_share {
	local mountpoint=$1
	if [ ! -d "$mountpoint" ]; then
		while [ ! -d "$mountpoint" ]; do
			mountpoint=$(dirname "$mountpoint")
		done
		mount "$mountpoint"
	fi
}

mount_smb_share "$localrmirror"

function get_home_dir {
	getent passwd "$USER" | cut -d: -f6
}

function get_other_folder {
	folder="$1"
	if [ -n "${folder}" ]; then
		folder="/${folder}"
	fi
	mountpoint="/media/adam-minipc/other"
	if [ -d "${mountpoint}" ]; then
		if [ ! -d "${mountpoint}${folder}" ]; then
			if ping -c 1 -w 1 ${minipc} >/dev/null; then
				mount ${mountpoint}
			fi 
		fi
		if [ -d "${mountpoint}${folder}" ]; then
			echo "${mountpoint}${folder}"
		fi
	fi
	echo ""
}

function get_deb_folder {
	deb_folder=$(get_home_dir)/tmp/debs
	other_folder=$(get_other_folder debs)
	if [ -n "${other_folder}" ]; then
		echo "${other_folder}"
	else
		if [ ! -d "${deb_folder}" ]; then
			mkdir -p "${deb_folder}"
		fi
		echo "${deb_folder}"
	fi
}

function update_r {
	# cran_folder was unused; removed to satisfy shellcheck
	sudo chown -R "${USER}" "$(get_home_dir)"/R
	Rscript -e 'dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)'
	Rscript -e "update.packages(ask = FALSE, lib = Sys.getenv(\"R_LIBS_USER\"), repos=\"${remotemirror}\")"
}

function get_netversion {

	netversion=$(curl -s http://download1.rstudio.org/current.ver)
	pattern='^([0-9.+]+)\+([0-9]+)'
	if [[ $netversion =~ $pattern ]]; then
		netversion1=${BASH_REMATCH[1]}
		netversion2=${BASH_REMATCH[2]}
		netversion="${netversion1}+${netversion2}"
	else
		return
	fi
}

function update_rstudio {
	ver=$(apt show rstudio | grep Version)
	if [[ -z "$ver" ]]; then
		return
	fi
	pattern='^Version: ([0-9.+]+)\s*$'
	if [[ $ver =~ $pattern ]]; then
		ourversion=${BASH_REMATCH[1]}
  	fi
	if [ "$ourversion" != "$netversion" ]; then
		deb_folder=$(get_deb_folder)
		RSTUDIO_URI="https://download1.rstudio.org/electron/jammy/amd64/rstudio-${netversion1}-${netversion2}-amd64.deb"
		
		wget --inet4-only -c --output-document /tmp/rstudio.deb "$RSTUDIO_URI" -O "${deb_folder}"/rstudio_"${netversion}"_amd64.deb
		if ! sudo dpkg -i "${deb_folder}"/rstudio_"${netversion}"_amd64.deb; then
			sudo apt install -f --yes
		fi
		rm /tmp/get_rstudio_uri.R

		if fc-list | grep -q FiraCode; then
			if ! grep -q "text-rendering:" /usr/lib/rstudio/www/index.htm; then
				sudo sed -i '/<head>/a<style>*{text-rendering: optimizeLegibility;}<\/style>' /usr/lib/rstudio/www/index.htm
			fi
		fi
	fi
}

function update_rstudio_server {
	ver=$(apt show rstudio-server | grep Version)
	if [[ -z "$ver" ]]; then
		return
	fi
	pattern='^Version: ([0-9.+]+)\s*$'
	if [[ $ver =~ $pattern ]]; then
		ourversion=${BASH_REMATCH[1]}
	fi
	if [ "$ourversion" != "$netversion" ]; then
		deb_folder=$(get_deb_folder)
		RSTUDIO_URI="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${netversion1}-${netversion2}-amd64.deb"

		wget --inet4-only -c "$RSTUDIO_URI" --output-document "${deb_folder}"/rstudio-server_"${netversion}"_amd64.deb
		if ! sudo dpkg -i "${deb_folder}"/rstudio-server_"${netversion}"_amd64.deb; then
			sudo apt install -f --yes
		fi
		rm /tmp/get_rstudio_uri.R
	fi
}

if dpkg -s r-base-core >/dev/null 2>/dev/null; then
	update_r
fi

get_netversion

update_rstudio

update_rstudio_server
